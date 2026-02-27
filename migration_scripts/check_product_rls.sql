SELECT 
    tablename, 
    policyname, 
    cmd, 
    qual, 
    with_check 
FROM pg_policies 
WHERE tablename = 'products' OR tablename = 'product_variants';
