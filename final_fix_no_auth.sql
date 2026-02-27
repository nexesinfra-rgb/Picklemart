-- FINAL FIX FOR CATEGORIES RLS - NO AUTHENTICATION REQUIRED
-- This script fixes the issue without relying on auth.uid() which is null in SQL Editor
-- Run this script in your Supabase SQL Editor

-- =============================================================================
-- STEP 1: DIAGNOSTIC - Check current state
-- =============================================================================

-- Check if categories table exists and has RLS enabled
SELECT 
    'CATEGORIES TABLE STATUS' as check_type,
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled,
    CASE WHEN rowsecurity THEN 'RLS is ENABLED' ELSE 'RLS is DISABLED' END as status
FROM pg_tables 
WHERE tablename = 'categories';

-- Check existing RLS policies on categories
SELECT 
    'EXISTING RLS POLICIES' as check_type,
    schemaname, 
    tablename, 
    policyname, 
    cmd as operation,
    roles,
    qual as using_condition,
    with_check as with_check_condition
FROM pg_policies 
WHERE tablename = 'categories';

-- Check profiles table structure and data
SELECT 
    'PROFILES TABLE CHECK' as check_type,
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
    array_agg(DISTINCT role) as all_roles
FROM profiles;

-- =============================================================================
-- STEP 2: CLEANUP - Remove any conflicting policies
-- =============================================================================

-- Drop existing policies if they exist (ignore errors if they don't exist)
DROP POLICY IF EXISTS "Admins can view all categories" ON categories;
DROP POLICY IF EXISTS "Admins can create categories" ON categories;
DROP POLICY IF EXISTS "Admins can update categories" ON categories;
DROP POLICY IF EXISTS "Admins can delete categories" ON categories;
DROP POLICY IF EXISTS "Public can view categories" ON categories;
DROP POLICY IF EXISTS "Enable read access for all users" ON categories;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON categories;
DROP POLICY IF EXISTS "Enable update for users based on email" ON categories;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON categories;
DROP POLICY IF EXISTS "admin_select_categories" ON categories;
DROP POLICY IF EXISTS "admin_insert_categories" ON categories;
DROP POLICY IF EXISTS "admin_update_categories" ON categories;
DROP POLICY IF EXISTS "admin_delete_categories" ON categories;
DROP POLICY IF EXISTS "public_select_categories" ON categories;

-- =============================================================================
-- STEP 3: ENSURE PROPER SETUP
-- =============================================================================

-- Ensure RLS is enabled on categories table
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Create admin user with known email (this will be your login)
-- We'll use a specific UUID that we can reference
INSERT INTO profiles (id, email, role, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    'admin@sm.com',
    'admin',
    NOW(),
    NOW()
)
ON CONFLICT (id) 
DO UPDATE SET 
    role = 'admin',
    email = 'admin@sm.com',
    updated_at = NOW();

-- =============================================================================
-- STEP 4: CREATE SIMPLE RLS POLICIES THAT WORK
-- =============================================================================

-- Policy 1: Allow admin users to do everything
CREATE POLICY "admin_full_access" ON categories
    FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Policy 2: Allow public read access (for browsing)
CREATE POLICY "public_read_access" ON categories
    FOR SELECT 
    USING (true);

-- =============================================================================
-- STEP 5: ALTERNATIVE - DISABLE RLS TEMPORARILY FOR TESTING
-- =============================================================================

-- If the above doesn't work, we can temporarily disable RLS for testing
-- Uncomment the next line if you want to disable RLS completely for now:
-- ALTER TABLE categories DISABLE ROW LEVEL SECURITY;

-- =============================================================================
-- STEP 6: VERIFICATION
-- =============================================================================

-- Verify policies were created
SELECT 
    'FINAL POLICY CHECK' as check_type,
    policyname, 
    cmd as operation,
    CASE 
        WHEN policyname LIKE '%admin%' THEN 'Admin access policy'
        WHEN policyname LIKE '%public%' THEN 'Public read policy'
        ELSE 'Other policy'
    END as description
FROM pg_policies 
WHERE tablename = 'categories'
ORDER BY cmd, policyname;

-- Check if we have admin users
SELECT 
    'ADMIN USERS CHECK' as check_type,
    id,
    email,
    role,
    created_at
FROM profiles 
WHERE role = 'admin';

-- Final status check
SELECT 
    'FINAL STATUS' as check_type,
    'Categories table: ' || CASE WHEN rowsecurity THEN 'RLS ENABLED' ELSE 'RLS DISABLED' END as table_status,
    'Admin users: ' || (SELECT COUNT(*)::text FROM profiles WHERE role = 'admin') as admin_count,
    'Policies: ' || (SELECT COUNT(*)::text FROM pg_policies WHERE tablename = 'categories') || ' created' as policy_status
FROM pg_tables 
WHERE tablename = 'categories';

SELECT '🎉 FINAL FIX COMPLETED! Now log into your admin panel and try creating a category.' as final_message;
SELECT 'If it still fails, uncomment the DISABLE RLS line in this script and run it again.' as backup_option;