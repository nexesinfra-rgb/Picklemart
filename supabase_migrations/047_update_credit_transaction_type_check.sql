-- Migration to add 'purchase' to the allowed transaction types in credit_transactions table

-- Drop the existing check constraint
ALTER TABLE public.credit_transactions
DROP CONSTRAINT IF EXISTS credit_transactions_transaction_type_check;

-- Add the new check constraint including 'purchase'
ALTER TABLE public.credit_transactions
ADD CONSTRAINT credit_transactions_transaction_type_check
CHECK (transaction_type IN ('payin', 'payout', 'purchase'));
