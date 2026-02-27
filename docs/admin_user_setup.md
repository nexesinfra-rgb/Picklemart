# Admin User Setup Guide

## Overview

This guide explains how to set up the admin user in Supabase for the SM E-commerce application.

> **Note**: For creating customer/store accounts, see [Admin Customer Account Creation Guide](./admin_customer_account_creation.md). Customers cannot sign up themselves - only admins can create accounts.

## Admin Credentials

- **Email**: `admin@sm.com`
- **Password**: `admin123`
- **Role**: `admin`

## Step-by-Step Setup

### Step 1: Create Admin User in Supabase Dashboard

1. Go to **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your project: `okjuhvgavbcbbnzvvyxc`
3. Navigate to **Authentication** → **Users**
4. Click **"Add User"** → **"Create new user"**
5. Fill in the details:
   - **Email**: `admin@sm.com`
   - **Password**: `admin123`
   - **Auto Confirm User**: ✅ **Yes** (to skip email confirmation)
6. Click **"Create User"**
7. **Copy the User ID** (UUID) - you'll need this for the next step

### Step 2: Create Admin Profile

1. Go to **SQL Editor** in Supabase Dashboard
2. Click **"New Query"**
3. Copy and paste the following SQL, replacing `USER_ID_HERE` with the UUID from Step 1:

```sql
INSERT INTO public.profiles (
    id,
    name,
    email,
    role,
    created_at,
    updated_at
) VALUES (
    'USER_ID_HERE',  -- Replace with actual UUID from auth.users
    'Admin',
    'admin@sm.com',
    'admin',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    name = 'Admin',
    email = 'admin@sm.com',
    role = 'admin',
    updated_at = NOW();
```

4. Click **"Run"** to execute the query
5. Verify the profile was created:
   - Go to **Table Editor** → **profiles**
   - You should see a row with email `admin@sm.com` and role `admin`

### Step 3: Verify Setup

1. **Test Admin Login**:

   - Open the app
   - Go to Login screen
   - Click **"Email"** tab
   - Enter: `admin@sm.com` / `admin123`
   - Click **"Login"**
   - You should be redirected to `/admin/dashboard`

2. **Verify Role Detection**:
   - After login, check that `AuthState.role == AppRole.admin`
   - Admin should have access to all admin routes

## Alternative: Using Migration Script

You can also use the migration script `supabase_migrations/003_create_admin_user.sql`:

1. The script includes a DO block that automatically finds the admin user by email
2. Run the migration after creating the user in the dashboard
3. The script will create/update the profile automatically

## Troubleshooting

### Admin Login Fails

- Verify user exists in **Authentication** → **Users**
- Check that email is exactly `admin@sm.com`
- Verify password is `admin123`
- Ensure **Auto Confirm User** was enabled

### Role Not Detected

- Check that profile exists in `profiles` table
- Verify `profiles.role = 'admin'`
- Check that profile `id` matches the user `id` from `auth.users`
- Review app logs for profile fetch errors

### Profile Not Created

- Verify RLS policies allow profile creation
- Check that user ID matches between `auth.users` and `profiles`
- Ensure the `profiles` table exists and has correct schema

## Security Notes

- **Change Default Password**: After initial setup, consider changing the admin password
- **Use Strong Password**: For production, use a stronger password
- **Limit Admin Access**: Only grant admin access to trusted users
- **Monitor Admin Activity**: Review admin actions regularly

## Next Steps

After admin user is set up:

1. Test admin login flow
2. Verify admin can access admin dashboard
3. Test admin can view/manage user data
4. Configure additional admin users if needed (with role 'manager' or 'support')









