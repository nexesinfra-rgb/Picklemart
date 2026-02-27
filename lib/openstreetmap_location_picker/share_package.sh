#!/bin/bash

# Script to help share the OpenStreetMap Location Picker package

echo "🚀 OpenStreetMap Location Picker Package"
echo "========================================"
echo ""

echo "📁 Package Location:"
echo "   $(pwd)"
echo ""

echo "📋 To share this package with your coworkers:"
echo ""
echo "1️⃣  Copy this folder to a shared location or Git repository"
echo "2️⃣  Share the path or Git URL with your team"
echo "3️⃣  They add this to their pubspec.yaml:"
echo ""
echo "   dependencies:"
echo "     openstreetmap_location_picker:"
echo "       path: $(pwd)"
echo ""
echo "   OR if using Git:"
echo ""
echo "   dependencies:"
echo "     openstreetmap_location_picker:"
echo "       git:"
echo "         url: https://github.com/yourusername/openstreetmap_location_picker.git"
echo "         ref: main"
echo ""

echo "📖 Documentation:"
echo "   - README.md - Full documentation"
echo "   - USAGE_GUIDE.md - Quick start for coworkers"
echo "   - example/ - Working example app"
echo ""

echo "✅ Package is ready to share!"
echo ""
echo "🧪 To test the package:"
echo "   cd example && flutter run"
