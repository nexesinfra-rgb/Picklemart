-- Add paid_amount column to purchase_orders table
ALTER TABLE public.purchase_orders
ADD COLUMN IF NOT EXISTS paid_amount DECIMAL(10, 2) DEFAULT 0.0;

-- Comment on column
COMMENT ON COLUMN public.purchase_orders.paid_amount IS 'The amount paid towards this purchase order';
