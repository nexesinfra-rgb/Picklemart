# Cloudflare Pages Deployment Checklist

Use this checklist to ensure your Flutter web app is ready for Cloudflare Pages deployment.

## Pre-Deployment Checklist

### ✅ Project Setup
- [x] Flutter project configured for web
- [x] `pubspec.yaml` has all required dependencies
- [x] `web/_redirects` file exists with SPA routing rule
- [x] `_build.sh` script is in project root
- [x] Build output directory is `build/web`

### ✅ Build Script
- [x] `_build.sh` is executable (will be made executable by Cloudflare)
- [x] Script installs Flutter if not present
- [x] Script builds with `--base-href /`
- [x] Script copies `_redirects` file to build output

### ✅ Configuration Files
- [x] `web/index.html` exists
- [x] `web/manifest.json` exists (if using PWA features)
- [x] `web/_redirects` contains: `/*    /index.html   200`
- [x] Assets are properly listed in `pubspec.yaml`

### ✅ Git Repository
- [x] Repository is pushed to GitHub/GitLab/Bitbucket
- [x] All files are committed
- [x] `build/` directory is in `.gitignore` (should not be committed)

## Cloudflare Pages Setup

### Step 1: Create Project
- [ ] Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
- [ ] Navigate to **Workers & Pages** → **Create application** → **Pages**
- [ ] Click **Connect to Git**
- [ ] Select your Git provider and authorize
- [ ] Select your repository

### Step 2: Configure Build Settings
- [ ] **Framework preset**: `None`
- [ ] **Build command**: `bash _build.sh`
- [ ] **Build output directory**: `build/web`
- [ ] **Root directory**: (leave empty)
- [ ] **Node version**: (not needed)
- [ ] **Python version**: (not needed)

### Step 3: Deploy
- [ ] Click **Save and Deploy**
- [ ] Wait for build to complete (first build: ~3-5 minutes)
- [ ] Verify build succeeded in logs
- [ ] Check that app is accessible at `*.pages.dev` URL

### Step 4: Verify Deployment
- [ ] App loads correctly
- [ ] Routes work (try navigating to different pages)
- [ ] Assets load (images, fonts, etc.)
- [ ] No console errors in browser
- [ ] Supabase connection works (if applicable)

## Post-Deployment

### Custom Domain (Optional)
- [ ] Go to **Custom domains** in Pages settings
- [ ] Add your domain
- [ ] Configure DNS as instructed
- [ ] Wait for SSL certificate provisioning
- [ ] Verify domain works

### Environment Variables (If Needed)
- [ ] Go to **Settings** → **Environment variables**
- [ ] Add any required variables
- [ ] Set for Production, Preview, or both
- [ ] Redeploy if needed

### Monitoring
- [ ] Set up Cloudflare Analytics (if desired)
- [ ] Monitor build logs for issues
- [ ] Check deployment history

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Build fails: Flutter not found | Ensure build command is `bash _build.sh` |
| Routes return 404 | Verify `_redirects` file exists in `build/web/` |
| Assets not loading | Check `pubspec.yaml` asset paths |
| Build timeout | First build takes longer (installing Flutter) |
| CORS errors | Check Supabase allowed origins |

## Build Command Reference

**For Cloudflare Pages Dashboard:**
```
Build command: bash _build.sh
Build output directory: build/web
```

**For Local Testing:**
```bash
# Windows
.\cloudflare-pages-build.ps1

# Linux/Mac
chmod +x cloudflare-pages-build.sh
./cloudflare-pages-build.sh
```

## Files Required for Deployment

```
project-root/
├── _build.sh                    # Build script (required)
├── pubspec.yaml                 # Flutter dependencies (required)
├── web/
│   ├── index.html              # Main HTML (required)
│   ├── _redirects              # SPA routing (required)
│   └── manifest.json           # PWA manifest (optional)
└── lib/                        # Flutter source code (required)
```

## Next Steps After Deployment

1. ✅ Test all app features
2. ✅ Verify mobile responsiveness
3. ✅ Check performance (Lighthouse score)
4. ✅ Set up custom domain (if needed)
5. ✅ Configure environment variables (if needed)
6. ✅ Enable Cloudflare optimizations (auto-minify, etc.)

## Support Resources

- **Cloudflare Pages Docs**: https://developers.cloudflare.com/pages/
- **Flutter Web Docs**: https://docs.flutter.dev/platform-integration/web
- **Build Logs**: Available in Cloudflare Pages dashboard

