import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import 'order_repository.dart';
import 'order_repository_provider.dart';
import 'order_model.dart';

class OrdersInfiniteScrollState {
  final List<Order> orders;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const OrdersInfiniteScrollState({
    this.orders = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  OrdersInfiniteScrollState copyWith({
    List<Order>? orders,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return OrdersInfiniteScrollState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

class OrdersInfiniteScrollNotifier
    extends StateNotifier<OrdersInfiniteScrollState> {
  final OrderRepository _repository;
  final int pageSize;
  int _lastLoadedPage = 0;
  bool _hasReachedEnd = false;
  StreamSubscription? _subscription;
  Timer? _refreshTimer;

  OrdersInfiniteScrollNotifier(this._repository, {this.pageSize = 50})
    : super(const OrdersInfiniteScrollState()) {
    _initSubscription();
    loadInitial();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      refresh(silent: true);
    });
  }

  void _initSubscription() {
    _subscription = _repository.subscribeToUserOrders().listen((_) {
      refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> loadInitial({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final initialOrders = await _repository.getUserOrders(
        page: 1,
        limit: pageSize,
      );

      if (initialOrders.isEmpty) {
        state = state.copyWith(
          orders: [],
          isLoading: false,
          hasMore: false,
          currentPage: 1,
        );
        _hasReachedEnd = true;
        return;
      }

      _lastLoadedPage = 1;
      _hasReachedEnd = initialOrders.length < pageSize;

      state = state.copyWith(
        orders: initialOrders,
        isLoading: false,
        hasMore: !_hasReachedEnd,
        currentPage: 1,
      );
    } catch (e) {
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load orders: ${e.toString()}',
        );
      }
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      // Fetch next page from database
      final nextPage = _lastLoadedPage + 1;
      final fetchedOrders = await _repository.getUserOrders(
        page: nextPage,
        limit: pageSize,
      );

      if (fetchedOrders.isEmpty) {
        _hasReachedEnd = true;
        state = state.copyWith(isLoading: false, hasMore: false);
        return;
      }

      _lastLoadedPage = nextPage;

      // Check if we've reached the end
      if (fetchedOrders.length < pageSize) {
        _hasReachedEnd = true;
      }

      state = state.copyWith(
        orders: [...state.orders, ...fetchedOrders],
        isLoading: false,
        hasMore: !_hasReachedEnd,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load more orders: ${e.toString()}',
      );
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (silent) {
      final currentCount = state.orders.length;
      final limit = currentCount > pageSize ? currentCount : pageSize;

      try {
        final freshOrders = await _repository.getUserOrders(
          page: 1,
          limit: limit,
        );

        if (freshOrders.isNotEmpty) {
          state = state.copyWith(orders: freshOrders);
        }
      } catch (_) {}
    } else {
      _lastLoadedPage = 0;
      _hasReachedEnd = false;
      await loadInitial(silent: silent);
    }
  }
}

final ordersInfiniteScrollProvider = StateNotifierProvider<
  OrdersInfiniteScrollNotifier,
  OrdersInfiniteScrollState
>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  // Watch auth state to force rebuild on user change to prevent cross-account order reflection
  ref.watch(authControllerProvider);
  return OrdersInfiniteScrollNotifier(repository);
});
