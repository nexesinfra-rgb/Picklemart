-- Add featured flags and ordering to products table
-- Run this in Supabase SQL Editor or via migrations

-- 1) Add columns if they do not already exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'products'
      AND column_name = 'is_featured'
  ) THEN
    ALTER TABLE public.products
      ADD COLUMN is_featured BOOLEAN NOT NULL DEFAULT FALSE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'products'
      AND column_name = 'featured_position'
  ) THEN
    ALTER TABLE public.products
      ADD COLUMN featured_position INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;

-- 2) Index to speed up featured queries
CREATE INDEX IF NOT EXISTS idx_products_featured_position
  ON public.products (is_featured, featured_position, created_at DESC);

-- 3) Simple verification query
SELECT
  '✅ Featured flags added to products' AS status,
  (SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'products'
      AND column_name = 'is_featured'
  )) AS has_is_featured,
  (SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'products'
      AND column_name = 'featured_position'
  )) AS has_featured_position;


