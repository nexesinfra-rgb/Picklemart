-- ============================================================================
-- Clean up stale FCM tokens
-- ============================================================================
-- This deletes old/inactive tokens that are no longer valid on Google's servers
-- Run this periodically or after receiving "Requested entity was not found" errors
-- ============================================================================

-- Delete tokens that haven't been updated in over 30 days (likely abandoned)
DELETE FROM public.user_fcm_tokens
WHERE updated_at < NOW() - INTERVAL '30 days'
  AND is_active = true;

-- Delete tokens that were explicitly marked inactive over 7 days ago
DELETE FROM public.user_fcm_tokens
WHERE is_active = false
  AND updated_at < NOW() - INTERVAL '7 days';

-- Show remaining active tokens count
SELECT 
    'User FCM Tokens' AS table_name,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE is_active = true) AS active
FROM public.user_fcm_tokens
UNION ALL
SELECT 
    'Admin FCM Tokens' AS table_name,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE is_active = true) AS active
FROM public.admin_fcm_tokens;

-- Show Mintor's current tokens (for debugging)
SELECT 
    'Tokens for Mintor' AS info,
    user_id,
    is_active,
    updated_at,
    left(fcm_token, 30) AS token_prefix
FROM public.user_fcm_tokens
WHERE user_id = '9cd38a94-e639-4586-9d35-e4f088a76fb2'
ORDER BY updated_at DESC;

SELECT '✅ Stale tokens cleaned up' AS status;

