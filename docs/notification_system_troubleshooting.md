# Notification System Troubleshooting Guide

## Issue: Notifications Not Appearing When Orders Are Placed

If you're not receiving notifications when placing orders, follow these steps:

### Step 1: Verify Database Migration Was Run

The notification system requires the database migration to be executed. 

**Check if migration was run:**
1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `okjuhvgavbcbbnzvvyxc`
3. Navigate to **SQL Editor**
4. Run this query to check if the table exists:
   ```sql
   SELECT EXISTS (
     SELECT FROM information_schema.tables 
     WHERE table_schema = 'public' 
     AND table_name = 'user_notifications'
   );
   ```

**If the table doesn't exist, run the migration:**
1. Open the file: `supabase_migrations/013_create_user_notifications_table.sql`
2. Copy the entire contents
3. Paste into Supabase SQL Editor
4. Click **Run** (or press Ctrl+Enter)
5. Verify you see: "✅ User notifications table created successfully"

### Step 2: Verify Triggers Are Created

Check if the triggers exist:
```sql
SELECT 
  trigger_name, 
  event_manipulation, 
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'orders'
AND trigger_name IN (
  'trigger_order_placed_notification',
  'trigger_order_status_notification'
);
```

**If triggers don't exist**, they should be created by the migration. Re-run the migration if needed.

### Step 3: Test Trigger Manually

Test if the trigger works by checking if a notification is created when you insert an order:

```sql
-- First, get a test order ID (replace with actual order ID)
SELECT id, user_id, order_number 
FROM orders 
ORDER BY created_at DESC 
LIMIT 1;

-- Check if notification was created for that order
SELECT * 
FROM user_notifications 
WHERE order_id = 'YOUR_ORDER_ID_HERE';
```

### Step 4: Check RLS Policies

Verify RLS policies are correct:
```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'user_notifications';
```

You should see:
- "Users can view their own notifications" (SELECT)
- "Users can update their own notifications" (UPDATE)
- "Users can insert their own notifications" (INSERT)

### Step 5: Check Trigger Function Security

The trigger functions use `SECURITY DEFINER` which should bypass RLS. Verify:
```sql
SELECT 
  proname,
  prosecdef,
  proconfig
FROM pg_proc
WHERE proname IN (
  'create_order_placed_notification',
  'create_order_status_notification'
);
```

The `prosecdef` column should be `true` for both functions.

### Step 6: Check App Initialization

1. **Verify notification controller is being watched:**
   - The home screen watches `unreadNotificationCountProvider`
   - This should initialize the notification controller
   - Check app logs for any errors

2. **Check if user is authenticated:**
   - Notifications only work for authenticated users
   - Verify you're logged in as a customer (not admin)

3. **Check real-time subscription:**
   - The notification controller subscribes to real-time changes
   - Check browser console or app logs for subscription errors

### Step 7: Manual Test

1. Place a test order as a customer
2. Immediately check Supabase:
   ```sql
   SELECT * 
   FROM user_notifications 
   WHERE user_id = 'YOUR_USER_ID'
   ORDER BY created_at DESC 
   LIMIT 5;
   ```
3. If notification exists in database but not in app:
   - Check app logs for errors
   - Try refreshing the notifications screen
   - Check if real-time subscription is working

### Step 8: Common Issues

**Issue: Trigger not firing**
- Solution: Re-run the migration to recreate triggers
- Check Supabase logs for trigger errors

**Issue: RLS blocking trigger inserts**
- Solution: The trigger uses SECURITY DEFINER which bypasses RLS
- If still blocked, check function permissions

**Issue: Notifications in DB but not in app**
- Solution: Check notification controller initialization
- Verify real-time subscription is active
- Check app logs for errors

**Issue: Migration already run but table missing**
- Solution: Check if table was accidentally dropped
- Re-run migration (it uses IF NOT EXISTS, so it's safe)

### Step 9: Debug Queries

**Check recent notifications:**
```sql
SELECT 
  id,
  user_id,
  type,
  title,
  message,
  order_id,
  is_read,
  created_at
FROM user_notifications
ORDER BY created_at DESC
LIMIT 10;
```

**Check trigger execution:**
```sql
-- Enable trigger logging (if needed)
SET log_statement = 'all';
```

**Check for errors in Supabase logs:**
1. Go to Supabase Dashboard
2. Navigate to **Logs** → **Postgres Logs**
3. Look for errors related to triggers or notifications

### Step 10: Re-run Migration (If Needed)

If all else fails, you can safely re-run the migration:
1. The migration uses `IF NOT EXISTS` and `DROP IF EXISTS`
2. It's safe to run multiple times
3. Copy and paste the entire SQL from `supabase_migrations/013_create_user_notifications_table.sql`
4. Run in Supabase SQL Editor

## Still Not Working?

If notifications still don't work after following these steps:

1. **Check Supabase project settings:**
   - Ensure real-time is enabled
   - Check API keys are correct

2. **Check app configuration:**
   - Verify Supabase URL and anon key in app
   - Check network connectivity

3. **Contact support:**
   - Provide error logs
   - Share results of debug queries above

