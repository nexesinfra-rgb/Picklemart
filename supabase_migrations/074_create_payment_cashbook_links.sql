-- Create payment_cashbook_links table to link payments to cashbook entries
-- This enables cascade deletion when payments are deleted

CREATE TABLE IF NOT EXISTS payment_cashbook_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id TEXT NOT NULL,           -- ID from payment_receipts or credit_transactions
  payment_type TEXT NOT NULL,          -- 'payment_in' or 'payment_out'
  cash_book_entry_id TEXT NOT NULL,    -- ID from cash_book table
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Index for fast lookups by payment
CREATE INDEX IF NOT EXISTS payment_cashbook_links_payment_idx 
  ON payment_cashbook_links(payment_id, payment_type);

-- Index for fast lookups by cashbook entry
CREATE INDEX IF NOT EXISTS payment_cashbook_links_cashbook_idx 
  ON payment_cashbook_links(cash_book_entry_id);

-- Enable RLS
ALTER TABLE payment_cashbook_links ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (allow all operations for authenticated users)
DROP POLICY IF EXISTS "Allow all for authenticated users" ON payment_cashbook_links;
CREATE POLICY "Allow all for authenticated users" ON payment_cashbook_links
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
