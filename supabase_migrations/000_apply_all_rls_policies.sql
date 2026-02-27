-- ============================================================================
-- Consolidated RLS Migration Script
-- Apply all tables and RLS policies in correct order
-- Run this in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- PART 1: PROFILES TABLE
-- ============================================================================

-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    mobile TEXT,
    display_mobile TEXT,
    avatar_url TEXT,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'manager', 'support')),
    gender TEXT CHECK (gender IN ('male', 'female', 'others', 'prefer_not_to_say')),
    date_of_birth DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_mobile ON public.profiles(mobile);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
DROP POLICY IF EXISTS profiles_select_admin ON public.profiles;
DROP POLICY IF EXISTS profiles_update_admin ON public.profiles;

-- RLS Policy: Users can SELECT their own profile
CREATE POLICY profiles_select_own ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

-- RLS Policy: Users can INSERT their own profile
CREATE POLICY profiles_insert_own ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- RLS Policy: Users can UPDATE their own profile
CREATE POLICY profiles_update_own ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at on profile updates
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.profiles TO authenticated;

-- ============================================================================
-- PART 2: IS_ADMIN FUNCTION (Prevents RLS Recursion)
-- ============================================================================

-- Create a security definer function to check admin role
-- This function bypasses RLS, preventing infinite recursion
CREATE OR REPLACE FUNCTION PUBLIC.IS_ADMIN(
    USER_ID UUID
) RETURNS BOOLEAN 
LANGUAGE PLPGSQL 
SECURITY DEFINER 
SET SEARCH_PATH = PUBLIC 
AS $$
BEGIN 
    RETURN EXISTS (
        SELECT 1
        FROM PUBLIC.PROFILES
        WHERE ID = USER_ID
        AND ROLE IN ('admin', 'manager', 'support')
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION PUBLIC.IS_ADMIN(UUID) TO AUTHENTICATED;

-- Recreate admin policies using the security definer function
-- This prevents infinite recursion because the function bypasses RLS
CREATE POLICY profiles_select_admin ON PUBLIC.PROFILES 
    FOR SELECT
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

CREATE POLICY profiles_update_admin ON PUBLIC.PROFILES 
    FOR UPDATE 
    USING (PUBLIC.IS_ADMIN(AUTH.UID())) 
    WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));

-- ============================================================================
-- PART 3: PRODUCTS TABLES
-- ============================================================================

-- Create products table
CREATE TABLE IF NOT EXISTS PUBLIC.PRODUCTS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    NAME TEXT NOT NULL,
    SUBTITLE TEXT,
    DESCRIPTION TEXT,
    PRICE DECIMAL(10, 2) NOT NULL,
    BRAND TEXT,
    SKU TEXT UNIQUE,
    STOCK INTEGER DEFAULT 0,
    IMAGE_URL TEXT NOT NULL,
    IMAGES TEXT[] DEFAULT ARRAY[]::TEXT[],
    CATEGORIES TEXT[] DEFAULT ARRAY[]::TEXT[],
    TAGS TEXT[] DEFAULT ARRAY[]::TEXT[],
    ALTERNATIVE_NAMES TEXT[] DEFAULT ARRAY[]::TEXT[],
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for products table
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_NAME ON PUBLIC.PRODUCTS(NAME);
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_SKU ON PUBLIC.PRODUCTS(SKU) WHERE SKU IS NOT NULL;
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_CATEGORIES ON PUBLIC.PRODUCTS USING GIN(CATEGORIES);
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_TAGS ON PUBLIC.PRODUCTS USING GIN(TAGS);
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_IS_ACTIVE ON PUBLIC.PRODUCTS(IS_ACTIVE);
CREATE INDEX IF NOT EXISTS IDX_PRODUCTS_CREATED_AT ON PUBLIC.PRODUCTS(CREATED_AT DESC);

-- Create product_variants table
CREATE TABLE IF NOT EXISTS PUBLIC.PRODUCT_VARIANTS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE CASCADE,
    SKU TEXT NOT NULL,
    ATTRIBUTES JSONB NOT NULL DEFAULT '{}'::JSONB,
    PRICE DECIMAL(10, 2) NOT NULL,
    STOCK INTEGER DEFAULT 0,
    IMAGES TEXT[] DEFAULT ARRAY[]::TEXT[],
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(PRODUCT_ID, SKU)
);

-- Create indexes for product_variants table
CREATE INDEX IF NOT EXISTS IDX_PRODUCT_VARIANTS_PRODUCT_ID ON PUBLIC.PRODUCT_VARIANTS(PRODUCT_ID);
CREATE INDEX IF NOT EXISTS IDX_PRODUCT_VARIANTS_SKU ON PUBLIC.PRODUCT_VARIANTS(SKU);

-- Create product_measurements table
CREATE TABLE IF NOT EXISTS PUBLIC.PRODUCT_MEASUREMENTS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE CASCADE,
    DEFAULT_UNIT TEXT NOT NULL,
    CATEGORY TEXT,
    PRICING_OPTIONS JSONB NOT NULL DEFAULT '[]'::JSONB,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(PRODUCT_ID)
);

-- Create indexes for product_measurements table
CREATE INDEX IF NOT EXISTS IDX_PRODUCT_MEASUREMENTS_PRODUCT_ID ON PUBLIC.PRODUCT_MEASUREMENTS(PRODUCT_ID);

-- Create updated_at trigger function (if not exists)
CREATE OR REPLACE FUNCTION PUBLIC.HANDLE_UPDATED_AT()
RETURNS TRIGGER AS $$
BEGIN 
    NEW.UPDATED_AT = NOW();
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS SET_UPDATED_AT_PRODUCTS ON PUBLIC.PRODUCTS;
CREATE TRIGGER SET_UPDATED_AT_PRODUCTS 
    BEFORE UPDATE ON PUBLIC.PRODUCTS 
    FOR EACH ROW 
    EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

DROP TRIGGER IF EXISTS SET_UPDATED_AT_PRODUCT_VARIANTS ON PUBLIC.PRODUCT_VARIANTS;
CREATE TRIGGER SET_UPDATED_AT_PRODUCT_VARIANTS 
    BEFORE UPDATE ON PUBLIC.PRODUCT_VARIANTS 
    FOR EACH ROW 
    EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

DROP TRIGGER IF EXISTS SET_UPDATED_AT_PRODUCT_MEASUREMENTS ON PUBLIC.PRODUCT_MEASUREMENTS;
CREATE TRIGGER SET_UPDATED_AT_PRODUCT_MEASUREMENTS 
    BEFORE UPDATE ON PUBLIC.PRODUCT_MEASUREMENTS 
    FOR EACH ROW 
    EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.PRODUCTS ENABLE ROW LEVEL SECURITY;
ALTER TABLE PUBLIC.PRODUCT_VARIANTS ENABLE ROW LEVEL SECURITY;
ALTER TABLE PUBLIC.PRODUCT_MEASUREMENTS ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for products table
-- Public can SELECT active products
DROP POLICY IF EXISTS "Public can view active products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Public can view active products" ON PUBLIC.PRODUCTS 
    FOR SELECT
    TO PUBLIC
    USING (IS_ACTIVE = TRUE);

-- Admins can SELECT all products (using IS_ADMIN function to prevent recursion)
DROP POLICY IF EXISTS "Admins can view all products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Admins can view all products" ON PUBLIC.PRODUCTS 
    FOR SELECT
    TO AUTHENTICATED
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Admins can INSERT products
DROP POLICY IF EXISTS "Admins can insert products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Admins can insert products" ON PUBLIC.PRODUCTS 
    FOR INSERT 
    TO AUTHENTICATED 
    WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Admins can UPDATE products
DROP POLICY IF EXISTS "Admins can update products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Admins can update products" ON PUBLIC.PRODUCTS 
    FOR UPDATE 
    TO AUTHENTICATED 
    USING (PUBLIC.IS_ADMIN(AUTH.UID()))
    WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Admins can DELETE products
DROP POLICY IF EXISTS "Admins can delete products" ON PUBLIC.PRODUCTS;
CREATE POLICY "Admins can delete products" ON PUBLIC.PRODUCTS 
    FOR DELETE 
    TO AUTHENTICATED 
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Create RLS policies for product_variants table
-- Public can SELECT variants for active products
DROP POLICY IF EXISTS "Public can view variants for active products" ON PUBLIC.PRODUCT_VARIANTS;
CREATE POLICY "Public can view variants for active products" ON PUBLIC.PRODUCT_VARIANTS 
    FOR SELECT
    TO PUBLIC
    USING (EXISTS (
        SELECT 1
        FROM PUBLIC.PRODUCTS
        WHERE ID = PRODUCT_VARIANTS.PRODUCT_ID
        AND IS_ACTIVE = TRUE
    ));

-- Admins can manage all variants
DROP POLICY IF EXISTS "Admins can manage all variants" ON PUBLIC.PRODUCT_VARIANTS;
CREATE POLICY "Admins can manage all variants" ON PUBLIC.PRODUCT_VARIANTS 
    FOR ALL 
    TO AUTHENTICATED 
    USING (PUBLIC.IS_ADMIN(AUTH.UID()))
    WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Create RLS policies for product_measurements table
-- Public can SELECT measurements for active products
DROP POLICY IF EXISTS "Public can view measurements for active products" ON PUBLIC.PRODUCT_MEASUREMENTS;
CREATE POLICY "Public can view measurements for active products" ON PUBLIC.PRODUCT_MEASUREMENTS 
    FOR SELECT
    TO PUBLIC
    USING (EXISTS (
        SELECT 1
        FROM PUBLIC.PRODUCTS
        WHERE ID = PRODUCT_MEASUREMENTS.PRODUCT_ID
        AND IS_ACTIVE = TRUE
    ));

-- Admins can manage all measurements
DROP POLICY IF EXISTS "Admins can manage all measurements" ON PUBLIC.PRODUCT_MEASUREMENTS;
CREATE POLICY "Admins can manage all measurements" ON PUBLIC.PRODUCT_MEASUREMENTS 
    FOR ALL 
    TO AUTHENTICATED 
    USING (PUBLIC.IS_ADMIN(AUTH.UID()))
    WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));

-- ============================================================================
-- PART 4: CART ITEMS TABLE
-- ============================================================================

-- Create cart_items table
CREATE TABLE IF NOT EXISTS PUBLIC.CART_ITEMS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE CASCADE,
    VARIANT_ID UUID REFERENCES PUBLIC.PRODUCT_VARIANTS(ID) ON DELETE SET NULL,
    QUANTITY INTEGER NOT NULL DEFAULT 1 CHECK (QUANTITY > 0),
    MEASUREMENT_UNIT TEXT,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(USER_ID, PRODUCT_ID, VARIANT_ID, MEASUREMENT_UNIT)
);

-- Create indexes for cart_items table
CREATE INDEX IF NOT EXISTS IDX_CART_ITEMS_USER_ID ON PUBLIC.CART_ITEMS(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_CART_ITEMS_PRODUCT_ID ON PUBLIC.CART_ITEMS(PRODUCT_ID);
CREATE INDEX IF NOT EXISTS IDX_CART_ITEMS_VARIANT_ID ON PUBLIC.CART_ITEMS(VARIANT_ID) WHERE VARIANT_ID IS NOT NULL;
CREATE INDEX IF NOT EXISTS IDX_CART_ITEMS_CREATED_AT ON PUBLIC.CART_ITEMS(CREATED_AT DESC);

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS SET_UPDATED_AT_CART_ITEMS ON PUBLIC.CART_ITEMS;
CREATE TRIGGER SET_UPDATED_AT_CART_ITEMS 
    BEFORE UPDATE ON PUBLIC.CART_ITEMS 
    FOR EACH ROW 
    EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.CART_ITEMS ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for cart_items table
-- Users can SELECT/INSERT/UPDATE/DELETE their own cart items
DROP POLICY IF EXISTS "Users can manage their own cart items" ON PUBLIC.CART_ITEMS;
CREATE POLICY "Users can manage their own cart items" ON PUBLIC.CART_ITEMS 
    FOR ALL 
    USING (AUTH.UID() = USER_ID);

-- Admins can SELECT all cart items (for analytics)
DROP POLICY IF EXISTS "Admins can view all cart items" ON PUBLIC.CART_ITEMS;
CREATE POLICY "Admins can view all cart items" ON PUBLIC.CART_ITEMS 
    FOR SELECT
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Add comment to table
COMMENT ON TABLE PUBLIC.CART_ITEMS IS 'Stores cart items for each user. Supports products with variants and measurement-based pricing.';

-- ============================================================================
-- PART 5: WISHLIST TABLE
-- ============================================================================

-- Create wishlist table
CREATE TABLE IF NOT EXISTS PUBLIC.WISHLIST (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE CASCADE,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(USER_ID, PRODUCT_ID)
);

-- Create indexes for wishlist table
CREATE INDEX IF NOT EXISTS IDX_WISHLIST_USER_ID ON PUBLIC.WISHLIST(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_WISHLIST_PRODUCT_ID ON PUBLIC.WISHLIST(PRODUCT_ID);
CREATE INDEX IF NOT EXISTS IDX_WISHLIST_CREATED_AT ON PUBLIC.WISHLIST(CREATED_AT DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.WISHLIST ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for wishlist table
-- Users can SELECT/INSERT/DELETE their own wishlist items
DROP POLICY IF EXISTS "Users can manage their own wishlist items" ON PUBLIC.WISHLIST;
CREATE POLICY "Users can manage their own wishlist items" ON PUBLIC.WISHLIST 
    FOR ALL 
    USING (AUTH.UID() = USER_ID);

-- Admins can SELECT all wishlist items (for analytics)
DROP POLICY IF EXISTS "Admins can view all wishlist items" ON PUBLIC.WISHLIST;
CREATE POLICY "Admins can view all wishlist items" ON PUBLIC.WISHLIST 
    FOR SELECT
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Add comment to table
COMMENT ON TABLE PUBLIC.WISHLIST IS 'Stores wishlist items for each user. Users can save products they are interested in.';

-- ============================================================================
-- PART 6: PRODUCT VIEWS TABLE
-- ============================================================================

-- Create product_views table
CREATE TABLE IF NOT EXISTS PUBLIC.PRODUCT_VIEWS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE CASCADE,
    USER_ID UUID REFERENCES PUBLIC.PROFILES(ID) ON DELETE SET NULL,
    SESSION_ID TEXT,
    VIEWED_AT TIMESTAMPTZ DEFAULT NOW(),
    DURATION_SECONDS INTEGER DEFAULT 0,
    SOURCE TEXT
);

-- Create indexes for product_views table
CREATE INDEX IF NOT EXISTS IDX_PRODUCT_VIEWS_PRODUCT_ID ON PUBLIC.PRODUCT_VIEWS(PRODUCT_ID);
CREATE INDEX IF NOT EXISTS IDX_PRODUCT_VIEWS_USER_ID ON PUBLIC.PRODUCT_VIEWS(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_PRODUCT_VIEWS_VIEWED_AT ON PUBLIC.PRODUCT_VIEWS(VIEWED_AT DESC);
CREATE INDEX IF NOT EXISTS IDX_PRODUCT_VIEWS_SESSION_ID ON PUBLIC.PRODUCT_VIEWS(SESSION_ID) WHERE SESSION_ID IS NOT NULL;

-- Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.PRODUCT_VIEWS ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for product_views table
-- Users can INSERT their own views
DROP POLICY IF EXISTS "Users can insert their own views" ON PUBLIC.PRODUCT_VIEWS;
CREATE POLICY "Users can insert their own views" ON PUBLIC.PRODUCT_VIEWS
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (AUTH.UID() = USER_ID OR USER_ID IS NULL);

-- Users can SELECT their own views
DROP POLICY IF EXISTS "Users can select their own views" ON PUBLIC.PRODUCT_VIEWS;
CREATE POLICY "Users can select their own views" ON PUBLIC.PRODUCT_VIEWS
    FOR SELECT
    TO AUTHENTICATED
    USING (AUTH.UID() = USER_ID);

-- Admins can SELECT all views
DROP POLICY IF EXISTS "Admins can select all views" ON PUBLIC.PRODUCT_VIEWS;
CREATE POLICY "Admins can select all views" ON PUBLIC.PRODUCT_VIEWS
    FOR SELECT
    TO AUTHENTICATED
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- ============================================================================
-- PART 7: USER SESSIONS AND LOCATIONS TABLES
-- ============================================================================

-- Create user_sessions table
CREATE TABLE IF NOT EXISTS PUBLIC.USER_SESSIONS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    SESSION_ID TEXT NOT NULL UNIQUE,
    DEVICE_INFO JSONB DEFAULT '{}'::JSONB,
    IP_ADDRESS TEXT,
    LOCATION_LATITUDE DECIMAL(10, 8),
    LOCATION_LONGITUDE DECIMAL(11, 8),
    LOCATION_ADDRESS TEXT,
    STARTED_AT TIMESTAMPTZ DEFAULT NOW(),
    LAST_ACTIVITY_AT TIMESTAMPTZ DEFAULT NOW(),
    ENDED_AT TIMESTAMPTZ,
    IS_ACTIVE BOOLEAN DEFAULT TRUE
);

-- Create user_locations table
CREATE TABLE IF NOT EXISTS PUBLIC.USER_LOCATIONS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    SESSION_ID TEXT,
    LATITUDE DECIMAL(10, 8) NOT NULL,
    LONGITUDE DECIMAL(11, 8) NOT NULL,
    ADDRESS TEXT,
    ACCURACY DOUBLE PRECISION,
    CAPTURED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for user_sessions table
CREATE INDEX IF NOT EXISTS IDX_USER_SESSIONS_USER_ID ON PUBLIC.USER_SESSIONS(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_USER_SESSIONS_SESSION_ID ON PUBLIC.USER_SESSIONS(SESSION_ID);
CREATE INDEX IF NOT EXISTS IDX_USER_SESSIONS_STARTED_AT ON PUBLIC.USER_SESSIONS(STARTED_AT DESC);
CREATE INDEX IF NOT EXISTS IDX_USER_SESSIONS_IS_ACTIVE ON PUBLIC.USER_SESSIONS(IS_ACTIVE);
CREATE INDEX IF NOT EXISTS IDX_USER_SESSIONS_LAST_ACTIVITY ON PUBLIC.USER_SESSIONS(LAST_ACTIVITY_AT DESC);

-- Create indexes for user_locations table
CREATE INDEX IF NOT EXISTS IDX_USER_LOCATIONS_USER_ID ON PUBLIC.USER_LOCATIONS(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_USER_LOCATIONS_SESSION_ID ON PUBLIC.USER_LOCATIONS(SESSION_ID);
CREATE INDEX IF NOT EXISTS IDX_USER_LOCATIONS_CAPTURED_AT ON PUBLIC.USER_LOCATIONS(CAPTURED_AT DESC);
CREATE INDEX IF NOT EXISTS IDX_USER_LOCATIONS_USER_CAPTURED ON PUBLIC.USER_LOCATIONS(USER_ID, CAPTURED_AT DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.USER_SESSIONS ENABLE ROW LEVEL SECURITY;
ALTER TABLE PUBLIC.USER_LOCATIONS ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_sessions table
-- Users can INSERT their own sessions
DROP POLICY IF EXISTS "Users can insert their own sessions" ON PUBLIC.USER_SESSIONS;
CREATE POLICY "Users can insert their own sessions" ON PUBLIC.USER_SESSIONS
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (AUTH.UID() = USER_ID);

-- Users can SELECT their own sessions
DROP POLICY IF EXISTS "Users can select their own sessions" ON PUBLIC.USER_SESSIONS;
CREATE POLICY "Users can select their own sessions" ON PUBLIC.USER_SESSIONS
    FOR SELECT
    TO AUTHENTICATED
    USING (AUTH.UID() = USER_ID);

-- Users can UPDATE their own sessions
DROP POLICY IF EXISTS "Users can update their own sessions" ON PUBLIC.USER_SESSIONS;
CREATE POLICY "Users can update their own sessions" ON PUBLIC.USER_SESSIONS
    FOR UPDATE
    TO AUTHENTICATED
    USING (AUTH.UID() = USER_ID)
    WITH CHECK (AUTH.UID() = USER_ID);

-- Admins can SELECT all sessions
DROP POLICY IF EXISTS "Admins can select all sessions" ON PUBLIC.USER_SESSIONS;
CREATE POLICY "Admins can select all sessions" ON PUBLIC.USER_SESSIONS
    FOR SELECT
    TO AUTHENTICATED
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Create RLS policies for user_locations table
-- Users can INSERT their own locations
DROP POLICY IF EXISTS "Users can insert their own locations" ON PUBLIC.USER_LOCATIONS;
CREATE POLICY "Users can insert their own locations" ON PUBLIC.USER_LOCATIONS
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (AUTH.UID() = USER_ID);

-- Users can SELECT their own locations
DROP POLICY IF EXISTS "Users can select their own locations" ON PUBLIC.USER_LOCATIONS;
CREATE POLICY "Users can select their own locations" ON PUBLIC.USER_LOCATIONS
    FOR SELECT
    TO AUTHENTICATED
    USING (AUTH.UID() = USER_ID);

-- Admins can SELECT all locations
DROP POLICY IF EXISTS "Admins can select all locations" ON PUBLIC.USER_LOCATIONS;
CREATE POLICY "Admins can select all locations" ON PUBLIC.USER_LOCATIONS
    FOR SELECT
    TO AUTHENTICATED
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Create function to update last_activity_at automatically
CREATE OR REPLACE FUNCTION PUBLIC.UPDATE_SESSION_ACTIVITY()
RETURNS TRIGGER AS $$
BEGIN 
    UPDATE PUBLIC.USER_SESSIONS 
    SET LAST_ACTIVITY_AT = NOW() 
    WHERE SESSION_ID = NEW.SESSION_ID AND IS_ACTIVE = TRUE;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- Create trigger to update session activity when location is captured
DROP TRIGGER IF EXISTS TRG_UPDATE_SESSION_ON_LOCATION ON PUBLIC.USER_LOCATIONS;
CREATE TRIGGER TRG_UPDATE_SESSION_ON_LOCATION 
    AFTER INSERT ON PUBLIC.USER_LOCATIONS 
    FOR EACH ROW 
    EXECUTE FUNCTION PUBLIC.UPDATE_SESSION_ACTIVITY();

-- ============================================================================
-- PART 8: ADDRESSES TABLE
-- ============================================================================

-- Create addresses table
CREATE TABLE IF NOT EXISTS PUBLIC.ADDRESSES (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    NAME TEXT NOT NULL,
    PHONE TEXT NOT NULL,
    ADDRESS TEXT NOT NULL,
    CITY TEXT NOT NULL,
    STATE TEXT NOT NULL,
    PINCODE TEXT NOT NULL,
    COORDINATES POINT,
    NOTES TEXT,
    IS_DEFAULT BOOLEAN DEFAULT FALSE,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for addresses table
CREATE INDEX IF NOT EXISTS IDX_ADDRESSES_USER_ID ON PUBLIC.ADDRESSES(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_ADDRESSES_IS_DEFAULT ON PUBLIC.ADDRESSES(IS_DEFAULT);

-- Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.ADDRESSES ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for addresses table
-- Users can manage their own addresses
DROP POLICY IF EXISTS "Users can manage their own addresses" ON PUBLIC.ADDRESSES;
CREATE POLICY "Users can manage their own addresses" ON PUBLIC.ADDRESSES
    FOR ALL
    TO AUTHENTICATED
    USING (AUTH.UID() = USER_ID)
    WITH CHECK (AUTH.UID() = USER_ID);

-- Admins can manage all addresses
DROP POLICY IF EXISTS "Admins can view all addresses" ON PUBLIC.ADDRESSES;
CREATE POLICY "Admins can manage all addresses" ON PUBLIC.ADDRESSES
    FOR ALL
    TO AUTHENTICATED
    USING (PUBLIC.IS_ADMIN(AUTH.UID()))
    WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Trigger to automatically update updated_at on address updates
DROP TRIGGER IF EXISTS SET_UPDATED_AT_ADDRESSES ON PUBLIC.ADDRESSES;
CREATE TRIGGER SET_UPDATED_AT_ADDRESSES
    BEFORE UPDATE ON PUBLIC.ADDRESSES
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Add comment to table
COMMENT ON TABLE PUBLIC.ADDRESSES IS 'Stores delivery addresses for each user. Supports one address per user (enforced by application logic/unique constraint).';

-- ============================================================================
-- PART 9: GST RECORDS TABLE
-- ============================================================================

-- Create gst_records table
CREATE TABLE IF NOT EXISTS PUBLIC.GST_RECORDS (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    GST_NUMBER TEXT NOT NULL,
    BUSINESS_NAME TEXT NOT NULL,
    BUSINESS_ADDRESS TEXT NOT NULL,
    CITY TEXT NOT NULL,
    STATE TEXT NOT NULL,
    PINCODE TEXT NOT NULL,
    EMAIL TEXT,
    PHONE TEXT,
    IS_DEFAULT BOOLEAN DEFAULT FALSE,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UPDATED_AT TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(USER_ID, GST_NUMBER)
);

-- Create indexes for gst_records table
CREATE INDEX IF NOT EXISTS IDX_GST_RECORDS_USER_ID ON PUBLIC.GST_RECORDS(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_GST_RECORDS_GST_NUMBER ON PUBLIC.GST_RECORDS(GST_NUMBER);

-- Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.GST_RECORDS ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for gst_records table
-- Users can manage their own GST records
DROP POLICY IF EXISTS "Users can manage their own gst records" ON PUBLIC.GST_RECORDS;
CREATE POLICY "Users can manage their own gst records" ON PUBLIC.GST_RECORDS
    FOR ALL
    TO AUTHENTICATED
    USING (AUTH.UID() = USER_ID)
    WITH CHECK (AUTH.UID() = USER_ID);

-- Admins can view all GST records
DROP POLICY IF EXISTS "Admins can view all gst records" ON PUBLIC.GST_RECORDS;
CREATE POLICY "Admins can view all gst records" ON PUBLIC.GST_RECORDS
    FOR SELECT
    TO AUTHENTICATED
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Trigger to automatically update updated_at on GST record updates
DROP TRIGGER IF EXISTS SET_UPDATED_AT_GST_RECORDS ON PUBLIC.GST_RECORDS;
CREATE TRIGGER SET_UPDATED_AT_GST_RECORDS
    BEFORE UPDATE ON PUBLIC.GST_RECORDS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.HANDLE_UPDATED_AT();

-- Add comment to table
COMMENT ON TABLE PUBLIC.GST_RECORDS IS 'Stores GST registration details for business users/customers.';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify all tables were created
SELECT
    '✅ All tables and RLS policies applied successfully' AS STATUS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'profiles') AS PROFILES_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'products') AS PRODUCTS_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'product_variants') AS VARIANTS_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'product_measurements') AS MEASUREMENTS_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'cart_items') AS CART_ITEMS_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'wishlist') AS WISHLIST_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'product_views') AS PRODUCT_VIEWS_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'user_sessions') AS USER_SESSIONS_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'user_locations') AS USER_LOCATIONS_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'addresses') AS ADDRESSES_EXISTS,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'public' AND TABLE_NAME = 'gst_records') AS GST_RECORDS_EXISTS;

-- Verify RLS is enabled on all tables
SELECT
    '✅ RLS Status Check' AS STATUS,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles' AND rowsecurity = true) AS PROFILES_RLS_ENABLED,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'products' AND rowsecurity = true) AS PRODUCTS_RLS_ENABLED,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'cart_items' AND rowsecurity = true) AS CART_ITEMS_RLS_ENABLED,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'wishlist' AND rowsecurity = true) AS WISHLIST_RLS_ENABLED,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'addresses' AND rowsecurity = true) AS ADDRESSES_RLS_ENABLED,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'gst_records' AND rowsecurity = true) AS GST_RECORDS_RLS_ENABLED;

