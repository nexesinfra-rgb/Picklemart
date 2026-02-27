# Firebase Server Key Setup Instructions

The Edge Function has been deployed successfully! However, you need to set the Firebase Server Key as a secret in Supabase for the function to work.

## Step 1: Get Firebase Server Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **picklemart-9a4b0**
3. Click the gear icon ⚙️ → **Project Settings**
4. Go to the **Cloud Messaging** tab
5. Under **Cloud Messaging API (Legacy)**, find the **Server key**
6. Click to reveal and copy the server key (it starts with `AAAA...`)

## Step 2: Set the Secret in Supabase

You have two options:

### Option A: Using Supabase Dashboard (Recommended)

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/bgqcuykvsiejgqeiefpi)
2. Click **Settings** (gear icon) in the left sidebar
3. Click **Edge Functions** in the settings menu
4. Click on the **Secrets** tab
5. Click **Add new secret**
6. Enter:
   - **Name**: `FIREBASE_SERVER_KEY`
   - **Value**: Paste your Firebase server key
7. Click **Save**

### Option B: Using Supabase CLI

If you have Supabase CLI installed:

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Set the secret
supabase secrets set FIREBASE_SERVER_KEY=your_server_key_here
```

## Step 3: Verify Deployment

The Edge Function `send-admin-fcm-notification` has been deployed and is **ACTIVE**.

To test it, you can call it from your Flutter app (which is already integrated) or test it directly:

```bash
curl -X POST 'https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/send-admin-fcm-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "order_status_changed",
    "title": "Test Notification",
    "message": "This is a test notification",
    "order_id": "test-order-id"
  }'
```

## Important Notes

1. **Firebase Server Key**: This is a sensitive credential. Never commit it to your repository.
2. **Security**: The Edge Function is currently deployed with `verify_jwt: false`. For production, consider enabling JWT verification.
3. **Testing**: After setting the secret, test the notification system by:
   - Updating an order status (should trigger FCM notification)
   - Sending a chat message as a user (should notify admin)

## Current Status

✅ Edge Function deployed: `send-admin-fcm-notification`  
✅ Status: ACTIVE  
⚠️  Action Required: Set `FIREBASE_SERVER_KEY` secret in Supabase

