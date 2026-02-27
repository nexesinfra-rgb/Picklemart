-- Modify Cart Items Table to Allow Multiple Entries
-- Run this in Supabase SQL Editor
--
-- This migration removes the unique constraint to allow multiple entries of the same product,
-- and adds a unique identifier for each cart entry to track individual additions.

-- Step 1: Add a new column for entry identifier
ALTER TABLE PUBLIC.CART_ITEMS ADD COLUMN IF NOT EXISTS ENTRY_ID UUID DEFAULT GEN_RANDOM_UUID();

-- Step 2: Create an index on the new entry_id column
CREATE INDEX IF NOT EXISTS IDX_CART_ITEMS_ENTRY_ID ON PUBLIC.CART_ITEMS(ENTRY_ID);

-- Step 3: Update existing entries to have unique entry_ids (for data consistency)
UPDATE PUBLIC.CART_ITEMS 
SET ENTRY_ID = GEN_RANDOM_UUID()
WHERE ENTRY_ID IS NULL;

-- Step 4: Create a new unique constraint that includes ENTRY_ID
-- This allows multiple entries of the same product but ensures each entry has a unique ID
DROP INDEX IF EXISTS IDX_CART_ITEMS_USER_ID_PRODUCT_ID_VARIANT_ID_MEASUREMENT_UNIT;
ALTER TABLE PUBLIC.CART_ITEMS DROP CONSTRAINT IF EXISTS CART_ITEMS_USER_ID_PRODUCT_ID_VARIANT_ID_MEASUREMENT_UNIT_key;

-- Step 5: Create a new unique constraint that allows multiple entries of the same product
-- but prevents duplicate entry_ids within the same user's cart
CREATE UNIQUE INDEX IDX_CART_ITEMS_USER_ENTRY_ID ON PUBLIC.CART_ITEMS(USER_ID, ENTRY_ID);

-- Step 6: Create a partial unique index for product tracking (optional)
-- This allows you to easily find all entries for a specific product/variant combination
CREATE INDEX IF NOT EXISTS IDX_CART_ITEMS_USER_PRODUCT_VARIANT_MEASUREMENT ON PUBLIC.CART_ITEMS(USER_ID, PRODUCT_ID, VARIANT_ID, MEASUREMENT_UNIT);

-- Step 7: Add comment to the new column
COMMENT ON COLUMN PUBLIC.CART_ITEMS.ENTRY_ID IS 'Unique identifier for each cart entry. Allows tracking individual product additions even for the same product.';

-- Step 8: Create a view to help with queries that group by product (for totals)
DROP VIEW IF EXISTS CART_ITEM_SUMMARY;
CREATE VIEW CART_ITEM_SUMMARY AS
SELECT 
    USER_ID,
    PRODUCT_ID,
    VARIANT_ID,
    MEASUREMENT_UNIT,
    SUM(QUANTITY) AS TOTAL_QUANTITY,
    COUNT(ENTRY_ID) AS ENTRY_COUNT,
    CREATED_AT,
    UPDATED_AT
FROM PUBLIC.CART_ITEMS
GROUP BY 
    USER_ID, 
    PRODUCT_ID, 
    VARIANT_ID, 
    MEASUREMENT_UNIT, 
    CREATED_AT, 
    UPDATED_AT;

-- Step 9: Grant permissions on the new view (if needed)
-- GRANT SELECT ON CART_ITEM_SUMMARY TO PUBLIC;
