# OpenStreetMap Location Picker

A beautiful, customizable location picker widget using OpenStreetMap with search functionality, auto/manual location selection, and India-specific search.

## Features

- 🗺️ **OpenStreetMap Integration** - High-quality map tiles with proper attribution
- 🔍 **Real-time Search** - Powered by Photon API with India-only results
- 📍 **Auto Location** - Automatic GPS location detection
- ✋ **Manual Selection** - Pan and select precise locations
- 📋 **Copy Coordinates** - Easy clipboard integration
- 🎨 **Beautiful UI** - Modern, responsive design with rounded corners
- 🔄 **State Management** - Built with Riverpod for efficient state handling
- 🇮🇳 **India Focused** - Optimized for Indian locations

## Screenshots

![Location Picker](https://via.placeholder.com/300x600/4CAF50/FFFFFF?text=Location+Picker)
![Search Results](https://via.placeholder.com/300x400/2196F3/FFFFFF?text=Search+Results)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  openstreetmap_location_picker:
    git:
      url: https://github.com/yourusername/openstreetmap_location_picker.git
      ref: main
```

Or if published to pub.dev:

```yaml
dependencies:
  openstreetmap_location_picker: ^0.1.0
```

## Usage

### Basic Usage

```dart
import 'package:openstreetmap_location_picker/openstreetmap_location_picker.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final location = await showLocationPicker(
                context: context,
                initialLocation: LocationData(
                  latitude: 28.6139, 
                  longitude: 77.2090
                ),
              );
              
              if (location != null) {
                print('Selected: ${location.coordinatesString}');
                print('Address: ${location.displayAddress}');
              }
            },
            child: Text('Pick Location'),
          ),
        ),
      ),
    );
  }
}
```

### Advanced Usage

```dart
// Custom initial location
final location = await showLocationPicker(
  context: context,
  initialLocation: LocationData(
    latitude: 19.0760,  // Mumbai
    longitude: 72.8777,
    address: 'Mumbai, Maharashtra, India',
  ),
  searchHint: 'Search locations in India...',
  restrictToIndia: true, // Default: true
);

if (location != null) {
  // Use the selected location
  print('Latitude: ${location.latitude}');
  print('Longitude: ${location.longitude}');
  print('Address: ${location.address}');
  print('City: ${location.city}');
  print('Country: ${location.country}');
}
```

### Using the Widget Directly

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openstreetmap_location_picker/openstreetmap_location_picker.dart';

class MyLocationPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Picker')),
      body: LocationPickerBottomSheet(
        onLocationSelected: (location) {
          // Handle location selection
          print('Selected: ${location.coordinatesString}');
        },
      ),
    );
  }
}
```

## API Reference

### `showLocationPicker()`

Shows the location picker as a bottom sheet.

**Parameters:**
- `context` (required) - BuildContext
- `initialLocation` - Initial location to display on map
- `searchHint` - Custom hint text for search bar
- `restrictToIndia` - Whether to restrict search to India (default: true)

**Returns:** `Future<LocationData?>` - Selected location or null if cancelled

### `LocationData`

Model class representing a location.

**Properties:**
- `latitude` - Latitude coordinate
- `longitude` - Longitude coordinate
- `address` - Full address string
- `city` - City name
- `country` - Country name
- `coordinatesString` - Formatted coordinates as string
- `displayAddress` - Best available address for display

### `SearchResult`

Model class for search results.

**Properties:**
- `name` - Location name
- `displayName` - Formatted display name
- `latitude` - Latitude coordinate
- `longitude` - Longitude coordinate
- `city` - City name
- `country` - Country name

## Configuration

### Required Permissions

Add these permissions to your platform-specific files:

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
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to show your current position on the map and allow location selection.</string>
```

### Riverpod Setup

Make sure your app is wrapped with `ProviderScope`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}
```

## Attribution

This package uses OpenStreetMap data and requires proper attribution. The attribution is automatically displayed in the map view as required by the Open Database License (ODbL).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.

## Support

If you encounter any issues or have questions, please file an issue on the [GitHub repository](https://github.com/yourusername/openstreetmap_location_picker/issues).
