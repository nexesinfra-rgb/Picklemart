-- Create user_fcm_tokens table for storing FCM tokens for regular users
-- This allows multiple devices per user and supports push notifications

-- Step 1: Create user_fcm_tokens table
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_info JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_token UNIQUE (user_id, fcm_token)
);

-- Step 2: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_fcm_token ON public.user_fcm_tokens(fcm_token);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_is_active ON public.user_fcm_tokens(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_created_at ON public.user_fcm_tokens(created_at DESC);

-- Step 3: Enable Row Level Security (RLS)
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies
-- Users can SELECT their own tokens
DROP POLICY IF EXISTS "Users can view their own FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can view their own FCM tokens" ON public.user_fcm_tokens
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role = 'user'
        )
    );

-- Users can INSERT their own tokens
DROP POLICY IF EXISTS "Users can insert their own FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can insert their own FCM tokens" ON public.user_fcm_tokens
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role = 'user'
        )
    );

-- Users can UPDATE their own tokens
DROP POLICY IF EXISTS "Users can update their own FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can update their own FCM tokens" ON public.user_fcm_tokens
    FOR UPDATE
    TO authenticated
    USING (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role = 'user'
        )
    )
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role = 'user'
        )
    );

-- Users can DELETE their own tokens
DROP POLICY IF EXISTS "Users can delete their own FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Users can delete their own FCM tokens" ON public.user_fcm_tokens
    FOR DELETE
    TO authenticated
    USING (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND role = 'user'
        )
    );

-- Service role can SELECT all tokens (for Edge Function)
DROP POLICY IF EXISTS "Service role can view all user FCM tokens" ON public.user_fcm_tokens;
CREATE POLICY "Service role can view all user FCM tokens" ON public.user_fcm_tokens
    FOR SELECT
    TO service_role
    USING (TRUE);

-- Step 5: Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_user_fcm_tokens_updated_at_trigger ON public.user_fcm_tokens;
CREATE TRIGGER update_user_fcm_tokens_updated_at_trigger
    BEFORE UPDATE ON public.user_fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_user_fcm_tokens_updated_at();

-- Step 7: Add comments
COMMENT ON TABLE public.user_fcm_tokens IS 'Stores FCM tokens for regular users to enable push notifications';
COMMENT ON COLUMN public.user_fcm_tokens.user_id IS 'Reference to user profile';
COMMENT ON COLUMN public.user_fcm_tokens.fcm_token IS 'Firebase Cloud Messaging token for the device';
COMMENT ON COLUMN public.user_fcm_tokens.device_info IS 'JSON object containing device information (platform, model, etc.)';
COMMENT ON COLUMN public.user_fcm_tokens.is_active IS 'Whether the token is currently active';

