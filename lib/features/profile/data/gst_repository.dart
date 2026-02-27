import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GstDetails {
  final String id;
  final String userId;
  final String gstNumber;
  final String businessName;
  final String businessAddress;
  final String city;
  final String state;
  final String pincode;
  final String? email;
  final String? phone;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GstDetails({
    required this.id,
    required this.userId,
    required this.gstNumber,
    required this.businessName,
    required this.businessAddress,
    required this.city,
    required this.state,
    required this.pincode,
    this.email,
    this.phone,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GstDetails.fromJson(Map<String, dynamic> json) {
    return GstDetails(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gstNumber: json['gst_number'] as String,
      businessName: json['business_name'] as String,
      businessAddress: json['business_address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      pincode: json['pincode'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'gst_number': gstNumber,
      'business_name': businessName,
      'business_address': businessAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'email': email,
      'phone': phone,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GstDetails copyWith({
    String? id,
    String? userId,
    String? gstNumber,
    String? businessName,
    String? businessAddress,
    String? city,
    String? state,
    String? pincode,
    String? email,
    String? phone,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GstDetails(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gstNumber: gstNumber ?? this.gstNumber,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullAddress => '$businessAddress, $city, $state $pincode';

  String get formattedGstNumber {
    // Format: 22AAAAA0000A1Z5
    if (gstNumber.length == 15) {
      return '${gstNumber.substring(0, 2)}-${gstNumber.substring(2, 7)}-${gstNumber.substring(7, 11)}-${gstNumber.substring(11, 12)}-${gstNumber.substring(12, 14)}-${gstNumber.substring(14)}';
    }
    return gstNumber;
  }
}

class GstRepository {
  final SupabaseClient _supabase;

  GstRepository(this._supabase);

  Future<List<GstDetails>> getGstDetails() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('gst_records')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((json) => GstDetails.fromJson(json)).toList();
    } catch (e) {
      // Return empty list if table doesn't exist or other error
      // This allows graceful degradation while migrations are pending
      return [];
    }
  }

  Future<GstDetails> addGstDetails(GstDetails gst) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // If setting as default, unset other defaults first
    if (gst.isDefault) {
      await _supabase
          .from('gst_records')
          .update({'is_default': false})
          .eq('user_id', userId);
    }

    final data = {
      'user_id': userId,
      'gst_number': gst.gstNumber,
      'business_name': gst.businessName,
      'business_address': gst.businessAddress,
      'city': gst.city,
      'state': gst.state,
      'pincode': gst.pincode,
      'email': gst.email,
      'phone': gst.phone,
      'is_default': gst.isDefault,
    };

    final response = await _supabase
        .from('gst_records')
        .insert(data)
        .select()
        .single();

    return GstDetails.fromJson(response);
  }

  Future<GstDetails> updateGstDetails(GstDetails gst) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // If setting as default, unset other defaults first
    if (gst.isDefault) {
      await _supabase
          .from('gst_records')
          .update({'is_default': false})
          .eq('user_id', userId)
          .neq('id', gst.id);
    }

    final data = {
      'gst_number': gst.gstNumber,
      'business_name': gst.businessName,
      'business_address': gst.businessAddress,
      'city': gst.city,
      'state': gst.state,
      'pincode': gst.pincode,
      'email': gst.email,
      'phone': gst.phone,
      'is_default': gst.isDefault,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('gst_records')
        .update(data)
        .eq('id', gst.id)
        .select()
        .single();

    return GstDetails.fromJson(response);
  }

  Future<void> deleteGstDetails(String id) async {
    await _supabase.from('gst_records').delete().eq('id', id);
  }

  Future<void> setDefaultGst(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Unset all defaults
    await _supabase
        .from('gst_records')
        .update({'is_default': false})
        .eq('user_id', userId);

    // Set new default
    await _supabase
        .from('gst_records')
        .update({'is_default': true})
        .eq('id', id);
  }
}

final gstRepositoryProvider = Provider<GstRepository>((ref) {
  return GstRepository(Supabase.instance.client);
});

final savedGstDetailsProvider = FutureProvider<List<GstDetails>>((ref) async {
  final repository = ref.watch(gstRepositoryProvider);
  return repository.getGstDetails();
});
