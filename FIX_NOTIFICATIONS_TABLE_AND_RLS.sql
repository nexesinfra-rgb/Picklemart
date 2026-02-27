-- ============================================================================
-- COMPLETE FIX: Create user_notifications Table + RLS + Triggers
-- ============================================================================
-- Run this in Supabase SQL Editor to create everything needed for notifications
-- This will create the table, RLS policies, triggers, and verify everything
-- ============================================================================
-- Copy entire file → Supabase Dashboard → SQL Editor → Paste → Run
-- ============================================================================

-- ============================================================================
-- STEP 1: Create user_notifications Table
-- ============================================================================
CREATE TABLE IF NOT EXISTS PUBLIC.USER_NOTIFICATIONS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    TYPE TEXT NOT NULL CHECK (TYPE IN ('order_placed', 'order_status_changed')),
    TITLE TEXT NOT NULL,
    MESSAGE TEXT NOT NULL,
    ORDER_ID UUID REFERENCES PUBLIC.ORDERS(ID) ON DELETE CASCADE,
    IS_READ BOOLEAN DEFAULT FALSE,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- STEP 2: Create Indexes for Performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_USER_ID ON PUBLIC.USER_NOTIFICATIONS(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_IS_READ ON PUBLIC.USER_NOTIFICATIONS(IS_READ);
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_CREATED_AT ON PUBLIC.USER_NOTIFICATIONS(CREATED_AT DESC);
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_ORDER_ID ON PUBLIC.USER_NOTIFICATIONS(ORDER_ID) WHERE ORDER_ID IS NOT NULL;

-- ============================================================================
-- STEP 3: Enable Row Level Security (RLS)
-- ============================================================================
ALTER TABLE PUBLIC.USER_NOTIFICATIONS ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 4: Create RLS Policies
-- ============================================================================

-- Policy 1: Users can SELECT their own notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Users can view their own notifications" ON PUBLIC.USER_NOTIFICATIONS
    FOR SELECT
    TO AUTHENTICATED
    USING (AUTH.UID() = USER_ID);

-- Policy 2: Users can UPDATE their own notifications (mark as read)
DROP POLICY IF EXISTS "Users can update their own notifications" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Users can update their own notifications" ON PUBLIC.USER_NOTIFICATIONS
    FOR UPDATE
    TO AUTHENTICATED
    USING (AUTH.UID() = USER_ID)
    WITH CHECK (AUTH.UID() = USER_ID);

-- Policy 3: Users can INSERT their own notifications (for triggers)
DROP POLICY IF EXISTS "Users can insert their own notifications" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Users can insert their own notifications" ON PUBLIC.USER_NOTIFICATIONS
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (AUTH.UID() = USER_ID);

-- Policy 4: Admins can INSERT notifications for any user (CRITICAL for app-level inserts)
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

-- ============================================================================
-- STEP 5: Create Trigger Function for Order Placed Notifications
-- ============================================================================
-- This function uses SECURITY DEFINER to bypass RLS completely
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
        RAISE WARNING 'Error creating order placed notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- ============================================================================
-- STEP 6: Create Trigger Function for Order Status Changed Notifications
-- ============================================================================
-- This function uses SECURITY DEFINER to bypass RLS completely
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    STATUS_LABEL TEXT;
BEGIN
    -- Only create notification if status actually changed
    IF OLD.STATUS = NEW.STATUS THEN
        RETURN NEW;
    END IF;

    -- Map status to user-friendly label
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
        RAISE WARNING 'Error creating order status notification: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- ============================================================================
-- STEP 7: Create Triggers
-- ============================================================================

-- Trigger for order placed notifications
DROP TRIGGER IF EXISTS TRIGGER_ORDER_PLACED_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ORDER_PLACED_NOTIFICATION
    AFTER INSERT ON PUBLIC.ORDERS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.CREATE_ORDER_PLACED_NOTIFICATION();

-- Trigger for order status changed notifications
DROP TRIGGER IF EXISTS TRIGGER_ORDER_STATUS_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ORDER_STATUS_NOTIFICATION
    AFTER UPDATE ON PUBLIC.ORDERS
    FOR EACH ROW
    WHEN (OLD.STATUS IS DISTINCT FROM NEW.STATUS)
    EXECUTE FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION();

-- ============================================================================
-- STEP 8: Grant Permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION() TO AUTHENTICATED;
GRANT EXECUTE ON FUNCTION PUBLIC.CREATE_ORDER_PLACED_NOTIFICATION() TO AUTHENTICATED;

-- ============================================================================
-- STEP 9: Add Table Comment
-- ============================================================================
COMMENT ON TABLE PUBLIC.USER_NOTIFICATIONS IS 'Stores user notifications for order events and status changes.';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check 1: Verify table exists
SELECT 
    '✅ Table Status' AS check_type,
    CASE 
        WHEN COUNT(*) > 0 THEN 'PASS: user_notifications table exists'
        ELSE 'FAIL: user_notifications table missing'
    END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_name = 'user_notifications';

-- Check 2: Verify triggers exist
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

-- Check 3: Verify functions use SECURITY DEFINER
SELECT 
    '✅ Function Security' AS check_type,
    routine_name,
    CASE 
        WHEN security_type = 'DEFINER' THEN 'PASS: SECURITY DEFINER (Bypasses RLS)'
        ELSE 'FAIL: NOT SECURITY DEFINER'
    END AS security_status
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_order_status_notification',
        'create_order_placed_notification'
    )
ORDER BY routine_name;

-- Check 4: Verify RLS policies exist
SELECT 
    '✅ RLS Policy Status' AS check_type,
    policyname,
    cmd AS operation
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
ORDER BY policyname;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT 
    '🎉 SETUP COMPLETE!' AS summary,
    'user_notifications table created with all policies and triggers' AS message,
    'Notifications will now work automatically!' AS status;

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
-- 1. Verify all checks above show ✅ PASS
-- 2. Test: As admin, change an order status to "shipped"
-- 3. Check: As customer, open notifications screen
-- 4. Expected: Notification appears immediately
-- ============================================================================

