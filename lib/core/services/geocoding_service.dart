import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/environment.dart';

/// Service for reverse geocoding (converting coordinates to addresses)
class GeocodingService {
  /// Get address string from coordinates
  /// Returns null if geocoding fails
  /// Uses OpenStreetMap Nominatim API on web, geocoding package on mobile
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude, {
    int maxRetries = 2,
  }) async {
    // On web, use OpenStreetMap Nominatim API
    if (kIsWeb) {
      return await _geocodeWithNominatim(latitude, longitude, maxRetries);
    }

    // On mobile, use geocoding package
    int attempts = 0;
    Exception? lastError;

    while (attempts <= maxRetries) {
      try {
        debugPrint(
          'GeocodingService: Attempting to geocode coordinates: '
          'lat=$latitude, lng=$longitude (attempt ${attempts + 1}/${maxRetries + 1})',
        );

        final placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );

        if (placemarks.isEmpty) {
          debugPrint('GeocodingService: No placemarks returned for coordinates');
          return null;
        }

        final place = placemarks.first;
        final address = _formatAddress(place);

        if (address.isNotEmpty && address != 'Unknown Location') {
          debugPrint('GeocodingService: Successfully geocoded to: $address');
          return address;
        } else {
          debugPrint('GeocodingService: Geocoding returned empty or unknown address');
          return null;
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempts++;
        debugPrint(
          'GeocodingService: Geocoding failed (attempt $attempts): $e',
        );

        if (attempts <= maxRetries) {
          // Wait a bit before retrying
          await Future.delayed(Duration(milliseconds: 500 * attempts));
        }
      }
    }

    debugPrint(
      'GeocodingService: All geocoding attempts failed. Last error: $lastError',
    );
    return null;
  }

  /// Geocode using Supabase Edge Function that proxies Nominatim API (for web)
  static Future<String?> _geocodeWithNominatim(
    double latitude,
    double longitude,
    int maxRetries,
  ) async {
    int attempts = 0;
    Exception? lastError;

    while (attempts <= maxRetries) {
      try {
        debugPrint(
          'GeocodingService: Attempting Nominatim geocode via Edge Function: '
          'lat=$latitude, lng=$longitude (attempt ${attempts + 1}/${maxRetries + 1})',
        );

        // Get Supabase URL and anon key from Environment
        final supabaseUrl = Environment.supabaseUrl;
        final anonKey = Environment.supabaseAnonKey;

        // Build Edge Function URL with query parameters
        final functionUrl = Uri.parse(
          '$supabaseUrl/functions/v1/reverse-geocode?'
          'lat=${latitude.toString()}&'
          'lon=${longitude.toString()}',
        );

        // Call Supabase Edge Function using HTTP client
        final response = await http.get(
          functionUrl,
          headers: {
            'Authorization': 'Bearer $anonKey',
            'apikey': anonKey,
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final address = _formatNominatimAddress(data);

          if (address.isNotEmpty) {
            debugPrint('GeocodingService: Successfully geocoded to: $address');
            return address;
          } else {
            debugPrint('GeocodingService: Nominatim returned empty address');
            return null;
          }
        } else {
          throw Exception(
            'Edge Function returned status ${response.statusCode}: ${response.body}',
          );
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempts++;
        debugPrint(
          'GeocodingService: Nominatim geocoding failed (attempt $attempts): $e',
        );

        if (attempts <= maxRetries) {
          // Wait a bit before retrying (Nominatim has rate limits)
          await Future.delayed(Duration(milliseconds: 1000 * attempts));
        }
      }
    }

    debugPrint(
      'GeocodingService: All Nominatim attempts failed. Last error: $lastError',
    );
    return null;
  }

  /// Format Nominatim API response into readable address
  static String _formatNominatimAddress(Map<String, dynamic> data) {
    final parts = <String>[];
    final address = data['address'] as Map<String, dynamic>?;

    if (address == null) {
      // Fallback to display_name if available
      final displayName = data['display_name'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
      return 'Unknown Location';
    }

    // Build address from components (order matters for readability)
    if (address['house_number'] != null && address['road'] != null) {
      parts.add('${address['house_number']} ${address['road']}');
    } else if (address['road'] != null) {
      parts.add(address['road'] as String);
    }

    if (address['suburb'] != null) {
      parts.add(address['suburb'] as String);
    } else if (address['neighbourhood'] != null) {
      parts.add(address['neighbourhood'] as String);
    }

    if (address['city'] != null) {
      parts.add(address['city'] as String);
    } else if (address['town'] != null) {
      parts.add(address['town'] as String);
    } else if (address['village'] != null) {
      parts.add(address['village'] as String);
    }

    if (address['state'] != null) {
      parts.add(address['state'] as String);
    } else if (address['region'] != null) {
      parts.add(address['region'] as String);
    }

    if (address['postcode'] != null) {
      parts.add(address['postcode'] as String);
    }

    if (address['country'] != null) {
      parts.add(address['country'] as String);
    }

    if (parts.isEmpty) {
      // Fallback to display_name if available
      final displayName = data['display_name'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
      return 'Unknown Location';
    }

    return parts.join(', ');
  }

  /// Get address string from LatLng
  static Future<String?> getAddressFromLatLng(LatLng location) async {
    return await getAddressFromCoordinates(
      location.latitude,
      location.longitude,
    );
  }

  /// Format Placemark into a readable address string
  static String _formatAddress(Placemark place) {
    final parts = <String>[];

    // Street address
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }

    // Sub-locality or locality
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    } else if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }

    // Administrative area (state/province)
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    // Postal code
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      parts.add(place.postalCode!);
    }

    // Country
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    if (parts.isEmpty) {
      // Fallback to name if available
      if (place.name != null && place.name!.isNotEmpty) {
        return place.name!;
      }
      return 'Unknown Location';
    }

    return parts.join(', ');
  }
}

