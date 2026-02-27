import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../application/admin_order_controller.dart';
import '../../orders/data/order_repository_supabase.dart';
import '../../orders/data/order_repository_provider.dart';
import '../../admin/data/product_repository_supabase.dart';
import '../../catalog/data/product_repository.dart';

class OrdersDashboardState {
  final int totalOrders;
  final int openOrders;
  final double orderValueReceived;
  final int outOfStockItemsCount;
  final bool loading;
  final String? error;

  const OrdersDashboardState({
    this.totalOrders = 0,
    this.openOrders = 0,
    this.orderValueReceived = 0.0,
    this.outOfStockItemsCount = 0,
    this.loading = false,
    this.error,
  });

  OrdersDashboardState copyWith({
    int? totalOrders,
    int? openOrders,
    double? orderValueReceived,
    int? outOfStockItemsCount,
    bool? loading,
    String? error,
  }) => OrdersDashboardState(
    totalOrders: totalOrders ?? this.totalOrders,
    openOrders: openOrders ?? this.openOrders,
    orderValueReceived: orderValueReceived ?? this.orderValueReceived,
    outOfStockItemsCount: outOfStockItemsCount ?? this.outOfStockItemsCount,
    loading: loading ?? this.loading,
    error: error,
  );
}

class OrdersDashboardController extends StateNotifier<OrdersDashboardState> {
  OrdersDashboardController(this._ref) : super(const OrdersDashboardState());

  final Ref _ref;

  Future<void> loadMetrics() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final orderRepository = _ref.read(orderRepositoryProvider);
      final productRepository = _ref.read(productRepositoryProvider);

      if (orderRepository is OrderRepositorySupabase) {
        // Run all queries in parallel for better performance
        final results = await Future.wait([
          orderRepository.getOrdersDashboardMetrics(),
          productRepository is ProductRepositorySupabase
              ? productRepository.getOutOfStockItemsCount()
              : Future.value(0),
        ]);

        final metrics = results[0] as Map<String, dynamic>;
        final outOfStockItemsCount = results[1] as int;

        state = state.copyWith(
          totalOrders: metrics['totalOrders'] as int,
          openOrders: metrics['openOrders'] as int,
          orderValueReceived: metrics['orderValueReceived'] as double,
          outOfStockItemsCount: outOfStockItemsCount,
          loading: false,
        );
      } else {
        state = state.copyWith(
          loading: false,
          error: 'Order repository is not OrderRepositorySupabase',
        );
      }
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to load metrics: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    await loadMetrics();
  }
}

final ordersDashboardControllerProvider =
    StateNotifierProvider<OrdersDashboardController, OrdersDashboardState>(
      (ref) => OrdersDashboardController(ref),
    );

class OrdersDashboardScreen extends ConsumerStatefulWidget {
  const OrdersDashboardScreen({super.key});

  @override
  ConsumerState<OrdersDashboardScreen> createState() =>
      _OrdersDashboardScreenState();
}

class _OrdersDashboardScreenState extends ConsumerState<OrdersDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersDashboardControllerProvider.notifier).loadMetrics();
      // Mark orders as read when entering the dashboard
      ref.read(adminOrderControllerProvider.notifier).markOrdersAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(ordersDashboardControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);
    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.viewPadding.bottom;

    final isUltraCompact = width <= 288;
    final isCompact = width <= 400;
    final bottomNavHeight = isUltraCompact ? 56.0 : (isCompact ? 60.0 : 64.0);
    final totalBottomSpacing = bottomNavHeight + systemBottomPadding + 40;

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Online Store',
        showBackButton: true,
        body: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(ordersDashboardControllerProvider.notifier)
                .refresh();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: totalBottomSpacing),
            child: Padding(
              padding: EdgeInsets.all(spacing),
              child:
                  dashboardState.loading
                      ? const Center(child: CircularProgressIndicator())
                      : dashboardState.error != null
                      ? _buildErrorState(context, dashboardState.error!)
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetricsGrid(context, dashboardState, spacing),
                          SizedBox(height: spacing),
                          _buildQuickActions(context, dashboardState, spacing),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
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
            'Error loading dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref
                  .read(ordersDashboardControllerProvider.notifier)
                  .loadMetrics();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    OrdersDashboardState state,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(
              context,
              'Total Orders',
              state.totalOrders.toString(),
              Ionicons.receipt_outline,
              Colors.blue,
              onTap: () {
                context.pushNamed('admin-orders');
              },
            ),
            _buildMetricCard(
              context,
              'Open Orders',
              state.openOrders.toString(),
              Ionicons.time_outline,
              Colors.red,
              badge: 'NEW',
              onTap: () {
                context.pushNamed('admin-open-orders');
              },
            ),
            _buildMetricCard(
              context,
              'Store Views',
              '26,133', // TODO: Get from analytics
              Ionicons.eye_outline,
              Colors.purple,
            ),
            _buildMetricCard(
              context,
              'Order Value Received',
              '₹ ${_formatCurrency(state.orderValueReceived)}',
              Ionicons.cash_outline,
              Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? badge,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    OrdersDashboardState dashboardState,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildQuickActionItem(
          context,
          'Manage Items',
          'Out of Stock - ${dashboardState.outOfStockItemsCount} Items',
          Ionicons.cube_outline,
          Colors.orange,
          onTap: () {
            context.pushNamed(
              'admin-products',
              queryParameters: {'outOfStock': 'true'},
            );
          },
        ),
        const SizedBox(height: 8),
        _buildQuickActionItem(
          context,
          'Manage Orders',
          'View and process all orders',
          Ionicons.cart_outline,
          Colors.red,
          onTap: () {
            context.pushNamed('admin-orders');
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Ionicons.chevron_forward_outline),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      // Crores
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      // Lakhs
      return '${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}
