-- Implement Sequential Order Numbers
-- This migration replaces the UUID-based order numbering with sequential numbers
-- Format: order_number = "4700", order_tag = "Order#4700"
-- Starts from 4700 and increments for each new order

-- Step 1: Drop the old UUID-based trigger and function
DROP TRIGGER IF EXISTS set_order_number_trigger ON public.orders;
DROP FUNCTION IF EXISTS generate_order_number_from_id();

-- Step 2: Create a sequence for order numbers starting from 4700
-- This will be used to generate sequential order numbers
CREATE SEQUENCE IF NOT EXISTS order_number_seq START WITH 4700;

-- Step 3: Create a new trigger function for sequential order numbers
-- This function generates sequential order numbers in the format:
-- order_number: "4700" (numeric string)
-- order_tag: "Order#4700" (human-readable format)
CREATE OR REPLACE FUNCTION generate_sequential_order_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Get next value from sequence for order_number
    NEW.order_number := nextval('order_number_seq')::text;
    
    -- Generate human-readable order_tag
    NEW.order_tag := 'Order#' || NEW.order_number;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create the trigger that runs BEFORE INSERT on orders table
-- This ensures every new order gets a sequential number automatically
CREATE TRIGGER set_order_number_trigger
    BEFORE INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION generate_sequential_order_number();

-- Step 5: Update all existing orders with sequential numbers
-- This assigns order numbers starting from 4700 based on creation date
-- Orders are numbered in the order they were created (oldest gets 4700)
UPDATE public.orders
SET 
    order_number = seq.seq::text,
    order_tag = 'Order#' || seq.seq::text
FROM (
    SELECT 
        id, 
        row_number() OVER (ORDER BY created_at) + 4699 as seq
    FROM public.orders
) AS seq
WHERE orders.id = seq.id;

-- Step 6: Set the sequence to continue after the highest existing order number
-- This ensures new orders continue the sequence correctly
SELECT setval('order_number_seq', COALESCE(
    (SELECT MAX((order_number)::int) FROM public.orders WHERE order_number ~ '^[0-9]+$'),
    4699
), true);

-- Documentation comment
COMMENT ON FUNCTION generate_sequential_order_number() IS 'Trigger function that generates sequential order numbers starting from 4700. Sets order_number to numeric value (e.g., "4700") and order_tag to human-readable format (e.g., "Order#4700")';

