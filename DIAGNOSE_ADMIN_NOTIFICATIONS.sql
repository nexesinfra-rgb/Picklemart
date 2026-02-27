-- ============================================================================
-- Diagnostic Script for Admin Notifications
-- ============================================================================
-- Run this in Supabase SQL Editor to diagnose why admin notifications
-- are not appearing after placing an order.
-- ============================================================================

-- Step 1: Check if admin users exist
SELECT 
    'Step 1: Admin Users Check' AS check_name,
    id,
    name,
    email,
    role
FROM PUBLIC.PROFILES
WHERE role = 'admin'
ORDER BY role, name;

-- Step 2: Check if triggers exist
SELECT 
    'Step 2: Trigger Check' AS check_name,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND event_object_table = 'orders'
    AND trigger_name IN (
        'trigger_admin_order_notification',
        'trigger_admin_order_status_notification',
        'trigger_order_placed_notification',
        'trigger_order_status_notification'
    )
ORDER BY trigger_name;

-- Step 3: Check if functions exist
SELECT 
    'Step 3: Function Check' AS check_name,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_admin_order_notification',
        'create_admin_order_status_notification',
        'create_order_placed_notification',
        'create_order_status_notification'
    )
ORDER BY routine_name;

-- Step 4: Check TYPE constraint on user_notifications
SELECT 
    'Step 4: Type Constraint Check' AS check_name,
    constraint_name,
    check_clause
FROM information_schema.check_constraints
WHERE constraint_schema = 'public'
    AND constraint_name LIKE '%user_notifications%type%'
    OR constraint_name LIKE '%type%check%';

-- Step 5: Check recent notifications (last 10)
SELECT 
    'Step 5: Recent Notifications' AS check_name,
    id,
    user_id,
    type,
    title,
    message,
    order_id,
    is_read,
    created_at
FROM PUBLIC.USER_NOTIFICATIONS
ORDER BY created_at DESC
LIMIT 10;

-- Step 6: Check notifications for admin users specifically
SELECT 
    'Step 6: Admin Notifications' AS check_name,
    un.id,
    un.user_id,
    p.name AS admin_name,
    p.role AS admin_role,
    un.type,
    un.title,
    un.message,
    un.order_id,
    un.is_read,
    un.created_at
FROM PUBLIC.USER_NOTIFICATIONS un
JOIN PUBLIC.PROFILES p ON un.user_id = p.id
WHERE p.role IN ('admin', 'manager', 'support')
ORDER BY un.created_at DESC
LIMIT 10;

-- Step 7: Check recent orders (last 5)
SELECT 
    'Step 7: Recent Orders' AS check_name,
    id,
    order_number,
    user_id,
    status,
    created_at
FROM PUBLIC.ORDERS
ORDER BY created_at DESC
LIMIT 5;

-- Step 8: Check if Realtime is enabled
SELECT 
    'Step 8: Realtime Check' AS check_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
            AND tablename = 'user_notifications'
        ) THEN '✅ Realtime enabled'
        ELSE '❌ Realtime NOT enabled'
    END AS realtime_status;

-- Step 9: Check RLS policies
SELECT 
    'Step 9: RLS Policies' AS check_name,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
ORDER BY policyname;

-- Step 10: Test trigger manually (if you have a test order ID)
-- Replace 'YOUR_ORDER_ID_HERE' with an actual order ID from Step 7
-- Uncomment the following to test:
/*
DO $$
DECLARE
    test_order RECORD;
    admin_record RECORD;
    notification_count INTEGER := 0;
BEGIN
    -- Get a recent order
    SELECT * INTO test_order
    FROM PUBLIC.ORDERS
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF test_order.id IS NULL THEN
        RAISE NOTICE 'No orders found to test';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testing with order: %', test_order.order_number;
    
    -- Count existing notifications for this order
    SELECT COUNT(*) INTO notification_count
    FROM PUBLIC.USER_NOTIFICATIONS
    WHERE order_id = test_order.id;
    
    RAISE NOTICE 'Existing notifications for this order: %', notification_count;
    
    -- Count admin users
    SELECT COUNT(*) INTO notification_count
    FROM PUBLIC.PROFILES
    WHERE role = 'admin';
    
    RAISE NOTICE 'Admin users found: %', notification_count;
END $$;
*/

