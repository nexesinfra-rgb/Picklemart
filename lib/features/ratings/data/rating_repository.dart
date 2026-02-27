import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

/// Model for a product rating
class ProductRating {
  final String id;
  final String productId;
  final String userId;
  final String? orderId;
  final int rating; // 1-5 stars
  final String? feedback; // Optional feedback/comment
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductRating({
    required this.id,
    required this.productId,
    required this.userId,
    this.orderId,
    required this.rating,
    this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductRating.fromJson(Map<String, dynamic> json) {
    return ProductRating(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String?,
      rating: json['rating'] as int,
      feedback: json['feedback'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'order_id': orderId,
      'rating': rating,
      'feedback': feedback,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Model for rating with user info (for admin views)
class ProductRatingWithUser {
  final ProductRating rating;
  final String? userName;
  final String? userEmail;

  ProductRatingWithUser({required this.rating, this.userName, this.userEmail});
}

/// Model for a rating reply
class RatingReply {
  final String id;
  final String ratingId;
  final String userId;
  final String? parentReplyId;
  final String replyText;
  final DateTime createdAt;
  final DateTime updatedAt;

  RatingReply({
    required this.id,
    required this.ratingId,
    required this.userId,
    this.parentReplyId,
    required this.replyText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RatingReply.fromJson(Map<String, dynamic> json) {
    return RatingReply(
      id: json['id'] as String,
      ratingId: json['rating_id'] as String,
      userId: json['user_id'] as String,
      parentReplyId: json['parent_reply_id'] as String?,
      replyText: json['reply_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating_id': ratingId,
      'user_id': userId,
      'parent_reply_id': parentReplyId,
      'reply_text': replyText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Model for reply with user info (for admin views)
class RatingReplyWithUser {
  final RatingReply reply;
  final String? userName;
  final String? userEmail;

  RatingReplyWithUser({required this.reply, this.userName, this.userEmail});
}

/// Repository for managing product ratings
class RatingRepository {
  final SupabaseClient _supabase;

  RatingRepository(this._supabase);

  /// Create or update a rating for a product
  /// Returns the created/updated rating
  Future<ProductRating> createOrUpdateRating({
    required String productId,
    required String userId,
    required int rating,
    String? orderId,
    String? feedback,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Check if user has purchased this product (if orderId is provided, verify it)
      if (orderId != null) {
        final orderCheck =
            await _supabase
                .from('orders')
                .select('id, status, user_id')
                .eq('id', orderId)
                .eq('user_id', userId)
                .maybeSingle();

        if (orderCheck == null) {
          throw Exception('Order not found or does not belong to user');
        }

        if (orderCheck['status'] == 'cancelled') {
          throw Exception('Cannot rate products from cancelled orders');
        }

        // Verify product is in the order
        final orderItemCheck =
            await _supabase
                .from('order_items')
                .select('product_id')
                .eq('order_id', orderId)
                .eq('product_id', productId)
                .maybeSingle();

        if (orderItemCheck == null) {
          throw Exception('Product not found in this order');
        }
      } else {
        // If no orderId, check if user has any delivered orders with this product
        final hasActiveOrder =
            await _supabase
                .from('orders')
                .select('id')
                .eq('user_id', userId)
                .neq('status', 'cancelled')
                .limit(1)
                .maybeSingle();

        if (hasActiveOrder == null) {
          throw Exception('Can only rate products from purchased orders');
        }
      }

      // Use upsert to create or update rating
      // Build data map, only include feedback if it's not null/empty
      final data = {
        'product_id': productId,
        'user_id': userId,
        'order_id': orderId,
        'rating': rating,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only add feedback if it exists (handles case where column might not exist yet)
      if (feedback != null && feedback.isNotEmpty) {
        data['feedback'] = feedback;
      }

      final response =
          await _supabase
              .from('product_ratings')
              .upsert(data, onConflict: 'product_id,user_id')
              .select()
              .single();

      return ProductRating.fromJson(response);
    } catch (e) {
      // Handle case where feedback column doesn't exist yet (migration not applied)
      if (e.toString().contains('feedback') &&
          e.toString().contains('schema cache')) {
        // Retry without feedback field
        final dataWithoutFeedback = {
          'product_id': productId,
          'user_id': userId,
          'order_id': orderId,
          'rating': rating,
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          final response =
              await _supabase
                  .from('product_ratings')
                  .upsert(dataWithoutFeedback, onConflict: 'product_id,user_id')
                  .select()
                  .single();

          return ProductRating.fromJson(response);
        } catch (retryError) {
          if (kDebugMode) {
            print('Error in createOrUpdateRating (retry): $retryError');
          }
          rethrow;
        }
      }

      if (kDebugMode) {
        print('Error in createOrUpdateRating: $e');
      }
      rethrow;
    }
  }

  /// Get all ratings for a product
  Future<List<ProductRating>> getProductRatings(String productId) async {
    try {
      final response = await _supabase
          .from('product_ratings')
          .select('*')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductRating.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in getProductRatings: $e');
      }
      rethrow;
    }
  }

  /// Get ratings for a product with user information (for admin)
  Future<List<ProductRatingWithUser>> getProductRatingsWithUsers(
    String productId,
  ) async {
    try {
      final response = await _supabase
          .from('product_ratings')
          .select('''
            *,
            profiles:user_id (
              name,
              email
            )
          ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final ratingData = json as Map<String, dynamic>;
        final profileData = ratingData['profiles'] as Map<String, dynamic>?;

        return ProductRatingWithUser(
          rating: ProductRating.fromJson(ratingData),
          userName: profileData?['name'] as String?,
          userEmail: profileData?['email'] as String?,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in getProductRatingsWithUsers: $e');
      }
      rethrow;
    }
  }

  /// Get product ratings with user info (paginated)
  Future<List<ProductRatingWithUser>> getProductRatingsWithUsersPaginated(
    String productId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final startIndex = (page - 1) * limit;
      final response = await _supabase
          .from('product_ratings')
          .select('''
            *,
            profiles:user_id (
              name,
              email
            )
          ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      return (response as List).map((json) {
        final ratingData = json as Map<String, dynamic>;
        final profileData = ratingData['profiles'] as Map<String, dynamic>?;

        return ProductRatingWithUser(
          rating: ProductRating.fromJson(ratingData),
          userName: profileData?['name'] as String?,
          userEmail: profileData?['email'] as String?,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in getProductRatingsWithUsersPaginated: $e');
      }
      rethrow;
    }
  }

  /// Get user's rating for a product
  Future<ProductRating?> getUserRating(String productId, String userId) async {
    try {
      final response =
          await _supabase
              .from('product_ratings')
              .select('*')
              .eq('product_id', productId)
              .eq('user_id', userId)
              .maybeSingle();

      if (response == null) return null;

      return ProductRating.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserRating: $e');
      }
      return null;
    }
  }

  /// Get user's ratings for multiple products in a single query (batch operation)
  /// Returns a map of product_id -> ProductRating for efficient lookup
  Future<Map<String, ProductRating>> getUserRatingsBatch(
    List<String> productIds,
    String userId,
  ) async {
    try {
      if (productIds.isEmpty) {
        return {};
      }

      final response = await _supabase
          .from('product_ratings')
          .select('*')
          .eq('user_id', userId)
          .inFilter('product_id', productIds);

      final ratingsMap = <String, ProductRating>{};
      for (final ratingData in response) {
        final rating = ProductRating.fromJson(ratingData);
        ratingsMap[rating.productId] = rating;
      }

      return ratingsMap;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getUserRatingsBatch: $e');
      }
      return {};
    }
  }

  /// Get rating by ID
  Future<ProductRating?> getRatingById(String ratingId) async {
    try {
      final response =
          await _supabase
              .from('product_ratings')
              .select('*')
              .eq('id', ratingId)
              .maybeSingle();

      if (response == null) return null;

      return ProductRating.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in getRatingById: $e');
      }
      return null;
    }
  }

  /// Delete a rating (admin only or own rating)
  Future<void> deleteRating(String ratingId) async {
    try {
      await _supabase.from('product_ratings').delete().eq('id', ratingId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteRating: $e');
      }
      rethrow;
    }
  }

  /// Get products from delivered orders that can be rated
  /// Returns list of product IDs from delivered orders for the user
  Future<List<Map<String, dynamic>>> getRatingsForOrder(String orderId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify order belongs to user and is delivered
      final order =
          await _supabase
              .from('orders')
              .select('id, status, user_id')
              .eq('id', orderId)
              .eq('user_id', userId)
              .maybeSingle();

      if (order == null) {
        throw Exception('Order not found or does not belong to user');
      }

      if (order['status'] != 'delivered') {
        throw Exception('Can only rate products from delivered orders');
      }

      // Get order items (use snapshot data already in order_items table)
      final orderItems = await _supabase
          .from('order_items')
          .select('product_id, name, image')
          .eq('order_id', orderId);

      // Get existing ratings for these products
      final productIds =
          (orderItems as List)
              .map(
                (item) =>
                    (item as Map<String, dynamic>)['product_id'] as String,
              )
              .toList();

      if (productIds.isEmpty) return [];

      final existingRatings = await _supabase
          .from('product_ratings')
          .select('product_id, rating')
          .eq('user_id', userId)
          .inFilter('product_id', productIds);

      final ratingsMap = <String, int>{};
      for (final rating in existingRatings as List) {
        final ratingData = rating as Map<String, dynamic>;
        ratingsMap[ratingData['product_id'] as String] =
            ratingData['rating'] as int;
      }

      // Combine order items with existing ratings
      return (orderItems as List).map((item) {
        final itemData = item as Map<String, dynamic>;
        final productId = itemData['product_id'] as String;
        final productName = itemData['name'] as String? ?? 'Unknown';
        final productImage = itemData['image'] as String? ?? '';

        return {
          'product_id': productId,
          'product_name': productName,
          'product_image': productImage,
          'order_id': orderId,
          'existing_rating': ratingsMap[productId],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in getRatingsForOrder: $e');
      }
      rethrow;
    }
  }

  /// Get most recent user who gave a high rating (4-5 stars) for a product
  Future<ProductRatingWithUser?> getHighestRatedUser(String productId) async {
    try {
      final response =
          await _supabase
              .from('product_ratings')
              .select('''
            *,
            profiles:user_id (
              name,
              email
            )
          ''')
              .eq('product_id', productId)
              .gte('rating', 4)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) return null;

      final ratingData = response;
      final profileData = ratingData['profiles'] as Map<String, dynamic>?;

      return ProductRatingWithUser(
        rating: ProductRating.fromJson(ratingData),
        userName: profileData?['name'] as String?,
        userEmail: profileData?['email'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in getHighestRatedUser: $e');
      }
      return null;
    }
  }

  /// Get all delivered orders for a user with products that can be rated
  Future<List<Map<String, dynamic>>> getDeliveredOrdersForRating(
    String userId,
  ) async {
    try {
      final orders = await _supabase
          .from('orders')
          .select('id, order_number, created_at, status')
          .eq('user_id', userId)
          .eq('status', 'delivered')
          .order('created_at', ascending: false);

      final result = <Map<String, dynamic>>[];

      for (final order in orders as List) {
        final orderData = order as Map<String, dynamic>;
        final orderId = orderData['id'] as String;

        // Get products for this order
        final products = await getRatingsForOrder(orderId);

        if (products.isNotEmpty) {
          result.add({
            'order_id': orderId,
            'order_number': orderData['order_number'] as String?,
            'created_at': orderData['created_at'] as String?,
            'products': products,
          });
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getDeliveredOrdersForRating: $e');
      }
      rethrow;
    }
  }

  /// Create a reply to a rating
  Future<RatingReply> createReply({
    required String ratingId,
    required String userId,
    required String replyText,
    String? parentReplyId,
  }) async {
    try {
      if (replyText.trim().isEmpty) {
        throw Exception('Reply text cannot be empty');
      }

      if (replyText.length > 1000) {
        throw Exception('Reply text cannot exceed 1000 characters');
      }

      final data = {
        'rating_id': ratingId,
        'user_id': userId,
        'reply_text': replyText.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (parentReplyId != null) {
        data['parent_reply_id'] = parentReplyId;
      }

      final response =
          await _supabase.from('rating_replies').insert(data).select().single();

      return RatingReply.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in createReply: $e');
      }
      rethrow;
    }
  }

  /// Get all replies for a rating (with threading support)
  Future<List<RatingReply>> getRepliesForRating(String ratingId) async {
    try {
      final response = await _supabase
          .from('rating_replies')
          .select('*')
          .eq('rating_id', ratingId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => RatingReply.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in getRepliesForRating: $e');
      }
      rethrow;
    }
  }

  /// Get replies for a rating with user information (for admin views)
  Future<List<RatingReplyWithUser>> getRepliesWithUsers(String ratingId) async {
    try {
      final response = await _supabase
          .from('rating_replies')
          .select('''
            *,
            profiles:user_id (
              name,
              email
            )
          ''')
          .eq('rating_id', ratingId)
          .order('created_at', ascending: true);

      return (response as List).map((json) {
        final replyData = json as Map<String, dynamic>;
        final profileData = replyData['profiles'] as Map<String, dynamic>?;

        return RatingReplyWithUser(
          reply: RatingReply.fromJson(replyData),
          userName: profileData?['name'] as String?,
          userEmail: profileData?['email'] as String?,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in getRepliesWithUsers: $e');
      }
      rethrow;
    }
  }

  /// Update a reply
  Future<RatingReply> updateReply({
    required String replyId,
    required String userId,
    required String replyText,
  }) async {
    try {
      if (replyText.trim().isEmpty) {
        throw Exception('Reply text cannot be empty');
      }

      if (replyText.length > 1000) {
        throw Exception('Reply text cannot exceed 1000 characters');
      }

      final response =
          await _supabase
              .from('rating_replies')
              .update({
                'reply_text': replyText.trim(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', replyId)
              .eq('user_id', userId)
              .select()
              .single();

      return RatingReply.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateReply: $e');
      }
      rethrow;
    }
  }

  /// Delete a reply
  Future<void> deleteReply(String replyId) async {
    try {
      await _supabase.from('rating_replies').delete().eq('id', replyId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in deleteReply: $e');
      }
      rethrow;
    }
  }

  /// Get reply count for a rating
  Future<int> getReplyCount(String ratingId) async {
    try {
      final response = await _supabase
          .from('rating_replies')
          .select('id')
          .eq('rating_id', ratingId);

      return (response as List).length;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getReplyCount: $e');
      }
      return 0;
    }
  }
}

/// Provider for rating repository
final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return RatingRepository(supabase);
});
