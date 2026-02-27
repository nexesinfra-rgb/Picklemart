import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/layout/responsive.dart';
import '../../../catalog/data/product.dart';
import '../../../admin/data/admin_features.dart';
import '../../../catalog/presentation/widgets/responsive_product_card.dart';

class ProductCarousel extends ConsumerWidget {
  final List<Product> items;
  const ProductCarousel({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(adminFeaturesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = Responsive.breakpointForWidth(constraints.maxWidth);
        // Use a flexible height based on content instead of fixed height
        final height = _getCarouselHeight(bp, constraints.maxWidth);

        return SizedBox(
          height: height,
          child:
              features.infinityScrollProductsEnabled
                  ? _InfiniteProductCarousel(
                    items: items,
                    maxWidth: _itemMaxWidthForTwoPointFive(constraints.maxWidth),
                  )
                  : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder:
                        (context, i) => SizedBox(
                          width: _itemMaxWidthForTwoPointFive(
                            constraints.maxWidth,
                          ),
                          child: ResponsiveProductCard(
                            product: items[i],
                            context: ProductCardContext.homepage,
                          ),
                        ),
                  ),
        );
      },
    );
  }

  double _getCarouselHeight(AppBreakpoint bp, double width) {
    // Height tuned for 3:4 thumbnails + content + button
    switch (bp) {
      case AppBreakpoint.expanded:
        return 420; // Taller for desktop with proper spacing
      case AppBreakpoint.medium:
        return 380; // Medium height for tablets
      case AppBreakpoint.compact:
        return 350; // Compact but not cramped for mobile
    }
  }

  // Force approximately 2.5 cards visible: item width = (viewport - totalGaps)/2.5
  double _itemMaxWidthForTwoPointFive(double viewportWidth) {
    const gap = 12.0; // matches separator
    final visible = 2.5;
    // We want some horizontal padding too: use Responsive.getResponsivePadding
    final horizontalPadding = Responsive.getResponsivePadding(viewportWidth)
        .horizontal;
    final innerWidth = viewportWidth - horizontalPadding;
    // If 2.5 items are visible, there are roughly 2 gaps fully + partial; approximate 2 gaps
    final totalGaps = gap * 2;
    final usable = innerWidth - totalGaps;
    
    // Ensure minimum width for readability and maximum for desktop
    final calculatedWidth = usable / visible;
    final bp = Responsive.breakpointForWidth(viewportWidth);
    
    // Adjust based on breakpoint to prevent clipping
    switch (bp) {
      case AppBreakpoint.expanded:
        return math.min(calculatedWidth, 280); // Cap desktop width
      case AppBreakpoint.medium:
        return math.min(calculatedWidth, 260); // Cap tablet width
      case AppBreakpoint.compact:
        return math.max(calculatedWidth, 140); // Ensure mobile minimum
    }
  }
}

class _InfiniteProductCarousel extends StatefulWidget {
  final List<Product> items;
  final double maxWidth;

  const _InfiniteProductCarousel({required this.items, required this.maxWidth});

  @override
  State<_InfiniteProductCarousel> createState() =>
      _InfiniteProductCarouselState();
}

class _InfiniteProductCarouselState extends State<_InfiniteProductCarousel> {
  late ScrollController _scrollController;
  static const int _largeItemCount = 999999; // Large number for "infinite" effect

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.items.isEmpty) return;
    
    final position = _scrollController.position;
    // Calculate item width (approximate based on maxWidth + separator)
    final estimatedItemWidth = widget.maxWidth + 12; // maxWidth + separator width
    final itemsPerScreen = (position.viewportDimension / estimatedItemWidth).ceil();
    
    // When scrolled far enough (near the "end"), reset to middle section
    // This creates the illusion of infinite scroll without pre-replicating items
    if (position.pixels >= position.maxScrollExtent * 0.8) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // Jump to middle section to maintain infinite feel
          final jumpPosition = position.maxScrollExtent * 0.4;
          _scrollController.jumpTo(jumpPosition);
        }
      });
    } else if (position.pixels <= position.minScrollExtent + 100) {
      // When scrolled near the beginning, jump to middle section
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final jumpPosition = position.maxScrollExtent * 0.4;
          _scrollController.jumpTo(jumpPosition);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use ListView.builder with modulo logic for infinite scroll
    // This avoids pre-replicating items in memory - only builds visible items
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: _largeItemCount,
      itemBuilder: (context, index) {
        // Use modulo to cycle through items - creates infinite effect
        final actualIndex = index % widget.items.length;
        final product = widget.items[actualIndex];
        
        return Padding(
          padding: EdgeInsets.only(
            right: index < _largeItemCount - 1 ? 12 : 0, // Separator except last item
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: ResponsiveProductCard(
              product: product,
              context: ProductCardContext.homepage,
            ),
          ),
        );
      },
    );
  }
}
