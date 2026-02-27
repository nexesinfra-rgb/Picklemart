-- ============================================
-- FIX ADMIN PROFILE - Run this in Supabase SQL Editor
-- ============================================
-- This script will:
-- 1. Find the admin user by email
-- 2. Create/update the admin profile with role='admin'
-- ============================================

DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- Step 1: Find admin user by email
    SELECT id INTO admin_user_id
    FROM auth.users
    WHERE email = 'admin@sm.com'
    LIMIT 1;
    
    -- Step 2: If user found, create/update profile
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
        
        RAISE NOTICE '✅ SUCCESS: Admin profile created/updated!';
        RAISE NOTICE '   User ID: %', admin_user_id;
        RAISE NOTICE '   Email: admin@sm.com';
        RAISE NOTICE '   Role: admin';
    ELSE
        RAISE EXCEPTION '❌ ERROR: Admin user not found!
        
Please do the following:
1. Go to Supabase Dashboard → Authentication → Users
2. Check if admin@sm.com exists
3. If not, create it:
   - Click "Add User" → "Create new user"
   - Email: admin@sm.com
   - Password: admin123
   - Auto Confirm User: ✅ Yes
4. Then run this script again';
    END IF;
END $$;

-- Step 3: Verify the profile was created
SELECT 
    p.id as profile_id,
    p.name,
    p.email,
    p.role,
    p.created_at,
    u.email as auth_email,
    u.created_at as user_created_at
FROM public.profiles p
JOIN auth.users u ON p.id = u.id
WHERE p.email = 'admin@sm.com';

