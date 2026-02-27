-- Create Admin User and Setup
-- Run this script in your Supabase SQL Editor to create an admin user
-- This will create an admin user that can log in and manage products

-- Step 1: Create admin user in auth.users (if not exists)
-- Note: You need to create the user in Supabase Auth Dashboard first
-- Go to Authentication > Users > Add User
-- Email: admin@sm.com
-- Password: (set a secure password)
-- Then run this script to set up the profile

-- Step 2: Get the user ID from auth.users
-- Replace 'admin@sm.com' with your admin email
DO $$
DECLARE
    admin_user_id UUID;
    admin_email TEXT := 'admin@sm.com';
BEGIN
    -- Get user ID from auth.users
    SELECT id INTO admin_user_id
    FROM auth.users
    WHERE email = admin_email;

    -- If user exists, create or update profile
    IF admin_user_id IS NOT NULL THEN
        -- Insert or update profile with admin role
        INSERT INTO profiles (id, name, email, role, created_at, updated_at)
        VALUES (
            admin_user_id,
            'Admin User',
            admin_email,
            'admin',
            NOW(),
            NOW()
        )
        ON CONFLICT (id) 
        DO UPDATE SET 
            role = 'admin',
            name = 'Admin User',
            email = admin_email,
            updated_at = NOW();
        
        RAISE NOTICE 'Admin profile created/updated for user: %', admin_email;
    ELSE
        RAISE NOTICE 'User with email % not found. Please create the user in Supabase Auth Dashboard first.', admin_email;
    END IF;
END $$;

-- Step 3: Verify admin profile was created
SELECT 
    p.id,
    p.name,
    p.email,
    p.role,
    p.created_at,
    u.email as auth_email
FROM profiles p
JOIN auth.users u ON p.id = u.id
WHERE p.role = 'admin';

-- Step 4: Ensure storage bucket exists for product images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Step 5: Create storage policies for product-images bucket
-- Policy: Allow authenticated users to upload images
CREATE POLICY IF NOT EXISTS "Authenticated users can upload product images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow authenticated users to update images
CREATE POLICY IF NOT EXISTS "Authenticated users can update product images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow authenticated users to delete images
CREATE POLICY IF NOT EXISTS "Authenticated users can delete product images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow public read access to product images
CREATE POLICY IF NOT EXISTS "Public can read product images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- Step 6: Verify storage bucket and policies
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
WHERE id = 'product-images';

SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND policyname LIKE '%product images%';

-- Final verification
SELECT 'Admin setup completed! Please verify the admin user can log in.' as status;










