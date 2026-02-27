# How to Get Firebase Server Key

## Important: Your Legacy API is Currently Disabled

Based on your Firebase Console, the **Cloud Messaging API (Legacy)** is currently **DISABLED**. You need to enable it temporarily to get the server key.

## Step-by-Step Instructions

### Step 1: Enable Cloud Messaging API (Legacy)

1. In Firebase Console, you're already on the **Cloud Messaging** tab
2. Find the section titled **"Cloud Messaging API (Legacy)"**
3. You'll see it shows "Disabled" with a grey icon
4. Click the **three dots (⋮)** icon on the right side of that section
5. Select **"Enable"** or click **"Enable API"** if there's a button
6. Confirm if prompted

**Note:** Firebase recommends using V1 API, but since your Edge Function uses the legacy format, enable Legacy API for now. You can migrate to V1 later if needed.

### Step 2: Get the Server Key

Once the Legacy API is enabled:

1. In the **"Cloud Messaging API (Legacy)"** section
2. Look for **"Server key"** - it will appear as a text field or button
3. Click to reveal/view the server key
4. Copy the entire key (it starts with `AAAA...` and is a long string)
5. **Keep this key secure** - never commit it to your repository

### Step 3: Set the Secret in Supabase

You have two options:

#### Option A: Using Supabase Dashboard (Recommended)

1. Go to: https://supabase.com/dashboard/project/bgqcuykvsiejgqeiefpi
2. Click **Settings** (gear icon) in the left sidebar
3. Click **Edge Functions** in the settings menu
4. Click on the **Secrets** tab
5. Click **Add new secret** button
6. Enter:
   - **Name**: `FIREBASE_SERVER_KEY`
   - **Value**: Paste your Firebase server key (the `AAAA...` key you copied)
7. Click **Save**

#### Option B: Using Supabase CLI (If installed)

```bash
# First, install Supabase CLI if not installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Set the secret (replace YOUR_KEY_HERE with your actual server key)
supabase secrets set FIREBASE_SERVER_KEY=YOUR_KEY_HERE
```

### Step 4: Verify Edge Function Deployment

✅ **Good news:** The Edge Function `send-admin-fcm-notification` is **already deployed and active**!

You don't need to deploy it again. Just set the secret and you're done.

### Step 5: Test the Setup

After setting the secret, test by:

1. **Login as admin** in your Flutter app
2. **Update an order status** (should trigger FCM notification)
3. **Send a chat message as a user** (should notify admin)

Or test directly using curl:

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

## Alternative: Migrate to V1 API (Future)

If you want to use the recommended V1 API instead (better for production):

1. The Edge Function code would need to be updated to use service account authentication
2. You'd need to download a service account JSON file from Firebase
3. This is more secure but requires code changes

For now, enabling the Legacy API and using the server key is the quickest solution.

## Summary Checklist

- [ ] Enable "Cloud Messaging API (Legacy)" in Firebase Console
- [ ] Copy the Server key from Firebase Console
- [ ] Set `FIREBASE_SERVER_KEY` secret in Supabase Dashboard (or via CLI)
- [ ] Test notifications by updating an order or sending a chat message
- [ ] ✅ Edge Function already deployed (no action needed)

## Need Help?

If you can't find the "Enable" option:
- Make sure you're the project owner or have admin permissions
- Try refreshing the Firebase Console page
- The Legacy API might need to be enabled in Google Cloud Console instead (Firebase Console should handle this)

