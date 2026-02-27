# Cloudflare Pages Quick Start Guide

This is a quick reference guide for deploying your Flutter web app to Cloudflare Pages.

## Prerequisites

- ✅ Flutter project configured for web
- ✅ Git repository (GitHub, GitLab, or Bitbucket)
- ✅ Cloudflare account

## Deployment Steps

### Step 1: Connect Repository to Cloudflare Pages

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Workers & Pages** → **Create application** → **Pages** → **Connect to Git**
3. Select your Git provider (GitHub, GitLab, or Bitbucket)
4. Authorize Cloudflare to access your repositories
5. Select your repository: `sm` (or your repo name)

### Step 2: Configure Build Settings

In the Cloudflare Pages project settings, use these **exact** settings:

```
Framework preset: None
Build command: bash _build.sh
Build output directory: build/web
Root directory: (leave empty)
```

**Important Settings:**
- **Build command**: `bash _build.sh`
- **Build output directory**: `build/web`
- **Root directory**: (empty - use project root)
- **Node version**: (not needed)
- **Python version**: (not needed)

### Step 3: Deploy

1. Click **Save and Deploy**
2. Cloudflare will automatically:
   - Clone your repository
   - Run the `_build.sh` script
   - Install Flutter
   - Build your Flutter web app
   - Deploy to Cloudflare Pages

### Step 4: Access Your App

After deployment completes:
- Your app will be available at: `https://<project-name>.pages.dev`
- You can find the URL in the Cloudflare Pages dashboard

## Build Script Details

The `_build.sh` script automatically:
1. ✅ Installs Flutter SDK (if not present)
2. ✅ Enables web support
3. ✅ Gets Flutter dependencies
4. ✅ Builds the web app in release mode
5. ✅ Copies `_redirects` file for SPA routing

## Environment Variables

Currently, no environment variables are needed as Supabase configuration is in code. If you need to add environment variables later:

1. Go to **Settings** → **Environment variables** in Cloudflare Pages
2. Add variables for each environment (Production, Preview, etc.)

## Custom Domain Setup

1. Go to your Pages project → **Custom domains**
2. Click **Set up a custom domain**
3. Enter your domain name
4. Follow DNS configuration instructions
5. Cloudflare will automatically provision SSL certificates

## Continuous Deployment

Once connected:
- ✅ Every push to your default branch triggers a new production deployment
- ✅ Pull requests get preview deployments automatically
- ✅ Build logs are available in the dashboard

## Troubleshooting

### Build Fails: "Flutter not found"
- ✅ The `_build.sh` script automatically installs Flutter
- ✅ Make sure build command is: `bash _build.sh`

### Build Fails: "Command not found: bash"
- Cloudflare Pages uses bash by default
- If issues persist, try: `sh _build.sh`

### Routes Return 404
- ✅ The `_redirects` file is automatically copied during build
- ✅ Verify it exists in `build/web/_redirects` after build
- ✅ Content should be: `/*    /index.html   200`

### Assets Not Loading
- ✅ Check that assets are listed in `pubspec.yaml`
- ✅ Verify `base-href` is set to `/` (done automatically in build script)

### Build Takes Too Long
- First build installs Flutter (~2-3 minutes)
- Subsequent builds are faster (~1-2 minutes)
- Consider using GitHub Actions for faster builds if needed

## Manual Deployment (Alternative)

If you prefer to build locally and upload:

1. **Build locally:**
   ```bash
   # On Windows
   .\cloudflare-pages-build.ps1
   
   # On Linux/Mac
   chmod +x cloudflare-pages-build.sh
   ./cloudflare-pages-build.sh
   ```

2. **Upload to Cloudflare Pages:**
   - Go to your Pages project
   - Click **Upload assets**
   - Upload the contents of `build/web` directory
   - Deploy

## Build Output Structure

After build, `build/web` contains:
```
build/web/
├── index.html
├── main.dart.js
├── flutter_bootstrap.js
├── assets/
├── icons/
├── manifest.json
└── _redirects
```

## Support

- **Cloudflare Pages Docs**: https://developers.cloudflare.com/pages/
- **Flutter Web Docs**: https://docs.flutter.dev/platform-integration/web
- **Project Issues**: Check build logs in Cloudflare Pages dashboard

