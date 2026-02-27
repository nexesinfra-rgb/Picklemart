-- ============================================================================
-- DIAGNOSTIC: Check Notification System Status
-- ============================================================================
-- Run this BEFORE applying the fix to see current state
-- Copy entire file → Supabase Dashboard → SQL Editor → Paste → Run
-- ============================================================================

-- ============================================================================
-- CHECK 1: Do Triggers Exist?
-- ============================================================================
SELECT 
    'CHECK 1: Triggers' AS check_name,
    CASE 
        WHEN COUNT(*) = 2 THEN '✅ PASS: Both triggers exist'
        WHEN COUNT(*) = 1 THEN '⚠️  PARTIAL: Only 1 trigger found (Expected: 2)'
        ELSE '❌ FAIL: No triggers found (Expected: 2)'
    END AS status,
    COUNT(*) AS found_count,
    string_agg(trigger_name, ', ') AS trigger_names,
    string_agg(event_manipulation::text, ', ') AS events
FROM information_schema.triggers
WHERE event_object_table = 'orders' 
    AND trigger_schema = 'public'
    AND trigger_name IN (
        'trigger_order_placed_notification',
        'trigger_order_status_notification'
    );

-- Show trigger details if they exist
SELECT 
    'Trigger Details' AS info,
    trigger_name,
    event_manipulation AS event,
    action_timing AS timing,
    action_statement AS function
FROM information_schema.triggers
WHERE event_object_table = 'orders' 
    AND trigger_schema = 'public'
    AND trigger_name IN (
        'trigger_order_placed_notification',
        'trigger_order_status_notification'
    )
ORDER BY trigger_name;

-- ============================================================================
-- CHECK 2: Do Functions Exist and Use SECURITY DEFINER?
-- ============================================================================
SELECT 
    'CHECK 2: Functions' AS check_name,
    CASE 
        WHEN COUNT(*) = 2 THEN '✅ PASS: Both functions exist'
        WHEN COUNT(*) = 1 THEN '⚠️  PARTIAL: Only 1 function found (Expected: 2)'
        ELSE '❌ FAIL: No functions found (Expected: 2)'
    END AS status,
    COUNT(*) AS found_count,
    string_agg(routine_name, ', ') AS function_names
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_order_status_notification',
        'create_order_placed_notification'
    );

-- Show function security details
SELECT 
    'Function Security Details' AS info,
    routine_name,
    security_type,
    CASE 
        WHEN security_type = 'DEFINER' THEN '✅ BYPASSES RLS'
        ELSE '❌ WILL BE BLOCKED BY RLS'
    END AS rls_bypass_status
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_order_status_notification',
        'create_order_placed_notification'
    )
ORDER BY routine_name;

-- ============================================================================
-- CHECK 3: Does RLS Policy Exist?
-- ============================================================================
SELECT 
    'CHECK 3: RLS Policy' AS check_name,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ PASS: Admin RLS policy exists'
        ELSE '❌ FAIL: Admin RLS policy missing - Run RUN_THIS_FIX.sql'
    END AS status,
    COUNT(*) AS policy_count,
    string_agg(policyname, ', ') AS policy_names
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
    AND policyname = 'Admins can insert notifications for any user';

-- Show all RLS policies for user_notifications
SELECT 
    'All RLS Policies for user_notifications' AS info,
    policyname,
    cmd AS operation,
    roles,
    qual AS using_expression,
    with_check AS with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
ORDER BY policyname;

-- ============================================================================
-- CHECK 4: Does user_notifications Table Exist?
-- ============================================================================
SELECT 
    'CHECK 4: Table Exists' AS check_name,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ PASS: user_notifications table exists'
        ELSE '❌ FAIL: user_notifications table missing - Run migration 013_create_user_notifications_table.sql first'
    END AS status,
    COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_name = 'user_notifications';

-- Show table structure if it exists
SELECT 
    'Table Structure' AS info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'user_notifications'
ORDER BY ordinal_position;

-- ============================================================================
-- CHECK 5: Is Real-Time Enabled?
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
        ELSE '⚠️  WARNING: Real-time may not be enabled. Enable in Dashboard → Database → Replication'
    END AS status;

-- Show real-time publication status
SELECT 
    'Real-Time Publication Status' AS info,
    schemaname,
    tablename,
    pubname AS publication_name
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'user_notifications';

-- ============================================================================
-- CHECK 6: Current Notification Count
-- ============================================================================
SELECT 
    'CHECK 6: Notification Data' AS check_name,
    COUNT(*) AS total_notifications,
    COUNT(CASE WHEN is_read = false THEN 1 END) AS unread_count,
    COUNT(CASE WHEN is_read = true THEN 1 END) AS read_count,
    MIN(created_at) AS oldest_notification,
    MAX(created_at) AS newest_notification
FROM user_notifications;

-- ============================================================================
-- DIAGNOSTIC SUMMARY
-- ============================================================================
SELECT 
    '📊 DIAGNOSTIC SUMMARY' AS summary,
    (SELECT COUNT(*) FROM information_schema.triggers 
     WHERE event_object_table = 'orders' AND trigger_schema = 'public'
     AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification')) AS triggers_found,
    (SELECT COUNT(*) FROM information_schema.routines 
     WHERE routine_schema = 'public'
     AND routine_name IN ('create_order_status_notification', 'create_order_placed_notification')) AS functions_found,
    (SELECT COUNT(*) FROM pg_policies 
     WHERE schemaname = 'public' AND tablename = 'user_notifications'
     AND policyname = 'Admins can insert notifications for any user') AS rls_policies_found,
    (SELECT COUNT(*) FROM information_schema.tables 
     WHERE table_schema = 'public' AND table_name = 'user_notifications') AS table_exists,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.triggers 
              WHERE event_object_table = 'orders' AND trigger_schema = 'public'
              AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification')) = 2
        AND (SELECT COUNT(*) FROM information_schema.routines 
             WHERE routine_schema = 'public'
             AND routine_name IN ('create_order_status_notification', 'create_order_placed_notification')) = 2
        AND (SELECT COUNT(*) FROM pg_policies 
             WHERE schemaname = 'public' AND tablename = 'user_notifications'
             AND policyname = 'Admins can insert notifications for any user') > 0
        THEN '✅ ALL CHECKS PASSED - System is configured correctly!'
        ELSE '❌ SOME CHECKS FAILED - Run RUN_THIS_FIX.sql to fix issues'
    END AS overall_status;

-- ============================================================================
-- RECOMMENDATIONS
-- ============================================================================
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.triggers 
              WHERE event_object_table = 'orders' AND trigger_schema = 'public'
              AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification')) < 2
        THEN '⚠️  ACTION REQUIRED: Run RUN_THIS_FIX.sql to create missing triggers'
        ELSE '✅ Triggers are configured'
    END AS recommendation_1,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'public'
            AND routine_name IN ('create_order_status_notification', 'create_order_placed_notification')
            AND security_type = 'DEFINER'
        )
        THEN '⚠️  ACTION REQUIRED: Run RUN_THIS_FIX.sql to fix function security'
        ELSE '✅ Functions use SECURITY DEFINER'
    END AS recommendation_2,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies 
              WHERE schemaname = 'public' AND tablename = 'user_notifications'
              AND policyname = 'Admins can insert notifications for any user') = 0
        THEN '⚠️  ACTION REQUIRED: Run RUN_THIS_FIX.sql to add RLS policy'
        ELSE '✅ RLS policy exists'
    END AS recommendation_3;

