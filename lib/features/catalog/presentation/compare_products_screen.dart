import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/product_repository.dart';
import '../../../core/ui/safe_scaffold.dart';
import 'widgets/compare_product_card.dart';

class CompareProductsScreen extends ConsumerStatefulWidget {
  final String productIds; // Comma-separated product IDs

  const CompareProductsScreen({
    super.key,
    required this.productIds,
  });

  @override
  ConsumerState<CompareProductsScreen> createState() =>
      _CompareProductsScreenState();
}

class _CompareProductsScreenState extends ConsumerState<CompareProductsScreen> {
  List<Product> _products = [];
  final Map<String, bool> _expandedStates = {};
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
      final productIds = widget.productIds.split(',').where((id) => id.isNotEmpty).toList();
      final products = <Product>[];

      for (final id in productIds) {
        final product = await repository.fetchById(id.trim());
        if (product != null) {
          products.add(product);
          _expandedStates[product.id] = false;
        }
      }

      setState(() {
        _products = products;
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

  void _toggleExpanded(String productId) {
    setState(() {
      _expandedStates[productId] = !(_expandedStates[productId] ?? false);
    });
  }

  void _removeProduct(String productId) {
    setState(() {
      _products.removeWhere((p) => p.id == productId);
      _expandedStates.remove(productId);
    });

    if (_products.length < 2) {
      // If less than 2 products, go back to selection
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Need at least 2 products to compare. Redirecting...'),
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _products.isNotEmpty) {
            context.push('/compare/select/${_products.first.id}');
          } else if (mounted) {
            context.pop();
          }
        });
      }
    } else {
      // Update URL with remaining products
      final remainingIds = _products.map((p) => p.id).join(',');
      context.go('/compare/$remainingIds');
    }
  }

  void _addMoreProducts() {
    if (_products.isEmpty) {
      context.pop();
      return;
    }
    context.push('/compare/select/${_products.first.id}');
  }

  void _clearAll() {
    if (_products.isEmpty) {
      context.pop();
      return;
    }
    context.push('/compare/select/${_products.first.id}');
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      appBar: AppBar(
        title: Text('Compare ${_products.length} Products'),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.home_outline),
            onPressed: () => context.go('/home'),
            tooltip: 'Go to home',
          ),
          if (_products.length < 4)
            IconButton(
              icon: const Icon(Ionicons.add_circle_outline),
              onPressed: _addMoreProducts,
              tooltip: 'Add more products',
            ),
          IconButton(
            icon: const Icon(Ionicons.refresh_outline),
            onPressed: _clearAll,
            tooltip: 'Start over',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.git_compare_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products to compare',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Ionicons.arrow_back),
                        label: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.information_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap on any product to expand and view details',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Product list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isExpanded = _expandedStates[product.id] ?? false;
                          return CompareProductCard(
                            product: product,
                            isExpanded: isExpanded,
                            onExpandToggle: () => _toggleExpanded(product.id),
                            onRemove: _products.length > 2
                                ? () => _removeProduct(product.id)
                                : null,
                          );
                        },
                      ),
                    ),
                    // Action buttons
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
                        child: Row(
                          children: [
                            if (_products.length < 4)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _addMoreProducts,
                                  icon: const Icon(Ionicons.add),
                                  label: const Text('Add More'),
                                ),
                              ),
                            if (_products.length < 4) const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _clearAll,
                                icon: const Icon(Ionicons.refresh),
                                label: const Text('Start Over'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

