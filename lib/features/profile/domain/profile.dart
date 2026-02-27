import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// Custom JSON converter for DateTime that handles both String and DateTime
class DateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const DateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is DateTime) return json;
    if (json is String) return DateTime.parse(json);
    try {
      return DateTime.parse(json.toString());
    } catch (e) {
      return null;
    }
  }

  @override
  dynamic toJson(DateTime? object) => object?.toIso8601String();
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String name,
    String? mobile,
    @JsonKey(name: 'display_mobile') String? displayMobile,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @Default('user') String role,
    String? gender,
    @JsonKey(name: 'date_of_birth') @DateTimeConverter() DateTime? dateOfBirth,
    String? email,
    @JsonKey(name: 'gst_number') String? gstNumber,
    @JsonKey(name: 'price_visibility_enabled') @Default(true) bool priceVisibilityEnabled,
    @JsonKey(name: 'created_at') @DateTimeConverter() DateTime? createdAt,
    @JsonKey(name: 'updated_at') @DateTimeConverter() DateTime? updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}

extension ProfileExtension on Profile {
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  String get displayName => name.isNotEmpty ? name : 'User';

  String? get formattedMobile {
    if (displayMobile != null && displayMobile!.isNotEmpty) {
      return displayMobile;
    }
    return mobile;
  }

  Profile copyWithUpdatedAt() {
    return copyWith(updatedAt: DateTime.now());
  }
}
