SELECT 
    id, 
    aud, 
    role, 
    email, 
    email_confirmed_at, 
    phone, 
    phone_confirmed_at, 
    confirmation_token, 
    recovery_token, 
    email_change_token_new, 
    email_change, 
    is_super_admin, 
    created_at, 
    updated_at, 
    banned_until, 
    deleted_at,
    raw_app_meta_data,
    raw_user_meta_data
FROM auth.users 
WHERE email = 'admin@sm.com';
