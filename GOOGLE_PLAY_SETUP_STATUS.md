# Google Play Console Setup Status

## ✅ Completed Tasks

### 1. Branding Fixes
- ✅ Replaced all "Shopping Mall" references with "Pickle Mart" in:
  - `lib/features/profile/presentation/terms_privacy_screen.dart` (3 instances)
  - `lib/features/profile/presentation/settings_screen.dart` (1 instance)
  - `lib/features/profile/presentation/help_support_screen.dart` (1 instance)

### 2. Contact Email Updates
- ✅ Updated all email addresses to `picklemartapp@gmail.com` in:
  - Terms of Service contact (line 90)
  - Privacy Policy contact (line 177)

### 3. Keystore Setup
- ✅ Created PowerShell script: `android/setup_keystore.ps1`
- ✅ Verified `.gitignore` excludes keystore files
- ✅ Keystore file generated: `android/app/upload-keystore.jks`
- ✅ Created `android/key.properties` file
- ✅ Passwords configured in `key.properties`
- ✅ Fixed build.gradle.kts compilation issues
- ✅ Updated compileSdk to 36 (required by plugins)
- ✅ Added ProGuard rules for Play Core
- ✅ **Release AAB successfully built**: `build/app/outputs/bundle/release/app-release.aab`
- ✅ Keystore details:
  - CN: Pickle Mart
  - OU: Pickle Mart
  - O: Pickle Mart
  - L: West Godavari
  - ST: Andhra pradesh
  - C: IN
  - Validity: 10,000 days
  - Algorithm: RSA 2048-bit

## ⚠️ Manual Steps Required

### 4. App Icon Verification
**Action Required:** Manually verify that all app icons are custom (not Flutter defaults):

Check these files:
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

**If icons are Flutter defaults:**
- Replace with custom Pickle Mart branding icons
- Ensure icons are high-resolution and match your brand
- Create a 512x512 PNG icon for Google Play Console upload (no transparency)

## Next Steps for Google Play Console

1. ✅ Keystore setup complete (passwords configured)
2. ✅ Release AAB built successfully
3. ⚠️ Verify app icons are custom
4. Test the AAB on a physical device
5. Prepare store listing:
   - App Title: "Pickle Mart" (max 50 chars) ✅
   - Short Description: Prepare (max 80 chars)
   - Full Description: Prepare (max 4,000 chars with ASO keywords)
   - Feature Graphic: 1024x500 image
   - Screenshots: Minimum 2 screenshots
   - App Icon: 512x512 PNG (no transparency)
6. Host Privacy Policy online and add URL to Play Console
7. Complete content rating questionnaire
8. Submit for review

## Verification Commands

After completing manual steps, verify everything works:

```bash
# Check for any remaining "Shopping Mall" references
grep -r "Shopping Mall" lib/

# Check for old email addresses
grep -r "shoppingmall.com" lib/

# Verify keystore exists (should return True)
Test-Path android/app/upload-keystore.jks
# ✅ Keystore file confirmed at: android/app/upload-keystore.jks

# Build release bundle
flutter build appbundle --release
```

## Notes

- All code changes have been completed and verified (no linting errors)
- Keystore files are properly excluded from version control
- Branding is now consistent throughout the app
- Contact information is updated to `picklemartapp@gmail.com`

