# FCM Setup - Remaining Steps Guide

## ✅ Completed

1. **Database Migration Applied** ✅
   - The `user_fcm_tokens` table has been successfully created via Supabase MCP
   - All RLS policies, indexes, and triggers are in place

## 🔧 Remaining Steps

### Step 1: Get Firebase Server Key (REQUIRES MANUAL ACTION)

The Firebase server key can only be retrieved from the Firebase Console UI. Follow these steps:

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your project: **picklemart-9a4b0**

2. **Enable Legacy FCM API**
   - Click the gear icon ⚙️ → **Project Settings**
   - Go to the **Cloud Messaging** tab
   - Find the section **"Cloud Messaging API (Legacy)"**
   - Click the three dots (⋮) icon on the right
   - Click **"Enable"** or **"Enable API"**
   - Confirm if prompted

3. **Get the Server Key**
   - Once enabled, the **"Server key"** field will appear
   - Click to reveal/view the server key
   - Copy the entire key (it starts with `AAAA...` and is a long string)
   - **Important:** Keep this key secure - never commit it to your repository

### Step 2: Set Firebase Server Key in Supabase

You have two options:

#### Option A: Using Supabase Dashboard (Recommended - Easiest)

1. Go to: https://supabase.com/dashboard/project/bgqcuykvsiejgqeiefpi
2. Click **Settings** (gear icon) in the left sidebar
3. Click **Edge Functions** in the settings menu
4. Click on the **Secrets** tab
5. Click **Add new secret** button
6. Enter:
   - **Name**: `FIREBASE_SERVER_KEY`
   - **Value**: Paste your Firebase server key (the `AAAA...` key you copied)
7. Click **Save**

#### Option B: Using Supabase CLI (If you install it)

**First, install Supabase CLI:**

For Windows, you can use one of these methods:

**Method 1: Using Chocolatey (if installed)**
```powershell
choco install supabase
```

**Method 2: Using Scoop (if installed)**
```powershell
scoop install supabase
```

**Method 3: Direct Download**
1. Go to: https://github.com/supabase/cli/releases
2. Download the latest Windows executable
3. Add it to your PATH

**Then run:**
```powershell
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Set the secret (replace YOUR_KEY_HERE with your actual server key)
supabase secrets set FIREBASE_SERVER_KEY=YOUR_KEY_HERE
```

### Step 3: Deploy Edge Function

**Option A: Using Supabase Dashboard**

1. Go to: https://supabase.com/dashboard/project/bgqcuykvsiejgqeiefpi
2. Click **Edge Functions** in the left sidebar
3. Click **Deploy a new function**
4. Select **"Create from local files"** or **"Deploy from GitHub"**
5. Upload/select the `supabase/functions/send-user-fcm-notification` directory
6. Click **Deploy**

**Option B: Using Supabase CLI (If installed)**

```powershell
# Make sure you're logged in and linked
supabase login
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Deploy the function
supabase functions deploy send-user-fcm-notification
```

## 📋 Verification Checklist

After completing all steps:

- [ ] Firebase Legacy API enabled
- [ ] Firebase server key copied
- [ ] `FIREBASE_SERVER_KEY` secret set in Supabase
- [ ] Edge Function `send-user-fcm-notification` deployed
- [ ] Test user login (should register FCM token)
- [ ] Test order status change (should send notification to user)
- [ ] Test admin chat message (should send notification to user)

## 🧪 Quick Test

After setup, you can test the Edge Function directly:

```bash
curl -X POST 'https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/send-user-fcm-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "order_status_changed",
    "title": "Test Notification",
    "message": "This is a test notification",
    "order_id": "test-order-id",
    "order_number": "12345",
    "user_id": "specific-user-uuid-optional"
  }'
```

Replace `YOUR_ANON_KEY` with your Supabase anon key from `.cursorrules`.

## ⚠️ Important Notes

1. **Firebase Server Key**: This is a sensitive credential. Never commit it to your repository.

2. **Legacy API**: The Edge Functions currently use the Legacy FCM API. Firebase recommends migrating to HTTP v1 API for production, but Legacy API works fine for now.

3. **Migration Applied**: The database migration has already been applied successfully. You can verify by checking the `user_fcm_tokens` table in Supabase Dashboard → Table Editor.

4. **Edge Function Code**: The Edge Function code is ready in `supabase/functions/send-user-fcm-notification/index.ts`. You just need to deploy it.

## 🆘 Troubleshooting

### Cannot Enable Legacy API
- Make sure you're the project owner or have admin permissions
- Try refreshing the Firebase Console page
- The Legacy API might need to be enabled in Google Cloud Console instead (though Firebase Console should handle this)

### Edge Function Deployment Fails
- Make sure the `FIREBASE_SERVER_KEY` secret is set first
- Check that the function code is correct in `supabase/functions/send-user-fcm-notification/index.ts`
- Verify you're logged in to Supabase CLI (if using CLI)

### Notifications Not Received
- Check Edge Function logs in Supabase Dashboard
- Verify FCM tokens are registered in the database
- Check that notification permissions are granted on the device
- Verify the Firebase server key is correct (not truncated)

## 📞 Need Help?

If you encounter issues:
1. Check the logs in Supabase Dashboard → Edge Functions → Logs
2. Verify all secrets are set correctly
3. Check that the database migration was applied (table should exist)
4. Review the troubleshooting section in `FCM_SETUP_COMPLETE.md`

