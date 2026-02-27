import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../application/customer_browsing_controller.dart';
import '../domain/customer_browsing_analytics.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'customer_product_view_detail_screen.dart';

class CustomerBrowsingAnalyticsScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final String customerEmail;

  const CustomerBrowsingAnalyticsScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
  });

  @override
  ConsumerState<CustomerBrowsingAnalyticsScreen> createState() =>
      _CustomerBrowsingAnalyticsScreenState();
}

class _CustomerBrowsingAnalyticsScreenState
    extends ConsumerState<CustomerBrowsingAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(customerBrowsingControllerProvider.notifier)
          .loadCustomerBrowsingAnalytics(
            widget.customerId,
            customerName: widget.customerName,
            customerEmail: widget.customerEmail,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final browsingState = ref.watch(customerBrowsingControllerProvider);
    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;
    final isMobile = screenSize == ScreenSize.mobile;

    return AdminAuthGuard(
      child: Scaffold(
        appBar: isMobile ? _buildMobileAppBar(context, browsingState) : null,
        body: _buildMainContent(context, browsingState, screenSize, width),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    CustomerBrowsingState browsingState,
  ) {
    return AppBar(
      title: const Text('Browsing Analytics'),
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          }
        },
        icon: const Icon(Ionicons.arrow_back),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    CustomerBrowsingState browsingState,
    ScreenSize screenSize,
    double width,
  ) {
    if (browsingState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (browsingState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.alert_circle_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading browsing analytics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              browsingState.error!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(customerBrowsingControllerProvider.notifier)
                    .loadCustomerBrowsingAnalytics(
                      widget.customerId,
                      customerName: widget.customerName,
                      customerEmail: widget.customerEmail,
                    );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final analytics = browsingState.analytics;
    if (analytics == null) {
      return const Center(child: Text('No browsing data available'));
    }

    final isMobile = screenSize == ScreenSize.mobile;
    final padding = isMobile ? 16.0 : 24.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (only for desktop)
          if (!isMobile) ...[
            _buildHeader(context, analytics),
            const SizedBox(height: 24),
          ],

          // Stats Cards
          _buildStatsCards(context, analytics, isMobile),
          const SizedBox(height: 24),

          // Filters and Sort
          _buildFiltersAndSort(context, browsingState, isMobile),
          const SizedBox(height: 16),

          // Products List
          Expanded(child: _buildProductsList(context, browsingState)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CustomerBrowsingAnalytics analytics,
  ) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          icon: const Icon(Ionicons.arrow_back),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browsing Analytics',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${analytics.customerName} (${analytics.customerEmail})',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    CustomerBrowsingAnalytics analytics,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        children: [
          // First row - 2 cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Products Viewed',
                  analytics.totalProductsViewed.toString(),
                  Ionicons.grid_outline,
                  Colors.blue,
                  isMobile: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total View Sessions',
                  analytics.totalViewSessions.toString(),
                  Ionicons.eye_outline,
                  Colors.green,
                  isMobile: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row - 2 cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Browsing Time',
                  _formatDuration(analytics.totalBrowsingTime),
                  Ionicons.time_outline,
                  Colors.orange,
                  isMobile: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Last Viewed',
                  _formatDate(analytics.lastViewedAt),
                  Ionicons.calendar_outline,
                  Colors.purple,
                  isMobile: true,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Total Products Viewed',
              analytics.totalProductsViewed.toString(),
              Ionicons.grid_outline,
              Colors.blue,
              isMobile: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              'Total View Sessions',
              analytics.totalViewSessions.toString(),
              Ionicons.eye_outline,
              Colors.green,
              isMobile: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              'Total Browsing Time',
              _formatDuration(analytics.totalBrowsingTime),
              Ionicons.time_outline,
              Colors.orange,
              isMobile: false,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              'Last Viewed',
              _formatDate(analytics.lastViewedAt),
              Ionicons.calendar_outline,
              Colors.purple,
              isMobile: false,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    required bool isMobile,
  }) {
    final padding = isMobile ? 12.0 : 20.0;
    final iconSize = isMobile ? 24.0 : 32.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: isMobile ? 16 : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: isMobile ? 12 : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSort(
    BuildContext context,
    CustomerBrowsingState state,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        children: [
          // Filter Dropdown
          DropdownButtonFormField<BrowsingFilterType>(
            initialValue: state.filterType,
            decoration: const InputDecoration(
              labelText: 'Time Filter',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items:
                BrowsingFilterType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      _getFilterDisplayName(type),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(customerBrowsingControllerProvider.notifier)
                    .updateFilterType(value);
              }
            },
          ),
          const SizedBox(height: 12),
          // Sort Dropdown
          DropdownButtonFormField<BrowsingSortType>(
            initialValue: state.sortType,
            decoration: const InputDecoration(
              labelText: 'Sort By',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items:
                BrowsingSortType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      _getSortDisplayName(type),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(customerBrowsingControllerProvider.notifier)
                    .updateSortType(value);
              }
            },
          ),
        ],
      );
    } else {
      return Row(
        children: [
          // Filter Dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<BrowsingFilterType>(
              initialValue: state.filterType,
              decoration: const InputDecoration(
                labelText: 'Time Filter',
                border: OutlineInputBorder(),
              ),
              items:
                  BrowsingFilterType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getFilterDisplayName(type)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(customerBrowsingControllerProvider.notifier)
                      .updateFilterType(value);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          // Sort Dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<BrowsingSortType>(
              initialValue: state.sortType,
              decoration: const InputDecoration(
                labelText: 'Sort By',
                border: OutlineInputBorder(),
              ),
              items:
                  BrowsingSortType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getSortDisplayName(type)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(customerBrowsingControllerProvider.notifier)
                      .updateSortType(value);
                }
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildProductsList(BuildContext context, CustomerBrowsingState state) {
    final products = state.filteredViews;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.search_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(context, product);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ProductViewSession product) {
    final screenSize = Responsive.getScreenSize(context);
    final isMobile = screenSize == ScreenSize.mobile;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child:
              isMobile
                  ? _buildMobileProductCard(context, product)
                  : _buildDesktopProductCard(context, product),
        ),
      ),
    );
  }

  Widget _buildMobileProductCard(
    BuildContext context,
    ProductViewSession product,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image and Basic Info
        Row(
          children: [
            _buildProductImage(product, size: 60),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.productPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Stats Row
        Row(
          children: [
            _buildInfoChip(context, '${product.viewCount} views', Colors.blue),
            const SizedBox(width: 8),
            _buildInfoChip(
              context,
              _formatDuration(product.duration),
              Colors.orange,
            ),
            const Spacer(),
            Text(
              'Last viewed ${_formatDate(product.endTime)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductImage(
    ProductViewSession product, {
    required double size,
  }) {
    final imageUrl = product.productImage;
    final hasUrl = imageUrl.isNotEmpty;

    Widget placeholder() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Ionicons.image_outline, size: 24),
        );

    if (!hasUrl) return placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder(),
      ),
    );
  }

  Widget _buildDesktopProductCard(
    BuildContext context,
    ProductViewSession product,
  ) {
    return Row(
      children: [
        _buildProductImage(product, size: 80),
        const SizedBox(width: 16),

        // Product Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${product.productPrice.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    '${product.viewCount} views',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    _formatDuration(product.duration),
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Last Viewed
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Last viewed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(product.endTime),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _navigateToProductDetail(ProductViewSession product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CustomerProductViewDetailScreen(
              customerId: widget.customerId,
              customerName: widget.customerName,
              product: product,
            ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    // Ensure duration is always positive (defensive coding for edge cases)
    final absDuration = duration.isNegative ? duration.abs() : duration;
    
    if (absDuration.inHours > 0) {
      return '${absDuration.inHours}h ${absDuration.inMinutes.remainder(60)}m';
    } else if (absDuration.inMinutes > 0) {
      return '${absDuration.inMinutes}m';
    } else {
      return '${absDuration.inSeconds}s';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getFilterDisplayName(BrowsingFilterType type) {
    switch (type) {
      case BrowsingFilterType.all:
        return 'All Time';
      case BrowsingFilterType.last24Hours:
        return 'Last 24 Hours';
      case BrowsingFilterType.last7Days:
        return 'Last 7 Days';
      case BrowsingFilterType.last30Days:
        return 'Last 30 Days';
      case BrowsingFilterType.last90Days:
        return 'Last 90 Days';
    }
  }

  String _getSortDisplayName(BrowsingSortType type) {
    switch (type) {
      case BrowsingSortType.mostViewed:
        return 'Most Viewed';
      case BrowsingSortType.longestViewed:
        return 'Longest Viewed';
      case BrowsingSortType.recentlyViewed:
        return 'Recently Viewed';
      case BrowsingSortType.alphabetical:
        return 'Alphabetical';
    }
  }
}
