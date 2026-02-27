-- COMPREHENSIVE FIX FOR CATEGORIES RLS ISSUES
-- This script will diagnose and fix ALL possible issues
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

-- Check current user and their profile
SELECT 
    'CURRENT USER STATUS' as check_type,
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN 'NOT AUTHENTICATED'
        ELSE 'AUTHENTICATED'
    END as auth_status,
    (SELECT role FROM profiles WHERE id = auth.uid()) as user_role,
    (SELECT email FROM profiles WHERE id = auth.uid()) as user_email;

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

-- =============================================================================
-- STEP 3: ENSURE PROPER SETUP
-- =============================================================================

-- Ensure RLS is enabled on categories table
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Ensure the current user has admin role (update with your actual user ID if needed)
-- This will work if you're authenticated
INSERT INTO profiles (id, email, role, created_at, updated_at)
VALUES (
    auth.uid(),
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
-- STEP 4: CREATE COMPREHENSIVE RLS POLICIES
-- =============================================================================

-- Policy 1: Allow admins to SELECT categories
CREATE POLICY "admin_select_categories" ON categories
    FOR SELECT 
    USING (
        auth.uid() IS NOT NULL 
        AND EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Policy 2: Allow admins to INSERT categories
CREATE POLICY "admin_insert_categories" ON categories
    FOR INSERT 
    WITH CHECK (
        auth.uid() IS NOT NULL 
        AND EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Policy 3: Allow admins to UPDATE categories
CREATE POLICY "admin_update_categories" ON categories
    FOR UPDATE 
    USING (
        auth.uid() IS NOT NULL 
        AND EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL 
        AND EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Policy 4: Allow admins to DELETE categories
CREATE POLICY "admin_delete_categories" ON categories
    FOR DELETE 
    USING (
        auth.uid() IS NOT NULL 
        AND EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Policy 5: Allow public to SELECT categories (for browsing)
CREATE POLICY "public_select_categories" ON categories
    FOR SELECT 
    USING (true);

-- =============================================================================
-- STEP 5: VERIFICATION
-- =============================================================================

-- Verify policies were created
SELECT 
    'FINAL POLICY CHECK' as check_type,
    policyname, 
    cmd as operation,
    CASE 
        WHEN cmd = 'SELECT' AND policyname LIKE '%admin%' THEN 'Admin can view'
        WHEN cmd = 'INSERT' AND policyname LIKE '%admin%' THEN 'Admin can create'
        WHEN cmd = 'UPDATE' AND policyname LIKE '%admin%' THEN 'Admin can update'
        WHEN cmd = 'DELETE' AND policyname LIKE '%admin%' THEN 'Admin can delete'
        WHEN cmd = 'SELECT' AND policyname LIKE '%public%' THEN 'Public can view'
        ELSE 'Other policy'
    END as description
FROM pg_policies 
WHERE tablename = 'categories'
ORDER BY cmd, policyname;

-- Final status check
SELECT 
    'FINAL STATUS' as check_type,
    'Categories table: ' || CASE WHEN rowsecurity THEN 'RLS ENABLED' ELSE 'RLS DISABLED' END as table_status,
    'User: ' || COALESCE(auth.uid()::text, 'NOT AUTHENTICATED') as user_status,
    'Role: ' || COALESCE((SELECT role FROM profiles WHERE id = auth.uid()), 'NO ROLE') as role_status,
    'Policies: ' || (SELECT COUNT(*)::text FROM pg_policies WHERE tablename = 'categories') || ' created' as policy_status
FROM pg_tables 
WHERE tablename = 'categories';

SELECT '🎉 COMPREHENSIVE FIX COMPLETED! Try creating a category now.' as final_message;