import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_browsing_repository.dart';
import '../domain/customer_browsing_analytics.dart';

class CustomerBrowsingState {
  final CustomerBrowsingAnalytics? analytics;
  final List<ProductViewSession> filteredViews;
  final BrowsingSortType sortType;
  final BrowsingFilterType filterType;
  final bool loading;
  final String? error;

  const CustomerBrowsingState({
    this.analytics,
    this.filteredViews = const [],
    this.sortType = BrowsingSortType.mostViewed,
    this.filterType = BrowsingFilterType.all,
    this.loading = false,
    this.error,
  });

  CustomerBrowsingState copyWith({
    CustomerBrowsingAnalytics? analytics,
    List<ProductViewSession>? filteredViews,
    BrowsingSortType? sortType,
    BrowsingFilterType? filterType,
    bool? loading,
    String? error,
  }) => CustomerBrowsingState(
    analytics: analytics ?? this.analytics,
    filteredViews: filteredViews ?? this.filteredViews,
    sortType: sortType ?? this.sortType,
    filterType: filterType ?? this.filterType,
    loading: loading ?? this.loading,
    error: error ?? this.error,
  );
}

class CustomerBrowsingController extends StateNotifier<CustomerBrowsingState> {
  CustomerBrowsingController(this._ref) : super(const CustomerBrowsingState());
  
  final Ref _ref;
  StreamSubscription<CustomerBrowsingAnalytics>? _subscription;

  Future<void> loadCustomerBrowsingAnalytics(
    String customerId, {
    String? customerName,
    String? customerEmail,
  }) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }
    
    try {
      final repository = _ref.read(customerBrowsingRepositoryProvider);
      final analytics = await repository.getCustomerBrowsingAnalytics(
        customerId,
        customerName: customerName,
        customerEmail: customerEmail,
      );
      final filteredViews = _applyFilters(analytics.productViews);
      
      if (mounted) {
        state = state.copyWith(
          analytics: analytics,
          filteredViews: filteredViews,
          loading: false,
        );
      }
      
      // Subscribe to real-time updates
      _subscription?.cancel();
      _subscription = repository.subscribeToCustomerBrowsingAnalytics(
        customerId,
        customerName: customerName,
        customerEmail: customerEmail,
      ).listen(
        (analytics) {
          final filteredViews = _applyFilters(analytics.productViews);
          if (mounted) {
            state = state.copyWith(
              analytics: analytics,
              filteredViews: filteredViews,
            );
          }
        },
        onError: (error) {
          // Don't update state on subscription error, just log it
          // The initial load already succeeded
        },
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          loading: false,
          error: e.toString(),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void updateSortType(BrowsingSortType sortType) {
    state = state.copyWith(sortType: sortType);
    if (state.analytics != null) {
      final filteredViews = _applyFilters(state.analytics!.productViews);
      state = state.copyWith(filteredViews: filteredViews);
    }
  }

  void updateFilterType(BrowsingFilterType filterType) {
    state = state.copyWith(filterType: filterType);
    if (state.analytics != null) {
      final filteredViews = _applyFilters(state.analytics!.productViews);
      state = state.copyWith(filteredViews: filteredViews);
    }
  }

  List<ProductViewSession> _applyFilters(List<ProductViewSession> views) {
    List<ProductViewSession> filtered = List.from(views);

    // Apply time filter
    final now = DateTime.now();
    switch (state.filterType) {
      case BrowsingFilterType.last24Hours:
        filtered = filtered.where((view) => 
          view.endTime.isAfter(now.subtract(const Duration(hours: 24)))
        ).toList();
        break;
      case BrowsingFilterType.last7Days:
        filtered = filtered.where((view) => 
          view.endTime.isAfter(now.subtract(const Duration(days: 7)))
        ).toList();
        break;
      case BrowsingFilterType.last30Days:
        filtered = filtered.where((view) => 
          view.endTime.isAfter(now.subtract(const Duration(days: 30)))
        ).toList();
        break;
      case BrowsingFilterType.last90Days:
        filtered = filtered.where((view) => 
          view.endTime.isAfter(now.subtract(const Duration(days: 90)))
        ).toList();
        break;
      case BrowsingFilterType.all:
        break;
    }

    // Apply sorting
    switch (state.sortType) {
      case BrowsingSortType.mostViewed:
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case BrowsingSortType.longestViewed:
        filtered.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case BrowsingSortType.recentlyViewed:
        filtered.sort((a, b) => b.endTime.compareTo(a.endTime));
        break;
      case BrowsingSortType.alphabetical:
        filtered.sort((a, b) => a.productName.compareTo(b.productName));
        break;
    }

    return filtered;
  }

}

final customerBrowsingControllerProvider = 
    StateNotifierProvider<CustomerBrowsingController, CustomerBrowsingState>(
  (ref) => CustomerBrowsingController(ref),
);

