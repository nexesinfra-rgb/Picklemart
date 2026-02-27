import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/catalog/data/product.dart';
import '../../../../features/catalog/data/product_repository.dart';
import '../../../../core/widgets/lazy_image.dart';

/// Product selector widget for sharing products in chat
class ProductSelectorWidget extends ConsumerStatefulWidget {
  final Function(Product) onProductSelected;

  const ProductSelectorWidget({
    super.key,
    required this.onProductSelected,
  });

  @override
  ConsumerState<ProductSelectorWidget> createState() =>
      _ProductSelectorWidgetState();
}

class _ProductSelectorWidgetState
    extends ConsumerState<ProductSelectorWidget> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsFuture = ref.watch(productRepositoryProvider).fetchAll();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Select Product to Share',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            // Products list
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading products: ${snapshot.error}'),
                    );
                  }

                  final products = snapshot.data ?? [];
                  final filteredProducts = _searchQuery.isEmpty
                      ? products
                      : products.where((product) {
                          return product.name
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              (product.description?.toLowerCase().contains(_searchQuery) ?? false);
                        }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(child: Text('No products found'));
                  }

                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: LazyImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Text('₹${product.finalPrice.toStringAsFixed(2)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          widget.onProductSelected(product);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

