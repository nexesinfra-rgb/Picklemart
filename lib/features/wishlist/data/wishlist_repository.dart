import '../../catalog/data/product.dart';

/// Repository interface for wishlist operations
abstract class WishlistRepository {
  /// Fetch all wishlist products for a user
  Future<List<Product>> getWishlistProducts(String userId);

  /// Add product to wishlist
  Future<void> addToWishlist(String productId, String userId);

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String productId, String userId);

  /// Check if product is in wishlist
  Future<bool> isInWishlist(String productId, String userId);

  /// Get list of product IDs in wishlist
  Future<List<String>> getWishlistProductIds(String userId);

  /// Subscribe to real-time wishlist changes for a user
  Stream<List<String>> watchWishlistProductIds(String userId);
}





