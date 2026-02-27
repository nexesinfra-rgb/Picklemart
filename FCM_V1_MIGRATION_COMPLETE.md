# FCM HTTP v1 API Migration Complete

## ✅ Migration Status

Both FCM Edge Functions have been successfully migrated from the deprecated Legacy API to the modern FCM HTTP v1 API.

## What Changed

### Before (Legacy API - Deprecated)
- ❌ Used server key authentication (`FIREBASE_SERVER_KEY`)
- ❌ Endpoint: `https://fcm.googleapis.com/fcm/send`
- ❌ Deprecated API (scheduled for shutdown)
- ❌ Less secure (long-lived server keys)

### After (HTTP v1 API - Current)
- ✅ Uses OAuth 2.0 authentication with service account
- ✅ Endpoint: `https://fcm.googleapis.com/v1/projects/{project-id}/messages:send`
- ✅ Modern, supported API
- ✅ More secure (short-lived OAuth tokens)

## Files Modified

1. ✅ `supabase/functions/_shared/fcm_auth.ts` (NEW) - OAuth token generation utility
2. ✅ `supabase/functions/send-admin-fcm-notification/index.ts` - Updated to v1 API
3. ✅ `supabase/functions/send-user-fcm-notification/index.ts` - Updated to v1 API
4. ✅ `supabase/functions/send-admin-fcm-notification/README.md` - Updated documentation
5. ✅ `supabase/functions/send-user-fcm-notification/README.md` - Updated documentation

## Setup Required

### Step 1: Get Firebase Service Account JSON

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **picklemart-9a4b0**
3. Click ⚙️ → **Project Settings** → **Service Accounts** tab
4. Click **"Generate new private key"**
5. Click **"Generate key"** to download the JSON file
6. Save the file securely (contains sensitive credentials)

### Step 2: Set Secret in Supabase

**Using Supabase Dashboard (Recommended):**

1. Go to: https://supabase.com/dashboard/project/bgqcuykvsiejgqeiefpi
2. Click **Settings** → **Edge Functions** → **Secrets** tab
3. Click **Add new secret**
4. Enter:
   - **Name**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: Paste the entire contents of the service account JSON file
5. Click **Save**

**Note:** You can remove the old `FIREBASE_SERVER_KEY` secret after confirming the new setup works.

### Step 3: Deploy Edge Functions

Deploy both updated functions:

```bash
# If using Supabase CLI
supabase functions deploy send-admin-fcm-notification
supabase functions deploy send-user-fcm-notification
```

Or deploy via Supabase Dashboard → Edge Functions.

## Features

### OAuth Token Management
- Automatic OAuth 2.0 token generation from service account
- Token caching (tokens cached for 55 minutes, valid for 1 hour)
- Automatic token refresh when expired

### Security Improvements
- Short-lived access tokens (instead of long-lived server keys)
- Service account-based authentication
- More secure credential management

### API Improvements
- Modern FCM HTTP v1 API endpoint
- Better error handling and reporting
- Improved response format

## Testing

After setup, test the functions:

### Test Admin Notifications
```bash
curl -X POST 'https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/send-admin-fcm-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "order_status_changed",
    "title": "Test Notification",
    "message": "Testing FCM v1 API migration",
    "order_id": "test-id",
    "order_number": "TEST-001"
  }'
```

### Test User Notifications
```bash
curl -X POST 'https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/send-user-fcm-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "order_status_changed",
    "title": "Test Notification",
    "message": "Testing FCM v1 API migration",
    "order_id": "test-id",
    "order_number": "TEST-001"
  }'
```

## Troubleshooting

### "Firebase authentication failed" Error

- Verify `FIREBASE_SERVICE_ACCOUNT` secret is set
- Check that the JSON is valid (no formatting issues)
- Ensure all required fields are present: `project_id`, `private_key`, `client_email`

### Token Generation Errors

- Verify the private key is properly formatted (PEM format)
- Check that the service account has Firebase Cloud Messaging permissions
- Review Edge Function logs for detailed error messages

### Notification Delivery Issues

- Check Edge Function logs in Supabase Dashboard
- Verify FCM tokens are valid in the database
- Check Firebase Console → Cloud Messaging for delivery statistics
- Ensure devices have valid FCM tokens registered

## Migration Benefits

1. **Security**: OAuth 2.0 tokens are more secure than server keys
2. **Compliance**: Using the supported API (Legacy API is deprecated)
3. **Future-proof**: HTTP v1 API is the current and future standard
4. **Better Error Handling**: v1 API provides more detailed error responses
5. **Token Management**: Automatic caching reduces API calls

## Notes

- The old `FIREBASE_SERVER_KEY` secret can be removed after migration is confirmed working
- OAuth tokens are automatically cached and refreshed
- Both functions share the same authentication utility (`fcm_auth.ts`)
- Service account JSON should be kept secure and never committed to version control

## Next Steps

1. ✅ Code migration completed
2. ⚠️ Get service account JSON from Firebase Console
3. ⚠️ Set `FIREBASE_SERVICE_ACCOUNT` secret in Supabase
4. ⚠️ Deploy updated Edge Functions
5. ⚠️ Test notifications
6. ⚠️ Remove old `FIREBASE_SERVER_KEY` secret (optional, after confirming everything works)

