-- Ensure Categories Table and RLS Policies
-- This migration creates the categories table if it doesn't exist and ensures proper RLS policies
-- Run this in Supabase SQL Editor

-- Step 1: Create categories table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    image_url TEXT,
    parent_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_categories_name ON public.categories(name);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON public.categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_is_active ON public.categories(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON public.categories(sort_order);

-- Step 3: Enable Row Level Security
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Public can view active categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can view all categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can create categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
DROP POLICY IF EXISTS "Admins can delete categories" ON public.categories;
DROP POLICY IF EXISTS "admin_select_categories" ON public.categories;
DROP POLICY IF EXISTS "admin_insert_categories" ON public.categories;
DROP POLICY IF EXISTS "admin_update_categories" ON public.categories;
DROP POLICY IF EXISTS "admin_delete_categories" ON public.categories;
DROP POLICY IF EXISTS "public_select_categories" ON public.categories;

-- Step 5: Create RLS Policies

-- Policy 1: Public can view active categories (for regular users browsing)
CREATE POLICY "Public can view active categories" ON public.categories
    FOR SELECT
    TO PUBLIC
    USING (is_active = true);

-- Policy 2: Admins can view all categories (including inactive ones)
-- Using IS_ADMIN function to prevent RLS recursion
CREATE POLICY "Admins can view all categories" ON public.categories
    FOR SELECT
    TO AUTHENTICATED
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Policy 3: Admins can create categories
CREATE POLICY "Admins can create categories" ON public.categories
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Policy 4: Admins can update categories
CREATE POLICY "Admins can update categories" ON public.categories
    FOR UPDATE
    TO AUTHENTICATED
    USING (PUBLIC.IS_ADMIN(AUTH.UID()))
    WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Policy 5: Admins can delete categories (CRITICAL FOR DELETION FUNCTIONALITY)
CREATE POLICY "Admins can delete categories" ON public.categories
    FOR DELETE
    TO AUTHENTICATED
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));

-- Step 6: Create trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS categories_updated_at_trigger ON public.categories;
CREATE TRIGGER categories_updated_at_trigger
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION update_categories_updated_at();

-- Step 7: Verify the policies were created
SELECT 
    '✅ Categories RLS policies created successfully!' as status,
    policyname,
    cmd as operation,
    CASE 
        WHEN cmd = 'SELECT' AND policyname LIKE '%Public%' THEN 'Public can view active'
        WHEN cmd = 'SELECT' AND policyname LIKE '%Admins%' THEN 'Admins can view all'
        WHEN cmd = 'INSERT' THEN 'Admins can create'
        WHEN cmd = 'UPDATE' THEN 'Admins can update'
        WHEN cmd = 'DELETE' THEN 'Admins can delete'
        ELSE 'Other policy'
    END as description
FROM pg_policies 
WHERE tablename = 'categories'
ORDER BY cmd, policyname;

