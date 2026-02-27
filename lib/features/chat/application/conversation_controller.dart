import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/chat_repository.dart';
import '../data/chat_models.dart';

/// Conversations state
class ConversationsState {
  final List<ConversationWithUser> conversations;
  final bool isLoading;
  final String? error;
  final ConversationStatus? statusFilter;
  final String? searchQuery;

  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.searchQuery,
  });

  ConversationsState copyWith({
    List<ConversationWithUser>? conversations,
    bool? isLoading,
    String? error,
    ConversationStatus? statusFilter,
    String? searchQuery,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Conversation controller (for admin)
class ConversationController extends StateNotifier<ConversationsState> {
  final ChatRepository _repository;
  StreamSubscription<List<ConversationWithUser>>? _subscription;

  ConversationController(this._repository) : super(const ConversationsState());

  /// Load all conversations
  Future<void> loadConversations({
    ConversationStatus? statusFilter,
    String? searchQuery,
    bool subscribeRealtime = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversations = await _repository.getAllConversations(
        status: statusFilter ?? state.statusFilter,
        searchQuery: searchQuery ?? state.searchQuery,
      );

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        statusFilter: statusFilter ?? state.statusFilter,
        searchQuery: searchQuery ?? state.searchQuery,
      );

      // Subscribe to real-time updates if requested
      if (subscribeRealtime) {
        _subscribeToConversations(
          statusFilter ?? state.statusFilter,
          searchQuery ?? state.searchQuery,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load conversations: ${e.toString()}',
      );
    }
  }

  /// Subscribe to real-time conversation updates
  void _subscribeToConversations(
    ConversationStatus? statusFilter,
    String? searchQuery,
  ) {
    _subscription?.cancel();

    _subscription = _repository
        .subscribeToConversations(
          statusFilter: statusFilter,
          searchQuery: searchQuery,
        )
        .listen(
      (conversations) {
        state = state.copyWith(
          conversations: conversations,
          isLoading: false,
        );
      },
      onError: (error) {
        state = state.copyWith(
          error: 'Failed to subscribe to conversations: ${error.toString()}',
        );
      },
    );
  }

  /// Update conversation status
  Future<void> updateConversationStatus(
    String conversationId,
    ConversationStatus status,
  ) async {
    try {
      await _repository.updateConversationStatus(conversationId, status);

      // Update local state
      final updatedConversations = state.conversations.map((c) {
        if (c.conversation.id == conversationId) {
          return ConversationWithUser(
            conversation: c.conversation.copyWith(status: status),
            userName: c.userName,
            userEmail: c.userEmail,
            userAvatarUrl: c.userAvatarUrl,
            unreadCount: c.unreadCount,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(conversations: updatedConversations);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update conversation status: ${e.toString()}');
    }
  }

  /// Assign admin to conversation
  Future<void> assignAdmin(String conversationId, String adminId) async {
    try {
      await _repository.assignAdmin(conversationId, adminId);

      // Reload conversations to get updated data
      await loadConversations();
    } catch (e) {
      state = state.copyWith(error: 'Failed to assign admin: ${e.toString()}');
    }
  }

  /// Set status filter
  void setStatusFilter(ConversationStatus? status) {
    loadConversations(
      statusFilter: status,
      subscribeRealtime: true,
    );
  }

  /// Set search query
  void setSearchQuery(String? query) {
    loadConversations(
      searchQuery: query,
      subscribeRealtime: true,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Conversation controller provider
final conversationControllerProvider =
    StateNotifierProvider<ConversationController, ConversationsState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ConversationController(repository);
});

