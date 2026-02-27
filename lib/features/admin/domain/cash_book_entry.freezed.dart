// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_book_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CashBookEntry _$CashBookEntryFromJson(Map<String, dynamic> json) {
  return _CashBookEntry.fromJson(json);
}

/// @nodoc
mixin _$CashBookEntry {
  @JsonKey(includeIfNull: false)
  String? get id => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  @JsonKey(name: 'entry_type')
  CashBookEntryType get type => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'transaction_date')
  DateTime get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'related_id')
  String? get relatedId => throw _privateConstructorUsedError;
  @JsonKey(name: 'payment_method')
  String get paymentMethod => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CashBookEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CashBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CashBookEntryCopyWith<CashBookEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CashBookEntryCopyWith<$Res> {
  factory $CashBookEntryCopyWith(
    CashBookEntry value,
    $Res Function(CashBookEntry) then,
  ) = _$CashBookEntryCopyWithImpl<$Res, CashBookEntry>;
  @useResult
  $Res call({
    @JsonKey(includeIfNull: false) String? id,
    double amount,
    @JsonKey(name: 'entry_type') CashBookEntryType type,
    String category,
    String description,
    @JsonKey(name: 'transaction_date') DateTime date,
    @JsonKey(name: 'related_id') String? relatedId,
    @JsonKey(name: 'payment_method') String paymentMethod,
    @JsonKey(name: 'created_by') String createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$CashBookEntryCopyWithImpl<$Res, $Val extends CashBookEntry>
    implements $CashBookEntryCopyWith<$Res> {
  _$CashBookEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CashBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? amount = null,
    Object? type = null,
    Object? category = null,
    Object? description = null,
    Object? date = null,
    Object? relatedId = freezed,
    Object? paymentMethod = null,
    Object? createdBy = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                freezed == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String?,
            amount:
                null == amount
                    ? _value.amount
                    : amount // ignore: cast_nullable_to_non_nullable
                        as double,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as CashBookEntryType,
            category:
                null == category
                    ? _value.category
                    : category // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            date:
                null == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            relatedId:
                freezed == relatedId
                    ? _value.relatedId
                    : relatedId // ignore: cast_nullable_to_non_nullable
                        as String?,
            paymentMethod:
                null == paymentMethod
                    ? _value.paymentMethod
                    : paymentMethod // ignore: cast_nullable_to_non_nullable
                        as String,
            createdBy:
                null == createdBy
                    ? _value.createdBy
                    : createdBy // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CashBookEntryImplCopyWith<$Res>
    implements $CashBookEntryCopyWith<$Res> {
  factory _$$CashBookEntryImplCopyWith(
    _$CashBookEntryImpl value,
    $Res Function(_$CashBookEntryImpl) then,
  ) = __$$CashBookEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(includeIfNull: false) String? id,
    double amount,
    @JsonKey(name: 'entry_type') CashBookEntryType type,
    String category,
    String description,
    @JsonKey(name: 'transaction_date') DateTime date,
    @JsonKey(name: 'related_id') String? relatedId,
    @JsonKey(name: 'payment_method') String paymentMethod,
    @JsonKey(name: 'created_by') String createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$CashBookEntryImplCopyWithImpl<$Res>
    extends _$CashBookEntryCopyWithImpl<$Res, _$CashBookEntryImpl>
    implements _$$CashBookEntryImplCopyWith<$Res> {
  __$$CashBookEntryImplCopyWithImpl(
    _$CashBookEntryImpl _value,
    $Res Function(_$CashBookEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CashBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? amount = null,
    Object? type = null,
    Object? category = null,
    Object? description = null,
    Object? date = null,
    Object? relatedId = freezed,
    Object? paymentMethod = null,
    Object? createdBy = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$CashBookEntryImpl(
        id:
            freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String?,
        amount:
            null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                    as double,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as CashBookEntryType,
        category:
            null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        date:
            null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        relatedId:
            freezed == relatedId
                ? _value.relatedId
                : relatedId // ignore: cast_nullable_to_non_nullable
                    as String?,
        paymentMethod:
            null == paymentMethod
                ? _value.paymentMethod
                : paymentMethod // ignore: cast_nullable_to_non_nullable
                    as String,
        createdBy:
            null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CashBookEntryImpl implements _CashBookEntry {
  const _$CashBookEntryImpl({
    @JsonKey(includeIfNull: false) this.id,
    required this.amount,
    @JsonKey(name: 'entry_type') required this.type,
    required this.category,
    required this.description,
    @JsonKey(name: 'transaction_date') required this.date,
    @JsonKey(name: 'related_id') this.relatedId,
    @JsonKey(name: 'payment_method') required this.paymentMethod,
    @JsonKey(name: 'created_by') required this.createdBy,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$CashBookEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CashBookEntryImplFromJson(json);

  @override
  @JsonKey(includeIfNull: false)
  final String? id;
  @override
  final double amount;
  @override
  @JsonKey(name: 'entry_type')
  final CashBookEntryType type;
  @override
  final String category;
  @override
  final String description;
  @override
  @JsonKey(name: 'transaction_date')
  final DateTime date;
  @override
  @JsonKey(name: 'related_id')
  final String? relatedId;
  @override
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @override
  @JsonKey(name: 'created_by')
  final String createdBy;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'CashBookEntry(id: $id, amount: $amount, type: $type, category: $category, description: $description, date: $date, relatedId: $relatedId, paymentMethod: $paymentMethod, createdBy: $createdBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CashBookEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.relatedId, relatedId) ||
                other.relatedId == relatedId) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    amount,
    type,
    category,
    description,
    date,
    relatedId,
    paymentMethod,
    createdBy,
    createdAt,
  );

  /// Create a copy of CashBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CashBookEntryImplCopyWith<_$CashBookEntryImpl> get copyWith =>
      __$$CashBookEntryImplCopyWithImpl<_$CashBookEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CashBookEntryImplToJson(this);
  }
}

abstract class _CashBookEntry implements CashBookEntry {
  const factory _CashBookEntry({
    @JsonKey(includeIfNull: false) final String? id,
    required final double amount,
    @JsonKey(name: 'entry_type') required final CashBookEntryType type,
    required final String category,
    required final String description,
    @JsonKey(name: 'transaction_date') required final DateTime date,
    @JsonKey(name: 'related_id') final String? relatedId,
    @JsonKey(name: 'payment_method') required final String paymentMethod,
    @JsonKey(name: 'created_by') required final String createdBy,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$CashBookEntryImpl;

  factory _CashBookEntry.fromJson(Map<String, dynamic> json) =
      _$CashBookEntryImpl.fromJson;

  @override
  @JsonKey(includeIfNull: false)
  String? get id;
  @override
  double get amount;
  @override
  @JsonKey(name: 'entry_type')
  CashBookEntryType get type;
  @override
  String get category;
  @override
  String get description;
  @override
  @JsonKey(name: 'transaction_date')
  DateTime get date;
  @override
  @JsonKey(name: 'related_id')
  String? get relatedId;
  @override
  @JsonKey(name: 'payment_method')
  String get paymentMethod;
  @override
  @JsonKey(name: 'created_by')
  String get createdBy;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of CashBookEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CashBookEntryImplCopyWith<_$CashBookEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
