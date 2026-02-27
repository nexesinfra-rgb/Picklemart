import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_result.dart';

class GeocodingService {
  static const String _baseUrl = 'https://photon.komoot.io/api';
  static const String _userAgent = 'LocationPicker/1.0.0 (contact@example.com)';
  static const Duration _timeout = Duration(seconds: 10);

  /// Search for locations using Photon API
  static Future<List<SearchResult>> searchLocations(
    String query, {
    double? latitude,
    double? longitude,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = _buildSearchUri(query, latitude, longitude, limit);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseSearchResults(data);
      } else {
        throw GeocodingException(
          'Search failed with status: ${response.statusCode}'
        );
      }
    } on http.ClientException {
      throw GeocodingException('Network error during search');
    } catch (e) {
      throw GeocodingException('Search failed: $e');
    }
  }

  /// Reverse geocoding - get address from coordinates
  static Future<SearchResult?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse')
          .replace(queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'limit': '1',
      });

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? [];
        if (features.isNotEmpty) {
          return SearchResult.fromJson(features.first);
        }
      }
      return null;
    } catch (e) {
      // Return null for reverse geocoding failures (not critical)
      return null;
    }
  }

  /// Build search URI with proper parameters
  static Uri _buildSearchUri(
    String query,
    double? latitude,
    double? longitude,
    int limit,
  ) {
    final params = <String, String>{
      'q': '$query, India', // Append India to search query
      'limit': limit.toString(),
    };

    // Add location bias if provided
    if (latitude != null && longitude != null) {
      params['lat'] = latitude.toString();
      params['lon'] = longitude.toString();
    }

    return Uri.parse(_baseUrl).replace(queryParameters: params);
  }

  /// Parse search results from API response
  static List<SearchResult> _parseSearchResults(Map<String, dynamic> data) {
    final features = data['features'] as List? ?? [];
    return features
        .map((feature) => SearchResult.fromJson(feature))
        .where((result) => result.latitude != 0.0 && result.longitude != 0.0)
        .toList();
  }

  /// Debounce search queries to avoid excessive API calls
  static String _lastQuery = '';
  static DateTime _lastQueryTime = DateTime.now();
  
  static bool shouldSearch(String query) {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastQueryTime).inMilliseconds;
    
    // Only search if query changed and enough time has passed
    if (query != _lastQuery && timeDiff >= 300) {
      _lastQuery = query;
      _lastQueryTime = now;
      return true;
    }
    
    return false;
  }
}

class GeocodingException implements Exception {
  final String message;
  const GeocodingException(this.message);

  @override
  String toString() => 'GeocodingException: $message';
}
