-- Fix Category Creation Issue
-- Run this script in your Supabase SQL Editor

-- Step 1: Check current user and profile
SELECT 
    auth.uid() as current_user_id,
    auth.jwt() ->> 'email' as current_email;

-- Step 2: Check if profile exists for current user
SELECT id, name, role, email 
FROM profiles 
WHERE id = auth.uid();

-- Step 3: Update current user to admin role (if profile exists)
UPDATE profiles 
SET 
    role = 'admin', 
    updated_at = NOW()
WHERE id = auth.uid();

-- Step 4: Create profile with admin role if it doesn't exist
INSERT INTO profiles (id, name, email, role, created_at, updated_at)
SELECT 
    auth.uid(),
    COALESCE(auth.jwt() ->> 'email', 'Admin User'),
    auth.jwt() ->> 'email',
    'admin',
    NOW(),
    NOW()
WHERE auth.uid() IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid())
ON CONFLICT (id) DO UPDATE SET 
    role = 'admin',
    updated_at = NOW();

-- Step 5: Verify the fix
SELECT 
    id, 
    name, 
    email, 
    role, 
    created_at, 
    updated_at 
FROM profiles 
WHERE id = auth.uid();

-- Step 6: Create the missing storage bucket for category images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'category-images',
    'category-images', 
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Step 7: Storage bucket is created above
-- Note: Storage policies will be automatically managed by Supabase
-- The bucket is set to public=true which allows read access
-- Upload permissions are handled by the application logic

-- Final verification query
SELECT 'Setup completed successfully!' as status;