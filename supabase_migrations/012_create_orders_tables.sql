-- Create Orders and Order Items Tables
-- Run this in Supabase SQL Editor

-- Step 1: Create orders table
CREATE TABLE IF NOT EXISTS PUBLIC.ORDERS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    ORDER_NUMBER TEXT NOT NULL UNIQUE,
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    STATUS TEXT NOT NULL DEFAULT 'confirmed' 
        CHECK (STATUS IN ('confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
    SUBTOTAL DECIMAL(10, 2) NOT NULL,
    SHIPPING DECIMAL(10, 2) NOT NULL DEFAULT 0,
    TAX DECIMAL(10, 2) NOT NULL DEFAULT 0,
    TOTAL DECIMAL(10, 2) NOT NULL,
    DELIVERY_ADDRESS JSONB NOT NULL,
    TRACKING_NUMBER TEXT,
    ESTIMATED_DELIVERY TIMESTAMPTZ,
    NOTES TEXT,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Create indexes for orders table
CREATE INDEX IF NOT EXISTS IDX_ORDERS_USER_ID ON PUBLIC.ORDERS(USER_ID);

CREATE INDEX IF NOT EXISTS IDX_ORDERS_ORDER_NUMBER ON PUBLIC.ORDERS(ORDER_NUMBER);

CREATE INDEX IF NOT EXISTS IDX_ORDERS_STATUS ON PUBLIC.ORDERS(STATUS);

CREATE INDEX IF NOT EXISTS IDX_ORDERS_CREATED_AT ON PUBLIC.ORDERS(CREATED_AT DESC);

-- Step 3: Create order_items table
CREATE TABLE IF NOT EXISTS PUBLIC.ORDER_ITEMS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    ORDER_ID UUID NOT NULL REFERENCES PUBLIC.ORDERS(ID) ON DELETE CASCADE,
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID),
    VARIANT_ID UUID REFERENCES PUBLIC.PRODUCT_VARIANTS(ID) ON DELETE SET NULL,
    MEASUREMENT_UNIT TEXT,
    NAME TEXT NOT NULL,
    IMAGE TEXT NOT NULL,
    PRICE DECIMAL(10, 2) NOT NULL,
    QUANTITY INTEGER NOT NULL CHECK (QUANTITY > 0),
    SIZE TEXT,
    COLOR TEXT,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Step 4: Create indexes for order_items table
CREATE INDEX IF NOT EXISTS IDX_ORDER_ITEMS_ORDER_ID ON PUBLIC.ORDER_ITEMS(ORDER_ID);

CREATE INDEX IF NOT EXISTS IDX_ORDER_ITEMS_PRODUCT_ID ON PUBLIC.ORDER_ITEMS(PRODUCT_ID);

CREATE INDEX IF NOT EXISTS IDX_ORDER_ITEMS_VARIANT_ID ON PUBLIC.ORDER_ITEMS(VARIANT_ID) WHERE VARIANT_ID IS NOT NULL;

-- Step 5: Create updated_at trigger function (if not exists)
CREATE OR REPLACE FUNCTION PUBLIC.HANDLE_UPDATED_AT(
) RETURNS TRIGGER AS
    $$     BEGIN NEW.UPDATED_AT = NOW();
    RETURN NEW;
END;
$$     LANGUAGE PLPGSQL;
 
-- Step 6: Create trigger for updated_at on orders table
DROP   TRIGGER IF EXISTS SET_UPDATED_AT_ORDERS ON PUBLIC.ORDERS;
CREATE TRIGGER SET_UPDATED_AT_ORDERS BEFORE
UPDATE ON PUBLIC.ORDERS FOR EACH ROW EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT(
);

-- Step 7: Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.ORDERS ENABLE ROW LEVEL SECURITY;
ALTER TABLE PUBLIC.ORDER_ITEMS ENABLE ROW LEVEL SECURITY;
 
-- Step 8: Create RLS policies for orders table
-- Users can SELECT their own orders
DROP POLICY IF EXISTS "Users can view their own orders" ON PUBLIC.ORDERS;
CREATE POLICY "Users can view their own orders" ON PUBLIC.ORDERS FOR
SELECT
    USING (AUTH.UID() = USER_ID);

-- Users can INSERT their own orders
DROP POLICY IF EXISTS "Users can create their own orders" ON PUBLIC.ORDERS;
CREATE POLICY "Users can create their own orders" ON PUBLIC.ORDERS FOR INSERT
    WITH CHECK (AUTH.UID() = USER_ID);

-- Users can UPDATE their own orders (for cancellation, etc.)
DROP POLICY IF EXISTS "Users can update their own orders" ON PUBLIC.ORDERS;
CREATE POLICY "Users can update their own orders" ON PUBLIC.ORDERS FOR
UPDATE
    USING (AUTH.UID() = USER_ID)
    WITH CHECK (AUTH.UID() = USER_ID);

-- Admins can SELECT all orders
DROP POLICY IF EXISTS "Admins can view all orders" ON PUBLIC.ORDERS;
CREATE POLICY "Admins can view all orders" ON PUBLIC.ORDERS FOR
SELECT
    USING ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    ) );

-- Admins can UPDATE all orders
DROP POLICY IF EXISTS "Admins can update all orders" ON PUBLIC.ORDERS;
CREATE POLICY "Admins can update all orders" ON PUBLIC.ORDERS FOR
UPDATE
    USING ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    ) )
    WITH CHECK ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    ) );

-- Step 9: Create RLS policies for order_items table
-- Users can SELECT items for their own orders
DROP POLICY IF EXISTS "Users can view items for their own orders" ON PUBLIC.ORDER_ITEMS;
CREATE POLICY "Users can view items for their own orders" ON PUBLIC.ORDER_ITEMS FOR
SELECT
    USING ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.ORDERS
        WHERE
            ORDERS.ID = ORDER_ITEMS.ORDER_ID
            AND ORDERS.USER_ID = AUTH.UID()
    ) );

-- Users can INSERT items for their own orders
DROP POLICY IF EXISTS "Users can create items for their own orders" ON PUBLIC.ORDER_ITEMS;
CREATE POLICY "Users can create items for their own orders" ON PUBLIC.ORDER_ITEMS FOR INSERT
    WITH CHECK ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.ORDERS
        WHERE
            ORDERS.ID = ORDER_ITEMS.ORDER_ID
            AND ORDERS.USER_ID = AUTH.UID()
    ) );

-- Admins can SELECT all order items
DROP POLICY IF EXISTS "Admins can view all order items" ON PUBLIC.ORDER_ITEMS;
CREATE POLICY "Admins can view all order items" ON PUBLIC.ORDER_ITEMS FOR
SELECT
    USING ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    ) );

-- Step 10: Add comments to tables
COMMENT ON TABLE PUBLIC.ORDERS IS 'Stores customer orders with delivery address, status, and pricing information.';
COMMENT ON TABLE PUBLIC.ORDER_ITEMS IS 'Stores individual items within each order. Supports products with variants and measurement-based pricing.';

-- Step 11: Verify tables were created
SELECT
    '✅ Orders tables created successfully' AS STATUS,
    (
        SELECT
            COUNT(*)
        FROM
            INFORMATION_SCHEMA.TABLES
        WHERE
            TABLE_SCHEMA = 'public'
            AND TABLE_NAME = 'orders'
    ) AS ORDERS_TABLE_EXISTS,
    (
        SELECT
            COUNT(*)
        FROM
            INFORMATION_SCHEMA.TABLES
        WHERE
            TABLE_SCHEMA = 'public'
            AND TABLE_NAME = 'order_items'
    ) AS ORDER_ITEMS_TABLE_EXISTS;

