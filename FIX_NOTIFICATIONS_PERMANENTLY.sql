-- ============================================================================
-- 🚀 PERMANENT FIX: Notifications Will Work Forever (User & Admin)
-- ============================================================================

-- 1. Ensure user_notifications table exists
CREATE TABLE IF NOT EXISTS public.user_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add missing columns safely
DO $$
BEGIN
    -- Add is_pushed column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'is_pushed') THEN
        ALTER TABLE public.user_notifications ADD COLUMN is_pushed BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add conversation_id column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'conversation_id') THEN
        ALTER TABLE public.user_notifications ADD COLUMN conversation_id UUID;
    END IF;
END $$;

-- 3. Ensure indexes
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON public.user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_is_pushed ON public.user_notifications(is_pushed) WHERE is_pushed = FALSE;

-- 4. Create FCM Token Tables
CREATE TABLE IF NOT EXISTS public.admin_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_info JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(admin_id, fcm_token)
);

CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_info JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

-- 5. Create Function: Notify User on Order Placed
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

-- 6. Create Trigger: Notify User on Order Placed
DROP TRIGGER IF EXISTS trigger_order_placed_notification ON public.orders;
CREATE TRIGGER trigger_order_placed_notification
    AFTER INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.create_order_placed_notification();

-- 7. Create Function: Notify ALL Admins on New Order
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

-- 8. Create Trigger: Notify Admins on New Order
DROP TRIGGER IF EXISTS trigger_admin_order_notification ON public.orders;
CREATE TRIGGER trigger_admin_order_notification
    AFTER INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.create_admin_order_notification();

-- 9. Create Function: Notify User on Order Status Change
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

-- 10. Create Trigger: Notify User on Status Change
DROP TRIGGER IF EXISTS trigger_order_status_notification ON public.orders;
CREATE TRIGGER trigger_order_status_notification
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.create_order_status_notification();

-- 11. Enable Realtime
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'user_notifications') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_notifications;
    END IF;
END $$;

-- 12. Grant Permissions
GRANT ALL ON public.user_notifications TO authenticated;
GRANT ALL ON public.user_notifications TO service_role;
GRANT ALL ON public.admin_fcm_tokens TO authenticated;
GRANT ALL ON public.user_fcm_tokens TO authenticated;
