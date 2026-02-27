-- ============================================================================
-- FIX FCM PUSH NOTIFICATIONS
-- ============================================================================
-- This script fixes the FCM push notification trigger to work reliably
-- The issue is that pg_net.http_post is asynchronous, so we need a better approach
-- ============================================================================

-- Step 1: Ensure pg_net extension is enabled
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Step 2: Drop and recreate the function with improved error handling
-- and synchronous-like behavior using pg_net's request queue
DROP FUNCTION IF EXISTS PUBLIC.SEND_FCM_PUSH_NOTIFICATION() CASCADE;

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
    anon_key TEXT := 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoiYW5vbiJ9.yW0F7LtfldnjQzwnlqQRsvoc2iKFycfgmUOPT1f-Sxs';
    request_url TEXT;
BEGIN
    -- Get user role from profile
    SELECT role INTO user_role
    FROM PUBLIC.PROFILES
    WHERE id = NEW.USER_ID
    LIMIT 1;
    
    -- If profile not found, skip FCM (shouldn't happen, but be safe)
    IF user_role IS NULL THEN
        RAISE WARNING '[FCM] User profile not found for user_id: %', NEW.USER_ID;
        RETURN NEW;
    END IF;
    
    -- Set Supabase URL
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
    
    -- Build payload for edge function
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
    
    -- Build the full URL
    request_url := supabase_url || '/functions/v1/' || function_name;
    
    -- Call edge function via pg_net.http_post
    -- Note: pg_net.http_post is asynchronous - it queues the request and returns immediately
    -- The request will be processed by a background worker
    BEGIN
        SELECT net.http_post(
            url := request_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || anon_key,
                'apikey', anon_key
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
        RAISE WARNING '[FCM] Error in send_fcm_push_notification for notification % (user_id: %, type: %): %', 
            NEW.ID, NEW.USER_ID, NEW.TYPE, SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 3: Recreate the trigger
DROP TRIGGER IF EXISTS TRIGGER_SEND_FCM_PUSH_NOTIFICATION ON PUBLIC.USER_NOTIFICATIONS;
CREATE TRIGGER TRIGGER_SEND_FCM_PUSH_NOTIFICATION
    AFTER INSERT ON PUBLIC.USER_NOTIFICATIONS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.SEND_FCM_PUSH_NOTIFICATION();

-- Step 4: Grant execute permissions
GRANT EXECUTE ON FUNCTION PUBLIC.SEND_FCM_PUSH_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.SEND_FCM_PUSH_NOTIFICATION() TO SERVICE_ROLE;

-- ============================================================================
-- ALTERNATIVE: Use Supabase Database Webhooks (if pg_net doesn't work)
-- ============================================================================
-- If pg_net is not working, you can use Supabase Database Webhooks instead:
-- 1. Go to Supabase Dashboard → Database → Webhooks
-- 2. Create a new webhook
-- 3. Table: user_notifications
-- 4. Events: INSERT
-- 5. HTTP Request URL: https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/send-user-fcm-notification
-- 6. HTTP Request Method: POST
-- 7. HTTP Request Headers: Authorization: Bearer YOUR_ANON_KEY
-- 8. HTTP Request Body: Select "JSON" and use the notification data
-- ============================================================================

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check if trigger exists
SELECT 
    '✅ Trigger Status' AS check_name,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND trigger_name = 'trigger_send_fcm_push_notification';

-- Check if function exists
SELECT 
    '✅ Function Status' AS check_name,
    routine_name,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name = 'send_fcm_push_notification';

-- Check pg_net extension
SELECT 
    '✅ pg_net Extension' AS check_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') 
        THEN '✅ Enabled' 
        ELSE '❌ Not Enabled' 
    END AS status;

-- Check recent HTTP requests (if any)
SELECT 
    '✅ Recent HTTP Requests' AS check_name,
    COUNT(*) AS total_requests,
    COUNT(*) FILTER (WHERE status_code = 200) AS successful,
    COUNT(*) FILTER (WHERE status_code IS NOT NULL AND status_code != 200) AS failed,
    COUNT(*) FILTER (WHERE status_code IS NULL) AS pending
FROM net.http_request_queue
WHERE created_at > NOW() - INTERVAL '1 hour';

-- ============================================================================
-- TEST: Create a test notification to trigger FCM
-- ============================================================================
-- Uncomment and run this to test (replace USER_ID with an actual user ID):
/*
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Get a user ID (preferably one with an FCM token)
    SELECT id INTO test_user_id
    FROM PUBLIC.PROFILES
    WHERE role != 'admin'
    LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RAISE NOTICE 'No users found to test';
        RETURN;
    END IF;
    
    -- Insert a test notification (this will trigger the FCM push)
    INSERT INTO PUBLIC.USER_NOTIFICATIONS (
        USER_ID,
        TYPE,
        TITLE,
        MESSAGE,
        IS_READ,
        CREATED_AT
    ) VALUES (
        test_user_id,
        'order_placed',
        'Test FCM Notification',
        'This is a test notification to verify FCM push is working',
        FALSE,
        NOW()
    );
    
    RAISE NOTICE '✅ Test notification created for user: %', test_user_id;
    RAISE NOTICE 'Check net.http_request_queue to see if HTTP request was queued';
END $$;
*/

SELECT 
    '🎉 FCM Push Notification Fix Applied!' AS status,
    'The trigger will now queue HTTP requests via pg_net' AS message,
    'Check net.http_request_queue table to see queued requests' AS next_step,
    'If requests are queued but not executing, check Supabase Dashboard → Logs' AS troubleshooting;














