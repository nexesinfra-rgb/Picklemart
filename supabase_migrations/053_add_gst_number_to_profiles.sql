-- Add GST number column to profiles table
-- This migration adds an optional gst_number field to store customer GST numbers

-- Step 1: Add gst_number column to profiles table (if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'gst_number'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN gst_number TEXT;
    END IF;
END $$;

-- Step 2: Create index for GST number lookups (if it doesn't exist)
CREATE INDEX IF NOT EXISTS idx_profiles_gst_number 
ON public.profiles(gst_number) 
WHERE gst_number IS NOT NULL;

-- Step 3: Add comment to document the column
COMMENT ON COLUMN public.profiles.gst_number IS 'Optional GST number for customer accounts (15 characters, format: 22AAAAA0000A1Z5)';

