-- Create User Self-Deletion Function
-- This migration creates a PostgreSQL function that allows users to delete their own account
-- The function deletes the profile, which cascades to delete all related data
-- Run this in Supabase SQL Editor

-- Step 1: Create function to delete user account
-- This function verifies the user is authenticated and deletes their profile
-- All related data will be automatically deleted due to ON DELETE CASCADE constraints
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get the current authenticated user ID
    current_user_id := auth.uid();
    
    -- Check if user is authenticated
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated to delete account';
    END IF;
    
    -- Delete the profile - this will cascade delete all related data:
    -- - Orders and order items (ON DELETE CASCADE)
    -- - Cart items (ON DELETE CASCADE)
    -- - Wishlist items (ON DELETE CASCADE)
    -- - Addresses (if exists with ON DELETE CASCADE)
    -- - User sessions and locations (ON DELETE CASCADE)
    -- - Notifications (ON DELETE CASCADE)
    -- - Chat conversations and messages (ON DELETE CASCADE)
    -- - Product ratings (ON DELETE CASCADE)
    -- - GST details (if exists with ON DELETE CASCADE)
    DELETE FROM public.profiles
    WHERE id = current_user_id;
    
    -- Note: The auth.users entry will remain but will be orphaned
    -- The user won't be able to log in anymore since there's no profile
    -- In production, you might want to add logic to also delete from auth.users
    -- but that requires admin privileges or a Supabase Edge Function
    
END;
$$;

-- Step 2: Grant execute permission on the function to authenticated users
-- This allows authenticated users to call the function via RPC
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;

-- Step 3: Add comment for documentation
COMMENT ON FUNCTION delete_user_account() IS 'Allows authenticated users to delete their own account. Deletes profile and all related data via cascade constraints.';

-- Step 4: Verify the function was created
SELECT '✅ User self-deletion function created successfully' AS STATUS;

