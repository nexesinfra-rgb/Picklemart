import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../catalog/data/infinite_scroll_provider.dart';
import 'responsive_product_grid.dart';

class InfiniteScrollGridNew extends ConsumerStatefulWidget {
  final String? category;
  final VoidCallback? onProductTap;
  final VoidCallback? onAddToCart;

  const InfiniteScrollGridNew({
    super.key,
    this.category,
    this.onProductTap,
    this.onAddToCart,
  });

  @override
  ConsumerState<InfiniteScrollGridNew> createState() =>
      _InfiniteScrollGridNewState();
}

class _InfiniteScrollGridNewState extends ConsumerState<InfiniteScrollGridNew> {
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
    final screenWidth = MediaQuery.of(context).size.width;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(infiniteScrollProvider(widget.category).notifier)
            .refresh();
      },
      child: CustomScrollView(
        controller: _scrollController,
        cacheExtent: 500, // Cache 500px of off-screen items for smoother scrolling
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
                    ),
                  ],
                ),
              ),
            ),
          // Products grid
          if (infiniteState.products.isNotEmpty)
            SliverToBoxAdapter(
              child: ResponsiveProductGrid(
                products: infiniteState.products,
                category: widget.category,
                useMasonryLayout: true,
                shrinkWrap: true,
              ),
            ),
          // Loading indicator
          if (infiniteState.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          // End of list indicator
          if (!infiniteState.hasMore && infiniteState.products.isNotEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No more products',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
