import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../catalog/data/product.dart';
import '../../../catalog/presentation/widgets/responsive_product_card.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final double? cardWidth;

  const ProductCard({super.key, required this.product, this.cardWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveProductCard(
      product: product,
      onTap: () => context.push('/product/${product.id}'),
    );
  }
}
