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
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error creating notification for order %: %', NEW.ID, SQLERRM;
        RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ORDER_PLACED_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
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
        RAISE WARNING 'Error creating notification for order %: %', NEW.ID, SQLERRM;
        RETURN NEW;
END;
$$;

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

DROP POLICY IF EXISTS "Admins can insert notifications for any user" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Admins can insert notifications for any user" ON PUBLIC.USER_NOTIFICATIONS
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ORDER_PLACED_NOTIFICATION() TO AUTHENTICATED;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'user_notifications'
    ) THEN
        RAISE NOTICE 'Real-time is enabled for user_notifications';
    ELSE
        RAISE WARNING 'Real-time may not be enabled. Go to Supabase Dashboard → Database → Replication → Enable for user_notifications table';
    END IF;
END $$;

SELECT 
    '✅ Trigger Status' AS check_type,
    CASE 
        WHEN COUNT(*) = 2 THEN 'PASS: Both triggers exist'
        ELSE 'FAIL: Expected 2 triggers, found ' || COUNT(*)
    END AS status,
    COUNT(*) AS trigger_count,
    string_agg(trigger_name, ', ') AS trigger_names
FROM information_schema.triggers
WHERE event_object_table = 'orders' 
    AND trigger_schema = 'public'
    AND trigger_name IN (
        'trigger_order_placed_notification',
        'trigger_order_status_notification'
    );

SELECT 
    '✅ Function Status' AS check_type,
    routine_name,
    CASE 
        WHEN security_type = 'DEFINER' THEN 'PASS: SECURITY DEFINER (Bypasses RLS)'
        ELSE 'FAIL: NOT SECURITY DEFINER - Will be blocked by RLS!'
    END AS security_status,
    security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_order_status_notification',
        'create_order_placed_notification'
    )
ORDER BY routine_name;

SELECT 
    '✅ RLS Policy Status' AS check_type,
    CASE 
        WHEN COUNT(*) > 0 THEN 'PASS: Admin RLS policy exists'
        ELSE 'FAIL: Admin RLS policy missing'
    END AS status,
    COUNT(*) AS policy_count,
    string_agg(policyname, ', ') AS policy_names
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
    AND policyname = 'Admins can insert notifications for any user';

SELECT 
    '✅ Table Status' AS check_type,
    CASE 
        WHEN COUNT(*) > 0 THEN 'PASS: user_notifications table exists'
        ELSE 'FAIL: user_notifications table missing'
    END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_name = 'user_notifications';

SELECT 
    '🎉 FIX COMPLETE!' AS summary,
    'Notifications will now work automatically via database triggers' AS message,
    'Triggers bypass RLS using SECURITY DEFINER' AS method,
    'RLS policy added as backup for application-level inserts' AS backup;
