-- Create Wishlist Table
-- Run this in Supabase SQL Editor

-- Step 1: Create wishlist table
CREATE TABLE IF NOT EXISTS PUBLIC.WISHLIST (
    ID UUID PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    USER_ID UUID NOT NULL REFERENCES PUBLIC.PROFILES(ID) ON DELETE CASCADE,
    PRODUCT_ID UUID NOT NULL REFERENCES PUBLIC.PRODUCTS(ID) ON DELETE CASCADE,
    CREATED_AT TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate wishlist items
    UNIQUE(USER_ID, PRODUCT_ID)
);

-- Step 2: Create indexes for wishlist table
CREATE INDEX IF NOT EXISTS IDX_WISHLIST_USER_ID ON PUBLIC.WISHLIST(USER_ID);
CREATE INDEX IF NOT EXISTS IDX_WISHLIST_PRODUCT_ID ON PUBLIC.WISHLIST(PRODUCT_ID);
CREATE INDEX IF NOT EXISTS IDX_WISHLIST_CREATED_AT ON PUBLIC.WISHLIST(CREATED_AT DESC);

-- Step 3: Enable Row Level Security (RLS)
ALTER TABLE PUBLIC.WISHLIST ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies for wishlist table
-- Users can SELECT/INSERT/DELETE their own wishlist items
DROP POLICY IF EXISTS "Users can manage their own wishlist items" ON PUBLIC.WISHLIST;
CREATE POLICY "Users can manage their own wishlist items" ON PUBLIC.WISHLIST 
FOR ALL 
USING (AUTH.UID() = USER_ID);

-- Admins can SELECT all wishlist items (for analytics)
DROP POLICY IF EXISTS "Admins can view all wishlist items" ON PUBLIC.WISHLIST;
CREATE POLICY "Admins can view all wishlist items" ON PUBLIC.WISHLIST 
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM PUBLIC.PROFILES
        WHERE PROFILES.ID = AUTH.UID()
        AND PROFILES.ROLE IN ('admin', 'manager', 'support')
    )
);

-- Step 5: Add comment to table
COMMENT ON TABLE PUBLIC.WISHLIST IS 'Stores wishlist items for each user. Users can save products they are interested in.';

