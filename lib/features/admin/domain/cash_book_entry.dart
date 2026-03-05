import 'package:freezed_annotation/freezed_annotation.dart';

part 'cash_book_entry.freezed.dart';
part 'cash_book_entry.g.dart';

enum CashBookEntryType {
  payin,
  payout,
}

@freezed
class CashBookEntry with _$CashBookEntry {
  const factory CashBookEntry({
    @JsonKey(includeIfNull: false) String? id,
    required double amount,
    @JsonKey(name: 'entry_type') required CashBookEntryType type,
    required String category,
    required String description,
    @JsonKey(name: 'transaction_date') required DateTime date,
    @JsonKey(name: 'related_id') String? relatedId,
    @JsonKey(name: 'reference_id') String? referenceId,
    @JsonKey(name: 'reference_type') String? referenceType,
    @JsonKey(name: 'link_id', includeIfNull: false) String? linkId,  // ID from payment_cashbook_links table
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _CashBookEntry;

  factory CashBookEntry.fromJson(Map<String, dynamic> json) =>
      _$CashBookEntryFromJson(json);
}
