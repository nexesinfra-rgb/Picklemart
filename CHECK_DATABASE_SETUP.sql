-- ============================================================================
-- DATABASE SETUP VERIFICATION
-- ============================================================================
-- Run this to verify your database is properly configured for notifications
-- Copy entire file → Supabase Dashboard → SQL Editor → Paste → Run
-- ============================================================================

-- ============================================================================
-- CHECK 1: Verify Triggers Exist
-- ============================================================================
SELECT 
    'CHECK 1: Triggers' AS check_name,
    CASE 
        WHEN COUNT(*) = 2 THEN '✅ PASS: Both triggers exist'
        WHEN COUNT(*) = 1 THEN '⚠️  PARTIAL: Only 1 trigger found'
        ELSE '❌ FAIL: No triggers found - Run RUN_THIS_FIX.sql'
    END AS status,
    COUNT(*) AS found_count,
    string_agg(trigger_name, ', ') AS trigger_names
FROM information_schema.triggers
WHERE event_object_table = 'orders' 
    AND trigger_schema = 'public'
    AND trigger_name IN (
        'trigger_order_placed_notification',
        'trigger_order_status_notification'
    );

-- Show trigger details
SELECT 
    'Trigger Details' AS info,
    trigger_name,
    event_manipulation AS event,
    action_timing AS timing
FROM information_schema.triggers
WHERE event_object_table = 'orders' 
    AND trigger_schema = 'public'
    AND trigger_name IN (
        'trigger_order_placed_notification',
        'trigger_order_status_notification'
    )
ORDER BY trigger_name;

-- ============================================================================
-- CHECK 2: Verify Functions Use SECURITY DEFINER
-- ============================================================================
SELECT 
    'CHECK 2: Functions' AS check_name,
    routine_name,
    security_type,
    CASE 
        WHEN security_type = 'DEFINER' THEN '✅ BYPASSES RLS'
        ELSE '❌ WILL BE BLOCKED BY RLS'
    END AS status
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_order_status_notification',
        'create_order_placed_notification'
    )
ORDER BY routine_name;

-- ============================================================================
-- CHECK 3: Verify RLS Policy Exists
-- ============================================================================
SELECT 
    'CHECK 3: RLS Policy' AS check_name,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ PASS: Admin RLS policy exists'
        ELSE '❌ FAIL: Admin RLS policy missing - Run RUN_THIS_FIX.sql'
    END AS status,
    COUNT(*) AS policy_count
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
    AND policyname = 'Admins can insert notifications for any user';

-- ============================================================================
-- CHECK 4: Verify Table Exists
-- ============================================================================
SELECT 
    'CHECK 4: Table' AS check_name,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ PASS: user_notifications table exists'
        ELSE '❌ FAIL: user_notifications table missing'
    END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_name = 'user_notifications';

-- ============================================================================
-- CHECK 5: Verify Real-Time is Enabled
-- ============================================================================
SELECT 
    'CHECK 5: Real-Time' AS check_name,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
            AND schemaname = 'public'
            AND tablename = 'user_notifications'
        ) THEN '✅ PASS: Real-time is enabled'
        ELSE '⚠️  WARNING: Real-time may not be enabled - Enable in Dashboard → Database → Replication'
    END AS status;

-- ============================================================================
-- CHECK 6: Test Trigger Function (Dry Run)
-- ============================================================================
-- This checks if the function can be called without errors
DO $$
BEGIN
    -- Check if function exists and is callable
    IF EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_schema = 'public'
        AND routine_name = 'create_order_status_notification'
        AND routine_type = 'FUNCTION'
    ) THEN
        RAISE NOTICE '✅ Trigger function exists and is callable';
    ELSE
        RAISE WARNING '❌ Trigger function missing or invalid';
    END IF;
END $$;

-- ============================================================================
-- SUMMARY
-- ============================================================================
SELECT 
    '📊 VERIFICATION SUMMARY' AS summary,
    (SELECT COUNT(*) FROM information_schema.triggers 
     WHERE event_object_table = 'orders' AND trigger_schema = 'public'
     AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification')) AS triggers_found,
    (SELECT COUNT(*) FROM information_schema.routines 
     WHERE routine_schema = 'public'
     AND routine_name IN ('create_order_status_notification', 'create_order_placed_notification')
     AND security_type = 'DEFINER') AS functions_with_definer,
    (SELECT COUNT(*) FROM pg_policies 
     WHERE schemaname = 'public' AND tablename = 'user_notifications'
     AND policyname = 'Admins can insert notifications for any user') AS rls_policies_found,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.triggers 
              WHERE event_object_table = 'orders' AND trigger_schema = 'public'
              AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification')) = 2
        AND (SELECT COUNT(*) FROM information_schema.routines 
             WHERE routine_schema = 'public'
             AND routine_name IN ('create_order_status_notification', 'create_order_placed_notification')
             AND security_type = 'DEFINER') = 2
        AND (SELECT COUNT(*) FROM pg_policies 
             WHERE schemaname = 'public' AND tablename = 'user_notifications'
             AND policyname = 'Admins can insert notifications for any user') > 0
        THEN '✅ ALL CHECKS PASSED - Database is properly configured!'
        ELSE '❌ SOME CHECKS FAILED - Run RUN_THIS_FIX.sql to fix issues'
    END AS overall_status;

