import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import '../../orders/data/order_model.dart';
import '../application/admin_order_controller.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../../../core/router/router_helpers.dart';
import '../../../core/utils/debouncer.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  final _scrollController = ScrollController();
  bool _isInitialized = false;
  bool _isUpdatingUrl = false;
  bool _isLoadingFromUrl = false;
  String? _entryRoute; // Track the route we came from

  @override
  void initState() {
    super.initState();
    // Pagination listener removed
    // _scrollController.addListener(_onScroll);
  }

  // void _onScroll() {
  //   if (_scrollController.position.pixels >=
  //       _scrollController.position.maxScrollExtent - 200) {
  //     final state = ref.read(adminOrderControllerProvider);
  //     if (state.hasMore && !state.isLoadingMore && !state.loading) {
  //       ref.read(adminOrderControllerProvider.notifier).loadMoreOrders();
  //     }
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer accessing router state until after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_isInitialized) {
        // Capture entry route before any URL updates break the stack
        final state = GoRouterState.of(context);
        final previousRoute = state.uri.queryParameters['previousRoute'];

        if (previousRoute != null && previousRoute.isNotEmpty) {
          // Previous route was passed via query parameter (from bottom nav navigation)
          _entryRoute = previousRoute;
        } else if (context.canPop()) {
          // Try to get previous route from navigation history
          // Since we can't directly access it, we'll use a smart fallback
          _entryRoute = '/admin/dashboard'; // Default assumption
        } else {
          // No navigation stack - likely accessed from bottom nav or direct link
          _entryRoute = null; // Will use dashboard as fallback
        }
        _loadFromUrl();
        _isInitialized = true;
      } else {
        // Check if we need to sync based on URL changes
        // We do this even if updating/loading if it's an explicit refresh request
        final state = GoRouterState.of(context);
        final hasRefresh = state.uri.queryParameters.containsKey('refresh');

        if (hasRefresh || (!_isUpdatingUrl && !_isLoadingFromUrl)) {
          // Listen for URL changes (browser back/forward, deep links, or refresh)
          _syncFromUrl();
        }
      }
    });
  }

  void _loadFromUrl() {
    if (!mounted) return;
    _isLoadingFromUrl = true;

    try {
      final state = GoRouterState.of(context);
      final qp = state.uri.queryParameters;
      final urlQuery = qp['q'] ?? '';
      final urlStatus = OrderStatusExtension.fromUrlValue(qp['status']);
      final urlCustomerId = qp['customerId'];

      // Defer provider modifications to avoid build-time errors
      Future(() async {
        if (!mounted) return;
        final controller = ref.read(adminOrderControllerProvider.notifier);

        // FORCE RESET: Clear all potential filters (Payment Status, Transaction Type, Date Range)
        // that might be stuck from previous sessions. This ensures we start with a clean slate.
        controller.resetFilters();

        // Ensure controller is initialized and data is loaded.
        // We call loadOrders/loadOrdersForCustomer directly instead of refresh()
        // because resetFilters() is a microtask and might not have cleared state.customerId yet,
        // which would cause refresh() to load the WRONG data (previous customer's orders).
        if (urlCustomerId != null && urlCustomerId.isNotEmpty) {
          await controller.loadOrdersForCustomer(urlCustomerId);
        } else {
          await controller.loadOrders();
        }

        if (!mounted) return;

        controller.markOrdersAsRead();

        // Handle search query
        if (urlQuery.isNotEmpty) {
          controller.searchOrders(urlQuery);
          _searchController.text = urlQuery;
        } else {
          _searchController.clear();
        }

        // Handle status filter
        if (urlStatus != null) {
          controller.filterByStatus(urlStatus);
        }

        // Handle customer filter
        if (urlCustomerId != null && urlCustomerId.isNotEmpty) {
          controller.filterByCustomer(urlCustomerId);
        }

        _isLoadingFromUrl = false;
      });
    } catch (e) {
      // Router state not available yet, but we should still reset filters to be safe
      // This prevents stuck filters from previous sessions hiding orders
      Future(() {
        if (!mounted) return;
        final controller = ref.read(adminOrderControllerProvider.notifier);
        controller.resetFilters();
      });
      _isLoadingFromUrl = false;
    }
  }

  void _syncFromUrl() {
    if (!mounted) return;

    try {
      final state = GoRouterState.of(context);
      final qp = state.uri.queryParameters;
      final urlQuery = qp['q'] ?? '';
      final urlStatus = OrderStatusExtension.fromUrlValue(qp['status']);
      final urlCustomerId = qp['customerId'];
      final forceRefresh = qp.containsKey('refresh');

      final controllerState = ref.read(adminOrderControllerProvider);

      // Defer provider modifications to avoid build-time errors
      Future(() async {
        if (!mounted) return;
        final controller = ref.read(adminOrderControllerProvider.notifier);

        // AGGRESSIVE RELOAD FIX:
        // When returning to the main list (no customerId), OR when explicit refresh requested,
        // FORCE a full reset and reload.
        // This handles cases where filters (from AdminCustomerOrdersScreen) get stuck,
        // or where the order list is stale/empty.
        // User requested "Full App Reload" behavior when clicking Orders tab.
        if (urlCustomerId == null || forceRefresh) {
          // 1. Reset all filters (clears customerId, status, etc.)
          controller.resetFilters();

          // 2. Force reload from server to ensure we have ALL orders
          // We intentionally do this even if we think we have data, to satisfy the "Full App Reload" request.
          await controller.loadOrders();

          // 3. Re-apply any URL parameters present (search, status)
          if (urlQuery.isNotEmpty) {
            controller.searchOrders(urlQuery);
            _searchController.text = urlQuery;
          } else {
            _searchController.clear();
          }

          if (urlStatus != null) {
            controller.filterByStatus(urlStatus);
          }
          return;
        }

        if (urlQuery != controllerState.searchQuery) {
          controller.searchOrders(urlQuery);
          _searchController.text = urlQuery;
        }

        // Handle status filter: apply if URL status differs from current state
        // This handles null values correctly - if URL has no status (null) and state has one, it will reset
        if (urlStatus != controllerState.selectedStatus) {
          controller.filterByStatus(urlStatus);
        }

        if (urlCustomerId != controllerState.customerId) {
          controller.filterByCustomer(urlCustomerId);
        }
      });
    } catch (e) {
      // Router state not available yet, ignore
    }
  }

  void _updateUrl({String? query, OrderStatus? status, String? customerId}) {
    if (_isUpdatingUrl || _isLoadingFromUrl) return;
    _isUpdatingUrl = true;

    final currentState = ref.read(adminOrderControllerProvider);
    final currentQuery = query ?? currentState.searchQuery;
    // For status: use provided status if it's different from current state
    // This handles the case where status is explicitly null (for "All" chip)
    final currentStatus =
        (status != currentState.selectedStatus)
            ? status
            : (status ?? currentState.selectedStatus);
    final currentCustomerId = customerId ?? currentState.customerId;

    final url = RouterHelpers.buildAdminOrdersUrl(
      query: currentQuery.isEmpty ? null : currentQuery,
      status: currentStatus?.urlValue,
      customerId: currentCustomerId,
    );

    context.go(url);
    // Reset flag after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isUpdatingUrl = false;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(adminOrderControllerProvider);
    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Manage Orders',
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh_outline),
            onPressed: () {
              // Full refresh: reset filters and reload from server
              final controller = ref.read(
                adminOrderControllerProvider.notifier,
              );
              controller.resetFilters();
              controller.loadOrders();
            },
          ),
        ],
        showBackButton: true,
        onBackPressed: () {
          // Try to pop first
          if (context.canPop()) {
            context.pop();
          } else {
            // Navigation stack broken by _updateUrl() - use entry route or default to dashboard
            context.go(_entryRoute ?? '/admin/dashboard');
          }
        },
        body:
            !orderState.loading && orderState.error != null
                ? _buildErrorState(context, orderState.error!)
                : _buildResponsiveContent(
                  context,
                  orderState,
                  screenSize,
                  foldableBreakpoint,
                ),
      ),
    );
  }

  Widget _buildResponsiveContent(
    BuildContext context,
    AdminOrderState orderState,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);
    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.viewPadding.bottom;

    // Calculate responsive navigation bar height
    final isUltraCompact = width <= 288;
    final isCompact = width <= 400;
    final bottomNavHeight = isUltraCompact ? 56.0 : (isCompact ? 60.0 : 64.0);
    final totalBottomSpacing =
        bottomNavHeight + systemBottomPadding + 40; // 40px buffer

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminOrderControllerProvider.notifier).refresh();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        slivers: [
          // Loading Indicator
          if (orderState.loading)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),

          // Search and Filter Bar
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(spacing),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: const Icon(Ionicons.search_outline),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Ionicons.close_outline),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(
                                        adminOrderControllerProvider.notifier,
                                      )
                                      .searchOrders('');
                                  _searchDebouncer.debounce(() {
                                    if (mounted && !_isLoadingFromUrl) {
                                      _updateUrl(query: '');
                                    }
                                  });
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      ref
                          .read(adminOrderControllerProvider.notifier)
                          .searchOrders(value);
                      _searchDebouncer.debounce(() {
                        if (mounted && !_isLoadingFromUrl) {
                          _updateUrl(query: value);
                        }
                      });
                    },
                  ),
                  SizedBox(height: spacing * 0.75),

                  // Status Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip(context, 'All', null),
                        SizedBox(width: spacing * 0.5),
                        ...OrderStatus.values
                            .where(
                              (s) =>
                                  s != OrderStatus.shipped &&
                                  s != OrderStatus.delivered,
                            )
                            .map((status) {
                              return Padding(
                                padding: EdgeInsets.only(right: spacing * 0.5),
                                child: _buildStatusChip(
                                  context,
                                  status.displayName,
                                  status,
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Orders List or Empty State
          if (orderState.loading && orderState.filteredOrders.isNotEmpty)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),

          if (orderState.loading && orderState.filteredOrders.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (orderState.filteredOrders.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyStateInLayout(context, spacing),
            )
          else ...[
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: spacing),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final order = orderState.filteredOrders[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing * 0.5),
                    child: _buildResponsiveOrderCard(
                      context,
                      order,
                      screenSize,
                      foldableBreakpoint,
                    ),
                  );
                }, childCount: orderState.filteredOrders.length),
              ),
            ),
            if (orderState.hasMore || orderState.isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            // Buffer for bottom navigation
            SliverToBoxAdapter(child: SizedBox(height: totalBottomSpacing)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String label,
    OrderStatus? status,
  ) {
    final orderState = ref.watch(adminOrderControllerProvider);
    final isSelected = orderState.selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // Apply filter first to update state immediately
        ref.read(adminOrderControllerProvider.notifier).filterByStatus(status);
        // Update URL after state update (use post-frame to ensure state is updated)
        if (!_isLoadingFromUrl) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isLoadingFromUrl) {
              _updateUrl(status: status);
            }
          });
        }
      },
      selectedColor:
          status?.color.withOpacity(0.2) ??
          Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: status?.color ?? Theme.of(context).colorScheme.primary,
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
            'Error loading orders',
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
              ref.read(adminOrderControllerProvider.notifier).loadOrders();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateInLayout(BuildContext context, double spacing) {
    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.receipt_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveOrderCard(
    BuildContext context,
    Order order,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isUltraCompact = Responsive.isUltraCompactDevice(width);
    final isFoldable = Responsive.isFoldableMobile(width);

    final padding =
        isUltraCompact
            ? const EdgeInsets.all(12)
            : isFoldable
            ? const EdgeInsets.all(14)
            : const EdgeInsets.all(16);

    final borderRadius = isUltraCompact ? 8.0 : 12.0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap:
            () => context.pushNamed(
              'admin-order-detail',
              pathParameters: {'id': order.id},
            ),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: _buildOrderContent(context, order, isUltraCompact, isFoldable),
        ),
      ),
    );
  }

  Widget _buildOrderContent(
    BuildContext context,
    Order order,
    bool isUltraCompact,
    bool isFoldable,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderTag,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isUltraCompact ? 14 : null,
                    ),
                  ),
                  SizedBox(height: isUltraCompact ? 2 : 4),
                  Text(
                    '${order.deliveryAddress.alias ?? order.deliveryAddress.name} • ${order.deliveryAddress.phone}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: isUltraCompact ? 11 : null,
                    ),
                    maxLines: isUltraCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isUltraCompact ? 2 : 4),
                  Text(
                    'Address: ${order.deliveryAddress.fullAddress}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: isUltraCompact ? 10 : null,
                    ),
                    maxLines: isUltraCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isUltraCompact ? 8 : 12,
                vertical: isUltraCompact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: order.status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isUltraCompact ? 12 : 16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    order.status.icon,
                    size: isUltraCompact ? 12 : 16,
                    color: order.status.color,
                  ),
                  SizedBox(width: isUltraCompact ? 2 : 4),
                  Text(
                    order.status.displayName,
                    style: TextStyle(
                      color: order.status.color,
                      fontSize: isUltraCompact ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isUltraCompact ? 8 : 12),

        // Order Details
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: isUltraCompact ? 10 : null,
                    ),
                  ),
                  SizedBox(height: isUltraCompact ? 2 : 4),
                  Text(
                    'Ordered ${_formatDate(order.orderDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: isUltraCompact ? 9 : null,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Rs ${order.total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: isUltraCompact ? 14 : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /*
  Widget _buildOrderCard(
    BuildContext context,
    Order order,
    ScreenSize screenSize,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.pushNamed('admin-order-detail', pathParameters: {'id': order.id}),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.deliveryAddress.alias ?? order.deliveryAddress.name} • ${order.deliveryAddress.phone}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: order.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          order.status.icon,
                          size: 16,
                          color: order.status.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.status.displayName,
                          style: TextStyle(
                            color: order.status.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Order Items
              ...order.items.take(2).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item.image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              child: const Icon(
                                Ionicons.image_outline,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.size != null || item.color != null)
                              Text(
                                '${item.size ?? ''} ${item.color ?? ''}'.trim(),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'Qty: ${item.quantity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${order.items.length - 2} more items',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Footer
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Date',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (order.trackingNumber != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            order.trackingNumber!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        'Rs ${order.total.toStringAsFixed(2)}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  */
}
