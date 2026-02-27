# Fix RLS Infinite Recursion Error

## Problem
The error `infinite recursion detected in policy for relation "profiles"` occurs because the admin RLS policies were querying the `profiles` table to check if a user is an admin, which triggered the same policy check again, creating an infinite loop.

## Solution
Created a security definer function `is_admin()` that bypasses RLS when checking admin status. This prevents the recursion.

## How to Fix

### Step 1: Run the Fix Migration

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Copy the contents of `supabase_migrations/002_fix_profiles_rls_recursion.sql`
3. Paste and execute it

### Step 2: Verify

After running the migration:
- The infinite recursion error should be resolved
- Users can now read their own profiles
- Admins can read/update all profiles

## What Changed

1. **Dropped problematic policies**: Removed the admin policies that caused recursion
2. **Created security definer function**: `is_admin()` function that bypasses RLS
3. **Recreated admin policies**: Using the new function to prevent recursion

## Technical Details

### Security Definer Function
```sql
CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
```

- `SECURITY DEFINER`: Runs with the privileges of the function creator, bypassing RLS
- This allows checking admin status without triggering the same RLS policy

### Updated Policies
```sql
CREATE POLICY profiles_select_admin ON public.profiles
    FOR SELECT
    USING (public.is_admin(auth.uid()));
```

The policies now use `is_admin()` instead of directly querying the profiles table.

## Testing

After applying the fix:
1. Try loading a profile in your app
2. The error should be gone
3. Users should be able to see their own profiles
4. Admins should be able to see all profiles

## Alternative Solutions (If Needed)

If you need more granular control, you could:
1. Store admin status in user metadata instead of profiles table
2. Use a separate `user_roles` table
3. Use Supabase's built-in role system

But the security definer function approach is the simplest and most effective for this use case.










