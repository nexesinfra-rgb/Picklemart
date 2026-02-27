import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/layout/responsive.dart';
import '../application/admin_marketing_controller.dart';
import '../data/marketing_models.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';

class AdminMarketingScreen extends ConsumerStatefulWidget {
  const AdminMarketingScreen({super.key});

  @override
  ConsumerState<AdminMarketingScreen> createState() =>
      _AdminMarketingScreenState();
}

class _AdminMarketingScreenState extends ConsumerState<AdminMarketingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketingState = ref.watch(adminMarketingControllerProvider);
    final screenSize = Responsive.getScreenSize(context);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Marketing',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCampaignDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminMarketingControllerProvider.notifier).refresh();
            },
          ),
        ],
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Campaigns', icon: Icon(Icons.campaign)),
                Tab(text: 'Templates', icon: Icon(Icons.description)),
                Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
              ],
            ),
            Expanded(
              child:
                  marketingState.loading
                      ? const Center(child: CircularProgressIndicator())
                      : marketingState.error != null
                      ? _buildErrorState(marketingState.error!)
                      : _buildTabContent(marketingState, screenSize),
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
            'Failed to load marketing data',
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
              ref.read(adminMarketingControllerProvider.notifier).refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(AdminMarketingState state, ScreenSize screenSize) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCampaignsTab(state, screenSize),
        _buildTemplatesTab(state, screenSize),
        _buildAnalyticsTab(state, screenSize),
      ],
    );
  }

  Widget _buildCampaignsTab(AdminMarketingState state, ScreenSize screenSize) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSearchAndFilters(),
          _buildCampaignsList(state, screenSize),
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
                hintText: 'Search campaigns...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(adminMarketingControllerProvider.notifier)
                                .searchCampaigns('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref
                    .read(adminMarketingControllerProvider.notifier)
                    .searchCampaigns(value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CampaignType?>(
                    initialValue: null,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ...CampaignType.values.map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref
                          .read(adminMarketingControllerProvider.notifier)
                          .filterByType(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<CampaignStatus?>(
                    initialValue: null,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Status'),
                      ),
                      ...CampaignStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref
                          .read(adminMarketingControllerProvider.notifier)
                          .filterByStatus(value);
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

  Widget _buildCampaignsList(AdminMarketingState state, ScreenSize screenSize) {
    if (state.filteredCampaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No campaigns found',
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
          state.filteredCampaigns.map((campaign) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCampaignItem(campaign, screenSize),
            );
          }).toList(),
    );
  }

  Widget _buildCampaignItem(MarketingCampaign campaign, ScreenSize screenSize) {
    final metrics = ref
        .read(adminMarketingControllerProvider.notifier)
        .getCampaignMetrics(campaign.id);

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
                        campaign.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        campaign.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(campaign.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeChip(campaign.type),
                const SizedBox(width: 8),
                _buildPriorityChip(campaign.priority),
              ],
            ),
            const SizedBox(height: 12),
            if (metrics != null) _buildMetricsRow(metrics),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Budget: ₹${campaign.budget.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Spent: ₹${campaign.spent.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(campaign.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (campaign.status == CampaignStatus.draft) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startCampaign(campaign.id),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Start'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (campaign.status == CampaignStatus.running) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pauseCampaign(campaign.id),
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Pause'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewCampaignDetails(campaign),
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

  Widget _buildStatusChip(CampaignStatus status) {
    Color color;
    String text;

    switch (status) {
      case CampaignStatus.draft:
        color = Colors.grey;
        text = 'Draft';
        break;
      case CampaignStatus.scheduled:
        color = Colors.blue;
        text = 'Scheduled';
        break;
      case CampaignStatus.running:
        color = Colors.green;
        text = 'Running';
        break;
      case CampaignStatus.paused:
        color = Colors.orange;
        text = 'Paused';
        break;
      case CampaignStatus.completed:
        color = Colors.purple;
        text = 'Completed';
        break;
      case CampaignStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
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

  Widget _buildTypeChip(CampaignType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.name,
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(CampaignPriority priority) {
    Color color;
    switch (priority) {
      case CampaignPriority.low:
        color = Colors.green;
        break;
      case CampaignPriority.normal:
        color = Colors.blue;
        break;
      case CampaignPriority.high:
        color = Colors.orange;
        break;
      case CampaignPriority.urgent:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.name,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetricsRow(CampaignMetrics metrics) {
    return Row(
      children: [
        _buildMetricItem('Sent', metrics.totalSent.toString()),
        const SizedBox(width: 16),
        _buildMetricItem('Opened', '${metrics.openRate.toStringAsFixed(1)}%'),
        const SizedBox(width: 16),
        _buildMetricItem('Clicked', '${metrics.clickRate.toStringAsFixed(1)}%'),
        const SizedBox(width: 16),
        _buildMetricItem('Revenue', '₹${metrics.revenue.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesTab(AdminMarketingState state, ScreenSize screenSize) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Marketing Templates',
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
          _buildTemplatesList(state, screenSize),
        ],
      ),
    );
  }

  Widget _buildTemplatesList(AdminMarketingState state, ScreenSize screenSize) {
    if (state.templates.isEmpty) {
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
          state.templates.map((template) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTemplateItem(template, screenSize),
            );
          }).toList(),
    );
  }

  Widget _buildTemplateItem(MarketingTemplate template, ScreenSize screenSize) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(template.name),
        subtitle: Text(template.type),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editTemplate(template),
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () => _deleteTemplate(template.id),
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(AdminMarketingState state, ScreenSize screenSize) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Marketing Analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: screenSize == ScreenSize.desktop ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildAnalyticsCard(
                  'Total Campaigns',
                  state.campaigns.length.toString(),
                  Icons.campaign,
                  Colors.blue,
                ),
                _buildAnalyticsCard(
                  'Active Campaigns',
                  state.campaigns
                      .where((c) => c.status == CampaignStatus.running)
                      .length
                      .toString(),
                  Icons.play_circle,
                  Colors.green,
                ),
                _buildAnalyticsCard(
                  'Total Templates',
                  state.templates.length.toString(),
                  Icons.description,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  void _showCreateCampaignDialog() {
    // Implementation for creating new campaign
  }

  void _startCampaign(String campaignId) async {
    final success = await ref
        .read(adminMarketingControllerProvider.notifier)
        .startCampaign(campaignId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Campaign started')));
    }
  }

  void _pauseCampaign(String campaignId) async {
    final success = await ref
        .read(adminMarketingControllerProvider.notifier)
        .pauseCampaign(campaignId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Campaign paused')));
    }
  }

  void _viewCampaignDetails(MarketingCampaign campaign) {
    // Implementation for viewing campaign details
  }

  void _showCreateTemplateDialog() {
    // Implementation for creating template
  }

  void _editTemplate(MarketingTemplate template) {
    // Implementation for editing template
  }

  void _deleteTemplate(String templateId) {
    // Implementation for deleting template
  }
}
