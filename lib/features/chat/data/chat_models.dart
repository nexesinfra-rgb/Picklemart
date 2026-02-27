/// Chat domain models
library;

/// Message type enum
enum MessageType {
  text,
  image,
  product;

  String toJson() {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.product:
        return 'product';
    }
  }

  static MessageType fromJson(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'product':
        return MessageType.product;
      default:
        return MessageType.text;
    }
  }
}

/// Conversation status enum
enum ConversationStatus {
  active,
  closed,
  archived;

  String toJson() {
    switch (this) {
      case ConversationStatus.active:
        return 'active';
      case ConversationStatus.closed:
        return 'closed';
      case ConversationStatus.archived:
        return 'archived';
    }
  }

  static ConversationStatus fromJson(String value) {
    switch (value) {
      case 'active':
        return ConversationStatus.active;
      case 'closed':
        return ConversationStatus.closed;
      case 'archived':
        return ConversationStatus.archived;
      default:
        return ConversationStatus.active;
    }
  }
}

/// Chat conversation model
class Conversation {
  final String id;
  final String userId;
  final String? adminId;
  final ConversationStatus status;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    this.adminId,
    required this.status,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      adminId: json['admin_id'] as String?,
      status: ConversationStatus.fromJson(json['status'] as String),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'admin_id': adminId,
      'status': status.toJson(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? id,
    String? userId,
    String? adminId,
    ConversationStatus? status,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      status: status ?? this.status,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole;
  final MessageType messageType;
  final String? content;
  final String? imageUrl;
  final String? productId;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderRole,
    required this.messageType,
    this.content,
    this.imageUrl,
    this.productId,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderRole: json['sender_role'] as String,
      messageType: MessageType.fromJson(json['message_type'] as String),
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      productId: json['product_id'] as String?,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'message_type': messageType.toJson(),
      'content': content,
      'image_url': imageUrl,
      'product_id': productId,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderRole,
    MessageType? messageType,
    String? content,
    String? imageUrl,
    String? productId,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      productId: productId ?? this.productId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isRead => readAt != null;
}

/// Conversation with user info (for admin view)
class ConversationWithUser {
  final Conversation conversation;
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final int unreadCount;

  ConversationWithUser({
    required this.conversation,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
    this.unreadCount = 0,
  });
}

/// Typing status model
class TypingStatus {
  final String id;
  final String conversationId;
  final String userId;
  final bool isTyping;
  final DateTime updatedAt;

  TypingStatus({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.isTyping,
    required this.updatedAt,
  });

  factory TypingStatus.fromJson(Map<String, dynamic> json) {
    return TypingStatus(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      isTyping: (json['is_typing'] as bool?) ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'is_typing': isTyping,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

