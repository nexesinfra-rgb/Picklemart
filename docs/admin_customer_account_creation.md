# Admin Customer Account Creation Guide

## Overview

This guide explains how admins can create customer/store accounts in the SM E-commerce application. Customers/stores cannot sign up themselves - only admins can create accounts through the Supabase Dashboard or the admin panel.

## Methods to Create Customer Accounts

### Method 1: Using Admin Panel (Recommended)

Admins can create customer accounts directly from the admin panel:

1. **Navigate to Customers/Stores Screen**
   - Log in as admin
   - Go to Admin Dashboard → Customers/Stores (or "Manage Stores")

2. **Click "Create Customer" Button**
   - Click the "+" (plus) icon in the top action bar
   - A dialog will open with a form

3. **Fill in Customer Details**
   - **Name**: Customer/store name (required)
   - **Mobile Number**: 10-digit mobile number (required)
   - **Password**: Minimum 6 characters (required)

4. **Submit the Form**
   - Click "Create" button
   - The system will create the account and display credentials

5. **Share Credentials with Customer**
   - After successful creation, a dialog shows the credentials:
     - Mobile number
     - Password
   - Copy and share these credentials securely with the customer/store
   - The customer can then log in using these credentials

### Method 2: Using Supabase Dashboard (Alternative)

Admins can also create customer accounts directly in Supabase Dashboard:

1. **Go to Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project: `bgqcuykvsiejgqeiefpi`

2. **Create User in Authentication**
   - Go to **Authentication** → **Users**
   - Click **"Add User"** → **"Create new user"**
   - Fill in the details:
     - **Email**: Use format `91{mobile}@phone.local` (e.g., `919876543210@phone.local` for mobile 9876543210)
     - **Password**: Set a secure password (minimum 6 characters)
     - **Auto Confirm User**: ✅ **Yes** (to skip email confirmation)
   - Click **"Create User"**
   - **Copy the User ID** (UUID) - you'll need this for the next step

3. **Create Profile**
   - Go to **SQL Editor** in Supabase Dashboard
   - Click **"New Query"**
   - Run the following SQL, replacing placeholders:

```sql
INSERT INTO public.profiles (
    id,
    name,
    email,
    mobile,
    display_mobile,
    role,
    created_at,
    updated_at
) VALUES (
    'USER_ID_HERE',  -- Replace with actual UUID from auth.users
    'Customer Name',  -- Replace with customer name
    '91MOBILE@phone.local',  -- Replace MOBILE with 10-digit mobile number
    'MOBILE',  -- Replace MOBILE with 10-digit mobile number (without country code)
    'MOBILE',  -- Replace MOBILE with 10-digit mobile number (for display)
    'user',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    name = 'Customer Name',
    email = '91MOBILE@phone.local',
    mobile = 'MOBILE',
    display_mobile = 'MOBILE',
    updated_at = NOW();
```

4. **Verify Profile Creation**
   - Go to **Table Editor** → **profiles**
   - You should see the new customer with role `user`

5. **Share Credentials**
   - Share the mobile number and password with the customer/store
   - They can log in using these credentials

## Important Notes

### Mobile Number Format
- Mobile numbers are stored as 10-digit numbers (e.g., `9876543210`)
- Email format for mobile-based accounts: `91{mobile}@phone.local`
- Example: Mobile `9876543210` → Email `919876543210@phone.local`

### Password Requirements
- Minimum 6 characters
- Can contain letters, numbers, and special characters
- Should be strong and secure

### Account Status
- All accounts created are automatically confirmed (no email verification needed)
- Customers can log in immediately after account creation
- Customers have role `user` (regular customer, not admin)

### Security Considerations
- Credentials should be shared securely with customers (email, SMS, or in-person)
- Encourage customers to change their password after first login (if password change feature is available)
- Never share credentials over insecure channels

## Troubleshooting

### Error: "User with this mobile number already exists"
- The mobile number is already registered
- Check if the customer already has an account
- Use a different mobile number or check existing customers list

### Error: "Access denied. Admin privileges required"
- Only users with admin, manager, or support roles can create accounts
- Ensure you're logged in with an admin account
- Check your role in the profiles table

### Error: "Failed to create user account"
- Check network connectivity
- Verify Supabase service is running
- Check Supabase Dashboard for service status
- Review error details in the error message

### Customer Cannot Log In
- Verify the account was created successfully (check profiles table)
- Ensure credentials are correct (mobile number and password)
- Check if account is confirmed (should be auto-confirmed)
- Verify mobile number format is correct (10 digits)

## Best Practices

1. **Use Admin Panel Method**: The admin panel method is recommended as it handles all steps automatically and provides better error handling

2. **Secure Credential Sharing**: Always share credentials through secure channels (encrypted email, secure messaging, or in-person)

3. **Document Account Creation**: Keep a record of created accounts for your records

4. **Verify Account Creation**: After creating an account, verify it appears in the customers list

5. **Test Login**: Optionally test the credentials yourself to ensure they work before sharing with customers

