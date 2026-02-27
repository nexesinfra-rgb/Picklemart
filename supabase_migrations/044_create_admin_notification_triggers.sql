-- ============================================================================
-- Create Admin Notification Triggers
-- ============================================================================
-- This migration creates database triggers that automatically create
-- notifications for ALL admin users when:
-- 1. A new order is placed
-- 2. An order status is updated
--
-- This enables both Supabase Realtime subscriptions and FCM push notifications
-- to work properly for admin users.
-- ============================================================================

-- Step 1: Create function to notify all admins about new orders
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ADMIN_ORDER_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    admin_record RECORD;
BEGIN
    -- Loop through all active admin users and create notifications
    FOR admin_record IN 
        SELECT id, name, email
        FROM PUBLIC.PROFILES
        WHERE role = 'admin'
        AND id IS NOT NULL
    LOOP
        -- Create notification for this admin
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
    END LOOP;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail order creation
        RAISE WARNING 'Error creating admin notifications for order %: %', NEW.ID, SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 2: Create trigger to call this function when order is placed
DROP TRIGGER IF EXISTS TRIGGER_ADMIN_ORDER_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ADMIN_ORDER_NOTIFICATION
    AFTER INSERT ON PUBLIC.ORDERS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.CREATE_ADMIN_ORDER_NOTIFICATION();

-- Step 3: Create function to notify all admins about order status changes
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ADMIN_ORDER_STATUS_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    admin_record RECORD;
    status_label TEXT;
BEGIN
    -- Only notify if status actually changed
    IF OLD.STATUS = NEW.STATUS THEN
        RETURN NEW;
    END IF;

    -- Map status to user-friendly label
    CASE NEW.STATUS
        WHEN 'confirmed' THEN status_label := 'Accepted';
        WHEN 'processing' THEN status_label := 'Order Pending';
        WHEN 'shipped' THEN status_label := 'Shipped';
        WHEN 'delivered' THEN status_label := 'Delivered';
        WHEN 'cancelled' THEN status_label := 'Cancelled';
        WHEN 'pending' THEN status_label := 'Pending';
        WHEN 'out_for_delivery' THEN status_label := 'Out for Delivery';
        ELSE status_label := INITCAP(REPLACE(NEW.STATUS, '_', ' '));
    END CASE;

    -- Loop through all active admin users and create notifications
    FOR admin_record IN 
        SELECT id, name, email
        FROM PUBLIC.PROFILES
        WHERE role = 'admin'
        AND id IS NOT NULL
    LOOP
        -- Create notification for this admin
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
            'order_status_changed',
            'Order Status Updated',
            'Order #' || NEW.ORDER_NUMBER || ' status changed to: ' || status_label,
            NEW.ID,
            FALSE,
            NOW()
        );
    END LOOP;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating admin status notifications for order %: %', NEW.ID, SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 4: Create trigger for order status changes
DROP TRIGGER IF EXISTS TRIGGER_ADMIN_ORDER_STATUS_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ADMIN_ORDER_STATUS_NOTIFICATION
    AFTER UPDATE ON PUBLIC.ORDERS
    FOR EACH ROW
    WHEN (OLD.STATUS IS DISTINCT FROM NEW.STATUS)
    EXECUTE FUNCTION PUBLIC.CREATE_ADMIN_ORDER_STATUS_NOTIFICATION();

-- Step 5: Ensure Realtime is enabled for user_notifications table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'user_notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_notifications;
        RAISE NOTICE '✅ Realtime enabled for user_notifications';
    ELSE
        RAISE NOTICE '✅ Realtime already enabled for user_notifications';
    END IF;
END $$;

-- Step 6: Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ADMIN_ORDER_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ADMIN_ORDER_STATUS_NOTIFICATION() TO AUTHENTICATED;

-- Step 7: Verify setup
SELECT 
    '✅ Admin notification triggers created' AS status,
    COUNT(*) AS admin_count
FROM PUBLIC.PROFILES
WHERE role = 'admin';

-- Step 8: Verify Realtime is enabled
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
            AND tablename = 'user_notifications'
        ) THEN '✅ Realtime enabled for user_notifications'
        ELSE '❌ Realtime NOT enabled for user_notifications'
    END AS realtime_status;

-- Step 9: Verify triggers exist
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
    AND trigger_name IN (
        'trigger_admin_order_notification',
        'trigger_admin_order_status_notification'
    )
ORDER BY trigger_name;

