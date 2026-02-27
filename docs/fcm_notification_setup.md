# FCM Push Notification Setup Guide

This guide explains how to set up Firebase Cloud Messaging (FCM) push notifications for the admin panel.

## Prerequisites

1. Firebase project (you already have one: `standard-marketing-e82db`)
2. Supabase project with Edge Functions enabled
3. Admin user account in the application

## Setup Steps

### 1. Configure Firebase for Android

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `standard-marketing-e82db`
3. Go to **Project Settings** → **Your apps**
4. Click on the Android app or **Add app** → **Android**
5. Enter package name: `com.standardmarketing.app`
6. Download `google-services.json`
7. Place the file in `android/app/google-services.json`

**Note:** The Google Services plugin is already configured in `android/app/build.gradle.kts` and `android/settings.gradle.kts`.

### 2. Get Firebase Server Key

1. In Firebase Console, go to **Project Settings** → **Cloud Messaging**
2. Under **Cloud Messaging API (Legacy)**, copy the **Server key**
3. You'll need this for the Supabase Edge Function

### 3. Deploy Supabase Edge Function

1. Install Supabase CLI (if not already installed):
   ```bash
   npm install -g supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link to your project:
   ```bash
   supabase link --project-ref bgqcuykvsiejgqeiefpi
   ```

4. Set the Firebase server key as a secret:
   ```bash
   supabase secrets set FIREBASE_SERVER_KEY=your_server_key_here
   ```

5. Deploy the Edge Function:
   ```bash
   supabase functions deploy send-admin-fcm-notification
   ```

### 4. Verify Database Migration

The `admin_fcm_tokens` table should already be created. Verify by running in Supabase SQL Editor:

```sql
SELECT * FROM admin_fcm_tokens LIMIT 1;
```

If the table doesn't exist, run the migration:
```sql
-- See supabase_migrations/20250101120000_create_admin_fcm_tokens.sql
```

### 5. Test the Setup

1. **Login as Admin:**
   - The FCM token should be automatically registered when you log in as an admin
   - Check the console logs for: `✅ AdminAuthController: FCM token registered for admin`

2. **Test Order Notification:**
   - Update an order status (e.g., from "Pending" to "Confirmed")
   - Admin should receive an FCM push notification

3. **Test Chat Notification:**
   - Have a regular user send a message in chat
   - Admin should receive an FCM push notification

4. **Check Notification Icon:**
   - The notification icon in the admin navbar should show a badge with unread count
   - Click the icon to see the notification panel

## Troubleshooting

### FCM Token Not Registered

- Check Firebase initialization in `main.dart`
- Verify `google-services.json` is in the correct location
- Check console logs for FCM initialization errors
- Ensure notification permissions are granted (Android: automatic, iOS: needs permission)

### Notifications Not Received

1. **Check Edge Function:**
   - Verify the function is deployed: `supabase functions list`
   - Check function logs: `supabase functions logs send-admin-fcm-notification`

2. **Check Firebase Server Key:**
   - Verify the secret is set: `supabase secrets list`
   - Ensure the key is correct (not truncated)

3. **Check FCM Tokens:**
   - Verify tokens exist in database:
     ```sql
     SELECT admin_id, fcm_token, is_active FROM admin_fcm_tokens;
     ```

4. **Check Notification Permissions:**
   - Android: Permissions are automatic
   - iOS: User must grant notification permissions

### Edge Function Errors

- Check Supabase Edge Function logs for errors
- Verify Firebase server key is correctly set as a secret
- Ensure the Edge Function has access to `admin_fcm_tokens` table

## Architecture

1. **Admin logs in** → FCM token is registered and stored in `admin_fcm_tokens` table
2. **Order status changes / Chat message sent** → Application code calls Supabase Edge Function
3. **Edge Function** → Queries `admin_fcm_tokens` table for active tokens and sends FCM notifications
4. **Admin device receives notification** → Updates badge count and shows notification
5. **Admin clicks notification icon** → Shows notification panel with recent notifications

## File Locations

- **FCM Service:** `lib/core/services/fcm_service.dart`
- **Notification Controller:** `lib/features/admin/application/admin_fcm_notification_controller.dart`
- **Notification Icon:** `lib/features/admin/presentation/widgets/admin_notification_icon.dart`
- **Notification Panel:** `lib/features/admin/presentation/widgets/admin_notification_panel.dart`
- **Edge Function:** `supabase/functions/send-admin-fcm-notification/index.ts`
- **Database Migration:** `supabase_migrations/20250101120000_create_admin_fcm_tokens.sql`

## Future Enhancements

- Migrate from legacy FCM API to HTTP v1 API with service account authentication
- Add notification sound/vibration settings
- Implement notification categories/channels
- Add notification history/archiving
- Support for iOS push notifications (requires additional setup)

