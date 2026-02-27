-- ============================================================================
-- FIX CHAT AND ORDER NOTIFICATIONS FOR ADMIN
-- ============================================================================
-- This script creates database notifications for admin when:
-- 1. A user sends a chat message
-- 2. A new order is placed
-- 3. Order status changes
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Step 1: Ensure TYPE constraint allows all notification types
ALTER TABLE PUBLIC.USER_NOTIFICATIONS 
    DROP CONSTRAINT IF EXISTS user_notifications_type_check;

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
    -- Loop through all admin users and create notifications
    FOR admin_record IN 
        SELECT id, name, email
        FROM PUBLIC.PROFILES
        WHERE role = 'admin'
        AND id IS NOT NULL
    LOOP
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
                RAISE WARNING 'Error creating notification for admin % (order %): %', 
                    admin_record.id, NEW.ID, SQLERRM;
        END;
    END LOOP;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error in CREATE_ADMIN_ORDER_NOTIFICATION for order %: %', NEW.ID, SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 3: Create trigger for new orders
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

    -- Loop through all admin users and create notifications
    FOR admin_record IN 
        SELECT id, name, email
        FROM PUBLIC.PROFILES
        WHERE role = 'admin'
        AND id IS NOT NULL
    LOOP
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

-- Step 6: Create function to notify all admins when user sends chat message
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ADMIN_CHAT_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    admin_record RECORD;
    sender_name TEXT;
    conversation_user_id UUID;
BEGIN
    -- Only notify if user sent message (not admin)
    IF NEW.SENDER_ROLE != 'user' THEN
        RETURN NEW;
    END IF;
    
    -- Get sender name
    SELECT NAME INTO sender_name
    FROM PUBLIC.PROFILES
    WHERE ID = NEW.SENDER_ID;
    
    IF sender_name IS NULL THEN
        sender_name := 'User';
    END IF;
    
    -- Get conversation user_id (the customer)
    SELECT USER_ID INTO conversation_user_id
    FROM PUBLIC.CHAT_CONVERSATIONS
    WHERE ID = NEW.CONVERSATION_ID;
    
    -- Loop through all admin users and create notifications
    FOR admin_record IN 
        SELECT id, name, email
        FROM PUBLIC.PROFILES
        WHERE role = 'admin'
        AND id IS NOT NULL
    LOOP
        BEGIN
            INSERT INTO PUBLIC.USER_NOTIFICATIONS (
                USER_ID,
                TYPE,
                TITLE,
                MESSAGE,
                CONVERSATION_ID,
                IS_READ,
                CREATED_AT
            ) VALUES (
                admin_record.id,
                'chat_message',
                'New Message from ' || sender_name,
                COALESCE(NEW.CONTENT, 'New message'),
                NEW.CONVERSATION_ID,
                FALSE,
                NOW()
            );
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Error creating chat notification for admin % (message %): %', 
                    admin_record.id, NEW.ID, SQLERRM;
        END;
    END LOOP;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error in CREATE_ADMIN_CHAT_NOTIFICATION for message %: %', NEW.ID, SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 7: Create trigger for chat messages (user -> admin)
DROP TRIGGER IF EXISTS TRIGGER_ADMIN_CHAT_NOTIFICATION ON PUBLIC.CHAT_MESSAGES;
CREATE TRIGGER TRIGGER_ADMIN_CHAT_NOTIFICATION
    AFTER INSERT ON PUBLIC.CHAT_MESSAGES
    FOR EACH ROW
    WHEN (NEW.SENDER_ROLE = 'user')
    EXECUTE FUNCTION PUBLIC.CREATE_ADMIN_CHAT_NOTIFICATION();

-- Step 8: Ensure Realtime is enabled
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

-- Step 9: Grant permissions
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ADMIN_ORDER_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ADMIN_ORDER_STATUS_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ADMIN_CHAT_NOTIFICATION() TO AUTHENTICATED;

-- Step 10: Verify setup
SELECT 
    '✅ Setup Complete' AS status,
    (SELECT COUNT(*) FROM PUBLIC.PROFILES WHERE role = 'admin') AS admin_count,
    (SELECT COUNT(*) FROM information_schema.triggers 
     WHERE trigger_schema = 'public' 
     AND trigger_name IN (
         'trigger_admin_order_notification', 
         'trigger_admin_order_status_notification',
         'trigger_admin_chat_notification'
     )) AS trigger_count,
    (SELECT CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime' 
            AND tablename = 'user_notifications'
        ) THEN 'Enabled'
        ELSE 'Disabled'
    END) AS realtime_status;

-- Step 11: Show admin users
SELECT 
    'Admin Users' AS info,
    id,
    name,
    email,
    role
FROM PUBLIC.PROFILES
WHERE role = 'admin'
ORDER BY name;














