-- Create admin_fcm_tokens table for storing FCM tokens for admin users
-- This allows multiple devices per admin and supports push notifications

-- Step 1: Create admin_fcm_tokens table
CREATE TABLE IF NOT EXISTS public.admin_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_info JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_admin_token UNIQUE (admin_id, fcm_token)
);

-- Step 2: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_admin_fcm_tokens_admin_id ON public.admin_fcm_tokens(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_fcm_tokens_fcm_token ON public.admin_fcm_tokens(fcm_token);
CREATE INDEX IF NOT EXISTS idx_admin_fcm_tokens_is_active ON public.admin_fcm_tokens(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_admin_fcm_tokens_created_at ON public.admin_fcm_tokens(created_at DESC);

-- Step 3: Enable Row Level Security (RLS)
ALTER TABLE public.admin_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies
-- Admins can SELECT their own tokens
DROP POLICY IF EXISTS "Admins can view their own FCM tokens" ON public.admin_fcm_tokens;
CREATE POLICY "Admins can view their own FCM tokens" ON public.admin_fcm_tokens
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = admin_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'manager', 'support')
        )
    );

-- Admins can INSERT their own tokens
DROP POLICY IF EXISTS "Admins can insert their own FCM tokens" ON public.admin_fcm_tokens;
CREATE POLICY "Admins can insert their own FCM tokens" ON public.admin_fcm_tokens
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = admin_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'manager', 'support')
        )
    );

-- Admins can UPDATE their own tokens
DROP POLICY IF EXISTS "Admins can update their own FCM tokens" ON public.admin_fcm_tokens;
CREATE POLICY "Admins can update their own FCM tokens" ON public.admin_fcm_tokens
    FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = admin_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'manager', 'support')
        )
    )
    WITH CHECK (
        auth.uid() = admin_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'manager', 'support')
        )
    );

-- Admins can DELETE their own tokens
DROP POLICY IF EXISTS "Admins can delete their own FCM tokens" ON public.admin_fcm_tokens;
CREATE POLICY "Admins can delete their own FCM tokens" ON public.admin_fcm_tokens
    FOR DELETE
    TO authenticated
    USING (
        auth.uid() = admin_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role IN ('admin', 'manager', 'support')
        )
    );

-- Service role can SELECT all tokens (for Edge Function)
DROP POLICY IF EXISTS "Service role can view all FCM tokens" ON public.admin_fcm_tokens;
CREATE POLICY "Service role can view all FCM tokens" ON public.admin_fcm_tokens
    FOR SELECT
    TO service_role
    USING (TRUE);

-- Step 5: Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_admin_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_admin_fcm_tokens_updated_at_trigger ON public.admin_fcm_tokens;
CREATE TRIGGER update_admin_fcm_tokens_updated_at_trigger
    BEFORE UPDATE ON public.admin_fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_admin_fcm_tokens_updated_at();

-- Step 7: Add comments
COMMENT ON TABLE public.admin_fcm_tokens IS 'Stores FCM tokens for admin users to enable push notifications';
COMMENT ON COLUMN public.admin_fcm_tokens.admin_id IS 'Reference to admin user profile';
COMMENT ON COLUMN public.admin_fcm_tokens.fcm_token IS 'Firebase Cloud Messaging token for the device';
COMMENT ON COLUMN public.admin_fcm_tokens.device_info IS 'JSON object containing device information (platform, model, etc.)';
COMMENT ON COLUMN public.admin_fcm_tokens.is_active IS 'Whether the token is currently active';

