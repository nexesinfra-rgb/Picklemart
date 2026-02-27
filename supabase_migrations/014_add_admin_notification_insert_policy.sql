-- Add Admin Policy for Inserting Notifications
-- This allows admins to create notifications for any user when updating order status
-- Run this in Supabase SQL Editor

-- Step 1: Allow admins to insert notifications for any user
-- This is needed when admin updates order status and needs to notify the customer
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

-- Step 2: Verify policy was created
SELECT
    '✅ Admin notification insert policy created successfully' AS STATUS,
    (
        SELECT COUNT(*)
        FROM pg_policies
        WHERE schemaname = 'public'
        AND tablename = 'user_notifications'
        AND policyname = 'Admins can insert notifications for any user'
    ) AS POLICY_EXISTS;

