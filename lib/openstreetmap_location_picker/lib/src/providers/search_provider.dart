import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_result.dart';
import '../services/geocoding_service.dart';

class SearchState {
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;
  final String query;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
    String? query,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      query: query ?? this.query,
    );
  }

  bool get hasResults => results.isNotEmpty;
  bool get isEmpty => results.isEmpty && !isLoading;
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], query: query);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      query: query,
    );

    try {
      final results = await GeocodingService.searchLocations(query, limit: 10);
      // Only update if this is still the current query
      if (state.query == query) {
        state = state.copyWith(
          results: results,
          isLoading: false,
        );
      }
    } catch (e) {
      if (state.query == query) {
        state = state.copyWith(
          isLoading: false,
          error: 'Search failed. Please try again.',
        );
      }
    }
  }

  void clearResults() {
    state = const SearchState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<SearchResult?> reverseGeocode(double latitude, double longitude) async {
    try {
      return await GeocodingService.reverseGeocode(latitude, longitude);
    } catch (e) {
      return null;
    }
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(),
);
