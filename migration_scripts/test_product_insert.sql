BEGIN;

-- Simulate authenticated user
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = 'd341eb0b-d8f1-4bc1-89ef-06da050aa6af';

-- Try to insert a product
INSERT INTO public.products (
    name, 
    price, 
    stock, 
    description, 
    image_url, 
    images, 
    categories, 
    tags, 
    sku, 
    is_active
) VALUES (
    'Test Product RLS', 
    100, 
    10, 
    'Test Description', 
    'https://via.placeholder.com/150', 
    ARRAY['https://via.placeholder.com/150'], 
    ARRAY['Test'], 
    ARRAY['test'], 
    'TEST-SKU-RLS-001', 
    true
) RETURNING id, name;

ROLLBACK;
