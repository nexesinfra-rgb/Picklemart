import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'browser_location_stub.dart'
    if (dart.library.html) '../../features/cart/presentation/web_geo_impl.dart';
import 'geocoding_service.dart';

/// Service for handling location permissions and location capture
class LocationService {
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    if (kIsWeb) {
      return true; // Browser handles this
    }
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current location permission status
  static Future<LocationPermission> checkPermission() async {
    if (kIsWeb) {
      // On web, we'll check when requesting
      return LocationPermission.whileInUse;
    }
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    if (kIsWeb) {
      // Web handles permission via browser
      return LocationPermission.whileInUse;
    }
    return await Geolocator.requestPermission();
  }

  /// Get current location with permission handling
  /// Returns null if permission is denied or location cannot be obtained
  /// [includeAddress] - If true, performs reverse geocoding to get address (slower)
  static Future<LocationResult?> getCurrentLocation({
    bool includeAddress = false,
  }) async {
    try {
      // Check if location services are enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        return LocationResult(
          success: false,
          error: 'Location services are disabled. Please enable them in settings.',
        );
      }

      // Check and request permission
      LocationPermission permission = await checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          success: false,
          error: 'Location permission is permanently denied. Please enable it in app settings.',
          permissionDeniedForever: true,
        );
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return LocationResult(
          success: false,
          error: 'Location permission is denied.',
        );
      }

      // Get location
      Position position;
      if (kIsWeb) {
        // Try browser geolocation first
        final browserPos = await getBrowserPosition();
        if (browserPos != null) {
          String? address;
          if (includeAddress) {
            address = await GeocodingService.getAddressFromLatLng(browserPos);
          }
          return LocationResult(
            success: true,
            location: browserPos,
            accuracy: 0.0, // Browser doesn't provide accuracy
            address: address,
          );
        }
        // Fallback to geolocator on web
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } else {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      final location = LatLng(position.latitude, position.longitude);
      
      // Optionally get address via reverse geocoding
      String? address;
      if (includeAddress) {
        address = await GeocodingService.getAddressFromLatLng(location);
      }

      return LocationResult(
        success: true,
        location: location,
        accuracy: position.accuracy,
        address: address,
      );
    } catch (e) {
      return LocationResult(
        success: false,
        error: 'Failed to get location: $e',
      );
    }
  }

  /// Check if we can request permission (not denied forever)
  static Future<bool> canRequestPermission() async {
    final permission = await checkPermission();
    return permission != LocationPermission.deniedForever;
  }

  /// Open app settings to enable location permission
  static Future<bool> openAppSettings() async {
    if (kIsWeb) {
      return false; // Not applicable on web
    }
    return await Geolocator.openAppSettings();
  }

  /// Open location settings
  static Future<bool> openLocationSettings() async {
    if (kIsWeb) {
      return false; // Not applicable on web
    }
    return await Geolocator.openLocationSettings();
  }
}

/// Result of location request
class LocationResult {
  final bool success;
  final LatLng? location;
  final double? accuracy;
  final String? address;
  final String? error;
  final bool permissionDeniedForever;

  LocationResult({
    required this.success,
    this.location,
    this.accuracy,
    this.address,
    this.error,
    this.permissionDeniedForever = false,
  });
}

