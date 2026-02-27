-- Add unique constraint to ensure one address per user
-- This migration enforces that each user can only have one address

-- First, handle any existing duplicate addresses by keeping only the most recent one per user
-- This is a safety measure in case there are already duplicates
DO $$
DECLARE
    user_record RECORD;
BEGIN
    FOR user_record IN 
        SELECT user_id, COUNT(*) as count
        FROM addresses
        GROUP BY user_id
        HAVING COUNT(*) > 1
    LOOP
        -- Keep only the most recent address for each user
        DELETE FROM addresses
        WHERE user_id = user_record.user_id
        AND id NOT IN (
            SELECT id
            FROM addresses
            WHERE user_id = user_record.user_id
            ORDER BY created_at DESC
            LIMIT 1
        );
    END LOOP;
END $$;

-- Add unique constraint on user_id
-- This will prevent any future duplicate addresses
ALTER TABLE addresses 
ADD CONSTRAINT unique_user_address UNIQUE (user_id);

-- Add comment to document the constraint
COMMENT ON CONSTRAINT unique_user_address ON addresses IS 
'Ensures each user can only have one address. This constraint enforces the single-address-per-user business rule.';

