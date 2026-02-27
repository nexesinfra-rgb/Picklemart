import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/layout/responsive.dart';
import '../data/analytics_models.dart';
import '../data/analytics_provider.dart';
import '../application/admin_analytics_controller.dart';
import '../../catalog/data/shared_product_provider.dart';
import 'product_analytics_detail_screen.dart';
import '../application/admin_customer_controller.dart';
import '../../orders/data/order_model.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  DateTimeRange? _ordersDateRange;
  AnalyticsPeriod _orderShipmentPeriod = AnalyticsPeriod.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(adminAnalyticsControllerProvider);
    final realTimeMetrics = ref.watch(realTimeAnalyticsProvider);
    final customerState = ref.watch(adminCustomerControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Analytics',
        showBackButton: true,
        body: _buildBody(
          context,
          analyticsState,
          realTimeMetrics,
          customerState,
          width,
          bp,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminAnalyticsState analyticsState,
    RealTimeMetrics realTimeMetrics,
    AdminCustomerState customerState,
    double width,
    AppBreakpoint bp,
  ) {
    if (analyticsState.loading && analyticsState.analyticsData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading analytics data...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    if (analyticsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.warning_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading analytics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              analyticsState.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(adminAnalyticsControllerProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final analyticsData = analyticsState.analyticsData;
    if (analyticsData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          if (width >= 600) _buildFilterBar(context, width, bp),
          _buildTabBar(context, width, bp),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(analyticsData, realTimeMetrics, width, bp),
                _buildCustomersTab(customerState, width, bp),
                _buildProductsTab(analyticsData, width, bp),
                _buildOrdersTab(analyticsData, width, bp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, double width, AppBreakpoint bp) {
    final isCompact = bp == AppBreakpoint.compact;
    final padding = Responsive.getResponsivePadding(width);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Analytics Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 18.0 : 20.0,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_list, size: isCompact ? 20.0 : 24.0),
            tooltip: 'Filter',
            onPressed: () {
              // Filter functionality would go here
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, double width, AppBreakpoint bp) {
    final isCompact = bp == AppBreakpoint.compact;
    final isSmallScreen = width < 600;
    final isUltraCompact = Responsive.isUltraCompactDevice(width);

    // Responsive sizing based on width
    final iconSize = isUltraCompact ? 16.0 : (isCompact ? 18.0 : 20.0);
    final fontSize = isUltraCompact ? 10.0 : (isCompact ? 12.0 : 14.0);
    // Reduced spacing between tabs for tighter, cleaner appearance
    final horizontalPadding = isUltraCompact ? 6.0 : (isCompact ? 8.0 : 10.0);
    final verticalPadding = isUltraCompact ? 8.0 : 4.0;
    final labelPadding = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
    final indicatorWeight = isUltraCompact ? 2.0 : 3.0;
    // Reduced horizontal padding for tighter spacing
    final tabBarHorizontalPadding =
        isUltraCompact ? 8.0 : (isCompact ? 12.0 : 16.0);
    final tabBarPadding = EdgeInsets.symmetric(
      horizontal: tabBarHorizontalPadding,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isUltraCompact,
        padding: tabBarPadding,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: indicatorWeight,
        labelStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
        ),
        labelPadding: labelPadding,
        tabAlignment: isUltraCompact ? TabAlignment.start : TabAlignment.fill,
        tabs: [
          Tab(
            icon: Icon(Ionicons.stats_chart_outline, size: iconSize),
            text: 'Overview',
          ),
          Tab(
            icon: Icon(Ionicons.people_outline, size: iconSize),
            text: 'Stores',
          ),
          Tab(
            icon: Icon(Ionicons.cube_outline, size: iconSize),
            text: 'Products',
          ),
          Tab(
            icon: Icon(Ionicons.receipt_outline, size: iconSize),
            text: 'Orders',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    AnalyticsData data,
    RealTimeMetrics realTime,
    double width,
    AppBreakpoint bp,
  ) {
    final isCompact = bp == AppBreakpoint.compact;
    final crossAxisCount = _getCrossAxisCount(width, bp);
    final padding = Responsive.getResponsivePadding(width);
    final sectionSpacing = Responsive.getResponsiveSpacing(width) * 1.5;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time metrics
          _buildRealTimeMetrics(realTime, isCompact),
          SizedBox(height: sectionSpacing),

          // Key metrics cards
          _buildMetricsGrid(data, isCompact, crossAxisCount),
          SizedBox(height: sectionSpacing),

          // Charts section
          _buildChartsSection(data, isCompact),
          SizedBox(height: sectionSpacing),

          // Recent activity
          _buildRecentActivity(data, isCompact),
          SizedBox(height: sectionSpacing * 0.5), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildRealTimeMetrics(RealTimeMetrics metrics, bool isCompact) {
    final width = MediaQuery.of(context).size.width;
    final padding = Responsive.getResponsivePadding(width);
    final spacing = Responsive.getResponsiveSpacing(width);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Ionicons.pulse_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Real-time Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 18.0 : 20.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            LayoutBuilder(
              builder: (context, constraints) {
                // For mobile view (width < 600), show 2 cards per row
                if (width < 600) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              'Active Users',
                              '${metrics.currentActiveUsers}',
                              Ionicons.people_outline,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(width: spacing / 2),
                          Expanded(
                            child: _buildMetricItem(
                              'Current Sessions',
                              '${metrics.currentSessions}',
                              Ionicons.eye_outline,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricItem(
                              'Current Orders',
                              '${metrics.currentOrders}',
                              Ionicons.trending_up_outline,
                              Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: SizedBox(),
                          ), // Empty space for alignment
                        ],
                      ),
                    ],
                  );
                }
                // For larger screens, show 3 cards in a row
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Active Users',
                        '${metrics.currentActiveUsers}',
                        Ionicons.people_outline,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: spacing / 2),
                    Expanded(
                      child: _buildMetricItem(
                        'Current Sessions',
                        '${metrics.currentSessions}',
                        Ionicons.eye_outline,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: spacing / 2),
                    Expanded(
                      child: _buildMetricItem(
                        'Current Orders',
                        '${metrics.currentOrders}',
                        Ionicons.trending_up_outline,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 600;

    // Responsive sizing following 8dp grid
    final iconSize = isCompact ? 22.0 : 26.0;
    final spacing = isCompact ? 8.0 : 12.0;
    final valueFontSize = isCompact ? 18.0 : 22.0;
    final labelFontSize = isCompact ? 11.0 : 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 6.0 : 8.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(height: spacing),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: valueFontSize,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(height: spacing / 2),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(
    AnalyticsData data,
    bool isCompact,
    int crossAxisCount,
  ) {
    // Responsive spacing and aspect ratio
    final spacing = isCompact ? 12.0 : 16.0;
    final aspectRatio = isCompact ? 1.4 : 1.6;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: [
        _buildMetricCard(
          'Total Revenue',
          '₹${data.revenueMetrics.totalRevenue.toStringAsFixed(2)}',
          Ionicons.cash_outline,
          Colors.green,
          isCompact,
        ),
        _buildMetricCard(
          'Total Orders',
          '${data.orderMetrics.totalOrders}',
          Ionicons.receipt_outline,
          Colors.blue,
          isCompact,
        ),
        _buildMetricCard(
          'Total Stores',
          '${data.customerMetrics.totalCustomers}',
          Ionicons.people_outline,
          Colors.orange,
          isCompact,
        ),
        _buildMetricCard(
          'Conversion Rate',
          '${data.revenueMetrics.conversionRate.toStringAsFixed(1)}%',
          Ionicons.trending_up_outline,
          Colors.purple,
          isCompact,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isCompact,
  ) {
    // Responsive sizing following 8dp grid
    final padding = isCompact ? 14.0 : 18.0;
    final iconSize = isCompact ? 24.0 : 32.0;
    final spacing = isCompact ? 8.0 : 12.0;
    final valueFontSize = isCompact ? 18.0 : 24.0;
    final titleFontSize = isCompact ? 11.0 : 13.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 8.0 : 10.0),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  SizedBox(height: spacing),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: valueFontSize,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: spacing / 2),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection(AnalyticsData data, bool isCompact) {
    final width = MediaQuery.of(context).size.width;
    final padding = Responsive.getResponsivePadding(width);
    final spacing = Responsive.getResponsiveSpacing(width);
    final chartHeight = isCompact ? 180.0 : 240.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Ionicons.bar_chart_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Performance Charts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 18.0 : 20.0,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue Trend (Last 30 days)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: isCompact ? 14.0 : 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing),
                SizedBox(
                  height: chartHeight,
                  child: _RevenueTrendChart(points: data.revenueChart),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(AnalyticsData data, bool isCompact) {
    final width = MediaQuery.of(context).size.width;
    final padding = Responsive.getResponsivePadding(width);
    final spacing = Responsive.getResponsiveSpacing(width);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Ionicons.time_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 18.0 : 20.0,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: padding.horizontal,
              vertical: padding.vertical / 2,
            ),
            child:
                data.recentOrders.isEmpty
                    ? Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: isCompact ? 8.0 : 12.0,
                      ),
                      child: Text(
                        'No recent activity yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          data.recentOrders
                              .take(20)
                              .map(
                                (order) => ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isCompact ? 8.0 : 16.0,
                                    vertical: isCompact ? 4.0 : 8.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.shopping_cart,
                                      size: isCompact ? 18.0 : 20.0,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    'Order #${order.id}',
                                    style: TextStyle(
                                      fontSize: isCompact ? 13.0 : 14.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '₹${order.amount.toStringAsFixed(2)} · ${_formatRelativeTime(order.createdAt)}',
                                    style: TextStyle(
                                      fontSize: isCompact ? 11.0 : 12.0,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      order.status,
                                      style: TextStyle(
                                        fontSize: isCompact ? 10.0 : 11.0,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomersTab(
    AdminCustomerState customerState,
    double width,
    AppBreakpoint bp,
  ) {
    final isCompact = bp == AppBreakpoint.compact;
    final padding = Responsive.getResponsivePadding(width);
    final spacing = Responsive.getResponsiveSpacing(width);

    final customers =
        customerState.filteredCustomers.isNotEmpty ||
                customerState.searchQuery.isNotEmpty
            ? customerState.filteredCustomers
            : customerState.customers;

    // Limit the number of rendered rows to keep the first analytics view snappy
    const maxVisibleCustomers = 100;
    final visibleCustomers =
        customers.length > maxVisibleCustomers
            ? customers.take(maxVisibleCustomers).toList()
            : customers;

    Widget buildBody() {
      if (customerState.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.warning_outline,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Error loading stores',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  customerState.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(adminCustomerControllerProvider.notifier)
                      .loadCustomers();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (customers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.people_outline,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.25),
              ),
              const SizedBox(height: 12),
              Text(
                'No stores yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Stores will appear here as they place orders or sign up.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Stores',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 18.0 : 20.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  customers.length > maxVisibleCustomers
                      ? '${visibleCustomers.length} shown · ${customers.length} total'
                      : '${customers.length} total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search stores by name, email or phone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (value) {
              ref
                  .read(adminCustomerControllerProvider.notifier)
                  .searchCustomers(value);
            },
          ),
          SizedBox(height: spacing),
          if (customerState.loading)
            Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Refreshing stores…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleCustomers.length,
            separatorBuilder: (_, __) => SizedBox(height: spacing / 2),
            itemBuilder: (context, index) {
              final customer = visibleCustomers[index];

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    context.pushNamed(
                      'admin-customer-analytics',
                      extra: {
                        'customerId': customer.id,
                        'customerName': customer.name,
                        'customerEmail': customer.email,
                        'customerPhone': customer.phone,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            Ionicons.person_outline,
                            size: isCompact ? 20.0 : 22.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      customer.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isCompact ? 14.0 : 15.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (customer.isActive
                                              ? Colors.green
                                              : Colors.red)
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      customer.isActive ? 'Active' : 'Inactive',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color:
                                            customer.isActive
                                                ? Colors.green
                                                : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (customer.alias != null &&
                                  customer.alias!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  customer.alias!,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        customer.email,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        customer.phone,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Orders: ${customer.totalOrders}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Total spent: ₹${customer.totalSpent.toStringAsFixed(2)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              if (customer.lastOrderDate != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Last order: ${_formatRelativeTime(customer.lastOrderDate!)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return SingleChildScrollView(padding: padding, child: buildBody());
  }

  Widget _buildProductsTab(AnalyticsData data, double width, AppBreakpoint bp) {
    final isCompact = bp == AppBreakpoint.compact;
    final padding = Responsive.getResponsivePadding(width);
    final spacing = Responsive.getResponsiveSpacing(width);
    final products = data.topProducts;
    final fallbackProducts =
        ref
            .watch(sharedProductProvider)
            .products; // Fallback to catalog products

    String? formatDate(DateTime? date) {
      if (date == null) return null;
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    Widget buildEmptyState() {
      return Center(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing * 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Ionicons.cube_outline,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                SizedBox(height: spacing),
                Text(
                  'No products found',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: spacing / 2),
                Text(
                  'Product analytics data will appear here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: isCompact ? 13.0 : 14.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildProductCard({
      required String productId,
      required String name,
      required String imageUrl,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      final createdLabel = formatDate(createdAt);
      final updatedLabel = formatDate(updatedAt);

      return Card(
        elevation: 0,
        margin: EdgeInsets.only(bottom: spacing),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => ProductAnalyticsDetailScreen(
                      productId: productId,
                      productName: name,
                    ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Image.network(
                      imageUrl,
                      width: isCompact ? 64 : 80,
                      height: isCompact ? 64 : 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stack) => Container(
                            width: isCompact ? 64 : 80,
                            height: isCompact ? 64 : 80,
                            child: Icon(
                              Ionicons.image_outline,
                              size: isCompact ? 24 : 32,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                    ),
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 14.0 : 16.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (createdLabel != null)
                        Text(
                          'Added: $createdLabel',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (updatedLabel != null)
                        Text(
                          'Last updated: $updatedLabel',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Ionicons.chevron_forward_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 18.0 : 20.0,
            ),
          ),
          SizedBox(height: spacing * 2),
          if (products.isNotEmpty)
            Column(
              children: [
                ...products.map(
                  (p) => buildProductCard(
                    productId: p.id,
                    name: p.name,
                    imageUrl: p.imageUrl,
                    createdAt: p.createdAt,
                    updatedAt: p.updatedAt,
                  ),
                ),
              ],
            )
          else if (fallbackProducts.isNotEmpty)
            Column(
              children: [
                ...fallbackProducts.map(
                  (p) => buildProductCard(
                    productId: p.id,
                    name: p.name,
                    imageUrl: p.imageUrl,
                    createdAt: p.createdAt,
                    updatedAt: p.updatedAt,
                  ),
                ),
              ],
            )
          else
            buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(AnalyticsData data, double width, AppBreakpoint bp) {
    final isCompact = bp == AppBreakpoint.compact;
    final padding = Responsive.getResponsivePadding(width);
    final spacing = Responsive.getResponsiveSpacing(width);
    final metrics = data.orderMetrics;
    final shipmentOverview = data.shipmentOverview;
    final processingCount = math.max(
      0,
      metrics.pendingOrders - metrics.confirmedOrders,
    );

    final statusCardWidth =
        math.max((width - padding.horizontal - spacing) / 2, 140).toDouble();

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 18.0 : 20.0,
            ),
          ),
          SizedBox(height: spacing / 2),
          Text(
            'Performance Insights & KPIs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: isCompact ? 13.0 : 14.0,
            ),
          ),
          SizedBox(height: spacing),
          _buildOrdersDateRow(context, spacing),
          SizedBox(height: spacing * 1.25),
          Text(
            'Order Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: spacing * 0.75),
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(
                width: statusCardWidth,
                child: _StatusCardButton(
                  onTap: () => _navigateToOrders(context, null),
                  child: _MetricCard(
                    title: 'Total Orders',
                    subtitle: 'All time orders',
                    value: metrics.totalOrders.toString(),
                    change: metrics.orderGrowthRate,
                    icon: Ionicons.receipt_outline,
                    baseColor: Colors.blue,
                    width: width,
                  ),
                ),
              ),
              SizedBox(
                width: statusCardWidth,
                child: _StatusCardButton(
                  onTap:
                      () => _navigateToOrders(context, OrderStatus.processing),
                  child: _MetricCard(
                    title: 'Order Pending',
                    subtitle: 'Currently processing',
                    value: processingCount.toString(),
                    change: null,
                    icon: Ionicons.hourglass_outline,
                    baseColor: OrderStatus.processing.color,
                    width: width,
                  ),
                ),
              ),
              SizedBox(
                width: statusCardWidth,
                child: _StatusCardButton(
                  onTap:
                      () => _navigateToOrders(context, OrderStatus.cancelled),
                  child: _MetricCard(
                    title: 'Cancelled',
                    subtitle: 'Cancelled orders',
                    value: metrics.cancelledOrders.toString(),
                    change: null,
                    icon: Ionicons.close_circle_outline,
                    baseColor: OrderStatus.cancelled.color,
                    width: width,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 2),
          _buildPeriodToggle(context, spacing),
          SizedBox(height: spacing),
          _buildShipmentChartCard(
            context,
            shipmentOverview,
            spacing,
            isCompact,
          ),
          SizedBox(height: spacing * 2),
          Text(
            'Delivery',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: spacing * 0.75),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive aspect ratio based on width
              // For 288px width: (288 - 32 padding - 12 spacing) / 2 = 122px per card
              // Increased aspect ratio for more compact cards
              final aspectRatio = width < 400 ? 1.08 : 1.13;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
                children: [
                  _MetricCard(
                    title: 'Delivery Success',
                    subtitle: 'Total processed',
                    value: '${metrics.deliverySuccessRate.toStringAsFixed(1)}%',
                    change: metrics.deliverySuccessRate - 100,
                    icon: Ionicons.checkmark_done_circle_outline,
                    baseColor: Colors.teal,
                    width: width,
                  ),
                  _MetricCard(
                    title: 'Avg Delivery Time',
                    subtitle: 'Days to deliver',
                    value:
                        '${metrics.averageDeliveryTimeDays.toStringAsFixed(1)} days',
                    change: metrics.averageDeliveryTimeDays * -0.1,
                    icon: Ionicons.speedometer_outline,
                    baseColor: Colors.blueGrey,
                    width: width,
                  ),
                  _MetricCard(
                    title: 'Delayed Shipments',
                    subtitle: 'Past promised date',
                    value: metrics.delayedShipments.toString(),
                    change: -metrics.orderGrowthRate,
                    icon: Ionicons.time_outline,
                    baseColor: Colors.orange,
                    width: width,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(BuildContext context, double spacing) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(spacing / 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PeriodPill(
                label: 'Weekly',
                selected: _orderShipmentPeriod == AnalyticsPeriod.week,
                onTap:
                    () => setState(
                      () => _orderShipmentPeriod = AnalyticsPeriod.week,
                    ),
              ),
              SizedBox(width: spacing / 4),
              _PeriodPill(
                label: 'Monthly',
                selected: _orderShipmentPeriod == AnalyticsPeriod.month,
                onTap:
                    () => setState(
                      () => _orderShipmentPeriod = AnalyticsPeriod.month,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShipmentChartCard(
    BuildContext context,
    ShipmentOverview overview,
    double spacing,
    bool isCompact,
  ) {
    final theme = Theme.of(context);
    final labels = _pickLabels(overview.shipments);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(spacing * 1.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: spacing * 0.5),
            Text(
              'Shipments Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacing * 0.5),
            Row(
              children: [
                _LegendDot(color: theme.colorScheme.primary),
                SizedBox(width: 6),
                Text(
                  'Shipments',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: spacing),
                _LegendDot(color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'Processed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            SizedBox(
              height: isCompact ? 200 : 220,
              child: _ShipmentsChart(
                shipments: overview.shipments,
                delivered: overview.delivered,
                primaryColor: theme.colorScheme.primary,
              ),
            ),
            if (labels.isNotEmpty) ...[
              SizedBox(height: spacing / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    labels
                        .map(
                          (label) => Expanded(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToOrders(BuildContext context, OrderStatus? status) {
    final qp = <String, String>{'previousRoute': '/admin/analytics'};
    if (status != null) {
      qp['status'] = status.urlValue;
    }
    context.goNamed('admin-orders', queryParameters: qp);
  }

  Widget _buildOrdersDateRow(BuildContext context, double spacing) {
    final rangeLabel =
        _ordersDateRange == null
            ? 'All time'
            : '${_ordersDateRange!.start.month}/${_ordersDateRange!.start.day} - ${_ordersDateRange!.end.month}/${_ordersDateRange!.end.day}';
    return Row(
      children: [
        Expanded(
          child: Text(
            'Orders by date',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Ionicons.calendar_outline, size: 18),
          label: Text(rangeLabel),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: spacing,
              vertical: spacing * 0.6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _pickOrdersDateRange(context),
        ),
      ],
    );
  }

  Future<void> _pickOrdersDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialDateRange =
        _ordersDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialDateRange,
      helpText: 'Filter orders by date',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: Theme.of(ctx).colorScheme.primary,
              onPrimary: Theme.of(ctx).colorScheme.onPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() {
      _ordersDateRange = picked;
    });
    // Logic intentionally not wired to filters (UI-only as requested)
  }

  Widget _buildStatusChips(double spacing, double chipWidth) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing / 2,
      children:
          OrderStatus.values
              .where(
                (s) => s != OrderStatus.shipped && s != OrderStatus.delivered,
              )
              .map(
                (status) => SizedBox(
                  width: chipWidth,
                  child: Chip(
                    label: Text(
                      status.displayName,
                      style: TextStyle(
                        color: status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    avatar: Icon(status.icon, color: status.color, size: 18),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: status.color.withOpacity(0.6),
                        width: 1.2,
                      ),
                    ),
                    backgroundColor: status.color.withOpacity(0.08),
                  ),
                ),
              )
              .toList(),
    );
  }

  List<String> _pickLabels(List<ChartDataPoint> points) {
    if (points.isEmpty) return [];
    final desired = points.length <= 7 ? points.length : 7;
    final step = (points.length / desired).ceil();
    final labels = <String>[];
    for (int i = 0; i < points.length; i += step) {
      labels.add(points[i].label);
      if (labels.length == desired) break;
    }
    if (labels.isEmpty) {
      labels.add(points.first.label);
    }
    return labels;
  }

  int _getCrossAxisCount(double width, AppBreakpoint bp) {
    if (bp == AppBreakpoint.compact) {
      return 2;
    } else if (width < 1200) {
      return 3;
    } else {
      return 4;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.baseColor,
    required this.width,
    this.change,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color baseColor;
  final double width;
  final double? change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = (change ?? 0) >= 0;
    final changeText =
        change == null
            ? null
            : '${isPositive ? '+' : ''}${change!.toStringAsFixed(1)}%';

    // Responsive sizing based on width
    final isCompact = width < 400;
    final cardPadding = isCompact ? 10.0 : 12.0;
    final iconSize = isCompact ? 18.0 : 22.0;
    final iconPadding = isCompact ? 6.0 : 8.0;
    final valueFontSize = isCompact ? 20.0 : 24.0;
    final titleFontSize = isCompact ? 13.0 : 15.0;
    final subtitleFontSize = isCompact ? 12.0 : 13.0;
    final changeIconSize = isCompact ? 11.0 : 12.0;
    final changeFontSize = isCompact ? 11.0 : 12.0;
    final spacing1 = isCompact ? 5.0 : 7.0;
    final spacing2 = isCompact ? 2.0 : 3.0;
    final spacing3 = isCompact ? 2.0 : 2.0;

    return Container(
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withOpacity(0.15)),
      ),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: baseColor, size: iconSize),
              ),
              const Spacer(),
              if (changeText != null)
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 4.0 : 6.0,
                      vertical: isCompact ? 3.0 : 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.red)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Ionicons.trending_up_outline
                              : Ionicons.trending_down_outline,
                          size: changeIconSize,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: isCompact ? 1.0 : 2.0),
                        Flexible(
                          child: Text(
                            changeText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isPositive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: changeFontSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: spacing1),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: valueFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing2),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: titleFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing3),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: subtitleFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusCardButton extends StatelessWidget {
  const _StatusCardButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected
                  ? theme.colorScheme.onSurface.withOpacity(
                    theme.brightness == Brightness.dark ? 0.15 : 0.9,
                  )
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color:
                selected
                    ? theme.colorScheme.surface
                    : theme.colorScheme.onSurface.withOpacity(0.8),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  const _RevenueTrendChart({required this.points});

  final List<ChartDataPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: CustomPaint(
        painter: _RevenueTrendPainter(
          points: points,
          lineColor: theme.colorScheme.primary,
          gridColor: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
    );
  }
}

class _RevenueTrendPainter extends CustomPainter {
  _RevenueTrendPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
  });

  final List<ChartDataPoint> points;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid =
        Paint()
          ..color = gridColor
          ..strokeWidth = 1;

    // Draw horizontal grid lines (3)
    final gridStep = size.height / 3;
    for (var i = 1; i <= 3; i++) {
      final y = i * gridStep;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (points.isEmpty) {
      return;
    }

    final maxValue = points
        .map((p) => p.value)
        .fold<double>(0, (prev, v) => v > prev ? v : prev);
    if (maxValue <= 0) {
      return;
    }

    final path = Path();
    final count = points.length;
    final dx = count > 1 ? size.width / (count - 1) : 0;

    for (var i = 0; i < count; i++) {
      final double x = (dx * i).toDouble();
      final normalized = points[i].value / maxValue;
      final double y = size.height - (normalized * (size.height - 8.0)) - 4.0;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paintLine =
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant _RevenueTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _ShipmentsChart extends StatelessWidget {
  const _ShipmentsChart({
    required this.shipments,
    required this.delivered,
    required this.primaryColor,
  });

  final List<ChartDataPoint> shipments;
  final List<ChartDataPoint> delivered;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty && delivered.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return CustomPaint(
      size: Size.infinite,
      painter: _DualLineChartPainter(
        shipments: shipments,
        delivered: delivered,
        shipmentColor: primaryColor,
        deliveredColor: Colors.green,
      ),
    );
  }
}

class _DualLineChartPainter extends CustomPainter {
  final List<ChartDataPoint> shipments;
  final List<ChartDataPoint> delivered;
  final Color shipmentColor;
  final Color deliveredColor;

  _DualLineChartPainter({
    required this.shipments,
    required this.delivered,
    required this.shipmentColor,
    required this.deliveredColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shipments.isEmpty && delivered.isEmpty) return;

    final paintShipment =
        Paint()
          ..color = shipmentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    final paintDelivered =
        Paint()
          ..color = deliveredColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    final fillPaintShipment =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              shipmentColor.withOpacity(0.3),
              shipmentColor.withOpacity(0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final maxVal = _getMaxValue();
    if (maxVal == 0) return;

    _drawPath(
      canvas,
      size,
      shipments,
      paintShipment,
      fillPaintShipment,
      maxVal,
    );
    _drawPath(canvas, size, delivered, paintDelivered, null, maxVal);
  }

  double _getMaxValue() {
    double max = 0;
    for (var p in shipments) {
      if (p.value > max) max = p.value;
    }
    for (var p in delivered) {
      if (p.value > max) max = p.value;
    }
    return max == 0 ? 10 : max * 1.2;
  }

  void _drawPath(
    Canvas canvas,
    Size size,
    List<ChartDataPoint> points,
    Paint linePaint,
    Paint? fillPaint,
    double maxVal,
  ) {
    if (points.length < 2) return;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i].value / maxVal * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (fillPaint != null) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

String _formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} h ago';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays} days ago';

  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}
