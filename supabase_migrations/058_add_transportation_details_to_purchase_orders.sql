-- Add transportation/manufacturer details columns to purchase_orders table
ALTER TABLE public.purchase_orders
ADD COLUMN IF NOT EXISTS delivery_location TEXT,
ADD COLUMN IF NOT EXISTS transportation_name TEXT,
ADD COLUMN IF NOT EXISTS transportation_phone TEXT;

-- Add comments for clarity
COMMENT ON COLUMN public.purchase_orders.delivery_location IS 'The location/address of the manufacturer/delivery';
COMMENT ON COLUMN public.purchase_orders.transportation_name IS 'The name of the manufacturer or transportation service';
COMMENT ON COLUMN public.purchase_orders.transportation_phone IS 'The contact phone number for the manufacturer/transportation';
