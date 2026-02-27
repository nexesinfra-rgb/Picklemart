SELECT email, email_confirmed_at, encrypted_password FROM auth.users WHERE email = 'admin@sm.com';
SELECT count(*) as total_users FROM auth.users;