import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/layout/responsive.dart';
import '../application/admin_inventory_controller.dart';
import '../data/inventory_models.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() =>
      _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  bool _showLowStockOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(adminInventoryControllerProvider);
    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Inventory Management',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddInventoryDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminInventoryControllerProvider.notifier).refresh();
            },
          ),
        ],
        body: inventoryState.loading
            ? const Center(child: CircularProgressIndicator())
            : inventoryState.error != null
            ? _buildErrorState(inventoryState.error!)
            : _buildResponsiveInventoryContent(
              inventoryState,
              screenSize,
              foldableBreakpoint,
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
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load inventory',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(adminInventoryControllerProvider.notifier).refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveInventoryContent(
    AdminInventoryState state,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildResponsiveSearchAndFilters(spacing),
          _buildResponsiveAlertsSection(state.stockAlerts, spacing),
          _buildResponsiveInventoryList(
            state,
            screenSize,
            foldableBreakpoint,
            spacing,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveSearchAndFilters(double spacing) {
    final width = MediaQuery.of(context).size.width;
    final isUltraCompact = Responsive.isUltraCompactDevice(width);

    return Card(
      margin: EdgeInsets.all(spacing),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(adminInventoryControllerProvider.notifier)
                                .searchInventory('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref
                    .read(adminInventoryControllerProvider.notifier)
                    .searchInventory(value);
              },
            ),
            SizedBox(height: spacing * 0.75),
            isUltraCompact
                ? Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filter by',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Products'),
                        ),
                        DropdownMenuItem(
                          value: 'low_stock',
                          child: Text('Low Stock'),
                        ),
                        DropdownMenuItem(
                          value: 'out_of_stock',
                          child: Text('Out of Stock'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value ?? 'all';
                        });
                      },
                    ),
                    SizedBox(height: spacing * 0.5),
                    Row(
                      children: [
                        Switch(
                          value: _showLowStockOnly,
                          onChanged: (value) {
                            setState(() {
                              _showLowStockOnly = value;
                            });
                          },
                        ),
                        const Text('Low Stock Only'),
                      ],
                    ),
                  ],
                )
                : Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Products'),
                          ),
                          DropdownMenuItem(
                            value: 'low_stock',
                            child: Text('Low Stock'),
                          ),
                          DropdownMenuItem(
                            value: 'out_of_stock',
                            child: Text('Out of Stock'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value ?? 'all';
                          });
                        },
                      ),
                    ),
                    SizedBox(width: spacing * 0.75),
                    Switch(
                      value: _showLowStockOnly,
                      onChanged: (value) {
                        setState(() {
                          _showLowStockOnly = value;
                        });
                      },
                    ),
                    SizedBox(width: spacing * 0.25),
                    const Text('Low Stock Only'),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveAlertsSection(
    List<StockAlert> alerts,
    double spacing,
  ) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: spacing),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
                SizedBox(width: spacing * 0.5),
                Text(
                  'Stock Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 0.5),
            ...alerts.map(
              (alert) => Padding(
                padding: EdgeInsets.only(bottom: spacing * 0.25),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color:
                          alert.currentStock <= 0 ? Colors.red : Colors.orange,
                    ),
                    SizedBox(width: spacing * 0.5),
                    Expanded(
                      child: Text(
                        '${alert.productName}: ${alert.currentStock <= 0 ? "Out of stock" : "Low stock (${alert.currentStock} remaining)"}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveInventoryList(
    AdminInventoryState state,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
    double spacing,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: Column(
        children:
            state.inventoryItems.map((item) {
              return Padding(
                padding: EdgeInsets.only(bottom: spacing * 0.5),
                child: _buildInventoryItem(item, screenSize),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(adminInventoryControllerProvider.notifier)
                                .searchInventory('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref
                    .read(adminInventoryControllerProvider.notifier)
                    .searchInventory(value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Products'),
                      ),
                      DropdownMenuItem(
                        value: 'low_stock',
                        child: Text('Low Stock'),
                      ),
                      DropdownMenuItem(
                        value: 'out_of_stock',
                        child: Text('Out of Stock'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value ?? 'all';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _showLowStockOnly,
                  onChanged: (value) {
                    setState(() {
                      _showLowStockOnly = value;
                    });
                  },
                ),
                const Text('Low Stock Only'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(List<StockAlert> alerts) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Stock Alerts (${alerts.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...alerts
                .take(3)
                .map(
                  (alert) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${alert.productName}: ${alert.currentStock} units (threshold: ${alert.threshold})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ),
            if (alerts.length > 3)
              Text(
                '... and ${alerts.length - 3} more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList(AdminInventoryState state, ScreenSize screenSize) {
    final filteredItems = _getFilteredItems(state);

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No inventory items found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          filteredItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInventoryItem(item, screenSize),
            );
          }).toList(),
    );
  }

  List<InventoryItem> _getFilteredItems(AdminInventoryState state) {
    var items = state.filteredInventoryItems;

    if (_selectedFilter == 'low_stock') {
      items =
          items
              .where((item) => item.currentStock <= item.minStockThreshold)
              .toList();
    } else if (_selectedFilter == 'out_of_stock') {
      items = items.where((item) => item.currentStock == 0).toList();
    }

    if (_showLowStockOnly) {
      items =
          items
              .where((item) => item.currentStock <= item.minStockThreshold)
              .toList();
    }

    return items;
  }

  Widget _buildInventoryItem(InventoryItem item, ScreenSize screenSize) {
    final isLowStock = item.currentStock <= item.minStockThreshold;
    final isOutOfStock = item.currentStock == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${item.productId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStockStatusChip(
                  isLowStock,
                  isOutOfStock,
                  item.currentStock,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStockInfo(
                    'Current Stock',
                    item.currentStock.toString(),
                    isLowStock ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStockInfo(
                    'Min Threshold',
                    item.minStockThreshold.toString(),
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStockInfo(
                    'Last Updated',
                    _formatDate(item.lastUpdated),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            if (item.suppliers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Suppliers: ${item.suppliers.join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUpdateStockDialog(item),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Update Stock'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showItemDetails(item),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockStatusChip(
    bool isLowStock,
    bool isOutOfStock,
    int currentStock,
  ) {
    Color color;
    String text;

    if (isOutOfStock) {
      color = Colors.red;
      text = 'Out of Stock';
    } else if (isLowStock) {
      color = Colors.orange;
      text = 'Low Stock';
    } else {
      color = Colors.green;
      text = 'In Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void _showAddInventoryDialog() {
    showDialog(context: context, builder: (context) => _AddInventoryDialog());
  }

  void _showUpdateStockDialog(InventoryItem item) {
    final controller = TextEditingController(
      text: item.currentStock.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Update Stock - ${item.productName}'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New Stock Level',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                  }
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newStock = int.tryParse(controller.text);
                  if (newStock != null && newStock >= 0) {
                    final success = await ref
                        .read(adminInventoryControllerProvider.notifier)
                        .updateStock(item.productId, newStock);

                    if (success && context.mounted) {
                      if (Navigator.of(context).canPop()) {
                        if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stock updated successfully'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showItemDetails(InventoryItem item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(item.productName),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Product ID', item.productId),
                    _buildDetailRow('Current Stock', item.currentStock.toString()),
                    _buildDetailRow(
                      'Min Threshold',
                      item.minStockThreshold.toString(),
                    ),
                    _buildDetailRow('Last Updated', _formatDate(item.lastUpdated)),
                    if (item.suppliers.isNotEmpty)
                      _buildDetailRow('Suppliers', item.suppliers.join(', ')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                  }
                },
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _AddInventoryDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddInventoryDialog> createState() =>
      _AddInventoryDialogState();
}

class _AddInventoryDialogState extends ConsumerState<_AddInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productIdController = TextEditingController();
  final _productNameController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minThresholdController = TextEditingController();
  final _suppliersController = TextEditingController();

  @override
  void dispose() {
    _productIdController.dispose();
    _productNameController.dispose();
    _currentStockController.dispose();
    _minThresholdController.dispose();
    _suppliersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Inventory Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _productIdController,
                decoration: const InputDecoration(
                  labelText: 'Product ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentStockController,
                decoration: const InputDecoration(
                  labelText: 'Current Stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current stock';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null || stock < 0) {
                    return 'Please enter a valid stock number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minThresholdController,
                decoration: const InputDecoration(
                  labelText: 'Min Stock Threshold',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter min threshold';
                  }
                  final threshold = int.tryParse(value);
                  if (threshold == null || threshold < 0) {
                    return 'Please enter a valid threshold';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _suppliersController,
                decoration: const InputDecoration(
                  labelText: 'Suppliers (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final suppliers =
                  _suppliersController.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();

              final newItem = InventoryItem(
                productId: _productIdController.text,
                productName: _productNameController.text,
                currentStock: int.parse(_currentStockController.text),
                minStockThreshold: int.parse(_minThresholdController.text),
                lastUpdated: DateTime.now(),
                suppliers: suppliers,
              );

              final success = await ref
                  .read(adminInventoryControllerProvider.notifier)
                  .addInventoryItem(newItem);

              if (success && context.mounted) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inventory item added successfully'),
                  ),
                );
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
