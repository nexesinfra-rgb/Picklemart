import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../../catalog/data/product.dart';
import '../data/wishlist_repository.dart';

class WishlistState {
  final List<Product> products;
  final Set<String> productIds;
  final bool loading;
  final String? error;

  const WishlistState({
    this.products = const [],
    this.productIds = const {},
    this.loading = false,
    this.error,
  });

  WishlistState copyWith({
    List<Product>? products,
    Set<String>? productIds,
    bool? loading,
    String? error,
  }) {
    return WishlistState(
      products: products ?? this.products,
      productIds: productIds ?? this.productIds,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class WishlistController extends StateNotifier<WishlistState> {
  final Ref _ref;
  final WishlistRepository _repository;
  StreamSubscription<List<String>>? _wishlistSubscription;
  bool _isLoading = false;
  bool _hasLoaded = false;
  Timer? _debounceTimer;

  WishlistController(this._ref, this._repository)
      : super(const WishlistState()) {
    _initialize();
  }

  /// Initialize wishlist controller
  Future<void> _initialize() async {
    // Listen to auth state changes
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        if (next.isAuthenticated && next.userId != null) {
          // User logged in: load wishlist from server
          _handleLogin(next.userId!);
        } else {
          // User logged out: clear wishlist
          _handleLogout();
        }
      }
    });

    // Load wishlist if user is already authenticated
    final authState = _ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.userId != null) {
      await loadWishlist();
      _subscribeToWishlistChanges(authState.userId!);
    }
  }

  /// Handle user login
  Future<void> _handleLogin(String userId) async {
    try {
      await loadWishlist();
      _subscribeToWishlistChanges(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling login: $e');
      }
    }
  }

  /// Handle user logout
  void _handleLogout() {
    // Cancel real-time subscription
    _wishlistSubscription?.cancel();
    _wishlistSubscription = null;

    // Cancel debounce timer
    _debounceTimer?.cancel();
    _debounceTimer = null;

    // Clear wishlist state
    state = const WishlistState();
    _hasLoaded = false;
  }

  /// Load wishlist from server
  Future<void> loadWishlist() async {
    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated || authState.userId == null) {
      state = const WishlistState();
      _hasLoaded = false;
      return;
    }

    if (_isLoading) return;
    _isLoading = true;
    state = state.copyWith(loading: true, error: null);

    try {
      // 1. Fetch all product IDs first - this is the source of truth for "is in wishlist"
      final ids = await _repository.getWishlistProductIds(authState.userId!);
      final productIds = ids.toSet();

      // Update state with IDs immediately so hearts show correctly
      state = state.copyWith(
        productIds: productIds,
      );

      // 2. Fetch product details - this is for displaying the list
      // Note: Some products might fail to load details, but we keep their IDs in state
      final products = await _repository.getWishlistProducts(authState.userId!);
      
      state = state.copyWith(
        products: products,
        // Don't overwrite productIds here, keep the full set from step 1
        loading: false,
      );
      _hasLoaded = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading wishlist: $e');
      }
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Subscribe to real-time wishlist changes
  void _subscribeToWishlistChanges(String userId) {
    _wishlistSubscription?.cancel();
    _wishlistSubscription = _repository
        .watchWishlistProductIds(userId)
        .listen(
          (productIds) async {
            // Cancel any pending debounce timer
            _debounceTimer?.cancel();

            // Update product IDs set
            final productIdsSet = productIds.toSet();
            
            // Compare Set contents, not references
            final currentIds = state.productIds;
            final idsChanged = productIdsSet.length != currentIds.length ||
                !productIdsSet.every((id) => currentIds.contains(id)) ||
                !currentIds.every((id) => productIdsSet.contains(id));

            if (idsChanged) {
              // Update product IDs immediately for optimistic UI
              state = state.copyWith(productIds: productIdsSet);

              // Debounce the full reload to prevent rapid-fire reloads
              _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
                if (!_isLoading && _hasLoaded) {
                  // Only reload if we have new products that aren't in our current list
                  final newProductIds = productIdsSet.difference(currentIds);
                  if (newProductIds.isNotEmpty) {
                    // New products added - need to fetch their details
                    await loadWishlist();
                  } else {
                    // Products removed - update list optimistically
                    final currentState = state;
                    final updatedProducts = currentState.products
                        .where((p) => productIdsSet.contains(p.id))
                        .toList();
                    if (updatedProducts.length != currentState.products.length) {
                      state = state.copyWith(products: updatedProducts);
                    }
                  }
                }
              });
            }
          },
          onError: (e) {
            if (kDebugMode) {
              print('Error in wishlist subscription: $e');
            }
          },
        );
  }

  /// Add product to wishlist
  Future<bool> addToWishlist(String productId) async {
    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated || authState.userId == null) {
      return false;
    }

    // Optimistic update
    if (!state.productIds.contains(productId)) {
      state = state.copyWith(
        productIds: {...state.productIds, productId},
      );
    }

    try {
      await _repository.addToWishlist(productId, authState.userId!);
      // Reload to get full product details
      await loadWishlist();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to wishlist: $e');
      }
      // Revert optimistic update
      final updatedIds = Set<String>.from(state.productIds)..remove(productId);
      state = state.copyWith(productIds: updatedIds);
      return false;
    }
  }

  /// Remove product from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated || authState.userId == null) {
      return false;
    }

    // Optimistic update
    final wasInWishlist = state.productIds.contains(productId);
    if (wasInWishlist) {
      final updatedIds = Set<String>.from(state.productIds)..remove(productId);
      final updatedProducts =
          state.products.where((p) => p.id != productId).toList();
      state = state.copyWith(
        productIds: updatedIds,
        products: updatedProducts,
      );
    }

    try {
      await _repository.removeFromWishlist(productId, authState.userId!);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error removing from wishlist: $e');
      }
      // Revert optimistic update
      if (wasInWishlist) {
        await loadWishlist();
      }
      return false;
    }
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return state.productIds.contains(productId);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _wishlistSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

