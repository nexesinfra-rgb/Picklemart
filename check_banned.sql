UPDATE auth.users SET confirmation_token = NULL, recovery_token = NULL WHERE email = 'admin@sm.com';
SELECT banned_until FROM auth.users WHERE email = 'admin@sm.com';