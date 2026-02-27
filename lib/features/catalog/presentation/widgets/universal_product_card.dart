import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../catalog/data/product.dart';
import '../../../catalog/presentation/widgets/responsive_product_card.dart';

class UniversalProductCard extends ConsumerWidget {
  final Product product;
  final double? cardWidth;

  const UniversalProductCard({
    super.key,
    required this.product,
    this.cardWidth,
  });

  /// Calculates the aspect ratio for product cards based on screen width
  static double getCardAspectRatio(
    double screenWidth, {
    double? customCardWidth,
  }) {
    // We adjust based on screen size for optimal density
    // Smaller aspect ratio = more vertical space (width / height)
    // New design needs more height for the additional elements
    if (screenWidth <= 165) return 0.75; // Mobile ultra-compact
    if (screenWidth < 600) return 0.83; // Mobile standard (Much shorter height)
    if (screenWidth < 1200) return 0.86; // Tablet (Much shorter height)
    return 0.89; // Desktop (Much shorter height)
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveProductCard(
      product: product,
      onTap: () => context.push('/product/${product.id}'),
    );
  }
}
