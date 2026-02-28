-- ============================================================================
-- 🚀 FIX TRIGGER AMBIGUITY
-- ============================================================================
-- The error "column reference order_number is ambiguous" happens because 
-- both the table column and potential variables share the name.
-- We fix this by explicitly using NEW.order_number.
-- ============================================================================

-- 1. Fix Order Placed Notification Function
CREATE OR REPLACE FUNCTION public.create_order_placed_notification()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.user_notifications (user_id, type, title, message, order_id, is_read, is_pushed)
    VALUES (NEW.user_id, 'order_placed', 'Order Placed', 'Your order #' || NEW.order_number || ' has been placed.', NEW.id, FALSE, FALSE);
    RETURN NEW;
END;
$$;

-- 2. Fix Admin Order Notification Function
CREATE OR REPLACE FUNCTION public.create_admin_order_notification()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    admin_record RECORD;
BEGIN
    FOR admin_record IN 
        SELECT id FROM public.profiles WHERE role IN ('admin', 'manager')
    LOOP
        INSERT INTO public.user_notifications (user_id, type, title, message, order_id, is_read, is_pushed)
        VALUES (admin_record.id, 'order_placed', 'New Order Received', 'New order #' || NEW.order_number || ' received.', NEW.id, FALSE, FALSE);
    END LOOP;
    RETURN NEW;
END;
$$;

-- 3. Fix Order Status Notification Function
CREATE OR REPLACE FUNCTION public.create_order_status_notification()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    status_label TEXT;
BEGIN
    IF OLD.status = NEW.status THEN RETURN NEW; END IF;
    
    status_label := INITCAP(REPLACE(NEW.status, '_', ' '));
    
    INSERT INTO public.user_notifications (user_id, type, title, message, order_id, is_read, is_pushed)
    VALUES (NEW.user_id, 'order_status_changed', 'Order Update', 'Order #' || NEW.order_number || ' is now ' || status_label, NEW.id, FALSE, FALSE);
    RETURN NEW;
END;
$$;
