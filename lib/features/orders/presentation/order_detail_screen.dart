import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../data/order_model.dart';
import '../data/order_repository.dart';
import '../data/order_repository_provider.dart';
import '../../cart/application/cart_controller.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../catalog/data/product.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/order_location_map.dart';
import 'package:latlong2/latlong.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  StreamSubscription? _subscription;
  Timer? _refreshTimer;
  Order? _cachedOrder;

  @override
  void initState() {
    super.initState();
    // Schedule initial setup
    Future.microtask(() {
      _subscribeToUpdates();
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    // Auto-refresh every 10 seconds to keep data fresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        // Invalidate provider to trigger a silent refresh
        // The UI will keep showing old data while loading new data
        ref.invalidate(orderByIdProvider(widget.orderId));
      }
    });
  }

  void _subscribeToUpdates() {
    try {
      final repository = ref.read(orderRepositoryProvider);
      // Listen to real-time updates for user orders
      _subscription = repository.subscribeToUserOrders().listen((_) {
        if (mounted) {
          ref.invalidate(orderByIdProvider(widget.orderId));
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to order updates: $e');
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleReorder(Order order) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Adding items to cart...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Get all products from shared provider
      final products = ref.read(allProductsProvider);

      int addedCount = 0;
      int notFoundCount = 0;
      final errors = <String>[];

      for (final orderItem in order.items) {
        try {
          // Find product by ID
          final product = products.firstWhere((p) => p.id == orderItem.id);

          // Find matching variant if size/color exists
          Variant? variant;
          if ((orderItem.size != null || orderItem.color != null) &&
              product.variants.isNotEmpty) {
            try {
              variant = product.variants.firstWhere((v) {
                final sizeMatch =
                    orderItem.size == null ||
                    v.attributes['Size'] == orderItem.size;
                final colorMatch =
                    orderItem.color == null ||
                    v.attributes['Color'] == orderItem.color;
                return sizeMatch && colorMatch;
              });
            } catch (_) {
              // Variant not found, continue without variant
              variant = null;
            }
          }

          // Add to cart
          await ref
              .read(cartProvider.notifier)
              .add(product, variant: variant, qty: orderItem.quantity);

          addedCount++;
        } catch (e) {
          notFoundCount++;
          errors.add('${orderItem.name}: ${e.toString()}');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                notFoundCount > 0
                    ? '$addedCount item${addedCount > 1 ? 's' : ''} added. $notFoundCount item${notFoundCount > 1 ? 's' : ''} not available.'
                    : '$addedCount item${addedCount > 1 ? 's' : ''} added to cart',
              ),
              backgroundColor: notFoundCount > 0 ? Colors.orange : Colors.green,
              action:
                  addedCount > 0
                      ? SnackBarAction(
                        label: 'View Cart',
                        textColor: Colors.white,
                        onPressed: () => context.pushNamed('cart'),
                      )
                      : null,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No items could be added to cart. ${errors.isNotEmpty ? errors.first : 'Products may no longer be available.'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCancelOrder(Order order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: Text(
              'Are you sure you want to cancel order #${order.orderNumber}? '
              'This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Yes, Cancel Order'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Cancelling order...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Update order status to cancelled
      final repository = ref.read(orderRepositoryProvider);
      await repository.updateOrderStatus(order.id, OrderStatus.cancelled);

      // Refresh order data
      ref.invalidate(orderByIdProvider(widget.orderId));

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));

    // Cache the order data to prevent flickering during silent refreshes
    if (orderAsync.hasValue) {
      _cachedOrder = orderAsync.value;
    }

    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    final sectionSpacing = Responsive.getSectionSpacing(width);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh_outline),
            onPressed: () => ref.refresh(orderByIdProvider(widget.orderId)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          return await ref.refresh(orderByIdProvider(widget.orderId).future);
        },
        child: Builder(
          builder: (context) {
            // Use cached order if available to prevent loading flicker
            final order = _cachedOrder ?? orderAsync.valueOrNull;

            // Show loading only if we have no data at all
            if (orderAsync.isLoading && order == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (orderAsync.hasError && order == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Ionicons.warning_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error loading order: ${orderAsync.error}'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed:
                          () => ref.refresh(orderByIdProvider(widget.orderId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (order == null) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Ionicons.warning_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: sectionSpacing),
                      Text(
                        'Order not found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed:
                            () =>
                                ref.refresh(orderByIdProvider(widget.orderId)),
                        icon: const Icon(Ionicons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                order.status.icon,
                                color: order.status.color,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.status.displayName,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        color: order.status.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      order.orderTag,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Items',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          item.image.startsWith('http')
                                              ? Image.network(
                                                item.image,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: Icon(
                                                        Ionicons.image_outline,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade400,
                                                      ),
                                                    ),
                                              )
                                              : Image.asset(
                                                item.image.startsWith('assets/')
                                                    ? item.image
                                                    : 'assets/${item.image}',
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: Icon(
                                                        Ionicons.image_outline,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade400,
                                                      ),
                                                    ),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.size != null ||
                                            item.color != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              if (item.size != null)
                                                'Size: ${item.size}',
                                              if (item.color != null)
                                                'Color: ${item.color}',
                                            ].join(' • '),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Qty: ${item.quantity}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            Text(
                                              '₹${item.price.toStringAsFixed(2)}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery Address
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Address',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            order.deliveryAddress.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              order.deliveryAddress.address,
                              '${order.deliveryAddress.city}, ${order.deliveryAddress.state} ${order.deliveryAddress.pincode}',
                            ].where((e) => e.isNotEmpty).join('\n'),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Ionicons.call_outline,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order.deliveryAddress.phone,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Location Map
                  if (order.deliveryAddress.latitude != null &&
                      order.deliveryAddress.longitude != null) ...[
                    OrderLocationMap(
                      coordinates: LatLng(
                        order.deliveryAddress.latitude!,
                        order.deliveryAddress.longitude!,
                      ),
                      address: order.deliveryAddress.fullAddress,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Payment Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '₹${order.subtotal.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shipping',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '₹${order.shipping.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tax',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '₹${order.tax.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '₹${order.total.toStringAsFixed(2)}',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  if (order.status == OrderStatus.delivered ||
                      order.status == OrderStatus.cancelled)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _handleReorder(order),
                        icon: const Icon(Ionicons.refresh_circle_outline),
                        label: const Text('Reorder Items'),
                      ),
                    ),

                  if (order.status == OrderStatus.processing ||
                      order.status == OrderStatus.confirmed)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleCancelOrder(order),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          icon: const Icon(Ionicons.close_circle_outline),
                          label: const Text('Cancel Order'),
                        ),
                      ),
                    ),
                  SizedBox(height: sectionSpacing),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
