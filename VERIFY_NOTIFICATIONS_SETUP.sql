-- ============================================================================
-- VERIFY NOTIFICATIONS SETUP - Quick Check Script
-- ============================================================================
-- Run this to verify your notifications are properly set up
-- Copy entire file → Supabase Dashboard → SQL Editor → Paste → Run
-- ============================================================================

-- ============================================================================
-- QUICK STATUS CHECK
-- ============================================================================
SELECT 
    'QUICK STATUS' AS check_type,
    (SELECT COUNT(*) FROM information_schema.tables 
     WHERE table_schema = 'public' AND table_name = 'user_notifications') AS table_exists,
    (SELECT COUNT(*) FROM information_schema.triggers 
     WHERE event_object_table = 'orders' AND trigger_schema = 'public'
     AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification')) AS triggers_count,
    (SELECT COUNT(*) FROM pg_policies 
     WHERE schemaname = 'public' AND tablename = 'user_notifications'
     AND policyname = 'Admins can insert notifications for any user') AS admin_policy_exists,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.tables 
              WHERE table_schema = 'public' AND table_name = 'user_notifications') > 0
        AND (SELECT COUNT(*) FROM information_schema.triggers 
             WHERE event_object_table = 'orders' AND trigger_schema = 'public'
             AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification')) = 2
        AND (SELECT COUNT(*) FROM pg_policies 
             WHERE schemaname = 'public' AND tablename = 'user_notifications'
             AND policyname = 'Admins can insert notifications for any user') > 0
        THEN '✅ ALL CHECKS PASSED'
        ELSE '❌ SOME CHECKS FAILED - Run CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql'
    END AS overall_status;

-- ============================================================================
-- DETAILED CHECKS
-- ============================================================================

-- Check 1: Table Exists
SELECT 
    'CHECK 1: Table' AS check_name,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ PASS: user_notifications table exists'
        ELSE '❌ FAIL: Table missing - Run CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql'
    END AS status
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_name = 'user_notifications';

-- Check 2: Triggers Exist
SELECT 
    'CHECK 2: Triggers' AS check_name,
    CASE 
        WHEN COUNT(*) = 2 THEN '✅ PASS: Both triggers exist'
        WHEN COUNT(*) = 1 THEN '⚠️ PARTIAL: Only 1 trigger found'
        ELSE '❌ FAIL: No triggers found - Run CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql'
    END AS status,
    COUNT(*) AS count,
    string_agg(trigger_name, ', ') AS names
FROM information_schema.triggers
WHERE event_object_table = 'orders' 
    AND trigger_schema = 'public'
    AND trigger_name IN (
        'trigger_order_placed_notification',
        'trigger_order_status_notification'
    );

-- Check 3: Functions Use SECURITY DEFINER
SELECT 
    'CHECK 3: Functions' AS check_name,
    routine_name,
    CASE 
        WHEN security_type = 'DEFINER' THEN '✅ PASS: SECURITY DEFINER'
        ELSE '❌ FAIL: NOT SECURITY DEFINER'
    END AS status
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_order_status_notification',
        'create_order_placed_notification'
    )
ORDER BY routine_name;

-- Check 4: Admin RLS Policy Exists (CRITICAL)
SELECT 
    'CHECK 4: Admin RLS Policy' AS check_name,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ PASS: Admin can insert notifications'
        ELSE '❌ FAIL: Admin policy missing - Run CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql'
    END AS status,
    COUNT(*) AS count
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
    AND policyname = 'Admins can insert notifications for any user';

-- Check 5: All RLS Policies
SELECT 
    'CHECK 5: All RLS Policies' AS check_name,
    COUNT(*) AS total_policies,
    string_agg(policyname, ', ') AS policy_names,
    CASE 
        WHEN COUNT(*) >= 4 THEN '✅ PASS: All policies exist'
        ELSE '⚠️ PARTIAL: Some policies missing'
    END AS status
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'user_notifications';

-- ============================================================================
-- RECOMMENDATIONS
-- ============================================================================
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.tables 
              WHERE table_schema = 'public' AND table_name = 'user_notifications') = 0
        THEN '⚠️ ACTION REQUIRED: Run CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql to create the table'
        ELSE '✅ Table exists'
    END AS recommendation_1,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.triggers 
              WHERE event_object_table = 'orders' AND trigger_schema = 'public'
              AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification')) < 2
        THEN '⚠️ ACTION REQUIRED: Run CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql to create triggers'
        ELSE '✅ Triggers exist'
    END AS recommendation_2,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies 
              WHERE schemaname = 'public' AND tablename = 'user_notifications'
              AND policyname = 'Admins can insert notifications for any user') = 0
        THEN '⚠️ ACTION REQUIRED: Run CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql to add admin RLS policy'
        ELSE '✅ Admin RLS policy exists'
    END AS recommendation_3;

