-- ============================================================================
-- FIX ADMIN NOTIFICATIONS - Run This Now
-- ============================================================================
-- This script fixes admin notifications by ensuring all triggers and functions
-- are properly created. Run this in Supabase SQL Editor.
-- ============================================================================

-- Step 1: Ensure TYPE constraint allows 'order_placed' (should already exist)
-- First, drop the old constraint if it exists
ALTER TABLE PUBLIC.USER_NOTIFICATIONS 
    DROP CONSTRAINT IF EXISTS user_notifications_type_check;

-- Recreate with all allowed types
ALTER TABLE PUBLIC.USER_NOTIFICATIONS 
    ADD CONSTRAINT user_notifications_type_check
    CHECK (TYPE IN ('order_placed', 'order_status_changed', 'chat_message', 'rating_reply'));

-- Step 2: Create function to notify all admins about new orders
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

-- Step 3: Create trigger to call this function when order is placed
DROP TRIGGER IF EXISTS TRIGGER_ADMIN_ORDER_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ADMIN_ORDER_NOTIFICATION
    AFTER INSERT ON PUBLIC.ORDERS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.CREATE_ADMIN_ORDER_NOTIFICATION();

-- Step 4: Create function to notify all admins about order status changes
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
                'order_status_changed',
                'Order Status Updated',
                'Order #' || NEW.ORDER_NUMBER || ' status changed to: ' || status_label,
                NEW.ID,
                FALSE,
                NOW()
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Log error for this specific admin but continue with others
                RAISE WARNING 'Error creating status notification for admin % (order %): %', 
                    admin_record.id, NEW.ID, SQLERRM;
        END;
    END LOOP;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error in CREATE_ADMIN_ORDER_STATUS_NOTIFICATION for order %: %', NEW.ID, SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 5: Create trigger for order status changes
DROP TRIGGER IF EXISTS TRIGGER_ADMIN_ORDER_STATUS_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ADMIN_ORDER_STATUS_NOTIFICATION
    AFTER UPDATE ON PUBLIC.ORDERS
    FOR EACH ROW
    WHEN (OLD.STATUS IS DISTINCT FROM NEW.STATUS)
    EXECUTE FUNCTION PUBLIC.CREATE_ADMIN_ORDER_STATUS_NOTIFICATION();

-- Step 6: Ensure Realtime is enabled for user_notifications table
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

-- Step 7: Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ADMIN_ORDER_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ADMIN_ORDER_STATUS_NOTIFICATION() TO AUTHENTICATED;

-- Step 8: Verify setup
SELECT 
    '✅ Setup Complete' AS status,
    (SELECT COUNT(*) FROM PUBLIC.PROFILES WHERE role = 'admin') AS admin_count,
    (SELECT COUNT(*) FROM information_schema.triggers 
     WHERE trigger_schema = 'public' 
     AND trigger_name IN ('trigger_admin_order_notification', 'trigger_admin_order_status_notification')) AS trigger_count,
    (SELECT CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
            AND tablename = 'user_notifications'
        ) THEN 'Enabled'
        ELSE 'Disabled'
    END) AS realtime_status;

-- Step 9: Show admin users that will receive notifications
SELECT 
    'Admin Users' AS info,
    id,
    name,
    email,
    role
FROM PUBLIC.PROFILES
WHERE role = 'admin'
ORDER BY name;

