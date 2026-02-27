import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../data/product_repository_supabase.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../media_upload_widget.dart';

class AdminProductState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final String searchQuery;
  final String selectedCategory;
  final bool filterOutOfStock;
  final bool loading;
  final String? error;
  final Product? selectedProduct;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const AdminProductState({
    this.products = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.filterOutOfStock = false,
    this.loading = false,
    this.error,
    this.selectedProduct,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  AdminProductState copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    String? searchQuery,
    String? selectedCategory,
    bool? filterOutOfStock,
    bool? loading,
    String? error,
    Product? selectedProduct,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) => AdminProductState(
    products: products ?? this.products,
    filteredProducts: filteredProducts ?? this.filteredProducts,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    filterOutOfStock: filterOutOfStock ?? this.filterOutOfStock,
    loading: loading ?? this.loading,
    error: error,
    selectedProduct: selectedProduct ?? this.selectedProduct,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

class AdminProductController extends StateNotifier<AdminProductState> {
  AdminProductController(this._ref) : super(const AdminProductState()) {
    // Initialize repository
    final supabaseClient = _ref.read(supabaseClientProvider);
    _repository = ProductRepositorySupabase(supabaseClient);

    // Load products from Supabase on initialization
    _initializeTimer = Future.delayed(const Duration(milliseconds: 100), () {
      loadProducts();
    });
  }

  Future<void>? _initializeTimer;

  final Ref _ref;
  late final ProductRepositorySupabase _repository;

  Future<void> loadProducts() async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null, currentPage: 1);
    }

    try {
      // Load first page of products from Supabase using paginated method
      final products = await _repository.fetchAllProductsForAdminPaginated(
        page: 1,
        limit: 50,
      );
      final hasMore =
          products.length == 50; // If we got 50, there might be more

      if (mounted) {
        state = state.copyWith(
          products: products,
          filteredProducts: products,
          loading: false,
          currentPage: 1,
          hasMore: hasMore,
        );
        _applyFilters();
      }

      // Also update shared provider for consistency
      await _ref.read(sharedProductProvider.notifier).loadProducts();
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  Future<void> loadMoreProducts() async {
    if (state.isLoadingMore || !state.hasMore) return;

    if (mounted) {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final nextPage = state.currentPage + 1;
      final newProducts = await _repository.fetchAllProductsForAdminPaginated(
        page: nextPage,
        limit: 50,
      );

      final hasMore = newProducts.length == 50;
      final allProducts = [...state.products, ...newProducts];

      if (mounted) {
        state = state.copyWith(
          products: allProducts,
          filteredProducts: allProducts,
          currentPage: nextPage,
          hasMore: hasMore,
          isLoadingMore: false,
        );
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoadingMore: false, error: e.toString());
      }
    }
  }

  void searchProducts(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void filterByCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  void filterByOutOfStock(bool filter) {
    state = state.copyWith(filterOutOfStock: filter);
    _applyFilters();
  }

  void _applyFilters() {
    List<Product> filtered = state.products;

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered =
          filtered.where((product) {
            // Search in product name
            if (product.name.toLowerCase().contains(query)) return true;

            // Search in brand
            if (product.brand?.toLowerCase().contains(query) == true) {
              return true;
            }

            // Search in SKU
            if (product.sku?.toLowerCase().contains(query) == true) return true;

            // Search in alternative names (with trimming and empty string filtering)
            if (product.alternativeNames.any((name) {
              final trimmedName = name.trim();
              return trimmedName.isNotEmpty &&
                  trimmedName.toLowerCase().contains(query);
            })) {
              return true;
            }

            return false;
          }).toList();
    }

    // Apply category filter
    if (state.selectedCategory != 'All') {
      filtered =
          filtered.where((product) {
            return product.categories.contains(state.selectedCategory);
          }).toList();
    }

    // Apply out of stock filter
    if (state.filterOutOfStock) {
      filtered = filtered.where((product) => product.isOutOfStock).toList();
    }

    state = state.copyWith(filteredProducts: filtered);
  }

  void selectProduct(Product product) {
    state = state.copyWith(selectedProduct: product);
  }

  void clearSelection() {
    state = state.copyWith(selectedProduct: null);
  }

  Future<bool> addProduct(
    Product product, {
    List<MediaUploadResult>? selectedImages,
  }) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      // Insert product first to get the real UUID from Supabase
      // Use existing images if available, or placeholder if uploading new images
      List<String> imageUrls = [];
      if (selectedImages == null || selectedImages.isEmpty) {
        if (product.images.isNotEmpty) {
          // Use existing image URLs if no new images uploaded
          imageUrls = product.images;
        } else {
          throw Exception('At least one image is required');
        }
      }

      // Insert product into Supabase (with existing images or placeholder)
      final productData = await _repository.insertProduct(product, imageUrls);
      final productId = productData['id'] as String;

      // Upload images if provided (using the real product ID from Supabase)
      if (selectedImages != null && selectedImages.isNotEmpty) {
        imageUrls = await _repository.uploadProductImages(
          selectedImages,
          productId,
        );

        // Update product with actual image URLs
        await _repository.updateProduct(productId, product, imageUrls);
      }

      // Insert variants if any
      if (product.variants.isNotEmpty) {
        await _repository.insertProductVariants(productId, product.variants);
      }

      // Insert measurements if any
      if (product.measurement != null) {
        await _repository.insertProductMeasurement(
          productId,
          product.measurement!,
        );
      }

      // Refresh from Supabase
      await loadProducts();

      // Also update shared provider
      await _ref.read(sharedProductProvider.notifier).loadProducts();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> updateProduct(
    Product product, {
    List<MediaUploadResult>? selectedImages,
  }) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      // Upload new images if provided
      List<String>? imageUrls;
      if (selectedImages != null && selectedImages.isNotEmpty) {
        imageUrls = await _repository.uploadProductImages(
          selectedImages,
          product.id,
        );
      }

      // Update product in Supabase
      await _repository.updateProduct(product.id, product, imageUrls);

      // Update variants if any
      if (product.variants.isNotEmpty) {
        await _repository.insertProductVariants(product.id, product.variants);
      } else {
        // Delete all variants if product has no variants
        await _repository.insertProductVariants(product.id, []);
      }

      // Update measurements if any
      if (product.measurement != null) {
        await _repository.insertProductMeasurement(
          product.id,
          product.measurement!,
        );
      } else {
        // Delete measurement if product has no measurement
        // Note: This might need a separate delete method
      }

      // Refresh from Supabase
      await loadProducts();

      // Also update shared provider
      await _ref.read(sharedProductProvider.notifier).loadProducts();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      // Delete product from Supabase (soft delete: sets is_active = false)
      await _repository.deleteProduct(productId);

      // Optimistic update: Remove product from state immediately for instant UI feedback
      final updatedProducts =
          state.products.where((p) => p.id != productId).toList();
      final updatedFilteredProducts =
          state.filteredProducts.where((p) => p.id != productId).toList();

      if (mounted) {
        state = state.copyWith(
          products: updatedProducts,
          filteredProducts: updatedFilteredProducts,
          loading: false,
        );
      }

      // Refresh product list from Supabase to ensure consistency
      await loadProducts();

      // Also update shared provider for consistency
      await _ref.read(sharedProductProvider.notifier).loadProducts();

      return true;
    } catch (e) {
      final errorMessage = e.toString();
      if (kDebugMode) {
        print('Error deleting product $productId: $errorMessage');
      }
      if (mounted) {
        state = state.copyWith(
          loading: false,
          error: 'Failed to delete product: $errorMessage',
        );
      }
      return false;
    }
  }

  /// Toggle whether a product is featured.
  ///
  /// When enabling featured, this will append the product to the end of the
  /// current featured list by assigning the next available featured_position.
  Future<void> toggleFeatured(Product product, bool isFeatured) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      // Determine new position: if enabling, put at end; if disabling, 0.
      int position = 0;
      if (isFeatured) {
        final featured = state.products.where((p) => p.isFeatured).toList();
        if (featured.isNotEmpty) {
          final maxPos = featured
              .map((p) => p.featuredPosition)
              .fold<int>(0, (prev, v) => v > prev ? v : prev);
          position = maxPos + 1;
        }
      }

      final supabase = _ref.read(supabaseClientProvider);
      await supabase
          .from('products')
          .update({'is_featured': isFeatured, 'featured_position': position})
          .eq('id', product.id);

      // Reload products and shared state so all UIs see updates
      await loadProducts();
      await _ref.read(sharedProductProvider.notifier).loadProducts();

      if (mounted) {
        state = state.copyWith(loading: false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in toggleFeatured: $e');
      }
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  /// Toggle out of stock status for a product.
  ///
  /// This allows admins to mark products as unavailable (seasonal/unavailable)
  /// which makes them appear as unavailable to customers.
  Future<bool> toggleOutOfStock(String productId, bool isOutOfStock) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      // Update product in Supabase
      await _repository.toggleOutOfStockStatus(
        productId,
        isOutOfStock: isOutOfStock,
      );

      // Optimistic update: Update product in state immediately
      final updatedProducts =
          state.products.map((p) {
            if (p.id == productId) {
              return Product(
                id: p.id,
                name: p.name,
                imageUrl: p.imageUrl,
                images: p.images,
                price: p.price,
                costPrice: p.costPrice,
                tax: p.tax,
                subtitle: p.subtitle,
                brand: p.brand,
                sku: p.sku,
                createdAt: p.createdAt,
                updatedAt: DateTime.now(),
                stock: p.stock,
                description: p.description,
                tags: p.tags,
                categories: p.categories,
                variants: p.variants,
                measurement: p.measurement,
                alternativeNames: p.alternativeNames,
                isFeatured: p.isFeatured,
                featuredPosition: p.featuredPosition,
                averageRating: p.averageRating,
                ratingCount: p.ratingCount,
                isOutOfStock: isOutOfStock,
              );
            }
            return p;
          }).toList();

      final updatedFilteredProducts =
          state.filteredProducts.map((p) {
            if (p.id == productId) {
              return Product(
                id: p.id,
                name: p.name,
                imageUrl: p.imageUrl,
                images: p.images,
                price: p.price,
                costPrice: p.costPrice,
                tax: p.tax,
                subtitle: p.subtitle,
                brand: p.brand,
                sku: p.sku,
                createdAt: p.createdAt,
                updatedAt: DateTime.now(),
                stock: p.stock,
                description: p.description,
                tags: p.tags,
                categories: p.categories,
                variants: p.variants,
                measurement: p.measurement,
                alternativeNames: p.alternativeNames,
                isFeatured: p.isFeatured,
                featuredPosition: p.featuredPosition,
                averageRating: p.averageRating,
                ratingCount: p.ratingCount,
                isOutOfStock: isOutOfStock,
              );
            }
            return p;
          }).toList();

      if (mounted) {
        state = state.copyWith(
          products: updatedProducts,
          filteredProducts: updatedFilteredProducts,
          loading: false,
        );
      }

      // Refresh product list from Supabase to ensure consistency
      await loadProducts();

      // Also update shared provider for consistency
      await _ref.read(sharedProductProvider.notifier).loadProducts();

      return true;
    } catch (e, stackTrace) {
      final errorMessage = e.toString();
      if (kDebugMode) {
        print(
          'Error toggling out of stock status for $productId: $errorMessage',
        );
        print('Stack trace: $stackTrace');
      }

      // Provide more user-friendly error messages
      String userMessage = 'Failed to update out of stock status';
      if (errorMessage.contains('column') &&
          errorMessage.contains('does not exist')) {
        userMessage =
            'Database column not found. Please run the migration to add is_out_of_stock column.';
      } else if (errorMessage.contains('permission') ||
          errorMessage.contains('policy')) {
        userMessage = 'Permission denied. Please check your admin access.';
      } else {
        userMessage =
            'Failed to update: ${errorMessage.length > 100 ? "${errorMessage.substring(0, 100)}..." : errorMessage}';
      }

      if (mounted) {
        state = state.copyWith(loading: false, error: userMessage);
      }
      return false;
    }
  }

  /// Persist a new order for the featured products list.
  ///
  /// [ordered] should be the list of featured products in their new order.
  Future<void> updateFeaturedOrder(List<Product> ordered) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      final supabase = _ref.read(supabaseClientProvider);

      // Assign positions sequentially starting at 0 in Supabase
      for (var i = 0; i < ordered.length; i++) {
        final p = ordered[i];
        await supabase
            .from('products')
            .update({'is_featured': true, 'featured_position': i})
            .eq('id', p.id);
      }

      // Reload products and shared state
      await loadProducts();
      await _ref.read(sharedProductProvider.notifier).loadProducts();

      if (mounted) {
        state = state.copyWith(loading: false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateFeaturedOrder: $e');
      }
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  List<String> get categories {
    final allCategories = <String>{'All'};
    for (final product in state.products) {
      allCategories.addAll(product.categories);
    }
    return allCategories.toList()..sort();
  }

  @override
  void dispose() {
    _initializeTimer?.ignore();
    super.dispose();
  }
}

final adminProductControllerProvider =
    StateNotifierProvider<AdminProductController, AdminProductState>(
      (ref) => AdminProductController(ref),
    );
