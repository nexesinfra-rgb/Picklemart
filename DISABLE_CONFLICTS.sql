-- ============================================================================
-- 🚀 DISABLE CONFLICTING TRIGGERS (FCM ONLY) - FORCE CLEANUP
-- ============================================================================
-- We need to drop the old/conflicting trigger 'send_fcm_push_notification'
-- and any triggers that depend on it, so our new system works.
-- ============================================================================

DO $$
BEGIN
    -- 1. Drop conflicting triggers on ORDERS table
    DROP TRIGGER IF EXISTS on_order_created ON public.orders;
    DROP TRIGGER IF EXISTS trigger_send_fcm_push_notification ON public.orders;
    
    -- 2. Drop conflicting triggers on USER_NOTIFICATIONS table
    -- (The error logs showed a dependency here too)
    DROP TRIGGER IF EXISTS trigger_send_fcm_push_notification ON public.user_notifications;
    DROP TRIGGER IF EXISTS on_notification_created ON public.user_notifications;

    -- 3. Drop the old function with CASCADE
    -- This will automatically remove any other triggers linked to it
    DROP FUNCTION IF EXISTS public.send_fcm_push_notification() CASCADE;

    -- 4. Ensure our new triggers are definitely enabled
    ALTER TABLE public.orders ENABLE TRIGGER trigger_order_placed_notification;
    ALTER TABLE public.orders ENABLE TRIGGER trigger_admin_order_notification;
    ALTER TABLE public.orders ENABLE TRIGGER trigger_order_status_notification;

END $$;
