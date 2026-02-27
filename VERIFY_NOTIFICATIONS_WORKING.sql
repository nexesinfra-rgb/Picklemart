-- ============================================================================
-- VERIFY NOTIFICATIONS ARE WORKING
-- ============================================================================
-- Run this after placing an order or sending a chat message to check if
-- notifications are being created in the database
-- ============================================================================

-- Step 1: Check if triggers exist
SELECT 
    'Trigger Check' AS check_type,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND trigger_name IN (
        'trigger_admin_order_notification',
        'trigger_admin_order_status_notification',
        'trigger_admin_chat_notification'
    )
ORDER BY trigger_name;

-- Step 2: Check if functions exist
SELECT 
    'Function Check' AS check_type,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_admin_order_notification',
        'create_admin_order_status_notification',
        'create_admin_chat_notification'
    )
ORDER BY routine_name;

-- Step 3: Check recent notifications for admin user
-- Replace 'd341eb0b-d8f1-4bc1-89ef-06da050aa6af' with your admin ID if different
SELECT 
    'Recent Admin Notifications' AS check_type,
    id,
    user_id,
    type,
    title,
    message,
    order_id,
    conversation_id,
    is_read,
    created_at
FROM PUBLIC.USER_NOTIFICATIONS
WHERE user_id = 'd341eb0b-d8f1-4bc1-89ef-06da050aa6af'
ORDER BY created_at DESC
LIMIT 10;

-- Step 4: Count notifications by type for admin
SELECT 
    'Notification Count by Type' AS check_type,
    type,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE is_read = false) AS unread_count
FROM PUBLIC.USER_NOTIFICATIONS
WHERE user_id = 'd341eb0b-d8f1-4bc1-89ef-06da050aa6af'
GROUP BY type
ORDER BY total_count DESC;

-- Step 5: Check recent orders (to see if triggers should fire)
SELECT 
    'Recent Orders' AS check_type,
    id,
    order_number,
    user_id,
    status,
    created_at
FROM PUBLIC.ORDERS
ORDER BY created_at DESC
LIMIT 5;

-- Step 6: Check recent chat messages (to see if triggers should fire)
SELECT 
    'Recent Chat Messages' AS check_type,
    id,
    conversation_id,
    sender_id,
    sender_role,
    content,
    created_at
FROM PUBLIC.CHAT_MESSAGES
WHERE sender_role = 'user'
ORDER BY created_at DESC
LIMIT 5;

-- Step 7: Verify Realtime is enabled
SELECT 
    'Realtime Status' AS check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
            AND tablename = 'user_notifications'
        ) THEN '✅ Enabled'
        ELSE '❌ Disabled'
    END AS realtime_status;

-- Step 8: Test - Manually create a test notification
-- Uncomment the following to create a test notification:
/*
INSERT INTO PUBLIC.USER_NOTIFICATIONS (
    USER_ID,
    TYPE,
    TITLE,
    MESSAGE,
    IS_READ,
    CREATED_AT
) VALUES (
    'd341eb0b-d8f1-4bc1-89ef-06da050aa6af',
    'order_placed',
    'Test Notification',
    'This is a test notification to verify the system is working',
    FALSE,
    NOW()
);

SELECT '✅ Test notification created' AS result;
*/














