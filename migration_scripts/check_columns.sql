SELECT 
    column_name, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_schema = 'auth' 
  AND table_name = 'users'
  AND column_name IN ('confirmation_token', 'recovery_token', 'email_change_token_new', 'email_change_token_current');
