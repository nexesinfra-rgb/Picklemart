import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/product.dart';
import '../../../cart/application/cart_controller.dart';
import '../../../wishlist/presentation/widgets/wishlist_heart_button.dart';
import '../../../../core/widgets/lazy_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive_grid.dart';
import '../../../admin/data/admin_features.dart';
import '../../../profile/application/profile_controller.dart';

class VerticalProductCard extends ConsumerWidget {
  final Product product;
  final double? height;

  const VerticalProductCard({
    super.key,
    required this.product,
    this.height,
  });

  /// Get responsive configuration based on screen width
  _CardConfig _getCardConfig(double screenWidth, double availableWidth) {
    final gridConfig = ResponsiveGrid.getGridConfig(screenWidth);
    final breakpointInfo = ResponsiveBreakpoints.getBreakpointInfo(screenWidth);
    
    // Mobile (compact, <600px)
    if (screenWidth < 600) {
      // Calculate image size based on available width (96-120px range)
      final imageSize = availableWidth < 350
          ? 96.0
          : availableWidth < 450
              ? 108.0
              : 120.0;
      
      return _CardConfig(
        imageSize: imageSize,
        padding: availableWidth < 350 ? 12.0 : 16.0,
        horizontalSpacing: availableWidth < 350 ? 12.0 : 16.0,
        spacing: availableWidth < 350 ? 6.0 : 10.0,
        titleFontSize: availableWidth < 350 ? 14.0 : 15.0,
        priceFontSize: availableWidth < 350 ? 16.0 : 18.0,
        buttonHeight: availableWidth < 350 ? 38.0 : 42.0,
        buttonIconSize: availableWidth < 350 ? 16.0 : 18.0,
        ratingIconSize: availableWidth < 350 ? 14.0 : 16.0,
        ratingSpacing: 6.0,
        borderRadius: 12.0,
        imageRadius: 8.0,
        maxCardWidth: gridConfig.maxCardWidth,
      );
    }
    // Tablet (medium, 600-1024px)
    else if (screenWidth < 1024) {
      // Calculate image size based on available width (120-160px range)
      final imageSize = availableWidth < 500
          ? 120.0
          : availableWidth < 700
              ? 140.0
              : 160.0;
      
      return _CardConfig(
        imageSize: imageSize,
        padding: availableWidth < 500 ? 16.0 : 20.0,
        horizontalSpacing: availableWidth < 500 ? 16.0 : 20.0,
        spacing: availableWidth < 500 ? 10.0 : 14.0,
        titleFontSize: availableWidth < 500 ? 15.0 : 16.0,
        priceFontSize: availableWidth < 500 ? 18.0 : 20.0,
        buttonHeight: availableWidth < 500 ? 42.0 : 46.0,
        buttonIconSize: availableWidth < 500 ? 18.0 : 20.0,
        ratingIconSize: availableWidth < 500 ? 16.0 : 18.0,
        ratingSpacing: 8.0,
        borderRadius: 12.0,
        imageRadius: 8.0,
        maxCardWidth: gridConfig.maxCardWidth,
      );
    }
    // Desktop (expanded, ≥1024px)
    else {
      // Calculate image size based on available width (160-200px range)
      final imageSize = availableWidth < 600
          ? 160.0
          : availableWidth < 800
              ? 180.0
              : 200.0;
      
      return _CardConfig(
        imageSize: imageSize,
        padding: availableWidth < 600 ? 20.0 : 24.0,
        horizontalSpacing: availableWidth < 600 ? 20.0 : 24.0,
        spacing: availableWidth < 600 ? 16.0 : 20.0,
        titleFontSize: availableWidth < 600 ? 16.0 : 18.0,
        priceFontSize: availableWidth < 600 ? 20.0 : 22.0,
        buttonHeight: availableWidth < 600 ? 48.0 : 52.0,
        buttonIconSize: availableWidth < 600 ? 20.0 : 22.0,
        ratingIconSize: availableWidth < 600 ? 18.0 : 20.0,
        ratingSpacing: 10.0,
        borderRadius: 12.0,
        imageRadius: 8.0,
        maxCardWidth: gridConfig.maxCardWidth,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    // Optimized: Find cart item for this product (O(n) but more efficient than where().firstOrNull)
    CartItem? cartItem;
    try {
      cartItem = cart.values.firstWhere((item) => item.product.id == product.id);
    } catch (e) {
      cartItem = null;
    }
    final qty = cartItem?.quantity ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screenWidth;
        
        final config = _getCardConfig(screenWidth, availableWidth);

        return Container(
          constraints: BoxConstraints(
            maxWidth: config.maxCardWidth,
          ),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(config.borderRadius),
              side: BorderSide(color: Colors.grey.withOpacity(0.15), width: 0.8),
            ),
            child: InkWell(
              onTap: () {
                context.push('/product/${product.id}');
              },
              child: Container(
                width: double.infinity,
                constraints: height != null ? BoxConstraints(minHeight: height!) : null,
                padding: EdgeInsets.all(config.padding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image on the left with constraint-based sizing and heart button
                    ClipRRect(
                      borderRadius: BorderRadius.circular(config.imageRadius),
                      child: SizedBox(
                        width: config.imageSize,
                        height: config.imageSize,
                        child: Stack(
                          children: [
                            product.isOutOfStock
                                ? ColorFiltered(
                                    colorFilter: ColorFilter.mode(Colors.grey, BlendMode.saturation),
                                    child: LazyImage(
                                      imageUrl: product.imageUrl,
                                      fit: BoxFit.fill,
                                      width: config.imageSize,
                                      height: config.imageSize,
                                      borderRadius: BorderRadius.circular(config.imageRadius),
                                    ),
                                  )
                                : LazyImage(
                                    imageUrl: product.imageUrl,
                                    fit: BoxFit.fill,
                                    width: config.imageSize,
                                    height: config.imageSize,
                                    borderRadius: BorderRadius.circular(config.imageRadius),
                                  ),
                            if (product.isOutOfStock)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(config.imageRadius),
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
                                      fontSize: screenWidth < 600 ? 8 : 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            WishlistHeartButton(
                              productId: product.id,
                              size: screenWidth < 600 ? 20 : (screenWidth < 1024 ? 22 : 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: config.horizontalSpacing),
                    // Product details on the right
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Product title with responsive maxLines
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: config.titleFontSize,
                                    ),
                              ),
                              SizedBox(height: config.spacing),
                              // Price
                              Consumer(
                                builder: (context, ref, child) {
                                  final profile = ref.watch(currentProfileProvider);
                                  if (profile == null || !profile.priceVisibilityEnabled) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    '₹${product.finalPrice.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).primaryColor,
                                          fontSize: config.priceFontSize,
                                        ),
                                  );
                                },
                              ),
                              SizedBox(height: config.spacing),
                              // Rating
                              Consumer(
                                builder: (context, ref, child) {
                                  final features = ref.watch(adminFeaturesProvider);
                                  if (!features.starRatingsEnabled || 
                                      product.averageRating == null || 
                                      product.ratingCount == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return _RatingRow(
                                    rating: product.averageRating!,
                                    count: product.ratingCount,
                                    iconSize: config.ratingIconSize,
                                    spacing: config.ratingSpacing,
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: config.spacing),
                          // Add to cart section
                          _AddOrStepper(
                            product: product,
                            qty: qty,
                            buttonHeight: config.buttonHeight,
                            buttonIconSize: config.buttonIconSize,
                            availableWidth: availableWidth,
                            screenWidth: screenWidth,
                            onAdd: () => ref.read(cartProvider.notifier).add(product),
                            onIncrement: () =>
                                ref.read(cartProvider.notifier).add(product),
                            onDecrement: () =>
                                ref.read(cartProvider.notifier).remove(product),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Configuration class for responsive card values
class _CardConfig {
  final double imageSize;
  final double padding;
  final double horizontalSpacing;
  final double spacing;
  final double titleFontSize;
  final double priceFontSize;
  final double buttonHeight;
  final double buttonIconSize;
  final double ratingIconSize;
  final double ratingSpacing;
  final double borderRadius;
  final double imageRadius;
  final double maxCardWidth;

  const _CardConfig({
    required this.imageSize,
    required this.padding,
    required this.horizontalSpacing,
    required this.spacing,
    required this.titleFontSize,
    required this.priceFontSize,
    required this.buttonHeight,
    required this.buttonIconSize,
    required this.ratingIconSize,
    required this.ratingSpacing,
    required this.borderRadius,
    required this.imageRadius,
    required this.maxCardWidth,
  });
}

class _AddOrStepper extends StatelessWidget {
  final Product product;
  final int qty;
  final double buttonHeight;
  final double buttonIconSize;
  final double availableWidth;
  final double screenWidth;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _AddOrStepper({
    required this.product,
    required this.qty,
    required this.buttonHeight,
    required this.buttonIconSize,
    required this.availableWidth,
    required this.screenWidth,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  /// Calculate responsive horizontal padding based on available width
  double _getButtonPadding() {
    if (availableWidth < 350) {
      return 8.0; // Ultra-small: minimal padding
    } else if (availableWidth < 450) {
      return 12.0; // Small mobile: moderate padding
    } else if (screenWidth < 600) {
      return 16.0; // Medium mobile: standard padding
    } else if (screenWidth < 1024) {
      return 20.0; // Tablet: comfortable padding
    } else {
      return 24.0; // Desktop: generous padding
    }
  }

  /// Get appropriate button label text based on available width
  String _getButtonLabel(bool isOutOfStock) {
    if (isOutOfStock) return 'Out of Stock';
    // Always use full "Add to Cart" text - overflow handled by FittedBox
    return 'Add to Cart';
  }

  /// Calculate responsive icon size based on button height and screen size
  double _getResponsiveIconSize() {
    // Use the provided buttonIconSize but ensure it scales appropriately for very small screens
    if (availableWidth < 350) {
      return buttonIconSize.clamp(14.0, 16.0);
    } else if (availableWidth < 450) {
      return buttonIconSize.clamp(16.0, 18.0);
    }
    // For larger screens, use the provided icon size as-is (it's already calculated responsively)
    return buttonIconSize;
  }

  /// Calculate responsive font size based on button height and available width
  double _getButtonFontSize() {
    // Base size on button height (adjusted for reduced button heights)
    double baseSize = buttonHeight < 40 ? 11.0 : (buttonHeight < 44 ? 12.0 : (buttonHeight < 48 ? 13.0 : 14.0));
    
    // Adjust for very small screens to prevent overflow
    if (availableWidth < 350) {
      return baseSize - 1.0;
    } else if (screenWidth >= 1024) {
      return baseSize + 1.0; // Slightly larger on desktop
    }
    
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.isOutOfStock;
    final iconButtonSize = buttonHeight.clamp(38.0, 46.0);
    final buttonPadding = _getButtonPadding();
    final buttonLabel = _getButtonLabel(isOutOfStock);
    final responsiveIconSize = _getResponsiveIconSize();
    final buttonFontSize = _getButtonFontSize();
    
    return SizedBox(
      height: buttonHeight,
      child: qty == 0
          ? SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isOutOfStock ? null : onAdd,
                icon: Icon(
                  isOutOfStock ? Icons.close : Icons.add_shopping_cart,
                  size: responsiveIconSize,
                ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    buttonLabel,
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: buttonPadding,
                    vertical: buttonHeight < 40 ? 6.0 : 7.0,
                  ),
                  minimumSize: Size(0, buttonHeight),
                  maximumSize: Size(double.infinity, buttonHeight),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            )
          : Row(
              children: [
                IconButton(
                  tooltip: 'Decrease',
                  onPressed: isOutOfStock ? null : onDecrement,
                  icon: Icon(Icons.remove, size: buttonIconSize, color: Colors.black),
                  style: IconButton.styleFrom(
                    minimumSize: Size(iconButtonSize, iconButtonSize),
                    maximumSize: Size(iconButtonSize, iconButtonSize),
                    padding: EdgeInsets.zero,
                  ),
                ),
                SizedBox(width: buttonHeight < 44 ? 8 : 12),
                Expanded(
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontSize: buttonHeight < 44 ? 14 : (buttonHeight < 48 ? 15 : 16),
                    ),
                  ),
                ),
                SizedBox(width: buttonHeight < 44 ? 8 : 12),
                IconButton(
                  tooltip: 'Increase',
                  onPressed: isOutOfStock ? null : onIncrement,
                  icon: Icon(Icons.add, size: buttonIconSize, color: Colors.black),
                  style: IconButton.styleFrom(
                    minimumSize: Size(iconButtonSize, iconButtonSize),
                    maximumSize: Size(iconButtonSize, iconButtonSize),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int count;
  final double iconSize;
  final double spacing;
  
  const _RatingRow({
    required this.rating,
    required this.count,
    required this.iconSize,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    final icons = <Widget>[];
    for (int i = 0; i < 5; i++) {
      if (i < full) {
        icons.add(Icon(Icons.star, size: iconSize, color: Colors.amber));
      } else if (i == full && half) {
        icons.add(Icon(Icons.star_half, size: iconSize, color: Colors.amber));
      } else {
        icons.add(Icon(Icons.star_border, size: iconSize, color: Colors.amber));
      }
    }
    return Row(
      children: [
        ...icons,
        SizedBox(width: spacing),
        Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: iconSize < 16 ? 11 : (iconSize < 18 ? 12 : 13),
          ),
        ),
      ],
    );
  }
}

