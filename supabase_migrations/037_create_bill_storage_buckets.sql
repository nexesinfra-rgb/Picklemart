-- Create Storage Buckets for Bills
-- Run this in Supabase SQL Editor

-- Step 1: Create bill-templates bucket
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
) VALUES (
    'bill-templates',
    'bill-templates',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Step 2: Create bill-pdfs bucket
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
) VALUES (
    'bill-pdfs',
    'bill-pdfs',
    true,
    5242880, -- 5MB limit
    ARRAY['application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['application/pdf'];

-- Step 3: Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can upload bill templates" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update bill templates" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete bill templates" ON storage.objects;
DROP POLICY IF EXISTS "Public can read bill templates" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload bill PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update bill PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete bill PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Public can read bill PDFs" ON storage.objects;

-- Step 4: Create RLS policies for bill-templates bucket

-- Policy: Admins can upload bill templates
CREATE POLICY "Admins can upload bill templates"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'bill-templates' AND
    EXISTS (
        SELECT 1 FROM PUBLIC.PROFILES
        WHERE ID = AUTH.UID()
        AND ROLE = 'admin'
    )
);

-- Policy: Admins can update bill templates
CREATE POLICY "Admins can update bill templates"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'bill-templates' AND
    EXISTS (
        SELECT 1 FROM PUBLIC.PROFILES
        WHERE ID = AUTH.UID()
        AND ROLE = 'admin'
    )
);

-- Policy: Admins can delete bill templates
CREATE POLICY "Admins can delete bill templates"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'bill-templates' AND
    EXISTS (
        SELECT 1 FROM PUBLIC.PROFILES
        WHERE ID = AUTH.UID()
        AND ROLE = 'admin'
    )
);

-- Policy: Public can read bill templates
CREATE POLICY "Public can read bill templates"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'bill-templates');

-- Step 5: Create RLS policies for bill-pdfs bucket

-- Policy: Admins can upload bill PDFs
CREATE POLICY "Admins can upload bill PDFs"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'bill-pdfs' AND
    EXISTS (
        SELECT 1 FROM PUBLIC.PROFILES
        WHERE ID = AUTH.UID()
        AND ROLE = 'admin'
    )
);

-- Policy: Admins can update bill PDFs
CREATE POLICY "Admins can update bill PDFs"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'bill-pdfs' AND
    EXISTS (
        SELECT 1 FROM PUBLIC.PROFILES
        WHERE ID = AUTH.UID()
        AND ROLE = 'admin'
    )
);

-- Policy: Admins can delete bill PDFs
CREATE POLICY "Admins can delete bill PDFs"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'bill-pdfs' AND
    EXISTS (
        SELECT 1 FROM PUBLIC.PROFILES
        WHERE ID = AUTH.UID()
        AND ROLE = 'admin'
    )
);

-- Policy: Public can read bill PDFs
CREATE POLICY "Public can read bill PDFs"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'bill-pdfs');

