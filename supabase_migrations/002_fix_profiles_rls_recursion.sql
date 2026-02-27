-- Fix infinite recursion in profiles RLS policies
-- The admin policies were querying the profiles table, causing recursion

-- Drop existing admin policies
DROP POLICY IF EXISTS PROFILES_SELECT_ADMIN ON PUBLIC.PROFILES;

DROP POLICY IF EXISTS PROFILES_UPDATE_ADMIN ON PUBLIC.PROFILES;

DROP POLICY IF EXISTS PROFILES_SELECT_ADMIN ON PUBLIC.PROFILES;

DROP POLICY IF EXISTS PROFILES_UPDATE_ADMIN ON PUBLIC.PROFILES;

-- Create a security definer function to check admin role
-- This function bypasses RLS, preventing infinite recursion
CREATE OR REPLACE FUNCTION PUBLIC.IS_ADMIN(
    USER_ID UUID
) RETURNS BOOLEAN LANGUAGE PLPGSQL SECURITY DEFINER SET SEARCH_PATH = PUBLIC AS
    $$     BEGIN RETURN EXISTS (
        SELECT
            1
        FROM
            PUBLIC.PROFILES
        WHERE
            ID = USER_ID
            AND ROLE IN ('admin', 'manager', 'support')
    );
END;
$$    ;
 
-- Grant execute permission to authenticated users
GRANT  EXECUTE ON

FUNCTION PUBLIC.IS_ADMIN(
    UUID
) TO AUTHENTICATED;
 
-- Recreate admin policies using the security definer function
-- This prevents infinite recursion because the function bypasses RLS
CREATE POLICY PROFILES_SELECT_ADMIN ON PUBLIC.PROFILES FOR
SELECT
    USING (PUBLIC.IS_ADMIN(AUTH.UID()));
CREATE POLICY PROFILES_UPDATE_ADMIN ON PUBLIC.PROFILES FOR UPDATE USING (PUBLIC.IS_ADMIN(AUTH.UID())) WITH CHECK (PUBLIC.IS_ADMIN(AUTH.UID()));