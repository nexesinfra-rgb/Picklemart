SELECT 
    p.id, 
    p.email, 
    p.role, 
    u.id as auth_id 
FROM auth.users u 
LEFT JOIN public.profiles p ON u.id = p.id 
WHERE u.email = 'admin@sm.com';
