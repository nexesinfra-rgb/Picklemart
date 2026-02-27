class ProductViewSession {
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final int viewCount;

  const ProductViewSession({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.viewCount = 1,
  });

  ProductViewSession copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    int? viewCount,
  }) => ProductViewSession(
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    productImage: productImage ?? this.productImage,
    productPrice: productPrice ?? this.productPrice,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    duration: duration ?? this.duration,
    viewCount: viewCount ?? this.viewCount,
  );
}

class CustomerBrowsingAnalytics {
  final String customerId;
  final String customerName;
  final String customerEmail;
  final List<ProductViewSession> productViews;
  final DateTime lastViewedAt;
  final Duration totalBrowsingTime;
  final int totalProductsViewed;
  final int totalViewSessions;

  const CustomerBrowsingAnalytics({
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.productViews,
    required this.lastViewedAt,
    required this.totalBrowsingTime,
    required this.totalProductsViewed,
    required this.totalViewSessions,
  });

  CustomerBrowsingAnalytics copyWith({
    String? customerId,
    String? customerName,
    String? customerEmail,
    List<ProductViewSession>? productViews,
    DateTime? lastViewedAt,
    Duration? totalBrowsingTime,
    int? totalProductsViewed,
    int? totalViewSessions,
  }) => CustomerBrowsingAnalytics(
    customerId: customerId ?? this.customerId,
    customerName: customerName ?? this.customerName,
    customerEmail: customerEmail ?? this.customerEmail,
    productViews: productViews ?? this.productViews,
    lastViewedAt: lastViewedAt ?? this.lastViewedAt,
    totalBrowsingTime: totalBrowsingTime ?? this.totalBrowsingTime,
    totalProductsViewed: totalProductsViewed ?? this.totalProductsViewed,
    totalViewSessions: totalViewSessions ?? this.totalViewSessions,
  );

  // Helper methods
  List<ProductViewSession> getMostViewedProducts() {
    final sortedViews = List<ProductViewSession>.from(productViews);
    sortedViews.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sortedViews;
  }

  List<ProductViewSession> getLongestViewedProducts() {
    final sortedViews = List<ProductViewSession>.from(productViews);
    sortedViews.sort((a, b) => b.duration.compareTo(a.duration));
    return sortedViews;
  }

  List<ProductViewSession> getRecentlyViewedProducts() {
    final sortedViews = List<ProductViewSession>.from(productViews);
    sortedViews.sort((a, b) => b.endTime.compareTo(a.endTime));
    return sortedViews;
  }

  Duration getTotalTimeForProduct(String productId) {
    final productViews = this.productViews.where((view) => view.productId == productId);
    return productViews.fold(Duration.zero, (total, view) => total + view.duration);
  }

  int getTotalViewsForProduct(String productId) {
    return productViews.where((view) => view.productId == productId).length;
  }
}

enum BrowsingSortType {
  mostViewed,
  longestViewed,
  recentlyViewed,
  alphabetical,
}

enum BrowsingFilterType {
  all,
  last24Hours,
  last7Days,
  last30Days,
  last90Days,
}