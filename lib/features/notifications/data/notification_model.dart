enum NotificationType {
  orderPlaced,
  orderStatusChanged,
  chatMessage,
  ratingReply,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.orderPlaced:
        return 'order_placed';
      case NotificationType.orderStatusChanged:
        return 'order_status_changed';
      case NotificationType.chatMessage:
        return 'chat_message';
      case NotificationType.ratingReply:
        return 'rating_reply';
    }
  }

  static NotificationType? fromString(String value) {
    switch (value) {
      case 'order_placed':
        return NotificationType.orderPlaced;
      case 'order_status_changed':
        return NotificationType.orderStatusChanged;
      case 'chat_message':
        return NotificationType.chatMessage;
      case 'rating_reply':
        return NotificationType.ratingReply;
      default:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.orderPlaced:
        return 'Order Placed';
      case NotificationType.orderStatusChanged:
        return 'Order Status Updated';
      case NotificationType.chatMessage:
        return 'New Message';
      case NotificationType.ratingReply:
        return 'New Reply';
    }
  }
}

class UserNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? orderId;
  final String? conversationId;
  final String? ratingId;
  final bool isRead;
  final DateTime createdAt;

  const UserNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.orderId,
    this.conversationId,
    this.ratingId,
    required this.isRead,
    required this.createdAt,
  });

  UserNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? orderId,
    String? conversationId,
    String? ratingId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return UserNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      orderId: orderId ?? this.orderId,
      conversationId: conversationId ?? this.conversationId,
      ratingId: ratingId ?? this.ratingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    // Parse timestamp from Supabase (stored as UTC TIMESTAMPTZ)
    // Supabase returns TIMESTAMPTZ as ISO8601 strings (e.g., "2024-01-15T10:30:00Z")
    // DateTime.parse() correctly parses these, but we need to convert UTC to local time
    // for proper comparison with DateTime.now() (which is in local time)
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      try {
        final parsed = DateTime.parse(json['created_at'] as String);
        // Convert UTC timestamps to local time for accurate time difference calculation
        // DateTime.now() returns local time, so we need both in the same timezone
        parsedCreatedAt = parsed.isUtc ? parsed.toLocal() : parsed;
      } catch (e) {
        // Fallback to current time if parsing fails
        parsedCreatedAt = DateTime.now();
      }
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return UserNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationTypeExtension.fromString(
        json['type'] as String,
      ) ?? NotificationType.orderPlaced,
      title: json['title'] as String,
      message: json['message'] as String,
      orderId: json['order_id'] as String?,
      conversationId: json['conversation_id'] as String?,
      ratingId: json['rating_id'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'order_id': orderId,
      'conversation_id': conversationId,
      'rating_id': ratingId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

