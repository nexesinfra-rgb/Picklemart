import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'address_repository.dart';

/// Supabase address repository for managing addresses in the database
class AddressRepositorySupabase implements AddressRepository {
  final SupabaseClient _supabase;

  AddressRepositorySupabase(this._supabase);

  /// Fetch all addresses for a user
  @override
  Future<List<Address>> fetchAddresses(String userId) async {
    try {
      final response = await _supabase
          .from('addresses')
          .select('*')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      final addressesData = List<Map<String, dynamic>>.from(response);
      return addressesData.map((data) => _convertSupabaseToAddress(data)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchAddresses: $e');
      }
      rethrow;
    }
  }

  /// Create a new address
  @override
  Future<Address> createAddress(Address address, String userId) async {
    try {
      // If this address is set as default, unset other default addresses
      if (address.isDefault) {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true);
      }

      final addressData = await _convertAddressToSupabase(address, userId);
      
      final response = await _supabase
          .from('addresses')
          .insert(addressData)
          .select()
          .single();

      return _convertSupabaseToAddress(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in createAddress: $e');
      }
      rethrow;
    }
  }

  /// Update an existing address
  @override
  Future<Address> updateAddress(Address address, String userId) async {
    try {
      // If this address is set as default, unset other default addresses
      if (address.isDefault) {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true)
            .neq('id', address.id);
      }

      final addressData = await _convertAddressToSupabase(address, userId);
      
      final response = await _supabase
          .from('addresses')
          .update(addressData)
          .eq('id', address.id)
          .eq('user_id', userId)
          .select()
          .single();

      return _convertSupabaseToAddress(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateAddress: $e');
      }
      rethrow;
    }
  }

  /// Delete an address
  @override
  Future<void> deleteAddress(String addressId, String userId) async {
    try {
      await _supabase
          .from('addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteAddress: $e');
      }
      rethrow;
    }
  }

  /// Subscribe to real-time address changes for a user
  @override
  Stream<List<Address>> subscribeToAddressChanges(String userId) {
    final controller = StreamController<List<Address>>();

    // Initial fetch
    fetchAddresses(userId).then((addresses) {
      if (!controller.isClosed) {
        controller.add(addresses);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Subscribe to real-time changes
    final subscription = _supabase
        .from('addresses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
      (data) async {
        try {
          final addresses = data.map((item) => _convertSupabaseToAddress(item)).toList();
          if (!controller.isClosed) {
            controller.add(addresses);
          }
        } catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Cancel subscription when stream is closed
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Convert Supabase address data to Address object
  Address _convertSupabaseToAddress(Map<String, dynamic> data) {
    // Parse coordinates (PostGIS POINT or JSON format)
    LatLng? coordinates;
    if (data['coordinates'] != null) {
      try {
        // Handle PostGIS POINT format: {"x": lon, "y": lat} or [lon, lat]
        final coords = data['coordinates'];
        if (coords is Map) {
          // PostGIS POINT format: {"x": longitude, "y": latitude}
          final lon = coords['x'] as num?;
          final lat = coords['y'] as num?;
          if (lon != null && lat != null) {
            coordinates = LatLng(lat.toDouble(), lon.toDouble());
          }
        } else if (coords is List && coords.length >= 2) {
          // Array format: [longitude, latitude]
          final lon = coords[0] as num?;
          final lat = coords[1] as num?;
          if (lon != null && lat != null) {
            coordinates = LatLng(lat.toDouble(), lon.toDouble());
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing coordinates: $e');
        }
      }
    }

    return Address(
      id: data['id'] as String,
      name: data['name'] as String,
      phone: data['phone'] as String,
      address: data['address'] as String,
      city: data['city'] as String,
      state: data['state'] as String,
      pincode: data['pincode'] as String,
      coordinates: coordinates,
      notes: data['notes'] as String?,
      isDefault: data['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  /// Convert Address object to Supabase row format
  Future<Map<String, dynamic>> _convertAddressToSupabase(Address address, String userId) async {
    final addressData = <String, dynamic>{
      'user_id': userId,
      'name': address.name,
      'phone': address.phone,
      'address': address.address,
      'city': address.city,
      'state': address.state,
      'pincode': address.pincode,
      'notes': address.notes,
      'is_default': address.isDefault,
    };

    // Convert coordinates to PostGIS POINT format
    if (address.coordinates != null) {
      // PostGIS POINT format: POINT(longitude latitude)
      // Or use JSONB: {"x": longitude, "y": latitude}
      // For simplicity, we'll store as JSONB
      addressData['coordinates'] = {
        'x': address.coordinates!.longitude,
        'y': address.coordinates!.latitude,
      };
    }

    return addressData;
  }
}







