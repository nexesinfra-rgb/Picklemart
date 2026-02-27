-- Create Purchase Orders and Purchase Order Items Tables
-- Run this in Supabase SQL Editor

-- Step 1: Create purchase_orders table
CREATE TABLE IF NOT EXISTS PUBLIC.PURCHASE_ORDERS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    PURCHASE_NUMBER TEXT NOT NULL UNIQUE,
    ORDER_ID UUID REFERENCES PUBLIC.ORDERS(ID) ON DELETE SET NULL,
    MANUFACTURER_ID UUID NOT NULL REFERENCES PUBLIC.MANUFACTURERS(ID) ON DELETE RESTRICT,
    STATUS TEXT NOT NULL DEFAULT 'pending' 
        CHECK (STATUS IN ('pending', 'confirmed', 'received', 'cancelled')),
    SUBTOTAL DECIMAL(10, 2) NOT NULL DEFAULT 0,
    TAX DECIMAL(10, 2) NOT NULL DEFAULT 0,
    SHIPPING DECIMAL(10, 2) NOT NULL DEFAULT 0,
    TOTAL DECIMAL(10, 2) NOT NULL DEFAULT 0,
    PURCHASE_DATE DATE NOT NULL DEFAULT CURRENT_DATE,
    EXPECTED_DELIVERY_DATE DATE,
    NOTES TEXT,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Create indexes for purchase_orders table
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDERS_PURCHASE_NUMBER ON PUBLIC.PURCHASE_ORDERS(PURCHASE_NUMBER);
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDERS_ORDER_ID ON PUBLIC.PURCHASE_ORDERS(ORDER_ID) WHERE ORDER_ID IS NOT NULL;
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDERS_MANUFACTURER_ID ON PUBLIC.PURCHASE_ORDERS(MANUFACTURER_ID);
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDERS_STATUS ON PUBLIC.PURCHASE_ORDERS(STATUS);
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDERS_PURCHASE_DATE ON PUBLIC.PURCHASE_ORDERS(PURCHASE_DATE DESC);
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDERS_CREATED_AT ON PUBLIC.PURCHASE_ORDERS(CREATED_AT DESC);

-- Step 3: Create purchase_order_items table
CREATE TABLE IF NOT EXISTS PUBLIC.PURCHASE_ORDER_ITEMS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    PURCHASE_ORDER_ID UUID NOT NULL REFERENCES PUBLIC.PURCHASE_ORDERS(ID) ON DELETE CASCADE,
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE RESTRICT,
    VARIANT_ID UUID REFERENCES PUBLIC.PRODUCT_VARIANTS(ID) ON DELETE SET NULL,
    MEASUREMENT_UNIT TEXT,
    NAME TEXT NOT NULL,
    IMAGE TEXT NOT NULL,
    QUANTITY INTEGER NOT NULL CHECK (QUANTITY > 0),
    UNIT_PRICE DECIMAL(10, 2) NOT NULL,
    TOTAL_PRICE DECIMAL(10, 2) NOT NULL,
    NOTES TEXT,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Step 4: Create indexes for purchase_order_items table
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDER_ITEMS_PURCHASE_ORDER_ID ON PUBLIC.PURCHASE_ORDER_ITEMS(PURCHASE_ORDER_ID);
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDER_ITEMS_PRODUCT_ID ON PUBLIC.PURCHASE_ORDER_ITEMS(PRODUCT_ID);
CREATE INDEX IF NOT EXISTS IDX_PURCHASE_ORDER_ITEMS_VARIANT_ID ON PUBLIC.PURCHASE_ORDER_ITEMS(VARIANT_ID) WHERE VARIANT_ID IS NOT NULL;

-- Step 5: Create updated_at trigger for purchase_orders
DROP TRIGGER IF EXISTS SET_UPDATED_AT_PURCHASE_ORDERS ON PUBLIC.PURCHASE_ORDERS;
CREATE TRIGGER SET_UPDATED_AT_PURCHASE_ORDERS BEFORE
UPDATE ON PUBLIC.PURCHASE_ORDERS FOR EACH ROW EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Step 6: Create updated_at trigger for purchase_order_items
DROP TRIGGER IF EXISTS SET_UPDATED_AT_PURCHASE_ORDER_ITEMS ON PUBLIC.PURCHASE_ORDER_ITEMS;
CREATE TRIGGER SET_UPDATED_AT_PURCHASE_ORDER_ITEMS BEFORE
UPDATE ON PUBLIC.PURCHASE_ORDER_ITEMS FOR EACH ROW EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Step 7: Create function to generate sequential purchase numbers
CREATE OR REPLACE FUNCTION PUBLIC.GENERATE_PURCHASE_NUMBER()
RETURNS TEXT AS $$
DECLARE
    next_number INTEGER;
    purchase_number TEXT;
BEGIN
    -- Get the next sequential number
    SELECT COALESCE(MAX(CAST(SUBSTRING(PURCHASE_NUMBER FROM '[0-9]+') AS INTEGER)), 0) + 1
    INTO next_number
    FROM PUBLIC.PURCHASE_ORDERS
    WHERE PURCHASE_NUMBER ~ '^PO[0-9]+$';
    
    -- Format as PO00001, PO00002, etc.
    purchase_number := 'PO' || LPAD(next_number::TEXT, 5, '0');
    
    RETURN purchase_number;
END;
$$ LANGUAGE PLPGSQL;

-- Step 8: Create trigger to auto-generate purchase_number on insert
CREATE OR REPLACE FUNCTION PUBLIC.SET_PURCHASE_NUMBER()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.PURCHASE_NUMBER IS NULL OR NEW.PURCHASE_NUMBER = '' THEN
        NEW.PURCHASE_NUMBER := PUBLIC.GENERATE_PURCHASE_NUMBER();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS TRIGGER_SET_PURCHASE_NUMBER ON PUBLIC.PURCHASE_ORDERS;
CREATE TRIGGER TRIGGER_SET_PURCHASE_NUMBER
    BEFORE INSERT ON PUBLIC.PURCHASE_ORDERS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.SET_PURCHASE_NUMBER();

-- Step 9: Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.PURCHASE_ORDERS ENABLE ROW LEVEL SECURITY;
ALTER TABLE PUBLIC.PURCHASE_ORDER_ITEMS ENABLE ROW LEVEL SECURITY;

-- Step 10: Create RLS policies for purchase_orders table
-- Admins can SELECT all purchase orders
DROP POLICY IF EXISTS "Admins can view all purchase orders" ON PUBLIC.PURCHASE_ORDERS;
CREATE POLICY "Admins can view all purchase orders" ON PUBLIC.PURCHASE_ORDERS FOR
SELECT
    TO AUTHENTICATED
    USING (
        EXISTS (
            SELECT
                1
            FROM
                PUBLIC.PROFILES
            WHERE
                ID = AUTH.UID()
                AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Admins can INSERT purchase orders
DROP POLICY IF EXISTS "Admins can insert purchase orders" ON PUBLIC.PURCHASE_ORDERS;
CREATE POLICY "Admins can insert purchase orders" ON PUBLIC.PURCHASE_ORDERS FOR INSERT TO AUTHENTICATED WITH CHECK (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
);

-- Admins can UPDATE purchase orders
DROP POLICY IF EXISTS "Admins can update purchase orders" ON PUBLIC.PURCHASE_ORDERS;
CREATE POLICY "Admins can update purchase orders" ON PUBLIC.PURCHASE_ORDERS FOR
UPDATE TO AUTHENTICATED USING (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
) WITH CHECK (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
);

-- Admins can DELETE purchase orders
DROP POLICY IF EXISTS "Admins can delete purchase orders" ON PUBLIC.PURCHASE_ORDERS;
CREATE POLICY "Admins can delete purchase orders" ON PUBLIC.PURCHASE_ORDERS FOR
DELETE TO AUTHENTICATED USING (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
);

-- Step 11: Create RLS policies for purchase_order_items table
-- Admins can SELECT all purchase order items
DROP POLICY IF EXISTS "Admins can view all purchase order items" ON PUBLIC.PURCHASE_ORDER_ITEMS;
CREATE POLICY "Admins can view all purchase order items" ON PUBLIC.PURCHASE_ORDER_ITEMS FOR
SELECT
    TO AUTHENTICATED
    USING (
        EXISTS (
            SELECT
                1
            FROM
                PUBLIC.PROFILES
            WHERE
                ID = AUTH.UID()
                AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Admins can INSERT purchase order items
DROP POLICY IF EXISTS "Admins can insert purchase order items" ON PUBLIC.PURCHASE_ORDER_ITEMS;
CREATE POLICY "Admins can insert purchase order items" ON PUBLIC.PURCHASE_ORDER_ITEMS FOR INSERT TO AUTHENTICATED WITH CHECK (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
);

-- Admins can UPDATE purchase order items
DROP POLICY IF EXISTS "Admins can update purchase order items" ON PUBLIC.PURCHASE_ORDER_ITEMS;
CREATE POLICY "Admins can update purchase order items" ON PUBLIC.PURCHASE_ORDER_ITEMS FOR
UPDATE TO AUTHENTICATED USING (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
) WITH CHECK (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
);

-- Admins can DELETE purchase order items
DROP POLICY IF EXISTS "Admins can delete purchase order items" ON PUBLIC.PURCHASE_ORDER_ITEMS;
CREATE POLICY "Admins can delete purchase order items" ON PUBLIC.PURCHASE_ORDER_ITEMS FOR
DELETE TO AUTHENTICATED USING (
    EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    )
);

-- Step 12: Add comments to tables
COMMENT ON TABLE PUBLIC.PURCHASE_ORDERS IS 'Stores purchase orders from manufacturers, linked to original sales orders';
COMMENT ON TABLE PUBLIC.PURCHASE_ORDER_ITEMS IS 'Stores individual items within each purchase order';

-- Step 13: Verify tables were created
SELECT
    '✅ Purchase orders tables created successfully' AS STATUS,
    (
        SELECT
            COUNT(*)
        FROM
            INFORMATION_SCHEMA.TABLES
        WHERE
            TABLE_SCHEMA = 'public'
            AND TABLE_NAME = 'purchase_orders'
    ) AS PURCHASE_ORDERS_TABLE_EXISTS,
    (
        SELECT
            COUNT(*)
        FROM
            INFORMATION_SCHEMA.TABLES
        WHERE
            TABLE_SCHEMA = 'public'
            AND TABLE_NAME = 'purchase_order_items'
    ) AS PURCHASE_ORDER_ITEMS_TABLE_EXISTS;

