import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/providers/supabase_provider.dart';
import '../application/multi_device_controller.dart';
import '../data/multi_device_repository.dart';
import '../domain/multi_device_tracking.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import 'multi_device_map_view.dart';

class MultiDeviceTrackingScreen extends ConsumerStatefulWidget {
  final int? initialTab;
  
  const MultiDeviceTrackingScreen({super.key, this.initialTab});

  @override
  ConsumerState<MultiDeviceTrackingScreen> createState() =>
      _MultiDeviceTrackingScreenState();
}

class _MultiDeviceTrackingScreenState
    extends ConsumerState<MultiDeviceTrackingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  late TabController _tabController;
  Timer? _liveUsersRefreshTimer;
  DateTime? _lastLiveUsersUpdate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Navigate to initial tab if specified
    if (widget.initialTab != null && widget.initialTab! >= 0 && widget.initialTab! < 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(widget.initialTab!);
        }
      });
    }
    
    // Load all users data by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(multiDeviceControllerProvider.notifier).loadAllUsers();
      }
    });
    
    _startLiveUsersRefresh();
  }

  @override
  void dispose() {
    _liveUsersRefreshTimer?.cancel();
    _tabController.removeListener(_handleTabChange);
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    // Start/stop refresh timer based on active tab
    if (_tabController.index == 3) {
      // Live Users tab is active
      _startLiveUsersRefresh();
    } else {
      // Other tab is active, stop the timer
      _liveUsersRefreshTimer?.cancel();
      _liveUsersRefreshTimer = null;
    }
  }

  void _startLiveUsersRefresh() {
    _liveUsersRefreshTimer?.cancel();
    _liveUsersRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        if (mounted && _tabController.index == 3) {
          // Only refresh if Live Users tab is still active
          setState(() {
            _lastLiveUsersUpdate = DateTime.now();
          });
        }
      },
    );
  }

  void _searchDevices() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isNotEmpty) {
      ref.read(multiDeviceControllerProvider.notifier).searchByPhoneNumber(phoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(multiDeviceControllerProvider);
    final width = MediaQuery.of(context).size.width;
    
    // Get previousRoute from query parameters to handle back navigation
    final routerState = GoRouterState.of(context);
    final previousRoute = routerState.uri.queryParameters['previousRoute'];

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Multi-Device Tracking',
        showBackButton: true,
        onBackPressed: () {
          // Check if we have a previousRoute query parameter
          if (previousRoute != null && previousRoute.isNotEmpty) {
            // Navigate back to the previous route (e.g., /admin/more)
            context.go(previousRoute);
          } else if (context.canPop()) {
            // Use default pop behavior if navigation stack exists
            context.pop();
          } else {
            // Fallback to dashboard if no previous route and can't pop
            context.go('/admin/dashboard');
          }
        },
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh_outline),
            onPressed: () {
              final currentState = ref.read(multiDeviceControllerProvider);
              if (currentState.searchPhoneNumber != null) {
                // Refresh current search
                ref.read(multiDeviceControllerProvider.notifier).refresh();
              } else {
                // Refresh all users
                ref.read(multiDeviceControllerProvider.notifier).loadAllUsers();
              }
            },
            tooltip: 'Refresh',
          ),
        ],
        body: Column(
          children: [
            // Search Section
            _buildSearchSection(context, state),
            // Tabs
            _buildTabBar(context, width),
            // Tab Content
            Expanded(
              child: _buildTabContent(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, MultiDeviceState state) {
    final hasSearch = state.searchPhoneNumber != null && state.searchPhoneNumber!.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: hasSearch ? state.searchPhoneNumber : 'Enter phone number to filter',
                    prefixIcon: const Icon(Ionicons.call_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  keyboardType: TextInputType.phone,
                  onSubmitted: (_) => _searchDevices(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: state.loading ? null : _searchDevices,
                icon: state.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Ionicons.search_outline),
                label: const Text('Search'),
              ),
            ],
          ),
          if (hasSearch) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text('Filtered: ${state.searchPhoneNumber}'),
                  avatar: const Icon(Ionicons.filter_outline, size: 18),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: state.loading ? null : () {
                    _phoneController.clear();
                    ref.read(multiDeviceControllerProvider.notifier).clearSearch();
                  },
                  icon: const Icon(Ionicons.close_outline),
                  label: const Text('Clear Search'),
                ),
              ],
            ),
          ] else if (state.summary != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: const Text('Showing All Users'),
                  avatar: const Icon(Ionicons.people_outline, size: 18),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, double width) {
    final isCompact = width < 600;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isCompact,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: const [
          Tab(
            icon: Icon(Ionicons.list_outline),
            text: 'List View',
          ),
          Tab(
            icon: Icon(Ionicons.map_outline),
            text: 'Map View',
          ),
          Tab(
            icon: Icon(Ionicons.stats_chart_outline),
            text: 'Summary',
          ),
          Tab(
            icon: Icon(Ionicons.pulse_outline),
            text: 'Live Users',
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, MultiDeviceState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.alert_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.read(multiDeviceControllerProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        state.summary != null
            ? _buildListView(context, state.summary!)
            : _buildEmptyState(context, 'No Devices Found', 'No device history available'),
        state.summary != null
            ? _buildMapView(context, state.summary!)
            : _buildEmptyState(context, 'No Locations Found', 'No location data available'),
        state.summary != null
            ? _buildSummaryView(context, state.summary!)
            : _buildEmptyState(context, 'No Summary Available', 'No data available to display summary'),
        _buildLiveUsersView(context),
      ],
    );
  }

  Widget _buildListView(BuildContext context, MultiDeviceSummary summary) {
    if (summary.devices.isEmpty) {
      return const Center(
        child: Text('No devices found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: summary.devices.length,
      itemBuilder: (context, index) {
        final device = summary.devices[index];
        return _buildDeviceCard(context, device);
      },
    );
  }

  Widget _buildDeviceCard(BuildContext context, DeviceLoginInfo device) {
    final dateFormat = DateFormat('MMM dd, yyyy \'at\' hh:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: device.isActive
              ? Colors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Icon(
            device.platform == 'android'
                ? Ionicons.phone_portrait_outline
                : device.platform == 'ios'
                    ? Ionicons.phone_portrait_outline
                    : Ionicons.desktop_outline,
            color: device.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          device.deviceName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${device.manufacturer} • ${device.platform}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  device.isActive ? Ionicons.radio_button_on : Ionicons.radio_button_off,
                  size: 12,
                  color: device.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  device.isActive 
                      ? 'Currently logged in' 
                      : 'Last active: ${timeago.format(device.lastActivityAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: device.isActive 
                            ? Colors.green 
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            if (device.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Ionicons.location_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      device.locationAddress ?? 
                      '${device.location!.latitude.toStringAsFixed(6)}, ${device.location!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(context, device),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Ionicons.trash_outline, size: 20),
                  color: Colors.red,
                  onPressed: () => _showDeleteConfirmation(context, device),
                  tooltip: 'Delete session',
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Session ID', device.sessionId),
                _buildInfoRow('User', device.userName ?? 'Unknown'),
                _buildInfoRow('Phone', device.phoneNumber ?? 'N/A'),
                _buildInfoRow('Device ID', device.deviceId),
                _buildInfoRow('Platform', device.platform),
                _buildInfoRow('Model', device.deviceModel),
                _buildInfoRow('Manufacturer', device.manufacturer),
                if (device.ipAddress != null)
                  _buildInfoRow('IP Address', device.ipAddress!),
                _buildInfoRow(
                  'Started',
                  dateFormat.format(device.startedAt),
                ),
                _buildInfoRow(
                  'Last Activity',
                  dateFormat.format(device.lastActivityAt),
                ),
                if (device.endedAt != null)
                  _buildInfoRow(
                    'Ended',
                    dateFormat.format(device.endedAt!),
                  ),
                if (device.location != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Location',
                    '${device.location!.latitude.toStringAsFixed(6)}, ${device.location!.longitude.toStringAsFixed(6)}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, DeviceLoginInfo device) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: device.isActive 
            ? Colors.green.withOpacity(0.15) 
            : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: device.isActive ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: device.isActive ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            device.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: device.isActive ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, DeviceLoginInfo device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete the session for "${device.deviceName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting session...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final supabase = ref.read(supabaseClientProvider);
      final repository = MultiDeviceRepositorySupabase(supabase);
      final success = await repository.deleteSession(device.sessionId);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload devices
          final phoneNumber = _phoneController.text.trim();
          final state = ref.read(multiDeviceControllerProvider);
          if (phoneNumber.isNotEmpty) {
            ref.read(multiDeviceControllerProvider.notifier).searchByPhoneNumber(phoneNumber);
          } else if (state.searchPhoneNumber == null) {
            // Reload all users if no search is active
            ref.read(multiDeviceControllerProvider.notifier).loadAllUsers();
          } else {
            // Refresh current search
            ref.read(multiDeviceControllerProvider.notifier).refresh();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete session'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMapView(BuildContext context, MultiDeviceSummary summary) {
    return MultiDeviceMapView(
      devices: summary.devices,
      locations: summary.locations,
    );
  }

  Widget _buildSummaryView(BuildContext context, MultiDeviceSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Unique Devices',
                  summary.uniqueDeviceCount.toString(),
                  Ionicons.phone_portrait_outline,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Sessions',
                  summary.totalSessionCount.toString(),
                  Ionicons.list_outline,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Phone Number Info or All Users Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.phoneNumber == 'All Users' ? 'View' : 'Phone Number',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.phoneNumber,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (summary.userName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'User: ${summary.userName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else if (summary.phoneNumber == 'All Users') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Showing device history for all users',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Device Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...summary.devices.map((device) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            device.platform == 'android'
                                ? Ionicons.phone_portrait_outline
                                : device.platform == 'ios'
                                    ? Ionicons.phone_portrait_outline
                                    : Ionicons.desktop_outline,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.deviceName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${device.platform} • ${device.manufacturer}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              device.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: device.isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.search_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveUsersView(BuildContext context) {
    // Use key to force rebuild when _lastLiveUsersUpdate changes
    return FutureBuilder<List<DeviceLoginInfo>>(
      key: ValueKey(_lastLiveUsersUpdate?.millisecondsSinceEpoch ?? 0),
      future: _loadActiveSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Ionicons.alert_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild to reload
                  },
                  icon: const Icon(Ionicons.refresh_outline),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final activeSessions = snapshot.data ?? [];

        if (activeSessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Ionicons.people_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'There are no users currently logged in',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild to reload
                  },
                  icon: const Icon(Ionicons.refresh_outline),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with count and refresh
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Ionicons.pulse_outline,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${activeSessions.length} Active User${activeSessions.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Ionicons.refresh_outline),
                        onPressed: () {
                          setState(() {
                            _lastLiveUsersUpdate = DateTime.now();
                          });
                        },
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  if (_lastLiveUsersUpdate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Updated ${timeago.format(_lastLiveUsersUpdate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 11,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            // List of active sessions
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeSessions.length,
                itemBuilder: (context, index) {
                  final device = activeSessions[index];
                  return _buildLiveUserCard(context, device);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiveUserCard(BuildContext context, DeviceLoginInfo device) {
    final dateFormat = DateFormat('MMM dd, yyyy \'at\' hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Icon(
            device.platform == 'android'
                ? Ionicons.phone_portrait_outline
                : device.platform == 'ios'
                    ? Ionicons.phone_portrait_outline
                    : Ionicons.desktop_outline,
            color: Colors.green,
          ),
        ),
        title: Text(
          device.userName ?? 'Unknown User',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (device.phoneNumber != null)
              Text(
                device.phoneNumber!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 4),
            Text('${device.deviceName} • ${device.manufacturer}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Ionicons.radio_button_on,
                  size: 12,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Active • Last activity: ${timeago.format(device.lastActivityAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
            if (device.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Ionicons.location_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      device.locationAddress ?? 
                      '${device.location!.latitude.toStringAsFixed(6)}, ${device.location!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: _buildStatusChip(context, device),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Session ID', device.sessionId),
                _buildInfoRow('User', device.userName ?? 'Unknown'),
                _buildInfoRow('Phone', device.phoneNumber ?? 'N/A'),
                _buildInfoRow('Device ID', device.deviceId),
                _buildInfoRow('Platform', device.platform),
                _buildInfoRow('Model', device.deviceModel),
                _buildInfoRow('Manufacturer', device.manufacturer),
                if (device.ipAddress != null)
                  _buildInfoRow('IP Address', device.ipAddress!),
                _buildInfoRow(
                  'Started',
                  dateFormat.format(device.startedAt),
                ),
                _buildInfoRow(
                  'Last Activity',
                  dateFormat.format(device.lastActivityAt),
                ),
                if (device.location != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Location',
                    '${device.location!.latitude.toStringAsFixed(6)}, ${device.location!.longitude.toStringAsFixed(6)}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<DeviceLoginInfo>> _loadActiveSessions() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final repository = MultiDeviceRepositorySupabase(supabase);
      final sessions = await repository.getActiveSessions();
      
      return sessions;
    } catch (e) {
      if (kDebugMode) {
        print('LiveUsers: Error loading active sessions: $e');
        print('LiveUsers: Error type: ${e.runtimeType}');
      }
      throw Exception('Failed to load active sessions: $e');
    }
  }
}

