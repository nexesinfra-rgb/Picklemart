-- ============================================================================
-- 🚀 FIX MISSING COLUMNS IN FCM TOKEN TABLES
-- ============================================================================
-- The fcm_worker expects 'last_used_at' column to exist in token tables.
-- ============================================================================

-- 1. Add last_used_at to admin_fcm_tokens
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_fcm_tokens' AND column_name = 'last_used_at') THEN
        ALTER TABLE public.admin_fcm_tokens ADD COLUMN last_used_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- 2. Add last_used_at to user_fcm_tokens
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_fcm_tokens' AND column_name = 'last_used_at') THEN
        ALTER TABLE public.user_fcm_tokens ADD COLUMN last_used_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;

-- 3. Verify
SELECT table_name, column_name 
FROM information_schema.columns 
WHERE table_name IN ('admin_fcm_tokens', 'user_fcm_tokens') 
AND column_name = 'last_used_at';
