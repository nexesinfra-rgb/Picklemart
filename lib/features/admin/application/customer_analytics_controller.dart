import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_analytics_repository_provider.dart';

/// Model for customer analytics data
class CustomerAnalyticsData {
  final Map<String, dynamic>? profile;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> wishlist;
  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> orderItems;

  // Calculated fields
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final DateTime? lastOrderDate;
  final List<Map<String, dynamic>> productsBought;
  final Map<String, int> categoryCounts;
  final String? mostPurchasedCategory;

  CustomerAnalyticsData({
    required this.profile,
    required this.orders,
    required this.wishlist,
    required this.sessions,
    required this.orderItems,
    required this.totalOrders,
    required this.totalSpent,
    required this.averageOrderValue,
    this.lastOrderDate,
    required this.productsBought,
    required this.categoryCounts,
    this.mostPurchasedCategory,
  });

  factory CustomerAnalyticsData.fromRawData({
    required Map<String, dynamic>? profile,
    required List<Map<String, dynamic>> orders,
    required List<Map<String, dynamic>> wishlist,
    required List<Map<String, dynamic>> sessions,
    required List<Map<String, dynamic>> orderItems,
  }) {
    // Calculate totals
    final totalOrders = orders.length;
    final totalSpent = orders.fold<double>(
      0.0,
      (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0.0),
    );
    final averageOrderValue =
        totalOrders > 0 ? totalSpent / totalOrders : 0.0;

    // Get last order date
    DateTime? lastOrderDate;
    if (orders.isNotEmpty) {
      final lastOrder = orders.first;
      final createdAtString = lastOrder['created_at'] as String?;
      if (createdAtString != null) {
        try {
          lastOrderDate = DateTime.parse(createdAtString);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing last order date: $e');
          }
        }
      }
    }

    // Extract products bought from order items
    final productsBought = <Map<String, dynamic>>[];
    final categoryCounts = <String, int>{};

    for (final order in orderItems) {
      final items = order['order_items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final itemMap = item as Map<String, dynamic>;
        final product = itemMap['products'] as Map<String, dynamic>?;
        if (product != null) {
          final productId = product['id'] as String?;
          final existingProduct = productsBought.firstWhere(
            (p) => p['id'] == productId,
            orElse: () => <String, dynamic>{},
          );

          if (existingProduct.isEmpty) {
            productsBought.add({
              'id': productId,
              'name': product['name'] ?? '',
              'price': product['price'] ?? 0.0,
              'image_url': product['image_url'] ?? '',
              'images': product['images'] ?? [],
              'brand': product['brand'],
              'categories': product['categories'] ?? [],
              'quantity': (itemMap['quantity'] as num?)?.toInt() ?? 1,
              'total': ((itemMap['price'] as num?)?.toDouble() ?? 0.0) *
                  ((itemMap['quantity'] as num?)?.toInt() ?? 1),
            });
          } else {
            existingProduct['quantity'] =
                (existingProduct['quantity'] as int) +
                    ((itemMap['quantity'] as num?)?.toInt() ?? 1);
            existingProduct['total'] =
                (existingProduct['total'] as double) +
                    (((itemMap['price'] as num?)?.toDouble() ?? 0.0) *
                        ((itemMap['quantity'] as num?)?.toInt() ?? 1));
          }

          // Count categories
          final categories = product['categories'] as List<dynamic>? ?? [];
          for (final category in categories) {
            final catName = category.toString();
            categoryCounts[catName] = (categoryCounts[catName] ?? 0) + 1;
          }
        }
      }
    }

    // Find most purchased category
    String? mostPurchasedCategory;
    if (categoryCounts.isNotEmpty) {
      mostPurchasedCategory = categoryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return CustomerAnalyticsData(
      profile: profile,
      orders: orders,
      wishlist: wishlist,
      sessions: sessions,
      orderItems: orderItems,
      totalOrders: totalOrders,
      totalSpent: totalSpent,
      averageOrderValue: averageOrderValue,
      lastOrderDate: lastOrderDate,
      productsBought: productsBought,
      categoryCounts: categoryCounts,
      mostPurchasedCategory: mostPurchasedCategory,
    );
  }
}

/// State for customer analytics
class CustomerAnalyticsState {
  final CustomerAnalyticsData? data;
  final bool loading;
  final String? error;

  const CustomerAnalyticsState({
    this.data,
    this.loading = false,
    this.error,
  });

  CustomerAnalyticsState copyWith({
    CustomerAnalyticsData? data,
    bool? loading,
    String? error,
  }) =>
      CustomerAnalyticsState(
        data: data ?? this.data,
        loading: loading ?? this.loading,
        error: error,
      );
}

/// Controller for customer analytics
class CustomerAnalyticsController
    extends StateNotifier<CustomerAnalyticsState> {
  CustomerAnalyticsController(this._ref)
      : super(const CustomerAnalyticsState());

  final Ref _ref;

  Future<void> loadCustomerAnalytics(
    String customerId, {
    String? customerName,
    String? customerEmail,
  }) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final repository =
          _ref.read(customerAnalyticsRepositoryProvider);

      // Fetch all data in parallel
      final results = await Future.wait([
        repository.getCustomerProfile(customerId),
        repository.getCustomerOrders(customerId),
        repository.getCustomerWishlist(customerId),
        repository.getCustomerSessions(customerId),
        repository.getCustomerOrderItems(customerId),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final orders = results[1] as List<Map<String, dynamic>>;
      final wishlist = results[2] as List<Map<String, dynamic>>;
      final sessions = results[3] as List<Map<String, dynamic>>;
      final orderItems = results[4] as List<Map<String, dynamic>>;

      final analyticsData = CustomerAnalyticsData.fromRawData(
        profile: profile,
        orders: orders,
        wishlist: wishlist,
        sessions: sessions,
        orderItems: orderItems,
      );

      state = state.copyWith(
        data: analyticsData,
        loading: false,
        error: null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading customer analytics: $e');
      }
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }
}

final customerAnalyticsControllerProvider =
    StateNotifierProvider<CustomerAnalyticsController, CustomerAnalyticsState>(
  (ref) => CustomerAnalyticsController(ref),
);

