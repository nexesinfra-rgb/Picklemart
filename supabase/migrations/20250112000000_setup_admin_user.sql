-- Setup Admin User with ID: 82fd273a-ba63-4577-84f9-16dce9c06d3d
-- Run this script in Supabase SQL Editor

-- Step 1: Verify and ensure admin user has admin role
UPDATE PROFILES
SET
    ROLE = 'admin',
    UPDATED_AT = NOW(
    )
WHERE
    ID = '82fd273a-ba63-4577-84f9-16dce9c06d3d'::UUID;

-- Step 2: Verify admin user exists and has admin role
SELECT
    ID,
    NAME,
    EMAIL,
    ROLE,
    CREATED_AT,
    UPDATED_AT
FROM
    PROFILES
WHERE
    ID = '82fd273a-ba63-4577-84f9-16dce9c06d3d'::UUID;

-- Step 3: Ensure storage bucket exists for product images
INSERT INTO STORAGE.BUCKETS (
    ID,
    NAME,
    PUBLIC,
    FILE_SIZE_LIMIT,
    ALLOWED_MIME_TYPES
) VALUES (
    'product-images',
    'product-images',
    TRUE,
    10485760, -- 10MB limit
    ARRAY['image/jpeg',
    'image/png',
    'image/gif',
    'image/webp']
) ON CONFLICT (
    ID
) DO UPDATE SET PUBLIC = TRUE,
FILE_SIZE_LIMIT = 10485760,
ALLOWED_MIME_TYPES = ARRAY['image/jpeg',
'image/png',
'image/gif',
'image/webp'];

-- Step 4: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Authenticated users can upload product images" ON STORAGE.OBJECTS;

DROP POLICY IF EXISTS "Authenticated users can update product images" ON STORAGE.OBJECTS;

DROP POLICY IF EXISTS "Authenticated users can delete product images" ON STORAGE.OBJECTS;

DROP POLICY IF EXISTS "Public can read product images" ON STORAGE.OBJECTS;

-- Step 5: Create storage policies for product-images bucket
CREATE POLICY "Authenticated users can upload product images"
ON STORAGE.OBJECTS
FOR INSERT
TO AUTHENTICATED
WITH CHECK (
    BUCKET_ID = 'product-images' AND
    EXISTS (
    SELECT
         1
    FROM
         PROFILES
    WHERE
         ID = AUTH.UID()
        AND ROLE IN ('admin', 'manager', 'support')
)
);

CREATE POLICY "Authenticated users can update product images"
ON STORAGE.OBJECTS
FOR UPDATE
TO AUTHENTICATED
USING (
    BUCKET_ID = 'product-images' AND
    EXISTS (
    SELECT
         1
    FROM
         PROFILES
    WHERE
         ID = AUTH.UID()
        AND ROLE IN ('admin', 'manager', 'support')
)
)
WITH CHECK (
    BUCKET_ID = 'product-images' AND
    EXISTS (
    SELECT
         1
    FROM
         PROFILES
    WHERE
         ID = AUTH.UID()
        AND ROLE IN ('admin', 'manager', 'support')
)
);

CREATE POLICY "Authenticated users can delete product images"
ON STORAGE.OBJECTS
FOR DELETE
TO AUTHENTICATED
USING (
    BUCKET_ID = 'product-images' AND
    EXISTS (
    SELECT
         1
    FROM
         PROFILES
    WHERE
         ID = AUTH.UID()
        AND ROLE IN ('admin', 'manager', 'support')
)
);

CREATE POLICY "Public can read product images"
ON STORAGE.OBJECTS
FOR SELECT
TO PUBLIC
USING (BUCKET_ID = 'product-images');

-- Step 6: Final verification
SELECT
    '✅ Admin Setup Complete' AS STATUS,
    (
        SELECT
            ROLE
        FROM
            PROFILES
        WHERE
            ID = '82fd273a-ba63-4577-84f9-16dce9c06d3d'::UUID
    ) AS ADMIN_ROLE,
    (
        SELECT
            EXISTS(
                SELECT
                    1
                FROM
                    STORAGE.BUCKETS
                WHERE
                    ID = 'product-images'
            )
    ) AS STORAGE_BUCKET_EXISTS,
    (
        SELECT
            COUNT(*)
        FROM
            PG_POLICIES
        WHERE
            SCHEMANAME = 'storage'
            AND TABLENAME = 'objects'
            AND POLICYNAME LIKE '%product images%'
    ) AS STORAGE_POLICIES_COUNT;