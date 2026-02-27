import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_action_bottom_bar.dart';
import '../domain/purchase_order.dart';
import '../application/purchase_order_controller.dart';
import '../application/manufacturer_controller.dart';

class AdminPurchaseOrdersScreen extends ConsumerStatefulWidget {
  const AdminPurchaseOrdersScreen({super.key});

  @override
  ConsumerState<AdminPurchaseOrdersScreen> createState() =>
      _AdminPurchaseOrdersScreenState();
}

class _AdminPurchaseOrdersScreenState
    extends ConsumerState<AdminPurchaseOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(purchaseOrderControllerProvider.notifier)
            .setOnlyManufacturers(true);
        ref.read(manufacturerControllerProvider.notifier).loadManufacturers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final purchaseOrderState = ref.watch(purchaseOrderControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Purchase Orders',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Ionicons.add_outline),
            onPressed:
                () => context.pushNamed(
                  'admin-purchase-order-form',
                  queryParameters:
                      purchaseOrderState.selectedManufacturerId != null
                          ? {
                            'manufacturerId':
                                purchaseOrderState.selectedManufacturerId!,
                          }
                          : {},
                ),
            tooltip: 'Create Purchase Order',
          ),
        ],
        body: Stack(
          children: [
            purchaseOrderState.loading
                ? const Center(child: CircularProgressIndicator())
                : purchaseOrderState.error != null
                ? _buildErrorState(context, purchaseOrderState.error!)
                : purchaseOrderState.filteredPurchaseOrders.isEmpty
                ? _buildEmptyState(context, spacing)
                : Column(
                  children: [
                    _buildFilters(context, spacing),
                    Expanded(
                      child: _buildPurchaseOrdersList(
                        context,
                        purchaseOrderState,
                        spacing,
                      ),
                    ),
                  ],
                ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: AdminActionBottomBar(
                manufacturerId: purchaseOrderState.selectedManufacturerId,
                onRefresh: () {
                  ref.read(purchaseOrderControllerProvider.notifier).refresh();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.alert_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading purchase orders',
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
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(purchaseOrderControllerProvider.notifier)
                    .loadPurchaseOrders();
              },
              icon: const Icon(Ionicons.refresh_outline),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double spacing) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.cube_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No purchase orders found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first purchase order',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final state = ref.read(purchaseOrderControllerProvider);
                context.pushNamed(
                  'admin-purchase-order-form',
                  queryParameters:
                      state.selectedManufacturerId != null
                          ? {'manufacturerId': state.selectedManufacturerId!}
                          : {},
                );
              },
              icon: const Icon(Ionicons.add_outline),
              label: const Text('Create Purchase Order'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, double spacing) {
    final purchaseOrderState = ref.watch(purchaseOrderControllerProvider);
    final manufacturerState = ref.watch(manufacturerControllerProvider);

    return Container(
      padding: EdgeInsets.all(spacing),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(context, 'All', null, spacing),
                SizedBox(width: spacing * 0.5),
                ...PurchaseOrderStatus.values.map((status) {
                  return Padding(
                    padding: EdgeInsets.only(right: spacing * 0.5),
                    child: _buildStatusChip(
                      context,
                      status.displayName,
                      status,
                      spacing,
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: spacing),
          // Manufacturer Filter
          DropdownButtonFormField<String>(
            initialValue: purchaseOrderState.selectedManufacturerId,
            decoration: InputDecoration(
              labelText: 'Filter by Manufacturer',
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: spacing,
                vertical: spacing * 0.75,
              ),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Manufacturers'),
              ),
              ...manufacturerState.manufacturers.map((manufacturer) {
                return DropdownMenuItem(
                  value: manufacturer.id,
                  child: Text(manufacturer.businessName),
                );
              }),
            ],
            onChanged: (value) {
              ref
                  .read(purchaseOrderControllerProvider.notifier)
                  .filterByManufacturer(value);
              ref
                  .read(purchaseOrderControllerProvider.notifier)
                  .loadPurchaseOrders();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    String label,
    PurchaseOrderStatus? status,
    double spacing,
  ) {
    final purchaseOrderState = ref.watch(purchaseOrderControllerProvider);
    final isSelected = purchaseOrderState.selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref
            .read(purchaseOrderControllerProvider.notifier)
            .filterByStatus(selected ? status : null);
        ref.read(purchaseOrderControllerProvider.notifier).loadPurchaseOrders();
      },
      selectedColor:
          status?.color.withOpacity(0.2) ??
          Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: status?.color ?? Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildPurchaseOrdersList(
    BuildContext context,
    PurchaseOrderState state,
    double spacing,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(purchaseOrderControllerProvider.notifier)
            .loadPurchaseOrders();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(spacing),
        itemCount: state.filteredPurchaseOrders.length,
        itemBuilder: (context, index) {
          final purchaseOrder = state.filteredPurchaseOrders[index];
          return _buildPurchaseOrderCard(context, purchaseOrder, spacing);
        },
      ),
    );
  }

  Widget _buildPurchaseOrderCard(
    BuildContext context,
    PurchaseOrder purchaseOrder,
    double spacing,
  ) {
    final manufacturerState = ref.watch(manufacturerControllerProvider);
    final manufacturer =
        manufacturerState.manufacturers
            .where((m) => m.id == purchaseOrder.manufacturerId)
            .firstOrNull;

    return Card(
      margin: EdgeInsets.only(bottom: spacing * 0.75),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          context
              .pushNamed(
                'admin-purchase-order-detail',
                pathParameters: {'id': purchaseOrder.id},
              )
              .then((value) {
                if (value == true && mounted) {
                  ref
                      .read(purchaseOrderControllerProvider.notifier)
                      .loadPurchaseOrders();
                }
              });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchaseOrder.purchaseNumber,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (manufacturer != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            manufacturer.businessName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
                          size: 16,
                          color: purchaseOrder.status.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          purchaseOrder.status.displayName,
                          style: TextStyle(
                            color: purchaseOrder.status.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              // Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Builder(
                          builder: (context) {
                            DateTime displayDate = purchaseOrder.purchaseDate;
                            if (displayDate.hour == 0 &&
                                displayDate.minute == 0 &&
                                displayDate.second == 0) {
                              final createdAtLocal = purchaseOrder.createdAt.toLocal();
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          '${purchaseOrder.totalItems} items',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          'Rs ${purchaseOrder.total.toStringAsFixed(2)}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Actions
              SizedBox(height: spacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      context.pushNamed(
                        'admin-purchase-order-form',
                        queryParameters: {'id': purchaseOrder.id},
                      );
                    },
                    icon: const Icon(Ionicons.create_outline, size: 18),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      context.pushNamed(
                        'admin-purchase-order-detail',
                        pathParameters: {'id': purchaseOrder.id},
                      );
                    },
                    icon: const Icon(Ionicons.eye_outline, size: 18),
                    label: const Text('View'),
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
