-- Create admin user in Supabase
-- This migration creates an admin user with email admin@sm.com and password admin123
-- Note: In Supabase, you cannot directly insert into auth.users via SQL for security reasons
-- This script provides instructions and creates the admin profile

-- IMPORTANT: Before running this migration, you need to manually create the admin user:
-- 1. Go to Supabase Dashboard > Authentication > Users
-- 2. Click "Add User" > "Create new user"
-- 3. Email: admin@sm.com
-- 4. Password: admin123
-- 5. Auto Confirm User: Yes (to skip email confirmation)
-- 6. After creating the user, note the user ID (UUID)
-- 7. Then run the profile creation part below with the actual user ID

-- Function to create admin profile (uses the actual admin user UUID)
DO $$

DECLARE
    ADMIN_USER_ID UUID := '82fd273a-ba63-4577-84f9-16dce9c06d3d';
BEGIN
 
    -- Verify user exists, if not try to find by email
    IF NOT EXISTS (
        SELECT
            1
        FROM
            AUTH.USERS
        WHERE
            ID = ADMIN_USER_ID
    ) THEN
        SELECT
            ID INTO ADMIN_USER_ID
        FROM
            AUTH.USERS
        WHERE
            EMAIL = 'admin@sm.com' LIMIT 1;
    END IF;
 

    -- If user exists, create/update their profile
    IF ADMIN_USER_ID IS NOT NULL THEN
 
        -- Insert or update admin profile
        INSERT INTO PUBLIC.PROFILES (
            ID,
            NAME,
            EMAIL,
            ROLE,
            CREATED_AT,
            UPDATED_AT
        ) VALUES (
            ADMIN_USER_ID,
            'Admin',
            'admin@sm.com',
            'admin',
            NOW(),
            NOW()
        ) ON CONFLICT (
            ID
        ) DO UPDATE SET NAME = 'Admin', EMAIL = 'admin@sm.com', ROLE = 'admin', UPDATED_AT = NOW(
        );
    ELSE
        RAISE NOTICE 'Admin user not found. Please create the user in Supabase Dashboard first.';
    END IF;
END $$;
 

-- Direct INSERT statement (alternative to DO block above)
-- This uses the actual admin user UUID: 82fd273a-ba63-4577-84f9-16dce9c06d3d
INSERT INTO PUBLIC.PROFILES (
    ID,
    NAME,
    EMAIL,
    ROLE,
    CREATED_AT,
    UPDATED_AT
) VALUES (
    '82fd273a-ba63-4577-84f9-16dce9c06d3d', -- Admin user UUID
    'Admin',
    'admin@sm.com',
    'admin',
    NOW(),
    NOW()
) ON CONFLICT (
    ID
) DO UPDATE SET NAME = 'Admin', EMAIL = 'admin@sm.com', ROLE = 'admin', UPDATED_AT = NOW(
);