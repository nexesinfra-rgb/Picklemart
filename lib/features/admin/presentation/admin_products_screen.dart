import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../application/admin_product_controller.dart';
import '../data/category_service.dart' as admin_cat;
import '../../../core/layout/responsive.dart';
import '../../../core/layout/responsive_grid.dart';
import '../../../core/ui/responsive_buttons.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../catalog/data/product.dart';
import '../../catalog/presentation/widgets/responsive_product_card.dart';
import '../../../core/router/router_helpers.dart';
import '../../../core/utils/debouncer.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _searchController = TextEditingController();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  bool _isInitialized = false;
  bool _isUpdatingUrl = false;
  bool _isLoadingFromUrl = false;
  String? _entryRoute; // Track the route we came from

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Capture entry route before any URL updates break the stack
      final state = GoRouterState.of(context);
      final previousRoute = state.uri.queryParameters['previousRoute'];

      if (previousRoute != null && previousRoute.isNotEmpty) {
        // Previous route was passed via query parameter (from bottom nav navigation)
        _entryRoute = previousRoute;
      } else if (context.canPop()) {
        // Try to get previous route from navigation history
        // Since we can't directly access it, we'll use a smart fallback
        _entryRoute = '/admin/dashboard'; // Default assumption
      } else {
        // No navigation stack - likely accessed from bottom nav or direct link
        _entryRoute = null; // Will use dashboard as fallback
      }

      // Ensure shared products are loaded (deferred to post-build to avoid provider modification errors)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(sharedProductProvider.notifier).initialize();
        }
      });

      _loadFromUrl();
      _isInitialized = true;
    } else if (!_isUpdatingUrl && !_isLoadingFromUrl) {
      // Listen for URL changes (browser back/forward, deep links)
      _syncFromUrl();
    }
  }

  void _loadFromUrl() {
    _isLoadingFromUrl = true;
    final state = GoRouterState.of(context);
    final qp = state.uri.queryParameters;
    final urlQuery = qp['q'] ?? '';
    final urlCategory = qp['category'] ?? 'All';
    final urlOutOfStock = qp['outOfStock'] == 'true';

    // Defer provider modifications until after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = ref.read(adminProductControllerProvider.notifier);
        if (urlQuery.isNotEmpty) {
          controller.searchProducts(urlQuery);
          _searchController.text = urlQuery;
        }
        if (urlCategory != 'All') {
          controller.filterByCategory(urlCategory);
        }
        if (urlOutOfStock) {
          controller.filterByOutOfStock(true);
        }
        _isLoadingFromUrl = false;
      }
    });
  }

  void _syncFromUrl() {
    // Defer provider modifications until after build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final state = GoRouterState.of(context);
        final qp = state.uri.queryParameters;
        final urlQuery = qp['q'] ?? '';
        final urlCategory = qp['category'] ?? 'All';

        final controllerState = ref.read(adminProductControllerProvider);
        final controller = ref.read(adminProductControllerProvider.notifier);

        bool needsUpdate = false;

        if (urlQuery != controllerState.searchQuery) {
          controller.searchProducts(urlQuery);
          _searchController.text = urlQuery;
          needsUpdate = true;
        }

        if (urlCategory != controllerState.selectedCategory) {
          controller.filterByCategory(urlCategory);
          needsUpdate = true;
        }
      } catch (e) {
        // Router state not available yet, ignore
      }
    });
  }

  void _updateUrl({String? query, String? category}) {
    if (_isUpdatingUrl || _isLoadingFromUrl) return;
    _isUpdatingUrl = true;

    final currentState = ref.read(adminProductControllerProvider);
    final currentQuery = query ?? currentState.searchQuery;
    final currentCategory = category ?? currentState.selectedCategory;

    final url = RouterHelpers.buildAdminProductsUrl(
      query: currentQuery.isEmpty ? null : currentQuery,
      category: currentCategory == 'All' ? null : currentCategory,
    );

    context.go(url);
    // Reset flag after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isUpdatingUrl = false;
      }
    });
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(adminProductControllerProvider);
    final sharedState = ref.watch(sharedProductProvider);
    final categoriesAsync = ref.watch(admin_cat.categoriesProvider);
    final masterCategories =
        categoriesAsync.valueOrNull?.map((c) => c.name).toList() ?? [];
    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Manage Products',
        showBackButton: true,
        onBackPressed: () {
          // Try to pop first
          if (context.canPop()) {
            context.pop();
          } else {
            // Navigation stack broken by _updateUrl() - use entry route or default to dashboard
            context.go(_entryRoute ?? '/admin/dashboard');
          }
        },
        actions: [
          ResponsiveIconButton(
            icon: const Icon(Ionicons.add_outline),
            onPressed: () => _navigateToProductForm(),
            tooltip: 'Add Product',
          ),
        ],
        body: _buildBody(
          context,
          productState,
          sharedState,
          masterCategories,
          screenSize,
          foldableBreakpoint,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminProductState productState,
    SharedProductState sharedState,
    List<String> masterCategories,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final hasProducts =
        productState.products.isNotEmpty || sharedState.products.isNotEmpty;
    // Add defensive null checks to prevent "null is not a subtype of bool" errors
    final isLoading =
        (productState.loading ?? false) || (sharedState.isLoading ?? false);
    final error = productState.error ?? sharedState.error;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildErrorState(context, error);
    }

    if (!hasProducts) {
      return _buildEmptyState(context);
    }

    final productsToShow =
        productState.products.isNotEmpty
            ? productState
            : _createFilteredStateFromShared(
              sharedState,
              productState.searchQuery,
              productState.selectedCategory,
              productState.filterOutOfStock,
            );

    return _buildResponsiveContent(
      context,
      productsToShow,
      sharedState,
      masterCategories,
      screenSize,
      foldableBreakpoint,
    );
  }

  AdminProductState _createFilteredStateFromShared(
    SharedProductState sharedState,
    String searchQuery,
    String selectedCategory,
    bool filterOutOfStock,
  ) {
    List<Product> filtered = sharedState.products;

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered =
          filtered.where((product) {
            if (product.name.toLowerCase().contains(query)) return true;
            if (product.brand?.toLowerCase().contains(query) == true) {
              return true;
            }
            if (product.subtitle?.toLowerCase().contains(query) == true) {
              return true;
            }
            if (product.alternativeNames.any(
              (name) => name.toLowerCase().contains(query),
            )) {
              return true;
            }
            if (product.categories.any(
              (category) => category.toLowerCase().contains(query),
            )) {
              return true;
            }
            return false;
          }).toList();
    }

    if (selectedCategory != 'All') {
      filtered =
          filtered.where((product) {
            return product.categories.any(
              (category) =>
                  category.toLowerCase() == selectedCategory.toLowerCase(),
            );
          }).toList();
    }

    if (filterOutOfStock) {
      filtered = filtered.where((product) => product.isOutOfStock).toList();
    }

    return AdminProductState(
      products: sharedState.products,
      filteredProducts: filtered,
      searchQuery: searchQuery,
      selectedCategory: selectedCategory,
      filterOutOfStock: filterOutOfStock,
    );
  }

  List<String> _getCategories(
    AdminProductState productState,
    SharedProductState sharedState,
    List<String> masterCategories,
  ) {
    final products =
        productState.products.isNotEmpty
            ? productState.products
            : sharedState.products;
    final allCategories = <String>{'All'};

    // Add master categories first
    allCategories.addAll(masterCategories);

    // Also include categories from products as fallback
    for (final product in products) {
      allCategories.addAll(product.categories);
    }
    return allCategories.toList()..sort();
  }

  Widget _buildResponsiveContent(
    BuildContext context,
    AdminProductState productState,
    SharedProductState sharedState,
    List<String> masterCategories,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);
    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.viewPadding.bottom;

    // Calculate responsive navigation bar height
    final isUltraCompact = width <= 288;
    final isCompact = width <= 400;
    final bottomNavHeight = isUltraCompact ? 56.0 : (isCompact ? 60.0 : 64.0);
    final totalBottomSpacing =
        bottomNavHeight + systemBottomPadding + 40; // 40px buffer

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: totalBottomSpacing),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(spacing),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Ionicons.search_outline),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Ionicons.close_outline),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(
                                      adminProductControllerProvider.notifier,
                                    )
                                    .searchProducts('');
                                _searchDebouncer.debounce(() {
                                  if (mounted && !_isLoadingFromUrl) {
                                    _updateUrl(query: '');
                                  }
                                });
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    // Update controller immediately for responsive UI
                    ref
                        .read(adminProductControllerProvider.notifier)
                        .searchProducts(value);
                    // Debounce URL update to avoid excessive navigation
                    _searchDebouncer.debounce(() {
                      if (mounted && !_isLoadingFromUrl) {
                        _updateUrl(query: value);
                      }
                    });
                  },
                ),
                SizedBox(height: spacing * 0.75),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._getCategories(
                        productState,
                        sharedState,
                        masterCategories,
                      ).map((category) {
                        final isSelected =
                            productState.selectedCategory == category;
                        return Padding(
                          padding: EdgeInsets.only(right: spacing * 0.5),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              // Defer provider modification to avoid build conflicts
                              Future.microtask(() {
                                if (mounted) {
                                  ref
                                      .read(
                                        adminProductControllerProvider.notifier,
                                      )
                                      .filterByCategory(category);
                                  // Update URL immediately for filters (no debounce needed)
                                  if (!_isLoadingFromUrl) {
                                    _updateUrl(category: category);
                                  }
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildResponsiveProductsList(
            context,
            productState,
            screenSize,
            foldableBreakpoint,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.warning_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading products',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(adminProductControllerProvider.notifier).loadProducts();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.cube_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or add a new product',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _navigateToProductForm(),
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveProductsList(
    BuildContext context,
    AdminProductState state,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final width = MediaQuery.of(context).size.width;
    final gridConfig = ResponsiveGrid.getGridConfig(width);

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(gridConfig.padding),
          gridDelegate: ResponsiveGrid.getStandardDelegate(width),
          itemCount: state.filteredProducts.length,
          itemBuilder: (context, index) {
            return _buildProductCard(
              context,
              state.filteredProducts[index],
              gridConfig.isHorizontal,
            );
          },
        ),
        if (state.hasMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: gridConfig.mainAxisSpacing),
            child:
                state.isLoadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(adminProductControllerProvider.notifier)
                            .loadMoreProducts();
                      },
                      icon: const Icon(Ionicons.refresh_outline),
                      label: const Text('Load More'),
                    ),
          ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product product, bool isList) {
    return ResponsiveProductCard(
      product: product,
      context: ProductCardContext.grid,
      showWishlist: false,
      onTap:
          () => context.pushNamed(
            'admin-product-detail',
            pathParameters: {'id': product.id},
          ),
      actionButtonBuilder: (context, height, isUltraCompact) {
        return SizedBox(
          height: height,
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _navigateToProductForm(product),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Ionicons.create_outline, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _showDeleteDialog(product),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(
                    Ionicons.trash_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      trailing: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 20,
        splashRadius: 20,
        onSelected: (value) => _handleProductAction(value, product),
        itemBuilder:
            (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Ionicons.create_outline, size: 16),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Ionicons.copy_outline, size: 16),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Ionicons.trash_outline, size: 16),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
        child: const Icon(Ionicons.ellipsis_vertical_outline, size: 20),
      ),
    );
  }

  void _navigateToProductForm([Product? product]) {
    context.pushNamed('admin-product-form', extra: product);
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _navigateToProductForm(product);
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate functionality coming soon')),
        );
        break;
      case 'delete':
        _showDeleteDialog(product);
        break;
    }
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text('Are you sure you want to delete "${product.name}"?'),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  final controller = ref.read(
                    adminProductControllerProvider.notifier,
                  );
                  final success = await controller.deleteProduct(product.id);

                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // Show error message from controller state
                      final errorState = ref.read(
                        adminProductControllerProvider,
                      );
                      final errorMessage =
                          errorState.error ?? 'Failed to delete product';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
