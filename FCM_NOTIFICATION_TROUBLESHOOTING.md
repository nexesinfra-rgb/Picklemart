# FCM Push Notification Troubleshooting Guide

## Problem
Notifications are appearing in the app (via Supabase Realtime), but FCM push notifications are not being sent to devices.

## Root Cause
The database trigger is creating notification records successfully, but the FCM push notification trigger might not be working correctly. Common issues:

1. **pg_net extension not enabled** - Required for HTTP calls from PostgreSQL
2. **HTTP requests queued but not executing** - pg_net is asynchronous
3. **Edge functions not deployed or misconfigured** - FCM edge functions need to be deployed
4. **FCM tokens not registered** - Users need to have FCM tokens in the database
5. **Firebase service account not configured** - Edge functions need FIREBASE_SERVICE_ACCOUNT secret

## Step-by-Step Fix

### Step 1: Run Diagnostic Script

1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy and run `DIAGNOSE_FCM_PUSH_NOTIFICATIONS.sql`
3. Review the results to identify the issue

### Step 2: Apply the Fix

1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy and run `FIX_FCM_PUSH_NOTIFICATIONS.sql`
3. This will:
   - Ensure pg_net extension is enabled
   - Recreate the FCM push notification function with better error handling
   - Recreate the trigger
   - Add proper logging

### Step 3: Verify Edge Functions

1. Go to **Supabase Dashboard** → **Edge Functions**
2. Verify these functions are deployed:
   - `send-user-fcm-notification`
   - `send-admin-fcm-notification`
3. Check that `FIREBASE_SERVICE_ACCOUNT` secret is set:
   - Go to **Edge Functions** → **Secrets**
   - Verify `FIREBASE_SERVICE_ACCOUNT` exists and contains valid JSON

### Step 4: Check HTTP Request Queue

Run this query to see if HTTP requests are being queued:

```sql
SELECT 
    id,
    url,
    method,
    status_code,
    created_at,
    error_msg
FROM net.http_request_queue
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 20;
```

**What to look for:**
- ✅ Requests with `status_code = 200` = Success
- ⚠️ Requests with `status_code IS NULL` = Still pending (wait a few seconds)
- ❌ Requests with `status_code != 200` = Failed (check `error_msg`)

### Step 5: Verify FCM Tokens

Check if users have FCM tokens registered:

```sql
-- Check user FCM tokens
SELECT 
    COUNT(*) AS total_tokens,
    COUNT(*) FILTER (WHERE is_active = true) AS active_tokens,
    COUNT(DISTINCT user_id) AS users_with_tokens
FROM PUBLIC.USER_FCM_TOKENS;

-- Check admin FCM tokens
SELECT 
    COUNT(*) AS total_tokens,
    COUNT(*) FILTER (WHERE is_active = true) AS active_tokens,
    COUNT(DISTINCT admin_id) AS admins_with_tokens
FROM PUBLIC.ADMIN_FCM_TOKENS;
```

**If no tokens found:**
- Users need to log in to the app
- The app should automatically register FCM tokens on login
- Check app logs for FCM token registration errors

### Step 6: Test the Trigger

Create a test notification to trigger FCM:

```sql
-- Replace USER_ID with an actual user ID that has an FCM token
INSERT INTO PUBLIC.USER_NOTIFICATIONS (
    USER_ID,
    TYPE,
    TITLE,
    MESSAGE,
    IS_READ,
    CREATED_AT
) VALUES (
    'YOUR_USER_ID_HERE',  -- Replace with actual user ID
    'order_placed',
    'Test FCM Notification',
    'This is a test notification to verify FCM push is working',
    FALSE,
    NOW()
);
```

Then check:
1. **HTTP Request Queue** - Should see a new request
2. **Edge Function Logs** - Go to Edge Functions → Logs
3. **Device** - Should receive push notification

### Step 7: Check Edge Function Logs

1. Go to **Supabase Dashboard** → **Edge Functions** → **Logs**
2. Select `send-user-fcm-notification` or `send-admin-fcm-notification`
3. Look for:
   - ✅ Success messages
   - ❌ Error messages (especially authentication errors)
   - ⚠️ Warnings about missing FCM tokens

## Alternative Solution: Database Webhooks

If `pg_net` is not working reliably, you can use Supabase Database Webhooks instead:

1. Go to **Supabase Dashboard** → **Database** → **Webhooks**
2. Click **Create a new webhook**
3. Configure:
   - **Name**: `FCM Push Notification Webhook`
   - **Table**: `user_notifications`
   - **Events**: Select `INSERT`
   - **HTTP Request**:
     - **URL**: `https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/send-user-fcm-notification`
     - **Method**: `POST`
     - **Headers**: 
       - `Authorization`: `Bearer YOUR_ANON_KEY`
       - `apikey`: `YOUR_ANON_KEY`
       - `Content-Type`: `application/json`
     - **Body**: Select **JSON** and use:
       ```json
       {
         "type": "{{record.type}}",
         "title": "{{record.title}}",
         "message": "{{record.message}}",
         "order_id": "{{record.order_id}}",
         "user_id": "{{record.user_id}}"
       }
       ```
4. Click **Save**

**Note**: You'll need separate webhooks for user and admin notifications, or use a single webhook that calls a router function.

## Common Issues and Solutions

### Issue: HTTP requests are queued but never execute

**Solution**: Check Supabase project settings. Some Supabase plans have limitations on background workers. Upgrade plan or use Database Webhooks instead.

### Issue: Edge function returns 401 Unauthorized

**Solution**: 
- Verify the anon key is correct
- Check that edge function allows unauthenticated access (if needed)
- Or use service role key instead (more secure)

### Issue: Edge function returns 500 Internal Server Error

**Solution**:
- Check `FIREBASE_SERVICE_ACCOUNT` secret is set correctly
- Verify the service account JSON is valid
- Check edge function logs for detailed error messages

### Issue: FCM tokens exist but notifications not received

**Solution**:
- Verify Firebase project is configured correctly
- Check device has notification permissions enabled
- Verify FCM tokens are valid (not expired)
- Check Firebase Console → Cloud Messaging for delivery statistics

## Verification Checklist

- [ ] pg_net extension is enabled
- [ ] FCM push notification trigger exists
- [ ] FCM push notification function exists
- [ ] Edge functions are deployed
- [ ] FIREBASE_SERVICE_ACCOUNT secret is set
- [ ] Users have FCM tokens registered
- [ ] HTTP requests are being queued (check `net.http_request_queue`)
- [ ] HTTP requests are executing successfully (status_code = 200)
- [ ] Edge function logs show successful FCM sends
- [ ] Devices receive push notifications

## Still Not Working?

If notifications still don't work after following all steps:

1. **Check PostgreSQL logs** for warnings/errors
2. **Check Edge Function logs** for detailed error messages
3. **Test edge function directly** using curl:
   ```bash
   curl -X POST 'https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/send-user-fcm-notification' \
     -H 'Authorization: Bearer YOUR_ANON_KEY' \
     -H 'Content-Type: application/json' \
     -d '{
       "type": "order_placed",
       "title": "Test",
       "message": "Test message",
       "user_id": "USER_ID_HERE"
     }'
   ```
4. **Contact Supabase support** if pg_net is not working on your plan














