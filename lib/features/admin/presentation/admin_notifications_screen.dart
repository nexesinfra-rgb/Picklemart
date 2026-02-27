import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/layout/responsive.dart';
import '../application/admin_notification_controller.dart';
import '../data/notification_models.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _selectedStatus = 'all';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(adminNotificationControllerProvider);
    final screenSize = Responsive.getScreenSize(context);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Email Notifications',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateNotificationDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(adminNotificationControllerProvider.notifier)
                  .refresh();
            },
          ),
        ],
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Notifications', icon: Icon(Icons.email)),
                Tab(text: 'Templates', icon: Icon(Icons.description)),
                Tab(text: 'Rules', icon: Icon(Icons.rule)),
                Tab(text: 'Logs', icon: Icon(Icons.history)),
              ],
            ),
            Expanded(
              child:
                  notificationState.loading
                      ? const Center(child: CircularProgressIndicator())
                      : notificationState.error != null
                      ? _buildErrorState(notificationState.error!)
                      : _buildTabContent(notificationState, screenSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(adminNotificationControllerProvider.notifier).refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(AdminNotificationState state, ScreenSize screenSize) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildNotificationsTab(state, screenSize),
        _buildTemplatesTab(state, screenSize),
        _buildRulesTab(state, screenSize),
        _buildLogsTab(state, screenSize),
      ],
    );
  }

  Widget _buildNotificationsTab(
    AdminNotificationState state,
    ScreenSize screenSize,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSearchAndFilters(),
          _buildStatsCards(state),
          _buildNotificationsList(state.notifications, screenSize),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab(
    AdminNotificationState state,
    ScreenSize screenSize,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Email Templates',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateTemplateDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Template'),
                ),
              ],
            ),
          ),
          _buildTemplatesList(state.templates, screenSize),
        ],
      ),
    );
  }

  Widget _buildRulesTab(AdminNotificationState state, ScreenSize screenSize) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notification Rules',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateRuleDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Rule'),
                ),
              ],
            ),
          ),
          _buildRulesList(state.rules, screenSize),
        ],
      ),
    );
  }

  Widget _buildLogsTab(AdminNotificationState state, ScreenSize screenSize) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Notification Logs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _buildLogsList(state.logs, screenSize),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(
                                  adminNotificationControllerProvider.notifier,
                                )
                                .searchNotifications('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref
                    .read(adminNotificationControllerProvider.notifier)
                    .searchNotifications(value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(value: 'sent', child: Text('Sent')),
                      DropdownMenuItem(value: 'failed', child: Text('Failed')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value ?? 'all';
                      });
                      ref
                          .read(adminNotificationControllerProvider.notifier)
                          .filterByStatus(
                            value == 'all'
                                ? null
                                : NotificationStatus.values.firstWhere(
                                  (s) => s.name == value,
                                ),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Types')),
                      DropdownMenuItem(
                        value: 'order_placed',
                        child: Text('Order Placed'),
                      ),
                      DropdownMenuItem(
                        value: 'low_stock',
                        child: Text('Low Stock'),
                      ),
                      DropdownMenuItem(
                        value: 'customer_registration',
                        child: Text('Customer Registration'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value ?? 'all';
                      });
                      ref
                          .read(adminNotificationControllerProvider.notifier)
                          .filterByType(
                            value == 'all'
                                ? null
                                : NotificationType.values.firstWhere(
                                  (t) => t.name == value,
                                ),
                          );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(AdminNotificationState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Pending',
              state.pendingCount.toString(),
              Colors.orange,
              Icons.schedule,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Sent',
              state.sentCount.toString(),
              Colors.green,
              Icons.check_circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Failed',
              state.failedCount.toString(),
              Colors.red,
              Icons.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    List<EmailNotification> notifications,
    ScreenSize screenSize,
  ) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          notifications.map((notification) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNotificationItem(notification, screenSize),
            );
          }).toList(),
    );
  }

  Widget _buildNotificationItem(
    EmailNotification notification,
    ScreenSize screenSize,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.subject,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${notification.type}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(notification.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification.body,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${notification.recipients.length} recipients',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (notification.createdAt != null)
                  Text(
                    _formatDate(notification.createdAt!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (notification.status == NotificationStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendNotification(notification),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Send Now'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showNotificationDetails(notification),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(NotificationStatus status) {
    Color color;
    String text;

    switch (status) {
      case NotificationStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case NotificationStatus.sent:
        color = Colors.green;
        text = 'Sent';
        break;
      case NotificationStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
      case NotificationStatus.scheduled:
        color = Colors.blue;
        text = 'Scheduled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTemplatesList(
    List<EmailTemplate> templates,
    ScreenSize screenSize,
  ) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No templates found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          templates.map((template) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTemplateItem(template, screenSize),
            );
          }).toList(),
    );
  }

  Widget _buildTemplateItem(EmailTemplate template, ScreenSize screenSize) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${template.type}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _testTemplate(template),
                  icon: const Icon(Icons.send),
                  tooltip: 'Test Template',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              template.subject,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              template.body,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (template.variables.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children:
                    template.variables
                        .map(
                          (variable) => Chip(
                            label: Text(variable),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRulesList(List<NotificationRule> rules, ScreenSize screenSize) {
    if (rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rule_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No rules found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          rules.map((rule) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRuleItem(rule, screenSize),
            );
          }).toList(),
    );
  }

  Widget _buildRuleItem(NotificationRule rule, ScreenSize screenSize) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Event: ${rule.event}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: true, // Assuming rule is active
                  onChanged: (value) {
                    // Handle rule toggle
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Template: ${rule.templateId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Recipients: ${rule.recipients.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (rule.conditions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Conditions: ${rule.conditions.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList(List<NotificationLog> logs, ScreenSize screenSize) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No logs found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          logs.map((log) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildLogItem(log, screenSize),
            );
          }).toList(),
    );
  }

  Widget _buildLogItem(NotificationLog log, ScreenSize screenSize) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.recipient,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(log.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Notification ID: ${log.notificationId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sent: ${_formatDate(log.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void _sendNotification(EmailNotification notification) async {
    final success = await ref
        .read(adminNotificationControllerProvider.notifier)
        .sendNotification(notification);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully')),
      );
    }
  }

  void _testTemplate(EmailTemplate template) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Test Template - ${template.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Test Recipients (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle test template
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Send Test'),
              ),
            ],
          ),
    );
  }

  void _showNotificationDetails(EmailNotification notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(notification.subject),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Type', notification.type),
                  _buildDetailRow('Status', notification.status.name),
                  _buildDetailRow('Priority', notification.priority.name),
                  _buildDetailRow(
                    'Recipients',
                    notification.recipients.join(', '),
                  ),
                  if (notification.createdAt != null)
                    _buildDetailRow(
                      'Created',
                      _formatDate(notification.createdAt!),
                    ),
                  if (notification.sentAt != null)
                    _buildDetailRow('Sent', _formatDate(notification.sentAt!)),
                  const SizedBox(height: 16),
                  Text(
                    'Body:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(notification.body),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _showCreateNotificationDialog() {
    // Implementation for creating new notification
  }

  void _showCreateTemplateDialog() {
    // Implementation for creating new template
  }

  void _showCreateRuleDialog() {
    // Implementation for creating new rule
  }
}
