import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_model.dart';
import '../data/order_repository_provider.dart';
import '../../cart/application/cart_controller.dart';

class OrderState {
  final bool loading;
  final String? error;
  final Order? currentOrder;

  const OrderState({this.loading = false, this.error, this.currentOrder});

  OrderState copyWith({bool? loading, String? error, Order? currentOrder}) {
    return OrderState(
      loading: loading ?? this.loading,
      error: error,
      currentOrder: currentOrder,
    );
  }
}

class OrderController extends StateNotifier<OrderState> {
  OrderController(this._ref) : super(const OrderState());
  final Ref _ref;

  Future<Order?> createOrderFromCart({
    required OrderAddress deliveryAddress,
    String? notes,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final cartItems = _ref.read(cartProvider).values.toList();

      if (cartItems.isEmpty) {
        state = state.copyWith(loading: false, error: 'Cart is empty');
        return null;
      }

      // Calculate pricing
      // Cart prices already include tax, so no additional tax calculation needed
      final subtotal = _ref.read(cartProvider.notifier).total;
      final shipping = _calculateShipping(subtotal);
      final tax = 0.0; // Prices already include tax
      final total = subtotal + shipping;

      // Create order (order number will be generated automatically by database trigger)
      final order = await _ref
          .read(orderRepositoryProvider)
          .createOrder(
            cartItems: cartItems,
            deliveryAddress: deliveryAddress,
            subtotal: subtotal,
            shipping: shipping,
            tax: tax,
            total: total,
            notes: notes,
          );

      if (!mounted) return null;

      // Clear cart after successful order creation
      _ref.read(cartProvider.notifier).clear();

      // Note: Order placed notification is automatically created by database trigger
      // No need to create it manually here

      state = state.copyWith(loading: false, currentOrder: order);

      return order;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return null;
    }
  }

  double _calculateShipping(double subtotal) {
    // Free shipping for all orders
    return 0.0;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearCurrentOrder() {
    state = state.copyWith(currentOrder: null);
  }
}

final orderControllerProvider =
    StateNotifierProvider<OrderController, OrderState>((ref) {
      return OrderController(ref);
    });
