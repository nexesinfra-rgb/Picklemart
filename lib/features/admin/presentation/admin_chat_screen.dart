import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../chat/application/conversation_controller.dart';
import '../../chat/application/chat_controller.dart';
import '../../chat/data/chat_models.dart';
import '../../../core/ui/safe_scaffold.dart';
import 'widgets/admin_auth_guard.dart';

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationControllerProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh conversations when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      ref.read(conversationControllerProvider.notifier).loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(conversationControllerProvider);

    return AdminAuthGuard(
      child: SafeScaffold(
        appBar: AppBar(
          title: const Text('Chat Conversations'),
          leading: IconButton(
            icon: const Icon(Ionicons.arrow_back_outline),
            onPressed: () {
              // Check if we can pop the navigation stack
              if (context.canPop()) {
                context.pop();
              } else {
                // Fallback to admin dashboard if stack is broken
                context.go('/admin/dashboard');
              }
            },
          ),
          actions: [
            // Status filter
            PopupMenuButton<ConversationStatus?>(
              icon: const Icon(Ionicons.filter_outline),
              onSelected: (status) {
                ref.read(conversationControllerProvider.notifier).setStatusFilter(status);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('All'),
                ),
                const PopupMenuItem(
                  value: ConversationStatus.active,
                  child: Text('Active'),
                ),
                const PopupMenuItem(
                  value: ConversationStatus.closed,
                  child: Text('Closed'),
                ),
                const PopupMenuItem(
                  value: ConversationStatus.archived,
                  child: Text('Archived'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Ionicons.search_outline),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Ionicons.close_outline),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(conversationControllerProvider.notifier).setSearchQuery(null);
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  ref.read(conversationControllerProvider.notifier).setSearchQuery(value.isEmpty ? null : value);
                },
              ),
            ),
            // Conversations list
            Expanded(
              child: conversationsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : conversationsState.conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Ionicons.chatbubbles_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No conversations found',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(conversationControllerProvider.notifier).loadConversations();
                          },
                          child: ListView.builder(
                            itemCount: conversationsState.conversations.length,
                            itemBuilder: (context, index) {
                              final convWithUser = conversationsState.conversations[index];
                              return _buildConversationTile(context, convWithUser);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ConversationWithUser convWithUser) {
    final conversation = convWithUser.conversation;
    final hasUnread = convWithUser.unreadCount > 0;

    return GestureDetector(
      onDoubleTap: () {
        // Mark messages as read on double-click
        _markConversationAsRead(conversation.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            convWithUser.userName?.substring(0, 1).toUpperCase() ?? 'U',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          convWithUser.userName ?? convWithUser.userEmail ?? 'Unknown User',
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          conversation.lastMessageAt != null
              ? _formatLastMessageTime(conversation.lastMessageAt!)
              : 'No messages yet',
        ),
        trailing: hasUnread
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  convWithUser.unreadCount > 9 ? '9+' : '${convWithUser.unreadCount}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Icon(
                conversation.status == ConversationStatus.active
                    ? Ionicons.chatbubble_outline
                    : conversation.status == ConversationStatus.closed
                        ? Ionicons.checkmark_circle_outline
                        : Ionicons.archive_outline,
              ),
        onTap: () async {
          // Navigate to chat detail
          await context.push('/admin/chat/${conversation.id}');
          // Refresh conversation list when returning from detail screen
          if (mounted) {
            ref.read(conversationControllerProvider.notifier).loadConversations();
          }
        },
      ),
    );
  }

  Future<void> _markConversationAsRead(String conversationId) async {
    try {
      // Load messages for this conversation temporarily to mark as read
      await ref.read(chatControllerProvider.notifier).loadMessages(conversationId);
      
      // Mark messages as read
      await ref.read(chatControllerProvider.notifier).markAsRead();
      
      // Reload conversations to update unread count
      await ref.read(conversationControllerProvider.notifier).loadConversations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as read: $e')),
        );
      }
    }
  }

  String _formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

