import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../catalog/data/product.dart';
import 'infinite_scroll_grid_new.dart';

class InfiniteProducts extends ConsumerWidget {
  final List<Product> products;
  final int maxCount;
  final VoidCallback? onProductTap;
  final VoidCallback? onAddToCart;
  final String? category;

  const InfiniteProducts({
    super.key,
    required this.products,
    this.maxCount = 6,
    this.onProductTap,
    this.onAddToCart,
    this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the new infinite scroll grid with proper lazy loading and responsive design
    return InfiniteScrollGridNew(
      category: category,
      onProductTap: onProductTap,
      onAddToCart: onAddToCart,
    );
  }
}
