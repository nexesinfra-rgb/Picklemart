-- Make order_id nullable in payment_receipts table to allow general payments
ALTER TABLE PUBLIC.PAYMENT_RECEIPTS ALTER COLUMN ORDER_ID DROP NOT NULL;
