-- ============================================================================
-- 🚀 PERMANENT FIX: Notifications Will Work Forever
-- ============================================================================
-- Run this ONCE in Supabase SQL Editor and notifications will ALWAYS work
-- This uses database triggers (bypass RLS) + RLS policy (backup)
-- ============================================================================
-- Copy entire file → Supabase Dashboard → SQL Editor → Paste → Run
-- ============================================================================

-- Step 1: Create/Update order status notification function (BYPASSES RLS)
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    STATUS_LABEL TEXT;
BEGIN
    IF OLD.STATUS = NEW.STATUS THEN
        RETURN NEW;
    END IF;

    CASE NEW.STATUS
        WHEN 'confirmed' THEN STATUS_LABEL := 'Accepted';
        WHEN 'processing' THEN STATUS_LABEL := 'Order Pending';
        WHEN 'shipped' THEN STATUS_LABEL := 'Shipped';
        WHEN 'delivered' THEN STATUS_LABEL := 'Delivered';
        WHEN 'cancelled' THEN STATUS_LABEL := 'Cancelled';
        WHEN 'pending' THEN STATUS_LABEL := 'Pending';
        ELSE STATUS_LABEL := INITCAP(REPLACE(NEW.STATUS, '_', ' '));
    END CASE;

    INSERT INTO PUBLIC.USER_NOTIFICATIONS (
        USER_ID, TYPE, TITLE, MESSAGE, ORDER_ID, IS_READ, CREATED_AT
    ) VALUES (
        NEW.USER_ID,
        'order_status_changed',
        'Order Status Updated',
        'Your order ' || NEW.ORDER_NUMBER || ' status has been updated to: ' || STATUS_LABEL,
        NEW.ID,
        FALSE,
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 2: Create/Update order placed notification function (BYPASSES RLS)
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ORDER_PLACED_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
BEGIN
    INSERT INTO PUBLIC.USER_NOTIFICATIONS (
        USER_ID, TYPE, TITLE, MESSAGE, ORDER_ID, IS_READ, CREATED_AT
    ) VALUES (
        NEW.USER_ID,
        'order_placed',
        'Order Placed Successfully',
        'Your order ' || NEW.ORDER_NUMBER || ' has been placed successfully. We will process it soon.',
        NEW.ID,
        FALSE,
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 3: Create triggers (AUTOMATIC - no code needed)
DROP TRIGGER IF EXISTS TRIGGER_ORDER_PLACED_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ORDER_PLACED_NOTIFICATION
    AFTER INSERT ON PUBLIC.ORDERS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.CREATE_ORDER_PLACED_NOTIFICATION();

DROP TRIGGER IF EXISTS TRIGGER_ORDER_STATUS_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ORDER_STATUS_NOTIFICATION
    AFTER UPDATE ON PUBLIC.ORDERS
    FOR EACH ROW
    WHEN (OLD.STATUS IS DISTINCT FROM NEW.STATUS)
    EXECUTE FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION();

-- Step 4: Add RLS policy as backup (for app-level inserts)
DROP POLICY IF EXISTS "Admins can insert notifications for any user" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Admins can insert notifications for any user" ON PUBLIC.USER_NOTIFICATIONS
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Step 5: Grant permissions
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ORDER_PLACED_NOTIFICATION() TO AUTHENTICATED;

-- ============================================================================
-- ✅ VERIFICATION (Shows what was created)
-- ============================================================================
SELECT '✅ Triggers Created:' AS status, COUNT(*) AS count
FROM information_schema.triggers
WHERE event_object_table = 'orders' AND trigger_schema = 'public'
    AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification');

SELECT '✅ Functions Created:' AS status, COUNT(*) AS count
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN ('create_order_status_notification', 'create_order_placed_notification');

SELECT '✅ RLS Policy Created:' AS status, COUNT(*) AS count
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'user_notifications'
    AND policyname = 'Admins can insert notifications for any user';

-- ============================================================================
-- 🎉 DONE! Notifications will work automatically now.
-- ============================================================================
-- Test: Change an order status as admin → Customer gets notification instantly
-- ============================================================================

