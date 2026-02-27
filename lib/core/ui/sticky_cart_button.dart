import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/application/cart_controller.dart';
import '../layout/responsive.dart';

/// Sticky cart button that appears above the bottom navigation bar
/// Shows cart item count and provides quick access to cart
/// Only visible when cart has items
class StickyCartButton extends ConsumerWidget {
  const StickyCartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final itemCount =
        cartItems.values.map((item) => item.product.id).toSet().length;
    print('StickyCartButton:Cart items:${cartItems.length}');
    // Don't show button if cart is empty
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);

    // Calculate total
    final total = ref.read(cartProvider.notifier).total;

    return Container(
      margin: _getMargin(bp, width),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.3),
        child: InkWell(
          onTap: () => context.goNamed('cart'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: _getPadding(bp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Item count
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: Colors.black,
                    size: _getIconSize(bp),
                  ),
                ),
                SizedBox(width: _getSpacing(bp)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$itemCount ${itemCount == 1 ? 'product' : 'products'}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: _getTitleFontSize(bp),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (bp != AppBreakpoint.compact)
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: _getSubtitleFontSize(bp),
                          ),
                          overflow: TextOverflow.ellipsis,
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
  }

  EdgeInsets _getMargin(AppBreakpoint bp, double width) {
    switch (bp) {
      case AppBreakpoint.compact:
        // Mobile: smaller margins, positioning handled by parent Positioned widget
        return const EdgeInsets.fromLTRB(12, 0, 12, 8);
      case AppBreakpoint.medium:
        // Tablet: medium margins with more bottom space
        return const EdgeInsets.fromLTRB(16, 0, 16, 12);
      case AppBreakpoint.expanded:
        // Desktop: center with max width and consistent bottom spacing
        final horizontalMargin = (width - 800) / 2;
        return EdgeInsets.fromLTRB(
          horizontalMargin.clamp(24, double.infinity),
          0,
          horizontalMargin.clamp(24, double.infinity),
          16,
        );
    }
  }

  EdgeInsets _getPadding(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
      case AppBreakpoint.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
      case AppBreakpoint.expanded:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }

  double _getSpacing(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 8.0;
      case AppBreakpoint.medium:
        return 12.0;
      case AppBreakpoint.expanded:
        return 16.0;
    }
  }

  double _getIconSize(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 20.0;
      case AppBreakpoint.medium:
        return 22.0;
      case AppBreakpoint.expanded:
        return 24.0;
    }
  }

  double _getTitleFontSize(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 14.0;
      case AppBreakpoint.medium:
        return 15.0;
      case AppBreakpoint.expanded:
        return 16.0;
    }
  }

  double _getSubtitleFontSize(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 12.0;
      case AppBreakpoint.medium:
        return 13.0;
      case AppBreakpoint.expanded:
        return 14.0;
    }
  }
}

/// Calculates the proper bottom offset for positioning the sticky cart button
/// above the bottom navigation bar.
///
/// Accounts for:
/// - Safe area bottom padding
/// - NavigationBar height (64px as defined in app theme)
/// - Gap between button and nav bar (16px)
///
/// Returns the calculated bottom offset for use in Positioned widgets.
/// The Positioned widget positions from the bottom, so we need:
/// safeAreaBottom + navigationBarHeight + gap
double getStickyCartButtonBottomOffset(BuildContext context) {
  final safeAreaBottom = MediaQuery.of(context).padding.bottom;
  // NavigationBar height: 64px (as defined in app_theme.dart)
  // Gap between button bottom and nav bar top: 16px
  // Formula: safeAreaBottom + navigationBarHeight + gap
  // NavigationBar is positioned from screen bottom, not SafeArea bottom
  return safeAreaBottom + 64 + 16;
}
