-- Create Hero Images Table
-- This migration creates the hero_images table for managing hero section carousel images

-- Step 1: Create hero_images table
CREATE TABLE IF NOT EXISTS public.hero_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    image_url TEXT NOT NULL,
    title TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_hero_images_is_active ON public.hero_images(is_active);
CREATE INDEX IF NOT EXISTS idx_hero_images_display_order ON public.hero_images(display_order);
CREATE INDEX IF NOT EXISTS idx_hero_images_created_at ON public.hero_images(created_at DESC);

-- Step 3: Create trigger for updated_at auto-update
CREATE OR REPLACE FUNCTION update_hero_images_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_hero_images_updated_at ON public.hero_images;
CREATE TRIGGER trigger_update_hero_images_updated_at
    BEFORE UPDATE ON public.hero_images
    FOR EACH ROW
    EXECUTE FUNCTION update_hero_images_updated_at();

-- Step 4: Enable RLS
ALTER TABLE public.hero_images ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop existing policies if they exist
DROP POLICY IF EXISTS "Public can read active hero images" ON public.hero_images;
DROP POLICY IF EXISTS "Admins can manage hero images" ON public.hero_images;

-- Step 6: Create RLS policies
-- Policy: Public can read active hero images
CREATE POLICY "Public can read active hero images"
ON public.hero_images
FOR SELECT
TO public
USING (is_active = TRUE);

-- Policy: Admins can manage hero images
CREATE POLICY "Admins can manage hero images"
ON public.hero_images
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Step 7: Ensure storage bucket exists for hero images
INSERT INTO storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
) VALUES (
    'hero-images',
    'hero-images',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

-- Step 8: Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Authenticated users can upload hero images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update hero images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete hero images" ON storage.objects;
DROP POLICY IF EXISTS "Public can read hero images" ON storage.objects;

-- Step 9: Create storage policies for hero-images bucket
-- Policy: Allow authenticated admin/manager/support users to upload images
CREATE POLICY "Authenticated users can upload hero images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'hero-images' AND
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow authenticated admin/manager/support users to update images
CREATE POLICY "Authenticated users can update hero images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'hero-images' AND
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
)
WITH CHECK (
    bucket_id = 'hero-images' AND
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Allow authenticated admin/manager/support users to delete images
CREATE POLICY "Authenticated users can delete hero images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'hero-images' AND
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'manager', 'support')
    )
);

-- Policy: Public can read hero images
CREATE POLICY "Public can read hero images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'hero-images');

