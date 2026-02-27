-- Create User Notifications Table
-- Run this in Supabase SQL Editor

-- Step 1: Create user_notifications table
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

-- Step 2: Create indexes for user_notifications table
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_USER_ID ON PUBLIC.USER_NOTIFICATIONS(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_IS_READ ON PUBLIC.USER_NOTIFICATIONS(IS_READ);
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_CREATED_AT ON PUBLIC.USER_NOTIFICATIONS(CREATED_AT DESC);
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_ORDER_ID ON PUBLIC.USER_NOTIFICATIONS(ORDER_ID) WHERE ORDER_ID IS NOT NULL;

-- Step 3: Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.USER_NOTIFICATIONS ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies for user_notifications table
-- Users can SELECT their own notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Users can view their own notifications" ON PUBLIC.USER_NOTIFICATIONS
    FOR SELECT
    USING (AUTH.UID() = USER_ID);

-- Users can UPDATE their own notifications (to mark as read)
DROP POLICY IF EXISTS "Users can update their own notifications" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Users can update their own notifications" ON PUBLIC.USER_NOTIFICATIONS
    FOR UPDATE
    USING (AUTH.UID() = USER_ID)
    WITH CHECK (AUTH.UID() = USER_ID);

-- Allow INSERT for triggers (triggers use SECURITY DEFINER and bypass RLS)
-- Also allow users to insert their own notifications (though triggers handle this)
-- This policy ensures users can only insert notifications for themselves
DROP POLICY IF EXISTS "Users can insert their own notifications" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Users can insert their own notifications" ON PUBLIC.USER_NOTIFICATIONS
    FOR INSERT
    WITH CHECK (AUTH.UID() = USER_ID);

-- Step 5: Create function to create order placed notification
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ORDER_PLACED_NOTIFICATION()
RETURNS TRIGGER AS $$
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
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

-- Step 6: Create trigger for order placed notification
DROP TRIGGER IF EXISTS TRIGGER_ORDER_PLACED_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ORDER_PLACED_NOTIFICATION
    AFTER INSERT ON PUBLIC.ORDERS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.CREATE_ORDER_PLACED_NOTIFICATION();

-- Step 7: Create function to create order status changed notification
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION()
RETURNS TRIGGER AS $$
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
        ELSE STATUS_LABEL := NEW.STATUS;
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
END;
$$ LANGUAGE PLPGSQL SECURITY DEFINER;

-- Step 8: Create trigger for order status changed notification
DROP TRIGGER IF EXISTS TRIGGER_ORDER_STATUS_NOTIFICATION ON PUBLIC.ORDERS;
CREATE TRIGGER TRIGGER_ORDER_STATUS_NOTIFICATION
    AFTER UPDATE ON PUBLIC.ORDERS
    FOR EACH ROW
    WHEN (OLD.STATUS IS DISTINCT FROM NEW.STATUS)
    EXECUTE FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION();

-- Step 9: Add comment to table
COMMENT ON TABLE PUBLIC.USER_NOTIFICATIONS IS 'Stores user notifications for order events and status changes.';

-- Step 10: Verify table was created
SELECT
    '✅ User notifications table created successfully' AS STATUS,
    (
        SELECT
            COUNT(*)
        FROM
            INFORMATION_SCHEMA.TABLES
        WHERE
            TABLE_SCHEMA = 'public'
            AND TABLE_NAME = 'user_notifications'
    ) AS USER_NOTIFICATIONS_TABLE_EXISTS;

