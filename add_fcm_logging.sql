-- ============================================================================
-- Add FCM Push Logging Table + Update Trigger Function
-- ============================================================================
-- This creates a log table to track push notification requests
-- and updates the trigger to log each request
-- ============================================================================

-- 1) Create the log table
CREATE TABLE IF NOT EXISTS public.fcm_push_log (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    notification_id UUID,
    target_user_id UUID,
    function_name TEXT,
    request_id BIGINT,
    payload JSONB,
    status TEXT DEFAULT 'pending'
);

-- Enable RLS but allow service role to write
ALTER TABLE public.fcm_push_log ENABLE ROW LEVEL SECURITY;

-- Policy: service role can do everything
DROP POLICY IF EXISTS "Service role can manage fcm_push_log" ON public.fcm_push_log;
CREATE POLICY "Service role can manage fcm_push_log" ON public.fcm_push_log
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Policy: authenticated can read (for debugging)
DROP POLICY IF EXISTS "Authenticated can read fcm_push_log" ON public.fcm_push_log;
CREATE POLICY "Authenticated can read fcm_push_log" ON public.fcm_push_log
    FOR SELECT TO authenticated USING (true);

COMMENT ON TABLE public.fcm_push_log IS 'Logs FCM push notification requests for debugging';

-- 2) Grant permissions
GRANT ALL ON public.fcm_push_log TO service_role;
GRANT SELECT ON public.fcm_push_log TO authenticated;

-- 3) Update the trigger function to also log
CREATE OR REPLACE FUNCTION public.send_fcm_push_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    supabase_url text := 'https://db.picklemart.cloud';
    function_name text;
    payload jsonb;
    response_id bigint;
    order_number text;

    has_user_tokens boolean;
    has_admin_tokens boolean;

    anon_key text := 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoiYW5vbiJ9.yW0F7LtfldnjQzwnlqQRsvoc2iKFycfgmUOPT1f-Sxs';
BEGIN
    -- Decide routing by real active tokens (more reliable than role)
    SELECT EXISTS(
      SELECT 1 FROM public.user_fcm_tokens
      WHERE user_id = NEW.user_id AND is_active = true
    ) INTO has_user_tokens;

    SELECT EXISTS(
      SELECT 1 FROM public.admin_fcm_tokens
      WHERE admin_id = NEW.user_id AND is_active = true
    ) INTO has_admin_tokens;

    IF has_user_tokens AND NOT has_admin_tokens THEN
      function_name := 'send-user-fcm-notification';
    ELSIF has_admin_tokens AND NOT has_user_tokens THEN
      function_name := 'send-admin-fcm-notification';
    ELSIF has_user_tokens AND has_admin_tokens THEN
      -- If both exist, prefer user function for user_notifications rows
      function_name := 'send-user-fcm-notification';
    ELSE
      -- No tokens at all -> nothing to send
      RAISE NOTICE '[FCM] No active tokens for user_id=% (skip push)', NEW.user_id;
      RETURN NEW;
    END IF;

    IF NEW.order_id IS NOT NULL THEN
        SELECT order_number INTO order_number
        FROM public.orders
        WHERE id = NEW.order_id
        LIMIT 1;
    END IF;

    payload := jsonb_build_object(
        'type', NEW.type,
        'title', NEW.title,
        'message', NEW.message,
        'order_id', COALESCE(NEW.order_id::text, NULL),
        'order_number', order_number,
        'conversation_id', COALESCE(NEW.conversation_id::text, NULL)
    );

    IF function_name = 'send-user-fcm-notification' THEN
        payload := payload || jsonb_build_object('user_id', NEW.user_id::text);
    END IF;

    -- LOG THE REQUEST (before sending)
    BEGIN
        INSERT INTO public.fcm_push_log (notification_id, target_user_id, function_name, payload, status)
        VALUES (NEW.id, NEW.user_id, function_name, payload, 'queued')
        RETURNING id INTO response_id;
    EXCEPTION WHEN OTHERS THEN
        -- Log insert failed, continue anyway
        RAISE WARNING '[FCM] Failed to log request: %', SQLERRM;
    END;

    -- Send the request
    BEGIN
        SELECT net.http_post(
            url := supabase_url || '/functions/v1/' || function_name,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || anon_key,
                'apikey', anon_key
            ),
            body := payload::text
        ) INTO response_id;

        -- Update log to success
        UPDATE public.fcm_push_log
        SET status = 'sent', request_id = response_id
        WHERE id = response_id;

        RAISE NOTICE '[FCM] queued request_id=% notification_id=% user_id=% type=% fn=%',
          response_id, NEW.id, NEW.user_id, NEW.type, function_name;
    EXCEPTION WHEN OTHERS THEN
        -- Update log to failed
        UPDATE public.fcm_push_log
        SET status = 'failed'
        WHERE id = response_id;

        RAISE WARNING '[FCM] net.http_post failed notification_id=% err=%', NEW.id, SQLERRM;
    END;

    RETURN NEW;
END;
$$;

-- Ensure trigger exists
DROP TRIGGER IF EXISTS trigger_send_fcm_push_notification ON public.user_notifications;
CREATE TRIGGER trigger_send_fcm_push_notification
AFTER INSERT ON public.user_notifications
FOR EACH ROW
EXECUTE FUNCTION public.send_fcm_push_notification();

-- Verify
SELECT '✅ FCM push logging added' AS status;

