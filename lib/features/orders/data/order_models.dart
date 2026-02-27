import 'package:latlong2/latlong.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  outForDelivery,
  completed,
  cancelled,
}

class OrderItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String? variantSummary;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.variantSummary,
  });
}

class OrderStatusEntry {
  final OrderStatus status;
  final DateTime time;
  final String? note;

  const OrderStatusEntry({required this.status, required this.time, this.note});
}

class OrderAddress {
  final String name;
  final String phone;
  final String addressLine;
  final LatLng? location;

  const OrderAddress({
    required this.name,
    required this.phone,
    required this.addressLine,
    this.location,
  });
}

class Order {
  final String id;
  final DateTime createdAt;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double shipping;
  final double total;
  final OrderAddress address;
  final List<OrderStatusEntry> timeline;

  const Order({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.address,
    required this.timeline,
  });

  Order copyWith({OrderStatus? status, List<OrderStatusEntry>? timeline}) =>
      Order(
        id: id,
        createdAt: createdAt,
        status: status ?? this.status,
        items: items,
        subtotal: subtotal,
        shipping: shipping,
        total: total,
        address: address,
        timeline: timeline ?? this.timeline,
      );
}

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pending';
    case OrderStatus.confirmed:
      return 'Accepted';
    case OrderStatus.processing:
    case OrderStatus.outForDelivery:
    case OrderStatus.completed:
      return 'Order Pending';
    case OrderStatus.cancelled:
      return 'Cancelled';
  }
}

String orderStatusNote(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Awaiting admin confirmation';
    case OrderStatus.confirmed:
      return 'Admin confirmed your order';
    case OrderStatus.processing:
    case OrderStatus.outForDelivery:
    case OrderStatus.completed:
      return 'Being prepared for dispatch';
    case OrderStatus.cancelled:
      return 'Order cancelled';
  }
}

OrderStatus? nextStatus(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return OrderStatus.confirmed;
    case OrderStatus.confirmed:
      return OrderStatus.processing;
    case OrderStatus.processing:
    case OrderStatus.outForDelivery:
    case OrderStatus.completed:
    case OrderStatus.cancelled:
      return null;
  }
}
