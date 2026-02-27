# Production Readiness Checklist

Use this checklist before submitting your app to Google Play Console.

## Pre-Submission Verification

### 1. App Icons & Branding
- [ ] Verify all app icons are custom (not Flutter default)
  - Check: `android/app/src/main/res/mipmap-*/ic_launcher.png`
  - Verify icons in all density folders (hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)
  - Ensure Play Store icon is 512x512 PNG (no transparency)
  - Icons should not contain Flutter logo or default Flutter branding

### 2. Environment Configuration
- [ ] Update `lib/core/config/environment.dart`:
  - [ ] `appBaseUrl` - Set to actual production domain
  - [ ] `appDeepLinkScheme` - Set to actual app scheme
  - [ ] Verify Supabase URL and keys are production-ready

### 3. Security Checks
- [ ] No hardcoded credentials in UI (admin login screen)
- [ ] No test/demo data visible in production builds
- [ ] All API keys are public/anon keys (not service_role keys)
- [ ] No debug information exposed in release builds

### 4. Code Quality
- [ ] Run `flutter analyze` and fix all critical errors
- [ ] Run `flutter test` and ensure all tests pass
- [ ] Verify no `print()` statements in release code (all wrapped in `kDebugMode`)
- [ ] Check for TODO/FIXME comments that need attention

### 5. Build Configuration
- [ ] Verify `compileSdk = 35` and `targetSdk = 35` in `android/app/build.gradle.kts`
- [ ] Confirm `minSdk = 21` or higher
- [ ] Verify `isMinifyEnabled = true` and `isShrinkResources = true` for release
- [ ] Confirm release signing is configured (not using debug signing)

### 6. Permissions
- [ ] Review all permissions in `AndroidManifest.xml`
- [ ] Ensure only necessary permissions are requested
- [ ] Verify no high-risk permissions (SMS, CALL_LOG, etc.) unless required
- [ ] Test permission requests work correctly at runtime

### 7. Testing
- [ ] Test on small-screen devices (4.7" phones)
- [ ] Test on large-screen devices (tablets)
- [ ] Verify no layout overflow warnings
- [ ] Check bottom navigation/buttons aren't cut off
- [ ] Test all critical user flows (login, checkout, orders, etc.)
- [ ] Verify app works in both portrait and landscape modes

### 8. Release Build
- [ ] Build release AAB: `flutter build appbundle --release`
- [ ] Test the release AAB on a physical device
- [ ] Verify app size is reasonable
- [ ] Check app startup time is acceptable
- [ ] Verify no debug banners or debug flags

### 9. Google Play Console Requirements
- [ ] App icon (512x512) uploaded to Play Console
- [ ] Feature graphic (1024x500) prepared
- [ ] Screenshots for all required device sizes
- [ ] Privacy policy URL (if required)
- [ ] Content rating questionnaire completed
- [ ] Store listing description and metadata ready

### 10. Notifications (If Applicable)
- [ ] If using push notifications, verify FCM is properly configured
- [ ] Test notifications work when app is closed
- [ ] Verify notification channels are properly set up
- [ ] Test notification permissions are requested correctly

## Post-Submission Monitoring

- [ ] Monitor Google Play Console for any policy violations
- [ ] Check crash reports and ANR (Application Not Responding) reports
- [ ] Monitor user reviews for common issues
- [ ] Track app performance metrics

## Notes

- This checklist should be completed before every production release
- Keep a record of completed items for audit purposes
- Update this checklist as new requirements are identified

