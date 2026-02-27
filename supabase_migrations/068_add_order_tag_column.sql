-- Add order_tag column to orders table for serialized order numbering starting from 4700
-- This column will store human-readable order identifiers like "order#4700", "order#4701", etc.

-- Add order_tag column with unique constraint
ALTER TABLE orders ADD COLUMN order_tag TEXT UNIQUE;

-- Create index for fast lookups on order_tag
CREATE INDEX idx_orders_order_tag ON orders(order_tag);

-- Create a function to generate the next order tag
CREATE OR REPLACE FUNCTION generate_next_order_tag()
RETURNS TEXT AS $$
DECLARE
    next_num INTEGER;
    existing_tags TEXT[];
    new_tag TEXT;
BEGIN
    -- Get all existing order_tag values that match our pattern
    SELECT array_agg(order_tag) INTO existing_tags
    FROM orders
    WHERE order_tag IS NOT NULL
      AND order_tag LIKE 'order#%';

    -- Find the next available number starting from 4700
    next_num := 4700;
    
    IF existing_tags IS NOT NULL THEN
        WHILE ('order#' || next_num::TEXT) = ANY(existing_tags) LOOP
            next_num := next_num + 1;
        END LOOP;
    END IF;
    
    new_tag := 'order#' || next_num::TEXT;
    RETURN new_tag;
END;
$$ LANGUAGE plpgsql;

-- Add comment to explain the column purpose
COMMENT ON COLUMN orders.order_tag IS 'Human-readable serialized order number starting from 4700 (e.g., order#4700, order#4701)';


