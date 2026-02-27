import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/chat_repository.dart';
import '../data/chat_models.dart';
import '../services/chat_sound_service.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/config/environment.dart';
import '../../profile/application/profile_controller.dart';
import '../../notifications/data/notification_model.dart';
import '../../notifications/data/notification_repository_provider.dart';

/// Chat state
class ChatState {
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final Map<String, String> imageSignedUrls; // Cache signed URLs for images
  final Map<String, String> typingUsers; // userId -> userName (for typing indicator)
  final bool hasMoreMessages;
  final bool isLoadingOlderMessages;

  const ChatState({
    this.conversation,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.imageSignedUrls = const <String, String>{},
    this.typingUsers = const <String, String>{},
    this.hasMoreMessages = true,
    this.isLoadingOlderMessages = false,
  });

  ChatState copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    Map<String, String>? imageSignedUrls,
    Map<String, String>? typingUsers,
    bool? hasMoreMessages,
    bool? isLoadingOlderMessages,
  }) {
    // Always create fresh Map instances to avoid IdentityMap issues
    final newImageSignedUrls = imageSignedUrls != null 
        ? Map<String, String>.from(imageSignedUrls)
        : Map<String, String>.from(this.imageSignedUrls);
    
    // Handle typingUsers - convert from old bool type if needed
    final newTypingUsers = typingUsers != null
        ? Map<String, String>.from(typingUsers)
        : _convertTypingUsers(this.typingUsers);
    
    return ChatState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      imageSignedUrls: newImageSignedUrls,
      typingUsers: newTypingUsers,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingOlderMessages: isLoadingOlderMessages ?? this.isLoadingOlderMessages,
    );
  }
  
  // Helper to convert old bool map to new string map
  static Map<String, String> _convertTypingUsers(Map<dynamic, dynamic> oldMap) {
    final newMap = <String, String>{};
    for (final entry in oldMap.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      // If value is bool (old format), use default name, otherwise use as string
      if (value is bool) {
        // Old format - skip or use default
        continue;
      } else {
        newMap[key] = value.toString();
      }
    }
    return newMap;
  }
}

/// Chat controller
class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final Ref _ref;
  final SupabaseClient _supabase;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<List<TypingStatus>>? _typingSubscription;
  Timer? _typingTimer;
  Timer? _typingDebounceTimer;
  final ChatSoundService _soundService = ChatSoundService();
  int _previousMessageCount = 0;
  Set<String> _previousMessageIds = {};
  bool _isDisposed = false;

  ChatController(this._repository, this._ref, this._supabase)
      : super(const ChatState()) {
    // Initialize sound service
    _soundService.initialize();
  }

  /// Helper method to safely update state (checks if disposed)
  void _safeUpdateState(ChatState newState) {
    if (!_isDisposed) {
      state = newState;
    }
  }

  /// Initialize chat (load or create conversation)
  Future<void> initializeChat(String userId) async {
    if (_isDisposed) return;
    _safeUpdateState(state.copyWith(isLoading: true, error: null));

    try {
      // Create or get conversation
      final conversation = await _repository.createOrGetConversation(userId);
      if (_isDisposed) return;
      
      _safeUpdateState(state.copyWith(conversation: conversation));

      // Load messages
      await loadMessages(conversation.id);

      // Subscribe to real-time updates
      if (!_isDisposed) {
        _subscribeToMessages(conversation.id);
      }
    } catch (e) {
      if (!_isDisposed) {
        _safeUpdateState(state.copyWith(
          isLoading: false,
          error: 'Failed to initialize chat: ${e.toString()}',
        ));
      }
    }
  }

  /// Load messages for conversation (also used by admin)
  Future<void> loadMessages(String conversationId) async {
    if (_isDisposed) return;
    _safeUpdateState(state.copyWith(isLoading: true, error: null));
    
    try {
      // Get conversation if not already loaded
      if (state.conversation?.id != conversationId) {
        final conversation = await _repository.getConversationById(conversationId);
        if (_isDisposed) return;
        
        if (conversation == null) {
          _safeUpdateState(state.copyWith(
            isLoading: false,
            error: 'Conversation not found',
          ));
          return;
        }
        _safeUpdateState(state.copyWith(conversation: conversation));
      }

      if (_isDisposed) return;
      final messages = await _repository.getMessages(conversationId);
      if (_isDisposed) return;
      
      // Initialize previous message tracking
      _previousMessageIds = messages.map((m) => m.id).toSet();
      _previousMessageCount = messages.length;
      
      // Get signed URLs for image messages
      final imageUrls = <String, String>{};
      for (final message in messages) {
        if (_isDisposed) return;
        
        if (message.messageType == MessageType.image && message.imageUrl != null) {
          try {
            final signedUrl = await _repository.getImageSignedUrl(message.imageUrl!);
            if (!_isDisposed) {
              imageUrls[message.imageUrl!] = signedUrl;
            }
          } catch (e) {
            // Error handled silently
          }
        }
      }

      if (!_isDisposed) {
        final hasMore = messages.length == 50; // If we got 50, there might be more
        _safeUpdateState(state.copyWith(
          messages: messages,
          isLoading: false,
          imageSignedUrls: imageUrls,
          hasMoreMessages: hasMore,
        ));

        // Subscribe to real-time updates
        _subscribeToMessages(conversationId);
      }
    } catch (e) {
      if (!_isDisposed) {
        _safeUpdateState(state.copyWith(
          isLoading: false,
          error: 'Failed to load messages: ${e.toString()}',
        ));
      }
    }
  }

  /// Load older messages (pagination)
  Future<void> loadOlderMessages() async {
    if (_isDisposed || state.isLoadingOlderMessages || !state.hasMoreMessages || state.messages.isEmpty) {
      return;
    }

    _safeUpdateState(state.copyWith(isLoadingOlderMessages: true));

    try {
      // Get the oldest message date to load messages before it
      final oldestMessage = state.messages.first;
      final olderMessages = await _repository.getMessagesPaginated(
        state.conversation!.id,
        beforeDate: oldestMessage.createdAt,
        limit: 50,
      );

      if (_isDisposed) return;

      final hasMore = olderMessages.length == 50;
      
      // Get signed URLs for new image messages
      final imageUrls = Map<String, String>.from(state.imageSignedUrls);
      for (final message in olderMessages) {
        if (_isDisposed) return;
        
        if (message.messageType == MessageType.image && message.imageUrl != null) {
          try {
            final signedUrl = await _repository.getImageSignedUrl(message.imageUrl!);
            if (!_isDisposed) {
              imageUrls[message.imageUrl!] = signedUrl;
            }
          } catch (e) {
            // Error handled silently
          }
        }
      }

      if (!_isDisposed) {
        // Prepend older messages to the beginning of the list
        final allMessages = [...olderMessages, ...state.messages];
        _safeUpdateState(state.copyWith(
          messages: allMessages,
          imageSignedUrls: imageUrls,
          hasMoreMessages: hasMore,
          isLoadingOlderMessages: false,
        ));
      }
    } catch (e) {
      if (!_isDisposed) {
        _safeUpdateState(state.copyWith(
          isLoadingOlderMessages: false,
          error: 'Failed to load older messages: ${e.toString()}',
        ));
      }
    }
  }

  /// Set conversation directly (for admin use)
  void setConversation(Conversation conversation) {
    if (_isDisposed) return;
    _safeUpdateState(state.copyWith(conversation: conversation));
    loadMessages(conversation.id);
  }

  /// Subscribe to real-time message updates
  void _subscribeToMessages(String conversationId) {
    _messagesSubscription?.cancel();
    
    final currentUser = _supabase.auth.currentUser;
    final currentUserId = currentUser?.id;
    
    _messagesSubscription = _repository.subscribeToMessages(conversationId).listen(
      (messages) async {
        if (_isDisposed) return; // Check early
        
        // Get signed URLs for new image messages
        final imageUrls = Map<String, String>.from(state.imageSignedUrls);
        for (final message in messages) {
          if (_isDisposed) return; // Check in loop
          
          if (message.messageType == MessageType.image && 
              message.imageUrl != null &&
              !imageUrls.containsKey(message.imageUrl)) {
            try {
              final signedUrl = await _repository.getImageSignedUrl(message.imageUrl!);
              if (!_isDisposed) {
                imageUrls[message.imageUrl!] = signedUrl;
              }
            } catch (e) {
              // Error handled silently
            }
          }
        }

        if (_isDisposed) return; // Check before state update
        
        // IMPORTANT: Replace the entire messages list to ensure read_at updates are reflected
        // Don't merge - replace so that read_at changes are properly shown

        // Detect new messages and play sound if from other person
        if (currentUserId != null) {
          final currentMessageIds = messages.map((m) => m.id).toSet();
          final newMessageIds = currentMessageIds.difference(_previousMessageIds);
          
          // Check if there are new messages
          if (newMessageIds.isNotEmpty && _previousMessageIds.isNotEmpty) {
            // Find the newest message that wasn't in the previous set
            final newMessages = messages.where((m) => newMessageIds.contains(m.id)).toList();
            if (newMessages.isNotEmpty) {
              // Sort by created_at to get the latest
              newMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              final newestMessage = newMessages.first;
              
              // Only play sound if message is from someone else (not current user)
              if (newestMessage.senderId != currentUserId && !_isDisposed) {
                _soundService.playMessageSound();
              }
            }
          }
          
          // Update previous message tracking
          _previousMessageIds = currentMessageIds;
          _previousMessageCount = messages.length;
        } else {
          // Reset tracking if no user
          _previousMessageIds = {};
          _previousMessageCount = 0;
        }

        if (!_isDisposed) {
          // IMPORTANT: Replace the entire messages list to ensure read_at updates are reflected
          // This ensures that when read_at changes, the UI updates to show double ticks
          _safeUpdateState(state.copyWith(messages: messages, imageSignedUrls: imageUrls));
        }
      },
      onError: (error) {
        // Error handled silently
      },
    );

    // Subscribe to typing status
    if (!_isDisposed) {
      _subscribeToTypingStatus(conversationId);
    }
  }

  /// Subscribe to typing status
  void _subscribeToTypingStatus(String conversationId) {
    _typingSubscription?.cancel();
    
    if (_isDisposed) {
      return;
    }
    
    try {
      _typingSubscription = _repository.subscribeToTypingStatus(conversationId).listen(
        (typingStatuses) async {
          if (_isDisposed) {
            return; // Check early
          }
          
          final currentUser = _supabase.auth.currentUser;
          if (currentUser == null) {
            return;
          }

          // Filter to only users who are typing and not the current user
          final typingUserIds = <String>[];
          for (final status in typingStatuses) {
            if (status.userId != currentUser.id && status.isTyping) {
              typingUserIds.add(status.userId);
            }
          }

          if (typingUserIds.isEmpty) {
            if (!_isDisposed) {
              _safeUpdateState(state.copyWith(typingUsers: <String, String>{}));
            }
            return;
          }

          if (_isDisposed) {
            return; // Check before async operation
          }

          // Determine if current user is admin (for name display logic)
          final isAdminView = _getSenderRole() != 'user';
          
          // Use fallback names immediately, then update with real names
          final fallbackNames = <String, String>{};
          for (final userId in typingUserIds) {
            fallbackNames[userId] = isAdminView ? 'User' : 'SM Admin';
          }
          
          // Update with fallback names immediately for instant feedback
          if (!_isDisposed) {
            _safeUpdateState(state.copyWith(typingUsers: Map<String, String>.from(fallbackNames)));
          }
          
          // Fetch real user names asynchronously
          try {
            final userNames = await _repository.getTypingUserNames(typingUserIds, isAdminView: isAdminView);
            
            if (_isDisposed) {
              return; // Check after async
            }

            if (!_isDisposed) {
              _safeUpdateState(state.copyWith(typingUsers: userNames));
            }
          } catch (e) {
            // Fallback names already set above, so no need to update again
          }
        },
        onError: (error) {
          // Error handled silently
        },
        onDone: () {
          // Stream closed
        },
        cancelOnError: false,
      );
    } catch (e) {
      // Error handled silently
    }
  }

  /// Start typing indicator with debouncing
  void startTyping() {
    if (state.conversation == null || _isDisposed) return;
    
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    // Cancel existing debounce timer
    _typingDebounceTimer?.cancel();
    
    // Debounce: only set typing status after 300ms of typing (reduces database calls)
    _typingDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isDisposed || state.conversation == null) return;
      
      _repository.setTypingStatus(
        conversationId: state.conversation!.id,
        userId: currentUser.id,
        isTyping: true,
      ).catchError((e) {
        // Error handled silently
      });

      // Auto-stop typing after 3 seconds if no new input
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (!_isDisposed) {
          stopTyping();
        }
      });
    });
  }

  /// Stop typing indicator
  void stopTyping() {
    if (state.conversation == null || _isDisposed) return;
    
    // Cancel debounce timer
    _typingDebounceTimer?.cancel();
    
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    _repository.setTypingStatus(
      conversationId: state.conversation!.id,
      userId: currentUser.id,
      isTyping: false,
    ).catchError((e) {
      // Error handled silently
    });
    
    _typingTimer?.cancel();
  }

  /// Get sender role from profile
  String _getSenderRole() {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null) return 'user';
    
    final role = profile.role.toLowerCase() ?? 'user';
    if (role == 'admin') {
      return 'admin';
    }
    return 'user';
  }

  /// Send text message
  Future<void> sendTextMessage(String content) async {
    if (content.trim().isEmpty || state.conversation == null || _isDisposed) return;

    _safeUpdateState(state.copyWith(isSending: true, error: null));
    stopTyping(); // Stop typing when sending

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final senderRole = _getSenderRole();

      final message = await _repository.sendTextMessage(
        conversationId: state.conversation!.id,
        senderId: currentUser.id,
        senderRole: senderRole,
        content: content.trim(),
      );

      // Check if still valid before continuing
      if (_isDisposed) return;

      // Send notification to recipient
      await _sendChatNotification(message);

      // Check again before final state update
      if (!_isDisposed) {
        _safeUpdateState(state.copyWith(isSending: false));
      }
    } catch (e) {
      if (!_isDisposed) {
        _safeUpdateState(state.copyWith(
          isSending: false,
          error: 'Failed to send message: ${e.toString()}',
        ));
      }
    }
  }

  /// Send chat notification
  Future<void> _sendChatNotification(ChatMessage message) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Get conversation to find recipient
      final conversation = state.conversation;
      if (conversation == null) return;

      // If user sent message, notify admin via database notification and FCM
      if (message.senderRole == 'user') {
        // Get sender profile for notification
        final senderProfile = await _repository.getSenderProfile(currentUser.id);
        final senderName = senderProfile['name'] ?? 'User';

        // Database trigger will create notifications for all admins automatically
        // But we also create one here as backup in case trigger fails
        try {
          // Get all admin user IDs
          final adminProfiles = await _supabase
              .from('profiles')
              .select('id')
              .eq('role', 'admin');
          
          if (adminProfiles.isNotEmpty) {
            final notificationRepo = _ref.read(notificationRepositoryProvider);
            final adminList = adminProfiles as List;
            
            // Create notification for each admin (backup if trigger fails)
            for (final adminProfile in adminList) {
              final adminId = adminProfile['id'] as String;
              try {
                await notificationRepo.createNotification(
                  userId: adminId,
                  type: NotificationType.chatMessage,
                  title: 'New Message from $senderName',
                  message: message.content ?? 'New message',
                  conversationId: conversation.id,
                );
              } catch (e) {
                // Silent fail - trigger should handle it
                if (kDebugMode) {
                  print('⚠️ ChatController: Failed to create backup notification for admin $adminId: $e');
                }
              }
            }
          }
        } catch (e) {
          // Silent fail - trigger should handle it
          if (kDebugMode) {
            print('⚠️ ChatController: Error creating backup notifications: $e');
          }
        }
        
        // Send FCM notification to admin users (fire-and-forget)
        _sendFcmNotificationToAdmin(
          conversationId: conversation.id,
          userName: senderName,
          messagePreview: message.content ?? 'New message',
        ).catchError((e) {
          if (kDebugMode) {
            print('⚠️ ChatController: Failed to send FCM notification (non-critical): $e');
          }
        });

        return;
      }

      // Admin sent message, notify user (existing logic)
      final recipientId = conversation.userId;

      // Get sender profile for notification
      final senderProfile = await _repository.getSenderProfile(currentUser.id);
      final senderName = senderProfile['name'] ?? 'Admin';

      // Create notification
      final notificationRepo = _ref.read(notificationRepositoryProvider);
      await notificationRepo.createNotification(
        userId: recipientId,
        type: NotificationType.chatMessage,
        title: 'New message from $senderName',
        message: message.content ?? 'New message',
        conversationId: conversation.id,
      );

      // Send FCM notification to user (fire-and-forget)
      _sendFcmNotificationToUser(
        userId: recipientId,
        conversationId: conversation.id,
        senderName: senderName,
        messagePreview: message.content ?? 'New message',
      ).catchError((e) {
        if (kDebugMode) {
          print('⚠️ ChatController: Failed to send user FCM notification (non-critical): $e');
        }
      });
    } catch (e) {
      // Don't throw - notification failure shouldn't break message sending
      if (kDebugMode) {
        print('⚠️ ChatController: Error in _sendChatNotification: $e');
      }
    }
  }

  /// Send FCM notification to admin users (fire-and-forget)
  Future<void> _sendFcmNotificationToAdmin({
    required String conversationId,
    required String userName,
    required String messagePreview,
  }) async {
    // Fire-and-forget: don't await, run in background
    Future.microtask(() async {
      try {
        final functionUrl = '${Environment.supabaseUrl}/functions/v1/send-admin-fcm-notification';

        final payload = {
          'type': 'chat_message',
          'title': 'New Message from $userName',
          'message': messagePreview.length > 100 
              ? '${messagePreview.substring(0, 100)}...' 
              : messagePreview,
          'conversation_id': conversationId,
          'user_name': userName,
        };

        final response = await _supabase.functions.invoke(
          'send-admin-fcm-notification',
          body: payload,
        );

        if (kDebugMode) {
          if (response.status == 200) {
            print('✅ ChatController: FCM notification sent to admin');
          } else {
            print('⚠️ ChatController: FCM notification failed with status: ${response.status}');
          }
        }
      } catch (e) {
        // Silent fail - FCM notification is not critical
        if (kDebugMode) {
          print('⚠️ ChatController: Error sending FCM notification (non-critical): $e');
        }
      }
    });
  }

  /// Send FCM notification to user (fire-and-forget)
  Future<void> _sendFcmNotificationToUser({
    required String userId,
    required String conversationId,
    required String senderName,
    required String messagePreview,
  }) async {
    // Fire-and-forget: don't await, run in background
    Future.microtask(() async {
      try {
        final payload = {
          'type': 'chat_message',
          'title': 'New message from $senderName',
          'message': messagePreview.length > 100 
              ? '${messagePreview.substring(0, 100)}...' 
              : messagePreview,
          'conversation_id': conversationId,
          'user_id': userId, // Send to specific user
        };

        final response = await _supabase.functions.invoke(
          'send-user-fcm-notification',
          body: payload,
        );

        if (kDebugMode) {
          if (response.status == 200) {
            print('✅ ChatController: FCM notification sent to user');
          } else {
            print('⚠️ ChatController: User FCM notification failed with status: ${response.status}');
          }
        }
      } catch (e) {
        // Silent fail - FCM notification is not critical
        if (kDebugMode) {
          print('⚠️ ChatController: Error sending user FCM notification (non-critical): $e');
        }
      }
    });
  }

  /// Send image message
  Future<void> sendImageMessage(XFile imageFile) async {
    if (state.conversation == null || _isDisposed) return;

    _safeUpdateState(state.copyWith(isSending: true, error: null));

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload image
      final imagePath = await _repository.uploadChatImage(currentUser.id, imageFile);
      if (_isDisposed) return;

      final senderRole = _getSenderRole();

      // Send message with image
      await _repository.sendImageMessage(
        conversationId: state.conversation!.id,
        senderId: currentUser.id,
        senderRole: senderRole,
        imageUrl: imagePath,
      );

      // Check before final state update
      if (!_isDisposed) {
        _safeUpdateState(state.copyWith(isSending: false));
      }
    } catch (e) {
      if (!_isDisposed) {
        _safeUpdateState(state.copyWith(
          isSending: false,
          error: 'Failed to send image: ${e.toString()}',
        ));
      }
    }
  }

  /// Send product message
  Future<void> sendProductMessage(String productId) async {
    if (state.conversation == null || _isDisposed) return;

    _safeUpdateState(state.copyWith(isSending: true, error: null));

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final senderRole = _getSenderRole();

      await _repository.sendProductMessage(
        conversationId: state.conversation!.id,
        senderId: currentUser.id,
        senderRole: senderRole,
        productId: productId,
      );

      // Check before final state update
      if (!_isDisposed) {
        _safeUpdateState(state.copyWith(isSending: false));
      }
    } catch (e) {
      if (!_isDisposed) {
        _safeUpdateState(state.copyWith(
          isSending: false,
          error: 'Failed to send product: ${e.toString()}',
        ));
      }
    }
  }

  /// Mark messages as read
  Future<int> markAsRead() async {
    if (state.conversation == null) return 0;

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 0;

      final count = await _repository.markAsRead(state.conversation!.id, currentUser.id);
      
      // ALWAYS refresh messages after attempting to mark, regardless of count
      // This is critical because:
      // 1. If count is 0, it might be an RLS policy issue, but we still need to refresh
      // 2. Real-time subscription might have already updated, so we need to sync state
      // 3. Even if update failed, we should check current state from database
      if (!_isDisposed && state.conversation != null) {
        // Wait a bit for real-time subscription to emit the update
        Future.delayed(const Duration(milliseconds: 800), () async {
          if (!_isDisposed && state.conversation != null) {
            try {
              // Force refresh messages to get latest read_at values
              final refreshedMessages = await _repository.refreshMessages(state.conversation!.id);
              
              if (!_isDisposed) {
                // Always update state with refreshed messages to ensure read_at is current
                // This ensures UI reflects actual database state
                _safeUpdateState(state.copyWith(messages: refreshedMessages));
              }
            } catch (e) {
              if (kDebugMode) {
                print('❌ Chat: Error refreshing messages after markAsRead: $e');
              }
            }
          }
        });
      }
      
      if (kDebugMode) {
        if (count == 0) {
          print('⚠️ Chat Controller: markAsRead returned 0 - database update may have failed');
          print('   This could indicate RLS policy issue or messages already marked');
        } else {
          print('✅ Chat Controller: Marked $count messages as read');
        }
      }
      
      return count;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Chat Controller: Error in markAsRead: $e');
      }
      return 0;
    }
  }

  /// Get signed URL for an image (with caching)
  String? getImageUrl(String? imagePath) {
    if (imagePath == null) return null;
    return state.imageSignedUrls[imagePath] ?? imagePath;
  }

  /// Clear error
  void clearError() {
    if (!_isDisposed) {
      _safeUpdateState(state.copyWith(error: null));
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _typingDebounceTimer?.cancel();
    stopTyping();
    _soundService.dispose();
    super.dispose();
  }
}

/// Chat controller provider
final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return ChatController(repository, ref, supabase);
});

/// Provider for user chat unread count (real-time updates)
/// This tracks unread messages from admin for the current user
final userChatUnreadCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  
  final controller = StreamController<int>();
  StreamSubscription<Conversation?>? conversationSubscription;
  StreamSubscription<List<ChatMessage>>? messagesSubscription;
  
  Future<void> initialize() async {
    // Get current user
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      if (!controller.isClosed) {
        controller.add(0);
      }
      return;
    }

    final currentUserId = currentUser.id;

    // Subscribe to user conversation stream - this will emit when conversation is created
    conversationSubscription = repository.subscribeToUserConversation(currentUserId).listen(
      (conversation) {
        // Cancel previous message subscription if any
        messagesSubscription?.cancel();
        messagesSubscription = null;
        
        if (conversation == null) {
          // Conversation doesn't exist yet, emit 0 but keep listening
          if (!controller.isClosed) {
            controller.add(0);
          }
          return;
        }

        // Once conversation exists, subscribe to messages and count unread
        messagesSubscription = repository.subscribeToMessages(conversation.id).listen(
          (messages) {
            if (controller.isClosed) return;
            
            // Count messages that are not sent by the current user and not read
            final unreadCount = messages.where((message) {
              return message.senderId != currentUserId && message.readAt == null;
            }).length;
            
            controller.add(unreadCount);
          },
          onError: (error) {
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );
  }

  // Initialize immediately
  initialize();

  // Cleanup on cancel
  ref.onDispose(() {
    conversationSubscription?.cancel();
    messagesSubscription?.cancel();
    controller.close();
  });

  return controller.stream;
});

