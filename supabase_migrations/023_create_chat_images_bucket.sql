-- Create Chat Images Storage Bucket and RLS Policies
-- This migration ensures the bucket exists and creates proper RLS policies for chat image uploads

-- Step 1: Ensure storage bucket exists for chat images
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
) VALUES (
    'chat-images',
    'chat-images',
    false, -- Private bucket - users upload, but URLs are accessed via signed URLs
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- Step 2: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can upload their own chat images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own chat images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own chat images" ON storage.objects;
DROP POLICY IF EXISTS "Users and admins can read chat images" ON storage.objects;

-- Step 3: Create RLS policies for chat-images bucket

-- Policy: Allow authenticated users to upload their own chat images
-- Users can only upload to paths matching chat/{their_user_id}/*
CREATE POLICY "Users can upload their own chat images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'chat-images' AND
    name LIKE 'chat/' || auth.uid()::text || '/%'
);

-- Policy: Allow authenticated users to update their own chat images
CREATE POLICY "Users can update their own chat images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'chat-images' AND
    name LIKE 'chat/' || auth.uid()::text || '/%'
)
WITH CHECK (
    bucket_id = 'chat-images' AND
    name LIKE 'chat/' || auth.uid()::text || '/%'
);

-- Policy: Allow authenticated users to delete their own chat images
CREATE POLICY "Users can delete their own chat images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'chat-images' AND
    name LIKE 'chat/' || auth.uid()::text || '/%'
);

-- Policy: Allow authenticated users and admins to read chat images
-- Users can read images they uploaded, admins can read all images
CREATE POLICY "Users and admins can read chat images"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'chat-images' AND
    (
        -- Users can read their own images
        name LIKE 'chat/' || auth.uid()::text || '/%'
        OR
        -- Admins can read all images
        PUBLIC.IS_ADMIN(auth.uid())
    )
);

-- Migration completed successfully!
-- 
-- Verification:
-- ✅ Storage bucket 'chat-images' created/updated
-- ✅ RLS policies created for INSERT, UPDATE, DELETE, SELECT
-- ✅ Users can only manage images in their own folder (chat/{user_id}/*)
-- ✅ Users can read their own images, admins can read all images
-- ✅ Private bucket - URLs accessed via signed URLs
--
-- To verify manually, run:
-- SELECT * FROM storage.buckets WHERE id = 'chat-images';
-- SELECT policyname, cmd FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE '%chat images%';

