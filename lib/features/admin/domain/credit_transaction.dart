enum CreditTransactionType {
  payin, // Admin pays manufacturer
  payout, // Manufacturer pays admin
  purchase; // Admin buys from manufacturer

  String get displayName {
    switch (this) {
      case CreditTransactionType.payin:
        return 'Payin';
      case CreditTransactionType.payout:
        return 'Payout';
      case CreditTransactionType.purchase:
        return 'Purchase';
    }
  }

  static CreditTransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'payin':
        return CreditTransactionType.payin;
      case 'payout':
        return CreditTransactionType.payout;
      case 'purchase':
        return CreditTransactionType.purchase;
      default:
        throw ArgumentError('Invalid transaction type: $value');
    }
  }
}

enum PaymentMethod {
  cash,
  bankTransfer,
  cheque,
  upi,
  other;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  // Convert to database format (snake_case)
  String toDatabaseValue() {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.cheque:
        return 'cheque';
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.other:
        return 'other';
    }
  }

  static PaymentMethod? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'upi':
        return PaymentMethod.upi;
      case 'other':
        return PaymentMethod.other;
      default:
        return null;
    }
  }
}

class CreditTransaction {
  final String id;
  final String? manufacturerId; // Nullable - can be null for personal expenses
  final String? manufacturerName; // For display purposes (legacy)
  final String? entityName; // Name of entity (manufacturer name or personal expense category)
  final CreditTransactionType transactionType;
  final double amount;
  final double balanceAfter;
  final String? description;
  final String? referenceNumber;
  final PaymentMethod? paymentMethod;
  final DateTime transactionDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CreditTransaction({
    required this.id,
    this.manufacturerId,
    this.manufacturerName,
    this.entityName,
    required this.transactionType,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.referenceNumber,
    this.paymentMethod,
    required this.transactionDate,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  // Get display name - entity name if available, otherwise manufacturer name
  String get displayName {
    return entityName ?? manufacturerName ?? 'Unknown';
  }

  factory CreditTransaction.fromSupabaseJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] as String,
      manufacturerId: json['manufacturer_id'] as String?,
      manufacturerName: json['manufacturer_name'] as String?,
      entityName: json['entity_name'] as String?,
      transactionType: CreditTransactionType.fromString(
        json['transaction_type'] as String,
      ),
      amount: (json['amount'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      description: json['description'] as String?,
      referenceNumber: json['reference_number'] as String?,
      paymentMethod: PaymentMethod.fromString(
        json['payment_method'] as String?,
      ),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      if (manufacturerId != null) 'manufacturer_id': manufacturerId,
      if (entityName != null) 'entity_name': entityName,
      'transaction_type': transactionType.name,
      'amount': amount,
      'balance_after': balanceAfter,
      'description': description,
      'reference_number': referenceNumber,
      'payment_method': paymentMethod?.toDatabaseValue(),
      'transaction_date': transactionDate.toIso8601String(),
      'created_by': createdBy,
    };
  }

  CreditTransaction copyWith({
    String? id,
    String? manufacturerId,
    String? manufacturerName,
    String? entityName,
    CreditTransactionType? transactionType,
    double? amount,
    double? balanceAfter,
    String? description,
    String? referenceNumber,
    PaymentMethod? paymentMethod,
    DateTime? transactionDate,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditTransaction(
      id: id ?? this.id,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      entityName: entityName ?? this.entityName,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      description: description ?? this.description,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ManufacturerCreditBalance {
  final String? manufacturerId; // Nullable for personal expenses
  final String entityName; // Name of entity (manufacturer or personal expense)
  final double currentBalance; // Negative = admin owes, Positive = entity owes
  final double totalPayin;
  final double totalPayout;
  final int transactionCount;
  final DateTime? lastTransactionDate;

  const ManufacturerCreditBalance({
    this.manufacturerId,
    required this.entityName,
    required this.currentBalance,
    required this.totalPayin,
    required this.totalPayout,
    required this.transactionCount,
    this.lastTransactionDate,
  });

  String get balanceDisplay {
    if (currentBalance == 0) return '₹0.00 (Settled)';
    if (currentBalance < 0) {
      return '₹${currentBalance.abs().toStringAsFixed(2)} (Admin Owes)';
    }
    return '₹${currentBalance.toStringAsFixed(2)} (Owes)';
  }
}

