-- Add entity_name field to credit_transactions table
-- This allows tracking personal expenses (rent, bills, etc.) in addition to manufacturer transactions

-- Step 1: Make manufacturer_id nullable
ALTER TABLE PUBLIC.CREDIT_TRANSACTIONS 
    ALTER COLUMN MANUFACTURER_ID DROP NOT NULL;

-- Step 2: Add entity_name field
ALTER TABLE PUBLIC.CREDIT_TRANSACTIONS 
    ADD COLUMN IF NOT EXISTS ENTITY_NAME TEXT;

-- Step 3: Migrate existing data - populate entity_name from manufacturer names
UPDATE PUBLIC.CREDIT_TRANSACTIONS ct
SET ENTITY_NAME = COALESCE(m.name, m.business_name, 'Unknown')
FROM PUBLIC.MANUFACTURERS m
WHERE ct.MANUFACTURER_ID = m.ID
  AND ct.ENTITY_NAME IS NULL;

-- Step 4: Add constraint to ensure at least one of manufacturer_id or entity_name is provided
ALTER TABLE PUBLIC.CREDIT_TRANSACTIONS
    ADD CONSTRAINT CHECK_MANUFACTURER_OR_ENTITY 
    CHECK (MANUFACTURER_ID IS NOT NULL OR ENTITY_NAME IS NOT NULL);

-- Step 5: Add index on entity_name for performance
CREATE INDEX IF NOT EXISTS IDX_CREDIT_TRANSACTIONS_ENTITY_NAME 
    ON PUBLIC.CREDIT_TRANSACTIONS(ENTITY_NAME);

-- Step 6: Add composite index for entity-based queries
CREATE INDEX IF NOT EXISTS IDX_CREDIT_TRANSACTIONS_ENTITY_DATE 
    ON PUBLIC.CREDIT_TRANSACTIONS(ENTITY_NAME, TRANSACTION_DATE DESC)
    WHERE ENTITY_NAME IS NOT NULL;

-- Step 7: Update comments
COMMENT ON COLUMN PUBLIC.CREDIT_TRANSACTIONS.ENTITY_NAME IS 'Name of the entity (manufacturer name or personal expense category like rent, electricity, etc.)';
COMMENT ON COLUMN PUBLIC.CREDIT_TRANSACTIONS.MANUFACTURER_ID IS 'Manufacturer ID (nullable - can be null for personal expenses)';

-- Step 8: Verify changes
SELECT
    '✅ Credit transactions table updated successfully' AS STATUS,
    (
        SELECT COUNT(*)
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'public'
        AND TABLE_NAME = 'credit_transactions'
        AND COLUMN_NAME = 'entity_name'
    ) AS ENTITY_NAME_COLUMN_EXISTS,
    (
        SELECT COUNT(*)
        FROM PUBLIC.CREDIT_TRANSACTIONS
        WHERE ENTITY_NAME IS NOT NULL
    ) AS MIGRATED_RECORDS_COUNT;

