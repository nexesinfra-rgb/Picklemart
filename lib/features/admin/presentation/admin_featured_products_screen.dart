import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../application/admin_product_controller.dart';
import '../../catalog/data/product.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';

class AdminFeaturedProductsScreen extends ConsumerStatefulWidget {
  const AdminFeaturedProductsScreen({super.key});

  @override
  ConsumerState<AdminFeaturedProductsScreen> createState() =>
      _AdminFeaturedProductsScreenState();
}

class _AdminFeaturedProductsScreenState
    extends ConsumerState<AdminFeaturedProductsScreen> {
  late List<Product> _featuredOrder;
  String? _entryRoute; // Track the route we came from

  @override
  void initState() {
    super.initState();
    final state = ref.read(adminProductControllerProvider);
    _featuredOrder = _extractFeatured(state.products);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture entry route before any URL updates break the stack
    if (_entryRoute == null) {
      final routerState = GoRouterState.of(context);
      final previousRoute = routerState.uri.queryParameters['previousRoute'];
      
      if (previousRoute != null && previousRoute.isNotEmpty) {
        // Previous route was passed via query parameter (from More screen)
        _entryRoute = previousRoute;
      } else if (context.canPop()) {
        // Try to get previous route from navigation history
        // Since we can't directly access it, we'll use a smart fallback
        _entryRoute = '/admin/dashboard'; // Default assumption
      } else {
        // No navigation stack - likely accessed from bottom nav or direct link
        _entryRoute = null; // Will use dashboard as fallback
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProductControllerProvider);
    final controller = ref.read(adminProductControllerProvider.notifier);

    final featured = _extractFeatured(state.products);
    _syncLocalOrderWith(featured);

    final nonFeatured = state.products
        .where((p) => !p.isFeatured)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Featured Products',
        showBackButton: true,
        onBackPressed: () {
          // Try to pop first
          if (context.canPop()) {
            context.pop();
          } else {
            // Navigation stack broken - use entry route or default to dashboard
            context.go(_entryRoute ?? '/admin/dashboard');
          }
        },
        body: state.loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;

                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drag to reorder featured products. '
                        'Use the star icon in the list below to add or remove products '
                        'from the featured list.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                      if (isWide)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildFeaturedCard(
                                  context,
                                  controller,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAllProductsCard(
                                  context,
                                  controller,
                                  nonFeatured,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildFeaturedCard(
                                  context,
                                  controller,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: _buildAllProductsCard(
                                  context,
                                  controller,
                                  nonFeatured,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: content,
                  );
                },
              ),
      ),
    );
  }

  // === Helper widgets ===

  Widget _buildFeaturedCard(
    BuildContext context,
    AdminProductController controller,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Ionicons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Featured (${_featuredOrder.length})',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Ionicons.refresh_outline),
                  tooltip: 'Reload products',
                  onPressed: () => controller.loadProducts(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'These products appear in the Home “Featured Products” section. '
              'Drag the handle to change their order.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _featuredOrder.isEmpty
                  ? Center(
        child: Text(
                        'No featured products yet.\n'
                        'Tap the star in “All Products” to feature an item.',
          textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: _featuredOrder.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _featuredOrder.removeAt(oldIndex);
                          _featuredOrder.insert(newIndex, item);
                        });
                        controller.updateFeaturedOrder(_featuredOrder);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Featured order updated'),
                            duration: Duration(milliseconds: 800),
                          ),
                        );
      },
      itemBuilder: (context, index) {
                        final product = _featuredOrder[index];
        return Card(
          key: ValueKey(product.id),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
            leading: CircleAvatar(
                              radius: 18,
              backgroundImage: NetworkImage(product.imageUrl),
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                            title: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  '₹${product.finalPrice.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Stock: ${product.stock}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: product.stock > 0
                                        ? Colors.green
                                        : theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Ionicons.star,
                                    color: Colors.amber,
                                  ),
                                  tooltip: 'Remove from featured',
                                  onPressed: () {
                                    controller.toggleFeatured(product, false);
                                  },
                                ),
                                const Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllProductsCard(
    BuildContext context,
    AdminProductController controller,
    List<Product> nonFeatured,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Ionicons.cube_outline, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'All Products',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the star to feature a product. Featured items will appear '
              'in the list above and on the Home screen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: nonFeatured.isEmpty
                  ? const Center(child: Text('No products available'))
                  : ListView.builder(
                      itemCount: nonFeatured.length,
                      itemBuilder: (context, index) {
                        final product = nonFeatured[index];
                        final isFeatured = product.isFeatured;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(product.imageUrl),
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                            title: Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  '₹${product.finalPrice.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Stock: ${product.stock}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: product.stock > 0
                                        ? Colors.green
                                        : theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isFeatured
                                    ? Ionicons.star
                                    : Ionicons.star_outline,
                                color: isFeatured ? Colors.amber : null,
                              ),
                              tooltip: isFeatured
                                  ? 'Remove from featured'
                                  : 'Add to featured',
                              onPressed: () {
                                controller.toggleFeatured(
                                  product,
                                  !isFeatured,
                                );
                              },
            ),
          ),
        );
      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // === Helpers for state management ===

  List<Product> _extractFeatured(List<Product> products) {
    final featured =
        products.where((p) => p.isFeatured).toList()
          ..sort(
            (a, b) =>
                a.featuredPosition.compareTo(b.featuredPosition),
          );
    return featured;
  }

  void _syncLocalOrderWith(List<Product> featured) {
    // If the underlying featured list changed (e.g., after reload), sync
    if (featured.length != _featuredOrder.length ||
        !_sameIds(featured, _featuredOrder)) {
      _featuredOrder = List<Product>.from(featured);
    }
  }

  bool _sameIds(List<Product> a, List<Product> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}
