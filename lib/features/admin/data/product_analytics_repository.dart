import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:picklemart/core/providers/supabase_provider.dart';

class ProductViewEvent {
  final String id;
  final String productId;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final DateTime viewedAt;
  final String? city;
  final String? area;
  final String? address;

  ProductViewEvent({
    required this.id,
    required this.productId,
    required this.viewedAt,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.city,
    this.area,
    this.address,
  });
}

class ProductOrderEvent {
  final String id;
  final String productId;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String orderId;
  final int quantity;
  final double amount;
  final DateTime orderedAt;
  final String? city;
  final String? area;
  final String? address;

  ProductOrderEvent({
    required this.id,
    required this.productId,
    required this.orderId,
    required this.quantity,
    required this.amount,
    required this.orderedAt,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.city,
    this.area,
    this.address,
  });
}

class ProductAnalyticsRepository {
  final SupabaseClient _client;

  ProductAnalyticsRepository(this._client);

  Future<List<ProductViewEvent>> fetchViews(String productId) async {
    final response = await _client
        .from('product_views')
        .select('*, profiles:user_id(id, name, email, mobile)')
        .eq('product_id', productId)
        .order('viewed_at', ascending: false)
        .limit(100);

    final rows = List<Map<String, dynamic>>.from(response);
    return rows.map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      final profileName = profile?['name'] as String? ??
          profile?['full_name'] as String? ??
          profile?['display_name'] as String? ??
          profile?['username'] as String?;
      final profileEmail = profile?['email'] as String?;
      final profilePhone = profile?['mobile'] as String?;
      return ProductViewEvent(
        id: row['id'] as String,
        productId: row['product_id'] as String,
        userId: row['user_id'] as String?,
        userName: profileName,
        userEmail: profileEmail,
        userPhone: profilePhone,
        viewedAt: DateTime.tryParse(row['viewed_at'] as String? ?? '') ??
            DateTime.now(),
        city: row['city'] as String?,
        area: row['area'] as String?,
        address: row['address'] as String?,
      );
    }).toList();
  }

  Future<List<ProductOrderEvent>> fetchOrders(String productId) async {
    final response = await _client
        .from('product_order_analytics')
        .select(
            'id, product_id, order_id, user_id, quantity, amount, ordered_at, city, area, address')
        .eq('product_id', productId)
        .order('ordered_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response);

    // Collect user IDs to fetch profile details
    final userIds = <String>{};
    for (final row in rows) {
      final uid = row['user_id'] as String?;
      if (uid != null && uid.isNotEmpty) userIds.add(uid);
    }

    Map<String, Map<String, dynamic>> profilesById = {};
    if (userIds.isNotEmpty) {
      final profiles = await _client
          .from('profiles')
          .select('id, name, email, mobile')
          .filter('id', 'in', '(${userIds.join(',')})');
      profilesById = {
        for (final p in List<Map<String, dynamic>>.from(profiles))
          p['id'] as String: p
      };
    }

    return rows.map((row) {
      final uid = row['user_id'] as String?;
      final profile = uid != null ? profilesById[uid] : null;
      final profileName = profile?['name'] as String?;
      final profileEmail = profile?['email'] as String?;
      final profilePhone = profile?['mobile'] as String?;

      return ProductOrderEvent(
        id: row['id'] as String,
        productId: row['product_id'] as String,
        orderId: row['order_id'] as String,
        userId: uid,
        userName: profileName,
        userEmail: profileEmail,
        userPhone: profilePhone,
        quantity: row['quantity'] as int? ?? 0,
        amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
        orderedAt: DateTime.tryParse(row['ordered_at'] as String? ?? '') ??
            DateTime.now(),
        city: row['city'] as String?,
        area: row['area'] as String?,
        address: row['address'] as String?,
      );
    }).toList();
  }
}

final productAnalyticsRepositoryProvider =
    Provider<ProductAnalyticsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProductAnalyticsRepository(client);
});

