import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../../application/admin_fcm_notification_controller.dart';
import '../../../notifications/data/notification_model.dart';

/// Notification dropdown panel widget
class AdminNotificationPanel extends ConsumerWidget {
  const AdminNotificationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(adminFcmNotificationControllerProvider);
    final notifications = notificationState.recentNotifications;
    final unreadCount = notificationState.unreadCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Calculate responsive width: max 380px, min 280px, or 90% of screen width
        final panelWidth = (screenWidth * 0.9).clamp(280.0, 380.0);

        return Container(
          width: panelWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      ref
                          .read(adminFcmNotificationControllerProvider.notifier)
                          .markAllAsRead();
                    },
                    child: const Text('Mark all as read'),
                  ),
                IconButton(
                  icon: const Icon(Ionicons.close),
                  onPressed: () {
                    ref
                        .read(adminFcmNotificationControllerProvider.notifier)
                        .hidePanel();
                  },
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Notifications list
          Flexible(
            child: notifications.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Ionicons.notifications_off_outline,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationItem(
                        notification: notification,
                        onTap: () {
                          _handleNotificationTap(context, ref, notification);
                        },
                        onMarkAsRead: () {
                          ref
                              .read(adminFcmNotificationControllerProvider.notifier)
                              .markAsRead(notification.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
        );
      },
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    UserNotification notification,
  ) {
    // Mark as read
    ref
        .read(adminFcmNotificationControllerProvider.notifier)
        .markAsRead(notification.id);

    // Hide panel
    ref
        .read(adminFcmNotificationControllerProvider.notifier)
        .hidePanel();

    // Navigate based on type
    switch (notification.type) {
      case NotificationType.orderStatusChanged:
      case NotificationType.orderPlaced:
        if (notification.orderId != null) {
          context.push('/admin/orders/${notification.orderId}');
        } else {
          context.push('/admin/orders');
        }
        break;
      case NotificationType.chatMessage:
        if (notification.conversationId != null) {
          context.push('/admin/chat/${notification.conversationId}');
        } else {
          context.push('/admin/chat');
        }
        break;
      default:
        break;
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final UserNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isUnread
            ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getIconColor(context).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                color: _getIconColor(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.orderStatusChanged:
      case NotificationType.orderPlaced:
        return Ionicons.receipt_outline;
      case NotificationType.chatMessage:
        return Ionicons.chatbubbles_outline;
      default:
        return Ionicons.notifications_outline;
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (notification.type) {
      case NotificationType.orderStatusChanged:
      case NotificationType.orderPlaced:
        return Colors.green;
      case NotificationType.chatMessage:
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

