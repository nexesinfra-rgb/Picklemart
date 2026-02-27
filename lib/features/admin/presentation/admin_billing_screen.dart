import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../data/bill_model.dart';
import '../application/bill_controller.dart';
import '../application/manufacturer_controller.dart';
import '../domain/manufacturer.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/order_repository_provider.dart';
import '../../orders/data/order_repository_supabase.dart';
import 'widgets/bill_template_upload_widget.dart';
import 'widgets/bill_edit_dialog.dart';
import 'bill_detail_screen.dart';

class AdminBillingScreen extends ConsumerStatefulWidget {
  const AdminBillingScreen({super.key});

  @override
  ConsumerState<AdminBillingScreen> createState() => _AdminBillingScreenState();
}

class _AdminBillingScreenState extends ConsumerState<AdminBillingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Preload manufacturers in background for instant dialog display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final manufacturerState = ref.read(manufacturerControllerProvider);
        // Only load if not already loaded and not currently loading
        if (manufacturerState.manufacturers.isEmpty &&
            !manufacturerState.loading) {
          ref.read(manufacturerControllerProvider.notifier).loadManufacturers();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(billControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Billing',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Ionicons.share_outline),
            onPressed: () => _exportBills(billState),
            tooltip: 'Export Bills',
          ),
        ],
        body: Column(
          children: [
            // Tabs
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                unselectedLabelStyle: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(
                    text: 'Bills',
                    icon: Icon(Ionicons.receipt_outline, size: 20),
                  ),
                  Tab(
                    text: 'Generate',
                    icon: Icon(Ionicons.add_circle_outline, size: 20),
                  ),
                  Tab(
                    text: 'Templates',
                    icon: Icon(Ionicons.image_outline, size: 20),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBillsList(billState, spacing),
                  _buildGenerateBill(spacing),
                  _buildTemplatesTab(billState, spacing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsList(BillState state, double spacing) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading bills...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Ionicons.alert_circle_outline,
                  size: 48,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading Bills',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed:
                    () => ref.read(billControllerProvider.notifier).loadBills(),
                icon: const Icon(Ionicons.refresh_outline),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.bills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Ionicons.receipt_outline,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No bills found',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate bills from orders or create standalone bills',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Filter buttons
        Container(
          padding: EdgeInsets.all(spacing),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: 'All',
                  icon: Ionicons.list_outline,
                  isSelected: state.selectedBillType == null,
                  onTap:
                      () => ref
                          .read(billControllerProvider.notifier)
                          .filterBillsByType(null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  label: 'Store Bills',
                  icon: Ionicons.person_outline,
                  isSelected: state.selectedBillType == BillType.user,
                  onTap:
                      () => ref
                          .read(billControllerProvider.notifier)
                          .filterBillsByType(BillType.user),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterChip(
                  label: 'Manufacturer',
                  icon: Ionicons.business_outline,
                  isSelected: state.selectedBillType == BillType.manufacturer,
                  onTap:
                      () => ref
                          .read(billControllerProvider.notifier)
                          .filterBillsByType(BillType.manufacturer),
                ),
              ),
            ],
          ),
        ),

        // Bills list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(spacing),
            itemCount: state.bills.length,
            itemBuilder: (context, index) {
              final bill = state.bills[index];
              final isStoreBill = bill.billType == BillType.user;
              final iconColor = isStoreBill ? Colors.blue : Colors.orange;
              final iconBgColor =
                  isStoreBill
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BillDetailScreen(bill: bill),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icon container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isStoreBill ? Ionicons.person : Ionicons.business,
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Bill info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.billNumber,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${bill.billType.displayName} • ${_formatDate(bill.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        // Amount and actions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${bill.billData.correctTotal.toStringAsFixed(2)}',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildActionButton(
                                  icon: Ionicons.create_outline,
                                  tooltip: 'Edit Bill',
                                  onPressed: () async {
                                    final updated = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) =>
                                              BillEditDialog(bill: bill),
                                    );
                                    if (updated == true) {
                                      ref
                                          .read(billControllerProvider.notifier)
                                          .loadBills();
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                _buildActionButton(
                                  icon: Ionicons.trash_outline,
                                  tooltip: 'Delete Bill',
                                  onPressed: () => _deleteBill(bill),
                                ),
                                const SizedBox(width: 4),
                                _buildActionButton(
                                  icon: Ionicons.print_outline,
                                  tooltip: 'Print Bill',
                                  onPressed: () => _printBill(bill),
                                ),
                                const SizedBox(width: 4),
                                _buildActionButton(
                                  icon: Ionicons.download_outline,
                                  tooltip: 'Download PDF',
                                  onPressed: () => _downloadBill(bill),
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineSoft,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.thumbBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateBill(double spacing) {
    final orderRepository = ref.watch(orderRepositoryProvider);

    return FutureBuilder<List<Order>>(
      future:
          orderRepository is OrderRepositorySupabase
              ? orderRepository.getAllOrders(limit: 100)
              : Future.value(<Order>[]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading orders...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Ionicons.alert_circle_outline,
                      size: 48,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error Loading Orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Ionicons.refresh_outline),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final allOrders = snapshot.data ?? [];
        // Only show orders that have been converted to sales (confirmed or higher)
        final orders =
            allOrders.where((o) => o.status != OrderStatus.processing).toList();

        if (orders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Ionicons.receipt_outline,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No orders found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Orders will appear here when customers place orders',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(spacing),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _showBillTypeSelectionModal(order),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: order.status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          order.status.icon,
                          color: order.status.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
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
                              '${order.totalItems} items • ${_formatDate(order.orderDate)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: order.status.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                order.status.displayName,
                                style: TextStyle(
                                  color: order.status.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${order.total.toStringAsFixed(2)}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            Ionicons.chevron_forward_outline,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Check if order has cost prices available for manufacturer bills
  Future<bool> _checkOrderHasCostPrices(Order order) async {
    try {
      final billRepository = ref.read(billRepositoryProvider);
      final orderItemsWithCost = await billRepository
          .getOrderItemsWithCostPrices(order.id);

      if (orderItemsWithCost.isEmpty) {
        return false;
      }

      // Check if any item has a cost price (either in variant or product)
      for (final itemData in orderItemsWithCost) {
        final variant = itemData['product_variants'] as List?;
        final product = itemData['products'] as Map<String, dynamic>?;

        if (variant != null && variant.isNotEmpty) {
          final variantData = variant.first as Map<String, dynamic>;
          final costPrice = variantData['cost_price'];
          if (costPrice != null) {
            return true;
          }
        }

        if (product != null) {
          final costPrice = product['cost_price'];
          if (costPrice != null) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      // If there's an error, don't show manufacturer bill option
      return false;
    }
  }

  /// Show modal to select bill type (Customer or Manufacturer)
  void _showBillTypeSelectionModal(Order order) async {
    final hasCostPrices = await _checkOrderHasCostPrices(order);

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Ionicons.receipt_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Generate Bill',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Order: ${order.orderNumber}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                // Store Bill Option
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.blue.shade50,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleGenerateCustomerBill(order);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Ionicons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Store Bill',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Generate bill with selling prices',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.blue.shade700),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Ionicons.chevron_forward_outline,
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Manufacturer Bill Option (only if cost prices exist)
                if (hasCostPrices) ...[
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.orange.shade50,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _showManufacturerSelectionModal(order);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Ionicons.business,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Manufacturer Bill',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Generate bill with cost prices',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Ionicons.chevron_forward_outline,
                              color: Colors.orange.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Widget _buildTemplatesTab(BillState state, double spacing) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Templates',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload custom bill format templates for store and manufacturer bills',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          // Store bill template
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Ionicons.person,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Store Bill Template',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BillTemplateUploadWidget(
                    billType: BillType.user,
                    onTemplateUploaded: () {
                      ref.read(billControllerProvider.notifier).loadTemplates();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Manufacturer bill template
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Ionicons.business,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Manufacturer Bill Template',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BillTemplateUploadWidget(
                    billType: BillType.manufacturer,
                    onTemplateUploaded: () {
                      ref.read(billControllerProvider.notifier).loadTemplates();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Existing templates
          if (state.templates.isNotEmpty) ...[
            Text(
              'Existing Templates',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...state.templates.map((template) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          template.isActive
                              ? Colors.green.withOpacity(0.1)
                              : AppColors.thumbBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      template.isActive
                          ? Ionicons.checkmark_circle
                          : Ionicons.ellipse_outline,
                      color:
                          template.isActive
                              ? Colors.green
                              : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    template.templateName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    template.templateType.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing:
                      template.isActive
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          )
                          : TextButton(
                            onPressed: () {
                              ref
                                  .read(billControllerProvider.notifier)
                                  .setActiveTemplate(template.id);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text('Set Active'),
                          ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Show modal to select manufacturer for manufacturer bill
  void _showManufacturerSelectionModal(Order order) {
    showDialog(
      context: context,
      builder:
          (context) => Consumer(
            builder: (context, ref, child) {
              final manufacturerState = ref.watch(
                manufacturerControllerProvider,
              );

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Ionicons.business_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select Manufacturer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child:
                      manufacturerState.loading
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                          : manufacturerState.error != null
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Ionicons.alert_circle_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  manufacturerState.error!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(
                                          manufacturerControllerProvider
                                              .notifier,
                                        )
                                        .loadManufacturers();
                                  },
                                  icon: const Icon(Ionicons.refresh_outline),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                          : manufacturerState.manufacturers.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Ionicons.business_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No manufacturers found',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please add manufacturers first',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                          : SizedBox(
                            height: 400,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: manufacturerState.manufacturers.length,
                              itemBuilder: (context, index) {
                                final manufacturer =
                                    manufacturerState.manufacturers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Ionicons.business,
                                        color: Colors.orange,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      manufacturer.businessName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'GST: ${manufacturer.formattedGstNumber}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Ionicons.chevron_forward_outline,
                                      color: Colors.grey.shade400,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _handleGenerateManufacturerBill(
                                        order,
                                        manufacturer,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          ),
    );
  }

  /// Show dialog for bill payment details input
  Future<Map<String, double>?> _showBillPaymentDetailsDialog({
    required double defaultShipping,
    required double calculatedOldDue,
    required double orderTotal,
  }) async {
    final shippingController = TextEditingController(
      text: defaultShipping.toStringAsFixed(2),
    );
    final oldDueController = TextEditingController(
      text: calculatedOldDue.toStringAsFixed(2),
    );
    final totalAmount = orderTotal + calculatedOldDue;
    final receivedAmountController = TextEditingController(
      text: totalAmount.toStringAsFixed(2),
    );

    return showDialog<Map<String, double>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bill Payment Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: shippingController,
                    decoration: const InputDecoration(
                      labelText: 'Shipping Price',
                      prefixText: '₹',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: oldDueController,
                    decoration: const InputDecoration(
                      labelText: 'Old Due',
                      prefixText: '₹',
                      border: OutlineInputBorder(),
                      helperText: 'Auto-calculated from previous bills',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: receivedAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Received Amount',
                      prefixText: '₹',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
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
              ElevatedButton(
                onPressed: () {
                  try {
                    final shipping =
                        double.tryParse(shippingController.text) ?? 0.0;
                    final oldDue =
                        double.tryParse(oldDueController.text) ?? 0.0;
                    final receivedAmount =
                        double.tryParse(receivedAmountController.text) ?? 0.0;

                    Navigator.of(context).pop({
                      'shipping': shipping,
                      'oldDue': oldDue,
                      'receivedAmount': receivedAmount,
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid input: $e')),
                    );
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  /// Handle store bill generation
  Future<void> _handleGenerateCustomerBill(Order order) async {
    if (!mounted) return;

    // Calculate old due first
    final billRepository = ref.read(billRepositoryProvider);
    // User requested to NOT automatically calculate old due. Default to 0.
    const oldDue = 0.0;

    // Show payment details dialog
    final paymentDetails = await _showBillPaymentDetailsDialog(
      defaultShipping: order.shipping,
      calculatedOldDue: oldDue,
      orderTotal: order.total,
    );

    if (paymentDetails == null) {
      // User cancelled
      return;
    }

    // Show loading dialog
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
                    Text('Generating store bill...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final bill = await ref
          .read(billControllerProvider.notifier)
          .generateBillFromOrder(
            order: order,
            billType: BillType.user,
            shipping: paymentDetails['shipping']!,
            oldDue: paymentDetails['oldDue']!,
            receivedAmount: paymentDetails['receivedAmount']!,
          );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (bill != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Ionicons.checkmark_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Store bill generated successfully')),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                _tabController.animateTo(0);
              },
            ),
          ),
        );
        // Switch to Bills tab
        _tabController.animateTo(0);
      } else {
        final error = ref.read(billControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to generate store bill'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Handle manufacturer bill generation
  Future<void> _handleGenerateManufacturerBill(
    Order order,
    Manufacturer manufacturer,
  ) async {
    if (!mounted) return;

    // Calculate old due first (for manufacturer bills, we might not have old due, but allow manual entry)
    final billRepository = ref.read(billRepositoryProvider);
    // User requested to NOT automatically calculate old due. Default to 0.
    const oldDue = 0.0;

    // Show payment details dialog
    final paymentDetails = await _showBillPaymentDetailsDialog(
      defaultShipping: order.shipping,
      calculatedOldDue: oldDue,
      orderTotal: order.total,
    );

    if (paymentDetails == null) {
      // User cancelled
      return;
    }

    // Show loading dialog
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
                    Text('Generating manufacturer bill...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final bill = await ref
          .read(billControllerProvider.notifier)
          .generateManufacturerBill(
            manufacturerId: manufacturer.id,
            order: order,
            shipping: paymentDetails['shipping']!,
            oldDue: paymentDetails['oldDue']!,
            receivedAmount: paymentDetails['receivedAmount']!,
          );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (bill != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Ionicons.checkmark_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Manufacturer bill generated successfully'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                _tabController.animateTo(0);
              },
            ),
          ),
        );
        // Switch to Bills tab
        _tabController.animateTo(0);
      } else {
        final error = ref.read(billControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to generate manufacturer bill'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Bill'),
            content: const Text(
              'Are you sure you want to delete this bill? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(billControllerProvider.notifier).deleteBill(bill.id);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadBill(Bill bill) async {
    // Prevent multiple simultaneous share operations
    if (_isSharing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the current share to complete'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final pdfBytes = await ref
          .read(billControllerProvider.notifier)
          .downloadBillPdf(bill);

      if (pdfBytes != null) {
        // Share/download PDF
        // For web, we'll use share_plus which handles XFile
        final xFile = XFile.fromData(
          pdfBytes,
          name: '${bill.billNumber}.pdf',
          mimeType: 'application/pdf',
        );
        try {
          await Share.shareXFiles([xFile], text: 'Bill: ${bill.billNumber}');
        } catch (e) {
          // Handle the specific "earlier share has not yet completed" error
          if (e.toString().contains('earlier share has not yet completed') ||
              e.toString().contains('InvalidStateError')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please wait for the current share to complete',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
          rethrow;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to download bill: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _printBill(Bill bill) async {
    try {
      final pdfBytes = await ref
          .read(billControllerProvider.notifier)
          .downloadBillPdf(bill);

      if (pdfBytes != null) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to print bill: $e')));
      }
    }
  }

  Future<void> _exportBills(BillState state) async {
    if (state.bills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bills to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent multiple simultaneous share operations
    if (_isSharing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for the current share to complete'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      // Create CSV content
      final csvBuffer = StringBuffer();
      csvBuffer.writeln(
        'Bill Number,Type,Date,Total,Subtotal,Shipping,Old Due,Received Amount,Balance Due',
      );

      for (final bill in state.bills) {
        csvBuffer.writeln(
          '${bill.billNumber},'
          '${bill.billType.displayName},'
          '${_formatDate(bill.createdAt)},'
          '${bill.billData.correctTotal.toStringAsFixed(2)},'
          '${bill.billData.subtotal.toStringAsFixed(2)},'
          '${bill.billData.shipping.toStringAsFixed(2)},'
          '${bill.billData.oldDue.toStringAsFixed(2)},'
          '${bill.billData.receivedAmount.toStringAsFixed(2)},'
          '${bill.billData.balanceDue.toStringAsFixed(2)}',
        );
      }

      final csvString = csvBuffer.toString();
      final csvBytes = Uint8List.fromList(csvString.codeUnits);
      final xFile = XFile.fromData(
        csvBytes,
        name: 'bills_export_${DateTime.now().millisecondsSinceEpoch}.csv',
        mimeType: 'text/csv',
      );

      try {
        await Share.shareXFiles([xFile], text: 'Bills Export');
      } catch (e) {
        // Handle the specific "earlier share has not yet completed" error
        if (e.toString().contains('earlier share has not yet completed') ||
            e.toString().contains('InvalidStateError')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please wait for the current share to complete'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        rethrow;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to export bills: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}
