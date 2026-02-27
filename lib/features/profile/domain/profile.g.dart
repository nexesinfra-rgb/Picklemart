// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String?,
      displayMobile: json['display_mobile'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'user',
      gender: json['gender'] as String?,
      dateOfBirth: const DateTimeConverter().fromJson(json['date_of_birth']),
      email: json['email'] as String?,
      gstNumber: json['gst_number'] as String?,
      priceVisibilityEnabled: json['price_visibility_enabled'] as bool? ?? true,
      createdAt: const DateTimeConverter().fromJson(json['created_at']),
      updatedAt: const DateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'mobile': instance.mobile,
      'display_mobile': instance.displayMobile,
      'avatar_url': instance.avatarUrl,
      'role': instance.role,
      'gender': instance.gender,
      'date_of_birth': const DateTimeConverter().toJson(instance.dateOfBirth),
      'email': instance.email,
      'gst_number': instance.gstNumber,
      'price_visibility_enabled': instance.priceVisibilityEnabled,
      'created_at': const DateTimeConverter().toJson(instance.createdAt),
      'updated_at': const DateTimeConverter().toJson(instance.updatedAt),
    };
