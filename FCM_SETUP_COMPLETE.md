# FCM Setup Implementation Complete

## Summary

FCM (Firebase Cloud Messaging) has been successfully implemented for both regular users and admin users. All code changes have been completed.

## What Was Implemented

### 1. Database Migration ✅
- Created `supabase_migrations/20260102160940_create_user_fcm_tokens.sql`
- Creates `user_fcm_tokens` table with RLS policies for regular users
- Similar structure to `admin_fcm_tokens` table

### 2. FCM Service Updates ✅
- Updated `lib/core/services/fcm_service.dart`
- Added `registerUserToken(String userId)` method
- Added `unregisterUserToken(String userId)` method
- Added `deleteAllUserTokens(String userId)` method

### 3. Authentication Integration ✅
- Updated `lib/features/auth/application/auth_controller.dart`
- FCM token registration on user login (both `signIn` and `signInWithMobile`)
- FCM token cleanup on user logout

### 4. Edge Function ✅
- Created `supabase/functions/send-user-fcm-notification/index.ts`
- New Edge Function to send FCM notifications to users
- Supports sending to all users or specific user by `user_id`
- Similar structure to admin FCM notification function

### 5. Notification Integration ✅
- Updated `lib/features/orders/data/order_repository_supabase.dart`
- Sends FCM notifications to users when order status changes
- Updated `lib/features/chat/application/chat_controller.dart`
- Sends FCM notifications to users when admin sends chat messages

## Next Steps (Required)

### 1. Get Firebase Server Key

The Firebase server key is required for FCM to work. You need to:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **picklemart-9a4b0**
3. Click the gear icon ⚙️ → **Project Settings**
4. Go to the **Cloud Messaging** tab
5. **Enable "Cloud Messaging API (Legacy)"** (if not already enabled)
6. Copy the **Server key** (starts with `AAAA...`)

**Note:** The Legacy API is currently disabled in your Firebase Console. You need to enable it to get the server key, as the Edge Functions currently use the Legacy API format.

### 2. Set Firebase Server Key in Supabase

**Option A: Using Supabase Dashboard (Recommended)**
1. Go to: https://supabase.com/dashboard/project/bgqcuykvsiejgqeiefpi
2. Click **Settings** (gear icon) in the left sidebar
3. Click **Edge Functions** in the settings menu
4. Click on the **Secrets** tab
5. Click **Add new secret** button
6. Enter:
   - **Name**: `FIREBASE_SERVER_KEY`
   - **Value**: Paste your Firebase server key
7. Click **Save**

**Option B: Using Supabase CLI**
```bash
# Login to Supabase (if not already logged in)
supabase login

# Link to your project (if not already linked)
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Set the secret (replace YOUR_KEY_HERE with your actual server key)
supabase secrets set FIREBASE_SERVER_KEY=YOUR_KEY_HERE
```

### 3. Run Database Migration

Apply the new migration to create the `user_fcm_tokens` table:

**Option A: Using Supabase Dashboard**
1. Go to: https://supabase.com/dashboard/project/bgqcuykvsiejgqeiefpi
2. Navigate to **SQL Editor**
3. Copy the contents of `supabase_migrations/20260102160940_create_user_fcm_tokens.sql`
4. Paste and run the SQL

**Option B: Using Supabase CLI**
```bash
# Make sure you're linked to the project
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Push migrations
supabase db push --linked
```

### 4. Deploy Edge Function

Deploy the new user FCM notification Edge Function:

```bash
# Make sure you're logged in and linked
supabase login
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Deploy the function
supabase functions deploy send-user-fcm-notification
```

## Testing Checklist

After completing the setup steps above:

- [ ] User FCM tokens table created successfully
- [ ] Firebase server key configured in Supabase
- [ ] Edge Function deployed successfully
- [ ] User login registers FCM token (check console logs)
- [ ] User logout cleans up FCM token
- [ ] Order status change sends FCM notification to user
- [ ] Admin chat message sends FCM notification to user
- [ ] Admin FCM notifications still work (existing functionality)
- [ ] Notifications appear on device (foreground and background)

## Notification Types

### User Notifications
- **Order Status Changed**: Sent when order status is updated
- **Chat Message**: Sent when admin sends a message to user

### Admin Notifications (Existing)
- **Order Status Changed**: Sent when order status is updated
- **Chat Message**: Sent when user sends a message
- **New Order**: Sent when a new order is created

## Files Modified

1. `supabase_migrations/20260102160940_create_user_fcm_tokens.sql` (new)
2. `lib/core/services/fcm_service.dart`
3. `lib/features/auth/application/auth_controller.dart`
4. `lib/features/orders/data/order_repository_supabase.dart`
5. `lib/features/chat/application/chat_controller.dart`
6. `supabase/functions/send-user-fcm-notification/index.ts` (new)
7. `supabase/functions/send-user-fcm-notification/README.md` (new)

## Troubleshooting

### FCM Token Not Registered
- Check Firebase initialization in `main.dart`
- Verify `google-services.json` is in `android/app/`
- Check console logs for FCM initialization errors
- Ensure notification permissions are granted

### Notifications Not Received
1. **Check Edge Function**:
   - Verify function is deployed: `supabase functions list`
   - Check function logs: `supabase functions logs send-user-fcm-notification`

2. **Check Firebase Server Key**:
   - Verify the secret is set: Check Supabase Dashboard → Settings → Edge Functions → Secrets
   - Ensure the key is correct (not truncated)

3. **Check FCM Tokens**:
   - Verify tokens exist in database:
     ```sql
     SELECT user_id, fcm_token, is_active FROM user_fcm_tokens;
     SELECT admin_id, fcm_token, is_active FROM admin_fcm_tokens;
     ```

4. **Check Notification Permissions**:
   - Android: Permissions are automatic
   - iOS: User must grant notification permissions

### Edge Function Errors
- Check Supabase Edge Function logs for errors
- Verify Firebase server key is correctly set as a secret
- Ensure the Edge Function has access to `user_fcm_tokens` table (service role should have access via RLS)

## Future Enhancements

- Migrate from Legacy FCM API to HTTP v1 API with service account authentication
- Add notification sound/vibration settings
- Implement notification categories/channels
- Add notification history/archiving
- Support for batch notifications
- Notification analytics and tracking

