-- Ensure pgcrypto is available
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Reset Admin Password to 'admin123'
UPDATE auth.users
SET encrypted_password = crypt('admin123', gen_salt('bf')),
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    banned_until = NULL,
    raw_app_meta_data = CASE 
        WHEN raw_app_meta_data IS NULL THEN '{"provider": "email", "providers": ["email"]}'::jsonb
        ELSE raw_app_meta_data || '{"provider": "email", "providers": ["email"]}'::jsonb
    END
WHERE email = 'admin@sm.com';

-- 2. Reset Phone User Password to '123456'
UPDATE auth.users
SET encrypted_password = crypt('123456', gen_salt('bf')),
    phone_confirmed_at = COALESCE(phone_confirmed_at, NOW()),
    banned_until = NULL,
    raw_app_meta_data = CASE 
        WHEN raw_app_meta_data IS NULL THEN '{"provider": "phone", "providers": ["phone"]}'::jsonb
        ELSE raw_app_meta_data || '{"provider": "phone", "providers": ["phone"]}'::jsonb
    END
WHERE email = '918074924125@phone.local';

-- 3. Verify existence and status (select confirmed_at just to see it, don't update it)
SELECT id, email, phone, encrypted_password, confirmed_at, banned_until 
FROM auth.users 
WHERE email IN ('admin@sm.com', '918074924125@phone.local');
