-- Add DELETE Policy for User Notifications
-- This allows users to delete their own notifications
-- Run this in Supabase SQL Editor

-- Policy: Users can DELETE their own notifications
DROP POLICY IF EXISTS "Users can delete their own notifications" ON PUBLIC.USER_NOTIFICATIONS;
CREATE POLICY "Users can delete their own notifications" ON PUBLIC.USER_NOTIFICATIONS
    FOR DELETE
    TO AUTHENTICATED
    USING (AUTH.UID() = USER_ID);

-- Verify policy was created
SELECT
    '✅ Notification delete policy created successfully' AS STATUS,
    (
        SELECT COUNT(*)
        FROM pg_policies
        WHERE schemaname = 'public'
        AND tablename = 'user_notifications'
        AND policyname = 'Users can delete their own notifications'
    ) AS POLICY_EXISTS;

