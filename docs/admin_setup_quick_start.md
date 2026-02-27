# Admin Setup Quick Start

## Quick Fix for "Not authenticated" Error

The product creation failed because admin authentication wasn't integrated with Supabase. Here's the quick fix:

## Steps to Fix

### 1. Create Admin User in Supabase Auth

1. Go to Supabase Dashboard: https://okjuhvgavbcbbnzvvyxc.supabase.co
2. Navigate to **Authentication** > **Users** > **Add User**
3. Create user:
   - **Email**: `admin@sm.com`
   - **Password**: `Admin@123` (or your secure password)
   - **Auto Confirm User**: ✅ Enable
4. Click **Create User**

### 2. Run SQL Script

1. Go to **SQL Editor** in Supabase Dashboard
2. Copy and run the script from `supabase_migrations/004_create_admin_user_and_setup.sql`
3. The script will:
   - Create admin profile with `admin` role
   - Create `product-images` storage bucket
   - Set up storage policies

### 3. Test Login

1. Open Flutter app
2. Go to Admin Login
3. Login with:
   - **Email**: `admin@sm.com`
   - **Password**: The password you set in Step 1
4. Try creating a product with images

## What Changed

- ✅ Admin authentication now uses Supabase Auth
- ✅ Admin login creates a valid Supabase session
- ✅ Image uploads now work with authenticated session
- ✅ Product creation saves to Supabase database

## Files Modified

- `lib/features/admin/application/admin_auth_controller.dart`: Integrated with Supabase Auth
- `lib/features/admin/presentation/admin_dashboard_screen.dart`: Updated signOut to be async
- `supabase_migrations/004_create_admin_user_and_setup.sql`: New admin setup script
- `docs/admin_authentication_setup.md`: Detailed setup guide

## Troubleshooting

### Still getting "Not authenticated" error?

1. Verify admin user exists in Supabase Auth Dashboard
2. Verify admin user has `role = 'admin'` in `profiles` table
3. Check that you're logged in through Admin Login screen
4. Verify storage bucket `product-images` exists

### Can't create admin user?

Make sure you have admin access to the Supabase project. If not, ask the project owner to create the user.

## Next Steps

After setup:
1. Test product creation with images
2. Verify images upload to Supabase storage
3. Verify products save to database
4. Test on both web and mobile

For detailed information, see `docs/admin_authentication_setup.md`.










