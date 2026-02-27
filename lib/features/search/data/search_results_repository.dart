import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository interface for search results logging
abstract class SearchResultsRepository {
  /// Log a search query that returned no results
  Future<void> logSearchResult({
    String? userId,
    String? userName,
    required String searchQuery,
  });
}

/// Supabase implementation of SearchResultsRepository
class SearchResultsRepositorySupabase implements SearchResultsRepository {
  final SupabaseClient _supabase;

  SearchResultsRepositorySupabase(this._supabase);

  @override
  Future<void> logSearchResult({
    String? userId,
    String? userName,
    required String searchQuery,
  }) async {
    try {
      // Only log if search query is not empty
      if (searchQuery.trim().isEmpty) {
        return;
      }

      await _supabase.from('search_results').insert({
        'user_id': userId,
        'user_name': userName,
        'search_query': searchQuery.trim(),
        'searched_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - we don't want logging errors to break the search functionality
      if (kDebugMode) {
        print('Error logging search result: $e');
      }
    }
  }
}

/// Provider for SearchResultsRepository
final searchResultsRepositoryProvider =
    Provider<SearchResultsRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SearchResultsRepositorySupabase(supabaseClient);
});

