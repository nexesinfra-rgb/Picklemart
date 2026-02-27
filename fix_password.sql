UPDATE auth.users SET encrypted_password = extensions.crypt('admin123', extensions.gen_salt('bf')) WHERE email = 'admin@sm.com';
