enum CampaignType { email, sms, push, social, banner, popup }

enum CampaignStatus { draft, scheduled, running, paused, completed, cancelled }

enum CampaignPriority { low, normal, high, urgent }

class MarketingCampaign {
  final String id;
  final String name;
  final String description;
  final CampaignType type;
  final CampaignStatus status;
  final CampaignPriority priority;
  final String targetAudience;
  final Map<String, dynamic> settings;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic> metrics;
  final double budget;
  final double spent;

  const MarketingCampaign({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.priority,
    required this.targetAudience,
    this.settings = const {},
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.metrics = const {},
    this.budget = 0.0,
    this.spent = 0.0,
  });

  MarketingCampaign copyWith({
    String? id,
    String? name,
    String? description,
    CampaignType? type,
    CampaignStatus? status,
    CampaignPriority? priority,
    String? targetAudience,
    Map<String, dynamic>? settings,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? metrics,
    double? budget,
    double? spent,
  }) {
    return MarketingCampaign(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      settings: settings ?? this.settings,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      metrics: metrics ?? this.metrics,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
    );
  }
}

class EmailCampaign extends MarketingCampaign {
  final String subject;
  final String content;
  final String templateId;
  final List<String> recipients;
  final List<String> ccRecipients;
  final List<String> bccRecipients;
  final String? replyTo;
  final Map<String, dynamic> personalization;

  const EmailCampaign({
    required super.id,
    required super.name,
    required super.description,
    super.type = CampaignType.email,
    required super.status,
    required super.priority,
    required super.targetAudience,
    super.settings = const {},
    super.scheduledAt,
    super.startedAt,
    super.endedAt,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    super.metrics = const {},
    super.budget = 0.0,
    super.spent = 0.0,
    required this.subject,
    required this.content,
    required this.templateId,
    this.recipients = const [],
    this.ccRecipients = const [],
    this.bccRecipients = const [],
    this.replyTo,
    this.personalization = const {},
  });

  @override
  EmailCampaign copyWith({
    String? id,
    String? name,
    String? description,
    CampaignType? type,
    CampaignStatus? status,
    CampaignPriority? priority,
    String? targetAudience,
    Map<String, dynamic>? settings,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? metrics,
    double? budget,
    double? spent,
    String? subject,
    String? content,
    String? templateId,
    List<String>? recipients,
    List<String>? ccRecipients,
    List<String>? bccRecipients,
    String? replyTo,
    Map<String, dynamic>? personalization,
  }) {
    return EmailCampaign(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      settings: settings ?? this.settings,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      metrics: metrics ?? this.metrics,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      templateId: templateId ?? this.templateId,
      recipients: recipients ?? this.recipients,
      ccRecipients: ccRecipients ?? this.ccRecipients,
      bccRecipients: bccRecipients ?? this.bccRecipients,
      replyTo: replyTo ?? this.replyTo,
      personalization: personalization ?? this.personalization,
    );
  }
}

class SMSCampaign extends MarketingCampaign {
  final String message;
  final String templateId;
  final List<String> recipients;
  final String? senderId;

  const SMSCampaign({
    required super.id,
    required super.name,
    required super.description,
    super.type = CampaignType.sms,
    required super.status,
    required super.priority,
    required super.targetAudience,
    super.settings = const {},
    super.scheduledAt,
    super.startedAt,
    super.endedAt,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    super.metrics = const {},
    super.budget = 0.0,
    super.spent = 0.0,
    required this.message,
    required this.templateId,
    this.recipients = const [],
    this.senderId,
  });

  @override
  SMSCampaign copyWith({
    String? id,
    String? name,
    String? description,
    CampaignType? type,
    CampaignStatus? status,
    CampaignPriority? priority,
    String? targetAudience,
    Map<String, dynamic>? settings,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? metrics,
    double? budget,
    double? spent,
    String? message,
    String? templateId,
    List<String>? recipients,
    String? senderId,
  }) {
    return SMSCampaign(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      settings: settings ?? this.settings,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      metrics: metrics ?? this.metrics,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      message: message ?? this.message,
      templateId: templateId ?? this.templateId,
      recipients: recipients ?? this.recipients,
      senderId: senderId ?? this.senderId,
    );
  }
}

class PushCampaign extends MarketingCampaign {
  final String title;
  final String message;
  final String? imageUrl;
  final String? actionUrl;
  final Map<String, dynamic> payload;
  final List<String> targetDevices;

  const PushCampaign({
    required super.id,
    required super.name,
    required super.description,
    super.type = CampaignType.push,
    required super.status,
    required super.priority,
    required super.targetAudience,
    super.settings = const {},
    super.scheduledAt,
    super.startedAt,
    super.endedAt,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
    super.metrics = const {},
    super.budget = 0.0,
    super.spent = 0.0,
    required this.title,
    required this.message,
    this.imageUrl,
    this.actionUrl,
    this.payload = const {},
    this.targetDevices = const [],
  });

  @override
  PushCampaign copyWith({
    String? id,
    String? name,
    String? description,
    CampaignType? type,
    CampaignStatus? status,
    CampaignPriority? priority,
    String? targetAudience,
    Map<String, dynamic>? settings,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? metrics,
    double? budget,
    double? spent,
    String? title,
    String? message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? payload,
    List<String>? targetDevices,
  }) {
    return PushCampaign(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      settings: settings ?? this.settings,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      metrics: metrics ?? this.metrics,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      payload: payload ?? this.payload,
      targetDevices: targetDevices ?? this.targetDevices,
    );
  }
}

class CampaignMetrics {
  final String campaignId;
  final int totalSent;
  final int totalDelivered;
  final int totalOpened;
  final int totalClicked;
  final int totalUnsubscribed;
  final int totalBounced;
  final double openRate;
  final double clickRate;
  final double conversionRate;
  final double revenue;
  final DateTime lastUpdated;

  const CampaignMetrics({
    required this.campaignId,
    this.totalSent = 0,
    this.totalDelivered = 0,
    this.totalOpened = 0,
    this.totalClicked = 0,
    this.totalUnsubscribed = 0,
    this.totalBounced = 0,
    this.openRate = 0.0,
    this.clickRate = 0.0,
    this.conversionRate = 0.0,
    this.revenue = 0.0,
    required this.lastUpdated,
  });

  CampaignMetrics copyWith({
    String? campaignId,
    int? totalSent,
    int? totalDelivered,
    int? totalOpened,
    int? totalClicked,
    int? totalUnsubscribed,
    int? totalBounced,
    double? openRate,
    double? clickRate,
    double? conversionRate,
    double? revenue,
    DateTime? lastUpdated,
  }) {
    return CampaignMetrics(
      campaignId: campaignId ?? this.campaignId,
      totalSent: totalSent ?? this.totalSent,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      totalOpened: totalOpened ?? this.totalOpened,
      totalClicked: totalClicked ?? this.totalClicked,
      totalUnsubscribed: totalUnsubscribed ?? this.totalUnsubscribed,
      totalBounced: totalBounced ?? this.totalBounced,
      openRate: openRate ?? this.openRate,
      clickRate: clickRate ?? this.clickRate,
      conversionRate: conversionRate ?? this.conversionRate,
      revenue: revenue ?? this.revenue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class MarketingTemplate {
  final String id;
  final String name;
  final String type;
  final String content;
  final Map<String, dynamic> variables;
  final String? previewImage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const MarketingTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    this.variables = const {},
    this.previewImage,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  MarketingTemplate copyWith({
    String? id,
    String? name,
    String? type,
    String? content,
    Map<String, dynamic>? variables,
    String? previewImage,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return MarketingTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      content: content ?? this.content,
      variables: variables ?? this.variables,
      previewImage: previewImage ?? this.previewImage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
