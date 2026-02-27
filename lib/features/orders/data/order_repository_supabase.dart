import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';
import 'order_repository.dart';
import '../../cart/application/cart_controller.dart';
import '../../catalog/data/measurement.dart';
import '../../auth/application/auth_controller.dart';
import '../../../core/config/environment.dart';
import '../../notifications/data/notification_repository_provider.dart';
import '../../notifications/data/notification_model.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../admin/application/admin_product_controller.dart';

/// Supabase order repository for managing orders in the database
class OrderRepositorySupabase implements OrderRepository {
  final SupabaseClient _supabase;
  final Ref _ref;

  OrderRepositorySupabase(this._supabase, this._ref);

  /// Validate if a URL string is a valid HTTP/HTTPS URL
  /// Returns true if valid, false otherwise
  static bool _isValidShopPhotoUrl(String? url) {
    if (url == null) return false;

    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return false;

    // Must start with http:// or https://
    if (!trimmedUrl.startsWith('http://') &&
        !trimmedUrl.startsWith('https://')) {
      return false;
    }

    // Basic URL format validation using Uri.parse
    try {
      final uri = Uri.parse(trimmedUrl);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Invalid shopPhotoUrl format: $trimmedUrl - $e');
      }
      return false;
    }
  }

  /// Parse coordinates from order notes
  /// Pattern: "Location: Lat 17.385054, Lng 78.431535"
  /// Returns a map with 'latitude' and 'longitude' keys, or null if parsing fails
  Map<String, double>? _parseCoordinatesFromNotes(String? notes) {
    if (notes == null || notes.isEmpty) return null;

    try {
      // Pattern: "Location: Lat {latitude}, Lng {longitude}"
      final regex = RegExp(
        r'Location:\s*Lat\s+([\d.]+),\s*Lng\s+([\d.]+)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(notes);

      if (match == null || match.groupCount < 2) {
        return null;
      }

      final latStr = match.group(1);
      final lngStr = match.group(2);

      if (latStr == null || lngStr == null) {
        return null;
      }

      final latitude = double.parse(latStr);
      final longitude = double.parse(lngStr);

      // Validate coordinates
      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        if (kDebugMode) {
          print('⚠️ Invalid coordinates: Lat $latitude, Lng $longitude');
        }
        return null;
      }

      return {'latitude': latitude, 'longitude': longitude};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing coordinates from notes: $e');
      }
      return null;
    }
  }

  /// Get the next sequential order tag in format "order#4700", "order#4701", etc.
  /// Starts from 4700 and finds the max existing number + 1.
  Future<String> _getNextOrderTag() async {
    try {
      // Fetch latest orders to find the highest current tag
      // We only need the latest ones because we want the MAX number, not filling gaps
      final response = await _supabase
          .from('orders')
          .select('order_tag')
          .not('order_tag', 'is', null)
          .order('created_at', ascending: false)
          .limit(100);

      final existingTags = <int>{};
      for (final row in response) {
        final tag = row['order_tag'] as String?;
        if (tag != null && tag.startsWith('order#')) {
          final numStr = tag.substring(6); // Remove 'order#' prefix
          final num = int.tryParse(numStr);
          if (num != null) {
            existingTags.add(num);
          }
        }
      }

      // Find max number starting from 4700 (or 4699 as base)
      int maxNum = 4699;
      for (final num in existingTags) {
        if (num > maxNum) maxNum = num;
      }

      return 'order#${maxNum + 1}';
    } catch (e) {
      if (kDebugMode) {
        print('Error generating next order tag: $e');
      }
      // Fallback: use timestamp-based tag
      return 'order#${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get the next sequential order number
  /// Implements "Max + 1" strategy to ensure serial numbers
  Future<String> _getNextOrderNumber() async {
    try {
      // Fetch latest order numbers
      final response = await _supabase
          .from('orders')
          .select('order_number')
          .order('created_at', ascending: false)
          .limit(100);

      final List<dynamic> data = response;

      // Parse all existing numeric order numbers
      final existingNumbers = <int>{};
      for (final row in data) {
        final numStr = row['order_number'] as String?;
        if (numStr != null) {
          final num = int.tryParse(numStr);
          if (num != null && num > 0) {
            existingNumbers.add(num);
          }
        }
      }

      // Find the max number starting from 4700
      int maxNum = 4699;
      for (final num in existingNumbers) {
        if (num > maxNum) maxNum = num;
      }

      return (maxNum + 1).toString();
    } catch (e) {
      if (kDebugMode) {
        print('Error generating next order number: $e');
      }
      // Fallback
      return DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    }
  }

  /// Create a new order with order items (transaction)
  /// orderNumber is optional - if not provided, database trigger will generate it from order ID
  @override
  Future<Order> createOrder({
    String? orderNumber,
    required List<CartItem> cartItems,
    required OrderAddress deliveryAddress,
    required double subtotal,
    required double shipping,
    required double tax,
    required double total,
    String? notes,
    String? userId,
    OrderStatus? status,
    double oldDue = 0.0,
  }) async {
    try {
      // Get current user ID or use provided one
      final targetUserId = userId ?? _ref.read(authControllerProvider).userId;

      if (targetUserId == null) {
        throw Exception('User ID required for order creation');
      }

      // Deduplicate cart items to prevent duplicate products
      final uniqueItemsMap = <String, CartItem>{};
      for (final item in cartItems) {
        if (uniqueItemsMap.containsKey(item.key)) {
          final existing = uniqueItemsMap[item.key]!;
          uniqueItemsMap[item.key] = existing.copyWith(
            quantity: existing.quantity + item.quantity,
          );
        } else {
          uniqueItemsMap[item.key] = item;
        }
      }
      final processedCartItems = uniqueItemsMap.values.toList();

      // Handle old due if provided
      final updatedNotes =
          oldDue > 0
              ? '${notes ?? ''}\nOld Due: Rs ${oldDue.toStringAsFixed(2)}'
                  .trim()
              : notes;

      // Validate stock before creating order
      await _validateStock(processedCartItems);

      // Prepare delivery address as JSONB
      // Validate shopPhotoUrl - must be non-null, non-empty, and valid URL
      final shopPhotoUrl = deliveryAddress.shopPhotoUrl;
      final isValidShopPhotoUrl = _isValidShopPhotoUrl(shopPhotoUrl);

      final deliveryAddressJson = {
        'name': deliveryAddress.name,
        'phone': deliveryAddress.phone,
        'address': deliveryAddress.address,
        'city': deliveryAddress.city,
        'state': deliveryAddress.state,
        'pincode': deliveryAddress.pincode,
        'alias': deliveryAddress.alias,
        if (isValidShopPhotoUrl) 'shopPhotoUrl': shopPhotoUrl!.trim(),
      };

      if (kDebugMode) {
        print('📦 Creating order with delivery_address JSONB:');
        print('   shopPhotoUrl (original): ${shopPhotoUrl ?? 'null'}');
        print('   shopPhotoUrl (valid): $isValidShopPhotoUrl');
        if (isValidShopPhotoUrl) {
          print('   shopPhotoUrl (final): ${shopPhotoUrl!.trim()}');
        } else if (shopPhotoUrl != null) {
          print(
            '   ⚠️ shopPhotoUrl rejected: invalid format, empty, or not a valid URL',
          );
        }
        print('   Full delivery_address: $deliveryAddressJson');
      }

      // Generate sequential order tag
      final generatedOrderTag = await _getNextOrderTag();

      // Create order using Supabase transaction via RPC or multiple queries
      // Since Supabase doesn't support explicit transactions in the client,
      // we'll use a Postgres function or do sequential inserts with rollback on error
      final orderData = {
        'order_number':
            generatedOrderTag, // Use order_tag as order_number for display
        'order_tag': generatedOrderTag,
        'user_id': targetUserId,
        'status': status?.urlValue ?? 'processing',
        'subtotal': subtotal,
        'shipping': shipping,
        'tax': tax,
        'total': total,
        'delivery_address': deliveryAddressJson,
        'notes': updatedNotes,
        'estimated_delivery':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      };

      // Insert order (order_number will be set by database trigger if not provided)
      final orderResponse =
          await _supabase.from('orders').insert(orderData).select().single();

      final orderId = orderResponse['id'] as String;
      // Get the order_number from the response (either provided or generated by trigger)
      // final generatedOrderNumber = orderResponse['order_number'] as String;

      // Batch fetch variant IDs to avoid N+1 queries
      // Collect all unique variant lookups needed
      final variantLookupKeys = <String>{}; // Keys like "productId:sku"
      final productIdsSet = <String>{};
      for (final cartItem in processedCartItems) {
        if (cartItem.variant != null &&
            (cartItem.measurementUnit == null ||
                !cartItem.product.hasMeasurementPricing)) {
          final key = '${cartItem.product.id}:${cartItem.variant!.sku}';
          variantLookupKeys.add(key);
          productIdsSet.add(cartItem.product.id);
        }
      }

      // Batch fetch all variant IDs in one query
      final variantIdMap = <String, String>{};
      if (variantLookupKeys.isNotEmpty) {
        try {
          // Collect all product IDs for batch query
          final productIds = productIdsSet.toList();

          // Fetch variants matching any of the product IDs and SKUs
          // Note: We can't easily do a composite IN filter, so we'll fetch by product_id
          // and filter by SKU in memory, or fetch all and filter
          final variantsResponse = await _supabase
              .from('product_variants')
              .select('id, product_id, sku')
              .inFilter('product_id', productIds);

          final variantsData = List<Map<String, dynamic>>.from(
            variantsResponse,
          );

          // Create lookup map: key is "productId:sku", value is variant ID
          for (final variantData in variantsData) {
            final variantProductId = variantData['product_id'] as String? ?? '';
            final variantSku = variantData['sku'] as String? ?? '';
            final variantId = variantData['id'] as String? ?? '';
            final lookupKey = '$variantProductId:$variantSku';
            if (variantLookupKeys.contains(lookupKey)) {
              variantIdMap[lookupKey] = variantId;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error batch fetching variant IDs: $e');
          }
          // Continue without variant IDs if batch fetch fails
        }
      }

      // Prepare order items
      final orderItemsData = <Map<String, dynamic>>[];
      final orderAnalyticsData = <Map<String, dynamic>>[];
      for (final cartItem in processedCartItems) {
        double price;
        String name = cartItem.product.name;
        String? variantId;
        String? measurementUnit;
        double lineTotal;

        // Handle measurement-based pricing
        if (cartItem.measurementUnit != null &&
            cartItem.product.hasMeasurementPricing) {
          final measurement = cartItem.product.measurement!;
          final pricing = measurement.getPricingForUnit(
            cartItem.measurementUnit!,
          );
          final basePrice = pricing?.price ?? cartItem.product.price;
          // Calculate final price with tax for measurement pricing
          if (cartItem.product.tax != null && cartItem.product.tax! > 0) {
            price = basePrice + (basePrice * cartItem.product.tax! / 100);
          } else {
            price = basePrice;
          }
          name =
              '${cartItem.product.name} (${cartItem.measurementUnit!.shortName})';
          measurementUnit = cartItem.measurementUnit!.shortName;
        } else {
          // Use finalPrice (with tax) to match what customer sees in cart
          if (cartItem.variant != null) {
            price = cartItem.variant!.finalPriceWithFallback(
              cartItem.product.tax,
            );
          } else {
            price = cartItem.product.finalPrice;
          }
          // Get variant ID from pre-fetched map (batch lookup)
          if (cartItem.variant != null) {
            final lookupKey = '${cartItem.product.id}:${cartItem.variant!.sku}';
            variantId = variantIdMap[lookupKey];
          }
        }
        lineTotal = price * cartItem.quantity;

        orderItemsData.add({
          'order_id': orderId,
          'product_id': cartItem.product.id,
          'variant_id': variantId,
          'measurement_unit': measurementUnit,
          'name': name,
          'image': cartItem.product.imageUrl,
          'price': price,
          'quantity': cartItem.quantity,
          'size': cartItem.variant?.attributes['Size'],
          'color': cartItem.variant?.attributes['Color'],
          'category':
              cartItem.product.categories.isNotEmpty
                  ? cartItem.product.categories.first
                  : null,
        });

        // Prepare analytics row
        orderAnalyticsData.add({
          'product_id': cartItem.product.id,
          'order_id': orderId,
          'user_id': userId,
          'quantity': cartItem.quantity,
          'amount': lineTotal,
          'ordered_at': DateTime.now().toIso8601String(),
          'city': deliveryAddress.city,
          'area': deliveryAddress.city,
          'address': deliveryAddress.address,
        });
      }

      // Insert order items
      if (orderItemsData.isNotEmpty) {
        await _supabase.from('order_items').insert(orderItemsData);
      }

      // Insert product order analytics rows
      if (orderAnalyticsData.isNotEmpty) {
        await _supabase
            .from('product_order_analytics')
            .insert(orderAnalyticsData);
      }

      // Decrement stock for products and variants
      // NOTE: Actual stock decrement is now handled by a Postgres trigger
      // on the order_items table (see Supabase migrations:
      // 20251215000001_add_order_items_stock_triggers.sql).
      // This call is kept for compatibility but is effectively a no-op.
      await _decrementStock(processedCartItems);

      // Refresh product data in UI to show updated stock
      // This ensures products show as "out of stock" immediately after order
      try {
        // Refresh shared product provider (used by customer views)
        _ref.read(sharedProductProvider.notifier).refresh();

        // Refresh admin product controller (used by admin panel)
        // Use try-catch to handle case where admin controller might not be initialized
        try {
          _ref.read(adminProductControllerProvider.notifier).loadProducts();
        } catch (e) {
          // Admin controller might not be initialized if user is not admin
          // This is non-critical, just log for debugging
          if (kDebugMode) {
            print(
              '⚠️ OrderRepository: Could not refresh admin products (non-critical): $e',
            );
          }
        }

        if (kDebugMode) {
          print(
            '✅ OrderRepository: Refreshed product data after stock decrement',
          );
        }
      } catch (e) {
        // Don't fail order creation if refresh fails
        if (kDebugMode) {
          print(
            '⚠️ OrderRepository: Failed to refresh product data (non-critical): $e',
          );
        }
      }

      // Fetch complete order with items
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Failed to create order');
      }

      // Note: Order placed notification is automatically created by database trigger
      // No need to create it manually here

      return order;
    } catch (e) {
      if (kDebugMode) {
        print('Error in createOrder: $e');
      }
      rethrow;
    }
  }

  /// Validate products before creating order.
  /// Cart operations no longer depend on stock quantities.
  /// Only checks if products are marked as out of stock by admin.
  Future<void> _validateStock(List<CartItem> cartItems) async {
    for (final cartItem in cartItems) {
      // Check if product exists and is not marked as out of stock
      final productResponse =
          await _supabase
              .from('products')
              .select('id, is_out_of_stock')
              .eq('id', cartItem.product.id)
              .maybeSingle();

      if (productResponse == null) {
        throw Exception('Product ${cartItem.product.id} not found');
      }

      // Check if product is marked as out of stock by admin
      final isOutOfStock = productResponse['is_out_of_stock'] as bool? ?? false;
      if (isOutOfStock) {
        throw Exception(
          'Product ${cartItem.product.name} is currently out of stock and cannot be ordered.',
        );
      }

      // Stock quantity checks are removed - cart can have unlimited quantities
      // The isOutOfStock flag is the only restriction
    }
  }

  /// Decrement stock after order creation.
  ///
  /// NOTE: Stock is now decremented in the database via a Postgres trigger
  /// on the `order_items` table (see Supabase migrations). This method is
  /// intentionally a no-op and retained only for backwards compatibility.
  Future<void> _decrementStock(List<CartItem> cartItems) async {
    if (kDebugMode) {
      print(
        'ℹ️ _decrementStock called but stock is handled by database trigger on order_items.',
      );
    }
  }

  /// Get order by ID
  @override
  Future<Order?> getOrderById(String orderId) async {
    try {
      // Get order with nested order_items in a single query
      final orderResponse =
          await _supabase
              .from('orders')
              .select('*, order_items(*, products(categories))')
              .eq('id', orderId)
              .maybeSingle();

      if (orderResponse == null) return null;

      return await _convertSupabaseToOrder(
        orderResponse,
        null, // null indicates nested structure is used
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in getOrderById: $e');
      }
      return null;
    }
  }

  /// Get all orders for current user
  @override
  Future<List<Order>> getUserOrders({int page = 1, int limit = 50}) async {
    try {
      // Get user ID from Supabase session directly (more reliable than auth state)
      final user = _supabase.auth.currentUser;
      if (user == null || user.id.isEmpty) {
        if (kDebugMode) {
          print('getUserOrders: No authenticated user in session');
        }
        return [];
      }
      final userId = user.id;

      if (kDebugMode) {
        print('getUserOrders: Fetching orders for user_id: $userId');
      }

      // Get orders with nested order_items in a single query (optimized - no N+1)
      final startIndex = (page - 1) * limit;
      final ordersResponse = await _supabase
          .from('orders')
          .select('*, order_items(*, products(categories))')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final ordersData = List<Map<String, dynamic>>.from(ordersResponse);
      final orders = <Order>[];

      for (final orderData in ordersData) {
        final order = await _convertSupabaseToOrder(orderData, null);
        if (order != null) {
          orders.add(order);
        } else {
          if (kDebugMode) {
            print('Warning: Order ${orderData['id']} conversion returned null');
            print('Order data keys: ${orderData.keys}');
            final nestedItems = orderData['order_items'];
            if (nestedItems is List) {
              print('Order items count: ${nestedItems.length}');
              if (nestedItems.isNotEmpty) {
                print('First order item: ${nestedItems.first}');
              }
            }
          }
        }
      }

      if (kDebugMode) {
        print(
          'getUserOrders: Found ${ordersData.length} orders for user_id $userId, successfully converted ${orders.length}',
        );
      }

      return orders;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getUserOrders: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    }
  }

  /// Get all orders (admin only)
  @override
  Future<List<Order>> getAllOrders({
    int page = 1,
    int limit = 50,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase
          .from('orders')
          .select('*, order_items(*, products(categories))');

      // Use a very large range if limit is large to simulate "all orders"
      // or respect the pagination params
      final startIndex = (page - 1) * limit;
      final ordersResponse = await query
          .order('updated_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final ordersData = List<Map<String, dynamic>>.from(ordersResponse);
      final orders = <Order>[];

      for (final orderData in ordersData) {
        final order = await _convertSupabaseToOrder(orderData, null);
        if (order != null) {
          orders.add(order);
        }
      }

      return orders;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getAllOrders: $e');
      }
      return [];
    }
  }

  /// Get orders by customer ID (admin only)
  Future<List<Order>> getOrdersByCustomer(
    String customerId, {
    int page = 1,
    int limit = 50,
    String? searchQuery,
  }) async {
    try {
      final startIndex = (page - 1) * limit;
      var query = _supabase
          .from('orders')
          .select('*, order_items(*, products(categories))')
          .eq('user_id', customerId);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'order_number.ilike.%$searchQuery%,delivery_address->>name.ilike.%$searchQuery%,delivery_address->>alias.ilike.%$searchQuery%,delivery_address->>phone.ilike.%$searchQuery%',
        );
      }

      final ordersResponse = await query
          .order('updated_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final ordersData = List<Map<String, dynamic>>.from(ordersResponse);
      final orders = <Order>[];

      for (final orderData in ordersData) {
        final order = await _convertSupabaseToOrder(orderData, null);
        if (order != null) {
          orders.add(order);
        }
      }

      return orders;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getOrdersByCustomer: $e');
      }
      return [];
    }
  }

  /// Update order status
  /// Returns null on success to avoid expensive full order fetch.
  /// Callers should use optimistic updates with existing order data.
  /// Throws exception on failure so callers can handle errors.
  @override
  Future<Order?> updateOrderStatus(String orderId, OrderStatus status) async {
    final statusString = _orderStatusToString(status);

    if (kDebugMode) {
      print('🔄 OrderRepository: Updating order status');
      print('   Order ID: $orderId');
      print('   New Status: $status (string: "$statusString")');
    }

    // First, get the current order to check old status and user_id
    final currentOrderResponse =
        await _supabase
            .from('orders')
            .select('id, status, user_id, order_number')
            .eq('id', orderId)
            .single();

    final oldStatus = currentOrderResponse['status'] as String?;
    final userId = currentOrderResponse['user_id'] as String?;
    final orderNumber = currentOrderResponse['order_number'] as String?;

    if (kDebugMode) {
      print('   Old Status: $oldStatus');
      print('   User ID: $userId');
      print('   Order Number: $orderNumber');
    }

    // Update the order status
    final response =
        await _supabase
            .from('orders')
            .update({'status': statusString})
            .eq('id', orderId)
            .select();

    // Check if update succeeded (response contains updated rows)
    if (response.isEmpty) {
      if (kDebugMode) {
        print(
          '⚠️ OrderRepository: No rows updated - order might not exist or already has this status',
        );
      }
      // No rows updated - order might not exist or already has this status
      // Return null to indicate success (real-time subscription will sync correct state)
      // Callers using optimistic updates will have already updated UI
      return null;
    }

    if (kDebugMode) {
      print('✅ OrderRepository: Order status updated successfully');
      print('   Database trigger should create notification automatically');
    }

    // BACKUP: Create notification at application level if trigger fails
    // This ensures notifications are created even if database trigger has issues
    // We wait a moment to let the trigger execute first, then check if notification exists
    if (userId != null && oldStatus != statusString) {
      // Wait a moment for trigger to execute
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        // Check if notification was already created by trigger
        final existingNotifications = await _supabase
            .from('user_notifications')
            .select('id')
            .eq('order_id', orderId)
            .eq('type', 'order_status_changed')
            .gte(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(minutes: 1))
                  .toIso8601String(),
            )
            .limit(1);

        // Only create backup notification if trigger didn't create one
        if (existingNotifications.isEmpty) {
          if (kDebugMode) {
            print(
              '⚠️ OrderRepository: Trigger did not create notification, creating backup...',
            );
          }

          final notificationRepo = _ref.read(notificationRepositoryProvider);
          final statusLabel = _getStatusLabel(statusString);
          await notificationRepo.createNotification(
            userId: userId,
            type: NotificationType.orderStatusChanged,
            title: 'Order Status Updated',
            message:
                'Your order ${orderNumber ?? orderId} status has been updated to: $statusLabel',
            orderId: orderId,
          );

          if (kDebugMode) {
            print('✅ OrderRepository: Backup notification created');
          }
        } else {
          if (kDebugMode) {
            print('✅ OrderRepository: Notification already created by trigger');
          }
        }

        // Send FCM notification to admin users
        // This runs asynchronously and doesn't block the order update
        _sendFcmNotificationToAdmin(
          orderId: orderId,
          orderNumber: orderNumber ?? orderId,
          status: statusString,
        );

        // Send FCM notification to user (if user_id is available)
        _sendFcmNotificationToUser(
          userId: userId,
          orderId: orderId,
          orderNumber: orderNumber ?? orderId,
          status: statusString,
        );
      } catch (e) {
        // Don't fail the order update if notification creation fails
        // The database trigger should handle it, this is just a backup
        if (kDebugMode) {
          print(
            '⚠️ OrderRepository: Failed to create backup notification (non-critical): $e',
          );
          print('   Database trigger should still create the notification');
        }
      }
    }

    // Return null on success - controller handles optimistic updates
    // This avoids expensive getOrderById() call that fetches full order with items
    // Real-time subscription will automatically sync the updated order data
    return null;
  }

  /// Send FCM notification to admin users (fire-and-forget)
  Future<void> _sendFcmNotificationToAdmin({
    required String orderId,
    required String orderNumber,
    required String status,
  }) async {
    // Fire-and-forget: don't await, run in background
    // This prevents blocking the order update flow
    Future.microtask(() async {
      try {
        final functionUrl =
            '${Environment.supabaseUrl}/functions/v1/send-admin-fcm-notification';
        final statusLabel = _getStatusLabel(status);

        final payload = <String, dynamic>{
          'type': 'order_status_changed',
          'title': 'Order Status Updated',
          'message': 'Order #$orderNumber status changed to: $statusLabel',
          'order_id': orderId,
          'order_number': orderNumber,
        };

        // Use Supabase client's built-in HTTP functionality
        final response = await _supabase.functions.invoke(
          'send-admin-fcm-notification',
          body: payload,
        );

        if (kDebugMode) {
          if (response.status == 200) {
            print('✅ OrderRepository: FCM notification sent to admin');
          } else {
            print(
              '⚠️ OrderRepository: FCM notification failed with status: ${response.status}',
            );
          }
        }
      } catch (e) {
        // Silent fail - FCM notification is not critical
        if (kDebugMode) {
          print(
            '⚠️ OrderRepository: Error sending FCM notification (non-critical): $e',
          );
        }
      }
    });
  }

  /// Send FCM notification to user (fire-and-forget)
  Future<void> _sendFcmNotificationToUser({
    required String userId,
    required String orderId,
    required String orderNumber,
    required String status,
  }) async {
    // Fire-and-forget: don't await, run in background
    // This prevents blocking the order update flow
    Future.microtask(() async {
      try {
        final statusLabel = _getStatusLabel(status);

        final payload = <String, dynamic>{
          'type': 'order_status_changed',
          'title': 'Order Status Updated',
          'message': 'Your order #$orderNumber status changed to: $statusLabel',
          'order_id': orderId,
          'order_number': orderNumber,
          'user_id': userId, // Send to specific user
        };

        // Use Supabase client's built-in HTTP functionality
        final response = await _supabase.functions.invoke(
          'send-user-fcm-notification',
          body: payload,
        );

        if (kDebugMode) {
          if (response.status == 200) {
            print('✅ OrderRepository: FCM notification sent to user');
          } else {
            print(
              '⚠️ OrderRepository: User FCM notification failed with status: ${response.status}',
            );
          }
        }
      } catch (e) {
        // Silent fail - FCM notification is not critical
        if (kDebugMode) {
          print(
            '⚠️ OrderRepository: Error sending user FCM notification (non-critical): $e',
          );
        }
      }
    });
  }

  /// Helper method to get status label for notifications
  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Accepted';
      case 'processing':
        return 'Order Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  /// Update order tracking number
  Future<Order?> updateOrderTracking(
    String orderId,
    String trackingNumber,
  ) async {
    try {
      await _supabase
          .from('orders')
          .update({'tracking_number': trackingNumber})
          .eq('id', orderId);

      return await getOrderById(orderId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateOrderTracking: $e');
      }
      return null;
    }
  }

  @override
  Future<Order?> updateOrderDeliveryAddress(
    String orderId,
    OrderAddress address,
  ) async {
    try {
      final deliveryAddressJson = {
        'name': address.name,
        'phone': address.phone,
        'address': address.address,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
        if (address.alias != null) 'alias': address.alias,
        if (address.shopPhotoUrl != null) 'shopPhotoUrl': address.shopPhotoUrl,
      };

      await _supabase
          .from('orders')
          .update({
            'delivery_address': deliveryAddressJson,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      return await getOrderById(orderId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateOrderDeliveryAddress: $e');
      }
      return null;
    }
  }

  @override
  Future<Order?> updateOrderDetails({
    required String orderId,
    required OrderAddress deliveryAddress,
    required double shipping,
    double oldDue = 0.0,
  }) async {
    try {
      // Get current order to calculate new total and handle notes
      final currentOrderResponse =
          await _supabase.from('orders').select('*').eq('id', orderId).single();

      final currentSubtotal =
          (currentOrderResponse['subtotal'] as num?)?.toDouble() ?? 0.0;
      final currentTax =
          (currentOrderResponse['tax'] as num?)?.toDouble() ?? 0.0;
      final currentNotes = currentOrderResponse['notes'] as String? ?? '';

      // Calculate new total including Old Due
      final newTotal = currentSubtotal + shipping + currentTax + oldDue;

      // Handle Old Due in notes
      // Remove existing Old Due entry to avoid duplication
      var updatedNotes =
          currentNotes
              .replaceAll(RegExp(r'\n?Old Due: (?:₹|Rs )[\d\.]+'), '')
              .trim();

      // Append new Old Due if > 0
      if (oldDue > 0) {
        updatedNotes =
            '$updatedNotes\nOld Due: Rs ${oldDue.toStringAsFixed(2)}'.trim();
      }

      final deliveryAddressJson = {
        'name': deliveryAddress.name,
        'phone': deliveryAddress.phone,
        'address': deliveryAddress.address,
        'city': deliveryAddress.city,
        'state': deliveryAddress.state,
        'pincode': deliveryAddress.pincode,
        if (deliveryAddress.alias != null) 'alias': deliveryAddress.alias,
        if (deliveryAddress.shopPhotoUrl != null)
          'shopPhotoUrl': deliveryAddress.shopPhotoUrl,
      };

      await _supabase
          .from('orders')
          .update({
            'delivery_address': deliveryAddressJson,
            'shipping': shipping,
            'total': newTotal,
            'notes': updatedNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      return await getOrderById(orderId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateOrderDetails: $e');
      }
      return null;
    }
  }

  /// Get summary metrics for orders (optimized for dashboard)
  @override
  Future<Map<String, dynamic>> getOrderMetrics() async {
    try {
      // Fetch only necessary columns for all orders to calculate metrics
      // This is much faster than fetching full Order objects with items
      final response = await _supabase
          .from('orders')
          .select('total, status, delivery_address');

      final data = List<Map<String, dynamic>>.from(response);

      // Filter out Saikiran from metrics (replicate business logic)
      final filteredData =
          data.where((order) {
            final address = order['delivery_address'];
            if (address == null) return true;

            String name = '';
            if (address is Map) {
              name = (address['name'] ?? '').toString().toLowerCase();
            } else if (address is String) {
              try {
                final decoded = Map<String, dynamic>.from(jsonDecode(address));
                name = (decoded['name'] ?? '').toString().toLowerCase();
              } catch (_) {}
            }
            return !name.contains('saikiran');
          }).toList();

      final totalOrders = filteredData.length;
      final totalRevenue = filteredData
          .where(
            (order) =>
                order['status'] != 'processing' &&
                order['status'] != 'cancelled',
          )
          .fold<double>(
            0.0,
            (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0.0),
          );

      final pendingOrders =
          filteredData.where((order) => order['status'] == 'processing').length;

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'pendingOrders': pendingOrders,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in getOrderMetrics: $e');
      }
      return {'totalOrders': 0, 'totalRevenue': 0.0, 'pendingOrders': 0};
    }
  }

  /// Subscribe to real-time order changes for a user
  Stream<List<Order>> watchUserOrders(String userId) {
    final controller = StreamController<List<Order>>();

    // Initial fetch
    getUserOrders()
        .then((orders) {
          if (!controller.isClosed) {
            controller.add(orders);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });

    // Subscribe to real-time changes
    final subscription = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
          (data) {
            // SOCKET OPTIMIZATION: Process in microtask to prevent blocking UI thread
            scheduleMicrotask(() async {
              try {
                if (data.isEmpty) {
                  return;
                }

                // Batch fetch all order_items for all orders in a single query (optimized - no N+1)
                final orderIds =
                    data.map((order) => order['id'] as String).toList();

                final orderItemsResponse = await _supabase
                    .from('order_items')
                    .select('*, products(categories)')
                    .inFilter('order_id', orderIds);

                final allOrderItems = List<Map<String, dynamic>>.from(
                  orderItemsResponse,
                );

                // Group order items by order_id
                final orderItemsMap = <String, List<Map<String, dynamic>>>{};
                for (final item in allOrderItems) {
                  final orderId = item['order_id'] as String;
                  orderItemsMap.putIfAbsent(orderId, () => []).add(item);
                }

                final orders = <Order>[];
                for (final orderData in data) {
                  final orderId = orderData['id'] as String;
                  final orderItemsForOrder = orderItemsMap[orderId] ?? [];

                  try {
                    final order = await _convertSupabaseToOrder(
                      orderData,
                      orderItemsForOrder,
                    );
                    if (order != null) {
                      orders.add(order);
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error converting order in stream: $e');
                    }
                  }
                }

                // Sort by order date descending (most recent first)
                orders.sort((a, b) {
                  return b.orderDate.compareTo(a.orderDate);
                });

                if (!controller.isClosed) {
                  controller.add(orders);
                }
              } catch (e) {
                if (!controller.isClosed) {
                  controller.addError(e);
                }
              }
            });
          },
          onError: (error) {
            // Log error but don't crash the stream if it's a realtime connection error
            if (kDebugMode) {
              print('Supabase Realtime Error (All Orders): $error');
            }
            // Suppress error to keep UI stable
          },
        );

    // Cancel subscription when stream is closed
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Subscribe to real-time order changes for admin (all orders)
  Stream<List<Order>> subscribeToAllOrders() {
    final controller = StreamController<List<Order>>();

    // Initial fetch
    getAllOrders()
        .then((orders) {
          if (!controller.isClosed) {
            controller.add(orders);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });

    // Subscribe to real-time changes
    final subscription = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
          (data) {
            // SOCKET OPTIMIZATION: Process in microtask to prevent blocking UI thread
            scheduleMicrotask(() async {
              try {
                if (data.isEmpty) {
                  return;
                }

                // Batch fetch all order_items for all orders in a single query (optimized - no N+1)
                final orderIds =
                    data.map((order) => order['id'] as String).toList();

                final orderItemsResponse = await _supabase
                    .from('order_items')
                    .select('*')
                    .inFilter('order_id', orderIds);

                final allOrderItems = List<Map<String, dynamic>>.from(
                  orderItemsResponse,
                );

                // Group order items by order_id
                final orderItemsMap = <String, List<Map<String, dynamic>>>{};
                for (final item in allOrderItems) {
                  final orderId = item['order_id'] as String;
                  orderItemsMap.putIfAbsent(orderId, () => []).add(item);
                }

                final orders = <Order>[];
                for (final orderData in data) {
                  final orderId = orderData['id'] as String;
                  final orderItemsForOrder = orderItemsMap[orderId] ?? [];

                  try {
                    final order = await _convertSupabaseToOrder(
                      orderData,
                      orderItemsForOrder,
                    );
                    if (order != null) {
                      orders.add(order);
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error converting order in stream: $e');
                    }
                  }
                }

                // Sort by order number descending
                orders.sort((a, b) {
                  final numericPartA = a.orderNumber.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final numericPartB = b.orderNumber.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final numA =
                      numericPartA.isNotEmpty
                          ? int.tryParse(numericPartA) ?? 0
                          : 0;
                  final numB =
                      numericPartB.isNotEmpty
                          ? int.tryParse(numericPartB) ?? 0
                          : 0;
                  return numB.compareTo(numA);
                });

                if (!controller.isClosed) {
                  controller.add(orders);
                }
              } catch (e) {
                if (!controller.isClosed) {
                  controller.addError(e);
                }
              }
            });
          },
          onError: (error) {
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );

    // Cancel subscription when stream is closed
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Convert Supabase order data to Order object
  /// Handles both nested order_items structure (from nested select) and flat structure (for backward compatibility)
  Future<Order?> _convertSupabaseToOrder(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>>? orderItemsData,
  ) async {
    try {
      final orderId = orderData['id'] as String;
      final orderNumber = orderData['order_number'] as String? ?? '';
      final statusString = orderData['status'] as String? ?? 'confirmed';
      final status = _stringToOrderStatus(statusString);

      // Parse delivery address from JSONB
      final deliveryAddressJson =
          orderData['delivery_address'] as Map<String, dynamic>?;

      // FALLBACK: If delivery_address is missing, provide a placeholder instead of hiding the order
      final effectiveAddressJson =
          deliveryAddressJson ??
          {
            'name': 'Unknown (Missing Address)',
            'phone': '',
            'address': 'Address data missing in database',
            'city': '',
            'state': '',
            'pincode': '',
          };

      final shopPhotoUrlFromJson =
          effectiveAddressJson['shopPhotoUrl'] as String?;

      if (kDebugMode) {
        print('📖 Parsing delivery_address from JSONB for order $orderId:');
        print('   shopPhotoUrl from JSON: ${shopPhotoUrlFromJson ?? 'null'}');
        print(
          '   shopPhotoUrl is empty: ${shopPhotoUrlFromJson?.isEmpty ?? true}',
        );
        if (shopPhotoUrlFromJson != null) {
          print('   shopPhotoUrl length: ${shopPhotoUrlFromJson.length}');
        }
      }

      // Parse coordinates from notes
      final notes = orderData['notes'] as String?;
      final coordinates = _parseCoordinatesFromNotes(notes);
      final latitude = coordinates?['latitude'];
      final longitude = coordinates?['longitude'];

      if (kDebugMode && coordinates != null) {
        print(
          '📍 Parsed coordinates from notes: Lat $latitude, Lng $longitude',
        );
      }

      final deliveryAddress = OrderAddress(
        name: effectiveAddressJson['name'] as String? ?? 'Unknown',
        phone: effectiveAddressJson['phone'] as String? ?? '',
        address: effectiveAddressJson['address'] as String? ?? '',
        city: effectiveAddressJson['city'] as String? ?? '',
        state: effectiveAddressJson['state'] as String? ?? '',
        pincode: effectiveAddressJson['pincode'] as String? ?? '',
        alias: effectiveAddressJson['alias'] as String?,
        shopPhotoUrl: shopPhotoUrlFromJson,
        latitude: latitude,
        longitude: longitude,
      );

      if (kDebugMode) {
        print(
          '✅ OrderAddress created with shopPhotoUrl: ${deliveryAddress.shopPhotoUrl ?? 'null'}',
        );
      }

      // Parse order items - handle both nested and flat structures
      List<Map<String, dynamic>> itemsToProcess;

      // Check if order_items are nested in orderData (from nested select)
      if (orderData.containsKey('order_items') && orderItemsData == null) {
        final nestedItems = orderData['order_items'];
        if (nestedItems is List) {
          itemsToProcess = List<Map<String, dynamic>>.from(nestedItems);
        } else {
          itemsToProcess = [];
        }
      } else {
        // Use provided orderItemsData (flat structure)
        itemsToProcess = orderItemsData ?? [];
      }

      final orderItems =
          itemsToProcess.map((itemData) {
            // Resolve category: use stored category, fallback to product category
            String? category = itemData['category'] as String?;
            if (category == null) {
              final productData = itemData['products'];
              if (productData != null && productData is Map) {
                final categories = productData['categories'];
                if (categories != null &&
                    categories is List &&
                    categories.isNotEmpty) {
                  category = categories.first.toString();
                }
              }
            }

            return OrderItem(
              id: itemData['product_id'] as String? ?? '',
              name: itemData['name'] as String? ?? '',
              image: itemData['image'] as String? ?? '',
              price: (itemData['price'] as num?)?.toDouble() ?? 0.0,
              quantity: itemData['quantity'] as int? ?? 0,
              size: itemData['size'] as String?,
              color: itemData['color'] as String?,
              category: category,
              variantId: itemData['variant_id'] as String?,
            );
          }).toList();

      // Parse dates
      final createdAtString = orderData['created_at'] as String?;
      final orderDate =
          createdAtString != null
              ? DateTime.parse(createdAtString).toLocal()
              : DateTime.now();

      final estimatedDeliveryString =
          orderData['estimated_delivery'] as String?;
      final estimatedDelivery =
          estimatedDeliveryString != null
              ? DateTime.parse(estimatedDeliveryString).toLocal()
              : null;

      final updatedAtString = orderData['updated_at'] as String?;
      final updatedAt =
          updatedAtString != null
              ? DateTime.parse(updatedAtString).toLocal()
              : null;

      // Get order_tag from the database, fall back to order_number if not present
      final orderTag = orderData['order_tag'] as String? ?? orderNumber;

      return Order(
        id: orderId,
        orderTag: orderTag,
        orderNumber: orderNumber,
        orderDate: orderDate,
        status: status,
        items: orderItems,
        deliveryAddress: deliveryAddress,
        subtotal: (orderData['subtotal'] as num?)?.toDouble() ?? 0.0,
        shipping: (orderData['shipping'] as num?)?.toDouble() ?? 0.0,
        tax: (orderData['tax'] as num?)?.toDouble() ?? 0.0,
        total: (orderData['total'] as num?)?.toDouble() ?? 0.0,
        trackingNumber: orderData['tracking_number'] as String?,
        estimatedDelivery: estimatedDelivery,
        notes: orderData['notes'] as String?,
        userId: orderData['user_id'] as String?,
        updatedAt: updatedAt,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error converting order ${orderData['id']}: $e');
        print('Stack trace: $stackTrace');
        print('Order data: $orderData');
        print('Order items data: $orderItemsData');
      }
      return null;
    }
  }

  /// Convert OrderStatus enum to string
  String _orderStatusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.shipped:
      case OrderStatus.delivered:
        return 'processing'; // Map removed statuses to processing
    }
  }

  /// Convert string to OrderStatus enum
  OrderStatus _stringToOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
      case 'shipped':
      case 'delivered':
        return OrderStatus.processing; // Map removed statuses to processing
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.confirmed;
    }
  }

  /// Get orders dashboard metrics
  Future<Map<String, dynamic>> getOrdersDashboardMetrics() async {
    try {
      // Get total orders count - fetch only IDs for efficiency
      final totalOrdersResponse = await _supabase.from('orders').select('id');
      final totalOrders = totalOrdersResponse.length;

      // Get open orders count (processing only)
      final openOrdersResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('status', 'processing');
      final openOrders = openOrdersResponse.length;

      // Get order value received (sum of all converted order totals, excluding processing and cancelled)
      // Now only confirmed orders count as received since shipped/delivered are removed
      final ordersResponse = await _supabase
          .from('orders')
          .select('total')
          .eq('status', 'confirmed');
      final ordersData = List<Map<String, dynamic>>.from(ordersResponse);
      final orderValueReceived = ordersData.fold<double>(
        0.0,
        (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0.0),
      );

      return {
        'totalOrders': totalOrders,
        'openOrders': openOrders,
        'orderValueReceived': orderValueReceived,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting orders dashboard metrics: $e');
      }
      rethrow;
    }
  }

  /// Get open orders (processing status only)
  Future<List<Order>> getOpenOrders({
    int page = 1,
    int limit = 50,
    String? searchQuery,
  }) async {
    try {
      final startIndex = (page - 1) * limit;
      var query = _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('status', 'processing');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'order_number.ilike.%$searchQuery%,delivery_address->>name.ilike.%$searchQuery%,delivery_address->>alias.ilike.%$searchQuery%',
        );
      }

      final ordersResponse = await query
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final ordersData = List<Map<String, dynamic>>.from(ordersResponse);
      final orders = <Order>[];

      for (final orderData in ordersData) {
        final order = await _convertSupabaseToOrder(orderData, null);
        if (order != null) {
          orders.add(order);
        }
      }

      return orders;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting open orders: $e');
      }
      return [];
    }
  }

  /// Update order items (admin only, before shipping)
  @override
  Future<Order?> updateOrderItems(String orderId, List<OrderItem> items) async {
    try {
      // Validate items are not empty
      if (items.isEmpty) {
        throw Exception('Order must have at least one item');
      }

      // Get current order to validate status and get shipping/tax info
      final currentOrderResponse =
          await _supabase
              .from('orders')
              .select('*')
              .eq('id', orderId)
              .maybeSingle();

      if (currentOrderResponse == null) {
        throw Exception('Order not found');
      }

      final currentStatus = currentOrderResponse['status'] as String? ?? '';

      // Validate order status - only allow modification before shipping
      if (currentStatus != 'confirmed' && currentStatus != 'processing') {
        throw Exception(
          'Cannot modify order items after order has been shipped',
        );
      }

      // Validate all products exist and are not out of stock
      final productIds = items.map((item) => item.id).toSet().toList();
      final productsResponse = await _supabase
          .from('products')
          .select('id, is_out_of_stock, is_active')
          .inFilter('id', productIds);

      final productsData = List<Map<String, dynamic>>.from(productsResponse);
      final productsMap = <String, Map<String, dynamic>>{};
      for (final product in productsData) {
        productsMap[product['id'] as String] = product;
      }

      // Check all products exist
      for (final productId in productIds) {
        if (!productsMap.containsKey(productId)) {
          throw Exception('Product $productId not found');
        }
        final product = productsMap[productId]!;
        final isOutOfStock = product['is_out_of_stock'] as bool? ?? false;
        final isActive = product['is_active'] as bool? ?? true;

        if (isOutOfStock) {
          throw Exception(
            'Product ${items.firstWhere((item) => item.id == productId).name} is out of stock',
          );
        }
        if (!isActive) {
          throw Exception(
            'Product ${items.firstWhere((item) => item.id == productId).name} is not active',
          );
        }
      }

      // Validate quantities
      for (final item in items) {
        if (item.quantity <= 0) {
          throw Exception('Quantity must be greater than 0 for ${item.name}');
        }
      }

      // Get current shipping and tax from order
      final currentShipping =
          (currentOrderResponse['shipping'] as num?)?.toDouble() ?? 0.0;
      final currentTax =
          (currentOrderResponse['tax'] as num?)?.toDouble() ?? 0.0;

      // Calculate new subtotal from items
      final newSubtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      // Calculate new total
      final newTotal = newSubtotal + currentShipping + currentTax;

      // Delete existing order_items
      await _supabase.from('order_items').delete().eq('order_id', orderId);

      // Look up variant IDs for items that have SKU but no variantId
      final itemsWithSku =
          items.where((i) => i.variantId == null && i.sku != null).toList();
      final variantMap =
          <String, String>{}; // key: '${productId}:${sku}', value: variantId

      if (itemsWithSku.isNotEmpty) {
        final productIds = itemsWithSku.map((i) => i.id).toSet().toList();
        final skus = itemsWithSku.map((i) => i.sku!).toSet().toList();

        final variantsResponse = await _supabase
            .from('product_variants')
            .select('id, product_id, sku')
            .inFilter('product_id', productIds)
            .inFilter('sku', skus);

        final variantsData = List<Map<String, dynamic>>.from(variantsResponse);
        for (final v in variantsData) {
          final key = '${v['product_id']}:${v['sku']}';
          variantMap[key] = v['id'] as String;
        }
      }

      // Prepare new order items data with merging
      final mergedItems =
          <
            String,
            Map<String, dynamic>
          >{}; // key: '${productId}:${variantId ?? ''}'

      for (final item in items) {
        String? variantId = item.variantId;
        // Try to lookup variantId if missing
        if (variantId == null && item.sku != null) {
          final key = '${item.id}:${item.sku}';
          variantId = variantMap[key];
        }

        // Create a unique key for merging (combining product + variant)
        final uniqueKey = '${item.id}:${variantId ?? ''}';

        if (mergedItems.containsKey(uniqueKey)) {
          final existing = mergedItems[uniqueKey]!;
          existing['quantity'] = (existing['quantity'] as int) + item.quantity;
        } else {
          mergedItems[uniqueKey] = {
            'order_id': orderId,
            'product_id': item.id,
            'variant_id': variantId,
            'measurement_unit': null,
            'name': item.name,
            'image': item.image,
            'price': item.price,
            'quantity': item.quantity,
            'size': item.size,
            'color': item.color,
            'category': item.category,
          };
        }
      }

      final orderItemsData = mergedItems.values.toList();

      // Insert new order items
      if (orderItemsData.isNotEmpty) {
        await _supabase.from('order_items').insert(orderItemsData);
      }

      // Update order with new totals
      // IMPORTANT: Do NOT update status - only update totals to preserve order status
      await _supabase
          .from('orders')
          .update({
            'subtotal': newSubtotal,
            'total': newTotal,
            'updated_at': DateTime.now().toIso8601String(),
            // NOTE: Status is intentionally NOT updated - it remains unchanged
          })
          .eq('id', orderId);

      // Fetch and return updated order
      return await getOrderById(orderId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateOrderItems: $e');
      }
      rethrow;
    }
  }

  /// Convert order to sale (update shipping, old due, and status to delivered)
  Future<Order?> convertOrderToSale({
    required String orderId,
    required double shippingPrice,
    double oldDue = 0.0,
    bool roundOff = false,
  }) async {
    try {
      // Get current order
      final currentOrderResponse =
          await _supabase.from('orders').select('*').eq('id', orderId).single();

      final currentSubtotal =
          (currentOrderResponse['subtotal'] as num?)?.toDouble() ?? 0.0;
      final currentTax =
          (currentOrderResponse['tax'] as num?)?.toDouble() ?? 0.0;

      // Calculate new total: subtotal + shipping + tax + oldDue
      var newTotal = currentSubtotal + shippingPrice + currentTax + oldDue;

      // Apply round off if requested
      if (roundOff) {
        newTotal = newTotal.roundToDouble();
      }

      // Update order with new shipping, total, and status
      // Store old due in notes field for reference
      final currentNotes = currentOrderResponse['notes'] as String? ?? '';

      // Remove existing Old Due entry to avoid duplication
      var updatedNotes =
          currentNotes
              .replaceAll(RegExp(r'\n?Old Due: (?:₹|Rs )[\d\.]+'), '')
              .trim();

      // Append new Old Due if > 0
      if (oldDue > 0) {
        updatedNotes =
            '$updatedNotes\nOld Due: Rs ${oldDue.toStringAsFixed(2)}'.trim();
      }

      final updatedOrderResponse =
          await _supabase
              .from('orders')
              .update({
                'shipping': shippingPrice,
                'total': newTotal,
                'status': 'confirmed',
                'notes': updatedNotes,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', orderId)
              .select('*, order_items(*)')
              .single();

      // Convert to Order object
      final order = await _convertSupabaseToOrder(updatedOrderResponse, null);
      return order;
    } catch (e) {
      if (kDebugMode) {
        print('Error converting order to sale: $e');
      }
      rethrow;
    }
  }

  @override
  Future<bool> deleteOrder(String orderId) async {
    try {
      await _supabase.from('order_items').delete().eq('order_id', orderId);
      await _supabase.from('orders').delete().eq('id', orderId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting order: $e');
      }
      return false;
    }
  }

  @override
  Stream<void> subscribeToUserOrders() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    // Create a stream controller for broadcasting updates
    final controller = StreamController<void>.broadcast();

    // Create unique channel name
    final channelName = 'public:orders:user_id=eq.${user.id}';

    // Subscribe to changes on orders table for this user
    final channel =
        _supabase
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: user.id,
              ),
              callback: (payload) {
                if (kDebugMode) {
                  print('🔔 Order update received: ${payload.eventType}');
                }
                controller.add(null);
              },
            )
            .subscribe();

    // Handle stream cancellation
    controller.onCancel = () async {
      await _supabase.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }
}
