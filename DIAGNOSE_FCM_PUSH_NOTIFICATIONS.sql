-- ============================================================================
-- DIAGNOSE FCM PUSH NOTIFICATION ISSUES
-- ============================================================================
-- Run this to check why FCM push notifications are not being sent
-- ============================================================================

-- Step 1: Check if pg_net extension is enabled
SELECT 
    'Step 1: pg_net Extension' AS check_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') 
        THEN '✅ Enabled' 
        ELSE '❌ NOT Enabled - Run: CREATE EXTENSION IF NOT EXISTS pg_net;' 
    END AS status;

-- Step 2: Check if trigger exists
SELECT 
    'Step 2: FCM Push Trigger' AS check_name,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    CASE 
        WHEN trigger_name IS NOT NULL THEN '✅ Exists'
        ELSE '❌ Missing'
    END AS status
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND trigger_name = 'trigger_send_fcm_push_notification'
    AND event_object_table = 'user_notifications';

-- Step 3: Check if function exists
SELECT 
    'Step 3: FCM Push Function' AS check_name,
    routine_name,
    routine_type,
    security_type,
    CASE 
        WHEN routine_name IS NOT NULL THEN '✅ Exists'
        ELSE '❌ Missing'
    END AS status
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name = 'send_fcm_push_notification';

-- Step 4: Check recent pg_net HTTP requests (if available)
-- Note: This might not work if pg_net doesn't expose this view
SELECT 
    'Step 4: Recent HTTP Requests' AS check_name,
    COUNT(*) AS total_requests,
    COUNT(*) FILTER (WHERE status_code = 200) AS successful,
    COUNT(*) FILTER (WHERE status_code != 200 AND status_code IS NOT NULL) AS failed,
    COUNT(*) FILTER (WHERE status_code IS NULL) AS pending
FROM net.http_request_queue
WHERE created_at > NOW() - INTERVAL '1 hour'
LIMIT 10;

-- Step 5: Check recent notifications (to see if trigger should fire)
SELECT 
    'Step 5: Recent Notifications' AS check_name,
    id,
    user_id,
    type,
    title,
    created_at,
    CASE 
        WHEN created_at > NOW() - INTERVAL '5 minutes' THEN '✅ Recent (should trigger FCM)'
        ELSE '⚠️ Old'
    END AS status
FROM PUBLIC.USER_NOTIFICATIONS
ORDER BY created_at DESC
LIMIT 10;

-- Step 6: Check if users have FCM tokens registered
SELECT 
    'Step 6: User FCM Tokens' AS check_name,
    COUNT(*) AS total_tokens,
    COUNT(*) FILTER (WHERE is_active = true) AS active_tokens,
    COUNT(DISTINCT user_id) AS users_with_tokens
FROM PUBLIC.USER_FCM_TOKENS;

-- Step 7: Check if admins have FCM tokens registered
SELECT 
    'Step 7: Admin FCM Tokens' AS check_name,
    COUNT(*) AS total_tokens,
    COUNT(*) FILTER (WHERE is_active = true) AS active_tokens,
    COUNT(DISTINCT admin_id) AS admins_with_tokens
FROM PUBLIC.ADMIN_FCM_TOKENS;

-- Step 8: Test the function manually (if you have a test notification ID)
-- Replace 'YOUR_NOTIFICATION_ID' with an actual notification ID from Step 5
/*
DO $$
DECLARE
    test_notification RECORD;
    result TEXT;
BEGIN
    -- Get a recent notification
    SELECT * INTO test_notification
    FROM PUBLIC.USER_NOTIFICATIONS
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF test_notification.id IS NULL THEN
        RAISE NOTICE 'No notifications found to test';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testing FCM push for notification: %', test_notification.id;
    RAISE NOTICE 'User ID: %, Type: %, Title: %', 
        test_notification.user_id, 
        test_notification.type, 
        test_notification.title;
    
    -- Try to call the function (this won't work directly, but shows what would happen)
    RAISE NOTICE 'Note: Cannot directly test trigger function, but trigger should fire on INSERT';
END $$;
*/

-- Step 9: Check edge function deployment status
-- Note: This requires checking Supabase Dashboard manually
SELECT 
    'Step 9: Edge Functions Status' AS check_name,
    '⚠️ Manual Check Required' AS status,
    'Go to Supabase Dashboard → Edge Functions and verify:' AS instruction,
    '1. send-user-fcm-notification is deployed' AS check1,
    '2. send-admin-fcm-notification is deployed' AS check2,
    '3. FIREBASE_SERVICE_ACCOUNT secret is set' AS check3;

-- Step 10: Check for errors in PostgreSQL logs
-- Note: This might not be accessible, but worth checking
SELECT 
    'Step 10: Recent Warnings/Errors' AS check_name,
    '⚠️ Check Supabase Dashboard → Logs → Postgres Logs' AS instruction,
    'Look for warnings containing "FCM push notification" or "send_fcm_push_notification"' AS what_to_look_for;














