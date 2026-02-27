#!/bin/bash
# Cloudflare Pages Build Script for Flutter Web
# This script prepares your Flutter app for deployment on Cloudflare Pages

set -e

echo "🚀 Starting Flutter web build for Cloudflare Pages..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Get Flutter version
echo "📱 Flutter version:"
flutter --version

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Build for web with release mode
echo "🔨 Building Flutter web app (release mode)..."
flutter build web --release --base-href /

# Ensure _redirects file exists in build output
echo "📝 Ensuring _redirects file exists..."
if [ -f "web/_redirects" ]; then
    cp web/_redirects build/web/_redirects
    echo "✅ _redirects file copied to build/web/"
else
    echo "⚠️  Warning: web/_redirects not found, creating default one..."
    echo "/*    /index.html   200" > build/web/_redirects
fi

echo "✅ Build complete!"
echo "📂 Build output directory: build/web"
echo ""
echo "Next steps:"
echo "1. Upload the contents of 'build/web' to Cloudflare Pages"
echo "2. Or connect your Git repository to Cloudflare Pages with these build settings:"
echo "   - Build command: flutter build web --release --base-href /"
echo "   - Build output directory: build/web"
echo "   - Root directory: (leave empty or set to project root)"

