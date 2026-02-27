// Analytics Data Models
class AnalyticsData {
  final CustomerMetrics customerMetrics;
  final RevenueMetrics revenueMetrics;
  final OrderMetrics orderMetrics;
  final ProductMetrics productMetrics;
  final UserBehaviorMetrics userBehaviorMetrics;
  final RealTimeMetrics realTimeMetrics;
  final List<ChartDataPoint> revenueChart;
  final List<ChartDataPoint> orderChart;
  final List<ChartDataPoint> customerChart;
  final ShipmentOverview shipmentOverview;
  final List<TopProduct> topProducts;
  final List<TopCategory> topCategories;
  final List<RecentOrder> recentOrders;
  final List<CustomerActivity> customerActivities;

  const AnalyticsData({
    required this.customerMetrics,
    required this.revenueMetrics,
    required this.orderMetrics,
    required this.productMetrics,
    required this.userBehaviorMetrics,
    required this.realTimeMetrics,
    required this.revenueChart,
    required this.orderChart,
    required this.customerChart,
    required this.shipmentOverview,
    required this.topProducts,
    required this.topCategories,
    required this.recentOrders,
    required this.customerActivities,
  });
}

class CustomerMetrics {
  final int totalCustomers;
  final int activeCustomers;
  final int newCustomersToday;
  final int newCustomersThisWeek;
  final int newCustomersThisMonth;
  final double customerGrowthRate;
  final double averageCustomerLifetimeValue;
  final int returningCustomers;

  const CustomerMetrics({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.newCustomersToday,
    required this.newCustomersThisWeek,
    required this.newCustomersThisMonth,
    required this.customerGrowthRate,
    required this.averageCustomerLifetimeValue,
    required this.returningCustomers,
  });
}

class RevenueMetrics {
  final double totalRevenue;
  final double todayRevenue;
  final double thisWeekRevenue;
  final double thisMonthRevenue;
  final double revenueGrowthRate;
  final double averageOrderValue;
  final double revenuePerCustomer;
  final double conversionRate;

  const RevenueMetrics({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.thisWeekRevenue,
    required this.thisMonthRevenue,
    required this.revenueGrowthRate,
    required this.averageOrderValue,
    required this.revenuePerCustomer,
    required this.conversionRate,
  });
}

class OrderMetrics {
  final int totalOrders;
  final int todayOrders;
  final int thisWeekOrders;
  final int thisMonthOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double orderGrowthRate;
  final double averageOrderProcessingTime;
  final int totalShipments;
  final int delayedShipments;
  final double deliverySuccessRate;
  final double averageDeliveryTimeDays;

  const OrderMetrics({
    required this.totalOrders,
    required this.todayOrders,
    required this.thisWeekOrders,
    required this.thisMonthOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.shippedOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.orderGrowthRate,
    required this.averageOrderProcessingTime,
    required this.totalShipments,
    required this.delayedShipments,
    required this.deliverySuccessRate,
    required this.averageDeliveryTimeDays,
  });
}

class ProductMetrics {
  final int totalProducts;
  final int activeProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int totalViews;
  final int todayViews;
  final double averageViewsPerProduct;
  final double productConversionRate;

  const ProductMetrics({
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.totalViews,
    required this.todayViews,
    required this.averageViewsPerProduct,
    required this.productConversionRate,
  });
}

class UserBehaviorMetrics {
  final double averageSessionDuration;
  final int totalPageViews;
  final int todayPageViews;
  final double bounceRate;
  final int cartAbandonments;
  final double cartAbandonmentRate;
  final List<String> topSearchTerms;
  final Map<String, int> deviceUsage;
  final Map<String, int> locationData;

  const UserBehaviorMetrics({
    required this.averageSessionDuration,
    required this.totalPageViews,
    required this.todayPageViews,
    required this.bounceRate,
    required this.cartAbandonments,
    required this.cartAbandonmentRate,
    required this.topSearchTerms,
    required this.deviceUsage,
    required this.locationData,
  });
}

class RealTimeMetrics {
  final int currentActiveUsers;
  final int currentSessions;
  final int currentOrders;
  final int currentCartAdditions;
  final int currentProductViews;
  final List<LiveUser> liveUsers;
  final List<LiveOrder> liveOrders;

  const RealTimeMetrics({
    required this.currentActiveUsers,
    required this.currentSessions,
    required this.currentOrders,
    required this.currentCartAdditions,
    required this.currentProductViews,
    required this.liveUsers,
    required this.liveOrders,
  });
}

class ChartDataPoint {
  final String label;
  final double value;
  final DateTime date;
  final String? category;

  const ChartDataPoint({
    required this.label,
    required this.value,
    required this.date,
    this.category,
  });
}

class TopProduct {
  final String id;
  final String name;
  final String imageUrl;
  final int views;
  final int sales;
  final double revenue;
  final double conversionRate;
  final int stock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TopProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.views,
    required this.sales,
    required this.revenue,
    required this.conversionRate,
    required this.stock,
    this.createdAt,
    this.updatedAt,
  });
}

class TopCategory {
  final String name;
  final int views;
  final int sales;
  final double revenue;
  final double conversionRate;
  final int productCount;

  const TopCategory({
    required this.name,
    required this.views,
    required this.sales,
    required this.revenue,
    required this.conversionRate,
    required this.productCount,
  });
}

class RecentOrder {
  final String id;
  final String customerName;
  final String customerEmail;
  final double amount;
  final String status;
  final DateTime createdAt;
  final List<String> products;

  const RecentOrder({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.products,
  });
}

class CustomerActivity {
  final String id;
  final String name;
  final String email;
  final String activity;
  final DateTime timestamp;
  final String? productName;
  final double? amount;

  const CustomerActivity({
    required this.id,
    required this.name,
    required this.email,
    required this.activity,
    required this.timestamp,
    this.productName,
    this.amount,
  });
}

class LiveUser {
  final String id;
  final String name;
  final String email;
  final String currentPage;
  final DateTime lastActivity;
  final String device;
  final String location;

  const LiveUser({
    required this.id,
    required this.name,
    required this.email,
    required this.currentPage,
    required this.lastActivity,
    required this.device,
    required this.location,
  });
}

class LiveOrder {
  final String id;
  final String customerName;
  final double amount;
  final String status;
  final DateTime createdAt;
  final List<String> products;

  const LiveOrder({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.products,
  });
}

// Analytics Time Periods
enum AnalyticsPeriod { today, week, month, quarter, year, allTime }

// Analytics Chart Types
enum ChartType { line, bar, pie, area, donut }

// Analytics Filter Options
class AnalyticsFilter {
  final AnalyticsPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? product;
  final String? customer;

  const AnalyticsFilter({
    required this.period,
    this.startDate,
    this.endDate,
    this.category,
    this.product,
    this.customer,
  });

  AnalyticsFilter copyWith({
    AnalyticsPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? product,
    String? customer,
  }) {
    return AnalyticsFilter(
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      product: product ?? this.product,
      customer: customer ?? this.customer,
    );
  }
}

class ShipmentOverview {
  final List<ChartDataPoint> shipments;
  final List<ChartDataPoint> delivered;

  const ShipmentOverview({required this.shipments, required this.delivered});
}
