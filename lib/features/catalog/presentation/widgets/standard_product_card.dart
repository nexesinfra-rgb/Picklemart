import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive_grid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/lazy_image.dart';
import '../../../cart/application/cart_controller.dart';
import '../../../catalog/data/product.dart';
import '../../../wishlist/presentation/widgets/wishlist_heart_button.dart';
import '../../../profile/application/profile_controller.dart';

/// Standardized product card with consistent sizing and overflow prevention
class StandardProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final int? initialQuantity;
  final bool isHorizontal;

  const StandardProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.initialQuantity,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridConfig = ResponsiveGrid.getGridConfig(screenWidth);
    final breakpointInfo = ResponsiveBreakpoints.getBreakpointInfo(screenWidth);

    // Use horizontal layout for ultra-compact screens or when explicitly requested
    final useHorizontal = isHorizontal || breakpointInfo.isHorizontal;

    if (useHorizontal) {
      return _buildHorizontalCard(context, ref, gridConfig);
    } else {
      return _buildVerticalCard(context, ref, gridConfig);
    }
  }

  Widget _buildVerticalCard(
    BuildContext context,
    WidgetRef ref,
    ResponsiveGridConfig config,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: config.maxCardWidth,
        maxHeight: config.maxCardHeight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : config.maxCardHeight;
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : config.maxCardWidth;

          // Calculate responsive maxLines based on available height
          final maxTitleLines = availableHeight > 280
              ? 3 // Large cards can show 3 lines
              : availableHeight > 200
                  ? 2 // Medium cards show 2 lines
                  : 1; // Small cards show 1 line

          return InkWell(
            onTap: onTap ??
                () => context.push('/product/${product.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.15), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image section with 1:1 aspect ratio and heart button
                  Stack(
                    children: [
                      AspectRatio(aspectRatio: 1, child: _buildImage()),
                      if (product.isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      if (product.isOutOfStock)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      WishlistHeartButton(productId: product.id),
                    ],
                  ),
                  // Content section with intrinsic sizing
                  _buildContent(
                      context, ref, config, availableWidth, maxTitleLines),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    WidgetRef ref,
    ResponsiveGridConfig config,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: config.maxCardWidth,
        maxHeight: config.maxCardHeight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : config.maxCardWidth;

          // Calculate responsive image size and spacing
          final imageSize = availableWidth < 300 ? 60.0 : 80.0;
          final padding = availableWidth < 300 ? 6.0 : 8.0;
          final spacing = availableWidth < 300 ? 8.0 : 12.0;

          return InkWell(
            onTap: onTap ??
                () => context.push('/product/${product.id}'),
            borderRadius: BorderRadius.circular(12),
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.outlineMedium, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  children: [
                    // Image section with constraint-based sizing
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: _buildHorizontalImage(),
                      ),
                    ),
                    SizedBox(width: spacing),
                    // Content section
                    Expanded(child: _buildHorizontalContent(context, ref)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalImage() {
    return Stack(
      children: [
        _buildImage(),
        if (product.isOutOfStock)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        if (product.isOutOfStock)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Out of Stock',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        WishlistHeartButton(productId: product.id, size: 20),
      ],
    );
  }

  Widget _buildImage() {
    final image = LazyImage(
      imageUrl: product.imageUrl,
      fit: BoxFit.fill,
      borderRadius: BorderRadius.circular(8),
    );
    
    if (product.isOutOfStock) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: image,
      );
    }
    
    return image;
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ResponsiveGridConfig config,
    double availableWidth,
    int maxTitleLines,
  ) {
    // Calculate responsive padding based on card width
    final padding = availableWidth < 150 ? 6.0 : 8.0;
    final spacing = availableWidth < 150 ? 4.0 : 6.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product name with responsive maxLines
          Text(
            product.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: _getResponsiveFontSize(config),
                ),
            maxLines: maxTitleLines,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: spacing),
          // Product price
          Consumer(
            builder: (context, ref, child) {
              final profile = ref.watch(currentProfileProvider);
              if (profile == null || !profile.priceVisibilityEnabled) {
                return const SizedBox.shrink();
              }
              return Text(
                '₹${product.finalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: _getResponsiveFontSize(config) + 1,
                    ),
              );
            },
          ),
          SizedBox(height: spacing),
          // Add to cart button
          _buildAddToCartButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildHorizontalContent(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Product name with responsive maxLines
        Text(
          product.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Product price
        Consumer(
          builder: (context, ref, child) {
            final profile = ref.watch(currentProfileProvider);
            if (profile == null || !profile.priceVisibilityEnabled) {
              return const SizedBox.shrink();
            }
            return Text(
              '₹${product.finalPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
            );
          },
        ),
        const SizedBox(height: 4),
        // Add to cart button
        _buildAddToCartButton(context, ref),
      ],
    );
  }

  Widget _buildAddToCartButton(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    // Optimized: Calculate quantity by iterating once (handles multiple cart items per product)
    final int quantity = initialQuantity ??
        () {
          int qty = 0;
          for (final item in cartState.values) {
            if (item.product.id == product.id) {
              qty += item.quantity;
            }
          }
          return qty;
        }();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: product.isOutOfStock
            ? null
            : onAddToCart ?? () => ref.read(cartProvider.notifier).add(product),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (quantity > 0 && !product.isOutOfStock) ...[
              Icon(Ionicons.remove_circle_outline, size: 16, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                quantity.toString(),
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              product.isOutOfStock
                  ? Ionicons.close_circle_outline
                  : quantity > 0
                      ? Ionicons.add_circle_outline
                      : Ionicons.cart_outline,
              size: 16,
              color: Colors.black,
            ),
            const SizedBox(width: 4),
            Text(
              product.isOutOfStock
                  ? 'Out of Stock'
                  : quantity > 0
                      ? 'Add'
                      : 'Add to Cart',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getResponsiveFontSize(ResponsiveGridConfig config) {
    if (config.isHorizontal) {
      return 12;
    }

    if (config.crossAxisCount == 1) return 10;
    if (config.crossAxisCount == 2) return 11;
    if (config.crossAxisCount == 3) return 12;
    if (config.crossAxisCount == 4) return 13;
    return 14;
  }
}
