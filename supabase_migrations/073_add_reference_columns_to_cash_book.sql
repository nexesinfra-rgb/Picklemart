-- Add reference_id and reference_type columns to cash_book table
-- This allows linking cashbook entries to specific transactions (Payment In/Out)

ALTER TABLE public.cash_book
ADD COLUMN IF NOT EXISTS reference_id text,
ADD COLUMN IF NOT EXISTS reference_type text;

-- Create index for faster querying by reference
CREATE INDEX IF NOT EXISTS cash_book_reference_idx ON public.cash_book(reference_id, reference_type);
