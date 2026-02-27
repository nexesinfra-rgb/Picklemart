#!/bin/bash
# Custom build script for Cloudflare Pages
# This installs Flutter and builds the web app

set -e

echo "🚀 Cloudflare Pages Build Script Starting..."

# Install Flutter
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    export PATH="$PATH:$(pwd)/flutter/bin"
    
    # Enable web support (skip Android/iOS setup)
    flutter config --enable-web || true
else
    echo "✅ Flutter already installed"
fi

# Verify Flutter installation
echo "📱 Flutter version:"
flutter --version

# Ensure web is enabled
flutter config --enable-web || true

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean || true

# Build for web
echo "🔨 Building web app (release mode)..."
flutter build web --release --base-href /

# Ensure _redirects file is in build output
if [ -f "web/_redirects" ]; then
    cp web/_redirects build/web/_redirects
    echo "✅ _redirects file copied to build/web/"
else
    echo "/*    /index.html   200" > build/web/_redirects
    echo "✅ Default _redirects file created in build/web/"
fi

# Verify build output
if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
    echo "✅ Build complete! Output directory: build/web"
    echo "📂 Ready for Cloudflare Pages deployment"
    echo "📊 Build output size:"
    du -sh build/web
else
    echo "❌ Build failed: build/web directory not found or incomplete"
    exit 1
fi

