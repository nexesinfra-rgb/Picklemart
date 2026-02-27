import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import 'admin_auth_controller.dart';
import '../data/admin_features.dart';
import '../../../features/notifications/data/notification_model.dart';

/// State for admin FCM notifications
class AdminFcmNotificationState {
  final int unreadCount;
  final List<UserNotification> recentNotifications;
  final bool isLoading;
  final String? error;
  final bool isPanelVisible;

  const AdminFcmNotificationState({
    this.unreadCount = 0,
    this.recentNotifications = const [],
    this.isLoading = false,
    this.error,
    this.isPanelVisible = false,
  });

  AdminFcmNotificationState copyWith({
    int? unreadCount,
    List<UserNotification>? recentNotifications,
    bool? isLoading,
    String? error,
    bool? isPanelVisible,
    bool clearError = false,
  }) {
    return AdminFcmNotificationState(
      unreadCount: unreadCount ?? this.unreadCount,
      recentNotifications: recentNotifications ?? this.recentNotifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isPanelVisible: isPanelVisible ?? this.isPanelVisible,
    );
  }
}

/// Controller for managing admin FCM notifications
class AdminFcmNotificationController
    extends StateNotifier<AdminFcmNotificationState> {
  final Ref _ref;
  final SupabaseClient _supabase;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  AdminFcmNotificationController(this._ref, this._supabase)
    : super(const AdminFcmNotificationState()) {
    _initialize();
  }

  void _initialize() {
    // Listen to admin auth state changes
    _ref.listen<AdminAuthState>(adminAuthControllerProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        if (next.isAuthenticated && next.adminUser != null) {
          // Admin is logged in, load notifications
          loadNotifications();
          _subscribeToNotifications(next.adminUser!.id);
        } else {
          _unsubscribe();
          state = const AdminFcmNotificationState();
        }
      }
    });

    // Check if already authenticated
    final adminAuthState = _ref.read(adminAuthControllerProvider);
    if (adminAuthState.isAuthenticated && adminAuthState.adminUser != null) {
      loadNotifications();
      _subscribeToNotifications(adminAuthState.adminUser!.id);
    }
  }

  /// Load notifications for admin user
  Future<void> loadNotifications() async {
    final adminAuthState = _ref.read(adminAuthControllerProvider);
    if (!adminAuthState.isAuthenticated || adminAuthState.adminUser == null) {
      return;
    }

    final adminId = adminAuthState.adminUser!.id;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Get unread count
      final unreadCountResponse = await _supabase
          .from('user_notifications')
          .select('id')
          .eq('user_id', adminId)
          .eq('is_read', false);

      final unreadCount = (unreadCountResponse as List).length;

      // Get recent notifications (last 20)
      final notificationsResponse = await _supabase
          .from('user_notifications')
          .select('*')
          .eq('user_id', adminId)
          .order('created_at', ascending: false)
          .limit(20);

      final notifications =
          (notificationsResponse as List)
              .map(
                (json) =>
                    UserNotification.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      state = state.copyWith(
        unreadCount: unreadCount,
        recentNotifications: notifications,
        isLoading: false,
      );

      if (kDebugMode) {
        print(
          '✅ AdminFcmNotificationController: Loaded ${notifications.length} notifications, $unreadCount unread',
        );
        print('   Admin ID: $adminId');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ AdminFcmNotificationController: Error loading notifications: $e',
        );
        print('   Admin ID: $adminId');
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications',
      );
    }
  }

  /// Subscribe to real-time notification updates
  void _subscribeToNotifications(String userId) {
    _unsubscribe();

    final features = _ref.read(adminFeaturesProvider);
    if (!features.notificationsEnabled) return;

    try {
      final stream = _supabase
          .from('user_notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _subscription = stream.listen(
        (data) {
          final notifications =
              data.map((json) => UserNotification.fromJson(json)).toList();

          final unreadCount = notifications.where((n) => !n.isRead).length;

          if (kDebugMode) {
            print(
              '📨 AdminFcmNotificationController: Received ${notifications.length} notifications via Realtime, $unreadCount unread',
            );
          }

          state = state.copyWith(
            unreadCount: unreadCount,
            recentNotifications: notifications.take(20).toList(),
          );
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ AdminFcmNotificationController: Stream error: $error');
          }
        },
      );

      if (kDebugMode) {
        print(
          '✅ AdminFcmNotificationController: Subscribed to Realtime for user: $userId',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AdminFcmNotificationController: Error subscribing: $e');
      }
    }
  }

  /// Unsubscribe from notifications
  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Toggle notification panel visibility
  void togglePanel() {
    state = state.copyWith(isPanelVisible: !state.isPanelVisible);
  }

  /// Show notification panel
  void showPanel() {
    state = state.copyWith(isPanelVisible: true);
  }

  /// Hide notification panel
  void hidePanel() {
    state = state.copyWith(isPanelVisible: false);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final adminAuthState = _ref.read(adminAuthControllerProvider);
    if (!adminAuthState.isAuthenticated || adminAuthState.adminUser == null) {
      return;
    }

    final adminId = adminAuthState.adminUser!.id;

    try {
      await _supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', adminId);

      // Update local state optimistically
      final updatedNotifications =
          state.recentNotifications.map((n) {
            if (n.id == notificationId) {
              return UserNotification(
                id: n.id,
                userId: n.userId,
                type: n.type,
                title: n.title,
                message: n.message,
                orderId: n.orderId,
                conversationId: n.conversationId,
                ratingId: n.ratingId,
                isRead: true,
                createdAt: n.createdAt,
              );
            }
            return n;
          }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        unreadCount: unreadCount,
        recentNotifications: updatedNotifications,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ AdminFcmNotificationController: Error marking as read: $e');
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final adminAuthState = _ref.read(adminAuthControllerProvider);
    if (!adminAuthState.isAuthenticated || adminAuthState.adminUser == null) {
      return;
    }

    final adminId = adminAuthState.adminUser!.id;

    try {
      await _supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', adminId)
          .eq('is_read', false);

      // Update local state
      final updatedNotifications =
          state.recentNotifications.map((n) {
            return UserNotification(
              id: n.id,
              userId: n.userId,
              type: n.type,
              title: n.title,
              message: n.message,
              orderId: n.orderId,
              conversationId: n.conversationId,
              ratingId: n.ratingId,
              isRead: true,
              createdAt: n.createdAt,
            );
          }).toList();

      state = state.copyWith(
        unreadCount: 0,
        recentNotifications: updatedNotifications,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ AdminFcmNotificationController: Error marking all as read: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}

/// Provider for admin FCM notification controller
final adminFcmNotificationControllerProvider = StateNotifierProvider<
  AdminFcmNotificationController,
  AdminFcmNotificationState
>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AdminFcmNotificationController(ref, supabase);
});
