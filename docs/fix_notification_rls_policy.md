# Fix Notification RLS Policy - Step by Step Guide

## Problem
When admin changes order status (e.g., to "shipped"), customers are not receiving notifications. This is because the RLS (Row Level Security) policy blocks admins from inserting notifications for other users.

## Solution
Run the migration file `014_add_admin_notification_insert_policy.sql` to add an RLS policy that allows admins to insert notifications for any user.

## Step-by-Step Instructions

### Step 1: Access Supabase Dashboard
1. Go to your Supabase project dashboard: https://supabase.com/dashboard
2. Navigate to your project (Project URL: `https://okjuhvgavbcbbnzvvyxc.supabase.co`)
3. Click on **SQL Editor** in the left sidebar

### Step 2: Check if Policy Already Exists (Optional Verification)
Run this query first to check if the policy already exists:

```sql
SELECT 
    policyname,
    cmd as operation,
    roles
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
    AND policyname = 'Admins can insert notifications for any user';
```

- **If you see a result**: The policy already exists, skip to Step 4
- **If you see no results**: Continue to Step 3

### Step 3: Run the Migration
1. In the SQL Editor, click **New Query**
2. Open the file `supabase_migrations/014_add_admin_notification_insert_policy.sql` from your project
3. Copy the entire contents of the file
4. Paste it into the SQL Editor
5. Click **Run** (or press `Ctrl+Enter` / `Cmd+Enter`)

The migration will:
- Drop the policy if it already exists (safe to run multiple times)
- Create the admin INSERT policy for `user_notifications` table
- Verify the policy was created successfully

### Step 4: Verify the Policy Was Created
After running the migration, you should see a success message. You can also verify by running:

```sql
SELECT 
    '✅ Policy Status' AS status,
    COUNT(*) AS policy_count
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename = 'user_notifications'
    AND policyname = 'Admins can insert notifications for any user';
```

Expected result: `policy_count = 1`

### Step 5: Test the Fix
1. **As Admin**: Change an order status to "shipped" (or any other status)
2. **As Customer**: Check the notifications screen
3. **Expected Result**: Customer should see a notification about the order status change

### Step 6: Check Debug Logs (If Still Not Working)
If notifications still don't appear after running the migration:

1. Open your Flutter app in debug mode
2. Change an order status as admin
3. Check the console/debug output
4. Look for error messages starting with `❌ Error creating notification:`
5. The enhanced error logging will show:
   - Error type and message
   - Whether it's an RLS policy violation
   - Target user ID
   - Notification details

## Troubleshooting

### Issue: "Policy already exists" error
**Solution**: This is fine! The migration uses `DROP POLICY IF EXISTS`, so it's safe to run multiple times.

### Issue: "Permission denied" error
**Solution**: Make sure you're logged in as an admin user in Supabase. The migration needs to be run by a user with admin privileges.

### Issue: Notifications still not appearing after migration
**Possible causes**:
1. **Check admin role**: Verify your admin user has role 'admin', 'manager', or 'support' in the `profiles` table:
   ```sql
   SELECT id, email, role FROM profiles WHERE role IN ('admin', 'manager', 'support');
   ```

2. **Check RLS is enabled**: Verify RLS is enabled on the table:
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE schemaname = 'public' 
   AND tablename = 'user_notifications';
   ```
   Expected: `rowsecurity = true`

3. **Check notification was created**: Verify if notifications are being created:
   ```sql
   SELECT * FROM user_notifications 
   ORDER BY created_at DESC 
   LIMIT 10;
   ```

4. **Check real-time subscription**: Make sure the Flutter app is subscribed to real-time updates (this should work automatically if the notification controller is initialized)

## What the Migration Does

The migration adds this RLS policy:

```sql
CREATE POLICY "Admins can insert notifications for any user" 
ON PUBLIC.USER_NOTIFICATIONS
FOR INSERT
TO AUTHENTICATED
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM PUBLIC.PROFILES
        WHERE ID = AUTH.UID()
        AND ROLE IN ('admin', 'manager', 'support')
    )
);
```

This policy allows any authenticated user with role 'admin', 'manager', or 'support' to insert notifications for any user (not just themselves).

## After Running the Migration

Once the migration is successfully applied:
- ✅ Admins can create notifications for customers when updating order status
- ✅ Customers will receive real-time notifications
- ✅ Notifications will appear in the customer's notification screen
- ✅ The notification badge count will update automatically

## Need Help?

If you're still experiencing issues after following these steps:
1. Check the Flutter debug console for detailed error messages
2. Check Supabase logs in the Dashboard → Logs → Postgres Logs
3. Verify your admin user's role in the profiles table
4. Ensure the notification controller is properly initialized in your app

