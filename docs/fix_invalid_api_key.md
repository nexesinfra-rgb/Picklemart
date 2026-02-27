# Fix "Invalid API Key" Error

## Problem

You're seeing a 401 error with message "Invalid API key" when trying to sign up or log in:

```
🔐 Auth Error: status=401, message=Invalid API key, code=401
```

## Root Cause

The Supabase anon key in your app configuration (`lib/core/config/environment.dart`) is either:
1. **Incorrect** - Doesn't match your Supabase project
2. **Expired** - Key was rotated/changed in Supabase
3. **Wrong Key Type** - Using service_role key instead of anon key
4. **Missing** - Key is empty or not properly set

## Solution: Get and Update the Correct Anon Key

### Step 1: Get Your Anon Key from Supabase

1. **Go to Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project: `bgqcuykvsiejgqeiefpi` (or your project name)

2. **Open API Settings**
   - Click on **Settings** (gear icon) in the left sidebar
   - Click on **API** in the settings menu

3. **Copy the Anon/Public Key**
   - Find the section labeled **"Project API keys"**
   - Look for **"anon"** or **"public"** key (NOT the service_role key!)
   - Click the **eye icon** or **copy icon** to reveal and copy the key
   - The key should start with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### Step 2: Update environment.dart

1. **Open the file**
   - Navigate to: `lib/core/config/environment.dart`

2. **Update the anon key**
   - Find the line: `static const String supabaseAnonKey = '...';`
   - Replace the value between the quotes with your new anon key
   - Make sure to keep the quotes!

3. **Example:**
   ```dart
   static const String supabaseAnonKey =
       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.YOUR_NEW_KEY_HERE';
   ```

### Step 3: Verify Configuration

1. **Check the URL matches**
   - Verify `supabaseUrl` matches your project URL
   - Current: `https://bgqcuykvsiejgqeiefpi.supabase.co`
   - Should match what's in Supabase Dashboard → Settings → API → Project URL

2. **Save the file**
   - Save `environment.dart`

### Step 4: Restart Your App

1. **Hot Restart** (not just hot reload)
   - Stop the app completely
   - Restart it from scratch
   - This ensures the new key is loaded

2. **Test Signup/Login**
   - Try signing up or logging in again
   - The error should be resolved

## Verification Checklist

- [ ] Anon key copied from Supabase Dashboard → Settings → API
- [ ] Using the **anon/public** key (NOT service_role)
- [ ] Key updated in `lib/core/config/environment.dart`
- [ ] URL matches your Supabase project URL
- [ ] App restarted (not just hot reloaded)
- [ ] Signup/login works without errors

## Common Mistakes

### ❌ Wrong: Using Service Role Key
```dart
// DON'T use service_role key - it's for server-side only!
static const String supabaseAnonKey = 'service_role_key_here';
```

### ✅ Correct: Using Anon/Public Key
```dart
// Use anon/public key - safe for client-side use
static const String supabaseAnonKey = 'anon_key_here';
```

### ❌ Wrong: Missing Quotes
```dart
static const String supabaseAnonKey = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...; // Missing quotes!
```

### ✅ Correct: Proper Quotes
```dart
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // Correct!
```

## Key Security Notes

- **Anon Key**: Safe to use in client-side code (Flutter app)
- **Service Role Key**: NEVER use in client-side code - it bypasses all security!
- **Key Rotation**: If you rotate keys in Supabase, update your app immediately
- **Version Control**: Be careful not to commit service_role keys to git

## Still Getting Errors?

If you're still getting "Invalid API key" after updating:

1. **Double-check the key**
   - Make sure you copied the entire key (they're long!)
   - No extra spaces or characters
   - Key starts with `eyJ`

2. **Verify project URL**
   - Check that `supabaseUrl` matches your project
   - Should be: `https://YOUR_PROJECT_REF.supabase.co`

3. **Check Supabase Dashboard**
   - Go to Settings → API
   - Verify the key is active (not disabled)
   - Check if keys were recently rotated

4. **Clear app cache**
   - Uninstall and reinstall the app
   - Or clear app data/cache

5. **Check console logs**
   - Look for the debug print: `🔐 Auth Error: status=401, message=...`
   - This will show the exact error message

## Quick Reference

| Issue | Solution |
|-------|----------|
| Invalid API key | Get anon key from Supabase Dashboard → Settings → API |
| Key expired | Supabase rotated keys - get new anon key |
| Wrong key type | Use anon/public key, NOT service_role |
| Key not updating | Restart app (not just hot reload) |

## Need Help?

1. Check Supabase Dashboard → Settings → API for your keys
2. Verify the key format (should be a long JWT token)
3. Ensure you're using the anon/public key
4. Restart your app after updating the key

