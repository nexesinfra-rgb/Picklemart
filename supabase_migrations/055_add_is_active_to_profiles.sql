-- Add is_active column to profiles table
-- This migration adds an is_active boolean field to manage user status

-- Step 1: Add is_active column to profiles table (if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
END $$;

-- Step 2: Add comment to document the column
COMMENT ON COLUMN public.profiles.is_active IS 'Status of the user account. If false, user access should be restricted.';
