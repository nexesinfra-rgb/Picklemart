SELECT 
    email, 
    confirmation_token IS NULL as confirmation_token_is_null,
    confirmation_token,
    recovery_token IS NULL as recovery_token_is_null,
    email_change_token_new IS NULL as email_change_token_new_is_null
FROM auth.users 
WHERE email = 'test_user_final@sm.com';
