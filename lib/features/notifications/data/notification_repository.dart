import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_model.dart';
import '../../auth/application/auth_controller.dart';

abstract class NotificationRepository {
  Future<List<UserNotification>> getUserNotifications();
  Future<List<UserNotification>> getUserNotificationsPaginated({int page = 1, int limit = 50});
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<int> getUnreadCount();
  Stream<List<UserNotification>> subscribeToNotifications(String userId);
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? orderId,
    String? conversationId,
  });
  Future<void> deleteNotification(String notificationId);
  Future<int> deleteNotifications(List<String> notificationIds);
  
  // Connection status for debugging
  Map<String, dynamic> getConnectionStatus() => {};
}

class NotificationRepositorySupabase implements NotificationRepository {
  final SupabaseClient _supabase;
  final Ref _ref;
  
  // Connection state tracking
  bool _supabaseRealtimeConnected = false;
  StreamSubscription? _supabaseSubscription;

  NotificationRepositorySupabase(this._supabase, this._ref);

  @override
  Future<List<UserNotification>> getUserNotifications() async {
    try {
      final authState = _ref.read(authControllerProvider);
      if (!authState.isAuthenticated || authState.userId == null) {
        if (kDebugMode) {
          print('📋 Notifications: User not authenticated, returning empty list');
        }
        return [];
      }
      final userId = authState.userId!;

      if (kDebugMode) {
        print('📋 Notifications: Fetching notifications for user $userId');
      }

      // SOCKET OPTIMIZATION: Limit to last 50 notifications for faster initial load
      // Real-time subscription will update with all notifications
      final response = await _supabase
          .from('user_notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final notificationsData = List<Map<String, dynamic>>.from(response);
      final notifications = notificationsData
          .map((data) => UserNotification.fromJson(data))
          .toList();

      // Ensure notifications are sorted by created_at descending (latest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kDebugMode) {
        print('✅ Notifications: Fetched ${notifications.length} notifications (limited to 50 for performance)');
        if (notifications.isNotEmpty) {
          print('   Latest notification: ${notifications.first.createdAt}');
          print('   Oldest notification: ${notifications.last.createdAt}');
        }
      }

      return notifications;
    } catch (e) {
      if (kDebugMode) {
        final errorString = e.toString();
        final isTableMissing = errorString.contains('Could not find the table') ||
            errorString.contains('does not exist') ||
            errorString.contains('PGRST205');
        
        print('❌ Notifications: Error in getUserNotifications: $e');
        print('   Error type: ${e.runtimeType}');
        print('   Stack trace: ${StackTrace.current}');
        
        if (isTableMissing) {
          print('');
          print('⚠️  ⚠️  ⚠️  CRITICAL ERROR: TABLE MISSING ⚠️  ⚠️  ⚠️');
          print('   The user_notifications table does not exist in your Supabase database!');
          print('   This is why notifications are not working.');
          print('');
          print('   🔧 TO FIX:');
          print('   1. Open Supabase Dashboard → SQL Editor');
          print('   2. Open file: CREATE_NOTIFICATIONS_TABLE_COMPLETE.sql');
          print('   3. Copy entire contents and paste into SQL Editor');
          print('   4. Click "Run" to create the table');
          print('   5. Restart your Flutter app');
          print('');
        }
      }
      return [];
    }
  }

  /// Get user notifications with pagination
  @override
  Future<List<UserNotification>> getUserNotificationsPaginated({int page = 1, int limit = 50}) async {
    try {
      final authState = _ref.read(authControllerProvider);
      if (!authState.isAuthenticated || authState.userId == null) {
        if (kDebugMode) {
          print('📋 Notifications: User not authenticated, returning empty list');
        }
        return [];
      }
      final userId = authState.userId!;

      if (kDebugMode) {
        print('📋 Notifications: Fetching paginated notifications for user $userId (page: $page, limit: $limit)');
      }

      final startIndex = (page - 1) * limit;
      final response = await _supabase
          .from('user_notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final notificationsData = List<Map<String, dynamic>>.from(response);
      final notifications = notificationsData
          .map((data) => UserNotification.fromJson(data))
          .toList();

      // Ensure notifications are sorted by created_at descending (latest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kDebugMode) {
        print('✅ Notifications: Fetched ${notifications.length} notifications (page $page)');
      }

      return notifications;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Notifications: Error in getUserNotificationsPaginated: $e');
      }
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      final authState = _ref.read(authControllerProvider);
      if (!authState.isAuthenticated || authState.userId == null) {
        return;
      }
      final userId = authState.userId!;

      await _supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);

      if (kDebugMode) {
        print('✅ Notifications: Marked notification $notificationId as read');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Notifications: Error in markAsRead: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final authState = _ref.read(authControllerProvider);
      if (!authState.isAuthenticated || authState.userId == null) {
        return;
      }
      final userId = authState.userId!;

      await _supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      if (kDebugMode) {
        print('✅ Notifications: Marked all notifications as read for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Notifications: Error in markAllAsRead: $e');
      }
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final authState = _ref.read(authControllerProvider);
      if (!authState.isAuthenticated || authState.userId == null) {
        return 0;
      }
      final userId = authState.userId!;

      // OPTIMIZATION: Select only 'id' field (minimal data transfer)
      // The database index on (user_id, is_read) makes this query fast
      // Even with many notifications, this is efficient due to proper indexing
      final response = await _supabase
          .from('user_notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      final count = (response as List).length;
      
      if (kDebugMode) {
        print('📊 Notifications: Unread count for user $userId: $count');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Notifications: Error in getUnreadCount: $e');
      }
      return 0;
    }
  }

  @override
  Stream<List<UserNotification>> subscribeToNotifications(String userId) {
    final controller = StreamController<List<UserNotification>>();
    
    if (kDebugMode) {
      print('🔔 Notifications: Starting Supabase Realtime subscription for user $userId');
    }

    // Initial fetch
    getUserNotifications().then((notifications) {
      if (!controller.isClosed) {
        if (kDebugMode) {
          print('📥 Notifications: Initial fetch completed, ${notifications.length} notifications');
        }
        controller.add(notifications);
      }
    }).catchError((error) {
      if (kDebugMode) {
        print('❌ Notifications: Initial fetch error: $error');
      }
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Setup Supabase Realtime subscription
    _setupSupabaseRealtime(userId, controller);

    // Setup cleanup
    controller.onCancel = () {
      _cleanupSubscriptions();
    };

    return controller.stream;
  }

  /// Setup Supabase Realtime subscription
  void _setupSupabaseRealtime(
    String userId,
    StreamController<List<UserNotification>> controller,
  ) {
    if (controller.isClosed) return;

    try {
      if (kDebugMode) {
        print('🔄 Notifications: Setting up Supabase Realtime subscription');
      }

      _supabaseSubscription?.cancel();
      
      final subscription = _supabase
          .from('user_notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .listen(
        (data) {
          try {
            _supabaseRealtimeConnected = true;

            // SOCKET OPTIMIZATION: Process in microtask to prevent blocking UI thread
            scheduleMicrotask(() {
              try {
                final notifications = data
                    .map((item) => UserNotification.fromJson(item))
                    .toList();

                // Ensure notifications are sorted by created_at descending (latest first)
                notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (!controller.isClosed) {
                  controller.add(notifications);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('❌ Notifications: Error processing notifications: $e');
                }
                if (!controller.isClosed) {
                  controller.addError(e);
                }
              }
            });
          } catch (e) {
            if (kDebugMode) {
              print('❌ Notifications: Error in stream handler: $e');
            }
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        },
        onError: (error) {
          _supabaseRealtimeConnected = false;
          
          if (kDebugMode) {
            print('❌ Notifications: Supabase Realtime error: $error');
            print('   Error type: ${error.runtimeType}');
          }

          if (!controller.isClosed) {
            controller.addError(error);
          }
        },
        cancelOnError: false,
      );

      _supabaseSubscription = subscription;
      
      // SOCKET OPTIMIZATION: Mark as connected immediately (no delay)
      _supabaseRealtimeConnected = true;
      
      if (kDebugMode) {
        print('✅ Notifications: Supabase Realtime subscription active');
      }
    } catch (e) {
      _supabaseRealtimeConnected = false;
      if (kDebugMode) {
        print('❌ Notifications: Failed to create Supabase Realtime subscription: $e');
      }
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  /// Get connection status for debugging
  @override
  Map<String, dynamic> getConnectionStatus() {
    try {
      return {
        'supabaseRealtime': _supabaseRealtimeConnected,
        'subscriptionActive': _supabaseSubscription != null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Notifications: Error getting connection status: $e');
      }
      return {
        'error': e.toString(),
      };
    }
  }

  /// Cleanup all subscriptions
  void _cleanupSubscriptions() {
    _supabaseSubscription?.cancel();
    _supabaseSubscription = null;
    _supabaseRealtimeConnected = false;
    
    if (kDebugMode) {
      print('🧹 Notifications: Cleaned up Supabase Realtime subscription');
    }
  }

  @override
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    String? orderId,
    String? conversationId,
  }) async {
    try {
      await _supabase.from('user_notifications').insert({
        'user_id': userId,
        'type': type.value,
        'title': title,
        'message': message,
        'order_id': orderId,
        'conversation_id': conversationId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      if (kDebugMode) {
        print('✅ Notifications: Created notification for user: $userId, type: ${type.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        final errorString = e.toString();
        final isRlsError = errorString.contains('new row violates row-level security') ||
            errorString.contains('RLS') ||
            errorString.contains('policy') ||
            errorString.contains('permission denied');
        
        print('❌ Notifications: Error creating notification:');
        print('   Error Type: ${e.runtimeType}');
        print('   Error Message: $errorString');
        print('   Target User ID: $userId');
        print('   Notification Type: ${type.value}');
        print('   Order ID: $orderId');
        print('   Is RLS Policy Error: $isRlsError');
        
        if (isRlsError) {
          print('   ⚠️  RLS POLICY VIOLATION DETECTED!');
          print('   ⚠️  This usually means the admin INSERT policy is missing.');
          print('   ⚠️  Please run: RUN_THIS_FIX.sql in Supabase SQL Editor');
        }
      }
      // Don't rethrow - notification creation failure shouldn't break order flow
    }
  }

  /// Helper method to generate order placed notification message
  static String getOrderPlacedMessage(String orderNumber) {
    return 'Your order $orderNumber has been placed successfully. We will process it soon.';
  }

  /// Helper method to generate order status changed notification message
  static String getOrderStatusChangedMessage(String orderNumber, String statusLabel) {
    String message = 'Your order $orderNumber status has been updated to: $statusLabel';
    // Add rating prompt for delivered orders
    if (statusLabel.toLowerCase() == 'delivered') {
      message += '. Please rate the products you received!';
    }
    return message;
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      final authState = _ref.read(authControllerProvider);
      if (!authState.isAuthenticated || authState.userId == null) {
        return;
      }
      final userId = authState.userId!;

      await _supabase
          .from('user_notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', userId);

      if (kDebugMode) {
        print('✅ Notifications: Deleted notification $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Notifications: Error in deleteNotification: $e');
      }
      rethrow;
    }
  }

  @override
  Future<int> deleteNotifications(List<String> notificationIds) async {
    try {
      final authState = _ref.read(authControllerProvider);
      if (!authState.isAuthenticated || authState.userId == null) {
        return 0;
      }
      final userId = authState.userId!;

      if (notificationIds.isEmpty) {
        return 0;
      }

      // Delete multiple notifications in a single query
      final response = await _supabase
          .from('user_notifications')
          .delete()
          .eq('user_id', userId)
          .inFilter('id', notificationIds);

      final deletedCount = notificationIds.length;
      
      if (kDebugMode) {
        print('✅ Notifications: Deleted $deletedCount notifications for user $userId');
      }

      return deletedCount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Notifications: Error in deleteNotifications: $e');
      }
      rethrow;
    }
  }
}

// Keep SocketNotificationService file for backward compatibility but it's no longer used
// The service is deprecated in favor of Supabase Realtime
