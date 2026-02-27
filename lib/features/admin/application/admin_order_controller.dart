import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/shared_orders_provider.dart';
import '../../orders/data/order_repository_provider.dart';
import '../../orders/data/order_repository_supabase.dart';
import '../../cart/application/cart_controller.dart';
import '../data/payment_receipt_repository.dart';
import '../services/order_sound_service.dart';
import 'admin_customer_controller.dart';
import 'admin_notification_settings_provider.dart';
import '../../notifications/data/notification_repository_provider.dart';
import '../../notifications/data/notification_model.dart';

/// Payment status based on balance
enum PaymentStatus {
  unpaid, // No payment received (balance == total)
  partial, // Some payment received (0 < balance < total)
  used, // Fully paid (balance == 0)
}

/// Sort mode for orders
enum SortMode {
  newest, // Sort by order date (newest first)
  balanceDesc, // Sort by balance (highest first)
}

/// Order with payment metadata
class OrderWithPayment {
  final Order order;
  final double balanceAmount;
  final PaymentStatus paymentStatus;

  const OrderWithPayment({
    required this.order,
    required this.balanceAmount,
    required this.paymentStatus,
  });
}

/// Combined transaction item for unified sales/payments list
class TransactionItem {
  final String type; // 'sale' or 'payment'
  final Order? order;
  final PaymentReceipt? receipt;
  final int orderNumber;

  const TransactionItem({
    required this.type,
    this.order,
    this.receipt,
    required this.orderNumber,
  });
}

class AdminOrderState {
  final List<Order> orders;
  final List<Order> filteredOrders;
  final List<PaymentReceipt> receipts;
  final List<PaymentReceipt> filteredReceipts;
  final String searchQuery;
  final OrderStatus? selectedStatus;
  final PaymentStatus? selectedPaymentStatus;
  final String? selectedTransactionType;

  /// Current sort mode. Nullable to be resilient to older serialized state.
  final SortMode? sortMode;
  final String? customerId;
  final bool loading;
  final String? error;
  final Order? selectedOrder;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final double? minAmount;
  final double? maxAmount;
  final String? lastUpdatedOrderId;
  // Map of order ID to payment metadata
  final Map<String, OrderWithPayment> orderPaymentMap;
  // Combined list of sales and payments for unified display
  final List<TransactionItem> combinedTransactions;

  const AdminOrderState({
    this.orders = const [],
    this.filteredOrders = const [],
    this.receipts = const [],
    this.filteredReceipts = const [],
    this.searchQuery = '',
    this.selectedStatus,
    this.selectedPaymentStatus,
    this.selectedTransactionType,
    this.sortMode = SortMode.newest,
    this.customerId,
    this.loading = false,
    this.error,
    this.selectedOrder,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.minAmount,
    this.maxAmount,
    this.lastUpdatedOrderId,
    this.orderPaymentMap = const {},
    this.combinedTransactions = const [],
  });

  AdminOrderState copyWith({
    List<Order>? orders,
    List<Order>? filteredOrders,
    List<PaymentReceipt>? receipts,
    List<PaymentReceipt>? filteredReceipts,
    String? searchQuery,
    OrderStatus? selectedStatus,
    PaymentStatus? selectedPaymentStatus,
    String? selectedTransactionType,
    bool resetSelectedPaymentStatus = false,
    bool resetSelectedTransactionType = false,
    SortMode? sortMode,
    String? customerId,
    bool resetCustomerId = false,
    bool? loading,
    String? error,
    Order? selectedOrder,
    bool resetSelectedStatus = false,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    double? minAmount,
    double? maxAmount,
    bool resetDateRangeStart = false,
    bool resetDateRangeEnd = false,
    bool resetMinAmount = false,
    bool resetMaxAmount = false,
    String? lastUpdatedOrderId,
    bool resetLastUpdatedOrderId = false,
    Map<String, OrderWithPayment>? orderPaymentMap,
    List<TransactionItem>? combinedTransactions,
  }) => AdminOrderState(
    orders: orders ?? this.orders,
    filteredOrders: filteredOrders ?? this.filteredOrders,
    receipts: receipts ?? this.receipts,
    filteredReceipts: filteredReceipts ?? this.filteredReceipts,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedStatus:
        resetSelectedStatus ? null : (selectedStatus ?? this.selectedStatus),
    selectedPaymentStatus:
        resetSelectedPaymentStatus
            ? null
            : (selectedPaymentStatus ?? this.selectedPaymentStatus),
    selectedTransactionType:
        resetSelectedTransactionType
            ? null
            : (selectedTransactionType ?? this.selectedTransactionType),
    sortMode: sortMode ?? this.sortMode ?? SortMode.newest,
    customerId: resetCustomerId ? null : (customerId ?? this.customerId),
    loading: loading ?? this.loading,
    error: error,
    selectedOrder: selectedOrder ?? this.selectedOrder,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    dateRangeStart:
        resetDateRangeStart ? null : (dateRangeStart ?? this.dateRangeStart),
    dateRangeEnd:
        resetDateRangeEnd ? null : (dateRangeEnd ?? this.dateRangeEnd),
    minAmount: resetMinAmount ? null : (minAmount ?? this.minAmount),
    maxAmount: resetMaxAmount ? null : (maxAmount ?? this.maxAmount),
    lastUpdatedOrderId:
        resetLastUpdatedOrderId
            ? null
            : (lastUpdatedOrderId ?? this.lastUpdatedOrderId),
    orderPaymentMap: orderPaymentMap ?? this.orderPaymentMap,
    combinedTransactions: combinedTransactions ?? this.combinedTransactions,
  );
}

final adminOrderControllerProvider =
    StateNotifierProvider.autoDispose<AdminOrderController, AdminOrderState>(
      (ref) => AdminOrderController(ref),
    );

/// Provider to track the last time the admin viewed the orders list
final lastOrdersViewedTimeProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for unread orders count (actually Open Orders count)
final unreadOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final orders = ref.watch(adminOrderControllerProvider).orders;

  // Return count of open orders (only processing)
  // This ensures the badge reflects the number of active orders requiring attention
  try {
    return orders
        .where((order) => order.status == OrderStatus.processing)
        .length;
  } catch (_) {
    return 0;
  }
});

class AdminOrderController extends StateNotifier<AdminOrderState> {
  AdminOrderController(this._ref) : super(const AdminOrderState()) {
    // Lazy initialization - don't load data until explicitly requested
  }

  final Ref _ref;
  bool _isInitialized = false;
  static const String _lastViewedKey = 'admin_last_orders_viewed_time';

  // Timer for polling backup (in case stream fails)
  Timer? _pollingTimer;

  // Track known orders to detect new ones for sound notifications
  Set<String> _knownOrderIds = {};
  bool _isFirstOrderLoad = true;

  @override
  void dispose() {
    print('🗑️ AdminOrderController DISPOSED');
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Helper to check for new orders and play sound
  void _checkForNewOrdersAndPlaySound(List<Order> orders) {
    print(
      '📦 Checking for new orders. Total: ${orders.length}, First Load: $_isFirstOrderLoad',
    );

    final now = DateTime.now();
    bool playSound = false;
    final List<String> newOrderIdsToMark = [];
    final soundService = OrderSoundService();

    if (_isFirstOrderLoad) {
      // First load - populate known IDs
      _knownOrderIds = orders.map((o) => o.id).toSet();
      _isFirstOrderLoad = false;

      // Check for VERY recent pending orders (created < 60s ago)
      for (final order in orders) {
        if (order.status == OrderStatus.processing) {
          // Skip if we've already played sound for this order
          if (!soundService.shouldPlayForOrder(order.id)) continue;

          try {
            final diff = now.difference(order.orderDate).inSeconds.abs();
            if (diff < 60) {
              print(
                '🔔 First Load: Found FRESH order (${diff}s old): ${order.id}',
              );
              playSound = true;
              newOrderIdsToMark.add(order.id);
            }
          } catch (e) {
            print('Error checking order date for ${order.id}: $e');
          }
        }
      }
    } else {
      // Subsequent updates - check for new pending orders
      for (final order in orders) {
        // Only consider orders we haven't seen in this controller instance
        // OR orders that are processing and we haven't played sound for globally yet
        if (!_knownOrderIds.contains(order.id)) {
          if (order.status == OrderStatus.processing) {
            // Skip if we've already played sound for this order
            if (!soundService.shouldPlayForOrder(order.id)) continue;

            print(
              '🔔 AdminOrderController: New PROCESSING order found: ${order.id}',
            );
            playSound = true;
            newOrderIdsToMark.add(order.id);
          }
        }
      }

      _knownOrderIds = orders.map((o) => o.id).toSet();
    }

    if (playSound) {
      final isSoundEnabled = _ref.read(adminNotificationSettingsProvider);
      if (isSoundEnabled) {
        print('🔔🔔🔔 TRIGGERING SOUND NOW 🔔🔔🔔');
        soundService.playBuzzerSound();
        // Mark these orders as having triggered a sound
        for (final id in newOrderIdsToMark) {
          soundService.markOrderAsPlayed(id);
        }
      } else {
        print('🔕 Sound suppressed by admin setting');
      }
    }
  }

  /// Initialize admin order controller with real-time subscriptions (lazy loading support)
  Future<void> initialize() async {
    // Defer execution to avoid "modify provider during build" errors
    await Future.microtask(() {});

    print('AdminOrderController: initialize() called');
    try {
      // Check if already initialized - use explicit check to avoid null issues
      final currentInitState = _isInitialized;
      if (currentInitState == true) {
        print('AdminOrderController: Already initialized, skipping.');
        return;
      }

      _isInitialized = true;

      // Load last viewed time from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final lastViewedStr = prefs.getString(_lastViewedKey);
      if (lastViewedStr != null) {
        _ref.read(lastOrdersViewedTimeProvider.notifier).state = DateTime.parse(
          lastViewedStr,
        );
      } else {
        // If first time, set to current time so old orders don't show as new
        final now = DateTime.now();
        await prefs.setString(_lastViewedKey, now.toIso8601String());
        _ref.read(lastOrdersViewedTimeProvider.notifier).state = now;
      }

      // Initialize sound service
      await OrderSoundService().initialize();
      if (!mounted) return;

      await loadOrders();
      if (!mounted) return;
      _subscribeToAllOrders();

      // Start polling backup (every 10 seconds)
      _startPolling();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing AdminOrderController: $e');
      }
      _isInitialized = false; // Reset on error so it can be retried
      rethrow;
    }
  }

  /// Start polling for orders as a backup to real-time stream
  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll every 10 seconds to ensure new orders are caught even if stream disconnects
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Only poll if not loading to avoid stacking requests
      if (!state.loading) {
        if (kDebugMode) {
          print(
            '🔄 AdminOrderController: Polling for new orders (backup check)...',
          );
        }
        loadOrders(silent: true);
      }
    });
  }

  /// Load all orders from Supabase
  Future<void> loadOrders({bool silent = false}) async {
    // Defer execution to avoid "modify provider during build" errors
    await Future.microtask(() {});

    if (!mounted) return;

    final repository = _ref.read(orderRepositoryProvider);
    final paymentRepository = _ref.read(paymentReceiptRepositoryProvider);

    if (!silent) {
      if (mounted) {
        state = state.copyWith(loading: true, error: null, currentPage: 1);
      }
    }

    try {
      // Cast to OrderRepositorySupabase to access getAllOrders method
      if (repository is OrderRepositorySupabase) {
        final ordersFuture = repository.getAllOrders(
          page: 1,
          limit: 10000,
          searchQuery: state.searchQuery,
        );

        final receiptsFuture = paymentRepository.getAllPaymentReceipts(
          page: 1,
          limit: 10000,
          searchQuery: state.searchQuery,
        );

        final results = await Future.wait([ordersFuture, receiptsFuture]);
        if (!mounted) return;

        final orders = results[0] as List<Order>;
        // Sort by order number descending (higher numbers first)
        orders.sort((a, b) {
          final numA = _extractNumericPortionFromOrder(a) ?? 0;
          final numB = _extractNumericPortionFromOrder(b) ?? 0;
          return numB.compareTo(numA);
        });
        final receipts = results[1] as List<PaymentReceipt>;

        final hasMore = false; // Pagination disabled as per request

        // Compute payment metadata for all orders
        final paymentMap = await _computePaymentMetadata(orders);
        if (!mounted) return;

        // Check for new orders and play sound (works for manual refresh too)
        _checkForNewOrdersAndPlaySound(orders);

        // Calculate filtered data first
        final filterResult = _calculateFilteredData(
          orders: orders,
          receipts: receipts,
        );

        if (!mounted) return;

        try {
          state = state.copyWith(
            orders: orders,
            filteredOrders: filterResult.filteredOrders,
            receipts: receipts,
            filteredReceipts: filterResult.filteredReceipts,
            combinedTransactions: filterResult.combinedTransactions,
            loading: false,
            currentPage: 1,
            hasMore: hasMore,
            orderPaymentMap: paymentMap,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error updating state in loadOrders: $e');
          }
        }
      } else {
        if (!silent && mounted) {
          state = state.copyWith(
            loading: false,
            error: 'Order repository is not OrderRepositorySupabase',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading orders: $e');
      }
      if (!silent && mounted) {
        state = state.copyWith(
          loading: false,
          error: 'Failed to load orders: ${e.toString()}',
        );
      } else if (mounted) {
        state = state.copyWith(loading: false);
      }
    }
  }

  /// Load orders for a specific customer
  Future<void> loadOrdersForCustomer(
    String customerId, {
    bool silent = false,
  }) async {
    // Defer execution to avoid "modify provider during build" errors
    await Future.microtask(() {});

    if (!mounted) return;
    final repository = _ref.read(orderRepositoryProvider);
    final paymentRepository = _ref.read(paymentReceiptRepositoryProvider);

    if (!silent) {
      if (mounted) {
        state = state.copyWith(
          loading: true,
          error: null,
          currentPage: 1,
          customerId: customerId,
        );
      }
    } else {
      if (mounted) {
        state = state.copyWith(customerId: customerId);
      }
    }

    try {
      // Cast to OrderRepositorySupabase to access getOrdersByCustomer method
      if (repository is OrderRepositorySupabase) {
        final ordersFuture = repository.getOrdersByCustomer(
          customerId,
          page: 1,
          limit: 100,
        );

        final receiptsFuture = paymentRepository.getReceiptsByCustomer(
          customerId,
          page: 1,
          limit: 100,
        );

        final results = await Future.wait([ordersFuture, receiptsFuture]);
        if (!mounted) return;

        final orders = results[0] as List<Order>;
        final receipts = results[1] as List<PaymentReceipt>;

        final hasMore = orders.length == 100 || receipts.length == 100;

        // Compute payment metadata
        final paymentMap = await _computePaymentMetadata(orders);
        if (!mounted) return;

        // Calculate filtered data first
        final filterResult = _calculateFilteredData(
          orders: orders,
          receipts: receipts,
        );

        if (!mounted) return;

        try {
          state = state.copyWith(
            orders: orders,
            filteredOrders: filterResult.filteredOrders,
            receipts: receipts,
            filteredReceipts: filterResult.filteredReceipts,
            combinedTransactions: filterResult.combinedTransactions,
            loading: false,
            currentPage: 1,
            hasMore: hasMore,
            orderPaymentMap: paymentMap,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error updating state in loadOrdersForCustomer: $e');
          }
        }
      } else {
        if (mounted) {
          state = state.copyWith(
            loading: false,
            error: 'Order repository is not OrderRepositorySupabase',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading customer orders: $e');
      }
      if (mounted) {
        state = state.copyWith(
          loading: false,
          error: 'Failed to load customer orders: ${e.toString()}',
        );
      }
    }
  }

  /// Create a new order manually
  Future<bool> createOrder({
    required List<CartItem> cartItems,
    required OrderAddress deliveryAddress,
    required double subtotal,
    required double shipping,
    required double tax,
    required double total,
    String? notes,
    String? userId,
    OrderStatus status = OrderStatus.processing,
    double oldDue = 0.0,
  }) async {
    if (!mounted) return false;
    final repository = _ref.read(orderRepositoryProvider);
    state = state.copyWith(loading: true, error: null);

    try {
      final createdOrder = await repository.createOrder(
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        subtotal: subtotal,
        shipping: shipping,
        tax: tax,
        total: total,
        notes: notes,
        userId: userId,
        // Admin created orders can have status specified (defaults to processing)
        status: status,
        oldDue: oldDue,
      );

      if (!mounted) return false;

      // Mark this order as played so it doesn't trigger a sound for the admin who just created it
      OrderSoundService().markOrderAsPlayed(createdOrder.id);

      // Trigger background tasks without awaiting them to speed up UI redirection
      _performPostOrderCreationTasks(createdOrder, userId);

      if (mounted) {
        state = state.copyWith(loading: false);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating order: $e');
      }
      if (mounted) {
        state = state.copyWith(
          loading: false,
          error: 'Failed to create order: ${e.toString()}',
        );
      }
      return false;
    }
  }

  /// Perform background tasks after order creation without blocking the UI
  void _performPostOrderCreationTasks(Order createdOrder, String? userId) {
    // 1. Refresh orders in background (silently)
    loadOrders(silent: true).catchError((e) {
      if (kDebugMode) print('Error refreshing orders in background: $e');
    });

    // 2. Refresh customer list to update balances (silently)
    _ref
        .read(adminCustomerControllerProvider.notifier)
        .refresh(silent: true)
        .catchError((e) {
          if (kDebugMode) print('Note: Could not refresh customer list: $e');
        });

    // 3. Send notifications in background
    _sendOrderNotifications(createdOrder, userId).catchError((e) {
      if (kDebugMode) print('Warning: Failed to send notifications: $e');
    });

    // 4. Mark new order as recently updated to force top placement
    markOrderRecentlyUpdated(createdOrder.id);
  }

  /// Send notifications for a new order
  Future<void> _sendOrderNotifications(Order order, String? userId) async {
    try {
      final notificationService = FcmNotificationService();
      final orderNumber = order.orderNumber;
      final orderId = order.id;

      // Send to user
      if (userId != null) {
        // First, create database notification for user
        // This will trigger the FCM push notification trigger automatically
        try {
          final notificationRepo = _ref.read(notificationRepositoryProvider);
          await notificationRepo.createNotification(
            userId: userId,
            type: NotificationType.orderPlaced,
            title: 'Order Placed Successfully',
            message: 'Your order #$orderNumber has been placed and confirmed.',
            orderId: orderId,
          );
          if (kDebugMode) {
            print('✅ AdminOrderController: Database notification created for user $userId');
          }
        } catch (e) {
          // Log error but don't fail - database trigger might have already created it
          if (kDebugMode) {
            print('⚠️ AdminOrderController: Failed to create database notification for user (may already exist): $e');
          }
        }

        // Also send FCM directly as backup (in case database trigger fails)
        try {
          await notificationService.sendUserNotification(
            userId: userId,
            type: 'order_created',
            title: 'Order Placed Successfully',
            message: 'Your order #$orderNumber has been placed and confirmed.',
            orderId: orderId,
            orderNumber: orderNumber,
          );
          if (kDebugMode) {
            print('✅ AdminOrderController: Direct FCM notification sent to user $userId');
          }
        } catch (e) {
          // Log error but don't fail - database trigger should handle it
          if (kDebugMode) {
            print('⚠️ AdminOrderController: Failed to send direct FCM to user (database trigger should handle it): $e');
          }
        }
      }

      // Send to admin
      try {
        await notificationService.sendAdminNotification(
          type: 'new_order',
          title: 'New Order Received',
          message: 'New order #$orderNumber has been placed and confirmed.',
          orderId: orderId,
          orderNumber: orderNumber,
        );
        if (kDebugMode) {
          print('✅ AdminOrderController: FCM notification sent to admin');
        }
      } catch (e) {
        // Log error but don't fail order creation
        if (kDebugMode) {
          print('⚠️ AdminOrderController: Failed to send FCM to admin (non-critical): $e');
        }
      }
    } catch (e) {
      // Log error but don't fail order creation - notifications are not critical
      if (kDebugMode) {
        print('⚠️ AdminOrderController: Error in _sendOrderNotifications (non-critical): $e');
      }
      // Don't rethrow - notification failures shouldn't break order creation
    }
  }

  /// Load more orders (pagination) - Disabled
  Future<void> loadMoreOrders() async {
    return; // Pagination disabled
  }

  /// Compute payment metadata for a list of orders
  Future<Map<String, OrderWithPayment>> _computePaymentMetadata(
    List<Order> orders,
  ) async {
    if (orders.isEmpty) return {};

    try {
      final paymentRepo = _ref.read(paymentReceiptRepositoryProvider);
      // Batch fetch all payment totals
      final paidByOrder = await paymentRepo.getTotalPaidForAllOrders();

      final paymentMap = <String, OrderWithPayment>{};
      for (final order in orders) {
        final totalPaid = paidByOrder[order.id] ?? 0.0;
        final effectiveTotal = order.total;
        final balance = (effectiveTotal - totalPaid).clamp(0.0, effectiveTotal);

        PaymentStatus paymentStatus;
        if (balance <= 0) {
          paymentStatus = PaymentStatus.used;
        } else if (totalPaid > 0) {
          paymentStatus = PaymentStatus.partial;
        } else {
          paymentStatus = PaymentStatus.unpaid;
        }

        paymentMap[order.id] = OrderWithPayment(
          order: order,
          balanceAmount: balance,
          paymentStatus: paymentStatus,
        );
      }

      return paymentMap;
    } catch (e) {
      if (kDebugMode) {
        print('Error computing payment metadata: $e');
      }
      // Return empty map on error - balances will be computed on-demand
      return {};
    }
  }

  /// Subscribe to real-time order changes (all orders) via shared provider
  void _subscribeToAllOrders() {
    print('AdminOrderController: Subscribing to all orders stream...');

    // Watch shared orders provider (single subscription shared across all controllers)
    _ref.listen<AsyncValue<List<Order>>>(sharedOrdersProvider, (
      previous,
      next,
    ) {
      next.whenData((orders) {
        // Process in microtask to avoid build-phase state updates
        Future.microtask(() async {
          if (!mounted) return;
          // Force log for debugging
          print(
            '📦 AdminOrderController: Stream update received. Orders count: ${orders.length}',
          );

          // Check for new orders and play sound
          _checkForNewOrdersAndPlaySound(orders);

          // Filter orders based on current customer filter if active
          // If we're filtering by customer, we only care about their orders for the UI
          // But we still want to know about ALL orders for the sound notification (handled above)

          // Sort by order number descending
          final sortedOrders = List<Order>.from(orders)..sort((a, b) {
            final numA = _extractNumericPortionFromOrder(a) ?? 0;
            final numB = _extractNumericPortionFromOrder(b) ?? 0;
            return numB.compareTo(numA);
          });

          // If we are viewing a specific customer's orders, merge updates instead of replacing
          if (state.customerId != null) {
            final customerOrders =
                sortedOrders
                    .where((o) => o.userId == state.customerId)
                    .toList();

            final existingMap = {for (var o in state.orders) o.id: o};
            bool changed = false;

            // Check if counts differ (added/removed)
            if (state.orders.length != customerOrders.length) {
              changed = true;
            } else {
              // Check for added or updated orders
              for (final newOrder in customerOrders) {
                final existingOrder = existingMap[newOrder.id];
                if (existingOrder == null ||
                    existingOrder.updatedAt != newOrder.updatedAt ||
                    existingOrder.status != newOrder.status ||
                    existingOrder.total != newOrder.total) {
                  changed = true;
                  break;
                }
              }
            }

            if (!changed) return;

            final updatedCustomerOrders = customerOrders;

            // Re-sort the customer list by order number descending
            updatedCustomerOrders.sort((a, b) {
              final numA = _extractNumericPortionFromOrder(a) ?? 0;
              final numB = _extractNumericPortionFromOrder(b) ?? 0;
              return numB.compareTo(numA);
            });

            // Recompute metadata only for the updated list
            final paymentMap = await _computePaymentMetadata(
              updatedCustomerOrders,
            );
            if (!mounted) return;

            // Calculate filtered data first
            final filterResult = _calculateFilteredData(
              orders: updatedCustomerOrders,
            );

            if (!mounted) return;

            state = state.copyWith(
              orders: updatedCustomerOrders,
              filteredOrders: filterResult.filteredOrders,
              filteredReceipts: filterResult.filteredReceipts,
              combinedTransactions: filterResult.combinedTransactions,
              orderPaymentMap: {...state.orderPaymentMap, ...paymentMap},
            );
            return;
          }

          final existing = List<Order>.from(state.orders);
          final existingMap = {for (var o in existing) o.id: o};
          bool changed = false;
          for (final o in sortedOrders) {
            final old = existingMap[o.id];
            if (old == null ||
                old.updatedAt != o.updatedAt ||
                old.status != o.status ||
                old.total != o.total) {
              existingMap[o.id] = o;
              changed = true;
            }
          }
          if (!changed) return;
          // Sort merged orders by order number descending
          final merged =
              existingMap.values.toList()..sort((a, b) {
                final numA = _extractNumericPortionFromOrder(a) ?? 0;
                final numB = _extractNumericPortionFromOrder(b) ?? 0;
                return numB.compareTo(numA);
              });
          final paymentMap = await _computePaymentMetadata(merged);
          if (!mounted) return;

          // Calculate filtered data first
          final filterResult = _calculateFilteredData(orders: merged);

          if (!mounted) return;

          state = state.copyWith(
            orders: merged,
            filteredOrders: filterResult.filteredOrders,
            filteredReceipts: filterResult.filteredReceipts,
            combinedTransactions: filterResult.combinedTransactions,
            loading: false,
            error: null,
            orderPaymentMap: paymentMap,
            hasMore: state.hasMore,
          );
        });
      });
    });
  }

  Future<void> searchOrders(String query) async {
    // Defer execution to avoid "modify provider during build" errors
    await Future.microtask(() {});

    if (!mounted) return;
    state = state.copyWith(searchQuery: query);
    if (state.customerId != null) {
      await loadOrdersForCustomer(state.customerId!);
    } else {
      await loadOrders();
    }
  }

  void filterByStatus(OrderStatus? status) {
    Future.microtask(() {
      if (!mounted) return;
      // When status is null, we need to explicitly reset it using resetSelectedStatus flag
      // because copyWith's null-coalescing operator treats null as "not provided"
      if (status == null) {
        state = state.copyWith(resetSelectedStatus: true);
      } else {
        state = state.copyWith(selectedStatus: status);
      }
      _applyFilters();
    });
  }

  void filterByPaymentStatus(PaymentStatus? paymentStatus) {
    Future.microtask(() {
      if (!mounted) return;
      if (paymentStatus == null) {
        state = state.copyWith(resetSelectedPaymentStatus: true);
      } else {
        state = state.copyWith(selectedPaymentStatus: paymentStatus);
      }
      _applyFilters();
    });
  }

  void filterByTransactionType(String? type) {
    Future.microtask(() {
      if (!mounted) return;
      if (type == null) {
        state = state.copyWith(resetSelectedTransactionType: true);
      } else {
        state = state.copyWith(selectedTransactionType: type);
      }
      _applyFilters();
    });
  }

  void setSortMode(SortMode mode) {
    Future.microtask(() {
      if (!mounted) return;
      state = state.copyWith(sortMode: mode);
      _applyFilters();
    });
  }

  void filterByCustomer(String? customerId) {
    // Wrap in microtask to avoid "modify provider during build" errors
    Future.microtask(() {
      if (!mounted) return;
      if (customerId == null) {
        state = state.copyWith(customerId: null, resetCustomerId: true);
        loadOrders();
      } else {
        state = state.copyWith(customerId: customerId);
        loadOrdersForCustomer(customerId);
      }
    });
  }

  void filterByDateRange(DateTime? start, DateTime? end) {
    Future.microtask(() {
      if (!mounted) return;
      state = state.copyWith(
        dateRangeStart: start,
        dateRangeEnd: end,
        resetDateRangeStart: start == null,
        resetDateRangeEnd: end == null,
      );
      _applyFilters();
    });
  }

  void filterByAmountRange(double? min, double? max) {
    Future.microtask(() {
      if (!mounted) return;
      state = state.copyWith(
        minAmount: min,
        maxAmount: max,
        resetMinAmount: min == null,
        resetMaxAmount: max == null,
      );
      _applyFilters();
    });
  }

  /// Mark an order as recently updated so it appears at the top of the list.
  /// This is used after converting an order to sale (when shipping/balance changes).
  void markOrderRecentlyUpdated(String orderId) {
    Future.microtask(() {
      if (!mounted) return;
      state = state.copyWith(
        lastUpdatedOrderId: orderId,
        resetLastUpdatedOrderId: false,
      );
      _applyFilters();
    });
  }

  /// Manually update an order in the state (e.g. after editing)
  void updateOrder(Order updatedOrder) {
    Future.microtask(() {
      if (!mounted) return;
      final currentOrders = List<Order>.from(state.orders);
      final index = currentOrders.indexWhere((o) => o.id == updatedOrder.id);

      if (index != -1) {
        currentOrders[index] = updatedOrder;

        // Update selected order if it matches
        final currentSelected = state.selectedOrder;
        final newSelected =
            (currentSelected != null && currentSelected.id == updatedOrder.id)
                ? updatedOrder
                : currentSelected;

        // Update payment map
        final currentPaymentMap = Map<String, OrderWithPayment>.from(
          state.orderPaymentMap,
        );
        final oldPaymentData = currentPaymentMap[updatedOrder.id];

        if (oldPaymentData != null) {
          // Calculate total paid from old data
          final oldTotal = oldPaymentData.order.total;
          final oldEffectiveTotal = oldTotal;
          final oldBalance = oldPaymentData.balanceAmount;
          final totalPaid = oldEffectiveTotal - oldBalance;

          // Calculate new balance
          final newEffectiveTotal = updatedOrder.total;
          // Ensure upper bound is at least 0.0 to avoid RangeError
          final maxBalance = newEffectiveTotal > 0 ? newEffectiveTotal : 0.0;
          final newBalance = (newEffectiveTotal - totalPaid).clamp(
            0.0,
            maxBalance,
          );

          // Determine new payment status
          PaymentStatus newPaymentStatus;
          if (newBalance <= 0) {
            newPaymentStatus = PaymentStatus.used;
          } else if (totalPaid > 0) {
            newPaymentStatus = PaymentStatus.partial;
          } else {
            newPaymentStatus = PaymentStatus.unpaid;
          }

          currentPaymentMap[updatedOrder.id] = OrderWithPayment(
            order: updatedOrder,
            balanceAmount: newBalance,
            paymentStatus: newPaymentStatus,
          );
        }

        // Calculate filtered data first
        final filterResult = _calculateFilteredData(orders: currentOrders);

        if (!mounted) return;

        state = state.copyWith(
          orders: currentOrders,
          selectedOrder: newSelected,
          orderPaymentMap: currentPaymentMap,
          filteredOrders: filterResult.filteredOrders,
          filteredReceipts: filterResult.filteredReceipts,
          combinedTransactions: filterResult.combinedTransactions,
        );
      }
    });
  }

  void resetFilters() {
    Future.microtask(() {
      if (!mounted) return;
      state = state.copyWith(
        searchQuery: '',
        resetSelectedStatus: true,
        resetSelectedPaymentStatus: true,
        resetSelectedTransactionType: true,
        customerId: null,
        resetCustomerId: true,
        resetDateRangeStart: true,
        resetDateRangeEnd: true,
        resetMinAmount: true,
        resetMaxAmount: true,
        lastUpdatedOrderId: null,
        resetLastUpdatedOrderId: true,
      );
      _applyFilters();
    });
  }

  ({
    List<Order> filteredOrders,
    List<PaymentReceipt> filteredReceipts,
    List<TransactionItem> combinedTransactions,
  })
  _calculateFilteredData({
    List<Order>? orders,
    List<PaymentReceipt>? receipts,
  }) {
    // Start with provided lists or current state
    // We create copies to avoid modifying the original lists during filtering/sorting if they are mutable
    final currentOrders = List<Order>.from(orders ?? state.orders);
    final currentReceipts = List<PaymentReceipt>.from(
      receipts ?? state.receipts,
    );

    List<Order> filtered = currentOrders;
    List<PaymentReceipt> filteredReceipts = currentReceipts;

    // Apply customer filter
    if (state.customerId != null && state.customerId!.isNotEmpty) {
      filtered = filtered.where((o) => o.userId == state.customerId).toList();
      filteredReceipts =
          filteredReceipts
              .where((r) => r.customerId == state.customerId)
              .toList();
    }

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered =
          filtered.where((order) {
            return order.orderNumber.toLowerCase().contains(query) ||
                order.deliveryAddress.name.toLowerCase().contains(query) ||
                (order.deliveryAddress.alias != null &&
                    order.deliveryAddress.alias!.toLowerCase().contains(
                      query,
                    )) ||
                order.deliveryAddress.phone.contains(query);
          }).toList();
      filteredReceipts =
          filteredReceipts.where((r) {
            return r.receiptNumber.toLowerCase().contains(query) ||
                (r.orderNumber?.toLowerCase().contains(query) ?? false) ||
                (r.customerName?.toLowerCase().contains(query) ?? false) ||
                (r.customerPhone?.contains(query) ?? false);
          }).toList();
    }

    // Apply status filter
    if (state.selectedStatus != null) {
      filtered =
          filtered.where((o) => o.status == state.selectedStatus).toList();
      // Keep receipts visible even when filtering by order status
      // filteredReceipts = [];
    }

    // SORTING: Always sort by order number descending (higher numbers first)
    filtered.sort((a, b) {
      final numA = _extractNumericPortionFromOrder(a) ?? 0;
      final numB = _extractNumericPortionFromOrder(b) ?? 0;
      return numB.compareTo(numA);
    });

    filteredReceipts.sort((a, b) {
      // Extract numeric portion from orderNumber for sorting
      final numericPartA = (a.orderNumber ?? '').replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final numericPartB = (b.orderNumber ?? '').replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final numA =
          numericPartA.isNotEmpty ? int.tryParse(numericPartA) ?? 0 : 0;
      final numB =
          numericPartB.isNotEmpty ? int.tryParse(numericPartB) ?? 0 : 0;
      return numB.compareTo(numA); // Higher numbers first
    });

    // Create combined list of Sales and Payments
    final combinedList = <TransactionItem>[];

    // Add all sales (orders)
    for (final order in filtered) {
      final orderNum = _extractNumericPortionFromOrder(order) ?? 0;
      combinedList.add(
        TransactionItem(
          type: 'sale',
          order: order,
          receipt: null,
          orderNumber: orderNum,
        ),
      );
    }

    // Add all payments
    for (final receipt in filteredReceipts) {
      final orderNumStr = (receipt.orderNumber ?? '').replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final orderNum =
          orderNumStr.isNotEmpty ? int.tryParse(orderNumStr) ?? 0 : 0;
      combinedList.add(
        TransactionItem(
          type: 'payment',
          order: null,
          receipt: receipt,
          orderNumber: orderNum,
        ),
      );
    }

    // Sort combined list by order number descending
    combinedList.sort((a, b) => b.orderNumber.compareTo(a.orderNumber));

    return (
      filteredOrders: filtered,
      filteredReceipts: filteredReceipts,
      combinedTransactions: combinedList,
    );
  }

  void _applyFilters() {
    if (!mounted) return;
    final result = _calculateFilteredData();

    if (!mounted) return;

    state = state.copyWith(
      filteredOrders: result.filteredOrders,
      filteredReceipts: result.filteredReceipts,
      combinedTransactions: result.combinedTransactions,
    );
  }

  /// Manually update an order in the list (e.g. for optimistic updates)
  void updateOrderInList(Order updatedOrder) {
    Future.microtask(() {
      if (!mounted) return;
      final currentOrders = List<Order>.from(state.orders);
      final index = currentOrders.indexWhere((o) => o.id == updatedOrder.id);

      if (index != -1) {
        currentOrders[index] = updatedOrder;
      } else {
        currentOrders.add(updatedOrder);
      }

      // Update selected order if it matches
      Order? newSelectedOrder = state.selectedOrder;
      if (state.selectedOrder?.id == updatedOrder.id) {
        newSelectedOrder = updatedOrder;
      }

      // Re-apply filters to ensure consistency and sorting
      final filterResult = _calculateFilteredData(orders: currentOrders);

      if (!mounted) return;

      state = state.copyWith(
        orders: currentOrders,
        selectedOrder: newSelectedOrder,
        filteredOrders: filterResult.filteredOrders,
        filteredReceipts: filterResult.filteredReceipts,
        combinedTransactions: filterResult.combinedTransactions,
      );
    });
  }

  void selectOrder(Order order) {
    Future.microtask(() {
      if (!mounted) return;
      state = state.copyWith(selectedOrder: order);
    });
  }

  void clearSelection() {
    Future.microtask(() {
      if (!mounted) return;
      state = state.copyWith(selectedOrder: null);
    });
  }

  Future<bool> deleteOrder(String orderId) async {
    if (!mounted) return false;
    final repository = _ref.read(orderRepositoryProvider);
    try {
      final success = await repository.deleteOrder(orderId);
      if (success) {
        // Remove from local state
        final updatedOrders =
            state.orders.where((o) => o.id != orderId).toList();

        // Calculate filtered data first
        final filterResult = _calculateFilteredData(orders: updatedOrders);

        if (!mounted) return true; // Already succeeded in repo

        state = state.copyWith(
          orders: updatedOrders,
          filteredOrders: filterResult.filteredOrders,
          filteredReceipts: filterResult.filteredReceipts,
          combinedTransactions: filterResult.combinedTransactions,
          selectedOrder:
              state.selectedOrder?.id == orderId ? null : state.selectedOrder,
        );
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting order: $e');
      }
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    // Defer execution to avoid "modify provider during build" errors
    await Future.microtask(() {});

    if (!mounted) return false;
    final repository = _ref.read(orderRepositoryProvider);

    // OPTIMISTIC UPDATE: Update UI immediately for instant feedback
    final currentOrder = state.selectedOrder;
    Order? optimisticSelectedOrder;

    // Create optimistic order for selectedOrder if it matches
    if (currentOrder != null && currentOrder.id == orderId) {
      optimisticSelectedOrder = Order(
        id: currentOrder.id,
        orderTag: currentOrder.orderTag,
        orderNumber: currentOrder.orderNumber,
        orderDate: currentOrder.orderDate,
        status: newStatus,
        items: currentOrder.items,
        deliveryAddress: currentOrder.deliveryAddress,
        subtotal: currentOrder.subtotal,
        shipping: currentOrder.shipping,
        tax: currentOrder.tax,
        total: currentOrder.total,
        trackingNumber: currentOrder.trackingNumber,
        estimatedDelivery: currentOrder.estimatedDelivery,
        notes: currentOrder.notes,
        userId: currentOrder.userId,
      );
    }

    // Create optimistic update for orders list
    final currentOrders = List<Order>.from(state.orders);
    final orderIndex = currentOrders.indexWhere((o) => o.id == orderId);
    Order? optimisticOrder;

    if (orderIndex != -1) {
      final order = currentOrders[orderIndex];
      optimisticOrder = Order(
        id: order.id,
        orderTag: order.orderTag,
        orderNumber: order.orderNumber,
        orderDate: order.orderDate,
        status: newStatus,
        items: order.items,
        deliveryAddress: order.deliveryAddress,
        subtotal: order.subtotal,
        shipping: order.shipping,
        tax: order.tax,
        total: order.total,
        trackingNumber: order.trackingNumber,
        estimatedDelivery: order.estimatedDelivery,
        notes: order.notes,
        userId: order.userId,
      );
      currentOrders[orderIndex] = optimisticOrder;
    }

    // Apply optimistic updates in single state change for better performance
    final ordersToUse = orderIndex != -1 ? currentOrders : state.orders;

    // Calculate filtered data if needed
    final filterResult =
        orderIndex != -1 ? _calculateFilteredData(orders: ordersToUse) : null;

    if (!mounted) return false;

    state = state.copyWith(
      orders: ordersToUse,
      selectedOrder: optimisticSelectedOrder ?? state.selectedOrder,
      loading: false,
      error: null,
      filteredOrders: filterResult?.filteredOrders ?? state.filteredOrders,
      filteredReceipts:
          filterResult?.filteredReceipts ?? state.filteredReceipts,
      combinedTransactions:
          filterResult?.combinedTransactions ?? state.combinedTransactions,
    );

    // FIRE-AND-FORGET: Update database in background (don't await)
    // Return immediately so UI updates instantly
    // Real-time subscription will sync correct state automatically
    repository
        .updateOrderStatus(orderId, newStatus)
        .then((_) {
          // Success case - handled by real-time subscription or already updated optimistically
        })
        .catchError((e) {
          // Handle errors in background - log but don't block UI
          if (kDebugMode) {
            print('Error updating order status in background: $e');
          }

          // On error, revert by reloading orders (real-time subscription will also help)
          loadOrders()
              .then((_) {
                if (!mounted) return;
                // Try to restore original order if update failed
                if (currentOrder != null && currentOrder.id == orderId) {
                  final revertedOrder = state.orders.firstWhere(
                    (order) => order.id == orderId,
                    orElse: () => currentOrder,
                  );
                  selectOrder(revertedOrder);
                }

                // Show error state (non-blocking)
                if (mounted) {
                  state = state.copyWith(
                    error: 'Failed to update order status. Please try again.',
                  );
                }
              })
              .catchError((reloadError) {
                // If reload also fails, just log it
                if (kDebugMode) {
                  print(
                    'Error reloading orders after status update failure: $reloadError',
                  );
                }
              });
        });

    // Return immediately - UI already updated optimistically
    // Database update happens in background, real-time syncs state
    return true;
  }

  Future<bool> addTrackingNumber(String orderId, String trackingNumber) async {
    // Defer execution to avoid "modify provider during build" errors
    await Future.microtask(() {});

    final repository = _ref.read(orderRepositoryProvider);

    state = state.copyWith(loading: true, error: null);

    try {
      // Cast to OrderRepositorySupabase to access updateOrderTracking method
      if (repository is OrderRepositorySupabase) {
        final updatedOrder = await repository.updateOrderTracking(
          orderId,
          trackingNumber,
        );

        if (!mounted) return false;

        if (updatedOrder != null) {
          // Real-time subscription will update the state automatically
          state = state.copyWith(loading: false);
          // Refresh to ensure we have the latest data
          await loadOrders();
          return true;
        } else {
          state = state.copyWith(
            loading: false,
            error: 'Failed to update tracking number',
          );
          return false;
        }
      } else {
        if (mounted) {
          state = state.copyWith(
            loading: false,
            error: 'Order repository is not OrderRepositorySupabase',
          );
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating tracking number: $e');
      }
      if (mounted) {
        state = state.copyWith(
          loading: false,
          error: 'Failed to update tracking number: ${e.toString()}',
        );
      }
      return false;
    }
  }

  Future<bool> updateOrderItems(String orderId, List<OrderItem> items) async {
    // Defer execution to avoid "modify provider during build" errors
    await Future.microtask(() {});

    final repository = _ref.read(orderRepositoryProvider);

    state = state.copyWith(loading: true, error: null);

    try {
      // Calculate new totals for optimistic update
      final currentOrder = state.selectedOrder;
      double newSubtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      double newTotal = 0.0;
      if (currentOrder != null && currentOrder.id == orderId) {
        newTotal = newSubtotal + currentOrder.shipping + currentOrder.tax;
      }

      // OPTIMISTIC UPDATE: Update UI immediately
      Order? optimisticSelectedOrder;
      if (currentOrder != null && currentOrder.id == orderId) {
        optimisticSelectedOrder = Order(
          id: currentOrder.id,
          orderTag: currentOrder.orderTag,
          orderNumber: currentOrder.orderNumber,
          orderDate: currentOrder.orderDate,
          status: currentOrder.status,
          items: items,
          deliveryAddress: currentOrder.deliveryAddress,
          subtotal: newSubtotal,
          shipping: currentOrder.shipping,
          tax: currentOrder.tax,
          total: newTotal,
          trackingNumber: currentOrder.trackingNumber,
          estimatedDelivery: currentOrder.estimatedDelivery,
          notes: currentOrder.notes,
          userId: currentOrder.userId,
        );
      }

      // Update orders list optimistically
      final currentOrders = List<Order>.from(state.orders);
      final orderIndex = currentOrders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        final order = currentOrders[orderIndex];
        final updatedOrder = Order(
          id: order.id,
          orderTag: order.orderTag,
          orderNumber: order.orderNumber,
          orderDate: order.orderDate,
          status: order.status,
          items: items,
          deliveryAddress: order.deliveryAddress,
          subtotal: newSubtotal,
          shipping: order.shipping,
          tax: order.tax,
          total: newSubtotal + order.shipping + order.tax,
          trackingNumber: order.trackingNumber,
          estimatedDelivery: order.estimatedDelivery,
          notes: order.notes,
          userId: order.userId,
        );
        currentOrders[orderIndex] = updatedOrder;
      }

      // Apply optimistic updates
      state = state.copyWith(
        orders: orderIndex != -1 ? currentOrders : state.orders,
        selectedOrder: optimisticSelectedOrder ?? state.selectedOrder,
        loading: false,
        error: null,
      );
      if (orderIndex != -1) {
        _applyFilters();
      }

      // Update database
      final updatedOrder = await repository.updateOrderItems(orderId, items);

      if (!mounted) return false;

      if (updatedOrder != null) {
        // Real-time subscription will sync the state, but refresh to be sure
        await loadOrders();
        if (!mounted) return true;

        // Update selected order if it matches
        if (currentOrder != null && currentOrder.id == orderId) {
          selectOrder(updatedOrder);
        }
        // Wait a moment for database transaction to fully commit
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return true;

        // Refresh customer list to update balances after order total change
        try {
          await _ref.read(adminCustomerControllerProvider.notifier).refresh();
        } catch (e) {
          // Non-critical - customer list refresh might fail if not initialized
          if (kDebugMode) {
            print(
              'Note: Could not refresh customer list after order update: $e',
            );
          }
        }
        return true;
      } else {
        // Revert optimistic update on failure
        await loadOrders();
        if (!mounted) return false;

        if (currentOrder != null && currentOrder.id == orderId) {
          final revertedOrder = state.orders.firstWhere(
            (order) => order.id == orderId,
            orElse: () => currentOrder,
          );
          selectOrder(revertedOrder);
        }
        state = state.copyWith(error: 'Failed to update order items');
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order items: $e');
      }

      // Revert optimistic update on error
      await loadOrders();
      if (mounted) {
        final currentOrder = state.selectedOrder;
        if (currentOrder != null && currentOrder.id == orderId) {
          final revertedOrder = state.orders.firstWhere(
            (order) => order.id == orderId,
            orElse: () => currentOrder,
          );
          selectOrder(revertedOrder);
        }

        state = state.copyWith(
          loading: false,
          error: 'Failed to update order items: ${e.toString()}',
        );
      }
      return false;
    }
  }

  /// Refresh orders manually
  Future<void> refresh() async {
    // Ensure initialized before refresh
    if (!_isInitialized) {
      await initialize();
    } else {
      if (state.customerId != null) {
        await loadOrdersForCustomer(state.customerId!);
      } else {
        await loadOrders();
      }
    }
  }

  /// Get payment metadata for an order
  OrderWithPayment? getPaymentMetadata(String orderId) {
    return state.orderPaymentMap[orderId];
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Mark all current orders as read
  Future<void> markOrdersAsRead() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    await prefs.setString(_lastViewedKey, now.toIso8601String());
    if (!mounted) return;
    _ref.read(lastOrdersViewedTimeProvider.notifier).state = now;
  }

  /// Extract numeric portion from order numbers for proper numeric sorting
  /// Handles formats like ORD0001, PO00-000097, etc.
  int? _extractNumericPortionFromOrder(Order order) {
    final numericPart = order.orderNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return numericPart.isNotEmpty ? int.tryParse(numericPart) : null;
  }
}
