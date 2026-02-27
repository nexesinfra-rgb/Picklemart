-- Add customer_id support to purchase_orders table
-- This allows purchase orders to be linked to either customers (stores) or manufacturers

-- Step 1: Add customer_id column (nullable)
ALTER TABLE PUBLIC.PURCHASE_ORDERS 
ADD COLUMN IF NOT EXISTS CUSTOMER_ID UUID REFERENCES PUBLIC.PROFILES(ID) ON DELETE SET NULL;

-- Step 2: Make manufacturer_id nullable (since we can have either customer or manufacturer)
ALTER TABLE PUBLIC.PURCHASE_ORDERS 
ALTER COLUMN MANUFACTURER_ID DROP NOT NULL;

-- Step 3: Add check constraint to ensure at least one of customer_id or manufacturer_id is set
ALTER TABLE PUBLIC.PURCHASE_ORDERS 
ADD CONSTRAINT CHECK_CUSTOMER_OR_MANUFACTURER 
CHECK (
  (CUSTOMER_ID IS NOT NULL AND MANUFACTURER_ID IS NULL) OR
  (CUSTOMER_ID IS NULL AND MANUFACTURER_ID IS NOT NULL)
);

-- Step 4: Create index for customer_id
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDERS_CUSTOMER_ID ON PUBLIC.PURCHASE_ORDERS(CUSTOMER_ID) WHERE CUSTOMER_ID IS NOT NULL;

-- Step 5: Add comment
COMMENT ON COLUMN PUBLIC.PURCHASE_ORDERS.CUSTOMER_ID IS 'Reference to customer/store (profiles table). Either customer_id or manufacturer_id must be set.';
COMMENT ON COLUMN PUBLIC.PURCHASE_ORDERS.MANUFACTURER_ID IS 'Reference to manufacturer. Either customer_id or manufacturer_id must be set.';

