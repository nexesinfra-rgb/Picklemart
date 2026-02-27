# Fix Supabase RLS Infinite Recursion Issue

## Problem
The current RLS policies on the `profiles` table are causing infinite recursion because they reference the same table they're protecting. The error message indicates:
```
"infinite recursion detected in policy for relation \"profiles\""
```

## Solution
You need to apply the SQL migration to fix the RLS policies. Follow these steps:

### Step 1: Access Supabase Dashboard
1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Navigate to your project: `pdnnrboseyfqwjtytozw`
3. Go to the SQL Editor

### Step 2: Apply the Fix Migration
Copy and paste the contents of `supabase_migrations/003_fix_rls_policies.sql` into the SQL Editor and execute it.

This migration will:
- Remove the problematic circular RLS policies
- Create simplified policies that only allow users to access their own data
- Ensure the profiles table has the correct structure
- Add proper indexes for performance

### Step 3: Verify the Fix
After applying the migration, the profile queries should work without infinite recursion.

## Alternative: Manual Fix via Dashboard
If you prefer to fix this manually:

1. Go to Authentication > Policies in your Supabase dashboard
2. Delete all existing policies on the `profiles` table
3. Create these new policies:

**Policy 1: profiles_select_own**
- Policy name: `profiles_select_own`
- Allowed operation: `SELECT`
- Target roles: `authenticated`
- USING expression: `auth.uid() = id`

**Policy 2: profiles_insert_own**
- Policy name: `profiles_insert_own`
- Allowed operation: `INSERT`
- Target roles: `authenticated`
- WITH CHECK expression: `auth.uid() = id`

**Policy 3: profiles_update_own**
- Policy name: `profiles_update_own`
- Allowed operation: `UPDATE`
- Target roles: `authenticated`
- USING expression: `auth.uid() = id`

## Testing
After applying the fix, test the profile functionality:
1. Try logging in with your existing user
2. Check if the profile data loads correctly
3. Try updating profile information
4. Verify no more infinite recursion errors appear in the logs