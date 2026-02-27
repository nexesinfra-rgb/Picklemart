import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/measurement.dart';
import '../../auth/application/auth_controller.dart';
import '../data/cart_repository.dart';
import '../data/cart_repository_provider.dart';

class CartItem {
  final String? id; // Database ID from Supabase
  final Product product;
  final Variant? variant;
  final int quantity;
  final MeasurementUnit? measurementUnit;

  const CartItem(
    this.product,
    this.quantity, {
    this.id,
    this.variant,
    this.measurementUnit,
  });

  String get key {
    if (measurementUnit != null) {
      return '${product.id}:${variant?.sku ?? 'base'}:${measurementUnit!.shortName}';
    }
    return '${product.id}:${variant?.sku ?? 'base'}';
  }

  CartItem copyWith({
    String? id,
    Product? product,
    Variant? variant,
    int? quantity,
    MeasurementUnit? measurementUnit,
  }) => CartItem(
    product ?? this.product,
    quantity ?? this.quantity,
    id: id ?? this.id,
    variant: variant ?? this.variant,
    measurementUnit: measurementUnit ?? this.measurementUnit,
  );
}

class CartController extends StateNotifier<Map<String, CartItem>> {
  final Ref _ref;
  final CartRepository _repository;
  StreamSubscription<List<CartItem>>? _cartSubscription;
  bool _isLoading = false;
  bool _isSyncing = false;

  CartController(this._ref, this._repository) : super({}) {
    _initialize();
  }

  /// Get maximum available stock for this cart item.
  /// Cart operations no longer depend on stock quantities - returns unlimited.
  int _getMaxAvailableStock(CartItem item) {
    // Cart should work independently of stock quantities
    // Return a very high number to allow unlimited quantities
    return 999999;
  }

  /// Initialize cart controller
  Future<void> _initialize() async {
    // Listen to auth state changes
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        if (next.isAuthenticated && next.userId != null) {
          // User logged in: load cart from server and merge with guest cart
          _handleLogin(next.userId!);
        } else {
          // User logged out: clear server cart subscription, keep local cart as guest cart
          _handleLogout();
        }
      }
    });

    // Load cart if user is already authenticated
    final authState = _ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.userId != null) {
      await _loadCartFromServer(authState.userId!);
      _subscribeToCartChanges(authState.userId!);
    }
  }

  /// Handle user login
  Future<void> _handleLogin(String userId) async {
    try {
      // Get current guest cart (local state)
      final guestCart = Map<String, CartItem>.from(state);

      // Load server cart
      await _loadCartFromServer(userId);

      // Merge guest cart with server cart
      if (guestCart.isNotEmpty) {
        await _mergeGuestCartWithServerCart(guestCart, userId);
      }

      // Subscribe to real-time changes
      _subscribeToCartChanges(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling login: $e');
      }
      // Continue with current state even if merge fails
    }
  }

  /// Handle user logout
  void _handleLogout() {
    // Cancel real-time subscription
    _cartSubscription?.cancel();
    _cartSubscription = null;

    // Clear cart on logout to prevent cross-account data leaks
    state = {};
  }

  /// Load cart from Supabase server
  Future<void> _loadCartFromServer(String userId) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final cartItems = await _repository.fetchCartItems(userId);
      if (!mounted) return;
      final cartMap = <String, CartItem>{};
      for (final item in cartItems) {
        cartMap[item.key] = item;
      }
      state = cartMap;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cart from server: $e');
      }
      // Keep current state if load fails
    } finally {
      _isLoading = false;
    }
  }

  /// Merge guest cart with server cart
  Future<void> _mergeGuestCartWithServerCart(
    Map<String, CartItem> guestCart,
    String userId,
  ) async {
    try {
      // Get current server cart state (already loaded)
      final serverCart = Map<String, CartItem>.from(state);

      // For each guest cart item, merge with server cart
      for (final entry in guestCart.entries) {
        final guestItem = entry.value;
        final key = guestItem.key;
        final serverItem = serverCart[key];

        try {
          if (serverItem != null) {
            // Item exists on both: merge quantities and update on server
            final mergedQuantity = serverItem.quantity + guestItem.quantity;
            if (serverItem.id != null) {
              // Update existing server item with merged quantity
              await _repository.updateCartItemQuantity(
                serverItem.id!,
                mergedQuantity,
              );
              if (!mounted) return;
              // Update local state with merged quantity
              state = {
                ...state,
                key: serverItem.copyWith(quantity: mergedQuantity),
              };
            } else {
              // Server item doesn't have ID yet (shouldn't happen, but handle it)
              final cartItemId = await _repository.addCartItem(
                serverItem.copyWith(quantity: mergedQuantity),
                userId,
              );
              if (!mounted) return;
              state = {
                ...state,
                key: serverItem.copyWith(
                  id: cartItemId,
                  quantity: mergedQuantity,
                ),
              };
            }
          } else {
            // Item only exists in guest cart: add to server
            final cartItemId = await _repository.addCartItem(guestItem, userId);
            if (!mounted) return;
            // Update local state with server ID
            state = {...state, key: guestItem.copyWith(id: cartItemId)};
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error merging cart item ${entry.key}: $e');
          }
          // Continue with other items even if one fails
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error merging guest cart: $e');
      }
    }
  }

  /// Subscribe to real-time cart changes
  void _subscribeToCartChanges(String userId) {
    // Cancel existing subscription
    _cartSubscription?.cancel();

    // Subscribe to real-time changes
    _cartSubscription = _repository
        .subscribeToCartChanges(userId)
        .listen(
          (cartItems) {
            // Skip update if we're currently syncing (to avoid race conditions)
            if (_isSyncing) return;

            // Update state with server cart
            final cartMap = <String, CartItem>{};
            for (final item in cartItems) {
              cartMap[item.key] = item;
            }
            state = cartMap;
          },
          onError: (error) {
            if (kDebugMode) {
              print('Error in cart subscription: $error');
            }
            // Continue with current state if subscription fails
          },
        );
  }

  /// Sync cart item to server (if authenticated)
  Future<void> _syncCartItemToServer(CartItem cartItem) async {
    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated || authState.userId == null) {
      // Guest mode: don't sync to server
      return;
    }

    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final key = cartItem.key;

      // If quantity is 0 or less, remove from server and local state
      if (cartItem.quantity <= 0) {
        if (cartItem.id != null) {
          await _repository.removeCartItem(cartItem.id!);
          if (!mounted) return;
        }
        // Remove from local state
        final copy = {...state}..remove(key);
        state = copy;
        return;
      }

      String cartItemId;

      if (cartItem.id != null) {
        // Item already exists on server: update quantity directly
        cartItemId = cartItem.id!;
        await _repository.updateCartItemQuantity(cartItemId, cartItem.quantity);
      } else {
        // Item doesn't exist on server: set exact quantity (not add)
        cartItemId = await _repository.setCartItemQuantity(
          cartItem,
          authState.userId!,
        );
        if (!mounted) return;
        // Update local state with server ID
        if (state.containsKey(key)) {
          state = {...state, key: cartItem.copyWith(id: cartItemId)};
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing cart item to server: $e');
      }
      // Continue with local state even if sync fails
    } finally {
      _isSyncing = false;
    }
  }

  /// Remove cart item from server (if authenticated)
  Future<void> _removeCartItemFromServer(String? cartItemId) async {
    if (cartItemId == null) return;

    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      // Guest mode: don't sync to server
      return;
    }

    try {
      await _repository.removeCartItem(cartItemId);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing cart item from server: $e');
      }
      // Continue with local state even if sync fails
    }
  }

  /// Update cart item quantity on server (if authenticated)
  Future<void> _updateCartItemQuantityOnServer(
    String? cartItemId,
    int quantity,
  ) async {
    if (cartItemId == null) return;

    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      // Guest mode: don't sync to server
      return;
    }

    try {
      await _repository.updateCartItemQuantity(cartItemId, quantity);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cart item quantity on server: $e');
      }
      // Continue with local state even if sync fails
    }
  }

  /// Add product to cart
  Future<void> add(
    Product product, {
    Variant? variant,
    int qty = 1,
    MeasurementUnit? measurementUnit,
  }) async {
    // Base item representing this product/variant/unit combination
    final baseItem = CartItem(
      product,
      qty,
      variant: variant,
      measurementUnit: measurementUnit,
    );
    final key = baseItem.key;
    final existing = state[key];
    final referenceItem = existing ?? baseItem;

    // Cart operations no longer depend on stock quantities
    // Allow adding any quantity without stock validation
    final currentQty = existing?.quantity ?? 0;
    final desiredQty = currentQty + qty;

    final updatedItem = referenceItem.copyWith(quantity: desiredQty);

    // Update local state immediately
    state = {...state, key: updatedItem};

    // Sync to server if authenticated
    await _syncCartItemToServer(updatedItem);

    // Debug logging
    if (kDebugMode) {
      print('DEBUG: Cart after adding ${product.name}');
      state.forEach((key, item) {
        print('  - $key: ${item.product.name} (qty: ${item.quantity})');
      });
      print('Total unique products: ${state.length}');
    }
  }

  /// Remove one quantity of product from cart
  Future<void> remove(
    Product product, {
    Variant? variant,
    MeasurementUnit? measurementUnit,
  }) async {
    final cartItem = CartItem(
      product,
      1,
      variant: variant,
      measurementUnit: measurementUnit,
    );
    final key = cartItem.key;
    final existing = state[key];
    if (existing == null) return;

    if (existing.quantity <= 1) {
      // Remove item from cart
      final copy = {...state}..remove(key);
      state = copy;

      // Remove from server if authenticated
      await _removeCartItemFromServer(existing.id);
    } else {
      // Decrease quantity
      final updatedItem = existing.copyWith(quantity: existing.quantity - 1);
      state = {...state, key: updatedItem};

      // Update server if authenticated
      await _updateCartItemQuantityOnServer(existing.id, updatedItem.quantity);
    }
  }

  /// Delete product from cart
  Future<void> delete(
    Product product, {
    Variant? variant,
    MeasurementUnit? measurementUnit,
  }) async {
    final cartItem = CartItem(
      product,
      1,
      variant: variant,
      measurementUnit: measurementUnit,
    );
    final key = cartItem.key;
    final existing = state[key];
    if (existing == null) return;

    // Remove from local state
    final copy = {...state}..remove(key);
    state = copy;

    // Remove from server if authenticated
    await _removeCartItemFromServer(existing.id);
  }

  /// Clear all items from cart
  Future<void> clear() async {
    final authState = _ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.userId != null) {
      try {
        await _repository.clearCart(authState.userId!);
      } catch (e) {
        if (kDebugMode) {
          print('Error clearing cart on server: $e');
        }
        // Continue with local clear even if server clear fails
      }
    }

    // Clear local state
    state = {};
  }

  /// Calculate total price
  double get total => state.values.fold(0.0, (sum, item) {
    double price;
    if (item.measurementUnit != null && item.product.hasMeasurementPricing) {
      final measurement = item.product.measurement!;
      final pricing = measurement.getPricingForUnit(item.measurementUnit!);
      final basePrice = pricing?.price ?? item.product.price;
      // Calculate final price with tax for measurement pricing
      if (item.product.tax != null && item.product.tax! > 0) {
        price = basePrice + (basePrice * item.product.tax! / 100);
      } else {
        price = basePrice;
      }
    } else {
      // Use variant's final price with fallback to product tax, or product's final price
      if (item.variant != null) {
        price = item.variant!.finalPriceWithFallback(item.product.tax);
      } else {
        price = item.product.finalPrice;
      }
    }
    return sum + price * item.quantity;
  });

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}

/// Cart provider
final cartProvider =
    StateNotifierProvider<CartController, Map<String, CartItem>>((ref) {
      final repository = ref.watch(cartRepositoryProvider);
      return CartController(ref, repository);
    });
