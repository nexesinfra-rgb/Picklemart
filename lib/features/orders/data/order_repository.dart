import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_model.dart';
import 'order_repository_provider.dart';
import '../../cart/application/cart_controller.dart';
import '../../catalog/data/measurement.dart';

abstract class OrderRepository {
  Future<Order> createOrder({
    String? orderNumber,
    required List<CartItem> cartItems,
    required OrderAddress deliveryAddress,
    required double subtotal,
    required double shipping,
    required double tax,
    required double total,
    String? notes,
    String? userId,

    /// Optional status. If provided, sets the initial status of the order.
    /// If null, defaults to [OrderStatus.processing].
    /// Admins typically create orders with [OrderStatus.confirmed].
    OrderStatus? status,

    /// Optional old due to be included in order notes
    double oldDue = 0.0,
  });

  Future<Order?> getOrderById(String orderId);
  Future<List<Order>> getUserOrders({int page = 1, int limit = 50});
  Future<List<Order>> getAllOrders({
    int page = 1,
    int limit = 50,
    String? searchQuery,
  });
  Future<Order?> updateOrderStatus(String orderId, OrderStatus status);
  Future<Order?> updateOrderItems(String orderId, List<OrderItem> items);
  Future<Order?> updateOrderDeliveryAddress(
    String orderId,
    OrderAddress address,
  );
  Future<Order?> updateOrderDetails({
    required String orderId,
    required OrderAddress deliveryAddress,
    required double shipping,
    double oldDue = 0.0,
  });
  Future<bool> deleteOrder(String orderId);

  /// Get summary metrics for orders (optimized for dashboard)
  Future<Map<String, dynamic>> getOrderMetrics();

  /// Subscribe to real-time updates for user orders
  Stream<void> subscribeToUserOrders();
}

class InMemoryOrderRepository implements OrderRepository {
  InMemoryOrderRepository();

  final List<Order> _orders = [];
  int _orderCounter = 1;

  @override
  Future<Order> createOrder({
    String? orderNumber,
    required List<CartItem> cartItems,
    required OrderAddress deliveryAddress,
    required double subtotal,
    required double shipping,
    required double tax,
    required double total,
    String? notes,
    String? userId,
    OrderStatus? status,
    double oldDue = 0.0,
  }) async {
    // Convert cart items to order items to order items
    final orderItems =
        cartItems.map((cartItem) {
          double price;
          String name = cartItem.product.name;

          // Handle measurement-based pricing
          if (cartItem.measurementUnit != null &&
              cartItem.product.hasMeasurementPricing) {
            final measurement = cartItem.product.measurement!;
            final pricing = measurement.getPricingForUnit(
              cartItem.measurementUnit!,
            );
            final basePrice = pricing?.price ?? cartItem.product.price;
            // Calculate final price with tax for measurement pricing
            if (cartItem.product.tax != null && cartItem.product.tax! > 0) {
              price = basePrice + (basePrice * cartItem.product.tax! / 100);
            } else {
              price = basePrice;
            }
            name =
                '${cartItem.product.name} (${cartItem.measurementUnit!.shortName})';
          } else {
            // Use finalPrice (with tax) to match what customer sees in cart
            if (cartItem.variant != null) {
              price = cartItem.variant!.finalPriceWithFallback(
                cartItem.product.tax,
              );
            } else {
              price = cartItem.product.finalPrice;
            }
          }

          return OrderItem(
            id: cartItem.product.id,
            name: name,
            image: cartItem.product.imageUrl,
            price: price,
            quantity: cartItem.quantity,
            size: cartItem.variant?.attributes['Size'],
            color: cartItem.variant?.attributes['Color'],
            variantId: cartItem.variant?.id,
            sku: cartItem.variant?.sku,
          );
        }).toList();

    final updatedNotes =
        oldDue > 0
            ? '${notes ?? ''}\nOld Due: Rs ${oldDue.toStringAsFixed(2)}'.trim()
            : notes;

    final order = Order(
      id: 'order_${_orderCounter++}',
      orderTag: orderNumber ?? 'ORD${_orderCounter.toString().padLeft(4, '0')}',
      orderNumber:
          orderNumber ?? 'ORD${_orderCounter.toString().padLeft(4, '0')}',
      orderDate: DateTime.now(),
      status: status ?? OrderStatus.processing,
      items: orderItems,
      deliveryAddress: deliveryAddress,
      subtotal: subtotal,
      shipping: shipping,
      tax: tax,
      total: total,
      estimatedDelivery: DateTime.now().add(const Duration(days: 3)),
      notes: updatedNotes,
      userId: null, // Mock repository doesn't track user ID
    );

    _orders.add(order);
    return order;
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Order>> getUserOrders({int page = 1, int limit = 50}) async {
    final reversedOrders = List<Order>.from(
      _orders.reversed,
    ); // Most recent first
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= reversedOrders.length) return [];

    return reversedOrders.sublist(
      startIndex,
      endIndex > reversedOrders.length ? reversedOrders.length : endIndex,
    );
  }

  @override
  Future<List<Order>> getAllOrders({
    int page = 1,
    int limit = 50,
    String? searchQuery,
  }) async {
    var filtered = List<Order>.from(_orders.reversed); // Most recent first

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered =
          filtered.where((order) {
            return order.orderNumber.toLowerCase().contains(query) ||
                order.deliveryAddress.name.toLowerCase().contains(query) ||
                order.deliveryAddress.phone.contains(query);
          }).toList();
    }

    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= filtered.length) return [];

    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  @override
  Future<Order?> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) return null;

      final order = _orders[orderIndex];
      // Create updated order with new status
      final updatedOrder = Order(
        id: order.id,
        orderTag: order.orderTag,
        orderNumber: order.orderNumber,
        orderDate: order.orderDate,
        status: status,
        items: order.items,
        deliveryAddress: order.deliveryAddress,
        subtotal: order.subtotal,
        shipping: order.shipping,
        tax: order.tax,
        total: order.total,
        trackingNumber: order.trackingNumber,
        estimatedDelivery: order.estimatedDelivery,
        notes: order.notes,
        userId: order.userId,
      );

      _orders[orderIndex] = updatedOrder;
      return updatedOrder;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Order?> updateOrderItems(String orderId, List<OrderItem> items) async {
    try {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) return null;

      final order = _orders[orderIndex];

      // Validate status
      if (order.status != OrderStatus.confirmed &&
          order.status != OrderStatus.processing) {
        throw Exception(
          'Cannot modify order items after order has been shipped',
        );
      }

      // Calculate new subtotal
      final newSubtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      // Calculate new total
      final newTotal = newSubtotal + order.shipping + order.tax;

      // Create updated order with new items and totals
      final updatedOrder = Order(
        id: order.id,
        orderTag: order.orderTag,
        orderNumber: order.orderNumber,
        orderDate: order.orderDate,
        status: order.status,
        items: items,
        deliveryAddress: order.deliveryAddress,
        subtotal: newSubtotal,
        shipping: order.shipping,
        tax: order.tax,
        total: newTotal,
        trackingNumber: order.trackingNumber,
        estimatedDelivery: order.estimatedDelivery,
        notes: order.notes,
        userId: order.userId,
      );

      _orders[orderIndex] = updatedOrder;
      return updatedOrder;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Order?> updateOrderDeliveryAddress(
    String orderId,
    OrderAddress address,
  ) async {
    try {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) return null;

      final order = _orders[orderIndex];
      final updatedOrder = Order(
        id: order.id,
        orderTag: order.orderTag,
        orderNumber: order.orderNumber,
        orderDate: order.orderDate,
        status: order.status,
        items: order.items,
        deliveryAddress: address,
        subtotal: order.subtotal,
        shipping: order.shipping,
        tax: order.tax,
        total: order.total,
        trackingNumber: order.trackingNumber,
        estimatedDelivery: order.estimatedDelivery,
        notes: order.notes,
        userId: order.userId,
      );

      _orders[orderIndex] = updatedOrder;
      return updatedOrder;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Order?> updateOrderDetails({
    required String orderId,
    required OrderAddress deliveryAddress,
    required double shipping,
    double oldDue = 0.0,
  }) async {
    try {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) return null;

      final order = _orders[orderIndex];
      final newTotal = order.subtotal + shipping + order.tax + oldDue;

      // Update notes with Old Due
      var updatedNotes = order.notes ?? '';
      updatedNotes =
          updatedNotes
              .replaceAll(RegExp(r'\n?Old Due: (?:₹|Rs )[\d\.]+'), '')
              .trim();
      if (oldDue > 0) {
        updatedNotes =
            '$updatedNotes\nOld Due: Rs ${oldDue.toStringAsFixed(2)}'.trim();
      }

      final updatedOrder = Order(
        id: order.id,
        orderTag: order.orderTag,
        orderNumber: order.orderNumber,
        orderDate: order.orderDate,
        status: order.status,
        items: order.items,
        deliveryAddress: deliveryAddress,
        subtotal: order.subtotal,
        shipping: shipping,
        tax: order.tax,
        total: newTotal,
        trackingNumber: order.trackingNumber,
        estimatedDelivery: order.estimatedDelivery,
        notes: updatedNotes,
        userId: order.userId,
      );

      _orders[orderIndex] = updatedOrder;
      return updatedOrder;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteOrder(String orderId) async {
    try {
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex == -1) return false;
      _orders.removeAt(orderIndex);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getOrderMetrics() async {
    final totalOrders = _orders.length;
    final totalRevenue = _orders
        .where((o) => o.status != OrderStatus.processing)
        .fold<double>(0.0, (sum, o) => sum + o.total);
    final pendingOrders =
        _orders.where((o) => o.status == OrderStatus.processing).length;

    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'pendingOrders': pendingOrders,
    };
  }

  @override
  Stream<void> subscribeToUserOrders() {
    return const Stream.empty();
  }
}

// Order repository provider is now in order_repository_provider.dart
// Keeping this file for backward compatibility
// final orderRepositoryProvider = Provider<OrderRepository>((ref) {
//   return InMemoryOrderRepository();
// });

// Provider for getting order by ID
final orderByIdProvider = FutureProvider.family<Order?, String>((
  ref,
  orderId,
) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});

// Provider for getting user orders
final userOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getUserOrders();
});
