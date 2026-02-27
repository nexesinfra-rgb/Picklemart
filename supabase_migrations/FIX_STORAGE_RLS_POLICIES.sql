-- Fix Supabase Storage RLS Policies for product-images Bucket
-- This migration ensures the bucket exists and creates proper RLS policies

-- Step 1: Ensure storage bucket exists for product images
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
) VALUES (
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

-- Step 2: Drop existing policies if they exist (to avoid conflicts)
-- Note: RLS is already enabled on storage.objects by Supabase
DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete product images" ON storage.objects;
DROP POLICY IF EXISTS "Public can read product images" ON storage.objects;

-- Step 4: Create RLS policies for product-images bucket

-- Policy: Allow authenticated admin/manager/support users to upload images
CREATE POLICY "Authenticated users can upload product images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1
        FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow authenticated admin/manager/support users to update images
CREATE POLICY "Authenticated users can update product images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1
        FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
)
WITH CHECK (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1
        FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow authenticated admin/manager/support users to delete images
CREATE POLICY "Authenticated users can delete product images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'product-images' AND
    EXISTS (
        SELECT 1
        FROM profiles
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

-- Migration completed successfully!
-- 
-- Verification:
-- ✅ Storage bucket 'product-images' created/updated
-- ✅ RLS policies created for INSERT, UPDATE, DELETE, SELECT
-- ✅ RLS is enabled on storage.objects (managed by Supabase)
--
-- To verify manually, run:
-- SELECT * FROM storage.buckets WHERE id = 'product-images';
-- SELECT policyname, cmd FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE '%product images%';

