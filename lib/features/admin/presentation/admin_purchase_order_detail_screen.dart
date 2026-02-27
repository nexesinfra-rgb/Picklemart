import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../domain/purchase_order.dart';
import '../application/purchase_order_controller.dart';
import '../application/manufacturer_controller.dart';
import '../services/purchase_order_pdf_service.dart';

class AdminPurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final String purchaseOrderId;

  const AdminPurchaseOrderDetailScreen({
    super.key,
    required this.purchaseOrderId,
  });

  @override
  ConsumerState<AdminPurchaseOrderDetailScreen> createState() =>
      _AdminPurchaseOrderDetailScreenState();
}

class _AdminPurchaseOrderDetailScreenState
    extends ConsumerState<AdminPurchaseOrderDetailScreen> {
  PurchaseOrder? _purchaseOrder;
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isSharing = false;
  bool _wasUpdated = false;

  @override
  void initState() {
    super.initState();
    _loadPurchaseOrder();
  }

  Future<void> _loadPurchaseOrder() async {
    setState(() => _isLoading = true);
    try {
      final purchaseOrder = await ref
          .read(purchaseOrderControllerProvider.notifier)
          .getPurchaseOrderById(widget.purchaseOrderId);

      if (mounted) {
        setState(() {
          _purchaseOrder = purchaseOrder;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading purchase order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_purchaseOrder == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
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

    try {
      final manufacturerState = ref.read(manufacturerControllerProvider);
      var manufacturer =
          manufacturerState.manufacturers
              .where((m) => m.id == _purchaseOrder!.manufacturerId)
              .firstOrNull;

      await PurchaseOrderPdfService.printPurchaseOrder(
        _purchaseOrder!,
        manufacturer,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePurchaseOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Purchase Order'),
            content: const Text(
              'Are you sure you want to delete this purchase order? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final success = await ref
            .read(purchaseOrderControllerProvider.notifier)
            .deletePurchaseOrder(widget.purchaseOrderId);

        if (mounted) {
          setState(() => _isDeleting = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Purchase order deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete purchase order'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Purchase Order Details',
        showBackButton: true,
        onBackPressed: () => context.pop(_wasUpdated),
        actions: [
          if (_purchaseOrder != null) ...[
            ResponsiveIconButton(
              icon:
                  _isSharing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Ionicons.share_social_outline),
              onPressed:
                  _isSharing
                      ? null
                      : () async {
                        setState(() => _isSharing = true);
                        try {
                          final manufacturerState = ref.read(
                            manufacturerControllerProvider,
                          );
                          var manufacturer =
                              manufacturerState.manufacturers
                                  .where(
                                    (m) =>
                                        m.id == _purchaseOrder!.manufacturerId,
                                  )
                                  .firstOrNull;

                          await PurchaseOrderPdfService.sharePurchaseOrder(
                            _purchaseOrder!,
                            manufacturer,
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error sharing: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isSharing = false);
                          }
                        }
                      },
              tooltip: 'Share PO',
            ),
            ResponsiveIconButton(
              icon: const Icon(Ionicons.print_outline),
              onPressed: _generatePdf,
              tooltip: 'Print PO',
            ),
          ],
        ],
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _purchaseOrder == null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.alert_circle_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Purchase order not found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _loadPurchaseOrder,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(spacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        _buildHeaderCard(context, _purchaseOrder!, spacing),
                        SizedBox(height: spacing),

                        // Manufacturer Card
                        _buildManufacturerCard(
                          context,
                          _purchaseOrder!,
                          spacing,
                        ),
                        SizedBox(height: spacing),

                        // Items Card
                        _buildItemsCard(context, _purchaseOrder!, spacing),
                        SizedBox(height: spacing),

                        // Totals Card
                        _buildTotalsCard(context, _purchaseOrder!, spacing),
                        SizedBox(height: spacing),

                        // Notes Card
                        if (_purchaseOrder!.notes != null &&
                            _purchaseOrder!.notes!.isNotEmpty)
                          _buildNotesCard(context, _purchaseOrder!, spacing),
                      ],
                    ),
                  ),
                ),
        bottomNavigationBar:
            _purchaseOrder != null
                ? Container(
                  padding: EdgeInsets.all(spacing),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isDeleting ? null : _deletePurchaseOrder,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isDeleting
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context
                                  .pushNamed(
                                    'admin-purchase-order-form',
                                    queryParameters: {'id': _purchaseOrder!.id},
                                  )
                                  .then((updated) {
                                    if (updated == true) {
                                      _loadPurchaseOrder();
                                      // Signal parent to refresh as well
                                      if (mounted) {
                                        // We don't pop here, but we set a flag or just ensure
                                        // that when we DO pop later, we return true.
                                        _wasUpdated = true;
                                      }
                                    }
                                  });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    PurchaseOrder purchaseOrder,
    double spacing,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing),
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
                        purchaseOrder.purchaseNumber,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${DateFormat('dd MMM, yyyy HH:mm').format(purchaseOrder.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: purchaseOrder.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        purchaseOrder.status.icon,
                        size: 20,
                        color: purchaseOrder.status.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        purchaseOrder.status.displayName,
                        style: TextStyle(
                          color: purchaseOrder.status.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          DateTime displayDate = purchaseOrder.purchaseDate;
                          if (displayDate.hour == 0 &&
                              displayDate.minute == 0 &&
                              displayDate.second == 0) {
                            final createdAtLocal =
                                purchaseOrder.createdAt.toLocal();
                            // Combine purchaseDate date with createdAt time to show meaningful time
                            displayDate = DateTime(
                              displayDate.year,
                              displayDate.month,
                              displayDate.day,
                              createdAtLocal.hour,
                              createdAtLocal.minute,
                              createdAtLocal.second,
                            );
                          }
                          return Text(
                            DateFormat(
                              'dd MMM, yyyy • hh:mm a',
                            ).format(displayDate),
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (purchaseOrder.expectedDeliveryDate != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expected Delivery',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd MMM, yyyy',
                          ).format(purchaseOrder.expectedDeliveryDate!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManufacturerCard(
    BuildContext context,
    PurchaseOrder purchaseOrder,
    double spacing,
  ) {
    final manufacturerState = ref.watch(manufacturerControllerProvider);
    final manufacturer =
        manufacturerState.manufacturers
            .where((m) => m.id == purchaseOrder.manufacturerId)
            .firstOrNull;

    if (manufacturer == null) {
      return const SizedBox.shrink();
    }

    final manufacturerName =
        purchaseOrder.transportationName ?? manufacturer.businessName;
    final manufacturerAddress =
        purchaseOrder.deliveryLocation ?? manufacturer.fullAddress;
    final manufacturerPhone =
        purchaseOrder.transportationPhone ?? manufacturer.phone;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Ionicons.business_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Manufacturer Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              manufacturerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('GST: ${manufacturer.formattedGstNumber}'),
            const SizedBox(height: 4),
            Text(manufacturerAddress),
            if (manufacturer.email != null) ...[
              const SizedBox(height: 4),
              Text('Email: ${manufacturer.email}'),
            ],
            if (manufacturerPhone != null) ...[
              const SizedBox(height: 4),
              Text('Phone: $manufacturerPhone'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(
    BuildContext context,
    PurchaseOrder purchaseOrder,
    double spacing,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Ionicons.cube_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Items (${purchaseOrder.items.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...purchaseOrder.items.map((item) {
              return Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.image.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Ionicons.image_outline),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity : ${item.quantity}${item.measurementUnit != null && item.measurementUnit!.isNotEmpty ? 'X${item.measurementUnit}' : ''}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Qty: ${item.quantity} × Rs ${item.unitPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs ${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsCard(
    BuildContext context,
    PurchaseOrder purchaseOrder,
    double spacing,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Totals',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(
                  'Rs ${purchaseOrder.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax:'),
                Text(
                  'Rs ${purchaseOrder.tax.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping:'),
                Text(
                  'Rs ${purchaseOrder.shipping.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs ${purchaseOrder.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(
    BuildContext context,
    PurchaseOrder purchaseOrder,
    double spacing,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Ionicons.document_text_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              purchaseOrder.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
