import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../catalog/data/product.dart';
import '../../../catalog/data/infinite_scroll_provider.dart';
import '../../../cart/application/cart_controller.dart';
import '../../../../core/layout/responsive.dart';
import 'responsive_product_card.dart';

class InfiniteScrollGrid extends ConsumerStatefulWidget {
  final String? category;
  final VoidCallback? onProductTap;
  final VoidCallback? onAddToCart;

  const InfiniteScrollGrid({
    super.key,
    this.category,
    this.onProductTap,
    this.onAddToCart,
  });

  @override
  ConsumerState<InfiniteScrollGrid> createState() => _InfiniteScrollGridState();
}

class _InfiniteScrollGridState extends ConsumerState<InfiniteScrollGrid> {
  late ScrollController _scrollController;

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
    final position = _scrollController.position;
    final infiniteState = ref.read(infiniteScrollProvider(widget.category));

    // Only load more if we're near the end, not already loading, and have more content
    if (position.pixels >= position.maxScrollExtent - 200 &&
        !infiniteState.isLoading &&
        infiniteState.hasMore) {
      ref.read(infiniteScrollProvider(widget.category).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final infiniteState = ref.watch(infiniteScrollProvider(widget.category));
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);
    final ultra = Responsive.isUltraCompact(width);
    final singleColumn = Responsive.isSingleColumnMobile(width);

    // Use the same optimized grid configuration as ProductGrid
    final gridDelegate = _buildGridDelegate(width, bp, ultra, singleColumn);

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(infiniteScrollProvider(widget.category).notifier)
            .refresh();
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Empty state
          if (infiniteState.products.isEmpty && !infiniteState.isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.category != null
                          ? 'No products in this category'
                          : 'Try refreshing to load products',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(
                              infiniteScrollProvider(widget.category).notifier,
                            )
                            .refresh();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(Responsive.getCardPadding(width)),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < infiniteState.products.length) {
                    return _ProductCard(
                      product: infiniteState.products[index],
                      onTap: widget.onProductTap,
                      onAddToCart: widget.onAddToCart,
                    );
                  }
                  return null;
                }, childCount: infiniteState.products.length),
                gridDelegate: gridDelegate,
              ),
            ),
          // Loading indicator
          if (infiniteState.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'Loading more products...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Error indicator
          if (infiniteState.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading products',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        infiniteState.error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          ref
                              .read(
                                infiniteScrollProvider(
                                  widget.category,
                                ).notifier,
                              )
                              .refresh();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
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
    if (ultra) {
      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 2.5, // Optimized for horizontal cards
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      );
    }

    switch (bp) {
      case AppBreakpoint.compact:
        return SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75, // Optimized for mobile cards
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        );
      case AppBreakpoint.medium:
        return SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          childAspectRatio: 0.8, // Optimized for tablet cards
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        );
      case AppBreakpoint.expanded:
        return SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          childAspectRatio: 0.85, // Optimized for desktop cards
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        );
    }
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const _ProductCard({required this.product, this.onTap, this.onAddToCart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    // Optimized: Calculate quantity by iterating once instead of using where().fold()
    // This is more efficient for products with multiple cart items (variants/measurements)
    int qty = 0;
    for (final item in cartState.values) {
      if (item.product.id == product.id) {
        qty += item.quantity;
      }
    }

    return ResponsiveProductCard(
      product: product,
      initialQuantity: qty,
      onAddToCart: onAddToCart,
      onTap:
          onTap ??
          () =>
              context.push('/product/${product.id}'),
    );
  }
}
