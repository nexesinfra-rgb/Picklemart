import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/application/cart_controller.dart';
import '../layout/responsive.dart';

/// View Cart bottom sheet button that appears at the bottom edge of the screen
/// Shows a two-section bar: cart info on left, View Cart button on right
/// Only visible when cart has items
class ViewCartButton extends ConsumerWidget {
  const ViewCartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final itemCount = cartItems.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    // Don't show button if cart is empty
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.goNamed('cart'),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  _getHorizontalPadding(bp),
                  12,
                  _getHorizontalPadding(bp),
                  12 + safeAreaBottom,
                ),
                child: Row(
                  children: [
                    // Left section: Cart icon and item count
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getLeftPadding(bp),
                          vertical: _getVerticalPadding(bp),
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: Colors.black,
                              size: _getIconSize(bp),
                            ),
                            SizedBox(width: _getSpacing(bp)),
                            Flexible(
                              child: Text(
                                '$itemCount ${itemCount == 1 ? 'item' : 'items'} added',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: _getItemCountFontSize(bp),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: _getSpacing(bp)),
                    // Right section: View Cart button
                    InkWell(
                      onTap: () => context.goNamed('cart'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getButtonPadding(bp),
                          vertical: _getVerticalPadding(bp),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Cart',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: _getFontSize(bp),
                              ),
                            ),
                            SizedBox(width: _getSpacing(bp) / 2),
                            Icon(
                              Icons.arrow_forward,
                              color: primaryColor,
                              size: _getIconSize(bp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getHorizontalPadding(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 12.0;
      case AppBreakpoint.medium:
        return 16.0;
      case AppBreakpoint.expanded:
        return 20.0;
    }
  }

  double _getLeftPadding(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 12.0;
      case AppBreakpoint.medium:
        return 14.0;
      case AppBreakpoint.expanded:
        return 16.0;
    }
  }

  double _getVerticalPadding(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 10.0;
      case AppBreakpoint.medium:
        return 12.0;
      case AppBreakpoint.expanded:
        return 14.0;
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

  double _getButtonPadding(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 16.0;
      case AppBreakpoint.medium:
        return 20.0;
      case AppBreakpoint.expanded:
        return 24.0;
    }
  }

  double _getFontSize(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 15.0;
      case AppBreakpoint.medium:
        return 16.0;
      case AppBreakpoint.expanded:
        return 17.0;
    }
  }

  double _getItemCountFontSize(AppBreakpoint bp) {
    switch (bp) {
      case AppBreakpoint.compact:
        return 14.0;
      case AppBreakpoint.medium:
        return 15.0;
      case AppBreakpoint.expanded:
        return 16.0;
    }
  }
}
