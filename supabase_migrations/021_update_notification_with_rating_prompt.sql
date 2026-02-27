-- ============================================================================
-- Update Order Notification to Include Rating Prompt
-- ============================================================================
-- This migration updates the order status notification function to include
-- a rating prompt when orders are delivered

-- Update the order status notification function to include rating prompt for delivered orders
CREATE OR REPLACE FUNCTION PUBLIC.CREATE_ORDER_STATUS_NOTIFICATION()
RETURNS TRIGGER 
LANGUAGE PLPGSQL 
SECURITY DEFINER
SET SEARCH_PATH = PUBLIC
AS $$
DECLARE
    STATUS_LABEL TEXT;
    NOTIFICATION_MESSAGE TEXT;
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

    -- Build notification message
    NOTIFICATION_MESSAGE := 'Your order ' || NEW.ORDER_NUMBER || ' status has been updated to: ' || STATUS_LABEL;
    
    -- Add rating prompt for delivered orders
    IF NEW.STATUS = 'delivered' THEN
        NOTIFICATION_MESSAGE := NOTIFICATION_MESSAGE || '. Please rate the products you received!';
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
        NOTIFICATION_MESSAGE,
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

