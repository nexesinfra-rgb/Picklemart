-- Fix credit_transactions constraint to allow 'purchase' type
-- This is necessary because the app now uses 'purchase' as a transaction type

ALTER TABLE PUBLIC.CREDIT_TRANSACTIONS 
DROP CONSTRAINT IF EXISTS credit_transactions_transaction_type_check;

ALTER TABLE PUBLIC.CREDIT_TRANSACTIONS 
ADD CONSTRAINT credit_transactions_transaction_type_check 
CHECK (TRANSACTION_TYPE IN ('payin', 'payout', 'purchase'));
