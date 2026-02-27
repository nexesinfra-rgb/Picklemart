# Login Issue Diagnosis and Solution

## Issue Summary

Login fails with "Invalid login credentials" error when attempting to log in with mobile number `9989776655`.

## Root Cause

The user account with mobile number `9989776655` (email: `919989776655@phone.local`) **does not exist** in the Supabase authentication system. This is why login fails with "Invalid login credentials".

## Diagnosis Results

### Email Format Verification ✅

The mobile-to-email conversion format is **consistent** across the system:

- **Login Flow** (`PhoneUtils.mobileToEmail`): Converts `9989776655` → `919989776655@phone.local`
- **Account Creation** (Edge Function): Creates users with format `91{mobile}@phone.local`
- **Format**: Both use `{country_code}{mobile}@phone.local` (e.g., `919989776655@phone.local`)

### Login Flow Review ✅

The login authentication flow in `lib/features/auth/data/auth_repository.dart` is functioning correctly:

1. ✅ Mobile number validation
2. ✅ Email format conversion
3. ✅ Supabase authentication call
4. ✅ Error handling and user-friendly messages
5. ✅ Session validation

The issue is **not** with the code - the user account simply doesn't exist.

### Existing User Accounts

The following user accounts **do exist** in the system:

| Name | Mobile | Email Format | Role | Status |
|------|--------|--------------|------|--------|
| Admin | - | `admin@sm.com` | admin | ✅ Confirmed |
| krishana | `9988776655` | `919988776655@phone.local` | user | ✅ Confirmed |
| sandeep12 | `7780325877` | `917780325877@phone.local` | user | ✅ Confirmed |
| sandeep11 | `7780325876` | `917780325876@phone.local` | user | ✅ Confirmed |
| sandeep10 | `7780325875` | `917780325875@phone.local` | user | ✅ Confirmed |
| sandeep | `7780325874` | `917780325874@phone.local` | user | ✅ Confirmed |
| kiransai | `9989443845` | `919989443845@phone.local` | user | ✅ Confirmed |
| shiva | `9000960470` | `919000960470@phone.local` | user | ✅ Confirmed |
| shiva | `6302024849` | `916302024849@phone.local` | user | ✅ Confirmed |
| saurab | `9876543210` | `919876543210@phone.local` | user | ✅ Confirmed |

**Note**: There is a similar number `9988776655` (krishana) that exists, but `9989776655` does not.

## Solutions

### Option 1: Use Existing Admin Account (Recommended)

If you need to create a new customer account, log in as admin first:

1. **Login Screen**: Click the **"Email"** tab (not Mobile tab)
2. **Credentials**:
   - Email: `admin@sm.com`
   - Password: `admin123`
3. **After Login**: You'll be redirected to Admin Dashboard
4. **Create Customer**: Use the "Create Customer" button in Admin → Customers section
5. **Create Account**: Create the account with mobile `9989776655` and your desired password

### Option 2: Create Account via SQL (Development Only)

**⚠️ Warning**: Only use this for development/testing. Do not use in production.

Run this SQL in Supabase SQL Editor:

```sql
-- Step 1: Create user in auth.users (you'll need to set a password hash manually)
-- This is complex, so Option 1 (Admin Panel) is recommended instead

-- Step 2: After creating user, create profile
-- Replace USER_ID with the UUID from auth.users
INSERT INTO profiles (
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
    'Test User',
    '919989776655@phone.local',
    '9989776655',
    '9989776655',
    'user',
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    name = 'Test User',
    mobile = '9989776655',
    updated_at = NOW();
```

**Recommended**: Use Option 1 (Admin Panel) instead, as it properly handles password hashing and user creation.

### Option 3: Use Similar Existing Account (If You Have Password)

If you have the password for the account with mobile `9988776655` (krishana), you can use that account for testing. However, this is a different number than what you're trying to use.

## Recommended Test Accounts

For development and testing, use these accounts:

### Admin Account (For Creating Customer Accounts)

- **Login Type**: Email
- **Email**: `admin@sm.com`
- **Password**: `admin123`
- **Role**: Admin
- **Access**: Admin Dashboard, Customer Management, etc.

### Customer Accounts

The existing customer accounts listed above can be used if you have their passwords. However, passwords are not stored in plain text, so you'll need to:

1. Reset the password via Supabase Dashboard, OR
2. Create a new account via Admin Panel

## Next Steps

1. **Immediate**: Log in as admin (`admin@sm.com` / `admin123`) using the Email tab
2. **Create Account**: Use Admin → Customers → Create Customer to create account with mobile `9989776655`
3. **Test Login**: Log out and log in with the newly created customer account

## Prevention

To avoid this issue in the future:

1. **Always create customer accounts via Admin Panel** (not via public signup, which is disabled)
2. **Document test account credentials** in a secure location
3. **Use Admin account** to create test customer accounts as needed
4. **Verify account exists** in Supabase Dashboard → Authentication → Users before testing login

## Related Documentation

- [Admin Customer Account Creation Guide](./admin_customer_account_creation.md) - How to create customer accounts via admin panel
- [Admin User Setup Guide](./admin_user_setup.md) - Admin account setup and credentials
- [Login Implementation Summary](./admin_login_implementation_summary.md) - Login flow details

