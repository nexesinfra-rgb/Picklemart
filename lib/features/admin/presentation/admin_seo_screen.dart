import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/layout/responsive.dart';
import '../application/admin_seo_controller.dart';
import '../data/seo_models.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';

class AdminSEOScreen extends ConsumerStatefulWidget {
  const AdminSEOScreen({super.key});

  @override
  ConsumerState<AdminSEOScreen> createState() => _AdminSEOScreenState();
}

class _AdminSEOScreenState extends ConsumerState<AdminSEOScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seoState = ref.watch(adminSEOControllerProvider);
    final screenSize = Responsive.getScreenSize(context);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'SEO Tools',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminSEOControllerProvider.notifier).refresh();
            },
          ),
        ],
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
                Tab(text: 'Meta Tags', icon: Icon(Icons.tag)),
                Tab(text: 'Sitemap', icon: Icon(Icons.map)),
                Tab(text: 'Robots.txt', icon: Icon(Icons.settings)),
              ],
            ),
            Expanded(
              child:
                  seoState.loading
                      ? const Center(child: CircularProgressIndicator())
                      : seoState.error != null
                      ? _buildErrorState(seoState.error!)
                      : _buildTabContent(seoState, screenSize),
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
            'Failed to load SEO data',
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
              ref.read(adminSEOControllerProvider.notifier).refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(AdminSEOState state, ScreenSize screenSize) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAnalysisTab(state, screenSize),
        _buildMetaTagsTab(state, screenSize),
        _buildSitemapTab(state, screenSize),
        _buildRobotsTab(state, screenSize),
      ],
    );
  }

  Widget _buildAnalysisTab(AdminSEOState state, ScreenSize screenSize) {
    return SingleChildScrollView(
      child: Column(
        children: [_buildUrlAnalyzer(), _buildAnalysisList(state, screenSize)],
      ),
    );
  }

  Widget _buildUrlAnalyzer() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Analyze URL', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Enter URL to analyze',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _analyzeUrl(),
                  child: const Text('Analyze'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisList(AdminSEOState state, ScreenSize screenSize) {
    if (state.analyses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No SEO analyses found',
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
          state.analyses.map((analysis) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAnalysisItem(analysis, screenSize),
            );
          }).toList(),
    );
  }

  Widget _buildAnalysisItem(SEOAnalysis analysis, ScreenSize screenSize) {
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
                        analysis.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        analysis.url,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildScoreChip(analysis.score),
              ],
            ),
            const SizedBox(height: 12),
            Text(analysis.description),
            const SizedBox(height: 12),
            _buildMetricsRow(analysis.metrics),
            const SizedBox(height: 12),
            if (analysis.issues.isNotEmpty) ...[
              Text(
                'Issues (${analysis.issues.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...analysis.issues.take(3).map((issue) => _buildIssueItem(issue)),
              if (analysis.issues.length > 3)
                Text(
                  '... and ${analysis.issues.length - 3} more issues',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewAnalysisDetails(analysis),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reanalyzeUrl(analysis.url),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reanalyze'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(int score) {
    Color color;
    if (score >= 90) {
      color = Colors.green;
    } else if (score >= 70) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$score/100',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic> metrics) {
    return Row(
      children: [
        _buildMetricItem('Speed', '${metrics['page_speed'] ?? 0}'),
        const SizedBox(width: 16),
        _buildMetricItem('Mobile', '${metrics['mobile_friendly'] ?? 0}'),
        const SizedBox(width: 16),
        _buildMetricItem('Accessibility', '${metrics['accessibility'] ?? 0}'),
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
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildIssueItem(SEOIssue issue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getIssueIcon(issue.priority),
            size: 16,
            color: _getPriorityColor(issue.priority),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              issue.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIssueIcon(SEOPriority priority) {
    switch (priority) {
      case SEOPriority.critical:
        return Icons.error;
      case SEOPriority.high:
        return Icons.warning;
      case SEOPriority.normal:
        return Icons.info;
      case SEOPriority.low:
        return Icons.info_outline;
    }
  }

  Color _getPriorityColor(SEOPriority priority) {
    switch (priority) {
      case SEOPriority.critical:
        return Colors.red;
      case SEOPriority.high:
        return Colors.orange;
      case SEOPriority.normal:
        return Colors.blue;
      case SEOPriority.low:
        return Colors.grey;
    }
  }

  Widget _buildMetaTagsTab(AdminSEOState state, ScreenSize screenSize) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Meta Tags',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateMetaTagDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Meta Tag'),
                ),
              ],
            ),
          ),
          _buildMetaTagsList(state, screenSize),
        ],
      ),
    );
  }

  Widget _buildMetaTagsList(AdminSEOState state, ScreenSize screenSize) {
    if (state.metaTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No meta tags found',
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
          state.metaTags.map((metaTag) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMetaTagItem(metaTag, screenSize),
            );
          }).toList(),
    );
  }

  Widget _buildMetaTagItem(SEOMetaTag metaTag, ScreenSize screenSize) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(metaTag.name),
        subtitle: Text(metaTag.content),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editMetaTag(metaTag),
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () => _deleteMetaTag(metaTag.id),
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSitemapTab(AdminSEOState state, ScreenSize screenSize) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sitemap',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _generateSitemap(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate'),
                ),
              ],
            ),
          ),
          _buildSitemapList(state, screenSize),
        ],
      ),
    );
  }

  Widget _buildSitemapList(AdminSEOState state, ScreenSize screenSize) {
    if (state.sitemaps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No sitemap entries found',
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
          state.sitemaps.map((sitemap) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSitemapItem(sitemap, screenSize),
            );
          }).toList(),
    );
  }

  Widget _buildSitemapItem(SEOSitemap sitemap, ScreenSize screenSize) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(sitemap.url),
        subtitle: Text(
          'Priority: ${sitemap.priority} | Frequency: ${sitemap.changeFrequency}',
        ),
        trailing: Text(_formatDate(sitemap.lastModified)),
      ),
    );
  }

  Widget _buildRobotsTab(AdminSEOState state, ScreenSize screenSize) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Robots.txt',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _editRobotsTxt(),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child:
                    state.robotsTxt != null
                        ? Text(
                          state.robotsTxt!.content,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontFamily: 'monospace'),
                        )
                        : const Text('No robots.txt content'),
              ),
            ),
          ),
        ],
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

  void _analyzeUrl() async {
    if (_urlController.text.isNotEmpty) {
      final success = await ref
          .read(adminSEOControllerProvider.notifier)
          .analyzeUrl(_urlController.text);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL analyzed successfully')),
        );
        _urlController.clear();
      }
    }
  }

  void _reanalyzeUrl(String url) async {
    final success = await ref
        .read(adminSEOControllerProvider.notifier)
        .analyzeUrl(url);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL reanalyzed successfully')),
      );
    }
  }

  void _viewAnalysisDetails(SEOAnalysis analysis) {
    // Implementation for viewing analysis details
  }

  void _showCreateMetaTagDialog() {
    // Implementation for creating meta tag
  }

  void _editMetaTag(SEOMetaTag metaTag) {
    // Implementation for editing meta tag
  }

  void _deleteMetaTag(String metaTagId) async {
    final success = await ref
        .read(adminSEOControllerProvider.notifier)
        .deleteMetaTag(metaTagId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Meta tag deleted')));
    }
  }

  void _generateSitemap() {
    // Implementation for generating sitemap
  }

  void _editRobotsTxt() {
    // Implementation for editing robots.txt
  }
}
