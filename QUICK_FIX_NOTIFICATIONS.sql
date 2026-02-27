-- ============================================================================
-- QUICK FIX: Enable Admin Notifications for Order Status Changes
-- ============================================================================
-- Run this in Supabase SQL Editor to fix notifications immediately
-- Copy and paste this entire file into Supabase Dashboard → SQL Editor → Run

-- Step 1: Add admin policy to allow inserting notifications for any user
DROP POLICY IF EXISTS "Admins can insert notifications for any user" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Admins can insert notifications for any user" ON PUBLIC.USER_NOTIFICATIONS
    FOR INSERT
    TO AUTHENTICATED
    WITH CHECK (
        EXISTS (
            SELECT 1
            FROM PUBLIC.PROFILES
            WHERE ID = AUTH.UID()
            AND ROLE IN ('admin', 'manager', 'support')
        )
    );

-- Step 2: Verify the policy was created
SELECT 
    '✅ SUCCESS: Admin notification policy created!' AS status,
    policyname,
    cmd as operation
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
    AND policyname = 'Admins can insert notifications for any user';

-- Step 3: Check all policies on user_notifications table
SELECT 
    '📋 All policies on user_notifications:' AS info,
    policyname,
    cmd as operation,
    roles
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
ORDER BY cmd, policyname;

-- Step 4: Verify your admin role
SELECT 
    '👤 Your admin status:' AS info,
    id,
    email,
    role,
    CASE 
        WHEN role IN ('admin', 'manager', 'support') THEN '✅ You are an admin'
        ELSE '❌ You are NOT an admin'
    END as admin_status
FROM profiles 
WHERE id = AUTH.UID();

-- ============================================================================
-- DONE! Now test by changing an order status as admin.
-- The customer should receive a notification immediately.
-- ============================================================================

