import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../application/notification_controller.dart';
import '../data/notification_model.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../admin/data/admin_features.dart';
import '../../ratings/data/rating_repository.dart';
import '../../../core/providers/supabase_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationControllerProvider);
    final notifications = notificationState.notifications;
    final unreadCount = notificationState.unreadCount;
    final isSelectionMode = notificationState.isSelectionMode ?? false;
    final selectedIds = notificationState.selectedNotificationIds ?? const {};

    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    final sectionSpacing = Responsive.getSectionSpacing(width);

    return SafeScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading:
            isSelectionMode
                ? IconButton(
                  icon: const Icon(Ionicons.close_outline),
                  onPressed: () {
                    ref
                        .read(notificationControllerProvider.notifier)
                        .clearSelection();
                  },
                )
                : IconButton(
                  icon: const Icon(Ionicons.arrow_back_outline),
                  onPressed:
                      () => NavigationHelper.handleBackNavigation(
                        context,
                        ref: ref,
                      ),
                ),
        title:
            isSelectionMode
                ? Text('${selectedIds.length} selected')
                : const Text('Notifications'),
        actions: [
          if (isSelectionMode) ...[
            if (selectedIds.isNotEmpty)
              IconButton(
                icon: const Icon(Ionicons.trash_outline),
                onPressed: () => _showDeleteConfirmation(context, ref),
                tooltip: 'Delete',
              ),
          ] else ...[
            if (unreadCount > 0)
              TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(notificationControllerProvider.notifier)
                      .markAllAsRead();
                },
                icon: const Icon(Ionicons.checkmark_done_outline, size: 18),
                label: const Text('Mark all read'),
              ),
          ],
        ],
      ),
      body:
          notificationState.loading && notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? Center(
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Ionicons.notifications_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      Text(
                        'No notifications',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: cardPadding * 0.5),
                      Text(
                        'You\'ll receive notifications about your orders here',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(notificationControllerProvider.notifier)
                      .refresh();
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(cardPadding),
                  itemCount:
                      notifications.length +
                      (notificationState.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show load more button at the end
                    if (index == notifications.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: cardPadding),
                        child:
                            notificationState.isLoadingMore
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : OutlinedButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(
                                          notificationControllerProvider
                                              .notifier,
                                        )
                                        .loadMoreNotifications();
                                  },
                                  icon: const Icon(Ionicons.refresh_outline),
                                  label: const Text('Load More'),
                                ),
                      );
                    }

                    final notification = notifications[index];
                    final isSelected = selectedIds.contains(notification.id);

                    // Create the notification item widget
                    final notificationWidget = _NotificationItem(
                      notification: notification,
                      isSelected: isSelected,
                      isSelectionMode: isSelectionMode,
                      onTap: () {
                        if (isSelectionMode) {
                          // Toggle selection in selection mode
                          ref
                              .read(notificationControllerProvider.notifier)
                              .toggleSelection(notification.id);
                        } else {
                          // Normal mode: navigate to relevant page
                          _handleNotificationTap(context, ref, notification);
                        }
                      },
                      onLongPress: () {
                        // Long-press enters selection mode
                        if (!isSelectionMode) {
                          ref
                              .read(notificationControllerProvider.notifier)
                              .enterSelectionMode(notification.id);
                        } else {
                          ref
                              .read(notificationControllerProvider.notifier)
                              .toggleSelection(notification.id);
                        }
                      },
                    );

                    // Only enable swipe-to-delete when NOT in selection mode
                    if (isSelectionMode) {
                      return notificationWidget;
                    }

                    // Wrap in Dismissible for swipe-to-delete
                    return Dismissible(
                      key: Key('notification_${notification.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: cardPadding),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Ionicons.trash_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Delete Notification'),
                                content: const Text(
                                  'Are you sure you want to delete this notification?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                        );
                        return confirmed ?? false;
                      },
                      onDismissed: (direction) async {
                        // Delete the notification
                        try {
                          await ref
                              .read(notificationControllerProvider.notifier)
                              .deleteNotification(notification.id);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notification deleted'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to delete notification: ${e.toString()}',
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            // Reload to restore the notification on error
                            await ref
                                .read(notificationControllerProvider.notifier)
                                .loadNotifications();
                          }
                        }
                      },
                      child: notificationWidget,
                    );
                  },
                ),
              ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    UserNotification notification,
  ) async {
    // Mark as read on tap
    if (!notification.isRead) {
      await ref
          .read(notificationControllerProvider.notifier)
          .markAsRead(notification.id);
    }

    try {
      switch (notification.type) {
        case NotificationType.orderPlaced:
          // Navigate to order detail page
          if (notification.orderId != null) {
            context.pushNamed(
              'order-detail',
              pathParameters: {'id': notification.orderId!},
            );
          } else {
            _showNavigationError(context, 'Order information not available');
          }
          break;

        case NotificationType.orderStatusChanged:
          // Navigate to order detail page
          if (notification.orderId != null) {
            context.pushNamed(
              'order-detail',
              pathParameters: {'id': notification.orderId!},
            );
          } else {
            _showNavigationError(context, 'Order information not available');
          }
          break;

        case NotificationType.chatMessage:
          // Navigate to chat screen with conversation ID
          if (notification.conversationId != null) {
            context.pushNamed(
              'chat',
              queryParameters: {'conversationId': notification.conversationId!},
            );
          } else {
            // Navigate to general chat screen if no conversation ID
            context.pushNamed('chat');
          }
          break;

        case NotificationType.ratingReply:
          // Fetch rating to get product ID, then navigate to product detail
          if (notification.ratingId != null) {
            final supabase = ref.read(supabaseClientProvider);
            final repository = RatingRepository(supabase);
            final rating = await repository.getRatingById(
              notification.ratingId!,
            );

            if (rating != null) {
              context.pushNamed(
                'product',
                pathParameters: {'id': rating.productId},
              );
            } else {
              _showNavigationError(context, 'Rating information not found');
            }
          } else {
            _showNavigationError(context, 'Rating information not available');
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        _showNavigationError(context, 'Failed to navigate: ${e.toString()}');
      }
    }
  }

  void _showNavigationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedIds =
        ref.read(notificationControllerProvider).selectedNotificationIds ??
        const {};
    final selectedCount = selectedIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Notifications'),
            content: Text(
              selectedCount == 1
                  ? 'Are you sure you want to delete this notification?'
                  : 'Are you sure you want to delete $selectedCount notifications?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(notificationControllerProvider.notifier)
            .deleteSelectedNotifications();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                selectedCount == 1
                    ? 'Notification deleted'
                    : '$selectedCount notifications deleted',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete notifications: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final UserNotification notification;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _NotificationItem({
    required this.notification,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = Responsive.getCardPadding(
      MediaQuery.of(context).size.width,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: cardPadding * 0.75),
      child: Card(
        elevation: notification.isRead ? 1 : 2,
        margin: EdgeInsets.zero,
        color:
            isSelected
                ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                : notification.isRead
                ? null
                : Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.1),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox or Icon
                  if (isSelectionMode) ...[
                    Checkbox(value: isSelected, onChanged: (_) => onTap()),
                    SizedBox(width: cardPadding * 0.5),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getIconColor(context).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(notification.type),
                        color: _getIconColor(context),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: cardPadding),
                  ],
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight:
                                      notification.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: cardPadding * 0.25),
                        Text(
                          notification.message,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: cardPadding * 0.5),
                        Text(
                          _formatDate(notification.createdAt),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
        return Ionicons.checkmark_circle_outline;
      case NotificationType.orderStatusChanged:
        return Ionicons.information_circle_outline;
      case NotificationType.chatMessage:
        return Ionicons.chatbubble_outline;
      case NotificationType.ratingReply:
        return Ionicons.chatbubble_ellipses_outline;
    }
  }

  Color _getIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  String _formatDate(DateTime date) {
    // Ensure both timestamps are in local time for accurate comparison
    // DateTime.now() is already in local time
    final now = DateTime.now();
    // Convert date to local time if it's in UTC (safeguard, though fromJson should already handle this)
    final localDate = date.isUtc ? date.toLocal() : date;
    final difference = now.difference(localDate);

    // Handle negative differences (shouldn't happen, but safeguard)
    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(localDate);
    }
  }
}
