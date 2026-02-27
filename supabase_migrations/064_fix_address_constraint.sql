-- Fix missing unique constraint on addresses table
-- This migration ensures the unique constraint exists, handling cases where it might have been missed

DO $$
BEGIN
    -- Check if the constraint already exists
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'unique_user_address'
    ) THEN
        -- Clean up duplicates if any (keep most recent)
        DELETE FROM addresses a
        WHERE a.id NOT IN (
            SELECT DISTINCT ON (user_id) id
            FROM addresses
            ORDER BY user_id, updated_at DESC, created_at DESC
        );

        -- Add the unique constraint
        ALTER TABLE addresses 
        ADD CONSTRAINT unique_user_address UNIQUE (user_id);
    END IF;
END $$;
