import 'dart:async';
import '../application/cart_controller.dart';

/// Repository interface for cart operations
abstract class CartRepository {
  /// Fetch all cart items for a user
  Future<List<CartItem>> fetchCartItems(String userId);

  /// Add or update cart item (upsert)
  /// Returns the cart item ID from the database
  Future<String> addCartItem(CartItem cartItem, String userId);

  /// Set cart item quantity (upsert with exact quantity)
  /// Returns the cart item ID from the database
  Future<String> setCartItemQuantity(CartItem cartItem, String userId);

  /// Update cart item quantity
  Future<void> updateCartItemQuantity(String cartItemId, int quantity);

  /// Remove cart item
  Future<void> removeCartItem(String cartItemId);

  /// Clear all cart items for a user
  Future<void> clearCart(String userId);

  /// Subscribe to real-time cart changes for a user
  Stream<List<CartItem>> subscribeToCartChanges(String userId);
}

