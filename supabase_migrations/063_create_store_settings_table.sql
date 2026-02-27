-- Create store_settings table
CREATE TABLE IF NOT EXISTS public.store_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    email TEXT,
    gst_number TEXT,
    logo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Allow everyone to read store settings
CREATE POLICY "Everyone can read store settings"
    ON public.store_settings
    FOR SELECT
    USING (true);

-- Allow admins to insert/update/delete
CREATE POLICY "Admins can manage store settings"
    ON public.store_settings
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
    );

-- Insert default store settings if not exists
INSERT INTO public.store_settings (name, address, phone, email, gst_number)
SELECT 'PICKLE MART', 'D.No.25-4-28, 1st Floor, KSR st, R.R.Pet, Eluru-2.', '9676494040', 'picklemarts@gmail.com', '20122111000068'
WHERE NOT EXISTS (SELECT 1 FROM public.store_settings);
