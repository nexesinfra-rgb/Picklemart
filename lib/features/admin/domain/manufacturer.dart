class Manufacturer {
  final String id;
  final String name;
  final String gstNumber;
  final String businessName;
  final String businessAddress;
  final String city;
  final String state;
  final String pincode;
  final String? email;
  final String? phone;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Manufacturer({
    required this.id,
    required this.name,
    required this.gstNumber,
    required this.businessName,
    required this.businessAddress,
    required this.city,
    required this.state,
    required this.pincode,
    this.email,
    this.phone,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for creating from Supabase JSON
  factory Manufacturer.fromSupabaseJson(Map<String, dynamic> json) {
    return Manufacturer(
      id: json['id'] as String,
      name: json['name'] as String,
      gstNumber: json['gst_number'] as String,
      businessName: json['business_name'] as String,
      businessAddress: json['business_address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convert to JSON for Supabase operations
  Map<String, dynamic> toSupabaseJson() {
    return {
      'name': name,
      'gst_number': gstNumber,
      'business_name': businessName,
      'business_address': businessAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'email': email,
      'phone': phone,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Copy with method for immutable updates
  Manufacturer copyWith({
    String? id,
    String? name,
    String? gstNumber,
    String? businessName,
    String? businessAddress,
    String? city,
    String? state,
    String? pincode,
    String? email,
    String? phone,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Manufacturer(
      id: id ?? this.id,
      name: name ?? this.name,
      gstNumber: gstNumber ?? this.gstNumber,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get full address
  String get fullAddress => '$businessAddress, $city, $state $pincode';

  // Helper method to format GST number
  String get formattedGstNumber {
    // Format: 22AAAAA0000A1Z5
    if (gstNumber.length == 15) {
      return '${gstNumber.substring(0, 2)}-${gstNumber.substring(2, 7)}-${gstNumber.substring(7, 11)}-${gstNumber.substring(11, 12)}-${gstNumber.substring(12, 14)}-${gstNumber.substring(14)}';
    }
    return gstNumber;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Manufacturer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Manufacturer(id: $id, name: $name, gstNumber: $gstNumber, businessName: $businessName)';
  }
}

