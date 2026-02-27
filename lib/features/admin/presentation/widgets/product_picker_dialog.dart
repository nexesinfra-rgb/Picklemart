import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../catalog/data/product.dart';
import '../../../catalog/data/shared_product_provider.dart';
import '../../application/admin_product_controller.dart';

class ProductPickerDialog extends ConsumerStatefulWidget {
  final List<String> excludeProductIds; // Product IDs already in order

  const ProductPickerDialog({super.key, this.excludeProductIds = const []});

  @override
  ConsumerState<ProductPickerDialog> createState() =>
      _ProductPickerDialogState();
}

class _ProductPickerDialogState extends ConsumerState<ProductPickerDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Product? _selectedProduct;
  Variant? _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Ensure products are loaded when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProductControllerProvider.notifier).loadProducts();
      ref.read(sharedProductProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(adminProductControllerProvider);
    final sharedState = ref.watch(sharedProductProvider);

    // Filter products: exclude already added products and out of stock
    final availableProducts =
        (productState.filteredProducts.isNotEmpty
                ? productState.filteredProducts
                : sharedState.products)
            .where((product) {
              // Exclude products already in order
              if (widget.excludeProductIds.contains(product.id)) {
                return false;
              }
              // Exclude out of stock products
              if (product.isOutOfStock) {
                return false;
              }
              // Apply search filter if query exists
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                return product.name.toLowerCase().contains(query) ||
                    (product.brand?.toLowerCase().contains(query) ?? false) ||
                    product.alternativeNames.any(
                      (name) => name.toLowerCase().contains(query),
                    );
              }
              return true;
            })
            .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'Select Product',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Ionicons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Ionicons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  ref
                      .read(adminProductControllerProvider.notifier)
                      .searchProducts(value);
                },
              ),
            ),

            // Product list
            Expanded(
              child:
                  availableProducts.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Ionicons.search_outline,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No available products'
                                  : 'No products found',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: availableProducts.length,
                        itemBuilder: (context, index) {
                          final product = availableProducts[index];
                          final isSelected = _selectedProduct?.id == product.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color:
                                isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withOpacity(0.3)
                                    : null,
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: const Icon(Ionicons.image_outline),
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                product.name,
                                style: TextStyle(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.brand != null)
                                    Text('Brand: ${product.brand}'),
                                  Text(
                                    '₹${product.finalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing:
                                  isSelected
                                      ? Icon(
                                        Ionicons.checkmark_circle,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      )
                                      : null,
                              onTap: () {
                                setState(() {
                                  _selectedProduct = product;
                                  _selectedVariant =
                                      product.variants.isNotEmpty
                                          ? product.variants.first
                                          : null;
                                  _quantity = 1;
                                });
                              },
                            ),
                          );
                        },
                      ),
            ),

            // Selected product details and quantity
            if (_selectedProduct != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${_selectedProduct!.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedProduct!.variants.isNotEmpty) ...[
                      DropdownButtonFormField<Variant>(
                        value: _selectedVariant,
                        decoration: const InputDecoration(
                          labelText: 'Select Variant',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items:
                            _selectedProduct!.variants.map((variant) {
                              final attributes = variant.attributes.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(', ');
                              return DropdownMenuItem(
                                value: variant,
                                child: Text(
                                  '$attributes - ₹${variant.finalPrice.toStringAsFixed(2)}',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVariant = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quantity Selector
                        Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Ionicons.remove),
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                onPressed:
                                    _quantity > 1
                                        ? () {
                                          setState(() {
                                            _quantity--;
                                          });
                                        }
                                        : null,
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 32),
                                alignment: Alignment.center,
                                child: Text(
                                  _quantity.toString(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Ionicons.add),
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                onPressed: () {
                                  setState(() {
                                    _quantity++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Total
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '₹${((_selectedVariant?.finalPrice ?? _selectedProduct!.finalPrice) * _quantity).toStringAsFixed(2)}',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
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
            ],

            // Action buttons
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        _selectedProduct != null
                            ? () {
                              Navigator.of(context).pop({
                                'product': _selectedProduct,
                                'quantity': _quantity,
                                'variant': _selectedVariant,
                              });
                            }
                            : null,
                    child: const Text('Add Product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
