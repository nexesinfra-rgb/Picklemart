-- Update check constraint on transaction_type to include 'purchase'
-- This is required because the application uses 'purchase' type for purchase orders

-- Step 1: Drop the existing check constraint
ALTER TABLE PUBLIC.CREDIT_TRANSACTIONS 
    DROP CONSTRAINT IF EXISTS credit_transactions_transaction_type_check;

-- Step 2: Add the new check constraint with 'purchase' included
ALTER TABLE PUBLIC.CREDIT_TRANSACTIONS 
    ADD CONSTRAINT credit_transactions_transaction_type_check 
    CHECK (TRANSACTION_TYPE IN ('payin', 'payout', 'purchase'));

-- Step 3: Verify the change
SELECT 
    '✅ Transaction type check constraint updated successfully' as status,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'credit_transactions_transaction_type_check';
