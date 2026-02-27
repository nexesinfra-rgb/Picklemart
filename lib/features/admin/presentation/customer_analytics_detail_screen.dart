import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../application/customer_analytics_controller.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'customer_browsing_analytics_screen.dart';

class CustomerAnalyticsDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;

  const CustomerAnalyticsDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
  });

  @override
  ConsumerState<CustomerAnalyticsDetailScreen> createState() =>
      _CustomerAnalyticsDetailScreenState();
}

class _CustomerAnalyticsDetailScreenState
    extends ConsumerState<CustomerAnalyticsDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(customerAnalyticsControllerProvider.notifier)
          .loadCustomerAnalytics(
            widget.customerId,
            customerName: widget.customerName,
            customerEmail: widget.customerEmail,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(customerAnalyticsControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);
    final isCompact = bp == AppBreakpoint.compact;

    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customer Analytics'),
          leading: IconButton(
            icon: const Icon(Ionicons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: _buildBody(context, analyticsState, width, isCompact),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CustomerAnalyticsState state,
    double width,
    bool isCompact,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
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
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(customerAnalyticsControllerProvider.notifier)
                    .loadCustomerAnalytics(
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

    final data = state.data;
    if (data == null) {
      return const Center(child: Text('No data available'));
    }

    final padding = Responsive.getResponsivePadding(width);
    final spacing = Responsive.getResponsiveSpacing(width);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Details Section
          _buildUserDetailsSection(context, data, isCompact, spacing),
          SizedBox(height: spacing),

          // Order Summary Cards
          _buildOrderSummaryCards(context, data, isCompact, spacing),
          SizedBox(height: spacing),

          // Wishlist Section
          _buildWishlistSection(context, data, isCompact, spacing),
          SizedBox(height: spacing / 2),

          // View Products CTA
          _buildViewedProductsButton(context, isCompact, spacing),
          SizedBox(height: spacing),

          // Calendar Section (App Usage)
          _buildCalendarSection(context, data, isCompact, spacing),
          SizedBox(height: spacing),

          // Insights Section
          _buildInsightsSection(context, data, isCompact, spacing),
          SizedBox(height: spacing * 0.5),
        ],
      ),
    );
  }

  Widget _buildUserDetailsSection(
    BuildContext context,
    CustomerAnalyticsData data,
    bool isCompact,
    double spacing,
  ) {
    final profile = data.profile;
    final name = profile?['name'] as String? ?? widget.customerName;
    final email = profile?['email'] as String? ?? widget.customerEmail;
    final phone = profile?['mobile'] as String? ??
        profile?['display_mobile'] as String? ??
        widget.customerPhone ??
        '';
    final createdAtString = profile?['created_at'] as String?;
    final createdAt = createdAtString != null
        ? DateTime.tryParse(createdAtString)
        : null;
    final isActive = true; // Default to active

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: isCompact ? 28.0 : 36.0,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: TextStyle(
                  fontSize: isCompact ? 20.0 : 28.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isCompact ? 18.0 : 20.0,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isActive ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontSize: isCompact ? 11.0 : 12.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing / 2),
                  if (email.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: isCompact ? 14.0 : 16.0,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                        SizedBox(width: spacing / 2),
                        Expanded(
                          child: Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  if (phone.isNotEmpty) ...[
                    SizedBox(height: spacing / 3),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: isCompact ? 14.0 : 16.0,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                        SizedBox(width: spacing / 2),
                        Expanded(
                          child: Text(
                            phone,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (createdAt != null) ...[
                    SizedBox(height: spacing / 3),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: isCompact ? 14.0 : 16.0,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                        SizedBox(width: spacing / 2),
                        Text(
                          'Member since ${_formatDate(createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCards(
    BuildContext context,
    CustomerAnalyticsData data,
    bool isCompact,
    double spacing,
  ) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.blue.withOpacity(0.05),
                  ],
                ),
              ),
              padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Ionicons.receipt_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: spacing),
                  Text(
                    '${data.totalOrders}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: isCompact ? 24.0 : 32.0,
                        ),
                  ),
                  SizedBox(height: spacing / 4),
                  Text(
                    'Total Orders',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withOpacity(0.1),
                    Colors.green.withOpacity(0.05),
                  ],
                ),
              ),
              padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Ionicons.cash_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: spacing),
                  Text(
                    '₹${data.totalSpent.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: isCompact ? 24.0 : 32.0,
                        ),
                  ),
                  SizedBox(height: spacing / 4),
                  Text(
                    'Total Spent',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistSection(
    BuildContext context,
    CustomerAnalyticsData data,
    bool isCompact,
    double spacing,
  ) {
    final wishlist = data.wishlist;
    if (wishlist.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Ionicons.heart_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: spacing / 2),
                  Text(
                    'Wishlist',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 18.0 : 20.0,
                        ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Ionicons.heart_outline,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                    ),
                    SizedBox(height: spacing / 2),
                    Text(
                      'No items in wishlist',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
        child: Column(
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
                    Ionicons.heart_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: spacing / 2),
                Text(
                  'Purchase Later (${wishlist.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 18.0 : 20.0,
                      ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isCompact ? 2 : 3,
                crossAxisSpacing: spacing / 2,
                mainAxisSpacing: spacing / 2,
                childAspectRatio: 0.75,
              ),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final item = wishlist[index];
                final product = item['products'] as Map<String, dynamic>?;
                if (product == null) return const SizedBox.shrink();

                final productName = product['name'] as String? ?? 'Unknown';
                final price = (product['price'] as num?)?.toDouble() ?? 0.0;
                final images =
                    (product['images'] as List<dynamic>?)?.cast<String>();
                final imageUrl = (product['image_url'] as String?) ??
                    (images != null && images.isNotEmpty ? images.first : null);

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: spacing / 4),
                            Text(
                              '₹${price.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewedProductsButton(
    BuildContext context,
    bool isCompact,
    double spacing,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 12.0 : 14.0,
            horizontal: isCompact ? 12.0 : 16.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Ionicons.analytics_outline),
        label: const Text('View Products Viewed'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerBrowsingAnalyticsScreen(
                customerId: widget.customerId,
                customerName: widget.customerName,
                customerEmail: widget.customerEmail,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarSection(
    BuildContext context,
    CustomerAnalyticsData data,
    bool isCompact,
    double spacing,
  ) {
    final sessions = data.sessions;
    if (sessions.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Ionicons.calendar_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: spacing / 2),
                  Text(
                    'App Usage Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 18.0 : 20.0,
                        ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Ionicons.calendar_outline,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                    ),
                    SizedBox(height: spacing / 2),
                    Text(
                      'No app usage data',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Aggregate sessions per day
    final dayCounts = <DateTime, int>{};
    for (final session in sessions) {
      final startedAtString = session['started_at'] as String?;
      if (startedAtString != null) {
        final startedAt = DateTime.tryParse(startedAtString);
        if (startedAt != null) {
          final dayKey = DateTime(startedAt.year, startedAt.month, startedAt.day);
          dayCounts[dayKey] = (dayCounts[dayKey] ?? 0) + 1;
        }
      }

      final lastActivityString = session['last_activity_at'] as String?;
      if (lastActivityString != null) {
        final lastActivity = DateTime.tryParse(lastActivityString);
        if (lastActivity != null) {
          final dayKey =
              DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
          dayCounts[dayKey] = (dayCounts[dayKey] ?? 0) + 1;
        }
      }
    }

    if (dayCounts.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Ionicons.calendar_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: spacing / 2),
                  Text(
                    'App Usage Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 18.0 : 20.0,
                        ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Ionicons.calendar_outline,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                    ),
                    SizedBox(height: spacing / 2),
                    Text(
                      'No app usage data',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedEntries = dayCounts.entries.toList()
      ..sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        if (countComparison != 0) return countComparison;
        return b.key.compareTo(a.key); // show latest dates first on ties
      });

    final topEntries = sortedEntries.take(10).toList();
    final maxCount = topEntries.first.value;

    double opacityForCount(int count) {
      final ratio = maxCount > 0 ? count / maxCount : 0.0;
      final opacity = 0.25 + (0.5 * ratio);
      return opacity.clamp(0.25, 0.85).toDouble();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
        child: Column(
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
                    Ionicons.calendar_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: spacing / 2),
                Expanded(
                  child: Text(
                    'App Usage Activity (Top ${topEntries.length} days)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 18.0 : 20.0,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing / 2),
            ...topEntries.map((entry) {
              final dateLabel = _formatDate(entry.key);
              final count = entry.value;
              final primary = Theme.of(context).colorScheme.primary;
              final chipColor = primary.withOpacity(opacityForCount(count));

              return Padding(
                padding: EdgeInsets.only(bottom: spacing / 2),
                child: Row(
                  children: [
                    Container(
                      width: isCompact ? 12.0 : 14.0,
                      height: isCompact ? 12.0 : 14.0,
                      decoration: BoxDecoration(
                        color: chipColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: spacing / 2),
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8.0 : 10.0,
                        vertical: isCompact ? 6.0 : 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$count sessions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (sortedEntries.length > topEntries.length)
              Padding(
                padding: EdgeInsets.only(top: spacing / 4),
                child: Text(
                  '+ ${sortedEntries.length - topEntries.length} more active days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(
    BuildContext context,
    CustomerAnalyticsData data,
    bool isCompact,
    double spacing,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
        child: Column(
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
                    Ionicons.bulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: spacing / 2),
                Text(
                  'Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 18.0 : 20.0,
                      ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            // Average Order Value
            _buildInsightCard(
              context,
              'Average Order Value',
              '₹${data.averageOrderValue.toStringAsFixed(2)}',
              Ionicons.trending_up_outline,
              Colors.purple,
              isCompact,
              spacing,
            ),
            SizedBox(height: spacing / 2),
            // Most Purchased Category
            if (data.mostPurchasedCategory != null)
              _buildInsightCard(
                context,
                'Most Purchased Category',
                data.mostPurchasedCategory!,
                Ionicons.grid_outline,
                Colors.orange,
                isCompact,
                spacing,
              ),
            if (data.mostPurchasedCategory != null)
              SizedBox(height: spacing / 2),
            // Last Purchase Date
            if (data.lastOrderDate != null)
              _buildInsightCard(
                context,
                'Last Purchase',
                _formatRelativeTime(data.lastOrderDate!),
                Ionicons.time_outline,
                Colors.blue,
                isCompact,
                spacing,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isCompact,
    double spacing,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isCompact ? 18.0 : 20.0),
          ),
          SizedBox(width: spacing / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                SizedBox(height: spacing / 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

