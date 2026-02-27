import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import '../application/chat_controller.dart';
import '../application/conversation_controller.dart';
import '../data/chat_models.dart';
import '../services/chat_sound_service.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/product_selector_widget.dart';
import 'widgets/typing_indicator_dots.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/ui/safe_scaffold.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  
  const ChatScreen({super.key, this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  int _previousMessageCount = 0;
  Timer? _markAsReadDebounceTimer;
  DateTime? _lastMarkAsReadAttempt;
  Timer? _periodicMarkAsReadTimer;
  bool _isAtBottom = true;
  double _previousScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
      // Initialize sound service
      ChatSoundService().initialize();
      
      // Start periodic marking of admin messages as read
      // This ensures admin messages are marked even if other mechanisms fail
      _periodicMarkAsReadTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        final chatState = ref.read(chatControllerProvider);
        final supabase = ref.read(supabaseClientProvider);
        final currentUserId = supabase.auth.currentUser?.id;
        
        if (currentUserId == null || 
            chatState.conversation == null || 
            chatState.messages.isEmpty || 
            chatState.isLoading) {
          return;
        }
        
        // Check for unread admin messages
        final unreadAdminMessages = chatState.messages.where((message) =>
            message.senderId != currentUserId && 
            message.readAt == null &&
            message.senderRole.toLowerCase() == 'admin').toList();
        
        if (unreadAdminMessages.isNotEmpty) {
          _markMessagesAsRead();
        }
      });
    });
    // Listen to text changes for typing indicator
    _messageController.addListener(_onTextChanged);
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
    
    _previousScrollPosition = currentScroll;
  }

  void _markMessagesAsReadIfAtBottom() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 100.0; // pixels from bottom
    
    // Check if user is near or at the bottom
    final isNearBottom = (maxScroll - currentScroll) <= threshold;
    
    if (isNearBottom) {
      // Mark immediately when at bottom, then debounce for subsequent calls
      _markMessagesAsRead();
      
      // Debounce to avoid multiple calls
      _markAsReadDebounceTimer?.cancel();
      _markAsReadDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _markMessagesAsRead();
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (!mounted) return; // Check if widget is still mounted
    
    final chatState = ref.read(chatControllerProvider);
    final supabase = ref.read(supabaseClientProvider);
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      return;
    }

    if (!mounted) return; // Check again after async operations

    if (chatState.conversation == null) {
      return;
    }

    if (chatState.messages.isEmpty) {
      return;
    }

    if (chatState.isLoading) {
      return;
    }

    // Check specifically for unread admin messages before marking
    final hasUnreadAdminMessages = chatState.messages.any((message) =>
        message.senderId != currentUserId && 
        message.readAt == null &&
        message.senderRole.toLowerCase() == 'admin');

    if (!hasUnreadAdminMessages) {
      return;
    }

    if (!mounted) return; // Final check before async operation

    try {
      final count = await ref.read(chatControllerProvider.notifier).markAsRead();
      
      // Log for debugging - this helps identify if the issue is with RLS policies or database
      if (kDebugMode) {
        if (count == 0) {
          print('⚠️ Chat: markAsRead returned 0 - no messages were marked. Check RLS policies.');
          print('   Conversation ID: ${chatState.conversation!.id}');
          print('   Current User ID: $currentUserId');
          final unreadAdminCount = chatState.messages.where((m) => 
            m.senderId != currentUserId && 
            m.readAt == null &&
            m.senderRole.toLowerCase() == 'admin').length;
          print('   Unread admin messages in state: $unreadAdminCount');
        } else {
          print('✅ Chat: Marked $count messages as read');
        }
      }
      
      if (!mounted) return; // Check after async operation
    } catch (e) {
      // Log error instead of silently swallowing - this is critical for debugging
      if (kDebugMode) {
        print('❌ Chat: Error marking messages as read: $e');
        print('   Conversation ID: ${chatState.conversation?.id}');
        print('   Current User ID: $currentUserId');
        print('   Stack trace: ${StackTrace.current}');
      }
      // Don't rethrow - errors in read status shouldn't break the UI
      // But logging helps identify RLS policy issues or database problems
    }
  }

  void _initializeChat() {
    // If conversationId is provided, load that specific conversation
    if (widget.conversationId != null) {
      ref.read(chatControllerProvider.notifier).loadMessages(widget.conversationId!);
    } else {
      // Otherwise, initialize new chat for current user
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        ref.read(chatControllerProvider.notifier).initializeChat(userId);
      }
    }
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

  @override
  void dispose() {
    // Cancel timers first
    _markAsReadDebounceTimer?.cancel();
    _periodicMarkAsReadTimer?.cancel();
    
    // Mark messages as read before disposing (if still mounted)
    // Store values before dispose to avoid using ref after disposal
    if (mounted) {
      try {
        final chatState = ref.read(chatControllerProvider);
        final supabase = ref.read(supabaseClientProvider);
        final currentUserId = supabase.auth.currentUser?.id;
        
        if (currentUserId != null &&
            chatState.conversation != null && 
            chatState.messages.isNotEmpty && 
            !chatState.isLoading) {
          // Check if there are unread messages
          final hasUnreadMessages = chatState.messages.any((message) =>
              message.senderId != currentUserId && message.readAt == null);
          
          if (hasUnreadMessages) {
            // Store values to use after dispose check
            final conversationId = chatState.conversation!.id;
            final chatNotifier = ref.read(chatControllerProvider.notifier);
            
            // Fire and forget - don't wait for completion
            // Use stored values, not ref
            chatNotifier.markAsRead().catchError((e) {
              // Error handled silently
            });
          }
        }
      } catch (e) {
        // Ignore errors during dispose
      }
    }
    
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }


  void _scrollToBottom({bool immediate = false}) {
    if (_scrollController.hasClients) {
      if (immediate) {
        // Instant scroll (for when sending message)
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        // Update scroll position state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateScrollPosition();
        });
      } else {
        // Animated scroll (for receiving messages)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ).then((_) {
              // Update scroll position state after animation completes
              _updateScrollPosition();
            });
          }
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (!mounted) return; // Check if widget is still mounted
    
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    
    // Scroll immediately when sending (message will appear via subscription)
    _scrollToBottom(immediate: true);
    
    // IMPORTANT: Mark all admin messages as read BEFORE sending reply
    // This ensures admin sees double ticks immediately when user replies
    await _markMessagesAsRead();
    
    // Send the message
    await ref.read(chatControllerProvider.notifier).sendTextMessage(content);
    
    // Mark messages as read again after sending (in case any new admin messages arrived)
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _markMessagesAsRead();
          _scrollToBottom();
        }
      });
    }
  }

  String _getTypingIndicatorText(Map<String, String> typingUsers) {
    if (typingUsers.isEmpty) return '';
    
    if (typingUsers.length == 1) {
      final userName = typingUsers.values.first;
      return '$userName is typing';
    } else {
      return '${typingUsers.length} people are typing';
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        _scrollToBottom(immediate: true);
        await ref.read(chatControllerProvider.notifier).sendImageMessage(image);
        Future.delayed(const Duration(milliseconds: 200), () {
          _scrollToBottom();
        });
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
          _scrollToBottom(immediate: true);
          await ref.read(chatControllerProvider.notifier).sendProductMessage(product.id);
          Future.delayed(const Duration(milliseconds: 200), () {
            _scrollToBottom();
          });
        },
      ),
    );
  }

  Future<void> _endChat() async {
    final chatState = ref.read(chatControllerProvider);
    if (chatState.conversation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No conversation to close')),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Chat'),
        content: const Text('Are you sure you want to end this chat? You can still view the conversation history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End Chat'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Update conversation status to closed
      await ref.read(conversationControllerProvider.notifier).updateConversationStatus(
        chatState.conversation!.id,
        ConversationStatus.closed,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat ended successfully')),
        );
        
        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final supabase = ref.read(supabaseClientProvider);
    final currentUserId = supabase.auth.currentUser?.id;

    // Auto-scroll and mark messages as read when new messages arrive
    ref.listen<List<ChatMessage>>(
      chatControllerProvider.select((state) => state.messages),
      (previous, next) {
        if (previous == null) {
          // Initial load - scroll to bottom and mark messages as read immediately
          if (next.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom(immediate: true);
              // Mark messages as read immediately when first loaded
              // Get fresh values inside the callback
              _markMessagesAsRead();
              
              // Retry after a short delay to ensure marking succeeded
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _markMessagesAsRead();
                }
              });
            });
            _previousMessageCount = next.length;
          }
        } else if (next.length > previous.length) {
          // New messages arrived - scroll to bottom after rendering
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) {
                _scrollToBottom();
                // Mark messages as read when new messages arrive
                _markMessagesAsRead();
              }
            });
          });
          _previousMessageCount = next.length;
        } else {
          // Messages updated (possibly read_at changed) - ensure all admin messages are marked
          final adminMessages = next.where((m) => 
            m.senderId != currentUserId && 
            m.senderRole.toLowerCase() == 'admin'
          ).toList();
          final unreadAdminMessages = adminMessages.where((m) => m.readAt == null).toList();
          if (unreadAdminMessages.isNotEmpty) {
            _markMessagesAsRead();
          }
        }
      },
    );

    // Aggressively mark messages as read when conversation and messages are loaded
    // This ensures messages are marked even if ref.listen doesn't fire properly
    // Check every 1.5 seconds to ensure admin messages are marked when user views chat
    if (chatState.conversation != null && 
        chatState.messages.isNotEmpty && 
        !chatState.isLoading &&
        currentUserId != null) {
      final unreadAdminMessages = chatState.messages.where((message) =>
          message.senderId != currentUserId && 
          message.readAt == null &&
          message.senderRole.toLowerCase() == 'admin').toList();
      
      if (unreadAdminMessages.isNotEmpty) {
        final now = DateTime.now();
        if (_lastMarkAsReadAttempt == null || 
            now.difference(_lastMarkAsReadAttempt!) > const Duration(milliseconds: 1500)) {
          _lastMarkAsReadAttempt = now;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _markMessagesAsRead();
          });
        }
      }
    }

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Chat with Admin'),
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Ionicons.ellipsis_vertical_outline),
            onSelected: (value) async {
              if (value == 'end_chat') {
                await _endChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'end_chat',
                child: Row(
                  children: [
                    Icon(Ionicons.close_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text('End Chat'),
                  ],
                ),
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
                                'Start a conversation',
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
                                // Load Older Messages button at top
                                if (chatState.hasMoreMessages)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: chatState.isLoadingOlderMessages
                                        ? const Center(child: CircularProgressIndicator())
                                        : OutlinedButton.icon(
                                            onPressed: () {
                                              ref.read(chatControllerProvider.notifier).loadOlderMessages();
                                            },
                                            icon: const Icon(Ionicons.arrow_up_outline, size: 16),
                                            label: const Text('Load Older Messages'),
                                          ),
                                  ),
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
                                      );
                                    },
                                  ),
                                ),
                                // Typing indicator
                                if (chatState.typingUsers.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      children: [
                                        TypingIndicatorDots(
                                          color: Theme.of(context).colorScheme.primary,
                                          dotSize: 8.0,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getTypingIndicatorText(chatState.typingUsers),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ],
                                    ),
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
                      // Attachment buttons
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
                      // Text input
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
                      // Send button
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
    );
  }
}

