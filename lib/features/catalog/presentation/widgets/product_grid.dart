import 'package:flutter/material.dart';
import '../../../catalog/data/product.dart';
import 'responsive_product_grid.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> items;
  final String? category;
  const ProductGrid({super.key, required this.items, this.category});

  @override
  Widget build(BuildContext context) {
    // Always use the responsive grid system with shrinkWrap: true
    // to avoid unbounded height errors when nested in scrollable widgets
    return ResponsiveProductGrid(
      products: items,
      category: category,
      useMasonryLayout: true,
      shrinkWrap: true,
    );
  }
}