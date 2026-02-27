import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_models.dart';
import '../../../core/config/environment.dart';

class AdminNotificationState {
  final List<EmailNotification> notifications;
  final List<EmailTemplate> templates;
  final List<NotificationRule> rules;
  final List<NotificationLog> logs;
  final String searchQuery;
  final NotificationStatus? selectedStatus;
  final NotificationType? selectedType;
  final bool loading;
  final String? error;
  final int pendingCount;
  final int sentCount;
  final int failedCount;

  const AdminNotificationState({
    this.notifications = const [],
    this.templates = const [],
    this.rules = const [],
    this.logs = const [],
    this.searchQuery = '',
    this.selectedStatus,
    this.selectedType,
    this.loading = false,
    this.error,
    this.pendingCount = 0,
    this.sentCount = 0,
    this.failedCount = 0,
  });

  AdminNotificationState copyWith({
    List<EmailNotification>? notifications,
    List<EmailTemplate>? templates,
    List<NotificationRule>? rules,
    List<NotificationLog>? logs,
    String? searchQuery,
    NotificationStatus? selectedStatus,
    NotificationType? selectedType,
    bool? loading,
    String? error,
    int? pendingCount,
    int? sentCount,
    int? failedCount,
  }) {
    return AdminNotificationState(
      notifications: notifications ?? this.notifications,
      templates: templates ?? this.templates,
      rules: rules ?? this.rules,
      logs: logs ?? this.logs,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedType: selectedType ?? this.selectedType,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      pendingCount: pendingCount ?? this.pendingCount,
      sentCount: sentCount ?? this.sentCount,
      failedCount: failedCount ?? this.failedCount,
    );
  }
}

class AdminNotificationController
    extends StateNotifier<AdminNotificationState> {
  AdminNotificationController() : super(const AdminNotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(loading: true, error: null);

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      final mockNotifications = _generateMockNotifications();
      final mockTemplates = _generateMockTemplates();
      final mockRules = _generateMockRules();
      final mockLogs = _generateMockLogs();

      final pendingCount =
          mockNotifications
              .where((n) => n.status == NotificationStatus.pending)
              .length;
      final sentCount =
          mockNotifications
              .where((n) => n.status == NotificationStatus.sent)
              .length;
      final failedCount =
          mockNotifications
              .where((n) => n.status == NotificationStatus.failed)
              .length;

      state = state.copyWith(
        notifications: mockNotifications,
        templates: mockTemplates,
        rules: mockRules,
        logs: mockLogs,
        pendingCount: pendingCount,
        sentCount: sentCount,
        failedCount: failedCount,
        loading: false,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  void searchNotifications(String query) {
    state = state.copyWith(searchQuery: query);

    final filtered =
        state.notifications.where((notification) {
          final matchesSearch =
              notification.subject.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              notification.type.toLowerCase().contains(query.toLowerCase());

          final matchesStatus =
              state.selectedStatus == null ||
              notification.status == state.selectedStatus;
          final matchesType =
              state.selectedType == null ||
              notification.type == state.selectedType?.name;

          return matchesSearch && matchesStatus && matchesType;
        }).toList();

    state = state.copyWith(notifications: filtered);
  }

  void filterByStatus(NotificationStatus? status) {
    state = state.copyWith(selectedStatus: status);
    _applyFilters();
  }

  void filterByType(NotificationType? type) {
    state = state.copyWith(selectedType: type);
    _applyFilters();
  }

  void _applyFilters() {
    final filtered =
        state.notifications.where((notification) {
          final matchesSearch =
              notification.subject.toLowerCase().contains(
                state.searchQuery.toLowerCase(),
              ) ||
              notification.type.toLowerCase().contains(
                state.searchQuery.toLowerCase(),
              );

          final matchesStatus =
              state.selectedStatus == null ||
              notification.status == state.selectedStatus;
          final matchesType =
              state.selectedType == null ||
              notification.type == state.selectedType?.name;

          return matchesSearch && matchesStatus && matchesType;
        }).toList();

    state = state.copyWith(notifications: filtered);
  }

  Future<bool> sendNotification(EmailNotification notification) async {
    try {
      state = state.copyWith(loading: true);

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 2000));

      if (!mounted) return false;

      final updatedNotification = notification.copyWith(
        status: NotificationStatus.sent,
        sentAt: DateTime.now(),
      );

      state = state.copyWith(
        notifications: [...state.notifications, updatedNotification],
        loading: false,
      );

      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> scheduleNotification(
    EmailNotification notification,
    DateTime scheduledAt,
  ) async {
    try {
      final scheduledNotification = notification.copyWith(
        status: NotificationStatus.scheduled,
        scheduledAt: scheduledAt,
      );

      state = state.copyWith(
        notifications: [...state.notifications, scheduledNotification],
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> createTemplate(EmailTemplate template) async {
    try {
      state = state.copyWith(templates: [...state.templates, template]);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> createRule(NotificationRule rule) async {
    try {
      state = state.copyWith(rules: [...state.rules, rule]);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> testNotification(
    String templateId,
    List<String> testRecipients,
  ) async {
    try {
      final template = state.templates.firstWhere((t) => t.id == templateId);

      final testNotification = EmailNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: template.type,
        subject: 'TEST: ${template.subject}',
        body: template.body,
        recipients: testRecipients,
        priority: NotificationPriority.normal,
        status: NotificationStatus.sent,
        createdAt: DateTime.now(),
        sentAt: DateTime.now(),
        data: {'isTest': true},
      );

      state = state.copyWith(
        notifications: [...state.notifications, testNotification],
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  List<EmailNotification> _generateMockNotifications() {
    return [
      EmailNotification(
        id: 'notif_1',
        type: NotificationType.orderPlaced.name,
        subject: 'New Order #12345',
        body: 'A new order has been placed by customer John Doe for \$299.99',
        recipients: [Environment.adminEmail, Environment.salesEmail],
        priority: NotificationPriority.high,
        status: NotificationStatus.sent,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
        data: {'orderId': '12345', 'customerName': 'John Doe'},
      ),
      EmailNotification(
        id: 'notif_2',
        type: NotificationType.lowStock.name,
        subject: 'Low Stock Alert',
        body: 'Smart Watch stock is below reorder point (8/15)',
        recipients: [Environment.inventoryEmail],
        priority: NotificationPriority.normal,
        status: NotificationStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        data: {'productId': 'prod_2', 'currentStock': 8, 'reorderPoint': 15},
      ),
      EmailNotification(
        id: 'notif_3',
        type: NotificationType.customerNew.name,
        subject: 'New Customer Registration',
        body: 'New customer Jane Smith has registered',
        recipients: [Environment.adminEmail],
        priority: NotificationPriority.normal,
        status: NotificationStatus.sent,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        sentAt: DateTime.now().subtract(const Duration(hours: 5)),
        data: {'customerId': 'cust_123', 'customerName': 'Jane Smith'},
      ),
    ];
  }

  List<EmailTemplate> _generateMockTemplates() {
    return [
      EmailTemplate(
        id: 'template_1',
        name: 'Order Confirmation',
        type: NotificationType.orderPlaced.name,
        subject: 'Order Confirmation - #{orderNumber}',
        body:
            'Dear {customerName},\n\nThank you for your order! Your order #{orderNumber} has been confirmed.\n\nOrder Total: {orderTotal}\n\nWe will send you a tracking number once your order ships.\n\nBest regards,\nSM Team',
        variables: ['orderNumber', 'customerName', 'orderTotal'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        createdBy: 'admin',
      ),
      EmailTemplate(
        id: 'template_2',
        name: 'Low Stock Alert',
        type: NotificationType.lowStock.name,
        subject: 'Low Stock Alert - {productName}',
        body:
            'Alert: {productName} (SKU: {sku}) is running low on stock.\n\nCurrent Stock: {currentStock}\nReorder Point: {reorderPoint}\n\nPlease consider placing a new order.\n\nInventory Team',
        variables: ['productName', 'sku', 'currentStock', 'reorderPoint'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        createdBy: 'admin',
      ),
    ];
  }

  List<NotificationRule> _generateMockRules() {
    return [
      NotificationRule(
        id: 'rule_1',
        name: 'Order Placed Notifications',
        event: NotificationEvent.orderCreated.name,
        templateId: 'template_1',
        recipients: [Environment.adminEmail, Environment.salesEmail],
        priority: NotificationPriority.high,
        conditions: {'minOrderValue': 100},
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      NotificationRule(
        id: 'rule_2',
        name: 'Low Stock Alerts',
        event: NotificationEvent.stockLow.name,
        templateId: 'template_2',
        recipients: [Environment.inventoryEmail],
        priority: NotificationPriority.normal,
        conditions: {'stockThreshold': 10},
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  List<NotificationLog> _generateMockLogs() {
    return [
      NotificationLog(
        id: 'log_1',
        notificationId: 'notif_1',
        recipient: Environment.adminEmail,
        status: NotificationStatus.sent,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationLog(
        id: 'log_2',
        notificationId: 'notif_1',
        recipient: Environment.salesEmail,
        status: NotificationStatus.sent,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationLog(
        id: 'log_3',
        notificationId: 'notif_3',
        recipient: Environment.adminEmail,
        status: NotificationStatus.sent,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }
}

final adminNotificationControllerProvider =
    StateNotifierProvider<AdminNotificationController, AdminNotificationState>(
      (ref) => AdminNotificationController(),
    );
