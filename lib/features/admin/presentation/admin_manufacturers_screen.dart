import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_action_bottom_bar.dart';
import '../application/manufacturer_controller.dart';
import '../domain/manufacturer.dart';

class AdminManufacturersScreen extends ConsumerStatefulWidget {
  const AdminManufacturersScreen({super.key});

  @override
  ConsumerState<AdminManufacturersScreen> createState() =>
      _AdminManufacturersScreenState();
}

class _AdminManufacturersScreenState
    extends ConsumerState<AdminManufacturersScreen> {
  final _searchController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Load manufacturers when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(manufacturerControllerProvider.notifier).loadManufacturers();
        _isInitialized = true;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);
    final spacing = Responsive.getSpacingForFoldable(width);
    final manufacturerState = ref.watch(manufacturerControllerProvider);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Manufacturers',
        showBackButton: true,
        actions: [
          ResponsiveIconButton(
            icon: const Icon(Ionicons.refresh_outline),
            onPressed: () {
              ref.read(manufacturerControllerProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
        body: Stack(
          children: [
            Column(
              children: [
                // Search bar
                Padding(
                  padding: EdgeInsets.all(spacing),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search manufacturers...',
                      prefixIcon: const Icon(Ionicons.search_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Ionicons.close_outline),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(
                                        manufacturerControllerProvider.notifier,
                                      )
                                      .searchManufacturers('');
                                },
                              )
                              : null,
                    ),
                    onChanged: (value) {
                      ref
                          .read(manufacturerControllerProvider.notifier)
                          .searchManufacturers(value);
                    },
                  ),
                ),
                // Content
                Expanded(
                  child:
                      manufacturerState.loading
                          ? const Center(child: CircularProgressIndicator())
                          : manufacturerState.error != null
                          ? _buildErrorState(manufacturerState.error!)
                          : manufacturerState.filteredManufacturers.isEmpty
                          ? _buildEmptyState()
                          : _buildManufacturersList(
                            manufacturerState.filteredManufacturers,
                            spacing,
                          ),
                ),
              ],
            ),
            // Floating Action Button
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: AdminActionBottomBar(
                onRefresh: () {
                  ref
                      .read(manufacturerControllerProvider.notifier)
                      .loadManufacturers();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
            'Failed to load manufacturers',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(manufacturerControllerProvider.notifier).refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.business_outline,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No manufacturers found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first manufacturer to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManufacturersList(
    List<Manufacturer> manufacturers,
    double spacing,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(spacing),
      itemCount: manufacturers.length,
      itemBuilder: (context, index) {
        final manufacturer = manufacturers[index];
        return _buildManufacturerCard(context, manufacturer, spacing);
      },
    );
  }

  Widget _buildManufacturerCard(
    BuildContext context,
    Manufacturer manufacturer,
    double spacing,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: spacing * 0.75),
      child: InkWell(
        onTap: () => _showManufacturerDetails(context, manufacturer),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: EdgeInsets.all(spacing),
          leading: CircleAvatar(
            backgroundColor: manufacturer.isActive ? Colors.green : Colors.grey,
            radius: 24,
            child: Icon(Ionicons.business, color: Colors.white),
          ),
          title: Text(
            manufacturer.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                manufacturer.businessName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'GST: ${manufacturer.formattedGstNumber}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                manufacturer.fullAddress,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          manufacturer.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      manufacturer.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            manufacturer.isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected:
                (value) =>
                    _handleManufacturerAction(context, manufacturer, value),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Ionicons.eye_outline),
                        SizedBox(width: 8),
                        Text('View'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Ionicons.create_outline),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: manufacturer.isActive ? 'deactivate' : 'activate',
                    child: Row(
                      children: [
                        Icon(
                          manufacturer.isActive
                              ? Ionicons.pause_outline
                              : Ionicons.play_outline,
                        ),
                        const SizedBox(width: 8),
                        Text(manufacturer.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'create_bill',
                    child: Row(
                      children: [
                        Icon(Ionicons.receipt_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Create Bill'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Ionicons.trash_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }

  void _showManufacturerDetails(
    BuildContext context,
    Manufacturer manufacturer,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        manufacturer.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Ionicons.business,
                    color: manufacturer.isActive ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    manufacturer.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          context,
                          'Manufacturer Name',
                          manufacturer.name,
                          Ionicons.business_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Business Name',
                          manufacturer.businessName,
                          Ionicons.briefcase_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'GST Number',
                          manufacturer.formattedGstNumber,
                          Ionicons.document_text_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Business Address',
                          manufacturer.businessAddress,
                          Ionicons.location_outline,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                context,
                                'City',
                                manufacturer.city,
                                Ionicons.location_outline,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailRow(
                                context,
                                'State',
                                manufacturer.state,
                                Ionicons.map_outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          context,
                          'Pincode',
                          manufacturer.pincode,
                          Ionicons.pin_outline,
                        ),
                        if (manufacturer.email != null &&
                            manufacturer.email!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            'Email',
                            manufacturer.email!,
                            Ionicons.mail_outline,
                          ),
                        ],
                        if (manufacturer.phone != null &&
                            manufacturer.phone!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            'Phone',
                            manufacturer.phone!,
                            Ionicons.call_outline,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    manufacturer.isActive
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    manufacturer.isActive
                                        ? Ionicons.checkmark_circle
                                        : Ionicons.close_circle,
                                    size: 16,
                                    color:
                                        manufacturer.isActive
                                            ? Colors.green
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    manufacturer.isActive
                                        ? 'Active'
                                        : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          manufacturer.isActive
                                              ? Colors.green
                                              : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (manufacturer.createdAt != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            'Created At',
                            _formatDate(manufacturer.createdAt!),
                            Ionicons.calendar_outline,
                          ),
                        ],
                        if (manufacturer.updatedAt != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            context,
                            'Updated At',
                            _formatDate(manufacturer.updatedAt!),
                            Ionicons.time_outline,
                          ),
                        ],
                        const SizedBox(height: 80), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AdminActionBottomBar(
                    manufacturerId: manufacturer.id,
                    onRefresh: () {
                      ref
                          .read(manufacturerControllerProvider.notifier)
                          .loadManufacturers();
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pushNamed(
                    'admin-payment-out-list',
                    queryParameters: {'manufacturerId': manufacturer.id},
                  );
                },
                icon: const Icon(Ionicons.list_outline, size: 18),
                label: const Text('View Transactions'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/admin/manufacturers/${manufacturer.id}/edit');
                },
                icon: const Icon(Ionicons.create_outline, size: 18),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleManufacturerAction(
    BuildContext context,
    Manufacturer manufacturer,
    String action,
  ) {
    switch (action) {
      case 'view':
        _showManufacturerDetails(context, manufacturer);
        break;
      case 'edit':
        context.push('/admin/manufacturers/${manufacturer.id}/edit');
        break;
      case 'activate':
      case 'deactivate':
        _toggleManufacturerStatus(manufacturer);
        break;
      case 'create_bill':
        _showCreateBillDialog(context, manufacturer);
        break;
      case 'payment_out':
        context.pushNamed(
          'admin-payment-out',
          extra: {'manufacturerId': manufacturer.id},
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context, manufacturer);
        break;
    }
  }

  void _showCreateBillDialog(BuildContext context, Manufacturer manufacturer) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Ionicons.receipt_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Create Manufacturer Bill',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            content: Text(
              'Create a bill for ${manufacturer.businessName}?\n\nThis will generate a manufacturer bill with cost prices.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to bill creation screen or show order selection
                  context.push(
                    '/admin/billing?manufacturerId=${manufacturer.id}',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Create Bill'),
              ),
            ],
          ),
    );
  }

  void _toggleManufacturerStatus(Manufacturer manufacturer) async {
    try {
      final updated = manufacturer.copyWith(isActive: !manufacturer.isActive);
      final success = await ref
          .read(manufacturerControllerProvider.notifier)
          .updateManufacturer(updated);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Manufacturer ${updated.isActive ? 'activated' : 'deactivated'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Manufacturer manufacturer,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Manufacturer'),
            content: Text(
              'Are you sure you want to delete "${manufacturer.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final success = await ref
                      .read(manufacturerControllerProvider.notifier)
                      .deleteManufacturer(manufacturer.id);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Manufacturer deleted successfully'),
                      ),
                    );
                  } else if (mounted) {
                    final state = ref.read(manufacturerControllerProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.error ?? 'Failed to delete manufacturer',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
