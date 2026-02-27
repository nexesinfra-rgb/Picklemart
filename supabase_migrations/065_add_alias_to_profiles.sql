-- Add alias column to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS alias TEXT;
