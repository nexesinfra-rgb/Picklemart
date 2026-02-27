-- ============================================================================
-- Add Feedback Column to Product Ratings Table
-- ============================================================================
-- This migration adds a feedback/comments field to the product_ratings table
-- to allow users to provide written feedback along with their star ratings

-- Step 1: Add feedback column to product_ratings table
ALTER TABLE PUBLIC.PRODUCT_RATINGS 
ADD COLUMN IF NOT EXISTS FEEDBACK TEXT;

-- Step 2: Add index for feedback search (if needed in future)
-- Note: Full-text search on feedback can be added later if needed
-- CREATE INDEX IF NOT EXISTS IDX_PRODUCT_RATINGS_FEEDBACK ON PUBLIC.PRODUCT_RATINGS 
-- USING GIN(TO_TSVECTOR('english', COALESCE(FEEDBACK, '')));

-- Step 3: Add comment to column for documentation
COMMENT ON COLUMN PUBLIC.PRODUCT_RATINGS.FEEDBACK IS 'Optional text feedback/comment provided by the user along with their rating';

