-- Add is_deleted column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- Add index on is_deleted for faster filtering
CREATE INDEX IF NOT EXISTS idx_profiles_is_deleted ON public.profiles(is_deleted);

-- Add is_deleted column to manufacturers table
ALTER TABLE public.manufacturers 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;

-- Add index on is_deleted for faster filtering
CREATE INDEX IF NOT EXISTS idx_manufacturers_is_deleted ON public.manufacturers(is_deleted);
