-- Add missing link_id column to cash_book table
-- This column is used to link cash book entries to payment records

ALTER TABLE public.cash_book ADD COLUMN IF NOT EXISTS link_id TEXT;
