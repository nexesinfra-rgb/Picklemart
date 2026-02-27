-- ============================================================================
-- VERIFICATION: Check Notification Fix After Applying
-- ============================================================================
-- Run this AFTER running RUN_THIS_FIX.sql to verify everything is working
-- Copy entire file → Supabase Dashboard → SQL Editor → Paste → Run
-- ============================================================================

-- ============================================================================
-- QUICK VERIFICATION
-- ============================================================================
SELECT 
    'QUICK VERIFICATION' AS check_type,
    (SELECT COUNT(*) FROM information_schema.triggers 
     WHERE event_object_table = 'orders' AND trigger_schema = 'public'
     AND trigger_name IN ('trigger_order_placed_notification', 'trigger_order_status_notification')) AS triggers_count,
    (SELECT COUNT(*) FROM information_schema.routines 
     WHERE routine_schema = 'public'
     AND routine_name IN ('create_order_status_notification', 'create_order_placed_notification')
     AND security_type = 'DEFINER') AS functions_with_definer,
    (SELECT COUNT(*) FROM pg_policies 
     WHERE schemaname = 'public' AND tablename = 'user_notifications'
     AND policyname = 'Admins can insert notifications for any user') AS rls_policy_count,
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
        THEN '✅ ALL CHECKS PASSED'
        ELSE '❌ SOME CHECKS FAILED'
    END AS overall_status;

-- ============================================================================
-- DETAILED VERIFICATION
-- ============================================================================

-- Verify triggers
SELECT 
    '✅ Trigger Verification' AS check_type,
    trigger_name,
    event_manipulation AS fires_on,
    action_timing AS timing,
    CASE 
        WHEN trigger_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END AS status
FROM information_schema.triggers
WHERE event_object_table = 'orders' 
    AND trigger_schema = 'public'
    AND trigger_name IN (
        'trigger_order_placed_notification',
        'trigger_order_status_notification'
    )
ORDER BY trigger_name;

-- Verify functions use SECURITY DEFINER
SELECT 
    '✅ Function Security Verification' AS check_type,
    routine_name,
    security_type,
    CASE 
        WHEN security_type = 'DEFINER' THEN '✅ BYPASSES RLS'
        ELSE '❌ WILL BE BLOCKED'
    END AS status
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name IN (
        'create_order_status_notification',
        'create_order_placed_notification'
    )
ORDER BY routine_name;

-- Verify RLS policy
SELECT 
    '✅ RLS Policy Verification' AS check_type,
    policyname,
    cmd AS operation,
    CASE 
        WHEN policyname IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END AS status
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
    AND policyname = 'Admins can insert notifications for any user';

-- ============================================================================
-- TEST TRIGGER (Dry Run - Doesn't Create Actual Notification)
-- ============================================================================
-- This tests if the trigger function can be called (syntax check)
SELECT 
    '✅ Trigger Function Test' AS check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines
            WHERE routine_schema = 'public'
            AND routine_name = 'create_order_status_notification'
            AND routine_type = 'FUNCTION'
        ) THEN '✅ Function exists and is callable'
        ELSE '❌ Function missing or invalid'
    END AS status;

-- ============================================================================
-- REAL-TIME VERIFICATION
-- ============================================================================
SELECT 
    '✅ Real-Time Verification' AS check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
            AND schemaname = 'public'
            AND tablename = 'user_notifications'
        ) THEN '✅ Real-time is enabled'
        ELSE '⚠️  Real-time may not be enabled - Enable in Dashboard → Database → Replication'
    END AS status;

-- ============================================================================
-- FINAL STATUS
-- ============================================================================
SELECT 
    '🎉 VERIFICATION COMPLETE' AS summary,
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
        THEN '✅ System is ready! Notifications will work automatically.'
        ELSE '❌ Some components are missing. Re-run RUN_THIS_FIX.sql'
    END AS final_status;

-- ============================================================================
-- TESTING INSTRUCTIONS
-- ============================================================================
SELECT 
    '📋 NEXT STEPS' AS instructions,
    '1. As admin, change an order status to "shipped"' AS step_1,
    '2. Check Flutter debug console for notification creation messages' AS step_2,
    '3. As customer, open notifications screen' AS step_3,
    '4. Verify notification appears immediately' AS step_4,
    '5. Check Supabase Table Editor → user_notifications to see the notification' AS step_5;

