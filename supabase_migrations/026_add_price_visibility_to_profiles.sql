-- Add price_visibility_enabled column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS price_visibility_enabled BOOLEAN DEFAULT false;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_price_visibility 
ON public.profiles(price_visibility_enabled);

