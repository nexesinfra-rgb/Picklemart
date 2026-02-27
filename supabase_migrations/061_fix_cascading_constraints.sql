-- Fix cascading constraints and nullable audit fields
-- This migration ensures data integrity and prevents orphaned records

-- 1. Fix PURCHASE_ORDERS CUSTOMER_ID to ON DELETE CASCADE
-- This ensures that when a customer is deleted, their purchase orders are also deleted,
-- preventing violations of the CHECK_CUSTOMER_OR_MANUFACTURER constraint.
ALTER TABLE PUBLIC.PURCHASE_ORDERS 
DROP CONSTRAINT IF EXISTS PURCHASE_ORDERS_CUSTOMER_ID_FKEY;

ALTER TABLE PUBLIC.PURCHASE_ORDERS 
ADD CONSTRAINT PURCHASE_ORDERS_CUSTOMER_ID_FKEY 
FOREIGN KEY (CUSTOMER_ID) 
REFERENCES PUBLIC.PROFILES(ID) 
ON DELETE CASCADE;

-- 2. Fix PAYMENT_RECEIPTS CREATED_BY to be nullable
-- The previous definition had NOT NULL and ON DELETE SET NULL which is incompatible.
ALTER TABLE PUBLIC.PAYMENT_RECEIPTS 
ALTER COLUMN CREATED_BY DROP NOT NULL;

-- 3. Fix CREDIT_TRANSACTIONS CREATED_BY to be nullable
-- The previous definition had NOT NULL and ON DELETE SET NULL which is incompatible.
ALTER TABLE PUBLIC.CREDIT_TRANSACTIONS 
ALTER COLUMN CREATED_BY DROP NOT NULL;

-- 4. Ensure all other profiles references are CASCADE where appropriate
-- Checked: orders, bills, cart_items, product_views, user_sessions, wishlist, notifications, chat, ratings.
-- These are already CASCADE in their respective creation scripts.

-- 5. Add a comment explaining the changes
COMMENT ON COLUMN PUBLIC.PURCHASE_ORDERS.CUSTOMER_ID IS 'Reference to customer/store (profiles table). ON DELETE CASCADE to maintain CHECK_CUSTOMER_OR_MANUFACTURER.';
COMMENT ON COLUMN PUBLIC.PAYMENT_RECEIPTS.CREATED_BY IS 'Admin who created the receipt. Nullable to allow deletion of admin profiles while keeping records.';
COMMENT ON COLUMN PUBLIC.CREDIT_TRANSACTIONS.CREATED_BY IS 'Admin who created the transaction. Nullable to allow deletion of admin profiles while keeping records.';
