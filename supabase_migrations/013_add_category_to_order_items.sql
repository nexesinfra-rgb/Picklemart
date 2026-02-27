-- Add category column to order_items table
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS category TEXT;
