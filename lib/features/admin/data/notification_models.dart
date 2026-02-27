enum NotificationType { orderPlaced, lowStock, customerNew, system }

enum NotificationStatus { pending, sent, failed, scheduled }

enum NotificationPriority { low, normal, high, urgent }

enum NotificationEvent {
  orderCreated,
  stockLow,
  customerRegistered,
  systemAlert,
}

class EmailNotification {
  final String id;
  final String type;
  final String subject;
  final String body;
  final List<String> recipients;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime? createdAt;
  final DateTime? sentAt;
  final DateTime? scheduledAt;
  final Map<String, dynamic> data;

  const EmailNotification({
    required this.id,
    required this.type,
    required this.subject,
    required this.body,
    required this.recipients,
    required this.priority,
    required this.status,
    this.createdAt,
    this.sentAt,
    this.scheduledAt,
    this.data = const {},
  });

  EmailNotification copyWith({
    String? id,
    String? type,
    String? subject,
    String? body,
    List<String>? recipients,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? scheduledAt,
    Map<String, dynamic>? data,
  }) {
    return EmailNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      recipients: recipients ?? this.recipients,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      data: data ?? this.data,
    );
  }
}

class EmailTemplate {
  final String id;
  final String name;
  final String type;
  final String subject;
  final String body;
  final List<String> variables;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const EmailTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.subject,
    required this.body,
    required this.variables,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  EmailTemplate copyWith({
    String? id,
    String? name,
    String? type,
    String? subject,
    String? body,
    List<String>? variables,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return EmailTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      variables: variables ?? this.variables,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class NotificationRule {
  final String id;
  final String name;
  final String event;
  final String templateId;
  final List<String> recipients;
  final NotificationPriority priority;
  final Map<String, dynamic> conditions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationRule({
    required this.id,
    required this.name,
    required this.event,
    required this.templateId,
    required this.recipients,
    required this.priority,
    required this.conditions,
    required this.createdAt,
    required this.updatedAt,
  });

  NotificationRule copyWith({
    String? id,
    String? name,
    String? event,
    String? templateId,
    List<String>? recipients,
    NotificationPriority? priority,
    Map<String, dynamic>? conditions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      event: event ?? this.event,
      templateId: templateId ?? this.templateId,
      recipients: recipients ?? this.recipients,
      priority: priority ?? this.priority,
      conditions: conditions ?? this.conditions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NotificationLog {
  final String id;
  final String notificationId;
  final String recipient;
  final NotificationStatus status;
  final DateTime timestamp;

  const NotificationLog({
    required this.id,
    required this.notificationId,
    required this.recipient,
    required this.status,
    required this.timestamp,
  });

  NotificationLog copyWith({
    String? id,
    String? notificationId,
    String? recipient,
    NotificationStatus? status,
    DateTime? timestamp,
  }) {
    return NotificationLog(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      recipient: recipient ?? this.recipient,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
