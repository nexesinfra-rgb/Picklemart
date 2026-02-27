-- Add is_out_of_stock column to products table
-- This allows admins to mark products as unavailable (seasonal/unavailable)
-- regardless of stock quantity

-- Add the column with default value of false
ALTER TABLE PUBLIC.PRODUCTS
ADD COLUMN IF NOT EXISTS is_out_of_stock BOOLEAN DEFAULT FALSE;

-- Create index for query performance
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_IS_OUT_OF_STOCK 
ON PUBLIC.PRODUCTS(is_out_of_stock);

-- Update existing products to have is_out_of_stock = false by default
-- (This is already handled by the DEFAULT clause, but we'll ensure consistency)
UPDATE PUBLIC.PRODUCTS
SET is_out_of_stock = FALSE
WHERE is_out_of_stock IS NULL;

-- Add comment to document the column
COMMENT ON COLUMN PUBLIC.PRODUCTS.is_out_of_stock IS 
'Boolean flag to mark products as out of stock/unavailable. When true, product appears as unavailable to customers regardless of stock quantity.';

