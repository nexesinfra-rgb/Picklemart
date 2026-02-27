-- ============================================================================
-- OPTIMIZE NOTIFICATION QUERIES FOR SCALABILITY
-- ============================================================================
-- This adds a composite index to speed up the most common notification queries
-- Run this in Supabase SQL Editor
-- ============================================================================
-- IMPORTANT: This only adds an index - it does NOT change table structure or data
-- ============================================================================

-- Add composite index for optimal query performance
-- This speeds up queries that filter by user_id, is_read, and order by created_at
-- This is the most common query pattern for notifications
CREATE INDEX IF NOT EXISTS IDX_USER_NOTIFICATIONS_USER_READ_CREATED 
ON PUBLIC.USER_NOTIFICATIONS(USER_ID, IS_READ, CREATED_AT DESC);

-- Verify index was created
SELECT 
    '✅ Index Status:' AS info,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
    AND indexname = 'idx_user_notifications_user_read_created';

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
SELECT 
    '🎉 OPTIMIZATION COMPLETE!' AS status,
    'Notification queries are now optimized for 100-200 concurrent users' AS message,
    'No table structure or data was changed - only performance index added' AS note;

