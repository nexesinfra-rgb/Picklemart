import 'dart:async';
import 'package:latlong2/latlong.dart';

/// Repository interface for address operations
abstract class AddressRepository {
  /// Fetch all addresses for a user
  Future<List<Address>> fetchAddresses(String userId);

  /// Create a new address
  Future<Address> createAddress(Address address, String userId);

  /// Update an existing address
  Future<Address> updateAddress(Address address, String userId);

  /// Delete an address
  Future<void> deleteAddress(String addressId, String userId);

  /// Subscribe to real-time address changes for a user
  Stream<List<Address>> subscribeToAddressChanges(String userId);
}

class Address {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final LatLng? coordinates;
  final String? notes;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.coordinates,
    this.notes,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Address copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    LatLng? coordinates,
    String? notes,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      coordinates: coordinates ?? this.coordinates,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullAddress => '$address, $city, $state $pincode';
}
