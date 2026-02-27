import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/services/geocoding_service.dart';
import 'package:latlong2/latlong.dart';

/// Repository interface for location operations
abstract class LocationRepository {
  Future<void> saveLocation({
    required String userId,
    String? sessionId,
    required double latitude,
    required double longitude,
    String? address,
    double? accuracy,
  });

  Future<UserLocation?> getLastLocation(String userId);
  Future<List<UserLocation>> getLocationHistory(
    String userId, {
    int? limit = 50,
    void Function(UserLocation)? onAddressFetched,
  });
  Stream<List<UserLocation>> subscribeToLocationUpdates(String userId);
}

/// Supabase implementation of LocationRepository
class LocationRepositorySupabase implements LocationRepository {
  final SupabaseClient _supabase;

  LocationRepositorySupabase(this._supabase);

  @override
  Future<void> saveLocation({
    required String userId,
    String? sessionId,
    required double latitude,
    required double longitude,
    String? address,
    double? accuracy,
  }) async {
    try {
      await _supabase.from('user_locations').insert({
        'user_id': userId,
        'session_id': sessionId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'accuracy': accuracy,
        'captured_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save location: $e');
    }
  }

  @override
  Future<UserLocation?> getLastLocation(String userId) async {
    try {
      final response =
          await _supabase
              .from('user_locations')
              .select()
              .eq('user_id', userId)
              .order('captured_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) return null;

      return UserLocation.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get last location: $e');
    }
  }

  @override
  Future<List<UserLocation>> getLocationHistory(
    String userId, {
    int? limit = 50,
    void Function(UserLocation)? onAddressFetched,
  }) async {
    try {
      var query = _supabase
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .order('captured_at', ascending: false);

      // Apply default limit of 50 if not specified
      query = query.limit(limit ?? 50);

      final response = await query;

      final locations =
          (response as List)
              .map((json) => UserLocation.fromJson(json))
              .toList();

      // Fetch addresses for locations that don't have them (non-blocking)
      // Don't await - let it run in background
      _fetchMissingAddresses(locations, onAddressFetched: onAddressFetched);

      return locations;
    } catch (e) {
      // Re-throw with more context
      if (e.toString().contains('does not exist') ||
          e.toString().contains('user_locations') ||
          e.toString().contains('PGRST')) {
        throw Exception(
          'Database table "user_locations" not found. Please run migration: 010_create_user_sessions_and_locations.sql',
        );
      }
      throw Exception('Failed to get location history: $e');
    }
  }

  /// Fetch addresses for locations that don't have them and update in database
  /// Processes addresses in parallel batches for better performance
  Future<void> _fetchMissingAddresses(
    List<UserLocation> locations, {
    void Function(UserLocation)? onAddressFetched,
  }) async {
    final locationsNeedingAddress =
        locations
            .where((loc) => loc.address == null || loc.address!.isEmpty)
            .toList();

    if (locationsNeedingAddress.isEmpty) {
      return;
    }

    debugPrint(
      'LocationRepository: Fetching addresses for ${locationsNeedingAddress.length} locations in parallel batches',
    );

    int successCount = 0;
    int failureCount = 0;

    // Process in parallel batches (8 concurrent requests per batch)
    const batchSize = 8;
    const delayBetweenBatches = Duration(milliseconds: 500);

    for (var batchStart = 0;
        batchStart < locationsNeedingAddress.length;
        batchStart += batchSize) {
      final batchEnd = (batchStart + batchSize < locationsNeedingAddress.length)
          ? batchStart + batchSize
          : locationsNeedingAddress.length;
      final batch = locationsNeedingAddress.sublist(batchStart, batchEnd);

      // Process batch in parallel
      final futures = batch.map((location) async {
        try {
          debugPrint(
            'LocationRepository: Fetching address for location ${location.id} '
            'at ${location.latitude}, ${location.longitude}',
          );

          // Get address from coordinates
          final address = await GeocodingService.getAddressFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (address != null && address.isNotEmpty) {
            debugPrint(
              'LocationRepository: Successfully fetched address for location '
              '${location.id}: $address',
            );

            // Update the location in database with the address
            await _supabase
                .from('user_locations')
                .update({'address': address})
                .eq('id', location.id);

            // Create updated location object
            final updatedLocation = UserLocation(
              id: location.id,
              userId: location.userId,
              sessionId: location.sessionId,
              latitude: location.latitude,
              longitude: location.longitude,
              address: address,
              accuracy: location.accuracy,
              capturedAt: location.capturedAt,
            );

            // Find and update in original list
            final index = locations.indexWhere((l) => l.id == location.id);
            if (index != -1) {
              locations[index] = updatedLocation;
            }

            // Notify callback if provided
            if (onAddressFetched != null) {
              onAddressFetched(updatedLocation);
            }

            successCount++;
            return true;
          } else {
            debugPrint(
              'LocationRepository: Failed to get address for location ${location.id}',
            );
            failureCount++;
            return false;
          }
        } catch (e) {
          debugPrint(
            'LocationRepository: Error fetching address for location ${location.id}: $e',
          );
          failureCount++;
          return false;
        }
      });

      // Wait for batch to complete
      await Future.wait(futures);

      // Add delay between batches to respect rate limits
      if (batchEnd < locationsNeedingAddress.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }

    debugPrint(
      'LocationRepository: Address fetching complete. '
      'Success: $successCount, Failed: $failureCount',
    );
  }

  @override
  Stream<List<UserLocation>> subscribeToLocationUpdates(String userId) {
    return _supabase.from('user_locations').stream(primaryKey: ['id']).map((
      data,
    ) {
      final filtered =
          data.where((item) {
            final itemUserId = item['user_id'] as String?;
            return itemUserId == userId;
          }).toList();

      return filtered.map((json) => UserLocation.fromJson(json)).toList();
    });
  }
}

/// User location model
class UserLocation {
  final String id;
  final String userId;
  final String? sessionId;
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;
  final DateTime capturedAt;

  UserLocation({
    required this.id,
    required this.userId,
    this.sessionId,
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    required this.capturedAt,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sessionId: json['session_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      accuracy:
          json['accuracy'] != null
              ? (json['accuracy'] as num).toDouble()
              : null,
      capturedAt: DateTime.parse(json['captured_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'captured_at': capturedAt.toIso8601String(),
    };
  }
}

/// Provider for location repository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LocationRepositorySupabase(supabase);
});
