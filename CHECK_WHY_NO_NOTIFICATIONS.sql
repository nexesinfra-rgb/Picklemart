-- ============================================================================
-- CHECK WHY NOTIFICATIONS AREN'T SHOWING
-- ============================================================================
-- Run this to diagnose why admin notifications aren't appearing
-- ============================================================================

-- Step 1: Check if triggers exist and are active
SELECT 
    'Trigger Status' AS check_type,
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

-- Step 2: Check your admin user ID
SELECT 
    'Your Admin User' AS check_type,
    id AS admin_user_id,
    name,
    email,
    role
FROM PUBLIC.PROFILES
WHERE role = 'admin'
ORDER BY name;

-- Step 3: Check if ANY notifications exist for admin users
SELECT 
    'All Admin Notifications' AS check_type,
    un.id,
    un.user_id,
    p.name AS admin_name,
    p.email AS admin_email,
    un.type,
    un.title,
    un.message,
    un.is_read,
    un.created_at
FROM PUBLIC.USER_NOTIFICATIONS un
JOIN PUBLIC.PROFILES p ON un.user_id = p.id
WHERE p.role = 'admin'
ORDER BY un.created_at DESC
LIMIT 20;

-- Step 4: Count notifications per admin
SELECT 
    'Notification Count per Admin' AS check_type,
    p.id AS admin_id,
    p.name AS admin_name,
    COUNT(un.id) AS total_notifications,
    COUNT(un.id) FILTER (WHERE un.is_read = false) AS unread_count
FROM PUBLIC.PROFILES p
LEFT JOIN PUBLIC.USER_NOTIFICATIONS un ON p.id = un.user_id
WHERE p.role = 'admin'
GROUP BY p.id, p.name
ORDER BY total_notifications DESC;

-- Step 5: Check recent orders (to see if trigger should have fired)
SELECT 
    'Recent Orders (Last 5)' AS check_type,
    id,
    order_number,
    user_id,
    status,
    created_at,
    CASE 
        WHEN created_at > NOW() - INTERVAL '1 hour' THEN 'Recent (should have notification)'
        ELSE 'Older'
    END AS notification_expected
FROM PUBLIC.ORDERS
ORDER BY created_at DESC
LIMIT 5;

-- Step 6: Check recent chat messages from users (to see if trigger should have fired)
SELECT 
    'Recent User Chat Messages (Last 5)' AS check_type,
    id,
    conversation_id,
    sender_id,
    sender_role,
    LEFT(content, 50) AS message_preview,
    created_at,
    CASE 
        WHEN created_at > NOW() - INTERVAL '1 hour' THEN 'Recent (should have notification)'
        ELSE 'Older'
    END AS notification_expected
FROM PUBLIC.CHAT_MESSAGES
WHERE sender_role = 'user'
ORDER BY created_at DESC
LIMIT 5;

-- Step 7: Test trigger manually - Create a test notification directly
-- This will help verify if the issue is with triggers or with loading
INSERT INTO PUBLIC.USER_NOTIFICATIONS (
    USER_ID,
    TYPE,
    TITLE,
    MESSAGE,
    IS_READ,
    CREATED_AT
)
SELECT 
    id,
    'order_placed',
    'Test Notification',
    'This is a test notification created at ' || NOW()::TEXT,
    FALSE,
    NOW()
FROM PUBLIC.PROFILES
WHERE role = 'admin'
LIMIT 1;

SELECT '✅ Test notification created for admin user' AS result;

-- Step 8: Verify the test notification was created
SELECT 
    'Test Notification Check' AS check_type,
    id,
    user_id,
    type,
    title,
    message,
    is_read,
    created_at
FROM PUBLIC.USER_NOTIFICATIONS
WHERE title = 'Test Notification'
ORDER BY created_at DESC
LIMIT 1;

-- Step 9: Check Realtime status
SELECT 
    'Realtime Status' AS check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
            AND tablename = 'user_notifications'
        ) THEN '✅ Enabled'
        ELSE '❌ Disabled - This is a problem!'
    END AS realtime_status;

