// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_book_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CashBookEntryImpl _$$CashBookEntryImplFromJson(Map<String, dynamic> json) =>
    _$CashBookEntryImpl(
      id: json['id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: $enumDecode(_$CashBookEntryTypeEnumMap, json['entry_type']),
      category: json['category'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['transaction_date'] as String),
      relatedId: json['related_id'] as String?,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      linkId: json['link_id'] as String?,
      paymentMethod: json['payment_method'] as String,
      createdBy: json['created_by'] as String,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$CashBookEntryImplToJson(_$CashBookEntryImpl instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      'amount': instance.amount,
      'entry_type': _$CashBookEntryTypeEnumMap[instance.type]!,
      'category': instance.category,
      'description': instance.description,
      'transaction_date': instance.date.toIso8601String(),
      'related_id': instance.relatedId,
      'reference_id': instance.referenceId,
      'reference_type': instance.referenceType,
      if (instance.linkId case final value?) 'link_id': value,
      'payment_method': instance.paymentMethod,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$CashBookEntryTypeEnumMap = {
  CashBookEntryType.payin: 'payin',
  CashBookEntryType.payout: 'payout',
};
