import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wishlist_repository_provider.dart';
import 'wishlist_controller.dart';

/// Provider for wishlist controller
final wishlistControllerProvider =
    StateNotifierProvider<WishlistController, WishlistState>((ref) {
  final repository = ref.watch(wishlistRepositoryProvider);
  return WishlistController(ref, repository);
});

/// Provider for wishlist products
final wishlistProductsProvider = Provider((ref) {
  return ref.watch(wishlistControllerProvider).products;
});

/// Provider for wishlist product IDs set
final wishlistProductIdsProvider = Provider((ref) {
  return ref.watch(wishlistControllerProvider).productIds;
});

/// Provider to check if a product is in wishlist
final isProductInWishlistProvider = Provider.family<bool, String>((ref, productId) {
  final productIds = ref.watch(wishlistProductIdsProvider);
  return productIds.contains(productId);
});





