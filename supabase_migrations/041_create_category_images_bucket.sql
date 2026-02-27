-- Create Category Images Storage Bucket and RLS Policies
-- This migration ensures the bucket exists and creates proper RLS policies for category image uploads

-- Step 1: Ensure storage bucket exists for category images
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
) VALUES (
    'category-images',
    'category-images',
    true, -- Public bucket - images can be displayed directly via public URLs
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Step 2: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Admins can upload category images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update category images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete category images" ON storage.objects;
DROP POLICY IF EXISTS "Public can read category images" ON storage.objects;

-- Step 3: Create RLS policies for category-images bucket

-- Policy: Allow authenticated admin/manager/support users to upload category images
CREATE POLICY "Admins can upload category images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'category-images' AND
    EXISTS (
        SELECT 1
        FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow authenticated admin/manager/support users to update category images
CREATE POLICY "Admins can update category images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'category-images' AND
    EXISTS (
        SELECT 1
        FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
)
WITH CHECK (
    bucket_id = 'category-images' AND
    EXISTS (
        SELECT 1
        FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow authenticated admin/manager/support users to delete category images
CREATE POLICY "Admins can delete category images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'category-images' AND
    EXISTS (
        SELECT 1
        FROM profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow public to read category images (for displaying in app)
CREATE POLICY "Public can read category images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'category-images');

-- Migration completed successfully!
-- 
-- Verification:
-- ✅ Storage bucket 'category-images' created/updated
-- ✅ RLS policies created for INSERT, UPDATE, DELETE, SELECT
-- ✅ Authenticated admin/manager/support users can upload/update/delete images
-- ✅ Public can read all category images (for app display)
-- ✅ Public bucket - images accessible via public URLs
--
-- To verify manually, run:
-- SELECT * FROM storage.buckets WHERE id = 'category-images';
-- SELECT policyname, cmd FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE '%category images%';

