# Send Admin FCM Notification Edge Function

This Edge Function sends Firebase Cloud Messaging (FCM) push notifications to admin users using the FCM HTTP v1 API.

## Setup

### 1. Get Firebase Service Account JSON

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **picklemart-9a4b0**
3. Click the gear icon ⚙️ → **Project Settings**
4. Go to the **Service Accounts** tab
5. Click **"Generate new private key"**
6. Click **"Generate key"** to download the JSON file
7. **Important:** Keep this file secure - it contains sensitive credentials

The JSON file contains:
- `project_id`: Your Firebase project ID
- `private_key`: Private key for authentication
- `client_email`: Service account email

### 2. Set Environment Secret in Supabase

You have two options:

#### Option A: Using Supabase Dashboard (Recommended)

1. Go to: https://supabase.com/dashboard/project/bgqcuykvsiejgqeiefpi
2. Click **Settings** (gear icon) in the left sidebar
3. Click **Edge Functions** in the settings menu
4. Click on the **Secrets** tab
5. Click **Add new secret** button
6. Enter:
   - **Name**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: Copy the entire contents of the service account JSON file and paste it here (as a single-line JSON string)
7. Click **Save**

**Note:** The JSON should be pasted as-is, but Supabase will store it as a string. Make sure it's valid JSON.

#### Option B: Using Supabase CLI

```bash
# Login to Supabase (if not already logged in)
supabase login

# Link to your project (if not already linked)
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Set the secret (replace the path with your actual service account JSON file path)
# On Windows PowerShell:
$json = Get-Content -Path "path/to/service-account.json" -Raw
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$json"

# On Linux/Mac:
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/service-account.json)"
```

### 3. Deploy the Edge Function

```bash
# Make sure you're logged in and linked
supabase login
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Deploy the function
supabase functions deploy send-admin-fcm-notification
```

Or deploy via Supabase Dashboard → Edge Functions → Deploy.

## Usage

Send a POST request to the function:

```bash
curl -X POST 'https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/send-admin-fcm-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "order_status_changed",
    "title": "Order Updated",
    "message": "Order #12345 status changed to Processing",
    "order_id": "uuid-here",
    "order_number": "12345"
  }'
```

## Payload Format

```typescript
{
  type: "order_status_changed" | "chat_message" | "new_order",
  title: string,
  message: string,
  order_id?: string,        // Optional: for order-related notifications
  conversation_id?: string, // Optional: for chat notifications
  order_number?: string,    // Optional: for display purposes
  user_name?: string        // Optional: for chat notifications
}
```

## Features

- ✅ Uses FCM HTTP v1 API (modern, secure, recommended by Firebase)
- ✅ OAuth 2.0 authentication with service account
- ✅ Automatic token caching (tokens are cached for 55 minutes)
- ✅ Sends notifications to all active admin FCM tokens
- ✅ Handles errors gracefully (failed notifications don't break the batch)
- ✅ Detailed error reporting

## Notes

- This function uses the FCM HTTP v1 API (not the deprecated Legacy API)
- OAuth tokens are automatically cached and refreshed as needed
- The function sends notifications to all active admin FCM tokens stored in the `admin_fcm_tokens` table
- Failed notifications are logged but don't fail the entire batch
- Each notification is sent individually to each admin device

## Troubleshooting

### Authentication Errors

If you see "Firebase authentication failed":
- Verify `FIREBASE_SERVICE_ACCOUNT` secret is set correctly
- Ensure the JSON is valid (no extra characters, proper formatting)
- Check that the service account has proper permissions

### Token Generation Errors

If OAuth token generation fails:
- Verify the service account JSON is correct
- Check that the private key is properly formatted
- Ensure the service account email matches the JSON

### Notification Delivery Failures

- Check Edge Function logs in Supabase Dashboard
- Verify FCM tokens are valid and active in the database
- Check Firebase Console for delivery statistics
