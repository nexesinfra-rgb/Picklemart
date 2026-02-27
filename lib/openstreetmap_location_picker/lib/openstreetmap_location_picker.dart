import 'package:flutter/material.dart';

// Import models for use in this file
import 'src/models/location_data.dart';
import 'src/widgets/location_picker_bottom_sheet.dart';

// Export models and widgets for external use
export 'src/models/location_data.dart';
export 'src/models/search_result.dart';
export 'src/widgets/location_picker_bottom_sheet.dart';

/// OpenStreetMap Location Picker
/// 
/// A beautiful, customizable location picker widget using OpenStreetMap
/// with search functionality, auto/manual location selection, and India-specific search.
/// 
/// ## Features
/// - 🗺️ OpenStreetMap integration with proper attribution
/// - 🔍 Real-time search with Photon API (India-only)
/// - 📍 Auto location detection using device GPS
/// - ✋ Manual location selection by panning the map
/// - 📋 Copy coordinates to clipboard
/// - 🎨 Beautiful, responsive UI with rounded corners
/// - 🔄 Riverpod state management
/// 
/// ## Usage
/// 
/// ```dart
/// import 'package:openstreetmap_location_picker/openstreetmap_location_picker.dart';
/// 
/// // Show location picker
/// final location = await showLocationPicker(
///   context: context,
///   initialLocation: LocationData(latitude: 28.6139, longitude: 77.2090),
/// );
/// 
/// if (location != null) {
///   print('Selected: ${location.coordinatesString}');
/// }
/// ```
/// 
/// ## Attribution
/// 
/// This package uses OpenStreetMap data and requires proper attribution.
/// The attribution is automatically displayed in the map view.

/// Shows the OpenStreetMap location picker as a bottom sheet.
/// 
/// Returns the selected [LocationData] or null if cancelled.
/// 
/// Example:
/// ```dart
/// final location = await showLocationPicker(
///   context: context,
///   initialLocation: LocationData(latitude: 28.6139, longitude: 77.2090),
/// );
/// ```
Future<LocationData?> showLocationPicker({
  required BuildContext context,
  LocationData? initialLocation,
  String? searchHint,
  bool restrictToIndia = true,
}) async {
  // Use showModalBottomSheet with type parameter to return LocationData directly
  // The sheetContext is the correct context for closing only the bottom sheet
  return await showModalBottomSheet<LocationData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => LocationPickerBottomSheet(
      onLocationSelected: (location) {
        // Use sheetContext to pop only the bottom sheet, not the parent screen
        Navigator.of(sheetContext).pop(location);
      },
    ),
  );
}
