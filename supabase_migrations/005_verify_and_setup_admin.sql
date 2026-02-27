-- Verify and Setup Admin User
-- Admin User ID: 82fd273a-ba63-4577-84f9-16dce9c06d3d

-- Step 1: Verify admin user exists in profiles table
SELECT 
    p.id,
    p.name,
    p.email,
    p.role,
    p.created_at,
    p.updated_at,
    u.email as auth_email,
    u.created_at as auth_created_at
FROM profiles p
JOIN auth.users u ON p.id = u.id
WHERE p.id = '82fd273a-ba63-4577-84f9-16dce9c06d3d'::uuid;

-- Step 2: Ensure admin user has admin role
UPDATE profiles 
SET 
    role = 'admin',
    updated_at = NOW()
WHERE id = '82fd273a-ba63-4577-84f9-16dce9c06d3d'::uuid
AND (role IS NULL OR role != 'admin');

-- Step 3: Verify admin role was set
SELECT 
    id,
    name,
    email,
    role,
    created_at,
    updated_at
FROM profiles
WHERE id = '82fd273a-ba63-4577-84f9-16dce9c06d3d'::uuid;

-- Step 4: Ensure storage bucket exists for product images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Step 5: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete product images" ON storage.objects;
DROP POLICY IF EXISTS "Public can read product images" ON storage.objects;

-- Step 6: Create storage policies for product-images bucket
-- Policy: Allow authenticated admin users to upload images
CREATE POLICY "Authenticated users can upload product images"
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

-- Policy: Allow authenticated admin users to update images
CREATE POLICY "Authenticated users can update product images"
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
)
WITH CHECK (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow authenticated admin users to delete images
CREATE POLICY "Authenticated users can delete product images"
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
CREATE POLICY "Public can read product images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- Step 7: Verify storage bucket exists
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets
WHERE id = 'product-images';

-- Step 8: Verify storage policies
SELECT 
    policyname,
    cmd,
    roles,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND policyname LIKE '%product images%';

-- Step 9: Final verification - Check admin user and storage setup
SELECT 
    'Admin User Setup' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = '82fd273a-ba63-4577-84f9-16dce9c06d3d'::uuid 
            AND role = 'admin'
        ) THEN '✅ Admin user has admin role'
        ELSE '❌ Admin user does not have admin role'
    END as admin_user_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM storage.buckets 
            WHERE id = 'product-images'
        ) THEN '✅ Storage bucket exists'
        ELSE '❌ Storage bucket does not exist'
    END as storage_bucket_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE schemaname = 'storage' 
            AND tablename = 'objects' 
            AND policyname LIKE '%product images%'
        ) THEN '✅ Storage policies exist'
        ELSE '❌ Storage policies do not exist'
    END as storage_policies_status;

-- Step 10: Verify admin user can access storage (check RLS)
SELECT 
    '82fd273a-ba63-4577-84f9-16dce9c06d3d'::uuid as admin_user_id,
    role,
    CASE 
        WHEN role IN ('admin', 'manager', 'support') THEN '✅ Can upload images'
        ELSE '❌ Cannot upload images'
    END as upload_permission
FROM profiles
WHERE id = '82fd273a-ba63-4577-84f9-16dce9c06d3d'::uuid;










