/// Bill model and related classes for billing system
library;

enum BillType {
  user,
  manufacturer;

  String get displayName {
    switch (this) {
      case BillType.user:
        return 'Store Bill';
      case BillType.manufacturer:
        return 'Manufacturer Bill';
    }
  }
}

class BillItem {
  final String productId;
  final String productName;
  final String? sku;
  final String? imageUrl;
  final int quantity;
  final double unitPrice; // Selling price for store bills, cost price for manufacturer bills
  final double totalPrice;
  final Map<String, String>? variantAttributes;
  final String? measurementUnit;
  final String? category;

  const BillItem({
    required this.productId,
    required this.productName,
    this.sku,
    this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.variantAttributes,
    this.measurementUnit,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'sku': sku,
      'image_url': imageUrl,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'variant_attributes': variantAttributes,
      'measurement_unit': measurementUnit,
      'category': category,
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      sku: json['sku'] as String?,
      imageUrl: json['image_url'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      variantAttributes: json['variant_attributes'] != null
          ? Map<String, String>.from(json['variant_attributes'] as Map)
          : null,
      measurementUnit: json['measurement_unit'] as String?,
      category: json['category'] as String?,
    );
  }
}

class BillData {
  final List<BillItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final double oldDue;
  final double receivedAmount;
  final Map<String, dynamic> customerInfo;
  final Map<String, dynamic>? orderInfo;
  final Map<String, dynamic>? companyInfo;
  final Map<String, dynamic>? manufacturerInfo; // Manufacturer GST and business details

  const BillData({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    this.oldDue = 0.0,
    this.receivedAmount = 0.0,
    required this.customerInfo,
    this.orderInfo,
    this.companyInfo,
    this.manufacturerInfo,
  });

  /// Get the correct total (recalculated to ensure accuracy)
  /// This handles cases where old bills might have incorrect totals stored
  double get correctTotal {
    // Recalculate: subtotal + shipping + tax
    return subtotal + shipping + tax;
  }

  /// Calculate balance due (total + oldDue - receivedAmount)
  double get balanceDue {
    // Use correctTotal to ensure accuracy
    return (correctTotal + oldDue) - receivedAmount;
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'total': total,
      'old_due': oldDue,
      'received_amount': receivedAmount,
      'customer_info': customerInfo,
      'order_info': orderInfo,
      'company_info': companyInfo,
      'manufacturer_info': manufacturerInfo,
    };
  }

  factory BillData.fromJson(Map<String, dynamic> json) {
    return BillData(
      items: (json['items'] as List)
          .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      shipping: (json['shipping'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      oldDue: (json['old_due'] as num?)?.toDouble() ?? 0.0,
      receivedAmount: (json['received_amount'] as num?)?.toDouble() ?? 0.0,
      customerInfo: Map<String, dynamic>.from(json['customer_info'] as Map),
      orderInfo: json['order_info'] != null
          ? Map<String, dynamic>.from(json['order_info'] as Map)
          : null,
      companyInfo: json['company_info'] != null
          ? Map<String, dynamic>.from(json['company_info'] as Map)
          : null,
      manufacturerInfo: json['manufacturer_info'] != null
          ? Map<String, dynamic>.from(json['manufacturer_info'] as Map)
          : null,
    );
  }
}

class Bill {
  final String id;
  final String billNumber;
  final BillType billType;
  final String? orderId;
  final String? productId;
  final String userId;
  final BillData billData;
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Bill({
    required this.id,
    required this.billNumber,
    required this.billType,
    this.orderId,
    this.productId,
    required this.userId,
    required this.billData,
    this.pdfUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_number': billNumber,
      'bill_type': billType.name,
      'order_id': orderId,
      'product_id': productId,
      'user_id': userId,
      'bill_data': billData.toJson(),
      'pdf_url': pdfUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      billNumber: json['bill_number'] as String,
      billType: BillType.values.firstWhere(
        (e) => e.name == json['bill_type'],
        orElse: () => BillType.user,
      ),
      orderId: json['order_id'] as String?,
      productId: json['product_id'] as String?,
      userId: json['user_id'] as String,
      billData: BillData.fromJson(json['bill_data'] as Map<String, dynamic>),
      pdfUrl: json['pdf_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory Bill.fromSupabaseRow(Map<String, dynamic> row) {
    return Bill(
      id: row['id'] as String,
      billNumber: row['bill_number'] as String,
      billType: BillType.values.firstWhere(
        (e) => e.name == row['bill_type'],
        orElse: () => BillType.user,
      ),
      orderId: row['order_id'] as String?,
      productId: row['product_id'] as String?,
      userId: row['user_id'] as String,
      billData: BillData.fromJson(row['bill_data'] as Map<String, dynamic>),
      pdfUrl: row['pdf_url'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

class BillTemplate {
  final String id;
  final BillType templateType;
  final String templateName;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BillTemplate({
    required this.id,
    required this.templateType,
    required this.templateName,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BillTemplate.fromSupabaseRow(Map<String, dynamic> row) {
    return BillTemplate(
      id: row['id'] as String,
      templateType: BillType.values.firstWhere(
        (e) => e.name == row['template_type'],
        orElse: () => BillType.user,
      ),
      templateName: row['template_name'] as String,
      imageUrl: row['image_url'] as String,
      isActive: row['is_active'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

