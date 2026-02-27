import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_model.dart';
import '../data/notification_repository_provider.dart';
import '../../auth/application/auth_controller.dart' show authControllerProvider, AuthState;

class NotificationState {
  final List<UserNotification> notifications;
  final int unreadCount;
  final bool loading;
  final String? error;
  final Set<String>? selectedNotificationIds;
  final bool? isSelectionMode;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.loading = false,
    this.error,
    this.selectedNotificationIds,
    this.isSelectionMode,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  NotificationState copyWith({
    List<UserNotification>? notifications,
    int? unreadCount,
    bool? loading,
    String? error,
    Set<String>? selectedNotificationIds,
    bool? isSelectionMode,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      error: error,
      selectedNotificationIds: selectedNotificationIds ?? this.selectedNotificationIds ?? const {},
      isSelectionMode: isSelectionMode ?? this.isSelectionMode ?? false,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NotificationController extends StateNotifier<NotificationState> {
  NotificationController(this._ref) : super(const NotificationState(
    selectedNotificationIds: {},
    isSelectionMode: false,
  )) {
    _initialize();
  }

  final Ref _ref;
  StreamSubscription<List<UserNotification>>? _subscription;
  final Set<String> _deletedNotificationIds = {};
  bool _isDeleting = false;
  
  // SOCKET OPTIMIZATION: Debounce timer to prevent UI lag from rapid updates
  Timer? _updateDebounceTimer;
  List<UserNotification>? _pendingNotifications;

  Future<void> _initialize() async {
    // Listen to auth state changes
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        if (next.isAuthenticated && next.userId != null) {
          // User logged in: load notifications (non-blocking)
          _handleLogin(next.userId!);
        } else {
          // User logged out: clear notifications
          _handleLogout();
        }
      }
    });

    // SOCKET OPTIMIZATION: Non-blocking initialization - don't await, let app start immediately
    final authState = _ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.userId != null) {
      // Load in background without blocking
      _loadNotificationsAsync(authState.userId!);
    }
  }
  
  // SOCKET OPTIMIZATION: Async loading helper to prevent blocking
  void _loadNotificationsAsync(String userId) {
    loadNotifications().then((_) {
      // Only subscribe after initial load completes
      _subscribeToNotifications(userId);
    }).catchError((e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
      // Still try to subscribe even if load fails
      _subscribeToNotifications(userId);
    });
  }

  /// Handle user login
  Future<void> _handleLogin(String userId) async {
    try {
      await loadNotifications();
      _subscribeToNotifications(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling login in notification controller: $e');
      }
    }
  }

  /// Handle user logout
  void _handleLogout() {
    // Cancel real-time subscription
    _subscription?.cancel();
    _subscription = null;

    // Clear notification state
    state = const NotificationState(
      selectedNotificationIds: {},
      isSelectionMode: false,
    );
  }

  Future<void> loadNotifications() async {
    if (kDebugMode) {
      print('📋 NotificationController: Loading notifications...');
    }

    state = state.copyWith(loading: true, error: null, currentPage: 1);

    try {
      final repository = _ref.read(notificationRepositoryProvider);
      var notifications = await repository.getUserNotifications();
      final unreadCount = await repository.getUnreadCount();
      final hasMore = notifications.length == 50; // If we got 50, there might be more

      // Ensure notifications are sorted by created_at descending (latest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kDebugMode) {
        print('✅ NotificationController: Loaded ${notifications.length} notifications ($unreadCount unread)');
        if (notifications.isNotEmpty) {
          print('   Latest notification: ${notifications.first.createdAt}');
          print('   Oldest notification: ${notifications.last.createdAt}');
        }
      }

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        loading: false,
        currentPage: 1,
        hasMore: hasMore,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ NotificationController: Error loading notifications: $e');
        print('   Stack trace: ${StackTrace.current}');
      }
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreNotifications() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final repository = _ref.read(notificationRepositoryProvider);
      final nextPage = state.currentPage + 1;
      final newNotifications = await repository.getUserNotificationsPaginated(
        page: nextPage,
        limit: 50,
      );
      
      final hasMore = newNotifications.length == 50;
      final allNotifications = <UserNotification>[...state.notifications, ...newNotifications];
      
      // Ensure notifications are sorted by created_at descending (latest first)
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        notifications: allNotifications,
        currentPage: nextPage,
        hasMore: hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ NotificationController: Error loading more notifications: $e');
      }
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void _subscribeToNotifications(String userId) {
    // Cancel existing subscription
    _subscription?.cancel();

    if (kDebugMode) {
      print('🔔 NotificationController: Subscribing to notifications for user $userId');
    }

    final repository = _ref.read(notificationRepositoryProvider);
    
    _subscription = repository.subscribeToNotifications(userId).listen(
      (notifications) {
        // Skip subscription updates if we're currently deleting
        if (_isDeleting) {
          if (kDebugMode) {
            print('⏸️ NotificationController: Skipping subscription update during deletion');
          }
          return;
        }

        // Filter out deleted notifications
        final filteredNotifications = notifications
            .where((n) => !_deletedNotificationIds.contains(n.id))
            .toList();

        // SOCKET OPTIMIZATION: Debounce updates to prevent UI lag (wait 300ms before updating)
        _pendingNotifications = filteredNotifications;
        
        // Cancel existing timer
        _updateDebounceTimer?.cancel();
        
        // Create new timer
        _updateDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (_pendingNotifications != null) {
            _applyNotificationUpdate(_pendingNotifications!);
            _pendingNotifications = null;
          }
        });
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ NotificationController: Error in subscription: $error');
          print('   Error type: ${error.runtimeType}');
          print('   Stack trace: ${StackTrace.current}');
        }
        state = state.copyWith(error: error.toString());
      },
    );
  }
  
  // SOCKET OPTIMIZATION: Apply updates in a debounced manner
  void _applyNotificationUpdate(List<UserNotification> notifications) {
    // Ensure notifications are sorted by created_at descending (latest first)
    final sortedNotifications = List<UserNotification>.from(notifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Update state with sorted notifications
    final unreadCount = sortedNotifications.where((n) => !n.isRead).length;
    
    if (kDebugMode) {
      print('📨 NotificationController: Applied update with ${sortedNotifications.length} notifications ($unreadCount unread)');
    }

    state = state.copyWith(
      notifications: sortedNotifications,
      unreadCount: unreadCount,
      error: null,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.markAsRead(notificationId);

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      // Ensure notifications remain sorted by created_at descending (latest first)
      updatedNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.markAllAsRead();

      // Update local state
      final updatedNotifications = state.notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();

      // Ensure notifications remain sorted by created_at descending (latest first)
      updatedNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Toggle selection of a notification
  void toggleSelection(String notificationId) {
    final currentSelectedIds = state.selectedNotificationIds ?? const {};
    final selectedIds = Set<String>.from(currentSelectedIds);
    if (selectedIds.contains(notificationId)) {
      selectedIds.remove(notificationId);
    } else {
      selectedIds.add(notificationId);
    }

    // Exit selection mode if no items are selected
    final isSelectionMode = selectedIds.isNotEmpty;

    state = state.copyWith(
      selectedNotificationIds: selectedIds,
      isSelectionMode: isSelectionMode,
    );
  }

  /// Select all notifications
  void selectAll() {
    final allIds = state.notifications.map((n) => n.id).toSet();
    state = state.copyWith(
      selectedNotificationIds: allIds,
      isSelectionMode: true,
    );
  }

  /// Get selected notification IDs with null safety
  Set<String> get selectedIds => state.selectedNotificationIds ?? const {};
  
  /// Get selection mode with null safety
  bool get isInSelectionMode => state.isSelectionMode ?? false;

  /// Clear all selections and exit selection mode
  void clearSelection() {
    state = state.copyWith(
      selectedNotificationIds: const {},
      isSelectionMode: false,
    );
  }

  /// Delete selected notifications
  Future<void> deleteSelectedNotifications() async {
    final selectedIds = state.selectedNotificationIds ?? const {};
    if (selectedIds.isEmpty) {
      return;
    }

    try {
      _isDeleting = true;
      final repository = _ref.read(notificationRepositoryProvider);
      final idsToDelete = List<String>.from(selectedIds);
      
      // Add to deleted set to filter from subscription updates
      _deletedNotificationIds.addAll(idsToDelete);
      
      // Optimistic update: remove notifications from list immediately
      final updatedNotifications = state.notifications
          .where((notification) => !idsToDelete.contains(notification.id))
          .toList();

      final updatedUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: updatedUnreadCount,
        selectedNotificationIds: const {},
        isSelectionMode: false,
        loading: true,
      );

      // Delete from database
      await repository.deleteNotifications(idsToDelete);

      if (kDebugMode) {
        print('✅ NotificationController: Deleted ${idsToDelete.length} notifications');
      }

      // Reload notifications to ensure sync with database
      await Future.delayed(const Duration(milliseconds: 500));
      await loadNotifications();

      // Clear deleted IDs after successful deletion and reload
      _deletedNotificationIds.removeAll(idsToDelete);
      _isDeleting = false;

      state = state.copyWith(loading: false);
    } catch (e) {
      if (kDebugMode) {
        print('❌ NotificationController: Error deleting notifications: $e');
      }
      
      // Remove from deleted set on error
      final idsToDelete = List<String>.from(selectedIds);
      _deletedNotificationIds.removeAll(idsToDelete);
      _isDeleting = false;
      
      // Restore state on error by reloading notifications
      await loadNotifications();
      
      state = state.copyWith(
        error: 'Failed to delete notifications: ${e.toString()}',
        loading: false,
      );
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      _isDeleting = true;
      final repository = _ref.read(notificationRepositoryProvider);
      
      // Add to deleted set to filter from subscription updates
      _deletedNotificationIds.add(notificationId);
      
      // Optimistic update: remove notification from list immediately
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      final updatedUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: updatedUnreadCount,
        loading: true,
      );

      // Delete from database
      await repository.deleteNotification(notificationId);

      if (kDebugMode) {
        print('✅ NotificationController: Deleted notification $notificationId');
      }

      // Reload notifications to ensure sync with database
      await Future.delayed(const Duration(milliseconds: 500));
      await loadNotifications();

      // Clear deleted ID after successful deletion and reload
      _deletedNotificationIds.remove(notificationId);
      _isDeleting = false;

      state = state.copyWith(loading: false);
    } catch (e) {
      if (kDebugMode) {
        print('❌ NotificationController: Error deleting notification: $e');
      }
      
      // Remove from deleted set on error
      _deletedNotificationIds.remove(notificationId);
      _isDeleting = false;
      
      // Restore state on error by reloading notifications
      await loadNotifications();
      
      state = state.copyWith(
        error: 'Failed to delete notification: ${e.toString()}',
        loading: false,
      );
    }
  }

  /// Enter selection mode and select a notification
  void enterSelectionMode(String notificationId) {
    state = state.copyWith(
      selectedNotificationIds: {notificationId},
      isSelectionMode: true,
    );
  }

  @override
  void dispose() {
    // SOCKET OPTIMIZATION: Clean up debounce timer
    _updateDebounceTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  return NotificationController(ref);
});

// Provider for unread count only (for badge display)
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationControllerProvider).unreadCount;
});

