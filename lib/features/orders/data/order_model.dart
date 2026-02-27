import 'package:flutter/material.dart';

enum OrderStatus { confirmed, processing, shipped, delivered, cancelled }

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.confirmed:
        return 'Accepted';
      case OrderStatus.processing:
        return 'Order Pending';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Order Pending';
    }
  }

  String get urlValue {
    switch (this) {
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.cancelled:
        return 'cancelled';
      default:
        return 'processing';
    }
  }

  static OrderStatus? fromUrlValue(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return null;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.processing:
        return Icons.hourglass_empty;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_empty;
    }
  }
}

class OrderItem {
  final String id;
  final String name;
  final String image;
  final double price;
  final int quantity;
  final String? size;
  final String? color;
  final String? category; // Added category field
  final String? variantId;
  final String? sku;

  const OrderItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    this.size,
    this.color,
    this.category,
    this.variantId,
    this.sku,
  });

  double get totalPrice => price * quantity;
}

class OrderAddress {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? alias;
  final String? shopPhotoUrl;
  final double? latitude;
  final double? longitude;

  const OrderAddress({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.alias,
    this.shopPhotoUrl,
    this.latitude,
    this.longitude,
  });

  String get fullAddress => '$address, $city, $state $pincode';
}

class Order {
  final String id;
  final String orderTag;
  final String orderNumber;
  final DateTime orderDate;
  final OrderStatus status;
  final List<OrderItem> items;
  final OrderAddress deliveryAddress;
  final double subtotal;
  final double shipping;
  final double tax;
  final double total;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;
  final String? notes;
  final String? userId;
  final DateTime? updatedAt;

  const Order({
    required this.id,
    required this.orderTag,
    required this.orderNumber,
    required this.orderDate,
    required this.status,
    required this.items,
    required this.deliveryAddress,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    this.trackingNumber,
    this.estimatedDelivery,
    this.notes,
    this.userId,
    this.updatedAt,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
