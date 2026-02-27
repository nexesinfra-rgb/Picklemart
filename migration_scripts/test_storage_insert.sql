BEGIN;

-- Simulate authenticated user
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = 'd341eb0b-d8f1-4bc1-89ef-06da050aa6af';

-- Try to insert a storage object
INSERT INTO storage.objects (
    bucket_id, 
    name, 
    owner,
    metadata
) VALUES (
    'product-images', 
    'products/test_image.jpg', 
    'd341eb0b-d8f1-4bc1-89ef-06da050aa6af',
    '{"mimetype": "image/jpeg"}'::jsonb
) RETURNING id, name;

ROLLBACK;
