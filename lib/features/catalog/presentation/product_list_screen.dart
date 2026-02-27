import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/data/shared_product_provider.dart';
import 'widgets/product_grid.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(allProductsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('All Products')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ProductGrid(items: items),
      ),
    );
  }
}
