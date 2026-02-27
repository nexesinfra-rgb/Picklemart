-- ============================================================================
-- Enable Supabase Realtime for user_notifications table
-- ============================================================================
-- This migration enables real-time subscriptions for the user_notifications table
-- Run this after CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql
-- ============================================================================

-- Enable Realtime for user_notifications table
-- Note: This requires the table to exist and have proper RLS policies
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_notifications;

-- Verify RLS policies exist (recreate if missing)
-- Policy 1: Users can SELECT their own notifications
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_notifications' 
    AND policyname = 'Users can view their own notifications'
  ) THEN
    CREATE POLICY "Users can view their own notifications" ON public.user_notifications
      FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;
END $$;

-- Policy 2: Users can UPDATE their own notifications (mark as read)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_notifications' 
    AND policyname = 'Users can update their own notifications'
  ) THEN
    CREATE POLICY "Users can update their own notifications" ON public.user_notifications
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Policy 3: Users can INSERT their own notifications (for app code)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_notifications' 
    AND policyname = 'Users can insert their own notifications'
  ) THEN
    CREATE POLICY "Users can insert their own notifications" ON public.user_notifications
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Policy 4: Admins can INSERT notifications for any user
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'user_notifications' 
    AND policyname = 'Admins can insert notifications for any user'
  ) THEN
    CREATE POLICY "Admins can insert notifications for any user" ON public.user_notifications
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1
          FROM public.profiles
          WHERE id = auth.uid()
          AND role IN ('admin', 'manager', 'support')
        )
      );
  END IF;
END $$;

-- Verify Realtime is enabled
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' 
      AND tablename = 'user_notifications'
    ) THEN '✅ Realtime enabled for user_notifications'
    ELSE '❌ Realtime NOT enabled for user_notifications'
  END AS realtime_status;

-- Verify RLS policies
SELECT 
  '✅ RLS Policy Status' AS check_type,
  COUNT(*) AS policy_count,
  string_agg(policyname, ', ') AS policy_names,
  CASE 
    WHEN COUNT(*) >= 4 THEN 'PASS: All policies exist'
    WHEN COUNT(*) > 0 THEN 'PARTIAL: Some policies missing'
    ELSE 'FAIL: No policies found'
  END AS status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'user_notifications';

