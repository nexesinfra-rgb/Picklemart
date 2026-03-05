-- Fix get_cash_book_totals RPC function
-- Drop and recreate with correct return types

DROP FUNCTION IF EXISTS get_cash_book_totals();

CREATE OR REPLACE FUNCTION get_cash_book_totals()
RETURNS TABLE(
  total_payin BIGINT,
  total_payout BIGINT,
  balance BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(CASE WHEN entry_type = 'payin' THEN amount ELSE 0 END), 0)::BIGINT AS total_payin,
    COALESCE(SUM(CASE WHEN entry_type = 'payout' THEN amount ELSE 0 END), 0)::BIGINT AS total_payout,
    COALESCE(SUM(CASE WHEN entry_type = 'payin' THEN amount ELSE -amount END), 0)::BIGINT AS balance
  FROM cash_book;
END;
$$;
