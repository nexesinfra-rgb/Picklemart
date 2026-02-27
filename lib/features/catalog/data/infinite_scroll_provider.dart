import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product.dart';
import 'product_repository.dart';
import 'shared_product_provider.dart';

class InfiniteScrollState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const InfiniteScrollState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  InfiniteScrollState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return InfiniteScrollState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

class InfiniteScrollNotifier extends StateNotifier<InfiniteScrollState> {
  final ProductRepository _repository;
  final String? category;
  final int pageSize;
  List<Product> _loadedProducts = []; // Products loaded so far (for repeatable scrolling)
  int _lastLoadedPage = 0; // Track the last page we've loaded from the database
  bool _hasReachedEnd = false; // Track if we've loaded all available products
  Ref? _ref;

  InfiniteScrollNotifier(this._repository, {this.category, this.pageSize = 20})
    : super(const InfiniteScrollState()) {
    loadInitial();
  }

  void setRef(Ref ref) {
    _ref = ref;
    // Listen to shared product changes for real-time sync
    ref.listen(sharedProductProvider, (previous, next) {
      if (previous?.products != next.products) {
        _syncWithSharedProducts();
      }
    });
  }

  void _syncWithSharedProducts() {
    if (_ref == null) return;

    // When shared products change, reset and reload
    _loadedProducts = [];
    _lastLoadedPage = 0;
    _hasReachedEnd = false;
    refresh();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load first page using proper pagination
      final initialProducts = category != null
          ? await _repository.fetchByCategory(
              category!,
              page: 1,
              limit: pageSize,
            )
          : await _repository.fetchPaginated(page: 1, limit: pageSize);

      if (initialProducts.isEmpty) {
        state = state.copyWith(
          products: [],
          isLoading: false,
          hasMore: false,
          currentPage: 1,
        );
        _hasReachedEnd = true;
        return;
      }

      _loadedProducts = initialProducts;
      _lastLoadedPage = 1;
      _hasReachedEnd = initialProducts.length < pageSize; // If we got fewer than pageSize, we've reached the end

      state = state.copyWith(
        products: initialProducts,
        isLoading: false,
        hasMore: true, // Always true for repeatable scrolling
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load products: ${e.toString()}',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);
    try {
      final currentIndex = (state.currentPage - 1) * pageSize;
      final nextIndex = currentIndex + pageSize;
      List<Product> newProducts = [];

      // Check if we need to fetch more from the database
      if (nextIndex >= _loadedProducts.length && !_hasReachedEnd) {
        // Fetch next page from database
        final nextPage = _lastLoadedPage + 1;
        final fetchedProducts = category != null
            ? await _repository.fetchByCategory(
                category!,
                page: nextPage,
                limit: pageSize,
              )
            : await _repository.fetchPaginated(page: nextPage, limit: pageSize);

        if (fetchedProducts.isEmpty) {
          // No more products from database
          _hasReachedEnd = true;
        } else {
          // Add fetched products to our loaded list
          _loadedProducts.addAll(fetchedProducts);
          _lastLoadedPage = nextPage;
          
          // Check if we've reached the end (got fewer than pageSize)
          if (fetchedProducts.length < pageSize) {
            _hasReachedEnd = true;
          }
        }
      }

      // Now get the next batch from loaded products (for repeatable scrolling)
      if (nextIndex < _loadedProducts.length) {
        // Load next batch normally from loaded products
        final endIndex = (nextIndex + pageSize > _loadedProducts.length)
            ? _loadedProducts.length
            : nextIndex + pageSize;
        newProducts = _loadedProducts.sublist(nextIndex, endIndex);
      } else if (_loadedProducts.isNotEmpty) {
        // Start repeating from the beginning (repeatable scrolling)
        final remainingInCurrentCycle = _loadedProducts.length - currentIndex;
        final neededFromNextCycle = pageSize - remainingInCurrentCycle;

        // Add remaining products from current cycle
        if (remainingInCurrentCycle > 0) {
          newProducts.addAll(_loadedProducts.sublist(currentIndex));
        }

        // Add products from the beginning of the cycle
        if (neededFromNextCycle > 0) {
          newProducts.addAll(_loadedProducts.take(neededFromNextCycle));
        }
      }

      state = state.copyWith(
        products: [...state.products, ...newProducts],
        isLoading: false,
        hasMore: true, // Always true for repeatable scrolling
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more products: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    state = const InfiniteScrollState();
    await loadInitial();
  }
}

// Provider factory for infinite scroll
final infiniteScrollProvider = StateNotifierProvider.family<
  InfiniteScrollNotifier,
  InfiniteScrollState,
  String?
>((ref, category) {
  final repository = ref.watch(productRepositoryProvider);
  final notifier = InfiniteScrollNotifier(repository, category: category);
  notifier.setRef(ref);
  return notifier;
});

// Convenience providers
final infiniteProductsProvider = Provider.family<List<Product>, String?>((
  ref,
  category,
) {
  return ref.watch(infiniteScrollProvider(category)).products;
});

final infiniteScrollLoadingProvider = Provider.family<bool, String?>((
  ref,
  category,
) {
  return ref.watch(infiniteScrollProvider(category)).isLoading;
});

final infiniteScrollHasMoreProvider = Provider.family<bool, String?>((
  ref,
  category,
) {
  return ref.watch(infiniteScrollProvider(category)).hasMore;
});
