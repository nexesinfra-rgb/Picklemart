import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/content_models.dart';
import '../data/category_service.dart';
import '../domain/category.dart' as category_domain;

class AdminContentState {
  final bool loading;
  final String? error;
  final List<ContentItem> contentItems;
  final List<ContentItem> filteredContentItems;
  final List<ContentCategory> categories;
  final List<ContentComment> comments;
  final String searchQuery;
  final ContentType? selectedType;
  final ContentStatus? selectedStatus;
  final ContentItem? selectedItem;
  final ContentCategory? selectedCategory;

  const AdminContentState({
    this.loading = false,
    this.error,
    this.contentItems = const [],
    List<ContentItem>? filteredContentItems,
    this.categories = const [],
    this.comments = const [],
    this.searchQuery = '',
    this.selectedType,
    this.selectedStatus,
    this.selectedItem,
    this.selectedCategory,
  }) : filteredContentItems = filteredContentItems ?? contentItems;

  AdminContentState copyWith({
    bool? loading,
    String? error,
    List<ContentItem>? contentItems,
    List<ContentItem>? filteredContentItems,
    List<ContentCategory>? categories,
    List<ContentComment>? comments,
    String? searchQuery,
    ContentType? selectedType,
    ContentStatus? selectedStatus,
    ContentItem? selectedItem,
    ContentCategory? selectedCategory,
  }) {
    return AdminContentState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      contentItems: contentItems ?? this.contentItems,
      filteredContentItems: filteredContentItems ?? this.filteredContentItems,
      categories: categories ?? this.categories,
      comments: comments ?? this.comments,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedItem: selectedItem ?? this.selectedItem,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class AdminContentController extends StateNotifier<AdminContentState> {
  AdminContentController(this._ref) : super(const AdminContentState()) {
    loadContentItems();
    loadCategories();
    loadComments();
  }

  final Ref _ref;

  Future<void> loadContentItems() async {
    state = state.copyWith(loading: true, error: null);
    try {
      // In production, load real content from Supabase
      // Mock content is only available in debug mode for testing
      List<ContentItem> contentItems = [];
      
      if (kDebugMode) {
        // Only load mock content in debug mode
        await Future.delayed(const Duration(seconds: 1));

        final mockContent = [
          ContentItem(
            id: 'content_1',
            title: 'Welcome to Our Store',
            slug: 'welcome-to-our-store',
            content:
                'Welcome to our amazing store! We offer the best products at competitive prices.',
            excerpt: 'Welcome to our amazing store!',
            type: ContentType.page,
            status: ContentStatus.published,
            visibility: ContentVisibility.public,
            tags: ['welcome', 'store'],
            categories: ['general'],
            authorId: 'admin',
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now().subtract(const Duration(days: 5)),
            publishedAt: DateTime.now().subtract(const Duration(days: 30)),
            viewCount: 1250,
            commentCount: 15,
          ),
          ContentItem(
            id: 'content_2',
            title: 'How to Choose the Right Laptop',
            slug: 'how-to-choose-right-laptop',
            content:
                'Choosing the right laptop can be overwhelming. Here are our top tips...',
            excerpt: 'Choosing the right laptop can be overwhelming.',
            type: ContentType.blog,
            status: ContentStatus.published,
            visibility: ContentVisibility.public,
            tags: ['laptop', 'guide', 'technology'],
            categories: ['technology', 'guides'],
            authorId: 'admin',
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
            publishedAt: DateTime.now().subtract(const Duration(days: 15)),
            viewCount: 890,
            commentCount: 8,
          ),
          ContentItem(
            id: 'content_3',
            title: 'Product Review: Wireless Earbuds',
            slug: 'product-review-wireless-earbuds',
            content: 'Our detailed review of the latest wireless earbuds...',
            excerpt: 'Our detailed review of the latest wireless earbuds.',
            type: ContentType.product,
            status: ContentStatus.draft,
            visibility: ContentVisibility.public,
            tags: ['review', 'earbuds', 'audio'],
            categories: ['reviews'],
            authorId: 'admin',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
            viewCount: 0,
            commentCount: 0,
          ),
        ];
        contentItems = mockContent;
      } else {
        // Production: Load from Supabase
        // TODO: Implement Supabase content loading when content management is ready
        // For now, return empty list in production
        contentItems = [];
      }

      state = state.copyWith(
        contentItems: contentItems,
        filteredContentItems: _filterContent(
          contentItems,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadCategories() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final categoryService = _ref.read(categoryServiceProvider);
      final List<category_domain.Category> dbCategories = await categoryService.getAllCategories();
      
      // Convert Category (database) to ContentCategory (UI model)
      final List<ContentCategory> contentCategories = dbCategories.map((category_domain.Category cat) => _categoryToContentCategory(cat)).toList();
      
      state = state.copyWith(categories: contentCategories, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadComments() async {
    state = state.copyWith(loading: true, error: null);
    try {
      List<ContentComment> comments = [];
      
      if (kDebugMode) {
        // Only load mock comments in debug mode
        await Future.delayed(const Duration(milliseconds: 500));

        final mockComments = [
          ContentComment(
            id: 'comment_1',
            contentId: 'content_1',
            authorName: 'John Doe',
            authorEmail: 'john@example.com',
            content: 'Great article! Very helpful information.',
            isApproved: true,
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now().subtract(const Duration(days: 10)),
          ),
          ContentComment(
            id: 'comment_2',
            contentId: 'content_1',
            authorName: 'Jane Smith',
            authorEmail: 'jane@example.com',
            content: 'Thanks for sharing this valuable content.',
            isApproved: true,
            createdAt: DateTime.now().subtract(const Duration(days: 8)),
            updatedAt: DateTime.now().subtract(const Duration(days: 8)),
          ),
          ContentComment(
            id: 'comment_3',
            contentId: 'content_2',
            authorName: 'Mike Johnson',
            authorEmail: 'mike@example.com',
            content: 'This guide helped me choose the perfect laptop!',
            isApproved: false,
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ];
        comments = mockComments;
      } else {
        // Production: Load from Supabase
        // TODO: Implement Supabase comment loading when comment system is ready
        // For now, return empty list in production
        comments = [];
      }

      state = state.copyWith(comments: comments, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  List<ContentItem> _filterContent(
    List<ContentItem> items,
    String query,
    ContentType? type,
    ContentStatus? status,
  ) {
    return items.where((item) {
      final matchesSearch =
          query.isEmpty ||
          item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.content.toLowerCase().contains(query.toLowerCase()) ||
          item.tags.any(
            (tag) => tag.toLowerCase().contains(query.toLowerCase()),
          );

      final matchesType = type == null || item.type == type;
      final matchesStatus = status == null || item.status == status;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  void searchContent(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredContentItems: _filterContent(
        state.contentItems,
        query,
        state.selectedType,
        state.selectedStatus,
      ),
    );
  }

  void filterByType(ContentType? type) {
    state = state.copyWith(
      selectedType: type,
      filteredContentItems: _filterContent(
        state.contentItems,
        state.searchQuery,
        type,
        state.selectedStatus,
      ),
    );
  }

  void filterByStatus(ContentStatus? status) {
    state = state.copyWith(
      selectedStatus: status,
      filteredContentItems: _filterContent(
        state.contentItems,
        state.searchQuery,
        state.selectedType,
        status,
      ),
    );
  }

  Future<bool> createContent(ContentItem content) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedItems = [...state.contentItems, content];
      state = state.copyWith(
        contentItems: updatedItems,
        filteredContentItems: _filterContent(
          updatedItems,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateContent(ContentItem updatedContent) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedItems =
          state.contentItems.map((item) {
            if (item.id == updatedContent.id) {
              return updatedContent;
            }
            return item;
          }).toList();

      state = state.copyWith(
        contentItems: updatedItems,
        filteredContentItems: _filterContent(
          updatedItems,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteContent(String contentId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedItems =
          state.contentItems.where((item) => item.id != contentId).toList();
      state = state.copyWith(
        contentItems: updatedItems,
        filteredContentItems: _filterContent(
          updatedItems,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> createCategory(ContentCategory category) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final categoryService = _ref.read(categoryServiceProvider);
      
      // Convert ContentCategory to Category (database model)
      // Use temporary id - database will generate the real one
      final dbCategory = category_domain.Category(
        id: category.id.isEmpty ? 'temp-${DateTime.now().millisecondsSinceEpoch}' : category.id,
        name: category.name,
        description: category.description,
        parentId: category.parentId,
        sortOrder: category.sortOrder,
        isActive: category.isActive,
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
      );
      
      // Create in database
      final createdCategory = await categoryService.createCategory(dbCategory);
      
      // Convert back to ContentCategory and add to state
      final contentCategory = _categoryToContentCategory(createdCategory);
      
      state = state.copyWith(
        categories: [...state.categories, contentCategory],
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateCategory(ContentCategory category) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final categoryService = _ref.read(categoryServiceProvider);
      
      // Convert ContentCategory to Category (database model)
      final dbCategory = _contentCategoryToCategory(category);
      
      // Update in database
      final updatedCategory = await categoryService.updateCategory(dbCategory);
      
      // Convert back to ContentCategory and update state
      final contentCategory = _categoryToContentCategory(updatedCategory);
      
      final updatedCategories = state.categories.map((cat) {
        return cat.id == category.id ? contentCategory : cat;
      }).toList();
      
      state = state.copyWith(
        categories: updatedCategories,
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final categoryService = _ref.read(categoryServiceProvider);
      
      // Delete from database
      final success = await categoryService.deleteCategory(categoryId);
      
      if (!success) {
        state = state.copyWith(
          loading: false,
          error: 'Failed to delete category. It may be in use by products or you may not have permission.',
        );
        return false;
      }
      
      // Refresh categories from database to ensure consistency
      await loadCategories();
      
      return true;
    } catch (e) {
      // Extract meaningful error message
      String errorMessage = e.toString();
      
      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      state = state.copyWith(
        loading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  // Helper method to convert Category (database) to ContentCategory (UI)
  ContentCategory _categoryToContentCategory(category_domain.Category category) {
    return ContentCategory(
      id: category.id,
      name: category.name,
      slug: _generateSlug(category.name),
      description: category.description,
      parentId: category.parentId,
      sortOrder: category.sortOrder,
      isActive: category.isActive,
      createdAt: category.createdAt ?? DateTime.now(),
      updatedAt: category.updatedAt ?? DateTime.now(),
    );
  }

  // Helper method to convert ContentCategory (UI) to Category (database)
  category_domain.Category _contentCategoryToCategory(ContentCategory contentCategory) {
    return category_domain.Category(
      id: contentCategory.id,
      name: contentCategory.name,
      description: contentCategory.description,
      parentId: contentCategory.parentId,
      sortOrder: contentCategory.sortOrder,
      isActive: contentCategory.isActive,
      createdAt: contentCategory.createdAt,
      updatedAt: contentCategory.updatedAt,
    );
  }

  // Helper method to generate slug from name
  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<bool> approveComment(String commentId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedComments =
          state.comments.map((comment) {
            if (comment.id == commentId) {
              return comment.copyWith(isApproved: true);
            }
            return comment;
          }).toList();

      state = state.copyWith(comments: updatedComments, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedComments =
          state.comments.where((comment) => comment.id != commentId).toList();
      state = state.copyWith(comments: updatedComments, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  void selectItem(ContentItem? item) {
    state = state.copyWith(selectedItem: item);
  }

  void selectCategory(ContentCategory? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void refresh() {
    loadContentItems();
    loadCategories();
    loadComments();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final adminContentControllerProvider =
    StateNotifierProvider<AdminContentController, AdminContentState>(
      (ref) => AdminContentController(ref),
    );


