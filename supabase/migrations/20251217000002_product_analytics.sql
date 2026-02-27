-- Product analytics: views and order-level stats per product
-- Tables: product_views, product_order_analytics
-- RLS: admin/manager/support can read/write; authenticated users can write views/orders

-- product_views tracks user/product views with location
CREATE TABLE IF NOT EXISTS public.product_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    viewed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    session_id TEXT,
    city TEXT,
    area TEXT,
    address TEXT,
    user_agent TEXT
);

CREATE INDEX IF NOT EXISTS idx_product_views_product ON public.product_views(product_id);
CREATE INDEX IF NOT EXISTS idx_product_views_viewed_at ON public.product_views(viewed_at DESC);

-- product_order_analytics stores denormalized order-item analytics with location
CREATE TABLE IF NOT EXISTS public.product_order_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    ordered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    city TEXT,
    area TEXT,
    address TEXT
);

CREATE INDEX IF NOT EXISTS idx_poa_product ON public.product_order_analytics(product_id);
CREATE INDEX IF NOT EXISTS idx_poa_ordered_at ON public.product_order_analytics(ordered_at DESC);

-- Enable RLS
ALTER TABLE public.product_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_order_analytics ENABLE ROW LEVEL SECURITY;

-- Helper policy predicates
-- Admin roles: admin/manager/support

-- SELECT policies (admins)
DROP POLICY IF EXISTS "Admins can select product_views" ON public.product_views;
CREATE POLICY "Admins can select product_views" ON public.product_views
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin','manager','support')
  )
);

DROP POLICY IF EXISTS "Admins can select product_order_analytics" ON public.product_order_analytics;
CREATE POLICY "Admins can select product_order_analytics" ON public.product_order_analytics
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin','manager','support')
  )
);

-- INSERT policies
DROP POLICY IF EXISTS "Authenticated can insert product_views" ON public.product_views;
CREATE POLICY "Authenticated can insert product_views" ON public.product_views
FOR INSERT TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Authenticated can insert product_order_analytics" ON public.product_order_analytics;
CREATE POLICY "Authenticated can insert product_order_analytics" ON public.product_order_analytics
FOR INSERT TO authenticated
WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE/DELETE restricted to admins
DROP POLICY IF EXISTS "Admins can update product_views" ON public.product_views;
CREATE POLICY "Admins can update product_views" ON public.product_views
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin','manager','support')
  )
) WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin','manager','support')
  )
);

DROP POLICY IF EXISTS "Admins can delete product_views" ON public.product_views;
CREATE POLICY "Admins can delete product_views" ON public.product_views
FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin','manager','support')
  )
);

DROP POLICY IF EXISTS "Admins can update product_order_analytics" ON public.product_order_analytics;
CREATE POLICY "Admins can update product_order_analytics" ON public.product_order_analytics
FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin','manager','support')
  )
) WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin','manager','support')
  )
);

DROP POLICY IF EXISTS "Admins can delete product_order_analytics" ON public.product_order_analytics;
CREATE POLICY "Admins can delete product_order_analytics" ON public.product_order_analytics
FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin','manager','support')
  )
);

