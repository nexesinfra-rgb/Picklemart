// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  return _Profile.fromJson(json);
}

/// @nodoc
mixin _$Profile {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get mobile => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_mobile')
  String? get displayMobile => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_of_birth')
  @DateTimeConverter()
  DateTime? get dateOfBirth => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'gst_number')
  String? get gstNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_visibility_enabled')
  bool get priceVisibilityEnabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  @DateTimeConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  @DateTimeConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;
  @useResult
  $Res call({
    String id,
    String name,
    String? mobile,
    @JsonKey(name: 'display_mobile') String? displayMobile,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String role,
    String? gender,
    @JsonKey(name: 'date_of_birth') @DateTimeConverter() DateTime? dateOfBirth,
    String? email,
    @JsonKey(name: 'gst_number') String? gstNumber,
    @JsonKey(name: 'price_visibility_enabled') bool priceVisibilityEnabled,
    @JsonKey(name: 'created_at') @DateTimeConverter() DateTime? createdAt,
    @JsonKey(name: 'updated_at') @DateTimeConverter() DateTime? updatedAt,
  });
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? mobile = freezed,
    Object? displayMobile = freezed,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? gender = freezed,
    Object? dateOfBirth = freezed,
    Object? email = freezed,
    Object? gstNumber = freezed,
    Object? priceVisibilityEnabled = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            mobile:
                freezed == mobile
                    ? _value.mobile
                    : mobile // ignore: cast_nullable_to_non_nullable
                        as String?,
            displayMobile:
                freezed == displayMobile
                    ? _value.displayMobile
                    : displayMobile // ignore: cast_nullable_to_non_nullable
                        as String?,
            avatarUrl:
                freezed == avatarUrl
                    ? _value.avatarUrl
                    : avatarUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
            role:
                null == role
                    ? _value.role
                    : role // ignore: cast_nullable_to_non_nullable
                        as String,
            gender:
                freezed == gender
                    ? _value.gender
                    : gender // ignore: cast_nullable_to_non_nullable
                        as String?,
            dateOfBirth:
                freezed == dateOfBirth
                    ? _value.dateOfBirth
                    : dateOfBirth // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            email:
                freezed == email
                    ? _value.email
                    : email // ignore: cast_nullable_to_non_nullable
                        as String?,
            gstNumber:
                freezed == gstNumber
                    ? _value.gstNumber
                    : gstNumber // ignore: cast_nullable_to_non_nullable
                        as String?,
            priceVisibilityEnabled:
                null == priceVisibilityEnabled
                    ? _value.priceVisibilityEnabled
                    : priceVisibilityEnabled // ignore: cast_nullable_to_non_nullable
                        as bool,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProfileImplCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$ProfileImplCopyWith(
    _$ProfileImpl value,
    $Res Function(_$ProfileImpl) then,
  ) = __$$ProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? mobile,
    @JsonKey(name: 'display_mobile') String? displayMobile,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String role,
    String? gender,
    @JsonKey(name: 'date_of_birth') @DateTimeConverter() DateTime? dateOfBirth,
    String? email,
    @JsonKey(name: 'gst_number') String? gstNumber,
    @JsonKey(name: 'price_visibility_enabled') bool priceVisibilityEnabled,
    @JsonKey(name: 'created_at') @DateTimeConverter() DateTime? createdAt,
    @JsonKey(name: 'updated_at') @DateTimeConverter() DateTime? updatedAt,
  });
}

/// @nodoc
class __$$ProfileImplCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$ProfileImpl>
    implements _$$ProfileImplCopyWith<$Res> {
  __$$ProfileImplCopyWithImpl(
    _$ProfileImpl _value,
    $Res Function(_$ProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? mobile = freezed,
    Object? displayMobile = freezed,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? gender = freezed,
    Object? dateOfBirth = freezed,
    Object? email = freezed,
    Object? gstNumber = freezed,
    Object? priceVisibilityEnabled = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$ProfileImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        mobile:
            freezed == mobile
                ? _value.mobile
                : mobile // ignore: cast_nullable_to_non_nullable
                    as String?,
        displayMobile:
            freezed == displayMobile
                ? _value.displayMobile
                : displayMobile // ignore: cast_nullable_to_non_nullable
                    as String?,
        avatarUrl:
            freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
        role:
            null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                    as String,
        gender:
            freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                    as String?,
        dateOfBirth:
            freezed == dateOfBirth
                ? _value.dateOfBirth
                : dateOfBirth // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        email:
            freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                    as String?,
        gstNumber:
            freezed == gstNumber
                ? _value.gstNumber
                : gstNumber // ignore: cast_nullable_to_non_nullable
                    as String?,
        priceVisibilityEnabled:
            null == priceVisibilityEnabled
                ? _value.priceVisibilityEnabled
                : priceVisibilityEnabled // ignore: cast_nullable_to_non_nullable
                    as bool,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileImpl implements _Profile {
  const _$ProfileImpl({
    required this.id,
    required this.name,
    this.mobile,
    @JsonKey(name: 'display_mobile') this.displayMobile,
    @JsonKey(name: 'avatar_url') this.avatarUrl,
    this.role = 'user',
    this.gender,
    @JsonKey(name: 'date_of_birth') @DateTimeConverter() this.dateOfBirth,
    this.email,
    @JsonKey(name: 'gst_number') this.gstNumber,
    @JsonKey(name: 'price_visibility_enabled')
    this.priceVisibilityEnabled = true,
    @JsonKey(name: 'created_at') @DateTimeConverter() this.createdAt,
    @JsonKey(name: 'updated_at') @DateTimeConverter() this.updatedAt,
  });

  factory _$ProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? mobile;
  @override
  @JsonKey(name: 'display_mobile')
  final String? displayMobile;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey()
  final String role;
  @override
  final String? gender;
  @override
  @JsonKey(name: 'date_of_birth')
  @DateTimeConverter()
  final DateTime? dateOfBirth;
  @override
  final String? email;
  @override
  @JsonKey(name: 'gst_number')
  final String? gstNumber;
  @override
  @JsonKey(name: 'price_visibility_enabled')
  final bool priceVisibilityEnabled;
  @override
  @JsonKey(name: 'created_at')
  @DateTimeConverter()
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  @DateTimeConverter()
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Profile(id: $id, name: $name, mobile: $mobile, displayMobile: $displayMobile, avatarUrl: $avatarUrl, role: $role, gender: $gender, dateOfBirth: $dateOfBirth, email: $email, gstNumber: $gstNumber, priceVisibilityEnabled: $priceVisibilityEnabled, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.mobile, mobile) || other.mobile == mobile) &&
            (identical(other.displayMobile, displayMobile) ||
                other.displayMobile == displayMobile) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.gstNumber, gstNumber) ||
                other.gstNumber == gstNumber) &&
            (identical(other.priceVisibilityEnabled, priceVisibilityEnabled) ||
                other.priceVisibilityEnabled == priceVisibilityEnabled) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    mobile,
    displayMobile,
    avatarUrl,
    role,
    gender,
    dateOfBirth,
    email,
    gstNumber,
    priceVisibilityEnabled,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      __$$ProfileImplCopyWithImpl<_$ProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileImplToJson(this);
  }
}

abstract class _Profile implements Profile {
  const factory _Profile({
    required final String id,
    required final String name,
    final String? mobile,
    @JsonKey(name: 'display_mobile') final String? displayMobile,
    @JsonKey(name: 'avatar_url') final String? avatarUrl,
    final String role,
    final String? gender,
    @JsonKey(name: 'date_of_birth')
    @DateTimeConverter()
    final DateTime? dateOfBirth,
    final String? email,
    @JsonKey(name: 'gst_number') final String? gstNumber,
    @JsonKey(name: 'price_visibility_enabled')
    final bool priceVisibilityEnabled,
    @JsonKey(name: 'created_at') @DateTimeConverter() final DateTime? createdAt,
    @JsonKey(name: 'updated_at') @DateTimeConverter() final DateTime? updatedAt,
  }) = _$ProfileImpl;

  factory _Profile.fromJson(Map<String, dynamic> json) = _$ProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get mobile;
  @override
  @JsonKey(name: 'display_mobile')
  String? get displayMobile;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  String get role;
  @override
  String? get gender;
  @override
  @JsonKey(name: 'date_of_birth')
  @DateTimeConverter()
  DateTime? get dateOfBirth;
  @override
  String? get email;
  @override
  @JsonKey(name: 'gst_number')
  String? get gstNumber;
  @override
  @JsonKey(name: 'price_visibility_enabled')
  bool get priceVisibilityEnabled;
  @override
  @JsonKey(name: 'created_at')
  @DateTimeConverter()
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  @DateTimeConverter()
  DateTime? get updatedAt;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
