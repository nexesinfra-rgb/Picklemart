import 'package:freezed_annotation/freezed_annotation.dart';

part 'store_details.freezed.dart';
part 'store_details.g.dart';

@freezed
class StoreDetails with _$StoreDetails {
  const factory StoreDetails({
    required String id,
    required String name,
    String? address,
    String? phone,
    String? email,
    @JsonKey(name: 'gst_number') String? gstNumber,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _StoreDetails;

  factory StoreDetails.fromJson(Map<String, dynamic> json) =>
      _$StoreDetailsFromJson(json);
}
