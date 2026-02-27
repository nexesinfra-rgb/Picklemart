-- Add tax column to products and product_variants tables
-- Run this in Supabase SQL Editor

-- Step 1: Add tax column to products table
ALTER TABLE PUBLIC.PRODUCTS
ADD COLUMN IF NOT EXISTS TAX DECIMAL(5, 2);

-- Step 2: Add tax column to product_variants table
ALTER TABLE PUBLIC.PRODUCT_VARIANTS
ADD COLUMN IF NOT EXISTS TAX DECIMAL(5, 2);

-- Step 3: Add comments
COMMENT ON COLUMN PUBLIC.PRODUCTS.TAX IS 'Tax percentage applicable to selling price only';
COMMENT ON COLUMN PUBLIC.PRODUCT_VARIANTS.TAX IS 'Tax percentage applicable to selling price only';

