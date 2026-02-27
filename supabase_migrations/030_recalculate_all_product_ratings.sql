-- ============================================================================
-- Recalculate All Product Ratings
-- ============================================================================
-- This migration recalculates average_rating and rating_count for ALL products
-- based on existing data in the product_ratings table.
-- This fixes the issue where products have ratings but the products table
-- doesn't have the aggregated rating data updated.

-- Step 1: Ensure the trigger function exists and is correct
CREATE OR REPLACE FUNCTION PUBLIC.UPDATE_PRODUCT_RATING()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate new average rating and count
    UPDATE PUBLIC.PRODUCTS
    SET 
        AVERAGE_RATING = (
            SELECT COALESCE(ROUND(AVG(RATING)::NUMERIC, 2), 0.00)
            FROM PUBLIC.PRODUCT_RATINGS
            WHERE PRODUCT_ID = COALESCE(NEW.PRODUCT_ID, OLD.PRODUCT_ID)
        ),
        RATING_COUNT = (
            SELECT COUNT(*)
            FROM PUBLIC.PRODUCT_RATINGS
            WHERE PRODUCT_ID = COALESCE(NEW.PRODUCT_ID, OLD.PRODUCT_ID)
        ),
        UPDATED_AT = NOW()
    WHERE ID = COALESCE(NEW.PRODUCT_ID, OLD.PRODUCT_ID);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE PLPGSQL;

-- Step 2: Recalculate ratings for ALL products
-- This updates products that have ratings in product_ratings table
UPDATE PUBLIC.PRODUCTS p
SET 
    AVERAGE_RATING = COALESCE(
        (
            SELECT ROUND(AVG(pr.RATING)::NUMERIC, 2)
            FROM PUBLIC.PRODUCT_RATINGS pr
            WHERE pr.PRODUCT_ID = p.ID
        ),
        0.00
    ),
    RATING_COUNT = COALESCE(
        (
            SELECT COUNT(*)
            FROM PUBLIC.PRODUCT_RATINGS pr
            WHERE pr.PRODUCT_ID = p.ID
        ),
        0
    ),
    UPDATED_AT = NOW()
WHERE EXISTS (
    SELECT 1
    FROM PUBLIC.PRODUCT_RATINGS pr
    WHERE pr.PRODUCT_ID = p.ID
);

-- Step 3: Reset ratings for products that have no ratings
-- This ensures products without any ratings have average_rating = 0.00 and rating_count = 0
UPDATE PUBLIC.PRODUCTS p
SET 
    AVERAGE_RATING = 0.00,
    RATING_COUNT = 0,
    UPDATED_AT = NOW()
WHERE NOT EXISTS (
    SELECT 1
    FROM PUBLIC.PRODUCT_RATINGS pr
    WHERE pr.PRODUCT_ID = p.ID
)
AND (p.AVERAGE_RATING IS NULL OR p.AVERAGE_RATING != 0.00 OR p.RATING_COUNT IS NULL OR p.RATING_COUNT != 0);

-- Step 4: Ensure triggers are properly set up (recreate if needed)
DROP TRIGGER IF EXISTS TRG_UPDATE_PRODUCT_RATING_INSERT ON PUBLIC.PRODUCT_RATINGS;
CREATE TRIGGER TRG_UPDATE_PRODUCT_RATING_INSERT
    AFTER INSERT ON PUBLIC.PRODUCT_RATINGS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.UPDATE_PRODUCT_RATING();

DROP TRIGGER IF EXISTS TRG_UPDATE_PRODUCT_RATING_UPDATE ON PUBLIC.PRODUCT_RATINGS;
CREATE TRIGGER TRG_UPDATE_PRODUCT_RATING_UPDATE
    AFTER UPDATE ON PUBLIC.PRODUCT_RATINGS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.UPDATE_PRODUCT_RATING();

DROP TRIGGER IF EXISTS TRG_UPDATE_PRODUCT_RATING_DELETE ON PUBLIC.PRODUCT_RATINGS;
CREATE TRIGGER TRG_UPDATE_PRODUCT_RATING_DELETE
    AFTER DELETE ON PUBLIC.PRODUCT_RATINGS
    FOR EACH ROW
    EXECUTE FUNCTION PUBLIC.UPDATE_PRODUCT_RATING();

