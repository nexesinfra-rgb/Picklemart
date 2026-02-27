import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product.dart';
import 'product_repository.dart';
import 'sort_option.dart';
import '../../admin/data/category_service.dart';
import '../../admin/domain/category.dart';

/// Shared product state that both admin and user panels can use
class SharedProductState {
  final List<Product> products;
  final bool isLoading;
  final String? error;

  const SharedProductState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  SharedProductState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
  }) {
    return SharedProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Shared product notifier that manages the global product state
class SharedProductNotifier extends StateNotifier<SharedProductState> {
  final ProductRepository _repository;
  bool _hasLoaded = false;

  SharedProductNotifier(this._repository) : super(const SharedProductState()) {
    // Lazy loading: products are loaded when first accessed via providers
    // This prevents loading all products on app startup
  }

  Future<void> loadProducts() async {
    try {
      // Check if already loaded - use explicit check to avoid null issues
      final currentLoadState = _hasLoaded;
      if (currentLoadState == true) {
        final products = state.products;
        if (products.isNotEmpty) {
          // Already loaded, skip
          return;
        }
      }

      state = state.copyWith(isLoading: true, error: null);
      final products = await _repository.fetchAll();
      _hasLoaded = true;
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Initialize products loading (for lazy loading support)
  /// Uses Future.microtask to defer loading until after the build phase
  void initialize() {
    if (!_hasLoaded) {
      Future.microtask(() {
        loadProducts();
      });
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      // Optimistic update: Add product to list immediately
      // Product is already created in database by the time this is called
      final currentProducts = List<Product>.from(state.products);
      // Check if product already exists (shouldn't happen, but safe check)
      final existingIndex = currentProducts.indexWhere(
        (p) => p.id == product.id,
      );
      if (existingIndex >= 0) {
        // Product exists, replace it
        currentProducts[existingIndex] = product;
      } else {
        // Add new product at the beginning (most recent first)
        currentProducts.insert(0, product);
      }
      state = state.copyWith(products: currentProducts, error: null);
      _hasLoaded = true; // Mark as loaded since we have products now
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // On error, fall back to full reload
      await loadProducts();
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      // Optimistic update: Update product in list immediately
      // Product is already updated in database by the time this is called
      final currentProducts = List<Product>.from(state.products);
      final index = currentProducts.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        currentProducts[index] = product;
        state = state.copyWith(products: currentProducts, error: null);
      } else {
        // Product not found in list, add it (might be a new product)
        currentProducts.insert(0, product);
        state = state.copyWith(products: currentProducts, error: null);
        _hasLoaded = true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // On error, fall back to full reload
      await loadProducts();
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      // Optimistic update: Remove product from list immediately
      // Product is already deleted (or marked inactive) in database by the time this is called
      final currentProducts =
          state.products.where((p) => p.id != productId).toList();
      state = state.copyWith(products: currentProducts, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // On error, fall back to full reload
      await loadProducts();
    }
  }

  void refresh() {
    loadProducts();
  }
}

/// Shared product provider that both admin and user panels can watch
final sharedProductProvider =
    StateNotifierProvider<SharedProductNotifier, SharedProductState>((ref) {
      final repository = ref.watch(productRepositoryProvider);
      return SharedProductNotifier(repository);
    });

/// Convenience providers for different use cases
final allProductsProvider = Provider<List<Product>>((ref) {
  // Trigger lazy loading when products are first accessed (deferred to post-build)
  final notifier = ref.read(sharedProductProvider.notifier);
  Future.microtask(() {
    notifier.initialize();
  });
  return ref.watch(sharedProductProvider).products;
});

final featuredProductsProvider = Provider<List<Product>>((ref) {
  // Trigger lazy loading when products are first accessed (deferred to post-build)
  final notifier = ref.read(sharedProductProvider.notifier);
  Future.microtask(() {
    notifier.initialize();
  });
  final products = ref.watch(sharedProductProvider).products;
  // Prefer explicit featured flag when available.
  final featured =
      products.where((p) => p.isFeatured).toList()
        ..sort((a, b) => a.featuredPosition.compareTo(b.featuredPosition));

  if (featured.isNotEmpty) {
    return featured;
  }

  // Fallback: first few active products if none are marked as featured yet.
  return products.take(6).toList();
});

final categoriesProvider = Provider<List<String>>((ref) {
  // Trigger lazy loading when products are first accessed (deferred to post-build)
  final notifier = ref.read(sharedProductProvider.notifier);
  Future.microtask(() {
    notifier.initialize();
  });
  final products = ref.watch(sharedProductProvider).products;
  final set = <String>{};
  for (final p in products) {
    set.addAll(p.categories);
  }
  final list = set.toList()..sort();
  return list;
});

/// Helper function to get sort priority for categories
/// Returns a numeric priority where lower numbers appear first
/// Categories not in the list get priority 999 (appear last)
int getCategorySortPriority(String categoryName) {
  final normalized = categoryName.trim().toUpperCase();

  // Exact order as specified by client:
  // 1. VEG PICKLES
  // 2. NON- VEG PICKLES
  // 3. KARAPODULU
  // 4. VADIYALU
  // 5. SNACKS
  if (normalized.contains('VEG PICKLE') && !normalized.contains('NON')) {
    return 1; // VEG PICKLES
  }
  if (normalized.contains('NON') &&
      normalized.contains('VEG') &&
      normalized.contains('PICKLE')) {
    return 2; // NON- VEG PICKLES or NON-VEG PICKLES
  }
  if (normalized.contains('KARAPODULU')) {
    return 3; // KARAPODULU
  }
  if (normalized.contains('VADIYALU')) {
    return 4; // VADIYALU
  }
  if (normalized.contains('SNACK')) {
    return 5; // SNACKS
  }

  // All other categories appear after the specified ones
  return 999;
}

/// Provider for categories from database with image URLs
/// Fetches Category objects from Supabase that include image_url fields
final databaseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final categoryService = ref.watch(categoryServiceProvider);
  final allCategories = await categoryService.getAllCategories();

  // Filter to only active categories and sort by custom priority, then sort_order, then name
  final activeCategories =
      allCategories.where((category) => category.isActive).toList()
        ..sort((a, b) {
          // First sort by custom priority
          final priorityA = getCategorySortPriority(a.name);
          final priorityB = getCategorySortPriority(b.name);
          final priorityComparison = priorityA.compareTo(priorityB);
          if (priorityComparison != 0) return priorityComparison;

          // Then sort by sort_order
          final sortOrderComparison = a.sortOrder.compareTo(b.sortOrder);
          if (sortOrderComparison != 0) return sortOrderComparison;

          // Finally sort alphabetically by name
          return a.name.compareTo(b.name);
        });

  return activeCategories;
});

final brandsProvider = Provider<List<String>>((ref) {
  // Trigger lazy loading when products are first accessed (deferred to post-build)
  final notifier = ref.read(sharedProductProvider.notifier);
  Future.microtask(() {
    notifier.initialize();
  });
  final products = ref.watch(sharedProductProvider).products;
  final set = <String>{};
  for (final p in products) {
    if (p.brand != null && p.brand!.trim().isNotEmpty) {
      set.add(p.brand!.trim());
    }
  }
  final list = set.toList()..sort();
  return list;
});

/// Provider for products by category
final productsByCategoryProvider = Provider.family<List<Product>, String>((
  ref,
  category,
) {
  // Trigger lazy loading when products are first accessed (deferred to post-build)
  final notifier = ref.read(sharedProductProvider.notifier);
  Future.microtask(() {
    notifier.initialize();
  });
  final products = ref.watch(sharedProductProvider).products;
  return products
      .where(
        (p) =>
            p.categories.any((c) => c.toLowerCase() == category.toLowerCase()),
      )
      .toList();
});

/// Provider for search results
final searchProductsProvider = Provider.family<List<Product>, String>((
  ref,
  query,
) {
  // Trigger lazy loading when products are first accessed (deferred to post-build)
  final notifier = ref.read(sharedProductProvider.notifier);
  Future.microtask(() {
    notifier.initialize();
  });
  final products = ref.watch(sharedProductProvider).products;

  // Trim and normalize the query
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) return products;

  final q = trimmedQuery.toLowerCase();
  return products.where((product) {
    // Search in product name
    if (product.name.toLowerCase().contains(q)) return true;

    // Search in subtitle
    if (product.subtitle != null &&
        product.subtitle!.toLowerCase().contains(q)) {
      return true;
    }

    // Search in brand (handle null and empty strings)
    if (product.brand != null &&
        product.brand!.trim().isNotEmpty &&
        product.brand!.toLowerCase().contains(q)) {
      return true;
    }

    // Search in alternative names
    // Filter out empty/null names, trim whitespace, and check for matches
    if (product.alternativeNames.any((name) {
      final trimmedName = name.trim();
      return trimmedName.isNotEmpty && trimmedName.toLowerCase().contains(q);
    })) {
      return true;
    }

    // Search in tags
    if (product.tags.isNotEmpty &&
        product.tags.any((tag) => tag.toLowerCase().contains(q))) {
      return true;
    }

    // Search in categories
    if (product.categories.isNotEmpty &&
        product.categories.any(
          (category) => category.toLowerCase().contains(q),
        )) {
      return true;
    }

    return false;
  }).toList();
});

/// Filter parameters for search
class SearchFilters {
  final String query;
  final SortOption sort;
  final double? minPrice;
  final double? maxPrice;
  final List<String> categories;
  final List<String> brands;
  final bool inStockOnly;
  final double? minRating;

  const SearchFilters({
    required this.query,
    this.sort = SortOption.relevance,
    this.minPrice,
    this.maxPrice,
    this.categories = const [],
    this.brands = const [],
    this.inStockOnly = false,
    this.minRating,
  });
}

/// Provider for filtered search results
final filteredSearchProductsProvider = Provider.family<
  List<Product>,
  SearchFilters
>((ref, filters) {
  // Get base search results
  final searchResults = ref.watch(searchProductsProvider(filters.query));

  // Apply filters
  var filtered = List<Product>.from(searchResults);

  // Filter by price range
  if (filters.minPrice != null || filters.maxPrice != null) {
    filtered =
        filtered.where((product) {
          // Check base price
          final price = product.price;
          if (filters.minPrice != null && price < filters.minPrice!) {
            return false;
          }
          if (filters.maxPrice != null && price > filters.maxPrice!) {
            return false;
          }

          // Also check variant prices if they exist
          if (product.variants.isNotEmpty) {
            final variantPrices = product.variants.map((v) => v.price).toList();
            final minVariantPrice = variantPrices.reduce(
              (a, b) => a < b ? a : b,
            );
            final maxVariantPrice = variantPrices.reduce(
              (a, b) => a > b ? a : b,
            );

            // Product matches if any variant price is in range
            final hasMatchingVariant =
                (filters.minPrice == null ||
                    maxVariantPrice >= filters.minPrice!) &&
                (filters.maxPrice == null ||
                    minVariantPrice <= filters.maxPrice!);

            // If base price is out of range, check if any variant is in range
            if ((filters.minPrice != null && price < filters.minPrice!) ||
                (filters.maxPrice != null && price > filters.maxPrice!)) {
              return hasMatchingVariant;
            }
          }

          return true;
        }).toList();
  }

  // Filter by categories
  if (filters.categories.isNotEmpty) {
    filtered =
        filtered.where((product) {
          return product.categories.any(
            (category) => filters.categories.any(
              (filterCategory) =>
                  category.toLowerCase() == filterCategory.toLowerCase(),
            ),
          );
        }).toList();
  }

  // Filter by brands
  if (filters.brands.isNotEmpty) {
    filtered =
        filtered.where((product) {
          if (product.brand == null || product.brand!.trim().isEmpty) {
            return false;
          }
          return filters.brands.any(
            (brand) =>
                product.brand!.trim().toLowerCase() == brand.toLowerCase(),
          );
        }).toList();
  }

  // Filter by out of stock status (check isOutOfStock flag instead of stock count)
  if (filters.inStockOnly) {
    filtered =
        filtered.where((product) {
          // Show all products except those marked as out of stock by admin
          return !product.isOutOfStock;
        }).toList();
  }

  // Filter by rating
  if (filters.minRating != null) {
    filtered =
        filtered.where((product) {
          if (product.averageRating == null) return false;
          return product.averageRating! >= filters.minRating!;
        }).toList();
  }

  // Apply sorting
  switch (filters.sort) {
    case SortOption.priceLowHigh:
      filtered.sort((a, b) => a.price.compareTo(b.price));
      break;
    case SortOption.priceHighLow:
      filtered.sort((a, b) => b.price.compareTo(a.price));
      break;
    case SortOption.ratingHighLow:
      filtered.sort((a, b) {
        final aRating = a.averageRating ?? 0.0;
        final bRating = b.averageRating ?? 0.0;
        return bRating.compareTo(aRating);
      });
      break;
    case SortOption.relevance:
      // Keep original order from search
      break;
  }

  return filtered;
});

/// Provider for suggested products based on shared categories
/// Returns all products from the same categories (excluding the current product)
final suggestedProductsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  productId,
) async {
  final allProducts = ref.watch(allProductsProvider);
  final repository = ref.read(productRepositoryProvider);

  // Fetch the current product to get its categories
  final currentProduct = await repository.fetchById(productId);

  if (currentProduct == null || currentProduct.categories.isEmpty) {
    return [];
  }

  // Filter products that share at least one category with the current product
  // Exclude the current product itself
  final suggested =
      allProducts.where((product) {
        // Exclude the current product
        if (product.id == productId) return false;

        // Check if product shares at least one category
        return product.categories.any(
          (category) => currentProduct.categories.any(
            (currentCategory) =>
                category.toLowerCase() == currentCategory.toLowerCase(),
          ),
        );
      }).toList();

  // Return all matching products for pagination
  return suggested;
});

/// Provider for paginated suggested products
/// Returns 12 products per page
final paginatedSuggestedProductsProvider = Provider.family<
  ({
    List<Product> products,
    int currentPage,
    int totalPages,
    int totalProducts,
  }),
  ({String productId, int page})
>((ref, params) {
  final allSuggestedAsync = ref.watch(
    suggestedProductsProvider(params.productId),
  );

  return allSuggestedAsync.when(
    data: (allProducts) {
      const pageSize = 12;
      final totalProducts = allProducts.length;
      final totalPages =
          totalProducts > 0 ? ((totalProducts - 1) ~/ pageSize) + 1 : 1;
      final currentPage = params.page.clamp(1, totalPages);

      final startIndex = (currentPage - 1) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, totalProducts);
      final paginatedProducts = allProducts.sublist(startIndex, endIndex);

      return (
        products: paginatedProducts,
        currentPage: currentPage,
        totalPages: totalPages,
        totalProducts: totalProducts,
      );
    },
    loading:
        () => (
          products: <Product>[],
          currentPage: 1,
          totalPages: 1,
          totalProducts: 0,
        ),
    error:
        (_, __) => (
          products: <Product>[],
          currentPage: 1,
          totalPages: 1,
          totalProducts: 0,
        ),
  );
});

/// Provider for similar products based on tags (primary) or brand (fallback)
/// Returns all products with matching tags or brand (excluding the current product)
final similarProductsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  productId,
) async {
  final allProducts = ref.watch(allProductsProvider);
  final repository = ref.read(productRepositoryProvider);

  // Fetch the current product to get its tags and brand
  final currentProduct = await repository.fetchById(productId);

  if (currentProduct == null) {
    return [];
  }

  // Filter products that match by tags (primary) or brand (fallback)
  // Exclude the current product itself
  final similar =
      allProducts.where((product) {
        // Exclude the current product
        if (product.id == productId) return false;

        // Primary: Check if product shares at least one tag
        if (currentProduct.tags.isNotEmpty && product.tags.isNotEmpty) {
          final hasMatchingTag = product.tags.any(
            (tag) => currentProduct.tags.any(
              (currentTag) => tag.toLowerCase() == currentTag.toLowerCase(),
            ),
          );
          if (hasMatchingTag) return true;
        }

        // Fallback: Check if product has the same brand
        if (currentProduct.brand != null &&
            currentProduct.brand!.trim().isNotEmpty &&
            product.brand != null &&
            product.brand!.trim().isNotEmpty) {
          if (currentProduct.brand!.toLowerCase() ==
              product.brand!.toLowerCase()) {
            return true;
          }
        }

        return false;
      }).toList();

  // Return all matching products for pagination
  return similar;
});

/// Provider for paginated similar products
/// Returns 12 products per page
final paginatedSimilarProductsProvider = Provider.family<
  ({
    List<Product> products,
    int currentPage,
    int totalPages,
    int totalProducts,
  }),
  ({String productId, int page})
>((ref, params) {
  final allSimilarAsync = ref.watch(similarProductsProvider(params.productId));

  return allSimilarAsync.when(
    data: (allProducts) {
      const pageSize = 12;
      final totalProducts = allProducts.length;
      final totalPages =
          totalProducts > 0 ? ((totalProducts - 1) ~/ pageSize) + 1 : 1;
      final currentPage = params.page.clamp(1, totalPages);

      final startIndex = (currentPage - 1) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, totalProducts);
      final paginatedProducts = allProducts.sublist(startIndex, endIndex);

      return (
        products: paginatedProducts,
        currentPage: currentPage,
        totalPages: totalPages,
        totalProducts: totalProducts,
      );
    },
    loading:
        () => (
          products: <Product>[],
          currentPage: 1,
          totalPages: 1,
          totalProducts: 0,
        ),
    error:
        (_, __) => (
          products: <Product>[],
          currentPage: 1,
          totalPages: 1,
          totalProducts: 0,
        ),
  );
});
