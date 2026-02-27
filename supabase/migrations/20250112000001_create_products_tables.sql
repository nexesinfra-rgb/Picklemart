-- Create Products, Product Variants, and Product Measurements Tables
-- This migration creates the necessary tables for product management

-- Step 1: Create products table
CREATE TABLE IF NOT EXISTS PUBLIC.PRODUCTS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    NAME TEXT NOT NULL,
    SUBTITLE TEXT,
    DESCRIPTION TEXT,
    PRICE DECIMAL(10, 2) NOT NULL,
    BRAND TEXT,
    SKU TEXT UNIQUE,
    STOCK INTEGER DEFAULT 0,
    IMAGE_URL TEXT NOT NULL, -- Primary image
    IMAGES TEXT[] DEFAULT ARRAY[]::TEXT[], -- Array of image URLs
    CATEGORIES TEXT[] DEFAULT ARRAY[]::TEXT[], -- Array of category names
    TAGS TEXT[] DEFAULT ARRAY[]::TEXT[], -- Array of tags
    ALTERNATIVE_NAMES TEXT[] DEFAULT ARRAY[]::TEXT[], -- For search
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Create indexes for products table
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_NAME ON PUBLIC.PRODUCTS(NAME);

CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_SKU ON PUBLIC.PRODUCTS(SKU) WHERE SKU IS NOT NULL;

CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_CATEGORIES ON PUBLIC.PRODUCTS USING GIN(CATEGORIES);

CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_TAGS ON PUBLIC.PRODUCTS USING GIN(TAGS);

CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_IS_ACTIVE ON PUBLIC.PRODUCTS(IS_ACTIVE);

CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_CREATED_AT ON PUBLIC.PRODUCTS(CREATED_AT DESC);

-- Composite index for optimized category queries (fetchByCategory)
-- This index optimizes queries that filter by is_active, categories array, and order by created_at
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_ACTIVE_CATEGORIES_CREATED ON PUBLIC.PRODUCTS(IS_ACTIVE, CATEGORIES, CREATED_AT DESC)
WHERE IS_ACTIVE = TRUE;

-- Full-text search index on name, description, and alternative_names
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_FULLTEXT_SEARCH ON PUBLIC.PRODUCTS
USING GIN(TO_TSVECTOR('english', COALESCE(NAME, '')
                                 || ' '
                                 || COALESCE(DESCRIPTION, '')
                                    || ' '
                                    || ARRAY_TO_STRING(ALTERNATIVE_NAMES, ' ')));

-- Step 3: Create product_variants table
CREATE TABLE IF NOT EXISTS PUBLIC.PRODUCT_VARIANTS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE CASCADE,
    SKU TEXT NOT NULL,
    ATTRIBUTES JSONB NOT NULL DEFAULT '{}'::JSONB, -- e.g., {"Size": "M", "Color": "Black"}
    PRICE DECIMAL(10, 2) NOT NULL,
    STOCK INTEGER DEFAULT 0,
    IMAGES TEXT[] DEFAULT ARRAY[]::TEXT[], -- Variant-specific images
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(PRODUCT_ID, SKU)
);

-- Step 4: Create indexes for product_variants table
CREATE INDEX IF NOT EXISTS IDX_PRODUCT_VARIANTS_PRODUCT_ID ON PUBLIC.PRODUCT_VARIANTS(PRODUCT_ID);

CREATE INDEX IF NOT EXISTS IDX_PRODUCT_VARIANTS_SKU ON PUBLIC.PRODUCT_VARIANTS(SKU);

-- Step 5: Create product_measurements table
-- Note: Based on the code, this table stores pricing options for different units
CREATE TABLE IF NOT EXISTS PUBLIC.PRODUCT_MEASUREMENTS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE CASCADE,
    DEFAULT_UNIT TEXT NOT NULL, -- 'kg', 'gram', 'liter', 'ml', 'piece', etc.
    CATEGORY TEXT, -- 'weight', 'volume', 'count', 'length'
    PRICING_OPTIONS JSONB NOT NULL DEFAULT '[]'::JSONB, -- Array of pricing options
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(PRODUCT_ID)
);

-- Step 6: Create indexes for product_measurements table
CREATE INDEX IF NOT EXISTS IDX_PRODUCT_MEASUREMENTS_PRODUCT_ID ON PUBLIC.PRODUCT_MEASUREMENTS(PRODUCT_ID);

-- Step 7: Create updated_at trigger function (if not exists)
CREATE OR REPLACE FUNCTION PUBLIC.HANDLE_UPDATED_AT(
) RETURNS TRIGGER AS
    $$     BEGIN NEW.UPDATED_AT = NOW();
    RETURN NEW;
END;
$$     LANGUAGE PLPGSQL;
 
-- Step 8: Create triggers for updated_at on all tables
DROP   TRIGGER IF EXISTS SET_UPDATED_AT_PRODUCTS ON PUBLIC.PRODUCTS;
CREATE TRIGGER SET_UPDATED_AT_PRODUCTS BEFORE
UPDATE ON PUBLIC.PRODUCTS FOR EACH ROW EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT(
);
DROP TRIGGER IF EXISTS SET_UPDATED_AT_PRODUCT_VARIANTS ON PUBLIC.PRODUCT_VARIANTS;
CREATE TRIGGER SET_UPDATED_AT_PRODUCT_VARIANTS BEFORE
UPDATE ON PUBLIC.PRODUCT_VARIANTS FOR EACH ROW EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT(
);
DROP TRIGGER IF EXISTS SET_UPDATED_AT_PRODUCT_MEASUREMENTS ON PUBLIC.PRODUCT_MEASUREMENTS;
CREATE TRIGGER SET_UPDATED_AT_PRODUCT_MEASUREMENTS BEFORE
UPDATE ON PUBLIC.PRODUCT_MEASUREMENTS FOR EACH ROW EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT(
);
 
-- Step 9: Enable Row Level Security (RLS) on all tables
ALTER TABLE PUBLIC.PRODUCTS ENABLE ROW LEVEL SECURITY;
ALTER TABLE PUBLIC.PRODUCT_VARIANTS ENABLE ROW LEVEL SECURITY;
ALTER TABLE PUBLIC.PRODUCT_MEASUREMENTS ENABLE ROW LEVEL SECURITY;
 
-- Step 10: Create RLS policies for products table
-- Policy: Public can SELECT active products
DROP POLICY IF EXISTS "Public can view active products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Public can view active products" ON PUBLIC.PRODUCTS FOR
SELECT
    TO PUBLIC
    USING (IS_ACTIVE = TRUE);
 
-- Policy: Admins can SELECT all products
DROP POLICY IF EXISTS "Admins can view all products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Admins can view all products" ON PUBLIC.PRODUCTS FOR
SELECT
    TO AUTHENTICATED
    USING ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    ) );
 
-- Policy: Admins can INSERT products
DROP POLICY IF EXISTS "Admins can insert products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Admins can insert products" ON PUBLIC.PRODUCTS FOR INSERT TO AUTHENTICATED WITH CHECK (
    EXISTS ( SELECT 1 FROM PUBLIC.PROFILES WHERE ID = AUTH.UID() AND ROLE IN ('admin', 'manager', 'support') )
);
 
-- Policy: Admins can UPDATE products
DROP POLICY IF EXISTS "Admins can update products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Admins can update products" ON PUBLIC.PRODUCTS FOR
UPDATE TO AUTHENTICATED USING (
    EXISTS ( SELECT 1 FROM PUBLIC.PROFILES WHERE ID = AUTH.UID() AND ROLE IN ('admin', 'manager', 'support') )
) WITH CHECK (
    EXISTS ( SELECT 1 FROM PUBLIC.PROFILES WHERE ID = AUTH.UID() AND ROLE IN ('admin', 'manager', 'support') )
);
 
-- Policy: Admins can DELETE products (soft delete via is_active)
DROP POLICY IF EXISTS "Admins can delete products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Admins can delete products" ON PUBLIC.PRODUCTS FOR
DELETE TO AUTHENTICATED USING ( EXISTS (
    SELECT
        1
    FROM
        PUBLIC.PROFILES
    WHERE
        ID = AUTH.UID()
        AND ROLE IN ('admin', 'manager', 'support')
) );
 
-- Step 11: Create RLS policies for product_variants table
-- Policy: Public can SELECT variants for active products
DROP POLICY IF EXISTS "Public can view variants for active products" ON PUBLIC.PRODUCT_VARIANTS;
CREATE POLICY "Public can view variants for active products" ON PUBLIC.PRODUCT_VARIANTS FOR
SELECT
    TO PUBLIC
    USING ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PRODUCTS
        WHERE
            ID = PRODUCT_VARIANTS.PRODUCT_ID
            AND IS_ACTIVE = TRUE
    ) );
 
-- Policy: Admins can SELECT all variants
DROP POLICY IF EXISTS "Admins can view all variants" ON PUBLIC.PRODUCT_VARIANTS;
CREATE POLICY "Admins can view all variants" ON PUBLIC.PRODUCT_VARIANTS FOR
SELECT
    TO AUTHENTICATED
    USING ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    ) );
 
-- Policy: Admins can INSERT variants
DROP POLICY IF EXISTS "Admins can insert variants" ON PUBLIC.PRODUCT_VARIANTS;
CREATE POLICY "Admins can insert variants" ON PUBLIC.PRODUCT_VARIANTS FOR INSERT TO AUTHENTICATED WITH CHECK (
    EXISTS ( SELECT 1 FROM PUBLIC.PROFILES WHERE ID = AUTH.UID() AND ROLE IN ('admin', 'manager', 'support') )
);
 
-- Policy: Admins can UPDATE variants
DROP POLICY IF EXISTS "Admins can update variants" ON PUBLIC.PRODUCT_VARIANTS;
CREATE POLICY "Admins can update variants" ON PUBLIC.PRODUCT_VARIANTS FOR
UPDATE TO AUTHENTICATED USING (
    EXISTS ( SELECT 1 FROM PUBLIC.PROFILES WHERE ID = AUTH.UID() AND ROLE IN ('admin', 'manager', 'support') )
) WITH CHECK (
    EXISTS ( SELECT 1 FROM PUBLIC.PROFILES WHERE ID = AUTH.UID() AND ROLE IN ('admin', 'manager', 'support') )
);
 
-- Policy: Admins can DELETE variants
DROP POLICY IF EXISTS "Admins can delete variants" ON PUBLIC.PRODUCT_VARIANTS;
CREATE POLICY "Admins can delete variants" ON PUBLIC.PRODUCT_VARIANTS FOR
DELETE TO AUTHENTICATED USING ( EXISTS (
    SELECT
        1
    FROM
        PUBLIC.PROFILES
    WHERE
        ID = AUTH.UID()
        AND ROLE IN ('admin', 'manager', 'support')
) );
 
-- Step 12: Create RLS policies for product_measurements table
-- Policy: Public can SELECT measurements for active products
DROP POLICY IF EXISTS "Public can view measurements for active products" ON PUBLIC.PRODUCT_MEASUREMENTS;
CREATE POLICY "Public can view measurements for active products" ON PUBLIC.PRODUCT_MEASUREMENTS FOR
SELECT
    TO PUBLIC
    USING ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PRODUCTS
        WHERE
            ID = PRODUCT_MEASUREMENTS.PRODUCT_ID
            AND IS_ACTIVE = TRUE
    ) );
 
-- Policy: Admins can SELECT all measurements
DROP POLICY IF EXISTS "Admins can view all measurements" ON PUBLIC.PRODUCT_MEASUREMENTS;
CREATE POLICY "Admins can view all measurements" ON PUBLIC.PRODUCT_MEASUREMENTS FOR
SELECT
    TO AUTHENTICATED
    USING ( EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
    ) );
 
-- Policy: Admins can INSERT measurements
DROP POLICY IF EXISTS "Admins can insert measurements" ON PUBLIC.PRODUCT_MEASUREMENTS;
CREATE POLICY "Admins can insert measurements" ON PUBLIC.PRODUCT_MEASUREMENTS FOR INSERT TO AUTHENTICATED WITH CHECK (
    EXISTS ( SELECT 1 FROM PUBLIC.PROFILES WHERE ID = AUTH.UID() AND ROLE IN ('admin', 'manager', 'support') )
);
 
-- Policy: Admins can UPDATE measurements
DROP POLICY IF EXISTS "Admins can update measurements" ON PUBLIC.PRODUCT_MEASUREMENTS;
CREATE POLICY "Admins can update measurements" ON PUBLIC.PRODUCT_MEASUREMENTS FOR
UPDATE TO AUTHENTICATED USING (
    EXISTS ( SELECT 1 FROM PUBLIC.PROFILES WHERE ID = AUTH.UID() AND ROLE IN ('admin', 'manager', 'support') )
) WITH CHECK (
    EXISTS ( SELECT 1 FROM PUBLIC.PROFILES WHERE ID = AUTH.UID() AND ROLE IN ('admin', 'manager', 'support') )
);
 
-- Policy: Admins can DELETE measurements
DROP POLICY IF EXISTS "Admins can delete measurements" ON PUBLIC.PRODUCT_MEASUREMENTS;
CREATE POLICY "Admins can delete measurements" ON PUBLIC.PRODUCT_MEASUREMENTS FOR
DELETE TO AUTHENTICATED USING ( EXISTS (
    SELECT
        1
    FROM
        PUBLIC.PROFILES
    WHERE
        ID = AUTH.UID()
        AND ROLE IN ('admin', 'manager', 'support')
) );
 
-- Step 13: Verify tables were created
SELECT
    '✅ Products tables created successfully' AS STATUS,
    (
        SELECT
            COUNT(*)
        FROM
            INFORMATION_SCHEMA.TABLES
        WHERE
            TABLE_SCHEMA = 'public'
            AND TABLE_NAME = 'products'
    ) AS PRODUCTS_TABLE_EXISTS,
    (
        SELECT
            COUNT(*)
        FROM
            INFORMATION_SCHEMA.TABLES
        WHERE
            TABLE_SCHEMA = 'public'
            AND TABLE_NAME = 'product_variants'
    ) AS VARIANTS_TABLE_EXISTS,
    (
        SELECT
            COUNT(*)
        FROM
            INFORMATION_SCHEMA.TABLES
        WHERE
            TABLE_SCHEMA = 'public'
            AND TABLE_NAME = 'product_measurements'
    ) AS MEASUREMENTS_TABLE_EXISTS;









