-- ============================================================================
-- Add FCM Push Notification Trigger
-- ============================================================================
-- This migration creates a database trigger that automatically sends FCM push
-- notifications when a notification record is inserted into user_notifications table.
-- 
-- The trigger uses pg_net extension to call Supabase Edge Functions which then
-- send push notifications via Firebase Cloud Messaging (FCM).
-- ============================================================================

-- Step 1: Enable pg_net extension (allows HTTP calls from PostgreSQL)
-- Note: This extension may already be enabled in Supabase
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Step 2: Update TYPE constraint to include all notification types
-- First, drop the existing constraint if it exists
DO $$
BEGIN
    -- Drop existing constraint if it exists
    ALTER TABLE PUBLIC.USER_NOTIFICATIONS 
    DROP CONSTRAINT IF EXISTS user_notifications_type_check;
    
    -- Add new constraint with all notification types
    ALTER TABLE PUBLIC.USER_NOTIFICATIONS 
    ADD CONSTRAINT user_notifications_type_check 
    CHECK (TYPE IN (
        'order_placed', 
        'order_status_changed', 
        'chat_message', 
        'rating_reply'
    ));
    
    RAISE NOTICE '✅ Notification TYPE constraint updated';
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error updating TYPE constraint: %', SQLERRM;
END $$;

-- Step 3: Create function to send FCM push notification
-- This function determines if notification is for admin or user and calls appropriate edge function
CREATE OR REPLACE FUNCTION PUBLIC.SEND_FCM_PUSH_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    user_role TEXT;
    supabase_url TEXT;
    function_name TEXT;
    payload JSONB;
    response_id BIGINT;
    order_number TEXT;
BEGIN
    -- Get user role from profile
    SELECT role INTO user_role
    FROM PUBLIC.PROFILES
    WHERE id = NEW.USER_ID
    LIMIT 1;
    
    -- If profile not found, skip FCM (shouldn't happen, but be safe)
    IF user_role IS NULL THEN
        RAISE WARNING 'User profile not found for user_id: %', NEW.USER_ID;
        RETURN NEW;
    END IF;
    
    -- Get Supabase URL from environment or use default
    -- In Supabase, we can use current_setting to get the project URL
    -- For now, we'll use the hardcoded URL (can be made configurable later)
    supabase_url := 'https://db.picklemart.cloud';
    
    -- Determine which edge function to call based on user role
    IF user_role = 'admin' OR user_role = 'manager' OR user_role = 'support' THEN
        function_name := 'send-admin-fcm-notification';
    ELSE
        function_name := 'send-user-fcm-notification';
    END IF;
    
    -- Get order number if order_id exists
    IF NEW.ORDER_ID IS NOT NULL THEN
        SELECT order_number INTO order_number
        FROM PUBLIC.ORDERS
        WHERE id = NEW.ORDER_ID
        LIMIT 1;
    END IF;
    
    -- Build payload for edge function (handle NULL values properly)
    payload := jsonb_build_object(
        'type', NEW.TYPE,
        'title', NEW.TITLE,
        'message', NEW.MESSAGE,
        'order_id', COALESCE(NEW.ORDER_ID::TEXT, NULL),
        'order_number', order_number,
        'conversation_id', COALESCE(NEW.CONVERSATION_ID::TEXT, NULL)
    );
    
    -- For user notifications, include user_id to target specific user
    IF function_name = 'send-user-fcm-notification' THEN
        payload := payload || jsonb_build_object('user_id', NEW.USER_ID::TEXT);
    END IF;
    
    -- Call edge function via pg_net.http_post
    -- Note: pg_net.http_post is asynchronous - it queues the request and returns immediately
    -- The request will be processed by a background worker
    -- Using anon key is acceptable here because:
    -- 1. Edge functions handle authentication internally via service role key from environment
    -- 2. Edge functions validate the request and use service role key for FCM operations
    -- 3. The anon key is already public and used for client-side operations
    BEGIN
        SELECT net.http_post(
            url := supabase_url || '/functions/v1/' || function_name,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoiYW5vbiJ9.yW0F7LtfldnjQzwnlqQRsvoc2iKFycfgmUOPT1f-Sxs',
                'apikey', 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoiYW5vbiJ9.yW0F7LtfldnjQzwnlqQRsvoc2iKFycfgmUOPT1f-Sxs'
            ),
            body := payload::text
        ) INTO response_id;
        
        -- Log the request ID for debugging (can check in net.http_request_queue)
        RAISE NOTICE '[FCM] Queued HTTP request ID: % for notification % (user: %, type: %)', 
            response_id, NEW.ID, NEW.USER_ID, NEW.TYPE;
            
    EXCEPTION
        WHEN OTHERS THEN
            -- If pg_net fails, log but don't fail notification creation
            RAISE WARNING '[FCM] Failed to queue HTTP request for notification %: %', NEW.ID, SQLERRM;
    END;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail notification creation
        -- FCM push notification is not critical - notification record should still be created
        RAISE WARNING 'Error sending FCM push notification for notification % (user_id: %, type: %): %', 
            NEW.ID, NEW.USER_ID, NEW.TYPE, SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 4: Create trigger on user_notifications table
-- This trigger fires AFTER INSERT and sends FCM push notification
DROP TRIGGER IF EXISTS TRIGGER_SEND_FCM_PUSH_NOTIFICATION ON PUBLIC.USER_NOTIFICATIONS;
CREATE TRIGGER TRIGGER_SEND_FCM_PUSH_NOTIFICATION
    AFTER INSERT ON PUBLIC.USER_NOTIFICATIONS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.SEND_FCM_PUSH_NOTIFICATION();

-- Step 5: Grant execute permissions
GRANT EXECUTE ON FUNCTION PUBLIC.SEND_FCM_PUSH_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.SEND_FCM_PUSH_NOTIFICATION() TO SERVICE_ROLE;

-- ============================================================================
-- ALTERNATIVE IMPLEMENTATION (if pg_net doesn't work with service role key)
-- ============================================================================
-- If the above doesn't work due to authentication issues, we can use a simpler
-- approach that calls the edge function without authentication (edge function
-- should handle auth internally via service role key from environment)
-- ============================================================================

-- Alternative function that uses anon key (less secure but simpler)
-- Uncomment this if the main function doesn't work:
/*
CREATE OR REPLACE FUNCTION PUBLIC.SEND_FCM_PUSH_NOTIFICATION_ALT()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    user_role TEXT;
    user_profile RECORD;
    supabase_url TEXT;
    function_name TEXT;
    payload JSONB;
    response_id BIGINT;
    order_number TEXT;
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJncWN1eWt2c2llamdxZWllZnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3NzE1NzQsImV4cCI6MjA4MTM0NzU3NH0.YysdlRJwJWTDrFgF8cQA6-0ppETGRV6RBCTcXxe0jvg';
BEGIN
    -- Get user profile to determine role
    SELECT role INTO user_profile
    FROM PUBLIC.PROFILES
    WHERE id = NEW.USER_ID
    LIMIT 1;
    
    IF user_profile IS NULL THEN
        RETURN NEW;
    END IF;
    
    user_role := user_profile.role;
    supabase_url := 'https://bgqcuykvsiejgqeiefpi.supabase.co';
    
    IF user_role = 'admin' OR user_role = 'manager' OR user_role = 'support' THEN
        function_name := 'send-admin-fcm-notification';
    ELSE
        function_name := 'send-user-fcm-notification';
    END IF;
    
    IF NEW.ORDER_ID IS NOT NULL THEN
        SELECT order_number INTO order_number
        FROM PUBLIC.ORDERS
        WHERE id = NEW.ORDER_ID
        LIMIT 1;
    END IF;
    
    payload := jsonb_build_object(
        'type', NEW.TYPE,
        'title', NEW.TITLE,
        'message', NEW.MESSAGE,
        'order_id', NEW.ORDER_ID,
        'order_number', order_number,
        'conversation_id', NEW.CONVERSATION_ID
    );
    
    IF function_name = 'send-user-fcm-notification' THEN
        payload := payload || jsonb_build_object('user_id', NEW.USER_ID::TEXT);
    END IF;
    
    -- Call edge function with anon key
    SELECT net.http_post(
        url := supabase_url || '/functions/v1/' || function_name,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || anon_key
        ),
        body := payload::text
    ) INTO response_id;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error sending FCM push notification: %', SQLERRM;
        RETURN NEW;
END;
$$;
*/

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify pg_net extension is enabled
SELECT 
    '✅ pg_net Extension Status:' AS info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_extension WHERE extname = 'pg_net'
        ) THEN '✅ Enabled'
        ELSE '❌ Not Enabled'
    END AS status;

-- Verify trigger exists
SELECT 
    '✅ Trigger Status:' AS info,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND trigger_name = 'trigger_send_fcm_push_notification'
    AND event_object_table = 'user_notifications';

-- Verify function exists
SELECT 
    '✅ Function Status:' AS info,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name = 'send_fcm_push_notification';

-- Verify TYPE constraint
SELECT 
    '✅ TYPE Constraint Status:' AS info,
    constraint_name,
    check_clause
FROM information_schema.check_constraints
WHERE constraint_schema = 'public'
    AND constraint_name = 'user_notifications_type_check';

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
SELECT 
    '🎉 FCM Push Notification Trigger Created!' AS status,
    'Notifications will now automatically send FCM push notifications' AS message,
    'Trigger fires AFTER INSERT on user_notifications table' AS trigger_info,
    'Uses pg_net extension to call Supabase Edge Functions' AS method;

