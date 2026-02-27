import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/order_repository_provider.dart';
import '../../orders/data/order_repository_supabase.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../application/admin_order_controller.dart';
import '../../../core/utils/order_utils.dart';

class OpenOrdersState {
  final List<Order> orders;
  final bool loading;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchQuery;

  const OpenOrdersState({
    this.orders = const [],
    this.loading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.searchQuery = '',
  });

  OpenOrdersState copyWith({
    List<Order>? orders,
    bool? loading,
    String? error,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
  }) => OpenOrdersState(
    orders: orders ?? this.orders,
    loading: loading ?? this.loading,
    error: error,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

class OpenOrdersController extends StateNotifier<OpenOrdersState> {
  OpenOrdersController(this._ref) : super(const OpenOrdersState());

  final Ref _ref;

  Future<void> loadOrders({String? query}) async {
    final searchQuery = query ?? state.searchQuery;
    state = state.copyWith(
      loading: true,
      error: null,
      currentPage: 1,
      searchQuery: searchQuery,
    );

    try {
      final repository = _ref.read(orderRepositoryProvider);
      if (repository is OrderRepositorySupabase) {
        final orders = await repository.getOpenOrders(
          page: 1,
          limit: 50,
          searchQuery: searchQuery,
        );
        // Sort by order number descending (higher numbers first)
        orders.sort((a, b) {
          final numA = _extractNumericPortionFromOrder(a) ?? 0;
          final numB = _extractNumericPortionFromOrder(b) ?? 0;
          return numB.compareTo(numA);
        });
        state = state.copyWith(
          orders: orders,
          loading: false,
          currentPage: 1,
          hasMore: orders.length == 50,
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
        error: 'Failed to load orders: ${e.toString()}',
      );
    }
  }

  Future<void> search(String query) async {
    if (query == state.searchQuery) return;
    await loadOrders(query: query);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = _ref.read(orderRepositoryProvider);
      if (repository is OrderRepositorySupabase) {
        final nextPage = state.currentPage + 1;
        final newOrders = await repository.getOpenOrders(
          page: nextPage,
          limit: 50,
          searchQuery: state.searchQuery,
        );
        final hasMore = newOrders.length == 50;
        final allOrders = [...state.orders, ...newOrders];
        // Sort by order number descending
        allOrders.sort((a, b) {
          final numA = _extractNumericPortionFromOrder(a) ?? 0;
          final numB = _extractNumericPortionFromOrder(b) ?? 0;
          return numB.compareTo(numA);
        });

        state = state.copyWith(
          orders: allOrders,
          currentPage: nextPage,
          hasMore: hasMore,
          isLoadingMore: false,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more orders: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    await loadOrders();
  }

  /// Extract numeric portion from order numbers for proper numeric sorting
  int _extractNumericPortionFromOrder(Order order) {
    final numericPart = order.orderNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return numericPart.isNotEmpty ? int.tryParse(numericPart) ?? 0 : 0;
  }
}

final openOrdersControllerProvider =
    StateNotifierProvider<OpenOrdersController, OpenOrdersState>(
      (ref) => OpenOrdersController(ref),
    );

class OpenOrdersScreen extends ConsumerStatefulWidget {
  const OpenOrdersScreen({super.key});

  @override
  ConsumerState<OpenOrdersScreen> createState() => _OpenOrdersScreenState();
}

class _OpenOrdersScreenState extends ConsumerState<OpenOrdersScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(openOrdersControllerProvider.notifier).loadOrders();
      // Mark orders as read when entering the open orders screen
      ref.read(adminOrderControllerProvider.notifier).markOrdersAsRead();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(openOrdersControllerProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(openOrdersControllerProvider);
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
        title: 'Open Orders',
        showBackButton: true,
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(openOrdersControllerProvider.notifier).refresh();
          },
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(spacing),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by store/customer name or order #',
                    prefixIcon: const Icon(Ionicons.search_outline),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Ionicons.close_circle_outline),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              Expanded(
                child:
                    ordersState.loading
                        ? const Center(child: CircularProgressIndicator())
                        : ordersState.error != null
                        ? _buildErrorState(context, ordersState.error!)
                        : ordersState.orders.isEmpty
                        ? _buildEmptyState(context, spacing)
                        : SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: totalBottomSpacing),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: spacing),
                            child: Column(
                              children: [
                                ...ordersState.orders.map((order) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: spacing * 0.75,
                                    ),
                                    child: _buildOrderCard(
                                      context,
                                      order,
                                      spacing,
                                      isUltraCompact,
                                    ),
                                  );
                                }),
                                if (ordersState.hasMore)
                                  Padding(
                                    padding: EdgeInsets.only(top: spacing),
                                    child:
                                        ordersState.isLoadingMore
                                            ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                            : OutlinedButton.icon(
                                              onPressed: () {
                                                ref
                                                    .read(
                                                      openOrdersControllerProvider
                                                          .notifier,
                                                    )
                                                    .loadMore();
                                              },
                                              icon: const Icon(
                                                Ionicons.refresh_outline,
                                              ),
                                              label: const Text('Load More'),
                                            ),
                                  ),
                              ],
                            ),
                          ),
                        ),
              ),
            ],
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
              ref.read(openOrdersControllerProvider.notifier).loadOrders();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double spacing) {
    return Center(
      child: Padding(
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
              'No open orders',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'All orders have been processed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Order order,
    double spacing,
    bool isUltraCompact,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isUltraCompact ? 12 : 16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            'admin-order-detail',
            pathParameters: {'id': order.id},
            queryParameters: {'fromOpenOrders': 'true'},
          );
        },
        borderRadius: BorderRadius.circular(isUltraCompact ? 12 : 16),
        child: Padding(
          padding: EdgeInsets.all(isUltraCompact ? 12 : 16),
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
                          order.orderTag,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isUltraCompact ? 14 : null,
                          ),
                        ),
                        SizedBox(height: isUltraCompact ? 2 : 4),
                        Text(
                          '${order.deliveryAddress.alias ?? order.deliveryAddress.name} • ${order.deliveryAddress.phone}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: isUltraCompact ? 11 : null,
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
                      borderRadius: BorderRadius.circular(
                        isUltraCompact ? 12 : 16,
                      ),
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
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: isUltraCompact ? 10 : null,
                          ),
                        ),
                        SizedBox(height: isUltraCompact ? 2 : 4),
                        Text(
                          DateFormat('dd MMM, yy').format(order.orderDate),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
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
                    '₹${order.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: isUltraCompact ? 14 : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
