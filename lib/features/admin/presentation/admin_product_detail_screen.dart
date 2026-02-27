import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/measurement.dart';
import '../../catalog/presentation/widgets/image_gallery.dart';
import '../application/admin_product_controller.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_auth_guard.dart';

class AdminProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const AdminProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<AdminProductDetailScreen> createState() =>
      _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState
    extends ConsumerState<AdminProductDetailScreen> {
  late Future<Product?> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = ref
        .read(productRepositoryProvider)
        .fetchById(widget.productId);
  }

  @override
  void didUpdateWidget(covariant AdminProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _productFuture = ref
          .read(productRepositoryProvider)
          .fetchById(widget.productId);
    }
  }

  void _handleUpdate(Product product) {
    context.pushNamed('admin-product-form', extra: product);
  }

  Future<void> _handleDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text(
              'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(false);
                  }
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final controller = ref.read(adminProductControllerProvider.notifier);
      final success = await controller.deleteProduct(product.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to products list
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed('admin-products');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete product'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleToggleOutOfStock(Product product) async {
    final newStatus = !product.isOutOfStock;
    final action = newStatus ? 'mark as out of stock' : 'mark as in stock';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(newStatus ? 'Mark Out of Stock' : 'Mark In Stock'),
            content: Text(
              newStatus
                  ? 'Are you sure you want to mark "${product.name}" as out of stock? Customers will see this product as unavailable.'
                  : 'Are you sure you want to mark "${product.name}" as in stock? Customers will be able to purchase this product.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(false);
                  }
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: newStatus ? Colors.orange : Colors.green,
                ),
                child: Text(newStatus ? 'Mark Out of Stock' : 'Mark In Stock'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final controller = ref.read(adminProductControllerProvider.notifier);
      final success = await controller.toggleOutOfStock(product.id, newStatus);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus
                    ? 'Product marked as out of stock'
                    : 'Product marked as in stock',
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the product detail view
          if (mounted) {
            setState(() {
              _productFuture = ref
                  .read(productRepositoryProvider)
                  .fetchById(product.id);
            });
          }
        } else {
          final controllerState = ref.read(adminProductControllerProvider);
          final errorMessage = controllerState.error ?? 'Failed to $action';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: FutureBuilder<Product?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return AdminScaffold(
              title: 'Product Details',
              showBackButton: true,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final product = snapshot.data;
          if (product == null) {
            return AdminScaffold(
              title: 'Product Details',
              showBackButton: true,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Ionicons.cube_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Product not found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed('admin-products');
                        }
                      },
                      child: const Text('Back to Products'),
                    ),
                  ],
                ),
              ),
            );
          }

          return AdminScaffold(
            title: product.name,
            showBackButton: true,
            body: _buildProductDetail(context, product),
          );
        },
      ),
    );
  }

  Widget _buildProductDetail(BuildContext context, Product product) {
    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    final images =
        product.images.isNotEmpty ? product.images : [product.imageUrl];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(screenSize == ScreenSize.mobile ? 16 : 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images
                  isWide
                      ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: ImageGallery(
                              images: images,
                              product: product,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 5,
                            child: _buildProductInfo(context, product),
                          ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ImageGallery(images: images, product: product),
                          const SizedBox(height: 24),
                          _buildProductInfo(context, product),
                        ],
                      ),
                  // Add bottom padding for buttons
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
        // Update and Delete Buttons at Bottom
        Container(
          padding: EdgeInsets.all(screenSize == ScreenSize.mobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _handleUpdate(product),
                        icon: const Icon(Ionicons.create_outline),
                        label: const Text('Update Product'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _handleDelete(product),
                        icon: const Icon(Ionicons.trash_outline),
                        label: const Text('Delete Product'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _handleToggleOutOfStock(product),
                    icon: Icon(
                      product.isOutOfStock
                          ? Ionicons.checkmark_circle_outline
                          : Ionicons.close_circle_outline,
                    ),
                    label: Text(
                      product.isOutOfStock
                          ? 'Mark In Stock'
                          : 'Mark Out of Stock',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          product.isOutOfStock ? Colors.green : Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context, Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Name and Subtitle
        Text(
          product.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (product.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            product.subtitle!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Price Information with Breakdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹${product.finalPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPriceRow(
                      context,
                      'Selling Price',
                      '₹${product.price.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 24),
                    _buildPriceRow(
                      context,
                      'Total Price',
                      '₹${product.finalPrice.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    if (product.costPrice != null) ...[
                      const Divider(height: 24),
                      _buildPriceRow(
                        context,
                        'Purchase Price',
                        '₹${product.costPrice!.toStringAsFixed(2)}',
                        isCost: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stock Status and SKU Information
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildInfoChip(
              context,
              icon:
                  product.isOutOfStock
                      ? Ionicons.close_circle_outline
                      : Ionicons.checkmark_circle_outline,
              label: 'Status',
              value: product.isOutOfStock ? 'Out of Stock' : 'In Stock',
              color: product.isOutOfStock ? Colors.red : Colors.green,
            ),
            if (product.sku != null)
              _buildInfoChip(
                context,
                icon: Ionicons.barcode_outline,
                label: 'SKU',
                value: product.sku!,
              ),
            if (product.brand != null)
              _buildInfoChip(
                context,
                icon: Ionicons.business_outline,
                label: 'Brand',
                value: product.brand!,
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Description
        if (product.description != null && product.description!.isNotEmpty) ...[
          Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.description!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Categories
        if (product.categories.isNotEmpty) ...[
          Text(
            'Categories',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                product.categories.map((category) {
                  return Chip(label: Text(category));
                }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Tags
        if (product.tags.isNotEmpty) ...[
          Text(
            'Tags',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                product.tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.15),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Alternative Names
        if (product.alternativeNames.isNotEmpty) ...[
          Text(
            'Alternative Names',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                product.alternativeNames.map((name) {
                  return Chip(
                    label: Text(
                      name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Variants
        if (product.variants.isNotEmpty) ...[
          Text(
            'Variants',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...product.variants.map((variant) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(variant.sku),
                subtitle: Text(
                  variant.attributes.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join(' • '),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${variant.finalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Stock: ${variant.stock}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],

        // Measurement Pricing
        if (product.measurement != null) ...[
          Text(
            'Measurement Pricing',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Type: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(product.measurement!.category ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Default Unit: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(product.measurement!.defaultUnit.displayName),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pricing Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...product.measurement!.pricingOptions.map((pricing) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(pricing.unit.displayName),
                          Text('₹${pricing.price.toStringAsFixed(2)}'),
                          Text('Stock: ${pricing.stock}'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Timestamps
        if (product.createdAt != null || product.updatedAt != null) ...[
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Metadata',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (product.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Created: ${_formatDate(product.createdAt!)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          if (product.updatedAt != null)
            Text(
              'Updated: ${_formatDate(product.updatedAt!)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            color != null
                ? color.withOpacity(0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border:
            color != null ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    bool isCost = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color:
                isCost
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    : null,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color:
                isTotal
                    ? Theme.of(context).colorScheme.primary
                    : isCost
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    : null,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
