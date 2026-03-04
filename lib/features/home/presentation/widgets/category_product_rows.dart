import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../catalog/data/shared_product_provider.dart';
import '../../../catalog/data/recent_categories.dart';
import '../../../catalog/data/product.dart';
// import 'product_carousel.dart'; // Removed for new implementation

class CategoryProductRows extends ConsumerWidget {
  final int maxCategories;
  final int maxItemsPerRow;
  const CategoryProductRows({
    super.key,
    this.maxCategories = 6,
    this.maxItemsPerRow = 6,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(allProductsProvider);
    // final viewed = ref.watch(recentCategoriesProvider); // Ignore viewed history

    // Order categories strictly by priority
    final ordered = List<String>.from(categories)..sort((a, b) {
       final priorityA = getCategorySortPriority(a);
       final priorityB = getCategorySortPriority(b);
       return priorityA.compareTo(priorityB);
    });
    
    // Take only the top N categories
    final displayCategories = ordered.take(maxCategories).toList();

    final rows = <Widget>[];
    for (final c in displayCategories) {
      final items = _byCategory(products, c).take(maxItemsPerRow).toList();
      if (items.isEmpty) continue;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed:
                    () => context.pushNamed(
                      'browse',
                      pathParameters: {'kind': 'category', 'value': c},
                    ),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
      );

      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SizedBox(
            height: 100,
            child: Center(
              child: Text(
                '${items.length} products in $c - new cards coming soon',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Iterable<Product> _byCategory(List<Product> all, String category) {
    final lc = category.toLowerCase();
    return all.where((p) => p.categories.any((c) => c.toLowerCase() == lc));
  }
}
