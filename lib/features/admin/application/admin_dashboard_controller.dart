import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/data/shared_orders_provider.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../catalog/data/product.dart';
import '../data/shared_customers_provider.dart';
import '../data/shared_manufacturers_provider.dart';
import '../domain/manufacturer.dart';
import 'admin_customer_controller.dart';
import '../data/customer_repository_provider.dart';
import '../../orders/data/order_repository_provider.dart';
import '../data/multi_device_repository.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../orders/data/order_model.dart';

class AdminDashboardState {
  final int totalOrders;
  final double totalRevenue;
  final int totalProducts;
  final int totalCustomers;
  final int pendingOrders;
  final int lowStockProducts;
  final int activeUsers;
  final double totalBalance;
  final bool loading;
  final String? error;
  final bool isInitialized;

  const AdminDashboardState({
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
    this.totalProducts = 0,
    this.totalCustomers = 0,
    this.pendingOrders = 0,
    this.lowStockProducts = 0,
    this.activeUsers = 0,
    this.totalBalance = 0.0,
    this.loading = false,
    this.error,
    this.isInitialized = false,
  });

  AdminDashboardState copyWith({
    int? totalOrders,
    double? totalRevenue,
    int? totalProducts,
    int? totalCustomers,
    int? pendingOrders,
    int? lowStockProducts,
    int? activeUsers,
    double? totalBalance,
    bool? loading,
    String? error,
    bool? isInitialized,
  }) => AdminDashboardState(
    totalOrders: totalOrders ?? this.totalOrders,
    totalRevenue: totalRevenue ?? this.totalRevenue,
    totalProducts: totalProducts ?? this.totalProducts,
    totalCustomers: totalCustomers ?? this.totalCustomers,
    pendingOrders: pendingOrders ?? this.pendingOrders,
    lowStockProducts: lowStockProducts ?? this.lowStockProducts,
    activeUsers: activeUsers ?? this.activeUsers,
    totalBalance: totalBalance ?? this.totalBalance,
    loading: loading ?? this.loading,
    error: error,
    isInitialized: isInitialized ?? this.isInitialized,
  );
}

class AdminDashboardController extends StateNotifier<AdminDashboardState> {
  AdminDashboardController(this._ref) : super(const AdminDashboardState()) {
    // Lazy initialization - don't load data until explicitly requested
  }

  final Ref _ref;
  bool _isInitialized = false;
  Timer? _activeUsersRefreshTimer;

  void _subscribeToRealTimeData() {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }

    // Watch shared orders provider (single subscription shared across all controllers)
    _ref.listen<AsyncValue<List<Order>>>(sharedOrdersProvider, (
      previous,
      next,
    ) {
      next.whenData((orders) {
        _updateMetricsFromOrders(orders);
      });
    });

    // Subscribe to products (via sharedProductProvider)
    _ref.listen<SharedProductState>(sharedProductProvider, (previous, next) {
      if (previous?.products != next.products) {
        _updateMetricsFromProducts(next.products);
      }
    });

    // Watch shared customers provider
    _ref.listen<AsyncValue<List<Customer>>>(sharedCustomersProvider, (
      previous,
      next,
    ) {
      _updateTotalMetrics();
    });

    // Watch shared manufacturers provider
    _ref.listen<AsyncValue<List<Manufacturer>>>(sharedManufacturersProvider, (
      previous,
      next,
    ) {
      _updateTotalMetrics();
    });

    // Initial load of products
    final products = _ref.read(allProductsProvider);
    _updateMetricsFromProducts(products);

    // Initial load of orders
    _ref.read(sharedOrdersProvider).whenData((orders) {
      _updateMetricsFromOrders(orders);
    });

    // Initial trigger for metrics
    _loadOptimizedMetrics();

    // Load active users count
    _loadActiveUsersCount();

    // Refresh active users count every 15 seconds
    _activeUsersRefreshTimer?.cancel();
    _activeUsersRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadActiveUsersCount(),
    );
  }

  Future<void> _loadActiveUsersCount() async {
    final count = await _loadActiveUsersCountInternal();
    if (mounted) {
      state = state.copyWith(activeUsers: count);
    }
  }

  Future<int> _loadActiveUsersCountInternal() async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final repository = MultiDeviceRepositorySupabase(supabase);
      final activeSessions = await repository.getActiveSessions();
      final uniqueUserIds = activeSessions.map((s) => s.userId).toSet();
      return uniqueUserIds.length;
    } catch (e) {
      if (!mounted) return 0;
      return state.activeUsers;
    }
  }

  Future<void> _loadOptimizedMetrics() async {
    try {
      if (kDebugMode) {
        print('AdminDashboardController: Loading optimized metrics...');
      }

      // Load active users, order metrics, and customer metrics in parallel
      final results = await Future.wait<dynamic>([
        _loadActiveUsersCountInternal(),
        _ref.read(orderRepositoryProvider).getOrderMetrics(),
        _ref.read(customerRepositoryProvider).getCustomerMetrics(),
        _ref.read(sharedManufacturersProvider.future),
      ]);

      final activeUsersCount = results[0] as int;
      final orderMetrics = results[1] as Map<String, dynamic>;
      final customerMetrics = results[2] as Map<String, dynamic>;
      final manufacturers = results[3] as List<Manufacturer>;

      if (mounted) {
        state = state.copyWith(
          activeUsers: activeUsersCount,
          totalOrders: orderMetrics['totalOrders'] as int,
          totalRevenue: orderMetrics['totalRevenue'] as double,
          pendingOrders: orderMetrics['pendingOrders'] as int,
          totalCustomers:
              (customerMetrics['totalCustomers'] as int) + manufacturers.length,
          totalBalance: customerMetrics['totalBalance'] as double,
          loading: false,
          error: null,
        );
      }

      if (kDebugMode) {
        print(
          'AdminDashboardController: Optimized metrics loaded successfully',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('AdminDashboardController: Error loading optimized metrics: $e');
      }
      if (!mounted) return;
      // Fallback to traditional loading if optimized fails
      _updateTotalMetrics();
    }
  }

  void _updateMetricsFromOrders(List<Order> orders) {
    if (!mounted) return;
    // Filter out Saikiran from metrics
    final filteredOrders =
        orders.where((order) {
          return !order.deliveryAddress.name.toLowerCase().contains('saikiran');
        }).toList();

    final totalOrders = filteredOrders.length;
    // Only count revenue for orders that are converted to sales
    final totalRevenue = filteredOrders
        .where((order) => order.status != OrderStatus.processing)
        .fold<double>(0.0, (sum, order) => sum + order.total);
    final pendingOrders =
        filteredOrders.where((order) {
          return order.status == OrderStatus.processing;
        }).length;

    state = state.copyWith(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      pendingOrders: pendingOrders,
      loading: false,
      error: null,
    );
  }

  void _updateMetricsFromProducts(List<Product> products) {
    if (!mounted) return;
    final totalProducts = products.length;
    const lowStockThreshold = 10;
    final lowStockProducts =
        products.where((product) {
          return product.stock < lowStockThreshold;
        }).length;

    state = state.copyWith(
      totalProducts: totalProducts,
      lowStockProducts: lowStockProducts,
      loading: false,
      error: null,
    );
  }

  void _updateTotalMetrics() {
    if (!mounted) return;
    final customersAsync = _ref.read(sharedCustomersProvider);
    final manufacturersAsync = _ref.read(sharedManufacturersProvider);

    int totalCustomers = 0;
    double totalBalance = 0.0;

    customersAsync.whenData((customers) {
      totalCustomers += customers.length;
      totalBalance += customers.fold<double>(
        0.0,
        (sum, customer) => sum + customer.totalBalance,
      );
    });

    manufacturersAsync.whenData((manufacturers) {
      totalCustomers += manufacturers.length;
      // Manufacturers might not have a balance field in the same way,
      // but if they do, add it here.
    });

    state = state.copyWith(
      totalCustomers: totalCustomers,
      totalBalance: totalBalance,
      loading: false,
      error: null,
    );
  }

  /// Initialize data loading (lazy loading support)
  void initialize() {
    if (!_isInitialized) {
      _isInitialized = true;
      if (kDebugMode) {
        print('AdminDashboardController: Initializing...');
      }
      _subscribeToRealTimeData();
      // Also load active users count immediately (in case _subscribeToRealTimeData hasn't called it yet)
      _loadActiveUsersCount();

      // Update state to indicate initialization has started
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> refresh() async {
    // Refresh all shared providers
    _ref.invalidate(sharedOrdersProvider);
    _ref.invalidate(sharedProductProvider);
    _ref.invalidate(sharedCustomersProvider);
    _ref.invalidate(sharedManufacturersProvider);
    await _ref.read(adminCustomerControllerProvider.notifier).refresh();
    await _loadActiveUsersCount();
  }

  @override
  void dispose() {
    _activeUsersRefreshTimer?.cancel();
    _activeUsersRefreshTimer = null;
    // No need to cancel subscriptions - shared providers handle cleanup
    super.dispose();
  }
}

final adminDashboardControllerProvider = StateNotifierProvider.autoDispose<
  AdminDashboardController,
  AdminDashboardState
>((ref) => AdminDashboardController(ref));
