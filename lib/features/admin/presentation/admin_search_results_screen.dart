import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../application/admin_search_results_controller.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';

class AdminSearchResultsScreen extends ConsumerStatefulWidget {
  const AdminSearchResultsScreen({super.key});

  @override
  ConsumerState<AdminSearchResultsScreen> createState() =>
      _AdminSearchResultsScreenState();
}

class _AdminSearchResultsScreenState
    extends ConsumerState<AdminSearchResultsScreen> {
  bool _isInitialized = false;
  String? _entryRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final state = GoRouterState.of(context);
      final previousRoute = state.uri.queryParameters['previousRoute'];

      if (previousRoute != null && previousRoute.isNotEmpty) {
        _entryRoute = previousRoute;
      } else if (context.canPop()) {
        _entryRoute = '/admin/dashboard';
      } else {
        _entryRoute = null;
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsState = ref.watch(adminSearchResultsControllerProvider);
    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;

    return AdminAuthGuard(
      child: _buildMainContent(
        context,
        searchResultsState,
        screenSize,
        width,
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    AdminSearchResultsState state,
    ScreenSize screenSize,
    double width,
  ) {
    return AdminScaffold(
      title: 'Search Results',
      showBackButton: true,
      onBackPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(_entryRoute ?? '/admin/dashboard');
        }
      },
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorState(context, state.error!)
              : state.searchResults.isEmpty
                  ? _buildEmptyState(context)
                  : _buildResponsiveTable(context, state, width),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.warning_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading search results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref
                  .read(adminSearchResultsControllerProvider.notifier)
                  .refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.search_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No search results found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Search queries with no results will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveTable(
    BuildContext context,
    AdminSearchResultsState state,
    double width,
  ) {
    final isCompact = Responsive.isMobile(width);
    final spacing = Responsive.getSpacingForFoldable(width);

    return Column(
      children: [
        // Header with refresh button
        Padding(
          padding: EdgeInsets.all(spacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${state.totalCount} (Page ${state.currentPage}/${state.totalPages})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Ionicons.refresh_outline),
                onPressed: () {
                  ref
                      .read(adminSearchResultsControllerProvider.notifier)
                      .refresh();
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        // Responsive table with horizontal and vertical scrolling
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing),
                      child: DataTable(
                  columnSpacing: isCompact ? 16 : 24,
                  horizontalMargin: isCompact ? 12 : 16,
                  headingRowHeight: isCompact ? 48 : 56,
                  dataRowHeight: isCompact ? 52 : 60,
                  columns: [
                    DataColumn(
                      label: Text(
                        'User',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 12 : 14,
                            ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Email',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 12 : 14,
                            ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Phone',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 12 : 14,
                            ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Search Query',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 12 : 14,
                            ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Searched At',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 12 : 14,
                            ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 12 : 14,
                            ),
                      ),
                    ),
                  ],
                  rows: state.searchResults.map((result) {
                    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            result.displayUserName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: isCompact ? 12 : 14,
                                ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isCompact ? 150 : 200,
                            ),
                            child: Text(
                              result.displayEmail,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: isCompact ? 11 : 13,
                                    color: result.email != null
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            result.displayPhone,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: isCompact ? 11 : 13,
                                  color: result.phone != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isCompact ? 200 : 300,
                            ),
                            child: Text(
                              result.searchQuery,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: isCompact ? 12 : 14,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            dateFormat.format(result.searchedAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: isCompact ? 11 : 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Ionicons.trash_outline),
                            color: Theme.of(context).colorScheme.error,
                            onPressed: () => _showDeleteDialog(context, result),
                            tooltip: 'Delete',
                            iconSize: isCompact ? 18 : 20,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              // Pagination controls
              Container(
                padding: EdgeInsets.all(spacing),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Ionicons.chevron_back_outline),
                      onPressed: state.hasPreviousPage
                          ? () {
                              ref
                                  .read(adminSearchResultsControllerProvider
                                      .notifier)
                                  .loadPreviousPage();
                            }
                          : null,
                      tooltip: 'Previous Page',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Page ${state.currentPage} of ${state.totalPages}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Ionicons.chevron_forward_outline),
                      onPressed: state.hasNextPage
                          ? () {
                              ref
                                  .read(adminSearchResultsControllerProvider
                                      .notifier)
                                  .loadNextPage();
                            }
                          : null,
                      tooltip: 'Next Page',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, SearchResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Search Result'),
        content: Text(
          'Are you sure you want to delete the search query "${result.searchQuery}"?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              
              final success = await ref
                  .read(adminSearchResultsControllerProvider.notifier)
                  .deleteSearchResult(result.id);
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Search result deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete search result'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

