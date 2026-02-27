import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';

/// Model for a search result entry
class SearchResult {
  final String id;
  final String? userId;
  final String? userName;
  final String? email;
  final String? phone;
  final String searchQuery;
  final DateTime searchedAt;
  final DateTime createdAt;

  SearchResult({
    required this.id,
    this.userId,
    this.userName,
    this.email,
    this.phone,
    required this.searchQuery,
    required this.searchedAt,
    required this.createdAt,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    // Handle joined profile data
    Map<String, dynamic>? profileData;
    if (json['profiles'] != null) {
      profileData = json['profiles'] is Map
          ? Map<String, dynamic>.from(json['profiles'] as Map)
          : null;
    }

    return SearchResult(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
      email: profileData?['email'] as String?,
      phone: profileData?['display_mobile'] as String? ??
          profileData?['mobile'] as String?,
      searchQuery: json['search_query'] as String,
      searchedAt: json['searched_at'] != null
          ? DateTime.parse(json['searched_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get displayUserName => userName ?? 'Anonymous';
  String get displayEmail => email ?? 'N/A';
  String get displayPhone => phone ?? 'N/A';
}

/// State for admin search results
class AdminSearchResultsState {
  final List<SearchResult> searchResults;
  final bool loading;
  final String? error;
  final int currentPage;
  final int pageSize;
  final int totalCount;

  const AdminSearchResultsState({
    this.searchResults = const [],
    this.loading = false,
    this.error,
    this.currentPage = 1,
    this.pageSize = 20,
    this.totalCount = 0,
  });

  AdminSearchResultsState copyWith({
    List<SearchResult>? searchResults,
    bool? loading,
    String? error,
    int? currentPage,
    int? pageSize,
    int? totalCount,
  }) =>
      AdminSearchResultsState(
        searchResults: searchResults ?? this.searchResults,
        loading: loading ?? this.loading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        pageSize: pageSize ?? this.pageSize,
        totalCount: totalCount ?? this.totalCount,
      );

  bool get hasNextPage => currentPage * pageSize < totalCount;
  bool get hasPreviousPage => currentPage > 1;
  int get totalPages => totalCount > 0 ? (totalCount / pageSize).ceil() : 1;
}

/// Controller for managing admin search results
class AdminSearchResultsController
    extends StateNotifier<AdminSearchResultsState> {
  AdminSearchResultsController(this._ref)
      : super(const AdminSearchResultsState()) {
    loadPage(1);
  }

  final Ref _ref;
  static const int _pageSize = 20;

  /// Load a specific page of search results
  Future<void> loadPage(int page) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final supabase = _ref.read(supabaseClientProvider);

      // Calculate offset
      final offset = (page - 1) * _pageSize;

      // Get total count first
      final countResponse = await supabase
          .from('search_results')
          .select('id');
      final totalCount = countResponse.length;

      // Fetch paginated results with profile join
      final response = await supabase
          .from('search_results')
          .select('*, profiles(email, mobile, display_mobile)')
          .order('searched_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      final results = (response as List)
          .map((json) => SearchResult.fromJson(
              Map<String, dynamic>.from(json)))
          .toList();

      state = state.copyWith(
        searchResults: results,
        loading: false,
        error: null,
        currentPage: page,
        totalCount: totalCount,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading search results: $e');
      }
      state = state.copyWith(
        loading: false,
        error: 'Failed to load search results: ${e.toString()}',
      );
    }
  }

  /// Load first page (for refresh)
  Future<void> refresh() async {
    await loadPage(1);
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (state.hasNextPage) {
      await loadPage(state.currentPage + 1);
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (state.hasPreviousPage) {
      await loadPage(state.currentPage - 1);
    }
  }

  /// Load all search results (backward compatibility)
  Future<void> loadSearchResults() async {
    await loadPage(1);
  }

  /// Delete a search result
  Future<bool> deleteSearchResult(String id) async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      
      await supabase
          .from('search_results')
          .delete()
          .eq('id', id);
      
      // Reload current page to refresh the list
      await loadPage(state.currentPage);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting search result: $e');
      }
      return false;
    }
  }
}

/// Provider for AdminSearchResultsController
final adminSearchResultsControllerProvider =
    StateNotifierProvider<AdminSearchResultsController,
        AdminSearchResultsState>((ref) {
  return AdminSearchResultsController(ref);
});

