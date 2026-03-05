import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/lazy_image.dart';
import '../../../cart/application/cart_controller.dart';
import '../../../catalog/data/product.dart';
import '../../../wishlist/presentation/widgets/wishlist_heart_button.dart';
import '../../../profile/application/profile_controller.dart';

/// A responsive product card widget optimized for different contexts
/// Provides consistent sizing and content fitting across all breakpoints
class ResponsiveProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final int? initialQuantity;
  final ProductCardContext context;
  final Widget? trailing;
  final Widget Function(
    BuildContext context,
    double height,
    bool isUltraCompact,
  )?
  actionButtonBuilder;
  final bool showWishlist;

  const ResponsiveProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.initialQuantity,
    this.context = ProductCardContext.grid,
    this.trailing,
    this.actionButtonBuilder,
    this.showWishlist = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isUltraCompact = screenWidth <= 165;

    final borderRadius = isUltraCompact ? 16.0 : 16.0; // Consistent radius
    final padding = isUltraCompact ? 8.0 : 12.0; // Comfortable padding
    final spacing = isUltraCompact ? 4.0 : 6.0; // Comfortable spacing
    final nameFontSize = isUltraCompact ? 12.0 : 13.5; // Readable text
    final priceFontSize = isUltraCompact ? 14.0 : 15.5;
    final buttonHeight = isUltraCompact ? 32.0 : 36.0; // Refined button height

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: Colors.grey.withOpacity(0.15), width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Background and Heart
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF8F9FA), // Light grey background
                    child: _buildProductImage(product),
                  ),
                  if (product.isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.6),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Heart Button on Image
                  if (showWishlist)
                    WishlistHeartButton(
                      productId: product.id,
                      top: 10,
                      right: 10,
                    ),
                  // Optional Tag/Badge (like 10% OFF)
                  if (product.costPrice != null &&
                      product.costPrice! > product.price)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ), // Compact badge
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF7A00), // Orange badge
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          '${((1 - product.price / product.costPrice!) * 100).toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ), // Smaller font
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding / 2,
              ), // Reduced vertical padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: nameFontSize,
                          color: const Color(0xFF1A1D1E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  // Price Row
                  Consumer(
                    builder: (context, ref, child) {
                      final profile = ref.watch(currentProfileProvider);
                      if (profile == null || !profile.priceVisibilityEnabled) {
                        return const SizedBox.shrink();
                      }
                      return Row(
                        children: [
                          Text(
                            '₹${product.finalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: priceFontSize,
                              color: const Color(0xFF1A1D1E),
                            ),
                          ),
                          if (product.costPrice != null &&
                              product.costPrice! > product.price) ...[
                            const SizedBox(width: 8),
                            Text(
                              '₹${product.costPrice!.toStringAsFixed(0)}',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: priceFontSize - 4,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  SizedBox(height: spacing),
                  // Add to Cart Button Row
                  Row(
                    children: [
                      Expanded(
                        child:
                            actionButtonBuilder != null
                                ? actionButtonBuilder!(
                                  context,
                                  buttonHeight,
                                  isUltraCompact,
                                )
                                : _buildAddToCartButton(
                                  context,
                                  ref,
                                  buttonHeight,
                                  isUltraCompact,
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    // Primary image attempt
    return LazyImage(
      imageUrl: product.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF8F9FA),
        child: Builder(
          builder: (context) {
            // Fallback 1: Try first image from gallery if available and different from primary
            if (product.images.isNotEmpty) {
              final fallbackUrl = product.images.first;
              if (fallbackUrl != product.imageUrl) {
                return LazyImage(
                  imageUrl: fallbackUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  // Fallback 2: Try second image if available
                  errorWidget: Builder(
                    builder: (context) {
                      if (product.images.length > 1) {
                        final fallbackUrl2 = product.images[1];
                        return LazyImage(
                          imageUrl: fallbackUrl2,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      }
                      // No more fallbacks, show default placeholder
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 24,
                        ),
                      );
                    },
                  ),
                );
              }
            }
            // No gallery images or same as primary, show default placeholder
            return const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(
    BuildContext context,
    WidgetRef ref,
    double height,
    bool isUltraCompact,
  ) {
    final cart = ref.watch(cartProvider);
    final key = '${product.id}:base';
    final qty = initialQuantity ?? cart[key]?.quantity ?? 0;

    if (qty == 0) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: FilledButton(
          onPressed:
              product.isOutOfStock
                  ? null
                  : onAddToCart ??
                      () => ref.read(cartProvider.notifier).add(product),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            padding: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Ionicons.cart_outline, size: 18, color: Colors.black),
                const SizedBox(width: 4),
                Text(
                  isUltraCompact ? 'Add' : 'ADD TO CART',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 20, color: Colors.black),
            onPressed: () => ref.read(cartProvider.notifier).remove(product),
            constraints: BoxConstraints(maxWidth: height, maxHeight: height),
            padding: EdgeInsets.zero,
          ),
          Text(
            '$qty',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 20, color: Colors.black),
            onPressed:
                product.isOutOfStock
                    ? null
                    : () => ref.read(cartProvider.notifier).add(product),
            constraints: BoxConstraints(maxWidth: height, maxHeight: height),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  CardConfig _getCardConfig(
    AppBreakpoint bp,
    bool isUltraCompact,
    bool isSingleColumn,
    ProductCardContext ctx,
  ) {
    switch (ctx) {
      case ProductCardContext.homepage:
        return _getHomepageConfig(bp, isUltraCompact, isSingleColumn);
      case ProductCardContext.grid:
        return _getGridConfig(bp, isUltraCompact, isSingleColumn);
      default:
        return _getGridConfig(bp, isUltraCompact, isSingleColumn);
    }
  }

  CardConfig _getHomepageConfig(
    AppBreakpoint bp,
    bool isUltraCompact,
    bool isSingleColumn,
  ) {
    switch (bp) {
      case AppBreakpoint.expanded:
        return CardConfig.homepageExpanded();
      case AppBreakpoint.medium:
        return CardConfig.homepageMedium();
      case AppBreakpoint.compact:
        if (isUltraCompact || isSingleColumn) {
          return CardConfig.homepageUltraCompact();
        }
        return CardConfig.homepageCompact();
    }
    return CardConfig.homepageCompact();
  }

  CardConfig _getGridConfig(
    AppBreakpoint bp,
    bool isUltraCompact,
    bool isSingleColumn,
  ) {
    // Ultra-compact threshold is now 165px wide
    switch (bp) {
      case AppBreakpoint.expanded:
        return CardConfig.gridExpanded();
      case AppBreakpoint.medium:
        return CardConfig.gridMedium();
      case AppBreakpoint.compact:
        if (isUltraCompact || isSingleColumn) {
          return CardConfig.gridUltraCompact();
        }
        return CardConfig.gridCompact();
    }
    // Fallback
    return CardConfig.gridCompact();
  }
}

/// Context for product cards to determine appropriate styling
enum ProductCardContext {
  homepage, // For carousel cards with more spacing
  grid, // For grid cards with compact layout
}

/// Configuration for responsive product cards
class CardConfig {
  final int imageFlex;
  final int contentFlex;
  final double padding;
  final double fontSize;
  final double priceFontSize;
  final double buttonFontSize;
  final double iconSize;
  final double buttonHeight;
  final double buttonPadding;
  final double borderRadius;
  final double buttonRadius;
  final double spacing;
  final int nameLines;

  const CardConfig({
    required this.imageFlex,
    required this.contentFlex,
    required this.padding,
    required this.fontSize,
    required this.priceFontSize,
    required this.buttonFontSize,
    required this.iconSize,
    required this.buttonHeight,
    required this.buttonPadding,
    required this.borderRadius,
    required this.buttonRadius,
    required this.spacing,
    required this.nameLines,
  });

  // Desktop configuration
  factory CardConfig.expanded() {
    return const CardConfig(
      imageFlex: 3,
      contentFlex: 2,
      padding: 19.2, // 20% increase from 16.0
      fontSize: 16.8, // 20% increase from 14.0
      priceFontSize: 19.2, // 20% increase from 16.0
      buttonFontSize: 16.8, // 20% increase from 14.0
      iconSize: 21.6, // 20% increase from 18.0
      buttonHeight: 57.6, // 20% increase from 48.0
      buttonPadding: 24.0, // 20% increase from 20.0
      borderRadius: 19.2, // 20% increase from 16.0
      buttonRadius: 14.4, // 20% increase from 12.0
      spacing: 9.6, // 20% increase from 8.0
      nameLines: 2,
    );
  }

  // Tablet configuration
  factory CardConfig.medium() {
    return const CardConfig(
      imageFlex: 3,
      contentFlex: 2,
      padding: 14.4, // 20% increase from 12.0
      fontSize: 15.6, // 20% increase from 13.0
      priceFontSize: 18.0, // 20% increase from 15.0
      buttonFontSize: 15.6, // 20% increase from 13.0
      iconSize: 19.2, // 20% increase from 16.0
      buttonHeight: 52.8, // 20% increase from 44.0
      buttonPadding: 19.2, // 20% increase from 16.0
      borderRadius: 16.8, // 20% increase from 14.0
      buttonRadius: 12.0, // 20% increase from 10.0
      spacing: 7.2, // 20% increase from 6.0
      nameLines: 2,
    );
  }

  // Mobile configuration
  factory CardConfig.compact() {
    return const CardConfig(
      imageFlex: 2,
      contentFlex: 1,
      padding: 7.2, // 20% increase from 6.0
      fontSize: 13.2, // 20% increase from 11.0
      priceFontSize: 14.4, // 20% increase from 12.0
      buttonFontSize: 12.0, // 20% increase from 10.0
      iconSize: 14.4, // 20% increase from 12.0
      buttonHeight: 38.4, // 20% increase from 32.0
      buttonPadding: 9.6, // 20% increase from 8.0
      borderRadius: 12.0, // 20% increase from 10.0
      buttonRadius: 7.2, // 20% increase from 6.0
      spacing: 3.6, // 20% increase from 3.0
      nameLines: 1,
    );
  }

  // Ultra compact configuration for very small screens
  factory CardConfig.ultraCompact() {
    return const CardConfig(
      imageFlex: 3,
      contentFlex: 1,
      padding: 3.6, // 20% increase from 3.0
      fontSize: 10.8, // 20% increase from 9.0
      priceFontSize: 12.0, // 20% increase from 10.0
      buttonFontSize: 9.6, // 20% increase from 8.0
      iconSize: 10.8, // 20% increase from 9.0
      buttonHeight: 31.2, // 20% increase from 26.0
      buttonPadding: 4.8, // 20% increase from 4.0
      borderRadius: 7.2, // 20% increase from 6.0
      buttonRadius: 3.6, // 20% increase from 3.0
      spacing: 1.2, // 20% increase from 1.0
      nameLines: 1,
    );
  }

  // Homepage configurations with more spacing
  factory CardConfig.homepageExpanded() {
    return const CardConfig(
      imageFlex: 3,
      contentFlex: 2,
      padding: 24.0, // 20% increase from 20.0
      fontSize: 19.2, // 20% increase from 16.0
      priceFontSize: 21.6, // 20% increase from 18.0
      buttonFontSize: 19.2, // 20% increase from 16.0
      iconSize: 24.0, // 20% increase from 20.0
      buttonHeight: 67.2, // 20% increase from 56.0
      buttonPadding: 28.8, // 20% increase from 24.0
      borderRadius: 24.0, // 20% increase from 20.0
      buttonRadius: 19.2, // 20% increase from 16.0
      spacing: 14.4, // 20% increase from 12.0
      nameLines: 2,
    );
  }

  factory CardConfig.homepageMedium() {
    return const CardConfig(
      imageFlex: 3,
      contentFlex: 2,
      padding: 21.6, // 20% increase from 18.0
      fontSize: 18.0, // 20% increase from 15.0
      priceFontSize: 20.4, // 20% increase from 17.0
      buttonFontSize: 18.0, // 20% increase from 15.0
      iconSize: 21.6, // 20% increase from 18.0
      buttonHeight: 62.4, // 20% increase from 52.0
      buttonPadding: 26.4, // 20% increase from 22.0
      borderRadius: 21.6, // 20% increase from 18.0
      buttonRadius: 16.8, // 20% increase from 14.0
      spacing: 12.0, // 20% increase from 10.0
      nameLines: 2,
    );
  }

  factory CardConfig.homepageCompact() {
    // Tweaked for 375–724px: bigger tap targets and text
    return const CardConfig(
      imageFlex: 2,
      contentFlex: 1,
      padding: 16.8, // 20% increase from 14.0
      fontSize: 16.8, // 20% increase from 14.0
      priceFontSize: 19.2, // 20% increase from 16.0
      buttonFontSize: 15.6, // 20% increase from 13.0
      iconSize: 21.6, // 20% increase from 18.0
      buttonHeight: 57.6, // 20% increase from 48.0
      buttonPadding: 21.6, // 20% increase from 18.0
      borderRadius: 16.8, // 20% increase from 14.0
      buttonRadius: 14.4, // 20% increase from 12.0
      spacing: 9.6, // 20% increase from 8.0
      nameLines: 1,
    );
  }

  factory CardConfig.homepageUltraCompact() {
    // Tweaked for very small phones: still bigger than before
    return const CardConfig(
      imageFlex: 2,
      contentFlex: 1,
      padding: 12.0, // 20% increase from 10.0
      fontSize: 14.4, // 20% increase from 12.0
      priceFontSize: 15.6, // 20% increase from 13.0
      buttonFontSize: 13.2, // 20% increase from 11.0
      iconSize: 16.8, // 20% increase from 14.0
      buttonHeight: 50.4, // 20% increase from 42.0
      buttonPadding: 16.8, // 20% increase from 14.0
      borderRadius: 14.4, // 20% increase from 12.0
      buttonRadius: 12.0, // 20% increase from 10.0
      spacing: 7.2, // 20% increase from 6.0
      nameLines: 1,
    );
  }

  // Grid configurations with compact layout
  factory CardConfig.gridExpanded() {
    return const CardConfig(
      imageFlex: 3,
      contentFlex: 2,
      padding: 20.0, // Reduced from 22.0 to prevent overflow
      fontSize: 16.8, // 20% increase from 14.0
      priceFontSize: 19.2, // 20% increase from 16.0
      buttonFontSize: 15.0, // Reduced from 16.8 for compact design
      iconSize: 21.6, // 20% increase from 18.0
      buttonHeight: 52.0, // Reduced from 57.6 to prevent overflow
      buttonPadding: 20.0, // Reduced from 24.0 for compact design
      borderRadius: 19.2, // 20% increase from 16.0
      buttonRadius: 14.4, // 20% increase from 12.0
      spacing: 9.6, // 20% increase from 8.0
      nameLines: 2,
    );
  }

  factory CardConfig.gridMedium() {
    return const CardConfig(
      imageFlex: 3,
      contentFlex: 2,
      padding: 14.0, // Reduced from 16.0 to prevent overflow
      fontSize: 15.6, // 20% increase from 13.0
      priceFontSize: 18.0, // 20% increase from 15.0
      buttonFontSize: 14.0, // Further reduced for compact design
      iconSize: 19.2, // 20% increase from 16.0
      buttonHeight: 44.0, // Reduced from 50.0 to prevent overflow
      buttonPadding: 16.0, // Further reduced for compact design
      borderRadius: 16.8, // 20% increase from 14.0
      buttonRadius: 12.0, // 20% increase from 10.0
      spacing: 6.5, // Reduced from 7.2
      nameLines: 2,
    );
  }

  factory CardConfig.gridCompact() {
    return const CardConfig(
      imageFlex: 2,
      contentFlex: 1,
      padding: 8.0, // Reduced from 10.0 to prevent overflow
      fontSize: 13.2, // 20% increase from 11.0
      priceFontSize: 14.4, // 20% increase from 12.0
      buttonFontSize: 11.0, // Further reduced for compact design
      iconSize: 14.4, // 20% increase from 12.0
      buttonHeight: 32.0, // Reduced from 36.0 to prevent overflow
      buttonPadding: 6.0, // Further reduced for compact design
      borderRadius: 12.0, // 20% increase from 10.0
      buttonRadius: 7.2, // 20% increase from 6.0
      spacing: 3.0, // Reduced from 3.6
      nameLines: 1,
    );
  }

  factory CardConfig.gridUltraCompact() {
    return const CardConfig(
      imageFlex: 3,
      contentFlex: 1,
      padding: 3.6, // 20% increase from 3.0
      fontSize: 10.8, // 20% increase from 9.0
      priceFontSize: 12.0, // 20% increase from 10.0
      buttonFontSize: 9.6, // 20% increase from 8.0
      iconSize: 10.8, // 20% increase from 9.0
      buttonHeight: 31.2, // 20% increase from 26.0
      buttonPadding: 4.8, // 20% increase from 4.0
      borderRadius: 7.2, // 20% increase from 6.0
      buttonRadius: 3.6, // 20% increase from 3.0
      spacing: 1.2, // 20% increase from 1.0
      nameLines: 1,
    );
  }
}
