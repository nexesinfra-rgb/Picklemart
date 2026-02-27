import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/product_repository.dart';
import 'wishlist_repository.dart';

/// Supabase wishlist repository for managing wishlist items in the database
class WishlistRepositorySupabase implements WishlistRepository {
  final SupabaseClient _supabase;
  final ProductRepository _productRepository;

  WishlistRepositorySupabase(
    this._supabase,
    this._productRepository,
  );

  @override
  Future<List<Product>> getWishlistProducts(String userId) async {
    try {
      // Fetch wishlist items
      final response = await _supabase
          .from('wishlist')
          .select('product_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final wishlistData = List<Map<String, dynamic>>.from(response);
      final productIds = wishlistData
          .map((item) => item['product_id'] as String)
          .where((id) => id.isNotEmpty)
          .toList();

      if (productIds.isEmpty) {
        return [];
      }

      // Fetch products using ProductRepository
      final products = <Product>[];
      for (final productId in productIds) {
        try {
          final product = await _productRepository.fetchById(productId);
          if (product != null) {
            products.add(product);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching wishlist product $productId: $e');
          }
          // Continue with other products even if one fails
        }
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getWishlistProducts: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> addToWishlist(String productId, String userId) async {
    try {
      // Use upsert to handle cases where the item might already exist
      // This prevents unique constraint violations if the UI is out of sync
      await _supabase.from('wishlist').upsert(
        {
          'user_id': userId,
          'product_id': productId,
        },
        onConflict: 'user_id,product_id',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in addToWishlist: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> removeFromWishlist(String productId, String userId) async {
    try {
      await _supabase
          .from('wishlist')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in removeFromWishlist: $e');
      }
      rethrow;
    }
  }

  @override
  Future<bool> isInWishlist(String productId, String userId) async {
    try {
      final response = await _supabase
          .from('wishlist')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in isInWishlist: $e');
      }
      return false;
    }
  }

  @override
  Future<List<String>> getWishlistProductIds(String userId) async {
    try {
      final response = await _supabase
          .from('wishlist')
          .select('product_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final wishlistData = List<Map<String, dynamic>>.from(response);
      return wishlistData
          .map((item) => item['product_id'] as String)
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in getWishlistProductIds: $e');
      }
      rethrow;
    }
  }

  @override
  Stream<List<String>> watchWishlistProductIds(String userId) {
    try {
      return _supabase
          .from('wishlist')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .asyncMap((data) async {
        final wishlistData = List<Map<String, dynamic>>.from(data);
        return wishlistData
            .map((item) => item['product_id'] as String)
            .where((id) => id.isNotEmpty)
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error in watchWishlistProductIds: $e');
      }
      return Stream.value([]);
    }
  }
}

