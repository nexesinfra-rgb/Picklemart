import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../data/order_model.dart';
import '../data/orders_infinite_scroll_provider.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../profile/application/profile_controller.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/services/url_launcher_service.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final ordersState = ref.read(ordersInfiniteScrollProvider);

    // Only load more if we're near the end, not already loading, and have more content
    if (position.pixels >= position.maxScrollExtent - 200 &&
        !ordersState.isLoading &&
        ordersState.hasMore) {
      ref.read(ordersInfiniteScrollProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersInfiniteScrollProvider);

    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    // Slightly smaller padding for screen edges so content is closer to borders
    final edgePadding = cardPadding * kScreenEdgePaddingFactor;
    final sectionSpacing = Responsive.getSectionSpacing(width);

    return SafeScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          onPressed:
              () => NavigationHelper.handleBackNavigation(context, ref: ref),
        ),
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh_outline),
            onPressed:
                () => ref.read(ordersInfiniteScrollProvider.notifier).refresh(),
          ),
        ],
      ),
      body:
          ordersState.error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Ionicons.warning_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error loading orders: ${ordersState.error}'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed:
                          () =>
                              ref
                                  .read(ordersInfiniteScrollProvider.notifier)
                                  .refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : ordersState.isLoading && ordersState.orders.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ordersState.orders.isEmpty
              ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: edgePadding,
                    vertical: cardPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Ionicons.receipt_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      Text(
                        'No orders yet',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: cardPadding * 0.5),
                      Text(
                        'Your orders will appear here',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      FilledButton.icon(
                        onPressed: () => context.goNamed('home'),
                        icon: const Icon(Ionicons.home_outline),
                        label: const Text('Start Shopping'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: cardPadding * 1.5,
                            vertical: cardPadding * 0.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(ordersInfiniteScrollProvider.notifier)
                      .refresh();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: edgePadding,
                    vertical: cardPadding * 0.5,
                  ),
                  child: Column(
                    children: [
                    ...ordersState.orders.map((order) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: cardPadding),
                        child: InkWell(
                          onTap:
                              () => context.pushNamed(
                                'order-detail',
                                pathParameters: {'id': order.id},
                              ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Header (ID, Status)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order.orderTag.replaceAll(RegExp(r'[^0-9]'), '')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: order.status.color.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          order.status.icon,
                                          size: 14,
                                          color: order.status.color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          order.status.displayName
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: order.status.color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Date and Price
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy \u2022 hh:mm a',
                                    ).format(order.orderDate),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey.shade500),
                                  ),
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final profile = ref.watch(
                                        currentProfileProvider,
                                      );
                                      if (profile == null ||
                                          !profile.priceVisibilityEnabled) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(
                                        '₹${order.total.toStringAsFixed(2)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          color: const Color(0xFFEAB308),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Items
                              ...order.items.take(2).map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Image
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child:
                                                item.image.startsWith('http')
                                                    ? Image.network(
                                                      item.image,
                                                      fit: BoxFit.cover,
                                                    )
                                                    : Image.asset(
                                                      item.image.startsWith(
                                                            'assets/',
                                                          )
                                                          ? item.image
                                                          : 'assets/${item.image}',
                                                      fit: BoxFit.cover,
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Qty: ${item.quantity}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              // More items
                              if (order.items.length > 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '+ ${order.items.length - 2} more items',
                                    style: TextStyle(
                                      color: const Color(0xFFEAB308),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                              // Separator
                              const SizedBox(height: 8),
                              Divider(color: Colors.grey.shade200),
                            ],
                          ),
                        ),
                      );
                    }),
                    // Loading indicator at the bottom
                    if (ordersState.isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: edgePadding,
                          vertical: cardPadding,
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    // End message
                    if (!ordersState.hasMore && ordersState.orders.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: edgePadding,
                          vertical: cardPadding,
                        ),
                        child: Text(
                          'No more orders',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
