-- Create Profile Avatars Storage Bucket and RLS Policies
-- This migration ensures the bucket exists and creates proper RLS policies for profile avatar uploads

-- Step 1: Ensure storage bucket exists for profile avatars
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
) VALUES (
    'profile-avatars',
    'profile-avatars',
    true,
    5242880, -- 5MB limit (smaller than product images since avatars are typically smaller)
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Step 2: Drop existing policies if they exist (to avoid conflicts)
-- Note: RLS is already enabled on storage.objects by Supabase
DROP POLICY IF EXISTS "Users can upload their own profile avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public can read profile avatars" ON storage.objects;

-- Step 3: Create RLS policies for profile-avatars bucket

-- Policy: Allow authenticated users to upload their own avatars
-- Users can only upload to paths matching avatars/{their_user_id}/*
CREATE POLICY "Users can upload their own profile avatars"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'profile-avatars' AND
    name LIKE 'avatars/' || auth.uid()::text || '/%'
);

-- Policy: Allow authenticated users to update their own avatars
CREATE POLICY "Users can update their own profile avatars"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'profile-avatars' AND
    name LIKE 'avatars/' || auth.uid()::text || '/%'
)
WITH CHECK (
    bucket_id = 'profile-avatars' AND
    name LIKE 'avatars/' || auth.uid()::text || '/%'
);

-- Policy: Allow authenticated users to delete their own avatars
CREATE POLICY "Users can delete their own profile avatars"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'profile-avatars' AND
    name LIKE 'avatars/' || auth.uid()::text || '/%'
);

-- Policy: Allow public read access to profile avatars (for displaying avatars)
CREATE POLICY "Public can read profile avatars"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-avatars');

-- Migration completed successfully!
-- 
-- Verification:
-- ✅ Storage bucket 'profile-avatars' created/updated
-- ✅ RLS policies created for INSERT, UPDATE, DELETE, SELECT
-- ✅ Users can only manage avatars in their own folder (avatars/{user_id}/*)
-- ✅ Public read access enabled for displaying avatars
--
-- To verify manually, run:
-- SELECT * FROM storage.buckets WHERE id = 'profile-avatars';
-- SELECT policyname, cmd FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE '%profile avatars%';

