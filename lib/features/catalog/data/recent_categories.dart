import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecentCategories extends StateNotifier<Set<String>> {
  RecentCategories() : super({});

  void markViewed(String category) {
    final norm = category.trim();
    if (norm.isEmpty) return;
    state = {...state, norm};
  }
}

final recentCategoriesProvider = StateNotifierProvider<RecentCategories, Set<String>>(
  (ref) => RecentCategories(),
);

