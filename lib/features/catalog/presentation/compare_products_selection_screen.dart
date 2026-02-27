import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/product_repository.dart';
import '../../../core/ui/safe_scaffold.dart';
import 'widgets/compare_product_item.dart';

class CompareProductsSelectionScreen extends ConsumerStatefulWidget {
  final String currentProductId;

  const CompareProductsSelectionScreen({
    super.key,
    required this.currentProductId,
  });

  @override
  ConsumerState<CompareProductsSelectionScreen> createState() =>
      _CompareProductsSelectionScreenState();
}

class _CompareProductsSelectionScreenState
    extends ConsumerState<CompareProductsSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Product? _currentProduct;
  final Set<String> _selectedProductIds = {};
  List<Product> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(productRepositoryProvider);
      final products = await repository.fetchAll();
      final currentProduct = await repository.fetchById(widget.currentProductId);

      setState(() {
        _allProducts = products.where((p) => p.id != widget.currentProductId).toList();
        _currentProduct = currentProduct;
        if (currentProduct != null) {
          _selectedProductIds.add(currentProduct.id);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _allProducts;
    }

    final query = _searchQuery.toLowerCase();
    return _allProducts.where((product) {
      // Search in product name
      if (product.name.toLowerCase().contains(query)) return true;

      // Search in subtitle
      if (product.subtitle != null &&
          product.subtitle!.toLowerCase().contains(query)) {
        return true;
      }

      // Search in brand
      if (product.brand != null &&
          product.brand!.toLowerCase().contains(query)) {
        return true;
      }

      // Search in alternative names
      if (product.alternativeNames.any((name) {
        final trimmedName = name.trim();
        return trimmedName.isNotEmpty &&
            trimmedName.toLowerCase().contains(query);
      })) {
        return true;
      }

      // Search in tags
      if (product.tags.any((tag) => tag.toLowerCase().contains(query))) {
        return true;
      }

      // Search in categories
      if (product.categories.any(
          (category) => category.toLowerCase().contains(query))) {
        return true;
      }

      return false;
    }).toList();
  }

  void _toggleProductSelection(String productId) {
    if (_selectedProductIds.contains(productId)) {
      // Don't allow deselecting current product
      if (productId == widget.currentProductId) return;
      setState(() {
        _selectedProductIds.remove(productId);
      });
    } else {
      // Maximum 4 products (1 current + 3 additional)
      if (_selectedProductIds.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can compare up to 4 products at once'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      setState(() {
        _selectedProductIds.add(productId);
      });
    }
  }

  void _navigateToComparison() {
    if (_selectedProductIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one more product to compare'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final productIds = _selectedProductIds.join(',');
    context.push('/compare/$productIds');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedProductIds.length;
    final canSelectMore = selectedCount < 4;

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
        actions: [
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '$selectedCount selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products to compare...',
                      prefixIcon: const Icon(Ionicons.search_outline),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Ionicons.close_circle),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                // Info message
                if (canSelectMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Select up to ${4 - selectedCount} more product${4 - selectedCount > 1 ? 's' : ''} to compare',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.information_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Maximum 4 products selected. Deselect a product to add another.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Product list
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Ionicons.search_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No products available'
                                    : 'No products found',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final isSelected = _selectedProductIds.contains(product.id);
                            return CompareProductItem(
                              product: product,
                              isSelected: isSelected,
                              onTap: () => _toggleProductSelection(product.id),
                            );
                          },
                        ),
                ),
                // Current product section (moved to bottom)
                if (_currentProduct != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Product',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        CompareProductItem(
                          product: _currentProduct!,
                          isSelected: true,
                          isCurrentProduct: true,
                        ),
                      ],
                    ),
                  ),
                ],
                // Compare button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: selectedCount >= 2 ? _navigateToComparison : null,
                        icon: const Icon(Ionicons.git_compare),
                        label: Text(
                          selectedCount >= 2
                              ? 'Compare $selectedCount Products'
                              : 'Select at least 2 products',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

