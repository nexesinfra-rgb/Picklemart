import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/order_repository_provider.dart';
import '../../orders/data/order_repository_supabase.dart';
import '../application/admin_order_controller.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';
import 'widgets/admin_auth_guard.dart';
import '../../orders/presentation/widgets/order_location_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'orders_dashboard_screen.dart';
import 'open_orders_screen.dart';
import '../application/admin_dashboard_controller.dart';
import '../application/admin_customer_controller.dart';
import '../../orders/services/order_print_service.dart';
import '../application/admin_auth_controller.dart';
import '../data/payment_receipt_repository.dart';
import 'widgets/product_picker_dialog.dart';
import 'widgets/sale_invoice_dialog.dart';
import '../../catalog/data/product.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  final _trackingController = TextEditingController();
  final _notesController = TextEditingController();
  final _shippingController = TextEditingController();
  final _oldDueController = TextEditingController();
  bool _roundOff = false;
  bool _isConverting = false;
  bool _isFromOpenOrders = false;
  bool _isEditingItems = false;
  List<OrderItem> _editedItems = [];
  bool _isSavingItems = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRouteParams();
      _loadOrder();
    });
  }

  void _checkRouteParams() {
    try {
      final state = GoRouterState.of(context);
      final qp = state.uri.queryParameters;
      _isFromOpenOrders = qp['fromOpenOrders'] == 'true';
    } catch (e) {
      // Router state not available yet, ignore
    }
  }

  Future<void> _loadOrder() async {
    try {
      final orderState = ref.read(adminOrderControllerProvider);
      Order? order;

      // Try to find order in the controller's list first
      try {
        order = orderState.orders.firstWhere((o) => o.id == widget.orderId);
        ref.read(adminOrderControllerProvider.notifier).markOrdersAsRead();
      } catch (e) {
        // Order not in list, fetch directly from repository
        if (kDebugMode) {
          print(
            'Order not found in list, fetching directly from repository...',
          );
        }
        final repository = ref.read(orderRepositoryProvider);
        order = await repository.getOrderById(widget.orderId);

        if (order == null) {
          throw Exception('Order not found');
        }
      }

      ref.read(adminOrderControllerProvider.notifier).selectOrder(order);

      // Initialize shipping and old due with current order values
      _shippingController.text = order.shipping.toStringAsFixed(2);
      _oldDueController.text = _parseOldDueFromNotes(
        order.notes,
      ).toStringAsFixed(2);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading order: $e');
      }
      // Error will be handled by the UI
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _notesController.dispose();
    _shippingController.dispose();
    _oldDueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(adminOrderControllerProvider);
    final order = orderState.selectedOrder;
    final screenSize = Responsive.getScreenSize(context);

    if (order == null) {
      return AdminAuthGuard(
        child: Scaffold(
          appBar: AppBar(title: const Text('Order Details')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${(order.status == OrderStatus.processing) ? 'Order' : 'Sale'} ${order.orderTag}',
          ),
          actions: [
            ResponsiveIconButton(
              icon: const Icon(Ionicons.print_outline),
              onPressed: () => _printOrder(order),
              tooltip: 'Print Order',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenSize == ScreenSize.mobile ? double.infinity : 800,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer/Store Information (Top)
                _buildCustomerCard(context, order),
                const SizedBox(height: 16),

                // Order Items (Products)
                _buildOrderItemsCard(context, order),
                const SizedBox(height: 16),

                // Order Information (Details after products)
                _buildOrderInfoCard(context, order, screenSize),
                const SizedBox(height: 16),

                // Charges Section (Editable Shipping)
                _buildChargesCard(context, order),
                const SizedBox(height: 16),

                // Order Status (Dropdown)
                _buildStatusDropdownCard(context, order),
                const SizedBox(height: 16),

                // Order Actions (Edit/Delete)
                _buildOrderActionsCard(context, order),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomActionBar(context, order, screenSize),
      ),
    );
  }

  Widget _buildChargesCard(BuildContext context, Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Charges',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Delivery Charges
            TextField(
              controller: _shippingController,
              decoration: InputDecoration(
                labelText: 'Delivery Charges',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                enabled:
                    order.status == OrderStatus.processing &&
                    order.shipping <= 0,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                // Update local state if needed, or wait for save
                setState(() {});
              },
            ),
            const SizedBox(height: 16),

            // Old Due (if needed, keeping it as it was in convert logic)
            TextField(
              controller: _oldDueController,
              decoration: InputDecoration(
                labelText: 'Old Due',
                prefixText: 'Rs ',
                border: const OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                enabled:
                    order.status == OrderStatus.processing &&
                    order.shipping <= 0,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),
            // Round Off
            Row(
              children: [
                Checkbox(
                  value: _roundOff,
                  onChanged:
                      order.status == OrderStatus.processing &&
                              order.shipping <= 0
                          ? (value) {
                            setState(() {
                              _roundOff = value ?? false;
                            });
                          }
                          : null,
                ),
                const Text('Round Off'),
              ],
            ),

            const Divider(height: 32),

            // Summary with updated totals
            Builder(
              builder: (context) {
                final shipping =
                    double.tryParse(_shippingController.text) ?? 0.0;
                final oldDue = double.tryParse(_oldDueController.text) ?? 0.0;
                final subtotal = order.subtotal;
                final tax = order.tax;

                // Calculate current order total (excluding old due)
                final currentOrderTotal = subtotal + shipping + tax;
                final totalAmount =
                    _roundOff
                        ? currentOrderTotal.roundToDouble()
                        : currentOrderTotal;

                // Calculate grand total (including old due)
                final totalWithOldDue = currentOrderTotal + oldDue;
                final grandTotal =
                    _roundOff
                        ? totalWithOldDue.roundToDouble()
                        : totalWithOldDue;

                return Column(
                  children: [
                    _buildSummaryRow(
                      context,
                      'Subtotal:',
                      '₹${subtotal.toStringAsFixed(2)}',
                    ),
                    _buildSummaryRow(
                      context,
                      'Delivery Charges:',
                      '₹${shipping.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                oldDue > 0
                                    ? null
                                    : Theme.of(context).colorScheme.primary,
                            fontSize: oldDue > 0 ? 20 : null,
                          ),
                        ),
                      ],
                    ),
                    if (oldDue > 0) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      _buildSummaryRow(
                        context,
                        'Old Due:',
                        '₹${oldDue.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grand Total',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${grandTotal.toStringAsFixed(2)}',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (order.status == OrderStatus.processing &&
                        order.shipping <= 0)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              _isConverting
                                  ? null
                                  : () =>
                                      _convertToSale(order, saveAndNew: false),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child:
                              _isConverting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text('Convert to Sale'),
                        ),
                      ),
                    if (order.status != OrderStatus.cancelled) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            context.pushNamed(
                              'admin-purchase-order-form',
                              queryParameters: {
                                'orderId': order.id,
                                'shipping': order.shipping.toString(),
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Convert to Purchase'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    Order order,
    ScreenSize screenSize,
  ) {
    if (order.status == OrderStatus.processing && order.shipping <= 0) {
      return const SizedBox.shrink();
    }
    final isMobile = screenSize == ScreenSize.mobile;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 0 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmAndDeleteOrder(order),
                icon: const Icon(Ionicons.trash_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade400, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showEditOrderDialog(order),
                icon: const Icon(Ionicons.create_outline),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdownCard(BuildContext context, Order order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineSoft.withOpacity(0.5)),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (order.status == OrderStatus.cancelled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text(
                    'Cancelled',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _updateOrderStatus(OrderStatus.cancelled),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Ionicons.close_circle_outline),
                  label: const Text('Cancel Order'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(
    BuildContext context,
    Order order,
    ScreenSize screenSize,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineSoft.withOpacity(0.5)),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (screenSize == ScreenSize.mobile)
              _buildMobileOrderInfo(context, order)
            else
              _buildDesktopOrderInfo(context, order),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileOrderInfo(BuildContext context, Order order) {
    return Column(
      children: [
        _buildInfoRow(context, 'Order Number', order.orderTag),
        _buildInfoRow(
          context,
          'Order Date',
          '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
        ),
        _buildInfoRow(context, 'Total Items', order.totalItems.toString()),
        _buildInfoRow(
          context,
          'Subtotal',
          '₹${order.subtotal.toStringAsFixed(2)}',
        ),
        _buildInfoRow(
          context,
          'Shipping',
          '₹${order.shipping.toStringAsFixed(2)}',
        ),
        _buildInfoRow(
          context,
          'Total',
          '₹${order.total.toStringAsFixed(2)}',
          isTotal: true,
        ),
        if (order.trackingNumber != null)
          _buildInfoRow(context, 'Tracking', order.trackingNumber!),
        if (order.estimatedDelivery != null)
          _buildInfoRow(
            context,
            'Est. Delivery',
            '${order.estimatedDelivery!.day}/${order.estimatedDelivery!.month}/${order.estimatedDelivery!.year}',
          ),
      ],
    );
  }

  Widget _buildDesktopOrderInfo(BuildContext context, Order order) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildInfoRow(context, 'Order Number', order.orderTag),
              _buildInfoRow(
                context,
                'Order Date',
                '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
              ),
              _buildInfoRow(
                context,
                'Total Items',
                order.totalItems.toString(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildInfoRow(
                context,
                'Subtotal',
                '₹${order.subtotal.toStringAsFixed(2)}',
              ),
              _buildInfoRow(
                context,
                'Shipping',
                '₹${order.shipping.toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              _buildInfoRow(
                context,
                'Total',
                '₹${order.total.toStringAsFixed(2)}',
                isTotal: true,
              ),
              if (order.trackingNumber != null)
                _buildInfoRow(context, 'Tracking', order.trackingNumber!),
              if (order.estimatedDelivery != null)
                _buildInfoRow(
                  context,
                  'Est. Delivery',
                  '${order.estimatedDelivery!.day}/${order.estimatedDelivery!.month}/${order.estimatedDelivery!.year}',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Order order) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineSoft.withOpacity(0.5)),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store/Customer Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Ionicons.person,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (order.deliveryAddress.alias != null &&
                                order.deliveryAddress.alias!.isNotEmpty)
                            ? '${order.deliveryAddress.name} (${order.deliveryAddress.alias})'
                            : order.deliveryAddress.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.deliveryAddress.phone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Dropdown for Address Details
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Address Details',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(top: 8),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Delivery Address',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Ionicons.create_outline,
                                size: 20,
                              ),
                              onPressed: () {
                                _showEditOrderDialog(order);
                              },
                              style: IconButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              tooltip: 'Edit',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.deliveryAddress.fullAddress,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Map Section
                  if (order.deliveryAddress.latitude != null &&
                      order.deliveryAddress.longitude != null) ...[
                    const SizedBox(height: 12),
                    OrderLocationMap(
                      coordinates: LatLng(
                        order.deliveryAddress.latitude!,
                        order.deliveryAddress.longitude!,
                      ),
                      address: order.deliveryAddress.fullAddress,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Open in external map app
                          final lat = order.deliveryAddress.latitude!;
                          final lng = order.deliveryAddress.longitude!;
                          final url = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                          );
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not open map: $e'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Ionicons.map_outline),
                        label: const Text('View on Map'),
                      ),
                    ),
                  ] else if (order.deliveryAddress.fullAddress.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Open address in maps using search
                          final address = Uri.encodeComponent(
                            order.deliveryAddress.fullAddress,
                          );
                          final url = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$address',
                          );
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not open map: $e'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Ionicons.map_outline),
                        label: const Text('View Address on Map'),
                      ),
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

  Widget _buildOrderItemsCard(BuildContext context, Order order) {
    final canEdit =
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.processing;
    final itemsToDisplay = _isEditingItems ? _editedItems : order.items;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.outlineSoft.withOpacity(0.5)),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order Items (${itemsToDisplay.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canEdit && !_isEditingItems)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditingItems = true;
                        _editedItems = List.from(order.items);
                      });
                    },
                    icon: const Icon(Ionicons.create_outline, size: 18),
                    label: const Text('Edit'),
                  ),
                if (_isEditingItems) ...[
                  TextButton(
                    onPressed:
                        _isSavingItems
                            ? null
                            : () {
                              setState(() {
                                _isEditingItems = false;
                                _editedItems = [];
                              });
                            },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        _isSavingItems || _editedItems.isEmpty
                            ? null
                            : () => _saveOrderItems(order),
                    child:
                        _isSavingItems
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Save'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (_isEditingItems && _editedItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Ionicons.cart_outline,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items in order',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...itemsToDisplay.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            item.image.startsWith('http')
                                ? Image.network(
                                  item.image,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      child: const Icon(Ionicons.image_outline),
                                    );
                                  },
                                )
                                : Image.asset(
                                  item.image.startsWith('assets/')
                                      ? item.image
                                      : 'assets/${item.image}',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      child: const Icon(Ionicons.image_outline),
                                    );
                                  },
                                ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (item.size != null || item.color != null) ...[
                              const SizedBox(height: 4),
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
                            const SizedBox(height: 8),
                            if (_isEditingItems)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Ionicons.remove_circle_outline,
                                    ),
                                    iconSize: 20,
                                    onPressed: () {
                                      setState(() {
                                        if (item.quantity > 1) {
                                          final index = _editedItems.indexOf(
                                            item,
                                          );
                                          if (index != -1) {
                                            _editedItems[index] = OrderItem(
                                              id: item.id,
                                              name: item.name,
                                              image: item.image,
                                              price: item.price,
                                              quantity: item.quantity - 1,
                                              size: item.size,
                                              color: item.color,
                                              variantId: item.variantId,
                                            );
                                          }
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Ionicons.add_circle_outline,
                                    ),
                                    iconSize: 20,
                                    onPressed: () {
                                      setState(() {
                                        final index = _editedItems.indexOf(
                                          item,
                                        );
                                        if (index != -1) {
                                          _editedItems[index] = OrderItem(
                                            id: item.id,
                                            name: item.name,
                                            image: item.image,
                                            price: item.price,
                                            quantity: item.quantity + 1,
                                            size: item.size,
                                            color: item.color,
                                            variantId: item.variantId,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ],
                              )
                            else
                              Text(
                                'Quantity: ${item.quantity}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${item.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ₹${item.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_isEditingItems)
                            IconButton(
                              icon: const Icon(Ionicons.trash_outline),
                              color: Colors.red,
                              iconSize: 20,
                              onPressed: () {
                                setState(() {
                                  _editedItems.remove(item);
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            if (_isEditingItems) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addProductToOrder(),
                  icon: const Icon(Ionicons.add),
                  label: const Text('Add Product'),
                ),
              ),
              const SizedBox(height: 16),
              // Show preview of new totals
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Subtotal:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '₹${_editedItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shipping:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '₹${order.shipping.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Total:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${(_editedItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice) + order.shipping + order.tax).toStringAsFixed(2)}',
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActionsCard(BuildContext context, Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 8),

            // Notes
            Text(
              'Order Notes',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Add notes',
                hintText: 'Enter order notes...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Order'),
          content: const Text(
            'Are you sure you want to delete this order? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await ref
        .read(adminOrderControllerProvider.notifier)
        .deleteOrder(order.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTimelineCard(BuildContext context, Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              context,
              'Order Placed',
              order.orderDate,
              Ionicons.receipt_outline,
              Colors.blue,
              true,
            ),
            if (order.status.index >= OrderStatus.confirmed.index)
              _buildTimelineItem(
                context,
                OrderStatus.confirmed.displayName,
                order.orderDate.add(const Duration(minutes: 30)),
                Ionicons.checkmark_circle_outline,
                Colors.green,
                true,
              ),
            if (order.status.index >= OrderStatus.processing.index)
              _buildTimelineItem(
                context,
                OrderStatus.processing.displayName,
                order.orderDate.add(const Duration(hours: 2)),
                Ionicons.construct_outline,
                Colors.orange,
                true,
              ),
            if (order.status == OrderStatus.cancelled)
              _buildTimelineItem(
                context,
                'Cancelled',
                order.orderDate.add(const Duration(hours: 1)),
                Ionicons.close_circle_outline,
                Colors.red,
                true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    DateTime date,
    IconData icon,
    Color color,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? color.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isCompleted ? color : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? null : Colors.grey,
                  ),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    final order = ref.read(adminOrderControllerProvider).selectedOrder;
    if (order == null) return;

    final success = await ref
        .read(adminOrderControllerProvider.notifier)
        .updateOrderStatus(order.id, newStatus);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.displayName}'),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _addTrackingNumber() async {
    if (_trackingController.text.isEmpty) return;

    final order = ref.read(adminOrderControllerProvider).selectedOrder;
    if (order == null) return;

    final success = await ref
        .read(adminOrderControllerProvider.notifier)
        .addTrackingNumber(order.id, _trackingController.text);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tracking number added successfully')),
      );
      _trackingController.clear();
      setState(() {});
    }
  }

  Future<void> _printOrder(Order order) async {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating PDF...'),
                    ],
                  ),
                ),
              ),
            ),
      );
    }

    try {
      await OrderPrintService.printOrder(order, ref);
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bill sent to printer')));
      }
    } catch (e) {
      if (mounted) {
        // Ensure dialog is closed even if there was an error
        try {
          Navigator.of(context).pop(); // Close loading dialog
        } catch (_) {
          // Dialog might already be closed, ignore
        }

        // Show user-friendly error message
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (errorMessage.contains('timed out') ||
            errorMessage.contains('timeout')) {
          errorMessage =
              'Operation timed out. Please check your internet connection and try again.';
        } else if (errorMessage.contains('Failed to generate')) {
          errorMessage = 'Failed to generate PDF. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing bill: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildConvertToSaleCard(BuildContext context, Order order) {
    final shipping = double.tryParse(_shippingController.text) ?? 0.0;
    final oldDue = double.tryParse(_oldDueController.text) ?? 0.0;
    final subtotal = order.subtotal;
    final tax = order.tax;

    // Calculate current order total (excluding old due)
    final currentOrderTotal = subtotal + shipping + tax;
    final totalAmount =
        _roundOff ? currentOrderTotal.roundToDouble() : currentOrderTotal;

    // Calculate grand total (including old due)
    final totalWithOldDue = currentOrderTotal + oldDue;
    final grandTotal =
        _roundOff ? totalWithOldDue.roundToDouble() : totalWithOldDue;

    final roundOffAmount = _roundOff ? grandTotal - totalWithOldDue : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Ionicons.cash_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Convert to Sale',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Order Items Summary
            ...order.items.map((item) {
              final itemSubtotal = item.price * item.quantity;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Item Subtotal',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.quantity} x ₹${item.price.toStringAsFixed(2)} = ₹${itemSubtotal.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Discount (%): 0',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 32),

            // Summary
            _buildSummaryRow(context, 'Total Disc:', '0.0'),
            _buildSummaryRow(
              context,
              'Total Qty:',
              order.items
                  .fold<double>(0.0, (sum, item) => sum + item.quantity)
                  .toStringAsFixed(1),
            ),
            _buildSummaryRow(context, 'Subtotal:', subtotal.toStringAsFixed(2)),
            _buildSummaryRow(context, 'Total Count:', '0'),

            const SizedBox(height: 16),

            // Charges Section
            Text(
              'Charges',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Delivery Charges
            TextField(
              controller: _shippingController,
              decoration: InputDecoration(
                labelText: 'Delivery Charges',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Delivery Charges (read-only)',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              controller: TextEditingController(
                text: shipping.toStringAsFixed(2),
              ),
            ),

            const SizedBox(height: 16),

            // Old Due
            TextField(
              controller: _oldDueController,
              decoration: InputDecoration(
                labelText: 'Old Due',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Old Due (read-only)',
                prefixText: 'Rs ',
                border: const OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              controller: TextEditingController(
                text: oldDue.toStringAsFixed(2),
              ),
            ),

            const SizedBox(height: 16),

            // Round Off
            Row(
              children: [
                Checkbox(
                  value: _roundOff,
                  onChanged: (value) {
                    setState(() {
                      _roundOff = value ?? false;
                    });
                  },
                ),
                const Text('Round Off'),
                const Spacer(),
                Text(
                  _roundOff ? '₹ ${roundOffAmount.toStringAsFixed(2)}' : '₹ -',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            const Divider(height: 32),

            // Total Amount (Current Order)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹ ${totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        oldDue > 0
                            ? null
                            : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (oldDue > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grand Total',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹ ${grandTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isConverting
                            ? null
                            : () => _convertToSale(order, saveAndNew: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save & New'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _isConverting
                            ? null
                            : () => _convertToSale(order, saveAndNew: false),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isConverting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Convert to Sale'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _isConverting
                        ? null
                        : () => _convertToSale(
                          order,
                          saveAndNew: false,
                          withPayment: true,
                        ),
                icon: const Icon(Ionicons.wallet_outline),
                label: const Text('Convert to Payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _convertToSale(
    Order order, {
    required bool saveAndNew,
    bool withPayment = false,
  }) async {
    if (_isConverting) return;

    final shipping = double.tryParse(_shippingController.text) ?? 0.0;
    if (shipping < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipping price cannot be negative'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      final repository = ref.read(orderRepositoryProvider);
      if (repository is OrderRepositorySupabase) {
        final oldDue = double.tryParse(_oldDueController.text) ?? 0.0;

        // Optimistic Update: Update UI immediately before waiting for backend
        final currentSubtotal = order.subtotal;
        final currentTax = order.tax;
        var newTotal = currentSubtotal + shipping + currentTax;
        if (_roundOff) {
          newTotal = newTotal.roundToDouble();
        }

        final currentNotes = order.notes ?? '';
        final updatedNotes =
            oldDue > 0
                ? '$currentNotes\nOld Due: Rs ${oldDue.toStringAsFixed(2)}'
                    .trim()
                : currentNotes;

        final optimisticOrder = Order(
          id: order.id,
          orderTag: order.orderTag,
          orderNumber: order.orderNumber,
          orderDate: order.orderDate,
          status: OrderStatus.confirmed,
          items: order.items,
          deliveryAddress: order.deliveryAddress,
          subtotal: order.subtotal,
          shipping: shipping,
          tax: order.tax,
          total: newTotal,
          trackingNumber: order.trackingNumber,
          estimatedDelivery: order.estimatedDelivery,
          notes: updatedNotes,
          userId: order.userId,
          updatedAt: DateTime.now(),
        );

        // Update the order in the local state immediately
        ref
            .read(adminOrderControllerProvider.notifier)
            .selectOrder(optimisticOrder);

        // Also update the list to reflect sorting changes immediately
        ref
            .read(adminOrderControllerProvider.notifier)
            .updateOrderInList(optimisticOrder);

        // If not saving and navigating away, we want to show the result immediately
        if (!saveAndNew && mounted) {
          setState(() {
            _isConverting = false;
          });
        }

        final updatedOrder = await repository.convertOrderToSale(
          orderId: order.id,
          shippingPrice: shipping,
          oldDue: oldDue,
          roundOff: _roundOff,
        );

        if (updatedOrder != null && mounted) {
          // Refresh orders dashboard metrics
          ref.read(ordersDashboardControllerProvider.notifier).refresh();

          // Refresh open orders if we're coming from there
          ref.read(openOrdersControllerProvider.notifier).refresh();

          // Refresh admin dashboard
          ref.read(adminDashboardControllerProvider.notifier).refresh();

          // Update the order in the local state immediately
          // Use selectOrder to ensure UI updates even if order is not in the list
          ref
              .read(adminOrderControllerProvider.notifier)
              .selectOrder(updatedOrder);
          ref
              .read(adminOrderControllerProvider.notifier)
              .updateOrderInList(updatedOrder);

          // Refresh customer list to reflect new balance/last order info
          ref.read(adminCustomerControllerProvider.notifier).refresh();

          // Show success message with customer name
          final customerName =
              updatedOrder.deliveryAddress.alias ??
              updatedOrder.deliveryAddress.name;

          // Create Payment Receipt if requested
          if (withPayment) {
            try {
              final adminUser = ref.read(adminAuthControllerProvider).adminUser;
              if (adminUser != null) {
                // Create payment receipt linked to the SAME order
                final receiptNumber =
                    'RCPT-${DateTime.now().millisecondsSinceEpoch}';
                await ref
                    .read(paymentReceiptRepositoryProvider)
                    .createPaymentReceipt(
                      orderId: updatedOrder.id,
                      customerId: updatedOrder.userId ?? '',
                      receiptNumber: receiptNumber,
                      paymentDate: DateTime.now(),
                      amount: updatedOrder.total,
                      paymentType: 'cash',
                      createdBy: adminUser.id,
                      description: 'Auto-created from Convert to Payment',
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment Receipt created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint('Error creating payment receipt: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating payment receipt: $e'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }

          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => SaleInvoiceDialog(
                    order: updatedOrder,
                    onConfirm: () {
                      Navigator.of(context).pop();
                      if (mounted) {
                        context.goNamed('admin-dashboard');
                      }
                    },
                  ),
            );
          }

          if (saveAndNew) {
            // Navigate back to open orders to select next order
            if (mounted) context.pop();
          } else {
            // Stay on the individual dashboard (Order Detail Screen)
            // No navigation needed as we want to view the converted sale
          }
        } else {
          throw Exception('Failed to convert order to sale');
        }
      } else {
        throw Exception('Order repository is not OrderRepositorySupabase');
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        ref.read(adminOrderControllerProvider.notifier).selectOrder(order);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error converting to sale: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  double _parseOldDueFromNotes(String? notes) {
    if (notes == null) return 0.0;
    final match = RegExp(r'Old Due: (?:₹|Rs )([\d\.]+)').firstMatch(notes);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _showEditOrderDialog(Order order) async {
    final nameController = TextEditingController(
      text: order.deliveryAddress.name,
    );
    final phoneController = TextEditingController(
      text: order.deliveryAddress.phone,
    );
    final addressController = TextEditingController(
      text: order.deliveryAddress.address,
    );
    final cityController = TextEditingController(
      text: order.deliveryAddress.city,
    );
    final stateController = TextEditingController(
      text: order.deliveryAddress.state,
    );
    final pincodeController = TextEditingController(
      text: order.deliveryAddress.pincode,
    );
    final aliasController = TextEditingController(
      text: order.deliveryAddress.alias ?? '',
    );
    final shippingController = TextEditingController(
      text: order.shipping.toStringAsFixed(2),
    );

    // Parse Old Due from notes
    double oldDue = _parseOldDueFromNotes(order.notes);
    final oldDueController = TextEditingController(
      text: oldDue.toStringAsFixed(2),
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Order Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pincodeController,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: aliasController,
                  decoration: const InputDecoration(
                    labelText: 'Alias (optional)',
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'Order Charges',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: shippingController,
                  decoration: const InputDecoration(
                    labelText: 'Shipping',
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: oldDueController,
                  decoration: const InputDecoration(
                    labelText: 'Old Due',
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final updatedAddress = OrderAddress(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                  city: cityController.text.trim(),
                  state: stateController.text.trim(),
                  pincode: pincodeController.text.trim(),
                  alias:
                      aliasController.text.trim().isEmpty
                          ? null
                          : aliasController.text.trim(),
                  shopPhotoUrl: order.deliveryAddress.shopPhotoUrl,
                );

                final shipping =
                    double.tryParse(shippingController.text) ?? 0.0;
                final oldDue = double.tryParse(oldDueController.text) ?? 0.0;

                final repository = ref.read(orderRepositoryProvider);
                final updatedOrder = await repository.updateOrderDetails(
                  orderId: order.id,
                  deliveryAddress: updatedAddress,
                  shipping: shipping,
                  oldDue: oldDue,
                );

                if (updatedOrder != null && mounted) {
                  ref
                      .read(adminOrderControllerProvider.notifier)
                      .updateOrder(updatedOrder);

                  // Update local controllers
                  _shippingController.text = updatedOrder.shipping
                      .toStringAsFixed(2);
                  _oldDueController.text = oldDue.toStringAsFixed(2);

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order details updated successfully'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update order details'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProductToOrder() async {
    final order = ref.read(adminOrderControllerProvider).selectedOrder;
    if (order == null) return;

    final excludeIds = _editedItems.map((item) => item.id).toList();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ProductPickerDialog(excludeProductIds: excludeIds),
    );

    if (result != null && mounted) {
      final product = result['product'] as Product?;
      final quantity = result['quantity'] as int?;
      final variant = result['variant'] as Variant?;

      if (product == null || quantity == null) {
        return;
      }

      setState(() {
        // Check if product already exists in order
        final existingIndex = _editedItems.indexWhere((item) {
          if (variant != null) {
            return item.id == product.id && item.sku == variant.sku;
          }
          return item.id == product.id && item.variantId == null;
        });
        if (existingIndex != -1) {
          // Update quantity of existing item
          final existingItem = _editedItems[existingIndex];
          _editedItems[existingIndex] = OrderItem(
            id: existingItem.id,
            name: existingItem.name,
            image: existingItem.image,
            price: existingItem.price,
            quantity: existingItem.quantity + quantity,
            size: existingItem.size,
            color: existingItem.color,
            variantId: existingItem.variantId,
            sku: existingItem.sku,
            category: existingItem.category,
          );
        } else {
          // Add new item
          _editedItems.add(
            OrderItem(
              id: product.id,
              name: product.name,
              image: product.imageUrl,
              price: variant?.finalPrice ?? product.finalPrice,
              quantity: quantity,
              size: variant?.attributes['Size'],
              color: variant?.attributes['Color'],
              sku: variant?.sku,
              variantId: variant?.id,
              category:
                  product.categories.isNotEmpty
                      ? product.categories.first
                      : null,
            ),
          );
        }
      });
    }
  }

  Future<void> _saveOrderItems(Order order) async {
    if (_editedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order must have at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSavingItems = true;
    });

    try {
      final success = await ref
          .read(adminOrderControllerProvider.notifier)
          .updateOrderItems(order.id, _editedItems);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order items updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditingItems = false;
          _editedItems = [];
        });
      } else if (mounted) {
        final errorState = ref.read(adminOrderControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorState.error ?? 'Failed to update order items'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingItems = false;
        });
      }
    }
  }
}
