# Deploy create-customer-account Edge Function

## Quick Deployment Steps

The `create-customer-account` edge function needs to be deployed to Supabase. Follow these steps:

### Step 1: Open Terminal/PowerShell

Navigate to your project directory:
```powershell
cd "C:\Users\Venky\OneDrive\Desktop\optimize\backup\Pickle mart\sm"
```

### Step 2: Check Supabase CLI

Make sure Supabase CLI is installed:
```powershell
supabase --version
```

If not installed, install it:
```powershell
# Using npm
npm install -g supabase

# Or using Scoop (Windows)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

### Step 3: Login and Link (if needed)

```powershell
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref bgqcuykvsiejgqeiefpi
```

### Step 4: Deploy the Function

```powershell
supabase functions deploy create-customer-account
```

### Alternative: Deploy via Supabase Dashboard

If CLI doesn't work, use the dashboard:

1. Go to: https://supabase.com/dashboard/project/bgqcuykvsiejgqeiefpi
2. Click **Edge Functions** in the left sidebar
3. The function should appear in the list if the files are detected
4. Click **Deploy** or use the CLI command shown in the dashboard

## Verify Deployment

After deployment, the function should be available at:
```
https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/create-customer-account
```

## Troubleshooting

- **"Function not found"**: Make sure you're in the correct directory and the function files exist in `supabase/functions/create-customer-account/`
- **"Not logged in"**: Run `supabase login` first
- **"Project not linked"**: Run `supabase link --project-ref bgqcuykvsiejgqeiefpi`
- **"Permission denied"**: Make sure you have access to the Supabase project

