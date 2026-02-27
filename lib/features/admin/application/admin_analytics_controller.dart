import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_models.dart';
import '../data/analytics_provider.dart';
import '../../orders/data/shared_orders_provider.dart';
import '../../orders/data/order_model.dart';
import '../data/shared_customers_provider.dart';
import '../application/admin_customer_controller.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../catalog/data/product.dart';
import '../../orders/data/order_repository_provider.dart';
import '../../orders/data/order_repository_supabase.dart';
import '../data/customer_repository_provider.dart';

class AdminAnalyticsState {
  final bool loading;
  final String? error;
  final AnalyticsData? analyticsData;
  final AnalyticsFilter currentFilter;

  const AdminAnalyticsState({
    this.loading = false,
    this.error,
    this.analyticsData,
    this.currentFilter = const AnalyticsFilter(period: AnalyticsPeriod.today),
  });

  AdminAnalyticsState copyWith({
    bool? loading,
    String? error,
    AnalyticsData? analyticsData,
    AnalyticsFilter? currentFilter,
  }) {
    return AdminAnalyticsState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      analyticsData: analyticsData ?? this.analyticsData,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class AdminAnalyticsController extends StateNotifier<AdminAnalyticsState> {
  AdminAnalyticsController(this._ref) : super(const AdminAnalyticsState()) {
    _init();
  }

  final Ref _ref;
  List<Order> _allOrders = [];
  List<Customer> _allCustomers = [];
  List<Product> _allProducts = [];

  /// One-time initialization:
  /// - Load initial snapshots of orders, customers, and products from Supabase
  /// - Then attach realtime listeners so future changes keep analytics in sync.
  Future<void> _init() async {
    state = state.copyWith(loading: true, error: null);

    try {
      // Load initial data directly from repositories so analytics
      // have real totals even if realtime streams are delayed.

      // Orders (admin view – use Supabase repository when available)
      final orderRepository = _ref.read(orderRepositoryProvider);
      List<Order> initialOrders = [];
      if (orderRepository is OrderRepositorySupabase) {
        initialOrders = await orderRepository.getAllOrders();
      } else {
        // Fallback: use user orders (e.g., in-memory repository during tests)
        initialOrders = await orderRepository.getUserOrders();
      }

      // Customers (admin view)
      final customerRepository = _ref.read(customerRepositoryProvider);
      final initialCustomers = await customerRepository.getAllCustomers();

      // Products (shared state, already Supabase-backed)
      final initialProducts = _ref.read(allProductsProvider);

      _allOrders = initialOrders;
      _allCustomers = initialCustomers;
      _allProducts = initialProducts;

      if (!mounted) return;
      _recalculateAnalytics();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        loading: false,
        error: 'Error loading analytics data: ${e.toString()}',
      );
    }

    // Always attach realtime listeners after the initial snapshot load.
    _subscribeToRealTimeData();
  }

  void _subscribeToRealTimeData() {
    // Watch shared orders provider (single subscription shared across all controllers)
    _ref.listen<AsyncValue<List<Order>>>(sharedOrdersProvider, (
      previous,
      next,
    ) {
      next.whenData((orders) {
        _allOrders = orders;
        if (kDebugMode) {
          print(
            '📊 AdminAnalyticsController: received ${orders.length} orders from sharedOrdersProvider',
          );
        }
        _recalculateAnalytics();
      });
    });

    // Watch shared customers provider (single subscription shared across all controllers)
    _ref.listen<AsyncValue<List<Customer>>>(sharedCustomersProvider, (
      previous,
      next,
    ) {
      next.whenData((customers) {
        _allCustomers = customers;
        if (kDebugMode) {
          print(
            '📊 AdminAnalyticsController: received ${customers.length} customers from sharedCustomersProvider',
          );
        }
        _recalculateAnalytics();
      });
    });

    // Subscribe to products (via sharedProductProvider)
    _ref.listen<SharedProductState>(sharedProductProvider, (previous, next) {
      if (previous?.products != next.products) {
        _allProducts = next.products;
        if (kDebugMode) {
          print(
            '📊 AdminAnalyticsController: received ${next.products.length} products from sharedProductProvider',
          );
        }
        _recalculateAnalytics();
      }
    });

    // Initial load of products
    final products = _ref.read(allProductsProvider);
    _allProducts = products;
    _recalculateAnalytics();
  }

  void _recalculateAnalytics() {
    if (!mounted) return;
    try {
      final filter = state.currentFilter;
      final analyticsData = _buildAnalyticsData(filter);
      state = state.copyWith(
        analyticsData: analyticsData,
        loading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Error calculating analytics: ${e.toString()}',
      );
      if (kDebugMode) {
        print('Error calculating analytics: $e');
      }
    }
  }

  AnalyticsData _buildAnalyticsData(AnalyticsFilter filter) {
    final now = DateTime.now();
    final filteredOrders = _filterOrdersByPeriod(_allOrders, filter);
    final filteredCustomers = _filterCustomersByPeriod(_allCustomers, filter);

    // Calculate customer metrics
    final customerMetrics = _calculateCustomerMetrics(
      _allCustomers,
      filteredCustomers,
      now,
    );

    // Calculate revenue metrics
    final revenueMetrics = _calculateRevenueMetrics(
      _allOrders,
      filteredOrders,
      _allCustomers,
      now,
    );

    // Calculate order metrics
    final orderMetrics = _calculateOrderMetrics(
      _allOrders,
      filteredOrders,
      now,
    );

    // Calculate product metrics
    final productMetrics = _calculateProductMetrics(_allProducts);

    // Calculate user behavior metrics (using mock data for now)
    final userBehaviorMetrics = _calculateUserBehaviorMetrics();

    // Get real-time metrics from provider
    final realTimeMetrics = _ref.read(realTimeAnalyticsProvider);

    // Generate chart data
    final revenueChart = _generateRevenueChart(filteredOrders, filter);
    final orderChart = _generateOrderChart(filteredOrders, filter);
    final customerChart = _generateCustomerChart(filteredCustomers, filter);

    // Generate shipment overview (default 30 days or based on filter)
    int shipmentDays = 30;
    if (filter.period == AnalyticsPeriod.week) shipmentDays = 7;
    final shipmentOverview = _generateShipmentOverview(
      filteredOrders,
      shipmentDays,
    );

    // Generate top products
    final topProducts = _generateTopProducts(_allProducts, filteredOrders);

    // Generate top categories
    final topCategories = _generateTopCategories(_allProducts, filteredOrders);

    // Generate recent orders
    final recentOrders = _generateRecentOrders(filteredOrders);

    // Generate customer activities
    final customerActivities = _generateCustomerActivities(filteredOrders);

    return AnalyticsData(
      customerMetrics: customerMetrics,
      revenueMetrics: revenueMetrics,
      orderMetrics: orderMetrics,
      productMetrics: productMetrics,
      userBehaviorMetrics: userBehaviorMetrics,
      realTimeMetrics: realTimeMetrics,
      revenueChart: revenueChart,
      orderChart: orderChart,
      customerChart: customerChart,
      shipmentOverview: shipmentOverview,
      topProducts: topProducts,
      topCategories: topCategories,
      recentOrders: recentOrders,
      customerActivities: customerActivities,
    );
  }

  List<Order> _filterOrdersByPeriod(
    List<Order> orders,
    AnalyticsFilter filter,
  ) {
    final now = DateTime.now();
    DateTime? startDate;

    switch (filter.period) {
      case AnalyticsPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case AnalyticsPeriod.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case AnalyticsPeriod.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case AnalyticsPeriod.quarter:
        final quarter = (now.month - 1) ~/ 3;
        startDate = DateTime(now.year, quarter * 3 + 1, 1);
        break;
      case AnalyticsPeriod.year:
        startDate = DateTime(now.year, 1, 1);
        break;
      case AnalyticsPeriod.allTime:
        return orders;
    }

    if (filter.startDate != null) {
      startDate = filter.startDate;
    }

    final endDate = filter.endDate ?? now;

    return orders.where((order) {
      final orderDate = order.orderDate;
      return orderDate.isAfter(startDate!) && orderDate.isBefore(endDate);
    }).toList();
  }

  List<Customer> _filterCustomersByPeriod(
    List<Customer> customers,
    AnalyticsFilter filter,
  ) {
    final now = DateTime.now();
    DateTime? startDate;

    switch (filter.period) {
      case AnalyticsPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case AnalyticsPeriod.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case AnalyticsPeriod.month:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case AnalyticsPeriod.quarter:
        final quarter = (now.month - 1) ~/ 3;
        startDate = DateTime(now.year, quarter * 3 + 1, 1);
        break;
      case AnalyticsPeriod.year:
        startDate = DateTime(now.year, 1, 1);
        break;
      case AnalyticsPeriod.allTime:
        return customers;
    }

    if (filter.startDate != null) {
      startDate = filter.startDate;
    }

    final endDate = filter.endDate ?? now;

    return customers.where((customer) {
      return customer.createdAt.isAfter(startDate!) &&
          customer.createdAt.isBefore(endDate);
    }).toList();
  }

  CustomerMetrics _calculateCustomerMetrics(
    List<Customer> allCustomers,
    List<Customer> filteredCustomers,
    DateTime now,
  ) {
    final totalCustomers = allCustomers.length;
    final activeCustomers = allCustomers.where((c) => c.totalOrders > 0).length;

    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final newCustomersToday =
        allCustomers.where((c) => c.createdAt.isAfter(todayStart)).length;
    final newCustomersThisWeek =
        allCustomers.where((c) => c.createdAt.isAfter(weekStart)).length;
    final newCustomersThisMonth =
        allCustomers.where((c) => c.createdAt.isAfter(monthStart)).length;

    // Calculate growth rate (simplified)
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthCustomers =
        allCustomers
            .where(
              (c) =>
                  c.createdAt.isAfter(previousMonthStart) &&
                  c.createdAt.isBefore(monthStart),
            )
            .length;
    final customerGrowthRate =
        previousMonthCustomers > 0
            ? ((newCustomersThisMonth - previousMonthCustomers) /
                previousMonthCustomers *
                100)
            : 0.0;

    // Calculate average customer lifetime value
    final totalRevenue = allCustomers.fold<double>(
      0.0,
      (sum, customer) => sum + customer.totalSpent,
    );
    final averageCustomerLifetimeValue =
        totalCustomers > 0 ? totalRevenue / totalCustomers : 0.0;

    final returningCustomers =
        allCustomers.where((c) => c.totalOrders > 1).length;

    return CustomerMetrics(
      totalCustomers: totalCustomers,
      activeCustomers: activeCustomers,
      newCustomersToday: newCustomersToday,
      newCustomersThisWeek: newCustomersThisWeek,
      newCustomersThisMonth: newCustomersThisMonth,
      customerGrowthRate: customerGrowthRate,
      averageCustomerLifetimeValue: averageCustomerLifetimeValue,
      returningCustomers: returningCustomers,
    );
  }

  RevenueMetrics _calculateRevenueMetrics(
    List<Order> allOrders,
    List<Order> filteredOrders,
    List<Customer> allCustomers,
    DateTime now,
  ) {
    final totalRevenue = allOrders
        .where(
          (o) =>
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.processing,
        )
        .fold<double>(0.0, (sum, order) => sum + order.total);

    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final todayRevenue = allOrders
        .where(
          (o) =>
              o.orderDate.isAfter(todayStart) &&
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.processing,
        )
        .fold<double>(0.0, (sum, order) => sum + order.total);

    final thisWeekRevenue = allOrders
        .where(
          (o) =>
              o.orderDate.isAfter(weekStart) &&
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.processing,
        )
        .fold<double>(0.0, (sum, order) => sum + order.total);

    final thisMonthRevenue = allOrders
        .where(
          (o) =>
              o.orderDate.isAfter(monthStart) &&
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.processing,
        )
        .fold<double>(0.0, (sum, order) => sum + order.total);

    // Calculate growth rate
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthRevenue = allOrders
        .where(
          (o) =>
              o.orderDate.isAfter(previousMonthStart) &&
              o.orderDate.isBefore(monthStart) &&
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.processing,
        )
        .fold<double>(0.0, (sum, order) => sum + order.total);
    final revenueGrowthRate =
        previousMonthRevenue > 0
            ? ((thisMonthRevenue - previousMonthRevenue) /
                previousMonthRevenue *
                100)
            : 0.0;

    final totalOrderCount =
        allOrders.where((o) => o.status != OrderStatus.cancelled).length;
    final averageOrderValue =
        totalOrderCount > 0 ? totalRevenue / totalOrderCount : 0.0;

    final totalCustomers = allCustomers.length;
    final revenuePerCustomer =
        totalCustomers > 0 ? totalRevenue / totalCustomers : 0.0;

    // Conversion rate:
    // Prefer sessions-based rate when session data is available, otherwise
    // fall back to a simple orders-per-customer rate.
    double conversionRate = 0.0;
    try {
      final realTimeMetrics = _ref.read(realTimeAnalyticsProvider);
      final sessionCount = realTimeMetrics.currentSessions;

      if (sessionCount > 0) {
        // Orders in the filtered period divided by recent sessions
        final ordersInPeriod =
            filteredOrders
                .where((o) => o.status != OrderStatus.cancelled)
                .length;
        if (ordersInPeriod > 0) {
          conversionRate = (ordersInPeriod / sessionCount) * 100;
        }
      } else if (totalCustomers > 0) {
        final ordersInPeriod =
            filteredOrders
                .where((o) => o.status != OrderStatus.cancelled)
                .length;
        if (ordersInPeriod > 0) {
          conversionRate = (ordersInPeriod / totalCustomers) * 100;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AdminAnalyticsController: error calculating conversionRate: $e');
      }
      conversionRate = 0.0;
    }

    return RevenueMetrics(
      totalRevenue: totalRevenue,
      todayRevenue: todayRevenue,
      thisWeekRevenue: thisWeekRevenue,
      thisMonthRevenue: thisMonthRevenue,
      revenueGrowthRate: revenueGrowthRate,
      averageOrderValue: averageOrderValue,
      revenuePerCustomer: revenuePerCustomer,
      conversionRate: conversionRate,
    );
  }

  OrderMetrics _calculateOrderMetrics(
    List<Order> allOrders,
    List<Order> filteredOrders,
    DateTime now,
  ) {
    final totalOrders = allOrders.length;
    final activeShipments =
        allOrders.where((o) => o.status != OrderStatus.cancelled).toList();

    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final todayOrders =
        allOrders.where((o) => o.orderDate.isAfter(todayStart)).length;
    final thisWeekOrders =
        allOrders.where((o) => o.orderDate.isAfter(weekStart)).length;
    final thisMonthOrders =
        allOrders.where((o) => o.orderDate.isAfter(monthStart)).length;

    final pendingOrders =
        allOrders
            .where(
              (o) =>
                  o.status == OrderStatus.confirmed ||
                  o.status == OrderStatus.processing,
            )
            .length;
    final confirmedOrders =
        allOrders.where((o) => o.status == OrderStatus.confirmed).length;
    final shippedOrders =
        allOrders.where((o) => o.status == OrderStatus.shipped).length;
    final deliveredOrders =
        allOrders.where((o) => o.status == OrderStatus.delivered).length;
    final cancelledOrders =
        allOrders.where((o) => o.status == OrderStatus.cancelled).length;

    final totalShipments = activeShipments.length;
    final delayedShipments = 0; // Simplified
    final deliverySuccessRate =
        totalShipments > 0 ? (deliveredOrders / totalShipments * 100) : 0.0;
    final averageDeliveryTimeDays = 0.0; // Simplified

    // Calculate growth rate
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthOrders =
        allOrders
            .where(
              (o) =>
                  o.orderDate.isAfter(previousMonthStart) &&
                  o.orderDate.isBefore(monthStart),
            )
            .length;
    final orderGrowthRate =
        previousMonthOrders > 0
            ? ((thisMonthOrders - previousMonthOrders) /
                previousMonthOrders *
                100)
            : 0.0;

    // Average processing time (simplified)
    const averageOrderProcessingTime = 2.5; // Placeholder baseline

    return OrderMetrics(
      totalOrders: totalOrders,
      todayOrders: todayOrders,
      thisWeekOrders: thisWeekOrders,
      thisMonthOrders: thisMonthOrders,
      pendingOrders: pendingOrders,
      confirmedOrders: confirmedOrders,
      shippedOrders: shippedOrders,
      deliveredOrders: deliveredOrders,
      cancelledOrders: cancelledOrders,
      orderGrowthRate: orderGrowthRate,
      averageOrderProcessingTime: averageOrderProcessingTime,
      totalShipments: totalShipments,
      delayedShipments: delayedShipments,
      deliverySuccessRate: deliverySuccessRate,
      averageDeliveryTimeDays: averageDeliveryTimeDays,
    );
  }

  ProductMetrics _calculateProductMetrics(List<Product> products) {
    final totalProducts = products.length;
    final activeProducts = products.length; // All products are active
    const lowStockThreshold = 10;
    final lowStockProducts =
        products
            .where((p) => p.stock < lowStockThreshold && p.stock > 0)
            .length;
    final outOfStockProducts = products.where((p) => p.stock == 0).length;

    // View-based metrics will be populated when product_views analytics are wired.
    const totalViews = 0;
    const todayViews = 0;
    final averageViewsPerProduct =
        totalProducts > 0 ? totalViews / totalProducts : 0.0;
    const productConversionRate = 0.0;

    return ProductMetrics(
      totalProducts: totalProducts,
      activeProducts: activeProducts,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      totalViews: totalViews,
      todayViews: todayViews,
      averageViewsPerProduct: averageViewsPerProduct,
      productConversionRate: productConversionRate,
    );
  }

  UserBehaviorMetrics _calculateUserBehaviorMetrics() {
    // User behavior analytics will be driven by product_views/search_queries
    // once those tables are fully integrated.
    return const UserBehaviorMetrics(
      averageSessionDuration: 0.0,
      totalPageViews: 0,
      todayPageViews: 0,
      bounceRate: 0.0,
      cartAbandonments: 0,
      cartAbandonmentRate: 0.0,
      topSearchTerms: [],
      deviceUsage: {},
      locationData: {},
    );
  }

  ShipmentOverview _generateShipmentOverview(List<Order> orders, int days) {
    final shipments = <ChartDataPoint>[];
    final delivered = <ChartDataPoint>[];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayShipments =
          orders
              .where(
                (o) =>
                    o.orderDate.isAfter(dayStart) &&
                    o.orderDate.isBefore(dayEnd) &&
                    o.status != OrderStatus.cancelled,
              )
              .length;

      final dayDelivered =
          orders
              .where(
                (o) =>
                    o.orderDate.isAfter(dayStart) &&
                    o.orderDate.isBefore(dayEnd) &&
                    o.status == OrderStatus.delivered,
              )
              .length;

      shipments.add(
        ChartDataPoint(
          date: date,
          value: dayShipments.toDouble(),
          label: '${date.day}/${date.month}',
        ),
      );

      delivered.add(
        ChartDataPoint(
          date: date,
          value: dayDelivered.toDouble(),
          label: '${date.day}/${date.month}',
        ),
      );
    }

    return ShipmentOverview(shipments: shipments, delivered: delivered);
  }

  List<ChartDataPoint> _generateRevenueChart(
    List<Order> orders,
    AnalyticsFilter filter,
  ) {
    final chartData = <ChartDataPoint>[];
    final now = DateTime.now();
    // Always show the last 30 days for the overview revenue trend chart
    const int days = 30;

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayRevenue = orders
          .where(
            (o) =>
                o.orderDate.isAfter(dayStart) &&
                o.orderDate.isBefore(dayEnd) &&
                o.status != OrderStatus.cancelled,
          )
          .fold<double>(0.0, (sum, order) => sum + order.total);

      chartData.add(
        ChartDataPoint(
          date: date,
          value: dayRevenue,
          label: '${date.day}/${date.month}',
        ),
      );
    }

    return chartData;
  }

  List<ChartDataPoint> _generateOrderChart(
    List<Order> orders,
    AnalyticsFilter filter,
  ) {
    final chartData = <ChartDataPoint>[];
    final now = DateTime.now();
    int days = 30;

    switch (filter.period) {
      case AnalyticsPeriod.today:
        days = 1;
        break;
      case AnalyticsPeriod.week:
        days = 7;
        break;
      case AnalyticsPeriod.month:
        days = 30;
        break;
      case AnalyticsPeriod.quarter:
        days = 90;
        break;
      case AnalyticsPeriod.year:
        days = 365;
        break;
      case AnalyticsPeriod.allTime:
        days = 365;
        break;
    }

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayOrders =
          orders
              .where(
                (o) =>
                    o.orderDate.isAfter(dayStart) &&
                    o.orderDate.isBefore(dayEnd),
              )
              .length;

      chartData.add(
        ChartDataPoint(
          date: date,
          value: dayOrders.toDouble(),
          label: '${date.day}/${date.month}',
        ),
      );
    }

    return chartData;
  }

  List<ChartDataPoint> _generateCustomerChart(
    List<Customer> customers,
    AnalyticsFilter filter,
  ) {
    final chartData = <ChartDataPoint>[];
    final now = DateTime.now();
    int days = 30;

    switch (filter.period) {
      case AnalyticsPeriod.today:
        days = 1;
        break;
      case AnalyticsPeriod.week:
        days = 7;
        break;
      case AnalyticsPeriod.month:
        days = 30;
        break;
      case AnalyticsPeriod.quarter:
        days = 90;
        break;
      case AnalyticsPeriod.year:
        days = 365;
        break;
      case AnalyticsPeriod.allTime:
        days = 365;
        break;
    }

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayCustomers =
          customers
              .where(
                (c) =>
                    c.createdAt.isAfter(dayStart) &&
                    c.createdAt.isBefore(dayEnd),
              )
              .length;

      chartData.add(
        ChartDataPoint(
          date: date,
          value: dayCustomers.toDouble(),
          label: '${date.day}/${date.month}',
        ),
      );
    }

    return chartData;
  }

  List<TopProduct> _generateTopProducts(
    List<Product> products,
    List<Order> orders,
  ) {
    // Count product sales from orders
    final productSales = <String, Map<String, dynamic>>{};

    for (final order in orders) {
      for (final item in order.items) {
        final productId = item.id;
        if (!productSales.containsKey(productId)) {
          productSales[productId] = {'sales': 0, 'revenue': 0.0, 'quantity': 0};
        }
        productSales[productId]!['sales'] =
            (productSales[productId]!['sales'] as int) + 1;
        productSales[productId]!['revenue'] =
            (productSales[productId]!['revenue'] as double) + item.totalPrice;
        productSales[productId]!['quantity'] =
            (productSales[productId]!['quantity'] as int) + item.quantity;
      }
    }

    // Create top products list
    final topProductsList = <TopProduct>[];
    for (final product in products) {
      final salesData = productSales[product.id];
      if (salesData != null) {
        final sales = salesData['sales'] as int;
        final revenue = salesData['revenue'] as double;
        final views = 500; // Placeholder
        final conversionRate = views > 0 ? (sales / views * 100) : 0.0;

        topProductsList.add(
          TopProduct(
            id: product.id,
            name: product.name,
            imageUrl: product.imageUrl,
            views: views,
            sales: sales,
            revenue: revenue,
            conversionRate: conversionRate,
            stock: product.stock,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
          ),
        );
      }
    }

    // Sort by revenue descending and take top 10
    topProductsList.sort((a, b) => b.revenue.compareTo(a.revenue));
    return topProductsList.take(10).toList();
  }

  List<TopCategory> _generateTopCategories(
    List<Product> products,
    List<Order> orders,
  ) {
    // Count category sales from orders
    final categorySales = <String, Map<String, dynamic>>{};

    for (final order in orders) {
      for (final item in order.items) {
        // Try to find product by matching name or ID
        final product = products.firstWhere(
          (p) => p.id == item.id || p.name == item.name,
          orElse:
              () =>
                  products.isNotEmpty
                      ? products.first
                      : throw StateError('No products'),
        );
        for (final category in product.categories) {
          if (!categorySales.containsKey(category)) {
            categorySales[category] = {
              'sales': 0,
              'revenue': 0.0,
              'productCount': 0,
            };
          }
          categorySales[category]!['sales'] =
              (categorySales[category]!['sales'] as int) + 1;
          categorySales[category]!['revenue'] =
              (categorySales[category]!['revenue'] as double) + item.totalPrice;
        }
      }
    }

    // Count products per category
    for (final product in products) {
      for (final category in product.categories) {
        if (categorySales.containsKey(category)) {
          categorySales[category]!['productCount'] =
              (categorySales[category]!['productCount'] as int) + 1;
        }
      }
    }

    // Create top categories list
    final topCategoriesList = <TopCategory>[];
    categorySales.forEach((category, data) {
      final sales = data['sales'] as int;
      final revenue = data['revenue'] as double;
      final productCount = data['productCount'] as int;
      final views = 2000; // Placeholder
      final conversionRate = views > 0 ? (sales / views * 100) : 0.0;

      topCategoriesList.add(
        TopCategory(
          name: category,
          views: views,
          sales: sales,
          revenue: revenue,
          conversionRate: conversionRate,
          productCount: productCount,
        ),
      );
    });

    // Sort by revenue descending and take top 7
    topCategoriesList.sort((a, b) => b.revenue.compareTo(a.revenue));
    return topCategoriesList.take(7).toList();
  }

  List<RecentOrder> _generateRecentOrders(List<Order> orders) {
    // Sort by date descending and take the most recent orders
    final sortedOrders = List<Order>.from(orders)
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    return sortedOrders.take(20).map((order) {
      return RecentOrder(
        id: order.orderNumber,
        customerName: order.deliveryAddress.name,
        customerEmail: '', // Would need customer email from profile
        amount: order.total,
        status: order.status.name,
        createdAt: order.orderDate,
        products: order.items.map((item) => item.name).toList(),
      );
    }).toList();
  }

  List<CustomerActivity> _generateCustomerActivities(List<Order> orders) {
    // Generate activities from recent orders
    final activities = <CustomerActivity>[];
    final sortedOrders = List<Order>.from(orders)
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    for (final order in sortedOrders.take(15)) {
      activities.add(
        CustomerActivity(
          id: order.id,
          name: order.deliveryAddress.name,
          email: '', // Would need customer email
          activity: 'Completed Purchase',
          timestamp: order.orderDate,
          productName: order.items.isNotEmpty ? order.items.first.name : null,
          amount: order.total,
        ),
      );
    }

    return activities;
  }

  void updateFilter(AnalyticsFilter filter) {
    state = state.copyWith(currentFilter: filter);
    // Recalculate analytics with new filter
    _recalculateAnalytics();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    // Refresh by recalculating from current data
    _recalculateAnalytics();
  }

  void exportData() {
    // TODO: Implement data export functionality
    // This could export to CSV, PDF, or other formats
  }

  @override
  void dispose() {
    // No need to cancel subscriptions - shared providers handle cleanup
    super.dispose();
  }
}

final adminAnalyticsControllerProvider =
    StateNotifierProvider<AdminAnalyticsController, AdminAnalyticsState>(
      (ref) => AdminAnalyticsController(ref),
    );
