import 'package:flutter/material.dart';

enum PurchaseOrderStatus { pending, confirmed, received, cancelled }

extension PurchaseOrderStatusExtension on PurchaseOrderStatus {
  String get displayName {
    switch (this) {
      case PurchaseOrderStatus.pending:
        return 'Pending';
      case PurchaseOrderStatus.confirmed:
        return 'Confirmed';
      case PurchaseOrderStatus.received:
        return 'Received';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get databaseValue {
    switch (this) {
      case PurchaseOrderStatus.pending:
        return 'pending';
      case PurchaseOrderStatus.confirmed:
        return 'confirmed';
      case PurchaseOrderStatus.received:
        return 'received';
      case PurchaseOrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static PurchaseOrderStatus? fromDatabaseValue(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase()) {
      case 'pending':
        return PurchaseOrderStatus.pending;
      case 'confirmed':
        return PurchaseOrderStatus.confirmed;
      case 'received':
        return PurchaseOrderStatus.received;
      case 'cancelled':
        return PurchaseOrderStatus.cancelled;
      default:
        return null;
    }
  }

  Color get color {
    switch (this) {
      case PurchaseOrderStatus.pending:
        return Colors.orange;
      case PurchaseOrderStatus.confirmed:
        return Colors.blue;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case PurchaseOrderStatus.pending:
        return Icons.pending_outlined;
      case PurchaseOrderStatus.confirmed:
        return Icons.check_circle_outline;
      case PurchaseOrderStatus.received:
        return Icons.done_all;
      case PurchaseOrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

class PurchaseOrderItem {
  final String id;
  final String productId;
  final String? variantId;
  final String? measurementUnit;
  final String name;
  final String? category;
  final String image;
  final int quantity;
  final double unitPrice;
  final double shippingCost;
  final double totalPrice;
  final String? notes;

  const PurchaseOrderItem({
    required this.id,
    required this.productId,
    this.variantId,
    this.measurementUnit,
    required this.name,
    this.category,
    required this.image,
    required this.quantity,
    required this.unitPrice,
    this.shippingCost = 0.0,
    required this.totalPrice,
    this.notes,
  });

  PurchaseOrderItem copyWith({
    String? id,
    String? productId,
    String? variantId,
    String? measurementUnit,
    String? name,
    String? category,
    String? image,
    int? quantity,
    double? unitPrice,
    double? shippingCost,
    double? totalPrice,
    String? notes,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      name: name ?? this.name,
      category: category ?? this.category,
      image: image ?? this.image,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      shippingCost: shippingCost ?? this.shippingCost,
      totalPrice:
          totalPrice ??
          (quantity != null || unitPrice != null
              ? (quantity ?? this.quantity) * (unitPrice ?? this.unitPrice)
              : this.totalPrice),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_id': variantId,
      'measurement_unit': measurementUnit,
      'name': name,
      'category': category,
      'image': image,
      'quantity': quantity,
      'unit_price': unitPrice,
      'shipping_cost': shippingCost,
      'total_price': totalPrice,
      'notes': notes,
    };
  }

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      measurementUnit: json['measurement_unit'] as String?,
      name: json['name'] as String,
      category: json['category'] as String?,
      image: json['image'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

class PurchaseOrder {
  final String id;
  final String purchaseNumber;
  final String? orderId; // Reference to original sale/order
  final String? manufacturerId; // Nullable - can be customer or manufacturer
  final String? customerId; // Nullable - can be customer or manufacturer
  final PurchaseOrderStatus status;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final double paidAmount;
  final DateTime purchaseDate;
  final DateTime? expectedDeliveryDate;
  final String? notes;
  final String? deliveryLocation;
  final String? transportationName;
  final String? transportationPhone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PurchaseOrderItem> items;

  double get balance => total - paidAmount;

  const PurchaseOrder({
    required this.id,
    required this.purchaseNumber,
    this.orderId,
    this.manufacturerId,
    this.customerId,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    this.paidAmount = 0.0,
    required this.purchaseDate,
    this.expectedDeliveryDate,
    this.notes,
    this.deliveryLocation,
    this.transportationName,
    this.transportationPhone,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  PurchaseOrder copyWith({
    String? id,
    String? purchaseNumber,
    String? orderId,
    String? manufacturerId,
    String? customerId,
    PurchaseOrderStatus? status,
    double? subtotal,
    double? tax,
    double? shipping,
    double? total,
    double? paidAmount,
    DateTime? purchaseDate,
    DateTime? expectedDeliveryDate,
    String? notes,
    String? deliveryLocation,
    String? transportationName,
    String? transportationPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PurchaseOrderItem>? items,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      purchaseNumber: purchaseNumber ?? this.purchaseNumber,
      orderId: orderId ?? this.orderId,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      shipping: shipping ?? this.shipping,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      notes: notes ?? this.notes,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      transportationName: transportationName ?? this.transportationName,
      transportationPhone: transportationPhone ?? this.transportationPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_number': purchaseNumber,
      'order_id': orderId,
      'manufacturer_id': manufacturerId,
      'customer_id': customerId,
      'status': status.databaseValue,
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'total': total,
      'paid_amount': paidAmount,
      'purchase_date': purchaseDate.toIso8601String(),
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'notes': notes,
      'delivery_location': deliveryLocation,
      'transportation_name': transportationName,
      'transportation_phone': transportationPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String,
      purchaseNumber: json['purchase_number'] as String,
      orderId: json['order_id'] as String?,
      manufacturerId: json['manufacturer_id'] as String?,
      customerId: json['customer_id'] as String?,
      status:
          PurchaseOrderStatusExtension.fromDatabaseValue(
            json['status'] as String,
          ) ??
          PurchaseOrderStatus.pending,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      shipping: (json['shipping'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      expectedDeliveryDate:
          json['expected_delivery_date'] != null
              ? DateTime.parse(json['expected_delivery_date'] as String)
              : null,
      notes: json['notes'] as String?,
      deliveryLocation: json['delivery_location'] as String?,
      transportationName: json['transportation_name'] as String?,
      transportationPhone: json['transportation_phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
