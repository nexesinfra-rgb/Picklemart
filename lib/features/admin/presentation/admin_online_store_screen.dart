import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../application/admin_dashboard_controller.dart';
import 'widgets/admin_scaffold.dart';
import '../../../core/layout/responsive.dart';

class AdminOnlineStoreScreen extends ConsumerStatefulWidget {
  const AdminOnlineStoreScreen({super.key});

  @override
  ConsumerState<AdminOnlineStoreScreen> createState() =>
      _AdminOnlineStoreScreenState();
}

class _AdminOnlineStoreScreenState
    extends ConsumerState<AdminOnlineStoreScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize dashboard controller if needed
    Future.microtask(() {
      ref.read(adminDashboardControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(width);

    return AdminScaffold(
      title: 'Online Store',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Grid
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isMobile ? 1.5 : 2.0,
              children: [
                _buildMetricCard(
                  context,
                  'Total Orders',
                  dashboardState.totalOrders.toString(),
                  Ionicons.receipt_outline,
                  Colors.blue,
                ),
                _buildMetricCard(
                  context,
                  'Open Orders',
                  dashboardState.pendingOrders.toString(),
                  Ionicons.time_outline,
                  Colors.orange,
                ),
                _buildMetricCard(
                  context,
                  'Store Views',
                  '26,133', // Placeholder as per design request, since we don't have this metric yet
                  Ionicons.eye_outline,
                  Colors.purple,
                ),
                _buildMetricCard(
                  context,
                  'Order Value Received',
                  '₹${dashboardState.totalRevenue.toStringAsFixed(2)}',
                  Ionicons.cash_outline,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Quick Actions List
            _buildActionItem(
              context,
              'Manage Items',
              'Out of Stock - ${dashboardState.lowStockProducts} Items',
              Ionicons.cube_outline,
              Colors.blue,
              () => context.goNamed('admin-products'),
            ),
            const SizedBox(height: 12),
            _buildActionItem(
              context,
              'Manage Orders',
              'Total Orders - ${dashboardState.totalOrders}',
              Ionicons.cart_outline,
              Colors.green,
              () => context.goNamed(
                'admin-orders',
              ), // Assuming this route exists, or admin-orders-dashboard
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Ionicons.chevron_forward_outline,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
