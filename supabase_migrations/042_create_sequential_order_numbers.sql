-- Create Order Number Generation from Order ID
-- This migration creates a trigger function to generate order numbers
-- Format: ORD + last 4 characters of order UUID (e.g., ORD77c4)

-- Step 1: Create function to generate order number from order ID
-- This function extracts the last 4 characters from the UUID and prefixes with "ORD"
CREATE OR REPLACE FUNCTION generate_order_number_from_id()
RETURNS TRIGGER AS $$
BEGIN
    -- Extract last 4 characters from UUID (remove hyphens first, then take last 4)
    -- Format: ORD + last 4 hex characters of UUID
    NEW.order_number := 'ORD' || UPPER(RIGHT(REPLACE(NEW.id::text, '-', ''), 4));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create trigger that runs BEFORE INSERT to set order_number
-- This ensures order_number is set before the row is inserted
-- The trigger always sets order_number from the order ID (user-provided values are overridden)
CREATE TRIGGER set_order_number_trigger
    BEFORE INSERT ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION generate_order_number_from_id();

-- Step 3: Add comment for documentation
COMMENT ON FUNCTION generate_order_number_from_id() IS 'Trigger function that generates order numbers in the format ORD + last 4 hex characters of order UUID (e.g., ORD77c4)';

-- Step 4: Drop old sequence and function if they exist (from previous migration)
DROP FUNCTION IF EXISTS generate_order_number() CASCADE;
DROP SEQUENCE IF EXISTS order_number_seq CASCADE;
