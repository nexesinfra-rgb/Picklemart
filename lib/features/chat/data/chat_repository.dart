import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_models.dart';
import '../../../core/providers/supabase_provider.dart';

/// Repository for managing chat conversations and messages
class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  /// Create or get existing conversation for a user
  Future<Conversation> createOrGetConversation(String userId) async {
    try {
      // Try to get existing conversation
      final existing = await _supabase
          .from('chat_conversations')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        return Conversation.fromJson(existing);
      }

      // Create new conversation
      final response = await _supabase
          .from('chat_conversations')
          .insert({
            'user_id': userId,
            'status': 'active',
          })
          .select()
          .single();

      return Conversation.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create or get conversation: $e');
    }
  }

  /// Get user's conversation
  Future<Conversation?> getUserConversation(String userId) async {
    try {
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Conversation.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user conversation: $e');
    }
  }

  /// Get conversation by ID (for admin)
  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .eq('id', conversationId)
          .maybeSingle();

      if (response == null) return null;
      return Conversation.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get conversation by ID: $e');
    }
  }

  /// Get all conversations (admin only)
  Future<List<ConversationWithUser>> getAllConversations({
    ConversationStatus? status,
    String? searchQuery,
  }) async {
    try {
      // Build query with optional status filter
      dynamic query = _supabase
          .from('chat_conversations')
          .select('*, profiles:user_id(id, name, email, avatar_url)');
      
      if (status != null) {
        query = query.eq('status', status.toJson());
      }
      
      final response = await query
          .order('last_message_at', ascending: false)
          .order('created_at', ascending: false);

      // Get unread counts for each conversation
      final conversations = <ConversationWithUser>[];
      for (final row in response) {
        final conversation = Conversation.fromJson(row);
        final profile = row['profiles'] as Map<String, dynamic>?;

        // Count unread messages (messages not read by admin)
        final unreadCount = await _getUnreadCount(conversation.id, isAdmin: true);

        conversations.add(ConversationWithUser(
          conversation: conversation,
          userName: profile?['name'] as String?,
          userEmail: profile?['email'] as String?,
          userAvatarUrl: profile?['avatar_url'] as String?,
          unreadCount: unreadCount,
        ));
      }

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        conversations.retainWhere((c) {
          return (c.userName?.toLowerCase().contains(queryLower) ?? false) ||
              (c.userEmail?.toLowerCase().contains(queryLower) ?? false);
        });
      }

      return conversations;
    } catch (e) {
      throw Exception('Failed to get all conversations: $e');
    }
  }

  /// Get all conversations with pagination (admin only)
  Future<List<ConversationWithUser>> getAllConversationsPaginated({
    int page = 1,
    int limit = 50,
    ConversationStatus? status,
    String? searchQuery,
  }) async {
    try {
      final startIndex = (page - 1) * limit;
      
      // Build query with optional status filter
      dynamic query = _supabase
          .from('chat_conversations')
          .select('*, profiles:user_id(id, name, email, avatar_url)');
      
      if (status != null) {
        query = query.eq('status', status.toJson());
      }
      
      final response = await query
          .order('last_message_at', ascending: false)
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      // Get unread counts for each conversation
      final conversations = <ConversationWithUser>[];
      for (final row in response) {
        final conversation = Conversation.fromJson(row);
        final profile = row['profiles'] as Map<String, dynamic>?;

        // Count unread messages (messages not read by admin)
        final unreadCount = await _getUnreadCount(conversation.id, isAdmin: true);

        conversations.add(ConversationWithUser(
          conversation: conversation,
          userName: profile?['name'] as String?,
          userEmail: profile?['email'] as String?,
          userAvatarUrl: profile?['avatar_url'] as String?,
          unreadCount: unreadCount,
        ));
      }

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        conversations.retainWhere((c) {
          return (c.userName?.toLowerCase().contains(queryLower) ?? false) ||
              (c.userEmail?.toLowerCase().contains(queryLower) ?? false);
        });
      }

      return conversations;
    } catch (e) {
      throw Exception('Failed to get all conversations: $e');
    }
  }

  /// Get messages for a conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      // Load recent 50 messages for initial load
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(50);

      final messages = response.map((json) => ChatMessage.fromJson(json)).toList();
      // Sort ascending for display (oldest first)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Get messages for a conversation with pagination (loads older messages)
  /// [beforeDate] is the date before which to fetch messages (for loading older messages)
  Future<List<ChatMessage>> getMessagesPaginated(
    String conversationId, {
    DateTime? beforeDate,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId);

      // If beforeDate is provided, fetch messages before that date
      if (beforeDate != null) {
        query = query.lt('created_at', beforeDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = response.map((json) => ChatMessage.fromJson(json)).toList();
      // Sort ascending for display (oldest first)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Send a text message
  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String content,
  }) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'sender_role': senderRole,
            'message_type': MessageType.text.toJson(),
            'content': content,
          })
          .select()
          .single();

      return ChatMessage.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send an image message
  Future<ChatMessage> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String imageUrl,
  }) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'sender_role': senderRole,
            'message_type': MessageType.image.toJson(),
            'image_url': imageUrl,
          })
          .select()
          .single();

      return ChatMessage.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send image message: $e');
    }
  }

  /// Send a product message
  Future<ChatMessage> sendProductMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String productId,
  }) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'sender_role': senderRole,
            'message_type': MessageType.product.toJson(),
            'product_id': productId,
          })
          .select()
          .single();

      return ChatMessage.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send product message: $e');
    }
  }

  /// Upload chat image to storage
  Future<String> uploadChatImage(String userId, XFile imageFile) async {
    try {
      final bucket = _supabase.storage.from('chat-images');

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecondsSinceEpoch % 10000;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = 'chat/$userId/${timestamp}_$random.$extension';

      // Read file bytes
      Uint8List bytes;
      if (kIsWeb) {
        final xFile = XFile(imageFile.path);
        bytes = await xFile.readAsBytes();
      } else {
        final file = File(imageFile.path);
        if (!await file.exists()) {
          throw Exception('File not found: ${imageFile.path}');
        }
        bytes = await file.readAsBytes();
      }

      if (bytes.isEmpty) {
        throw Exception('Image bytes are empty');
      }

      // Check file size (5MB limit)
      const maxFileSize = 5242880; // 5MB
      if (bytes.length > maxFileSize) {
        throw Exception(
            'Image file is too large. Maximum size is 5MB. Current size: ${(bytes.length / 1048576).toStringAsFixed(2)}MB');
      }

      // Determine content type
      final contentType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : extension == 'gif'
                  ? 'image/gif'
                  : 'image/jpeg';

      // Upload to Supabase Storage
      if (kIsWeb) {
        await bucket.uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
      } else {
        final file = File(imageFile.path);
        await bucket.upload(
          fileName,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
      }

      // Return the file path (not signed URL, since signed URLs expire)
      // We'll generate signed URLs when displaying images
      return fileName;
    } catch (e) {
      throw Exception('Failed to upload chat image: $e');
    }
  }

  /// Get signed URL for an image (for displaying in chat)
  Future<String> getImageSignedUrl(String imagePath) async {
    try {
      final bucket = _supabase.storage.from('chat-images');
      // imagePath should be in format: chat/{userId}/{filename}
      // Create signed URL valid for 1 hour
      final signedUrl = await bucket.createSignedUrl(imagePath, 3600);
      return signedUrl;
    } catch (e) {
      // If signed URL creation fails, return original path
      // This handles edge cases
      return imagePath;
    }
  }

  /// Mark messages as read
  Future<int> markAsRead(String conversationId, String userId) async {
    try {
      // Update all unread messages in the conversation that were not sent by the current user
      // When user calls this: marks admin messages (sender_id != user_id)
      // When admin calls this: marks user messages (sender_id != admin_id)
      final readAt = DateTime.now().toIso8601String();
      
      if (kDebugMode) {
        print('📝 Chat Repository: Attempting to mark messages as read');
        print('   Conversation ID: $conversationId');
        print('   User ID: $userId');
        print('   Read At: $readAt');
      }
      
      final response = await _supabase
          .from('chat_messages')
          .update({'read_at': readAt})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .isFilter('read_at', null)
          .select('id, sender_id, sender_role, read_at');
      
      final count = (response as List).length;
      
      if (kDebugMode) {
        if (count == 0) {
          print('⚠️ Chat Repository: markAsRead returned 0 messages');
          print('   This means the UPDATE query matched 0 rows');
          print('   Possible causes:');
          print('   1. RLS policy is blocking the UPDATE');
          print('   2. All messages already have read_at set');
          print('   3. No messages match the criteria (conversation_id + sender_id != user_id + read_at IS NULL)');
        } else {
          print('✅ Chat Repository: Successfully marked $count messages as read');
          for (var msg in response) {
            print('   - Message ${msg['id']}: read_at = ${msg['read_at']}');
          }
        }
      }
      
      // Return count of messages marked as read
      return count;
    } catch (e) {
      // Log the actual error - this is critical for debugging RLS issues
      if (kDebugMode) {
        print('❌ Chat Repository: Error in markAsRead: $e');
        print('   Error type: ${e.runtimeType}');
        print('   Stack trace: ${StackTrace.current}');
        
        // Check if it's an RLS policy error
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('policy') || errorStr.contains('permission') || errorStr.contains('row level security')) {
          print('');
          print('🔒 RLS POLICY ERROR DETECTED!');
          print('   The database update is being blocked by Row Level Security policies.');
          print('   You need to create/update RLS policies on chat_messages table.');
          print('   Users need UPDATE permission on read_at column for messages they didn\'t send.');
          print('');
        }
      }
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Get unread message count for a conversation
  Future<int> _getUnreadCount(String conversationId, {required bool isAdmin}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 0;

      final response = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUser.id)
          .isFilter('read_at', null);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get unread message count for a user's conversation
  /// This is a public method for users to check their unread messages from admin
  Future<int> getUserUnreadCount(String conversationId) async {
    return _getUnreadCount(conversationId, isAdmin: false);
  }

  /// Subscribe to messages in a conversation (real-time)
  Stream<List<ChatMessage>> subscribeToMessages(String conversationId) {
    final controller = StreamController<List<ChatMessage>>();

    // Initial fetch
    getMessages(conversationId).then((messages) {
      if (!controller.isClosed) {
        controller.add(messages);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Subscribe to real-time changes
    // This subscription listens to INSERT, UPDATE, and DELETE events
    // UPDATE events are triggered when read_at changes
    final subscription = _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .listen(
      (data) {
        scheduleMicrotask(() {
          try {
            // When UPDATE events occur (e.g., read_at changes), Supabase sends all messages
            // in the conversation that match the filter. We need to parse and emit them.
            final messages = data.map((json) => ChatMessage.fromJson(json)).toList();
            
            if (!controller.isClosed) {
              controller.add(messages);
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        });
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Cancel subscription when stream is closed
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }
  
  /// Force refresh messages for a conversation
  /// This is used as a fallback when real-time subscription might not immediately reflect changes
  Future<List<ChatMessage>> refreshMessages(String conversationId) async {
    return await getMessages(conversationId);
  }

  /// Update conversation status
  Future<void> updateConversationStatus(
    String conversationId,
    ConversationStatus status,
  ) async {
    try {
      await _supabase
          .from('chat_conversations')
          .update({'status': status.toJson()})
          .eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to update conversation status: $e');
    }
  }

  /// Assign admin to conversation
  Future<void> assignAdmin(String conversationId, String adminId) async {
    try {
      await _supabase
          .from('chat_conversations')
          .update({'admin_id': adminId})
          .eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to assign admin: $e');
    }
  }

  /// Subscribe to conversations (real-time) for admin
  Stream<List<ConversationWithUser>> subscribeToConversations({
    ConversationStatus? statusFilter,
    String? searchQuery,
  }) {
    final controller = StreamController<List<ConversationWithUser>>();
    StreamSubscription? conversationsSubscription;
    StreamSubscription? messagesSubscription;

    Future<void> refreshConversations() async {
      try {
        // Re-fetch all conversations with user info and filters
        final conversations = await getAllConversations(
          status: statusFilter,
          searchQuery: searchQuery,
        );
        if (!controller.isClosed) {
          controller.add(conversations);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Initial fetch
    getAllConversations(
      status: statusFilter,
      searchQuery: searchQuery,
    ).then((conversations) {
      if (!controller.isClosed) {
        controller.add(conversations);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Subscribe to real-time changes on chat_conversations table
    conversationsSubscription = _supabase
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .order('created_at', ascending: false)
        .listen(
      (data) async {
        scheduleMicrotask(() => refreshConversations());
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Also subscribe to chat_messages changes to refresh unread counts
    // when messages are marked as read or new messages arrive
    messagesSubscription = _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .listen(
      (data) async {
        // When messages change (including read_at updates), refresh conversation list
        scheduleMicrotask(() => refreshConversations());
      },
      onError: (error) {
        // Don't add error to controller for messages subscription failures
        // as it's just for refreshing counts
      },
    );

    // Cancel subscriptions when stream is closed
    controller.onCancel = () {
      conversationsSubscription?.cancel();
      messagesSubscription?.cancel();
    };

    return controller.stream;
  }

  /// Subscribe to user conversations (real-time) for regular users
  Stream<Conversation?> subscribeToUserConversation(String userId) {
    final controller = StreamController<Conversation?>();

    // Initial fetch
    getUserConversation(userId).then((conversation) {
      if (!controller.isClosed) {
        controller.add(conversation);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Subscribe to real-time changes for this user's conversation
    final subscription = _supabase
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
      (data) {
        scheduleMicrotask(() {
          try {
            // Stream returns a list, get the first item or null
            final conversation = data.isNotEmpty 
                ? Conversation.fromJson(data.first)
                : null;
            if (!controller.isClosed) {
              controller.add(conversation);
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        });
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Cancel subscription when stream is closed
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Set typing status
  Future<void> setTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      // Upsert based on unique constraint (conversation_id, user_id)
      await _supabase
          .from('chat_typing_status')
          .upsert({
            'conversation_id': conversationId,
            'user_id': userId,
            'is_typing': isTyping,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'conversation_id,user_id');
    } catch (e) {
      // Error handled silently
    }
  }

  /// Get current typing status for a conversation
  Future<List<TypingStatus>> getTypingStatus(String conversationId) async {
    try {
      final response = await _supabase
          .from('chat_typing_status')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_typing', true);

      final typingStatuses = (response as List)
          .map((json) => TypingStatus.fromJson(json))
          .toList();
      
      return typingStatuses;
    } catch (e) {
      return [];
    }
  }

  /// Subscribe to typing status
  Stream<List<TypingStatus>> subscribeToTypingStatus(String conversationId) {
    final controller = StreamController<List<TypingStatus>>();
    Timer? pollingTimer;
    DateTime? lastRealTimeUpdate;
    List<TypingStatus> lastTypingStatuses = [];

    // Helper function to emit typing statuses
    void emitTypingStatuses(List<TypingStatus> typingStatuses) {
      if (controller.isClosed) {
        return;
      }

      // Only emit if statuses have changed
      final hasChanged = typingStatuses.length != lastTypingStatuses.length ||
          !typingStatuses.every((status) => lastTypingStatuses.any((s) => 
            s.userId == status.userId && s.isTyping == status.isTyping));
      
      if (hasChanged) {
        lastTypingStatuses = typingStatuses;
        controller.add(typingStatuses);
      }
    }

    // Initial fetch
    getTypingStatus(conversationId).then((typingStatuses) {
      if (!controller.isClosed) {
        lastTypingStatuses = typingStatuses;
        controller.add(typingStatuses);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Subscribe to real-time changes
    StreamSubscription? subscription;
    try {
      subscription = _supabase
          .from('chat_typing_status')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .listen(
        (data) {
          lastRealTimeUpdate = DateTime.now();
          
          scheduleMicrotask(() {
            try {
              // Filter to only show typing=true and map to TypingStatus
              final typingStatuses = data
                  .where((json) => (json['is_typing'] as bool?) ?? false)
                  .map((json) => TypingStatus.fromJson(json))
                  .toList();
              
              emitTypingStatuses(typingStatuses);
            } catch (e) {
              if (!controller.isClosed) {
                controller.addError(e);
              }
            }
          });
        },
        onError: (error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      // Will rely on polling fallback
    }

    // Polling fallback: Poll every 1.5 seconds to ensure we catch typing status changes
    // This works even if real-time subscription is not functioning
    pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      try {
        final typingStatuses = await getTypingStatus(conversationId);
        emitTypingStatuses(typingStatuses);
      } catch (e) {
        // Don't add error to controller for polling failures
      }
    });

    controller.onCancel = () {
      subscription?.cancel();
      pollingTimer?.cancel();
    };

    return controller.stream;
  }

  /// Get sender profile info for messages
  Future<Map<String, String?>> getSenderProfile(String senderId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('name, avatar_url')
          .eq('id', senderId)
          .maybeSingle();

      if (response == null) return {'name': null, 'avatar_url': null};
      
      return {
        'name': response['name'] as String?,
        'avatar_url': response['avatar_url'] as String?,
      };
    } catch (e) {
      return {'name': null, 'avatar_url': null};
    }
  }

  /// Get typing user names for typing indicator
  /// Returns a map of userId -> userName
  /// For admin users, returns "SM Admin" as the name
  Future<Map<String, String>> getTypingUserNames(List<String> userIds, {required bool isAdminView}) async {
    if (userIds.isEmpty) return <String, String>{};
    
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, name, role')
          .inFilter('id', userIds);

      final Map<String, String> userNames = {};
      
      for (final user in response) {
        final userId = user['id'] as String;
        final role = (user['role'] as String?)?.toLowerCase() ?? 'user';
        final name = user['name'] as String?;
        
        // For admin view: show user's actual name
        // For user view: show "SM Admin" for admin users, actual name for others
        if (isAdminView) {
          userNames[userId] = name ?? 'User';
        } else {
          // User view - check if this is an admin
          if (role == 'admin') {
            userNames[userId] = 'SM Admin';
          } else {
            userNames[userId] = name ?? 'User';
          }
        }
      }
      
      // Fill in missing users with default names
      for (final userId in userIds) {
        if (!userNames.containsKey(userId)) {
          userNames[userId] = isAdminView ? 'User' : 'SM Admin';
        }
      }
      
      return Map<String, String>.from(userNames);
    } catch (e) {
      // Return default names for all users
      return Map<String, String>.from({for (final userId in userIds) userId: isAdminView ? 'User' : 'SM Admin'});
    }
  }
}

/// Provider for ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ChatRepository(supabase);
});

