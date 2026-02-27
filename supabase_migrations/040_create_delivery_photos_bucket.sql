-- Create Delivery Photos Storage Bucket and RLS Policies
-- This migration ensures the bucket exists and creates proper RLS policies for delivery shop photo uploads

-- Step 1: Ensure storage bucket exists for delivery photos
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
) VALUES (
    'delivery-photos',
    'delivery-photos',
    true, -- Public bucket - photos can be displayed directly via public URLs
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Step 2: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Authenticated users can upload delivery photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update delivery photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete delivery photos" ON storage.objects;
DROP POLICY IF EXISTS "Public can read delivery photos" ON storage.objects;

-- Step 3: Create RLS policies for delivery-photos bucket

-- Policy: Allow authenticated users to upload delivery photos
-- Any authenticated user can upload to orders/{user_id}/* path
CREATE POLICY "Authenticated users can upload delivery photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'delivery-photos' AND
    name LIKE 'orders/' || auth.uid()::text || '/%'
);

-- Policy: Allow authenticated users to update their own delivery photos
CREATE POLICY "Authenticated users can update delivery photos"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'delivery-photos' AND
    name LIKE 'orders/' || auth.uid()::text || '/%'
)
WITH CHECK (
    bucket_id = 'delivery-photos' AND
    name LIKE 'orders/' || auth.uid()::text || '/%'
);

-- Policy: Allow authenticated users to delete their own delivery photos
CREATE POLICY "Authenticated users can delete delivery photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'delivery-photos' AND
    name LIKE 'orders/' || auth.uid()::text || '/%'
);

-- Policy: Allow public to read delivery photos (for displaying in admin)
CREATE POLICY "Public can read delivery photos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'delivery-photos');

-- Migration completed successfully!
-- 
-- Verification:
-- ✅ Storage bucket 'delivery-photos' created/updated
-- ✅ RLS policies created for INSERT, UPDATE, DELETE, SELECT
-- ✅ Authenticated users can upload photos to orders/{user_id}/* path
-- ✅ Public can read all delivery photos (for admin display)
-- ✅ Public bucket - photos accessible via public URLs
--
-- To verify manually, run:
-- SELECT * FROM storage.buckets WHERE id = 'delivery-photos';
-- SELECT policyname, cmd FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE '%delivery photos%';

