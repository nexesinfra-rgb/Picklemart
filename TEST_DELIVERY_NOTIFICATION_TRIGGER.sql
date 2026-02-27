-- ============================================================================
-- TEST DELIVERY NOTIFICATION TRIGGER
-- ============================================================================
-- This script tests the order status notification trigger
-- Run this in Supabase SQL Editor
-- ============================================================================

-- IMPORTANT: Replace the placeholders below with actual values from your database
-- 1. Find an order ID that is NOT already delivered
-- 2. Note the order's current status and user_id
-- 3. Replace the placeholders in the test below

-- Step 1: Find a test order (run this first to get an order ID)
SELECT 
    '📋 Available Test Orders:' AS info,
    id,
    order_number,
    status,
    user_id,
    created_at
FROM public.orders
WHERE status != 'delivered'
ORDER BY created_at DESC
LIMIT 5;

-- Step 2: Manual trigger test (uncomment and replace placeholders)
/*
DO $$
DECLARE
    test_order_id UUID := 'REPLACE_WITH_ORDER_ID';  -- Replace with actual order ID
    test_user_id UUID;
    old_status TEXT;
    new_status TEXT := 'delivered';
    notification_count_before INT;
    notification_count_after INT;
BEGIN
    -- Get order details
    SELECT user_id, status INTO test_user_id, old_status
    FROM public.orders
    WHERE id = test_order_id;
    
    IF test_user_id IS NULL THEN
        RAISE EXCEPTION 'Order not found: %', test_order_id;
    END IF;
    
    -- Count notifications before
    SELECT COUNT(*) INTO notification_count_before
    FROM public.user_notifications
    WHERE order_id = test_order_id
    AND type = 'order_status_changed';
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TESTING DELIVERY NOTIFICATION TRIGGER';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Order ID: %', test_order_id;
    RAISE NOTICE 'Order Number: %', (SELECT order_number FROM public.orders WHERE id = test_order_id);
    RAISE NOTICE 'User ID: %', test_user_id;
    RAISE NOTICE 'Old Status: %', old_status;
    RAISE NOTICE 'New Status: %', new_status;
    RAISE NOTICE 'Notifications before: %', notification_count_before;
    
    -- Update order status (this should trigger the notification)
    UPDATE public.orders
    SET status = new_status
    WHERE id = test_order_id;
    
    -- Wait a moment for trigger to execute
    PERFORM pg_sleep(0.5);
    
    -- Count notifications after
    SELECT COUNT(*) INTO notification_count_after
    FROM public.user_notifications
    WHERE order_id = test_order_id
    AND type = 'order_status_changed';
    
    RAISE NOTICE 'Notifications after: %', notification_count_after;
    
    -- Check if notification was created
    IF notification_count_after > notification_count_before THEN
        RAISE NOTICE '✅ SUCCESS: Notification was created!';
        
        -- Show the notification details
        RAISE NOTICE 'Notification Details:';
        FOR rec IN 
            SELECT id, title, message, created_at
            FROM public.user_notifications
            WHERE order_id = test_order_id
            AND type = 'order_status_changed'
            AND created_at > NOW() - INTERVAL '1 minute'
            ORDER BY created_at DESC
            LIMIT 1
        LOOP
            RAISE NOTICE '  ID: %', rec.id;
            RAISE NOTICE '  Title: %', rec.title;
            RAISE NOTICE '  Message: %', rec.message;
            RAISE NOTICE '  Created At: %', rec.created_at;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ FAILED: Notification was NOT created!';
        RAISE NOTICE 'Possible issues:';
        RAISE NOTICE '  1. Trigger might not be active';
        RAISE NOTICE '  2. Trigger function might have errors';
        RAISE NOTICE '  3. RLS policy might be blocking';
        RAISE NOTICE '  4. Check PostgreSQL logs for errors';
    END IF;
    
    -- Revert the status change
    UPDATE public.orders
    SET status = old_status
    WHERE id = test_order_id;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Test complete. Order status reverted.';
    RAISE NOTICE '========================================';
END $$;
*/

-- Step 3: Check trigger function directly (test without trigger)
/*
DO $$
DECLARE
    test_order_id UUID := 'REPLACE_WITH_ORDER_ID';
    test_user_id UUID;
    test_order_number TEXT;
    test_status TEXT := 'delivered';
BEGIN
    -- Get order details
    SELECT user_id, order_number INTO test_user_id, test_order_number
    FROM public.orders
    WHERE id = test_order_id;
    
    IF test_user_id IS NULL THEN
        RAISE EXCEPTION 'Order not found';
    END IF;
    
    RAISE NOTICE 'Testing trigger function directly...';
    
    -- Simulate OLD and NEW records
    -- Note: This is a simplified test - actual trigger has access to OLD and NEW
    PERFORM public.create_order_status_notification();
    
    RAISE NOTICE 'Function executed (check for errors above)';
END $$;
*/

-- Step 4: Check for recent trigger errors
-- Note: This requires access to PostgreSQL logs
-- Check Supabase Dashboard > Logs > Postgres Logs for any warnings or errors

-- Step 5: Verify trigger is enabled
SELECT 
    '🔍 Trigger Status:' AS info,
    t.trigger_name,
    t.event_manipulation,
    t.action_timing,
    t.action_statement,
    CASE 
        WHEN t.action_statement LIKE '%create_order_status_notification%' THEN '✅ Correct function'
        ELSE '❌ Wrong function'
    END as function_check
FROM information_schema.triggers t
WHERE t.event_object_table = 'orders'
    AND t.trigger_schema = 'public'
    AND t.trigger_name = 'trigger_order_status_notification';

-- Step 6: Check function definition
SELECT 
    '🔍 Function Definition:' AS info,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
    AND p.proname = 'create_order_status_notification';

