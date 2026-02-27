-- Create Admin Profile for Existing Admin User
-- This script creates a profile for the admin user that already exists in auth.users
-- Email: admin@sm.com

-- IMPORTANT: Replace ADMIN_USER_ID_HERE with the actual UUID from Supabase Dashboard
-- To get the User ID:
-- 1. Go to Supabase Dashboard → Authentication → Users
-- 2. Find the user with email: admin@sm.com
-- 3. Copy the User ID (UUID)
-- 4. Replace ADMIN_USER_ID_HERE below with that UUID

-- Option 1: If you know the User ID, use this:
/*
INSERT INTO public.profiles (
    id,
    name,
    email,
    role,
    created_at,
    updated_at
) VALUES (
    'ADMIN_USER_ID_HERE',  -- Replace with actual UUID from auth.users
    'Admin',
    'admin@sm.com',
    'admin',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    name = 'Admin',
    email = 'admin@sm.com',
    role = 'admin',
    updated_at = NOW();
*/

-- Option 2: Dynamic lookup (requires service_role key or admin access)
-- This will find the admin user by email and create the profile
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Get the admin user ID from auth.users
    SELECT id INTO admin_user_id
    FROM auth.users
    WHERE email = 'admin@sm.com'
    LIMIT 1;
    
    -- If user exists, create/update profile
    IF admin_user_id IS NOT NULL THEN
        INSERT INTO public.profiles (
            id,
            name,
            email,
            role,
            created_at,
            updated_at
        ) VALUES (
            admin_user_id,
            'Admin',
            'admin@sm.com',
            'admin',
            NOW(),
            NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
            name = 'Admin',
            email = 'admin@sm.com',
            role = 'admin',
            updated_at = NOW();
        
        RAISE NOTICE '✅ Admin profile created/updated for user ID: %', admin_user_id;
    ELSE
        RAISE EXCEPTION '❌ Admin user not found. Please create admin@sm.com in Supabase Dashboard first.';
    END IF;
END $$;

-- Verify the profile was created
SELECT 
    id,
    name,
    email,
    role,
    created_at
FROM public.profiles
WHERE email = 'admin@sm.com';

