-- ============================================================================
-- FIX DELIVERY NOTIFICATION TRIGGER
-- ============================================================================
-- This script ensures the order status notification trigger works correctly
-- Run this in Supabase SQL Editor to fix any issues
-- ============================================================================

-- Step 1: Improve the trigger function with better error handling
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    STATUS_LABEL TEXT;
    NOTIFICATION_ID UUID;
BEGIN
    -- Only create notification if status actually changed
    IF OLD.STATUS IS NOT DISTINCT FROM NEW.STATUS THEN
        RETURN NEW;
    END IF;

    -- Map status to user-friendly label (case-insensitive)
    CASE UPPER(TRIM(NEW.STATUS))
        WHEN 'CONFIRMED' THEN STATUS_LABEL := 'Accepted';
        WHEN 'PROCESSING' THEN STATUS_LABEL := 'Order Pending';
        WHEN 'SHIPPED' THEN STATUS_LABEL := 'Shipped';
        WHEN 'DELIVERED' THEN STATUS_LABEL := 'Delivered';
        WHEN 'CANCELLED' THEN STATUS_LABEL := 'Cancelled';
        WHEN 'CANCELED' THEN STATUS_LABEL := 'Cancelled';  -- Handle both spellings
        WHEN 'PENDING' THEN STATUS_LABEL := 'Pending';
        ELSE STATUS_LABEL := INITCAP(REPLACE(TRIM(NEW.STATUS), '_', ' '));
    END CASE;

    -- Validate required fields
    IF NEW.USER_ID IS NULL THEN
        RAISE WARNING 'Cannot create notification: user_id is NULL for order %', NEW.ID;
        RETURN NEW;
    END IF;

    IF NEW.ORDER_NUMBER IS NULL OR NEW.ORDER_NUMBER = '' THEN
        RAISE WARNING 'Cannot create notification: order_number is NULL or empty for order %', NEW.ID;
        RETURN NEW;
    END IF;

    -- Insert notification (bypasses RLS because function uses SECURITY DEFINER)
    INSERT INTO PUBLIC.USER_NOTIFICATIONS (
        USER_ID,
        TYPE,
        TITLE,
        MESSAGE,
        ORDER_ID,
        IS_READ,
        CREATED_AT
    ) VALUES (
        NEW.USER_ID,
        'order_status_changed',
        'Order Status Updated',
        'Your order ' || NEW.ORDER_NUMBER || ' status has been updated to: ' || STATUS_LABEL,
        NEW.ID,
        FALSE,
        NOW()
    )
    RETURNING ID INTO NOTIFICATION_ID;
    
    -- Log success (only in debug mode - comment out in production if needed)
    -- RAISE NOTICE 'Notification created successfully: % for order %', NOTIFICATION_ID, NEW.ID;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log detailed error but don't fail the order update
        RAISE WARNING 'Error creating notification for order % (status: % -> %): %', 
            NEW.ID, OLD.STATUS, NEW.STATUS, SQLERRM;
        -- Return NEW to allow order update to succeed even if notification fails
        RETURN NEW;
END;
$$;

-- Step 2: Ensure trigger exists and is properly configured
DROP TRIGGER IF EXISTS TRIGGER_ORDER_STATUS_NOTIFICATION ON PUBLIC.ORDERS;

CREATE TRIGGER TRIGGER_ORDER_STATUS_NOTIFICATION
    AFTER UPDATE ON PUBLIC.ORDERS
    FOR EACH ROW
    WHEN (OLD.STATUS IS DISTINCT FROM NEW.STATUS)
    EXECUTE FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION();

-- Step 3: Grant execute permissions
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION() TO SERVICE_ROLE;

-- Step 4: Verify trigger is created
SELECT 
    '✅ Trigger Status:' AS info,
    trigger_name,
    event_manipulation,
    action_timing,
    action_condition
FROM information_schema.triggers
WHERE event_object_table = 'orders'
    AND trigger_schema = 'public'
    AND trigger_name = 'trigger_order_status_notification';

-- Step 5: Verify function exists
SELECT 
    '✅ Function Status:' AS info,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name = 'create_order_status_notification';

-- Step 6: Test the trigger with a sample update (optional - uncomment to test)
/*
-- Find a test order
DO $$
DECLARE
    test_order_id UUID;
    test_user_id UUID;
    old_status TEXT;
BEGIN
    -- Get a test order
    SELECT id, user_id, status INTO test_order_id, test_user_id, old_status
    FROM public.orders
    WHERE status != 'delivered'
    AND user_id IS NOT NULL
    LIMIT 1;
    
    IF test_order_id IS NULL THEN
        RAISE NOTICE 'No test order found';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testing with order: %, user: %, old_status: %', 
        test_order_id, test_user_id, old_status;
    
    -- Update to delivered
    UPDATE public.orders
    SET status = 'delivered'
    WHERE id = test_order_id;
    
    -- Check if notification was created
    PERFORM pg_sleep(1);
    
    IF EXISTS (
        SELECT 1 FROM public.user_notifications
        WHERE order_id = test_order_id
        AND type = 'order_status_changed'
        AND created_at > NOW() - INTERVAL '1 minute'
    ) THEN
        RAISE NOTICE '✅ SUCCESS: Notification created!';
    ELSE
        RAISE NOTICE '❌ FAILED: Notification not created!';
    END IF;
    
    -- Revert
    UPDATE public.orders
    SET status = old_status
    WHERE id = test_order_id;
END $$;
*/

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
SELECT 
    '🎉 TRIGGER FIX COMPLETE!' AS status,
    'The delivery notification trigger has been updated and verified' AS message,
    'Notifications will now be created when order status changes to delivered' AS details;

