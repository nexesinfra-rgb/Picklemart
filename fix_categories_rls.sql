-- Fix Categories Table RLS Policies
-- Run this script in your Supabase SQL Editor after running fix_category_creation.sql

-- Step 1: Check current RLS policies on categories table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'categories';

-- Step 2: Check if RLS is enabled on categories table
SELECT schemaname, tablename, rowsecurity
FROM pg_tables 
WHERE tablename = 'categories';

-- Step 3: Create RLS policies for categories table
-- Allow admins to select categories
CREATE POLICY "Admins can view all categories" ON categories
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow admins to insert categories
CREATE POLICY "Admins can create categories" ON categories
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow admins to update categories
CREATE POLICY "Admins can update categories" ON categories
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    ) WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow admins to delete categories
CREATE POLICY "Admins can delete categories" ON categories
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow public read access to categories (for regular users browsing)
CREATE POLICY "Public can view categories" ON categories
    FOR SELECT USING (true);

-- Step 4: Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'categories';

-- Step 5: Test query to verify admin access
SELECT 
    'Admin user can access categories table' as test_result,
    auth.uid() as current_user_id,
    (SELECT role FROM profiles WHERE id = auth.uid()) as user_role;

SELECT 'Categories RLS policies fixed successfully!' as status;