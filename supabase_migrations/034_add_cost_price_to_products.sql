-- Add cost_price column to products and product_variants tables
-- Run this in Supabase SQL Editor

-- Step 1: Add cost_price column to products table
ALTER TABLE PUBLIC.PRODUCTS
ADD COLUMN IF NOT EXISTS COST_PRICE DECIMAL(10, 2);

-- Step 2: Add cost_price column to product_variants table
ALTER TABLE PUBLIC.PRODUCT_VARIANTS
ADD COLUMN IF NOT EXISTS COST_PRICE DECIMAL(10, 2);

-- Step 3: Add comments
COMMENT ON COLUMN PUBLIC.PRODUCTS.COST_PRICE IS 'Cost price of the product (for manufacturer billing)';
COMMENT ON COLUMN PUBLIC.PRODUCT_VARIANTS.COST_PRICE IS 'Cost price of the product variant (for manufacturer billing)';

