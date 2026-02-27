import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../data/product.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/safe_scaffold.dart';
import 'widgets/universal_product_card.dart';
import '../data/shared_product_provider.dart' as shared;

class FeaturedProductsScreen extends ConsumerWidget {
  const FeaturedProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(shared.featuredProductsProvider);
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);
    final ultra = Responsive.isUltraCompact(width);
    final singleColumn = Responsive.isSingleColumnMobile(width);

    final gridDelegate = _buildGridDelegate(width, bp, ultra, singleColumn);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Featured Products'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: products.isEmpty
          ? const Center(
              child: Text('No featured products available'),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < products.length) {
                          return _ProductCard(
                            product: products[index],
                          );
                        }
                        return null;
                      },
                      childCount: products.length,
                    ),
                    gridDelegate: gridDelegate,
                  ),
                ),
              ],
            ),
    );
  }

  SliverGridDelegate _buildGridDelegate(
    double width,
    AppBreakpoint bp,
    bool ultra,
    bool singleColumn,
  ) {
    // Use UniversalProductCard's actual aspect ratio to prevent overflow
    final aspectRatio = UniversalProductCard.getCardAspectRatio(width);
    
    // Always use 2-column grid for featured products
    switch (bp) {
      case AppBreakpoint.compact:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        );
      case AppBreakpoint.medium:
        return SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        );
      case AppBreakpoint.expanded:
        return SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        );
    }
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = Responsive.getUnifiedProductCardWidth(width);
    
    return UniversalProductCard(
      product: product,
      cardWidth: cardWidth,
    );
  }
}

