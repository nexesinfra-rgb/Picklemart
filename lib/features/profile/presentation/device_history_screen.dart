import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../admin/data/multi_device_repository.dart';
import '../../admin/domain/multi_device_tracking.dart';
import '../../admin/presentation/multi_device_map_view.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Screen to display login history and device locations for the current user
class DeviceHistoryScreen extends ConsumerStatefulWidget {
  const DeviceHistoryScreen({super.key});

  @override
  ConsumerState<DeviceHistoryScreen> createState() => _DeviceHistoryScreenState();
}

class _DeviceHistoryScreenState extends ConsumerState<DeviceHistoryScreen> {
  bool _loading = true;
  List<DeviceLoginInfo> _devices = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDevices();
      }
    });
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        if (mounted) {
          setState(() {
            _error = 'User not authenticated';
            _loading = false;
          });
        }
        return;
      }

      final repository = MultiDeviceRepositorySupabase(supabase);
      final devices = await repository.getUserDevices(userId);
      
      if (mounted) {
        setState(() {
          _devices = devices;
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeviceHistoryScreen: Error loading devices: $e');
      }
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          onPressed: () => context.pop(),
        ),
        title: const Text('Device History'),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh_outline),
            onPressed: _loadDevices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadDevices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.phone_portrait_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Device History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t logged in from any devices yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      );
    }

    // Get locations for map view
    final locations = _devices
        .where((d) => d.location != null)
        .map((d) => DeviceLocationInfo(
              sessionId: d.sessionId,
              userId: d.userId,
              location: d.location!,
              address: d.locationAddress,
              capturedAt: d.startedAt,
            ))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(
                icon: Icon(Ionicons.list_outline),
                text: 'Devices',
              ),
              Tab(
                icon: Icon(Ionicons.map_outline),
                text: 'Map',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDevicesList(context),
                locations.isNotEmpty
                    ? MultiDeviceMapView(
                        devices: _devices,
                        locations: locations,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Ionicons.map_outline,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Location Data',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No location information available',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy \'at\' hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
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
                    Expanded(
                      child: Text(
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
                  children: [
                    _buildStatusChip(context, device),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Ionicons.trash_outline, size: 20),
                      color: Colors.red,
                      onPressed: () => _showDeleteConfirmation(context, device),
                      tooltip: 'Delete device history',
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
      },
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
        title: const Text('Delete Device History'),
        content: Text(
          'Are you sure you want to delete the history for "${device.deviceName}"?\n\n'
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
                  Text('Deleting device history...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not authenticated'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final repository = MultiDeviceRepositorySupabase(supabase);
      final success = await repository.deleteUserSession(device.sessionId, userId);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device history deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload devices
          _loadDevices();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete device history'),
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
}

