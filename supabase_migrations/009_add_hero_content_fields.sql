-- Add Hero Content Fields
-- This migration adds subtitle, cta_text, and cta_link columns to hero_images table

-- Step 1: Add new columns to hero_images table
ALTER TABLE public.hero_images
ADD COLUMN IF NOT EXISTS subtitle TEXT,
ADD COLUMN IF NOT EXISTS cta_text TEXT,
ADD COLUMN IF NOT EXISTS cta_link TEXT;

-- Step 2: Add comment to columns for documentation
COMMENT ON COLUMN public.hero_images.subtitle IS 'Subtitle text displayed on hero image';
COMMENT ON COLUMN public.hero_images.cta_text IS 'Call-to-action button text';
COMMENT ON COLUMN public.hero_images.cta_link IS 'Route name or URL for CTA button navigation';

