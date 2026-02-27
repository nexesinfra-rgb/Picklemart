import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import '../../chat/application/chat_controller.dart';
import '../../chat/application/conversation_controller.dart';
import '../../chat/data/chat_models.dart';
import '../../chat/presentation/widgets/chat_message_bubble.dart';
import '../../chat/presentation/widgets/product_selector_widget.dart';
import '../../chat/presentation/widgets/typing_indicator_dots.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/ui/safe_scaffold.dart';
import 'widgets/admin_auth_guard.dart';

class AdminChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const AdminChatDetailScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends ConsumerState<AdminChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  Timer? _markAsReadDebounceTimer;
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Listen to text changes for typing indicator
    _messageController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversation();
    });
  }

  void _onTextChanged() {
    if (!mounted) return; // Check if widget is still mounted
    
    final text = _messageController.text;
    // Trigger typing indicator
    if (text.isNotEmpty) {
      ref.read(chatControllerProvider.notifier).startTyping();
    } else {
      ref.read(chatControllerProvider.notifier).stopTyping();
    }
  }

  void _onScroll() {
    _updateScrollPosition();
    _markMessagesAsReadIfAtBottom();
  }

  void _updateScrollPosition() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 50.0; // pixels from bottom
    
    final isNearBottom = (maxScroll - currentScroll) <= threshold;
    if (_isAtBottom != isNearBottom) {
      setState(() {
        _isAtBottom = isNearBottom;
      });
    }
  }

  void _markMessagesAsReadIfAtBottom() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 100.0; // pixels from bottom
    
    // Check if user is near or at the bottom
    final isNearBottom = (maxScroll - currentScroll) <= threshold;
    
    if (isNearBottom) {
      // Debounce to avoid multiple calls
      _markAsReadDebounceTimer?.cancel();
      _markAsReadDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _markMessagesAsRead();
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    final chatState = ref.read(chatControllerProvider);
    final supabase = ref.read(supabaseClientProvider);
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      return;
    }

    if (chatState.conversation == null) {
      return;
    }

    if (chatState.messages.isEmpty) {
      return;
    }

    if (chatState.isLoading) {
      return;
    }

    // Check if there are actually unread messages before marking
    final hasUnreadMessages = chatState.messages.any((message) =>
        message.senderId != currentUserId && message.readAt == null);

    if (!hasUnreadMessages) {
      return;
    }

    try {
      await ref.read(chatControllerProvider.notifier).markAsRead();
      
      // Refresh conversation list to update unread count immediately
      try {
        await ref.read(conversationControllerProvider.notifier).loadConversations();
      } catch (e) {
        // Error handled silently
      }
    } catch (e) {
      // Error handled silently
    }
  }

  void _loadConversation() async {
    // Assign admin to conversation if not already assigned
    final supabase = ref.read(supabaseClientProvider);
    final adminId = supabase.auth.currentUser?.id;
    if (adminId != null) {
      try {
        await ref.read(conversationControllerProvider.notifier).assignAdmin(
              widget.conversationId,
              adminId,
            );
      } catch (e) {
        // Ignore assignment errors - conversation might already be assigned
      }
    }

    // Load messages for this conversation (conversation will be loaded automatically)
    // This will also set up typing status subscription via _subscribeToMessages -> _subscribeToTypingStatus
    await ref.read(chatControllerProvider.notifier).loadMessages(widget.conversationId);
  }

  @override
  void dispose() {
    // Safety net: mark messages as read before disposing
    final chatState = ref.read(chatControllerProvider);
    if (chatState.conversation != null && 
        chatState.messages.isNotEmpty && 
        !chatState.isLoading) {
      // Fire and forget - don't wait for completion
      // Capture notifiers before async operations
      final chatNotifier = ref.read(chatControllerProvider.notifier);
      final conversationNotifier = ref.read(conversationControllerProvider.notifier);
      
      chatNotifier.markAsRead().then((_) {
        // Refresh conversation list after marking as read
        conversationNotifier.loadConversations();
      }).catchError((e) {
        // Error handled silently
      });
    }
    _markAsReadDebounceTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }


  void _scrollToBottom({bool immediate = false}) {
    if (_scrollController.hasClients) {
      if (immediate) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      // Update scroll position state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollPosition();
      });
    }
  }

  Future<void> _sendMessage() async {
    if (!mounted) return; // Check if widget is still mounted
    
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    await ref.read(chatControllerProvider.notifier).sendTextMessage(content);
    _scrollToBottom(immediate: true);
    
    // Mark messages as read after sending reply
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _markMessagesAsRead();
        }
      });
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        await ref.read(chatControllerProvider.notifier).sendImageMessage(image);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _selectAndSendProduct() async {
    showDialog(
      context: context,
      builder: (context) => ProductSelectorWidget(
        onProductSelected: (product) async {
          await ref.read(chatControllerProvider.notifier).sendProductMessage(product.id);
          _scrollToBottom();
        },
      ),
    );
  }

  Future<void> _updateConversationStatus(ConversationStatus status) async {
    await ref.read(conversationControllerProvider.notifier).updateConversationStatus(
          widget.conversationId,
          status,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation ${status.name}')),
      );
    }
  }

  String _getTypingIndicatorText(Map<String, String> typingUsers, ConversationWithUser conversationWithUser) {
    if (typingUsers.isEmpty) return '';
    
    if (typingUsers.length == 1) {
      // typingUsers map is userId -> userName, so we can get the name directly
      final userName = typingUsers.values.first;
      return '$userName is typing';
    } else {
      return '${typingUsers.length} people are typing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final supabase = ref.read(supabaseClientProvider);
    final currentUserId = supabase.auth.currentUser?.id;

    // Mark messages as read immediately when first loaded and when new messages arrive
    ref.listen<List<ChatMessage>>(
      chatControllerProvider.select((state) => state.messages),
      (previous, next) {
        if (previous == null) {
          // Initial load - scroll to bottom and mark messages as read immediately
          if (next.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom(immediate: true);
              _markMessagesAsRead();
            });
          }
        } else if (next.length > previous.length) {
          // New messages arrived - scroll to bottom and mark as read
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) {
                _scrollToBottom();
                _markMessagesAsRead();
              }
            });
          });
        } else {
          // Messages updated (possibly read_at changed) - check for read receipt changes
          if (kDebugMode) {
            final adminMessages = next.where((m) => m.senderId == currentUserId).toList();
            final adminReadMessages = adminMessages.where((m) => m.readAt != null).toList();
            final previousAdminReadMessages = previous.where((m) => m.senderId == currentUserId && m.readAt != null).toList();
            
            // Read receipt updates handled silently
          }
        }
      },
    );

    // Get conversation details from conversations list
    final conversationsState = ref.watch(conversationControllerProvider);
    final conversationWithUser = conversationsState.conversations.firstWhere(
      (c) => c.conversation.id == widget.conversationId,
      orElse: () => ConversationWithUser(
        conversation: Conversation(
          id: widget.conversationId,
          userId: '',
          status: ConversationStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );

    return AdminAuthGuard(
      child: SafeScaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conversationWithUser.userName ?? 'User'),
              if (conversationWithUser.userEmail != null)
                Text(
                  conversationWithUser.userEmail!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Ionicons.arrow_back_outline),
            onPressed: () => context.pop(),
          ),
          actions: [
            PopupMenuButton(
              icon: const Icon(Ionicons.ellipsis_vertical_outline),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Mark as Closed'),
                  onTap: () => _updateConversationStatus(ConversationStatus.closed),
                ),
                PopupMenuItem(
                  child: const Text('Archive'),
                  onTap: () => _updateConversationStatus(ConversationStatus.archived),
                ),
                PopupMenuItem(
                  child: const Text('Reactivate'),
                  onTap: () => _updateConversationStatus(ConversationStatus.active),
                ),
              ],
            ),
          ],
        ),
        body: chatState.isLoading && chatState.messages.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Messages list
                  Expanded(
                    child: chatState.messages.isEmpty
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
                                  'No messages yet',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      itemCount: chatState.messages.length,
                                      itemBuilder: (context, index) {
                                        final message = chatState.messages[index];
                                        final isCurrentUser = message.senderId == currentUserId;
                                        final controller = ref.read(chatControllerProvider.notifier);
                                        final imageUrl = message.messageType == MessageType.image
                                            ? controller.getImageUrl(message.imageUrl)
                                            : null;

                                        return ChatMessageBubble(
                                          message: message,
                                          isCurrentUser: isCurrentUser,
                                          imageUrl: imageUrl,
                                          isAdminView: true, // Admin view - no purchase actions
                                        );
                                      },
                                    ),
                                  ),
                                  // Typing indicator
                                  Builder(
                                    builder: (context) {
                                      if (chatState.typingUsers.isNotEmpty) {
                                        final typingText = _getTypingIndicatorText(chatState.typingUsers, conversationWithUser);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            children: [
                                              TypingIndicatorDots(
                                                color: Theme.of(context).colorScheme.primary,
                                                dotSize: 8.0,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                typingText,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                              // Scroll to bottom button
                              if (!_isAtBottom)
                                Positioned(
                                  bottom: chatState.typingUsers.isNotEmpty ? 100 : 80,
                                  right: 16,
                                  child: AnimatedOpacity(
                                    opacity: _isAtBottom ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: FloatingActionButton(
                                      mini: true,
                                      onPressed: () {
                                        _scrollToBottom(immediate: true);
                                      },
                                      tooltip: 'Scroll to bottom',
                                      child: const Icon(Ionicons.chevron_down),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  // Error message
                  if (chatState.error != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              chatState.error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              ref.read(chatControllerProvider.notifier).clearError();
                            },
                          ),
                        ],
                      ),
                    ),
                  // Input area
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Ionicons.image_outline),
                          onPressed: chatState.isSending ? null : _pickAndSendImage,
                          tooltip: 'Send image',
                        ),
                        IconButton(
                          icon: const Icon(Ionicons.bag_outline),
                          onPressed: chatState.isSending ? null : _selectAndSendProduct,
                          tooltip: 'Share product',
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            enabled: !chatState.isSending,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: chatState.isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Ionicons.send),
                          onPressed: chatState.isSending ? null : _sendMessage,
                          tooltip: 'Send',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

