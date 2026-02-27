-- ============================================================================
-- VERIFY DELIVERY NOTIFICATION TRIGGER
-- ============================================================================
-- Run this in Supabase SQL Editor to verify the trigger is working correctly
-- ============================================================================

-- Step 1: Verify trigger exists and is active
SELECT 
    '✅ Trigger Status:' AS info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    action_condition
FROM information_schema.triggers
WHERE event_object_table = 'orders'
    AND trigger_schema = 'public'
    AND trigger_name = 'trigger_order_status_notification';

-- Step 2: Verify function exists
SELECT 
    '✅ Function Status:' AS info,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name = 'create_order_status_notification';

-- Step 3: Check recent order status updates
SELECT 
    '📋 Recent Order Status Updates:' AS info,
    id,
    order_number,
    status,
    user_id,
    updated_at
FROM public.orders
ORDER BY updated_at DESC
LIMIT 10;

-- Step 4: Check if notifications were created for recent status changes
SELECT 
    '🔔 Recent Status Change Notifications:' AS info,
    n.id,
    n.user_id,
    n.type,
    n.title,
    n.message,
    n.order_id,
    n.created_at,
    o.order_number,
    o.status as order_status
FROM public.user_notifications n
LEFT JOIN public.orders o ON n.order_id = o.id
WHERE n.type = 'order_status_changed'
ORDER BY n.created_at DESC
LIMIT 10;

-- Step 5: Test trigger manually - Find an order to test with
-- Replace 'YOUR_ORDER_ID' with an actual order ID from your database
-- Replace 'YOUR_USER_ID' with the user ID who owns that order
/*
DO $$
DECLARE
    test_order_id UUID;
    test_user_id UUID;
    old_status TEXT;
    new_status TEXT := 'delivered';
BEGIN
    -- Get a test order (change this to use a real order ID)
    SELECT id, user_id, status INTO test_order_id, test_user_id, old_status
    FROM public.orders
    WHERE status != 'delivered'
    LIMIT 1;
    
    IF test_order_id IS NULL THEN
        RAISE NOTICE 'No test order found';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testing trigger with order: %, user: %, old_status: %, new_status: %', 
        test_order_id, test_user_id, old_status, new_status;
    
    -- Update order status (this should trigger the notification)
    UPDATE public.orders
    SET status = new_status
    WHERE id = test_order_id;
    
    -- Check if notification was created
    IF EXISTS (
        SELECT 1 FROM public.user_notifications
        WHERE order_id = test_order_id
        AND type = 'order_status_changed'
        AND created_at > NOW() - INTERVAL '1 minute'
    ) THEN
        RAISE NOTICE '✅ SUCCESS: Notification was created!';
    ELSE
        RAISE NOTICE '❌ FAILED: Notification was NOT created!';
    END IF;
    
    -- Revert the status change
    UPDATE public.orders
    SET status = old_status
    WHERE id = test_order_id;
    
    RAISE NOTICE 'Test complete. Order status reverted.';
END $$;
*/

-- Step 6: Check for trigger execution errors in PostgreSQL logs
-- Note: This requires access to PostgreSQL logs, which may not be available in Supabase dashboard
-- You can check Supabase logs in the Dashboard > Logs section

-- Step 7: Verify the trigger condition works
-- This query shows orders where status changed but no notification exists
SELECT 
    '⚠️ Potential Issues:' AS info,
    o.id as order_id,
    o.order_number,
    o.status,
    o.user_id,
    o.updated_at,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM public.user_notifications n
            WHERE n.order_id = o.id
            AND n.type = 'order_status_changed'
            AND n.created_at >= o.updated_at - INTERVAL '5 minutes'
        ) THEN 'Missing notification'
        ELSE 'OK'
    END as notification_status
FROM public.orders o
WHERE o.updated_at > NOW() - INTERVAL '1 hour'
ORDER BY o.updated_at DESC;

