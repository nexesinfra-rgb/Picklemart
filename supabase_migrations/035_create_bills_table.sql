-- Create Bills Table
-- Run this in Supabase SQL Editor

-- Step 1: Create bills table
CREATE TABLE IF NOT EXISTS PUBLIC.BILLS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    BILL_NUMBER TEXT NOT NULL UNIQUE,
    BILL_TYPE TEXT NOT NULL CHECK (BILL_TYPE IN ('user', 'manufacturer')),
    ORDER_ID UUID REFERENCES PUBLIC.ORDERS(ID) ON DELETE SET NULL,
    PRODUCT_ID UUID REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE SET NULL,
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    BILL_DATA JSONB NOT NULL DEFAULT '{}'::JSONB,
    PDF_URL TEXT,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Create indexes for bills table
CREATE INDEX IF NOT EXISTS IDX_BILLS_BILL_NUMBER ON PUBLIC.BILLS(BILL_NUMBER);
CREATE INDEX IF NOT EXISTS IDX_BILLS_BILL_TYPE ON PUBLIC.BILLS(BILL_TYPE);
CREATE INDEX IF NOT EXISTS IDX_BILLS_ORDER_ID ON PUBLIC.BILLS(ORDER_ID) WHERE ORDER_ID IS NOT NULL;
CREATE INDEX IF NOT EXISTS IDX_BILLS_PRODUCT_ID ON PUBLIC.BILLS(PRODUCT_ID) WHERE PRODUCT_ID IS NOT NULL;
CREATE INDEX IF NOT EXISTS IDX_BILLS_USER_ID ON PUBLIC.BILLS(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_BILLS_CREATED_AT ON PUBLIC.BILLS(CREATED_AT DESC);

-- Step 3: Create updated_at trigger
CREATE TRIGGER SET_UPDATED_AT_BILLS 
    BEFORE UPDATE ON PUBLIC.BILLS 
    FOR EACH ROW 
    EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Step 4: Enable RLS
ALTER TABLE PUBLIC.BILLS ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies
-- Policy: Users can view their own bills
CREATE POLICY "Users can view their own bills"
    ON PUBLIC.BILLS
    FOR SELECT
    USING (AUTH.UID() = USER_ID);

-- Policy: Admins can view all bills
CREATE POLICY "Admins can view all bills"
    ON PUBLIC.BILLS
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE = 'admin'
        )
    );

-- Policy: Admins can insert bills
CREATE POLICY "Admins can insert bills"
    ON PUBLIC.BILLS
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE = 'admin'
        )
    );

-- Policy: Admins can update bills
CREATE POLICY "Admins can update bills"
    ON PUBLIC.BILLS
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE = 'admin'
        )
    );

-- Policy: Admins can delete bills
CREATE POLICY "Admins can delete bills"
    ON PUBLIC.BILLS
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE = 'admin'
        )
    );

-- Step 6: Add comments
COMMENT ON TABLE PUBLIC.BILLS IS 'Stores generated bills for users and manufacturers';
COMMENT ON COLUMN PUBLIC.BILLS.BILL_TYPE IS 'Type of bill: user (selling price) or manufacturer (cost price)';
COMMENT ON COLUMN PUBLIC.BILLS.BILL_DATA IS 'JSONB containing all bill details (products, prices, customer info, order info, company info, tax)';

