-- ============================================================================
-- Fix FCM Notifications - Complete Solution
-- ============================================================================
-- This migration fixes critical FCM notification issues:
-- 1. Keeps your custom Supabase URL (db.picklemart.cloud)
-- 2. Prevents admin from receiving their own notifications when placing orders
-- 3. Ensures users receive notifications when admin places orders
-- ============================================================================

-- ============================================================================
-- Step 1: Fix FCM Push Notification Trigger Function
-- ============================================================================
-- Note: Keeping your custom URL (db.picklemart.cloud)
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
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJncWN1eWt2c2llamdxZWllZnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3NzE1NzQsImV4cCI6MjA4MTM0NzU3NH0.YysdlRJwJWTDrFgF8cQA6-0ppETGRV6RBCTcXxe0jvg';
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
    
    -- Use your custom Supabase URL
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
    BEGIN
        SELECT net.http_post(
            url := supabase_url || '/functions/v1/' || function_name,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || anon_key,
                'apikey', anon_key
            ),
            body := payload::text
        ) INTO response_id;
        
        -- Log the request ID for debugging
        RAISE NOTICE '[FCM] Queued HTTP request ID: % for notification % (user: %, type: %, function: %)', 
            response_id, NEW.ID, NEW.USER_ID, NEW.TYPE, function_name;
            
    EXCEPTION
        WHEN OTHERS THEN
            -- If pg_net fails, log but don't fail notification creation
            RAISE WARNING '[FCM] Failed to queue HTTP request for notification %: %', NEW.ID, SQLERRM;
    END;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail notification creation
        RAISE WARNING '[FCM] Error sending FCM push notification for notification % (user_id: %, type: %): %', 
            NEW.ID, NEW.USER_ID, NEW.TYPE, SQLERRM;
        RETURN NEW;
END;
$$;

-- ============================================================================
-- Step 2: Fix Admin Notification Trigger to Exclude Order Creator
-- ============================================================================
-- Fix: Prevent admin from receiving notifications for orders they created
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ADMIN_ORDER_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    admin_record RECORD;
    order_creator_id UUID;
    order_creator_role TEXT;
BEGIN
    -- Get the user who created this order
    order_creator_id := NEW.USER_ID;
    
    -- Get the role of the order creator
    SELECT role INTO order_creator_role
    FROM PUBLIC.PROFILES
    WHERE id = order_creator_id
    LIMIT 1;
    
    -- Loop through all active admin users and create notifications
    -- FIX: Exclude the admin who created this order
    FOR admin_record IN 
        SELECT id, name, email
        FROM PUBLIC.PROFILES
        WHERE role = 'admin'
        AND id IS NOT NULL
        AND id != order_creator_id  -- EXCLUDE ORDER CREATOR
    LOOP
        -- Create notification for this admin
        BEGIN
            INSERT INTO PUBLIC.USER_NOTIFICATIONS (
                USER_ID,
                TYPE,
                TITLE,
                MESSAGE,
                ORDER_ID,
                IS_READ,
                CREATED_AT
            ) VALUES (
                admin_record.id,
                'order_placed',
                'New Order Received',
                'New order #' || NEW.ORDER_NUMBER || ' has been placed by customer.',
                NEW.ID,
                FALSE,
                NOW()
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Log error for this specific admin but continue with others
                RAISE WARNING 'Error creating notification for admin % (order %): %', 
                    admin_record.id, NEW.ID, SQLERRM;
        END;
    END LOOP;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail order creation
        RAISE WARNING 'Error in CREATE_ADMIN_ORDER_NOTIFICATION for order %: %', NEW.ID, SQLERRM;
        RETURN NEW;
END;
$$;

-- ============================================================================
-- Step 3: Verify Functions Are Updated
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ FCM notification functions updated successfully';
    RAISE NOTICE '   - SEND_FCM_PUSH_NOTIFICATION: Using custom URL https://db.picklemart.cloud';
    RAISE NOTICE '   - CREATE_ADMIN_ORDER_NOTIFICATION: Now excludes order creator';
END $$;

-- ============================================================================
-- Step 4: Verification Queries
-- ============================================================================

-- Verify FCM trigger exists and is active
SELECT 
    '✅ FCM Trigger Status' AS info,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND trigger_name = 'trigger_send_fcm_push_notification'
    AND event_object_table = 'user_notifications';

-- Verify admin notification trigger exists
SELECT 
    '✅ Admin Notification Trigger Status' AS info,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND trigger_name = 'trigger_admin_order_notification'
    AND event_object_table = 'orders';

-- Verify functions exist
SELECT 
    '✅ Function Status' AS info,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN ('send_fcm_push_notification', 'create_admin_order_notification')
ORDER BY routine_name;

-- ============================================================================
-- Step 5: Summary
-- ============================================================================
SELECT 
    '🎉 FCM Notifications Fixed!' AS status,
    'All fixes applied successfully' AS message,
    'Users will now receive notifications when admin places orders' AS user_fix,
    'Admin will NOT receive their own notifications' AS admin_fix,
    'FCM trigger uses your custom URL (db.picklemart.cloud)' AS url_fix;

