-- Create Credit Transactions Table
-- This migration creates the credit_transactions table for tracking payin/payout between admin and manufacturers

-- Step 1: Create credit_transactions table
CREATE TABLE IF NOT EXISTS PUBLIC.CREDIT_TRANSACTIONS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    MANUFACTURER_ID UUID NOT NULL REFERENCES PUBLIC.MANUFACTURERS(ID) ON DELETE CASCADE,
    TRANSACTION_TYPE TEXT NOT NULL CHECK (TRANSACTION_TYPE IN ('payin', 'payout')),
    AMOUNT DECIMAL(10,2) NOT NULL CHECK (AMOUNT > 0),
    BALANCE_AFTER DECIMAL(10,2) NOT NULL,
    DESCRIPTION TEXT,
    REFERENCE_NUMBER TEXT, -- Bill number, order number, etc.
    PAYMENT_METHOD TEXT CHECK (PAYMENT_METHOD IN ('cash', 'bank_transfer', 'cheque', 'upi', 'other')),
    TRANSACTION_DATE TIMESTAMPTZ DEFAULT NOW(),
    CREATED_BY UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE SET NULL,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Create indexes for optimization
CREATE INDEX IF NOT EXISTS IDX_CREDIT_TRANSACTIONS_MANUFACTURER_ID ON PUBLIC.CREDIT_TRANSACTIONS(MANUFACTURER_ID);
CREATE INDEX IF NOT EXISTS IDX_CREDIT_TRANSACTIONS_TYPE ON PUBLIC.CREDIT_TRANSACTIONS(TRANSACTION_TYPE);
CREATE INDEX IF NOT EXISTS IDX_CREDIT_TRANSACTIONS_DATE ON PUBLIC.CREDIT_TRANSACTIONS(TRANSACTION_DATE DESC);
CREATE INDEX IF NOT EXISTS IDX_CREDIT_TRANSACTIONS_CREATED_BY ON PUBLIC.CREDIT_TRANSACTIONS(CREATED_BY);

-- Composite index for manufacturer transactions
CREATE INDEX IF NOT EXISTS IDX_CREDIT_TRANSACTIONS_MANUFACTURER_DATE ON PUBLIC.CREDIT_TRANSACTIONS(MANUFACTURER_ID, TRANSACTION_DATE DESC);

-- Step 3: Create updated_at trigger
DROP TRIGGER IF EXISTS SET_UPDATED_AT_CREDIT_TRANSACTIONS ON PUBLIC.CREDIT_TRANSACTIONS;
CREATE TRIGGER SET_UPDATED_AT_CREDIT_TRANSACTIONS 
    BEFORE UPDATE ON PUBLIC.CREDIT_TRANSACTIONS 
    FOR EACH ROW 
    EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Step 4: Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.CREDIT_TRANSACTIONS ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies
-- Policy: Admins can view all credit transactions
DROP POLICY IF EXISTS "Admins can view all credit transactions" ON PUBLIC.CREDIT_TRANSACTIONS;
CREATE POLICY "Admins can view all credit transactions"
    ON PUBLIC.CREDIT_TRANSACTIONS
    FOR SELECT
    TO AUTHENTICATED
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Policy: Admins can insert credit transactions
DROP POLICY IF EXISTS "Admins can insert credit transactions" ON PUBLIC.CREDIT_TRANSACTIONS;
CREATE POLICY "Admins can insert credit transactions"
    ON PUBLIC.CREDIT_TRANSACTIONS
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Policy: Admins can update credit transactions
DROP POLICY IF EXISTS "Admins can update credit transactions" ON PUBLIC.CREDIT_TRANSACTIONS;
CREATE POLICY "Admins can update credit transactions"
    ON PUBLIC.CREDIT_TRANSACTIONS
    FOR UPDATE
    TO AUTHENTICATED
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Policy: Admins can delete credit transactions
DROP POLICY IF EXISTS "Admins can delete credit transactions" ON PUBLIC.CREDIT_TRANSACTIONS;
CREATE POLICY "Admins can delete credit transactions"
    ON PUBLIC.CREDIT_TRANSACTIONS
    FOR DELETE
    TO AUTHENTICATED
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Step 6: Add comments
COMMENT ON TABLE PUBLIC.CREDIT_TRANSACTIONS IS 'Stores credit transactions (payin/payout) between admin and manufacturers';
COMMENT ON COLUMN PUBLIC.CREDIT_TRANSACTIONS.TRANSACTION_TYPE IS 'Type: payin (admin pays manufacturer) or payout (manufacturer pays admin)';
COMMENT ON COLUMN PUBLIC.CREDIT_TRANSACTIONS.BALANCE_AFTER IS 'Running balance after this transaction';
COMMENT ON COLUMN PUBLIC.CREDIT_TRANSACTIONS.REFERENCE_NUMBER IS 'Reference to bill number, order number, etc.';

-- Step 7: Verify table was created
SELECT
    '✅ Credit transactions table created successfully' AS STATUS,
    (
        SELECT COUNT(*)
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'public'
        AND TABLE_NAME = 'credit_transactions'
    ) AS CREDIT_TRANSACTIONS_TABLE_EXISTS;

