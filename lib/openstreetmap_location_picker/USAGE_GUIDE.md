# Quick Usage Guide for Coworkers

## How to Use This Package

### 1. Add to Your Project

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  openstreetmap_location_picker:
    path: /Users/sourab/Desktop/openstreetmap_location_picker
```

Or if you have it in a Git repository:

```yaml
dependencies:
  openstreetmap_location_picker:
    git:
      url: https://github.com/yourusername/openstreetmap_location_picker.git
      ref: main
```

### 2. Import in Your Code

```dart
import 'package:openstreetmap_location_picker/openstreetmap_location_picker.dart';
```

### 3. Use the Location Picker

**Simple Usage:**
```dart
final location = await showLocationPicker(context: context);

if (location != null) {
  print('Selected: ${location.coordinatesString}');
  print('Address: ${location.displayAddress}');
}
```

**Advanced Usage:**
```dart
final location = await showLocationPicker(
  context: context,
  initialLocation: LocationData(
    latitude: 28.6139,  // Delhi
    longitude: 77.2090,
  ),
  searchHint: 'Search locations in India...',
);

if (location != null) {
  // Use the selected location
  print('Latitude: ${location.latitude}');
  print('Longitude: ${location.longitude}');
  print('Address: ${location.address}');
}
```

### 4. Required Setup

**Make sure your app is wrapped with ProviderScope:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}
```

**Add permissions to your platform files:**

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show your current position on the map and allow location selection.</string>
```

### 5. Features

- 🗺️ **OpenStreetMap** - High-quality map tiles
- 🔍 **Search** - Real-time search for Indian locations
- 📍 **Auto Location** - Get current GPS location
- ✋ **Manual Selection** - Pan map to select location
- 📋 **Copy Coordinates** - Easy clipboard integration
- 🎨 **Beautiful UI** - Modern, responsive design

### 6. Example

See the `example/` folder for a complete working example.

### 7. Need Help?

Check the main `README.md` for detailed documentation and API reference.
