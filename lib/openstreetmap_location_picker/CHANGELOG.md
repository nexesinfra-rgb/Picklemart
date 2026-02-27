# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-01-XX

### Added
- Initial release of OpenStreetMap Location Picker
- OpenStreetMap integration with proper attribution
- Real-time search functionality using Photon API
- India-specific search restriction
- Auto location detection using device GPS
- Manual location selection by panning the map
- Copy coordinates to clipboard functionality
- Beautiful, responsive UI with rounded corners
- Riverpod state management
- Comprehensive documentation and examples
- Support for both iOS and Android platforms

### Features
- 🗺️ OpenStreetMap map tiles with proper attribution
- 🔍 Real-time search with debouncing (500ms)
- 📍 Auto/Manual location selection modes
- 📋 Copy coordinates with confirmation
- 🎨 Modern UI with draggable bottom sheet
- 🇮🇳 India-focused search results
- 📱 Responsive design for all screen sizes
- 🔄 Efficient state management with Riverpod

### Technical Details
- Flutter SDK: >=3.10.0
- Dart SDK: >=3.0.0
- Dependencies: flutter_map, riverpod, geolocator, http, permission_handler
- Platform support: iOS, Android, Web
- License: MIT
