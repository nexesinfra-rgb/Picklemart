# Admin Authentication Setup Guide

## Overview

The admin authentication has been integrated with Supabase Auth to enable secure product image uploads and database operations. This guide will help you set up the admin user in Supabase.

## Problem Solved

Previously, the admin authentication was using a mock system that didn't authenticate with Supabase. This caused product image uploads to fail with "Not authenticated" errors because the Supabase client didn't have a valid session.

## Solution

The admin authentication now:
1. Authenticates with Supabase Auth when admin logs in
2. Verifies the user has admin role in the `profiles` table
3. Creates a valid Supabase session for storage uploads and database operations
4. Maps Supabase roles (`admin`, `manager`, `support`) to AdminRole enum

## Setup Steps

### Step 1: Create Admin User in Supabase Auth

1. Go to your Supabase Dashboard: https://okjuhvgavbcbbnzvvyxc.supabase.co
2. Navigate to **Authentication** > **Users**
3. Click **Add User** (or **Invite User**)
4. Fill in the details:
   - **Email**: `admin@sm.com` (or your preferred admin email)
   - **Password**: Set a secure password (e.g., `Admin@123`)
   - **Auto Confirm User**: Enable this (or confirm manually via email)
5. Click **Create User**

### Step 2: Run the Admin Setup SQL Script

1. Go to **SQL Editor** in Supabase Dashboard
2. Open the file: `supabase_migrations/004_create_admin_user_and_setup.sql`
3. Update the admin email if needed (line 14: `admin_email TEXT := 'admin@sm.com';`)
4. Run the script

This script will:
- Create/update the admin profile with `admin` role
- Create the `product-images` storage bucket (if it doesn't exist)
- Set up storage policies for authenticated admin users
- Verify the setup

### Step 3: Verify Admin User Setup

Run this query in SQL Editor to verify:

```sql
SELECT 
    p.id,
    p.name,
    p.email,
    p.role,
    p.created_at,
    u.email as auth_email
FROM profiles p
JOIN auth.users u ON p.id = u.id
WHERE p.role = 'admin';
```

You should see your admin user with `role = 'admin'`.

### Step 4: Verify Storage Bucket

Run this query to verify the storage bucket exists:

```sql
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
WHERE id = 'product-images';
```

### Step 5: Test Admin Login

1. Open your Flutter app
2. Navigate to Admin Login screen
3. Enter credentials:
   - **Email**: `admin@sm.com` (or your admin email)
   - **Password**: The password you set in Step 1
4. Click **Login**

You should be able to:
- Log in successfully
- Navigate to Admin Dashboard
- Add products with image uploads
- Save products to Supabase database

## Storage Policies

The setup script creates the following storage policies for the `product-images` bucket:

1. **Authenticated users can upload product images**: Admins, managers, and support can upload images
2. **Authenticated users can update product images**: Admins can update existing images
3. **Authenticated users can delete product images**: Admins can delete images
4. **Public can read product images**: Anyone can view product images (for public product display)

## Admin Roles

The system supports three admin roles:

- **admin** (superAdmin): Full access to all admin features
- **manager**: Can manage products, orders, customers, and content
- **support**: Can view and manage orders and customers

## Troubleshooting

### Issue: "Access denied. Admin privileges required."

**Solution**: 
1. Verify the user exists in `auth.users` table
2. Verify the user has `role = 'admin'` in `profiles` table
3. Run the setup SQL script again

### Issue: "Not authenticated. Please log in as admin."

**Solution**:
1. Verify you're logged in through the Admin Login screen
2. Check that Supabase session exists: `_supabase.auth.currentSession`
3. Verify the user has admin role in profiles table

### Issue: "Failed to upload any images"

**Solution**:
1. Verify the `product-images` storage bucket exists
2. Verify storage policies are set up correctly
3. Check that the user is authenticated (has valid Supabase session)
4. Verify the user has admin role in profiles table

### Issue: Storage bucket doesn't exist

**Solution**:
1. Run the setup SQL script
2. Or manually create the bucket in Supabase Dashboard:
   - Go to **Storage** > **Buckets**
   - Click **New Bucket**
   - Name: `product-images`
   - Public: Yes
   - File size limit: 10MB
   - Allowed MIME types: `image/jpeg`, `image/png`, `image/gif`, `image/webp`

## Testing

After setup, test the following:

1. **Admin Login**: Login with admin credentials
2. **Add Product**: Create a new product with images
3. **Upload Images**: Upload multiple product images
4. **Save Product**: Save product to database
5. **View Product**: Verify product appears in product list
6. **Edit Product**: Edit existing product
7. **Delete Product**: Delete product (soft delete)

## Security Notes

1. **Password**: Use a strong password for the admin user
2. **Role Verification**: The system verifies admin role on every login
3. **Storage Policies**: Only authenticated users with admin role can upload images
4. **Session Management**: Supabase sessions are managed automatically
5. **RLS Policies**: Row Level Security policies protect database operations

## Next Steps

After setting up admin authentication:

1. Create additional admin users if needed
2. Set up different roles (manager, support) for different access levels
3. Test product creation, editing, and deletion
4. Verify image uploads work correctly
5. Test on both web and mobile platforms

## Related Files

- `lib/features/admin/application/admin_auth_controller.dart`: Admin authentication controller
- `lib/features/admin/data/product_repository_supabase.dart`: Product repository with Supabase integration
- `lib/features/admin/presentation/admin_product_form_screen.dart`: Product form screen
- `supabase_migrations/004_create_admin_user_and_setup.sql`: Admin setup SQL script

## Support

If you encounter any issues:

1. Check the Supabase Dashboard logs
2. Verify the SQL script ran successfully
3. Check Flutter app logs for error messages
4. Verify admin user exists in both `auth.users` and `profiles` tables
5. Verify storage bucket and policies are set up correctly










