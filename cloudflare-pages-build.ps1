# Cloudflare Pages Build Script for Flutter Web (PowerShell)
# This script prepares your Flutter app for deployment on Cloudflare Pages

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Flutter web build for Cloudflare Pages..." -ForegroundColor Cyan

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>&1
    Write-Host "📱 Flutter version:" -ForegroundColor Green
    Write-Host $flutterVersion
} catch {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Cyan
flutter clean

# Get dependencies
Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Cyan
flutter pub get

# Build for web with release mode
Write-Host "🔨 Building Flutter web app (release mode)..." -ForegroundColor Cyan
flutter build web --release --base-href /

# Ensure _redirects file exists in build output
Write-Host "📝 Ensuring _redirects file exists..." -ForegroundColor Cyan
if (Test-Path "web\_redirects") {
    Copy-Item "web\_redirects" -Destination "build\web\_redirects" -Force
    Write-Host "✅ _redirects file copied to build/web/" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: web/_redirects not found, creating default one..." -ForegroundColor Yellow
    "/*    /index.html   200" | Out-File -FilePath "build\web\_redirects" -Encoding utf8
}

Write-Host "✅ Build complete!" -ForegroundColor Green
Write-Host "📂 Build output directory: build/web" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Upload the contents of 'build/web' to Cloudflare Pages"
Write-Host "2. Or connect your Git repository to Cloudflare Pages with these build settings:"
Write-Host "   - Build command: flutter build web --release --base-href /" -ForegroundColor White
Write-Host "   - Build output directory: build/web" -ForegroundColor White
Write-Host "   - Root directory: (leave empty or set to project root)" -ForegroundColor White

