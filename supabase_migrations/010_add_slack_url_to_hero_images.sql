-- Add Slack URL to Hero Images Table
-- This migration adds slack_url column to hero_images table for Slack URL support

-- Step 1: Add slack_url column to hero_images table
ALTER TABLE public.hero_images
ADD COLUMN IF NOT EXISTS slack_url TEXT;

-- Step 2: Add comment to column for documentation
COMMENT ON COLUMN public.hero_images.slack_url IS 'Slack URL (deep link or web URL) for CTA button navigation';

