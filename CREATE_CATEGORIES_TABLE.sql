-- ============================================
-- CREATE CATEGORIES TABLE
-- ============================================
-- This script creates the categories table that is missing from the database
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Create categories table
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

-- Step 4: Create RLS Policies

-- Policy 1: Public can view active categories (for regular users browsing)
CREATE POLICY "Public can view active categories" ON public.categories
    FOR SELECT
    USING (is_active = true);

-- Policy 2: Admins can view all categories (including inactive ones)
CREATE POLICY "Admins can view all categories" ON public.categories
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 
            FROM public.profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'support')
        )
    );

-- Policy 3: Admins can create categories
CREATE POLICY "Admins can create categories" ON public.categories
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM public.profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'support')
        )
    );

-- Policy 4: Admins can update categories
CREATE POLICY "Admins can update categories" ON public.categories
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 
            FROM public.profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'support')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM public.profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'support')
        )
    );

-- Policy 5: Admins can delete categories
CREATE POLICY "Admins can delete categories" ON public.categories
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 
            FROM public.profiles 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'manager', 'support')
        )
    );

-- Step 5: Create trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER categories_updated_at_trigger
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION update_categories_updated_at();

-- Step 6: Verify the table was created
SELECT 
    '✅ Categories table created successfully!' as status,
    COUNT(*) as total_categories
FROM public.categories;

-- Step 7: Show table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'categories'
ORDER BY ordinal_position;

-- Step 8: Show RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd as operation,
    roles
FROM pg_policies
WHERE tablename = 'categories';

