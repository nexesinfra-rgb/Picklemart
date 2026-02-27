# Cloudflare Pages Deployment Guide

This guide explains how to deploy your Flutter web app to Cloudflare Pages.

## Prerequisites

- Flutter SDK installed (version 3.7.2 or higher)
- A Cloudflare account
- Git repository (GitHub, GitLab, or Bitbucket)

## Build Configuration

### Option 1: Automatic Build via Git Integration (Recommended)

1. **Connect Your Repository**
   - Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
   - Navigate to **Workers & Pages** → **Create application** → **Pages** → **Connect to Git**
   - Select your Git provider and authorize Cloudflare
   - Choose your repository

2. **Configure Build Settings**
   
   Use these settings in the Cloudflare Pages dashboard:
   
   - **Framework preset**: None (or "Other")
   - **Build command**: 
     ```bash
     flutter build web --release --base-href /
     ```
   - **Build output directory**: 
     ```
     build/web
     ```
   - **Root directory**: (leave empty)
   - **Environment variables**: 
     - No environment variables needed (Supabase keys are in code)

3. **Install Flutter on Cloudflare Build Environment**
   
   Since Cloudflare Pages build environment may not have Flutter pre-installed, you have two options:
   
   **Option A: Use a Custom Build Image (Recommended)**
   
   Add a `_build.sh` file in your project root with Flutter installation:
   
   ```bash
   #!/bin/bash
   set -e
   
   # Install Flutter
   git clone https://github.com/flutter/flutter.git -b stable --depth 1
   export PATH="$PATH:`pwd`/flutter/bin"
   
   # Build
   flutter doctor
   flutter pub get
   flutter build web --release --base-href /
   ```
   
   Then in Cloudflare Pages settings:
   - **Build command**: `bash _build.sh`
   
   **Option B: Use GitHub Actions for Build**
   
   Build using GitHub Actions and deploy the `build/web` folder to Cloudflare Pages.

### Option 2: Manual Deployment

1. **Build Locally**
   
   **On Windows:**
   ```powershell
   .\cloudflare-pages-build.ps1
   ```
   
   **On Linux/Mac:**
   ```bash
   chmod +x cloudflare-pages-build.sh
   ./cloudflare-pages-build.sh
   ```
   
   Or manually:
   ```bash
   flutter clean
   flutter pub get
   flutter build web --release --base-href /
   ```

2. **Upload to Cloudflare Pages**
   - Go to Cloudflare Dashboard → Workers & Pages
   - Create a new Pages project
   - Upload the contents of the `build/web` directory
   - Deploy

## Important Files

### `web/_redirects`

This file ensures proper routing for your single-page application (SPA). All routes redirect to `index.html` with a 200 status code, allowing Flutter's routing to handle navigation.

```
/*    /index.html   200
```

This file is automatically included in the build output.

### Build Output Structure

After building, your `build/web` directory will contain:
- `index.html` - Main HTML file
- `main.dart.js` - Compiled Dart code
- `assets/` - App assets
- `icons/` - App icons
- `manifest.json` - PWA manifest
- `_redirects` - Cloudflare Pages redirect rules

## Environment Configuration

Your app uses hardcoded configuration in `lib/core/config/environment.dart`:
- Supabase URL: `https://bgqcuykvsiejgqeiefpi.supabase.co`
- Supabase Anon Key: (configured in code)

If you need to change these for production, update `lib/core/config/environment.dart` before building.

## Custom Domain

After deployment, you can add a custom domain in Cloudflare Pages settings:
1. Go to your Pages project
2. Click **Custom domains**
3. Add your domain
4. Follow DNS configuration instructions

## SPA Routing Support

The `_redirects` file ensures that all routes work correctly:
- Direct navigation to routes (e.g., `/products/123`) works
- Browser refresh on any route works
- Deep linking works correctly

## Troubleshooting

### Build Fails: Flutter Not Found
- Ensure Flutter is installed in the build environment
- Use the custom build script approach (Option A above)

### Routes Not Working (404 Errors)
- Ensure `_redirects` file exists in `build/web/`
- Verify the redirect rule is: `/*    /index.html   200`

### Assets Not Loading
- Check that `assets/` folder is included in build
- Verify paths in `pubspec.yaml` are correct
- Ensure base-href is set to `/` during build

### CORS Issues with Supabase
- Supabase should handle CORS automatically
- If issues occur, check Supabase project settings for allowed origins

## Build Settings Summary

```
Framework preset: None
Build command: flutter build web --release --base-href /
Build output directory: build/web
Root directory: (empty)
Node version: (not needed)
Python version: (not needed)
```

## Continuous Deployment

Once connected to Git:
- Every push to the default branch triggers a new deployment
- Preview deployments are created for pull requests
- Build logs are available in the Cloudflare Pages dashboard

## Performance Optimization

Cloudflare Pages automatically provides:
- Global CDN distribution
- Automatic HTTPS
- DDoS protection
- Edge caching

For additional optimization, consider:
- Enabling Cloudflare's auto-minify settings
- Using Cloudflare Workers for API proxying (if needed)
- Enabling Brotli compression

## Support

For issues with:
- **Cloudflare Pages**: [Cloudflare Community](https://community.cloudflare.com/)
- **Flutter Web**: [Flutter Documentation](https://flutter.dev/docs)
- **Supabase**: [Supabase Documentation](https://supabase.com/docs)

