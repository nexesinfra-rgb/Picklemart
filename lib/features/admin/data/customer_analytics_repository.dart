import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for fetching customer analytics data
class CustomerAnalyticsRepository {
  final SupabaseClient _supabase;

  CustomerAnalyticsRepository(this._supabase);

  /// Fetch all orders for a customer
  Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final startIndex = (page - 1) * limit;
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('user_id', customerId)
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching customer orders: $e');
      }
      rethrow;
    }
  }

  /// Fetch wishlist items with product details
  Future<List<Map<String, dynamic>>> getCustomerWishlist(
    String customerId,
  ) async {
    try {
      final response = await _supabase
          .from('wishlist')
          .select('''
            *,
            products (
              id,
              name,
              price,
              image_url,
              images,
              brand,
              categories
            )
          ''')
          .eq('user_id', customerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching customer wishlist: $e');
      }
      rethrow;
    }
  }

  /// Fetch user sessions for calendar view
  Future<List<Map<String, dynamic>>> getCustomerSessions(
    String customerId,
  ) async {
    try {
      final response = await _supabase
          .from('user_sessions')
          .select('*')
          .eq('user_id', customerId)
          .order('started_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching customer sessions: $e');
      }
      rethrow;
    }
  }

  /// Fetch order items with product details for purchase behavior
  Future<List<Map<String, dynamic>>> getCustomerOrderItems(
    String customerId,
  ) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            order_items (
              *,
              products (
                id,
                name,
                price,
                image_url,
                images,
                brand,
                categories
              )
            )
          ''')
          .eq('user_id', customerId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching customer order items: $e');
      }
      rethrow;
    }
  }

  /// Fetch customer profile details
  Future<Map<String, dynamic>?> getCustomerProfile(String customerId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', customerId)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching customer profile: $e');
      }
      rethrow;
    }
  }
}

