# Fix 401 Unauthorized Authentication Error

## Problem

You're seeing a `401 (Unauthorized)` error when trying to log in:

```
POST https://bgqcuykvsiejgqeiefpi.supabase.co/auth/v1/token?grant_type=password 401 (Unauthorized)
```

## Common Causes

### 1. Email Confirmation Enabled (Most Common)

**Problem**: Supabase requires email confirmation before users can log in, but phone-based emails (like `919876543210@phone.local`) cannot receive confirmation emails.

**Solution**: Disable email confirmation in Supabase settings.

### 2. Invalid Credentials

**Problem**: Wrong email/phone number or password.

**Solution**: Verify credentials are correct.

### 3. User Account Doesn't Exist

**Problem**: Trying to log in with an account that hasn't been created.

**Solution**: Sign up first, or create the user in Supabase dashboard.

### 4. Supabase Configuration Issues

**Problem**: Incorrect Supabase URL or Anon Key.

**Solution**: Verify configuration in `lib/core/config/environment.dart`.

## Step-by-Step Fix

### Step 1: Disable Email Confirmation (Required for Phone-Based Auth)

1. **Go to Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project: `bgqcuykvsiejgqeiefpi`

2. **Open Authentication Settings**
   - Go to: **Authentication** → **Settings** (or **Configuration**)
   - Look for: **Email Auth** section

3. **Disable Email Confirmation**
   - Find the setting: **"Enable email confirmations"** or **"Confirm email"**
   - **Turn it OFF** (disable it)
   - This allows users to sign up and immediately log in without email confirmation

4. **Save Changes**
   - Click **Save** or **Update**

### Step 2: Verify User Account Exists

1. **Check Users in Supabase**
   - Go to: **Authentication** → **Users**
   - Look for the user you're trying to log in with
   - Verify the email/phone matches what you're using

2. **If User Doesn't Exist**
   - Create the user manually in Supabase dashboard, OR
   - Sign up through the app first

3. **If User Exists but is Unconfirmed**
   - Click on the user
   - Click **"Confirm User"** or **"Auto Confirm"** button
   - This manually confirms the user without email

### Step 3: Verify Configuration

1. **Check Environment Configuration**
   - Open: `lib/core/config/environment.dart`
   - Verify:
     ```dart
     static const String supabaseUrl = 'https://bgqcuykvsiejgqeiefpi.supabase.co';
     static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
     ```

2. **Get Correct Anon Key**
   - Go to Supabase Dashboard → **Settings** → **API**
   - Copy the **anon/public** key
   - Update `environment.dart` if different

### Step 4: Test Authentication

1. **Test with Diagnostic Service** (Optional)
   ```dart
   // In your app, you can run diagnostics:
   final diagnostic = ref.read(supabaseAuthDiagnosticProvider);
   final report = await diagnostic.getDiagnosticReport();
   print(report);
   ```

2. **Test Login**
   - Try logging in with valid credentials
   - Check error messages - they should now be more helpful

## For Admin Users

### Additional Steps for Admin Login

1. **Verify Admin User Exists**
   - Go to: **Authentication** → **Users**
   - Find admin email (e.g., `admin@sm.com`)
   - Ensure user is **Confirmed**

2. **Verify Admin Role**
   - Go to: **Table Editor** → **profiles**
   - Find the admin user's profile
   - Verify `role` column is set to: `admin`, `manager`, or `support`

3. **Create Admin User** (if doesn't exist)
   ```sql
   -- Run in SQL Editor
   INSERT INTO auth.users (email, encrypted_password, email_confirmed_at, created_at, updated_at)
   VALUES ('admin@sm.com', crypt('your_password', gen_salt('bf')), NOW(), NOW(), NOW())
   ON CONFLICT (email) DO NOTHING;
   
   -- Then create/update profile
   INSERT INTO profiles (id, name, email, role, created_at)
   SELECT id, 'Admin', email, 'admin', NOW()
   FROM auth.users
   WHERE email = 'admin@sm.com'
   ON CONFLICT (id) DO UPDATE SET role = 'admin';
   ```

## Troubleshooting

### Still Getting 401 After Disabling Email Confirmation?

1. **Check Supabase Logs**
   - Go to: **Logs** → **Auth Logs**
   - Look for specific error messages
   - Check for rate limiting or other issues

2. **Verify User Status**
   - Check if user is **Confirmed** in Authentication → Users
   - Manually confirm if needed

3. **Test with Different Credentials**
   - Try creating a new test user
   - Verify signup works (should return session if email confirmation is disabled)

4. **Check Network/Connectivity**
   - Verify internet connection
   - Check if Supabase project is paused (unpause if needed)

5. **Clear App Data** (Mobile)
   - Clear app cache/data
   - Restart app
   - Try logging in again

### Error Messages to Look For

- **"Email confirmation required"** → Email confirmation is still enabled
- **"Invalid email or password"** → Wrong credentials
- **"No account found"** → User doesn't exist, sign up first
- **"Access denied"** → User exists but doesn't have admin role (for admin login)

## Prevention

### For Development

- Always disable email confirmation during development
- Use test accounts that are manually confirmed
- Keep Supabase dashboard open to monitor auth logs

### For Production

- Consider implementing SMS-based verification for phone numbers
- Use proper email verification for email-based accounts
- Implement proper error handling and user feedback
- Monitor Supabase auth logs regularly

## Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Email Confirmation Settings](https://supabase.com/docs/guides/auth/auth-email-templates)
- [Troubleshooting Auth Issues](https://supabase.com/docs/guides/auth/troubleshooting)

## Quick Reference

| Issue | Solution |
|-------|----------|
| 401 with phone-based login | Disable email confirmation in Supabase |
| User not found | Create user or sign up first |
| Invalid credentials | Check email/password |
| Admin access denied | Verify role in profiles table |
| Session expired | Sign in again |

## Need More Help?

1. Check the diagnostic service output
2. Review Supabase Auth logs
3. Check error messages in the app (they're now more detailed)
4. Verify all configuration steps above

