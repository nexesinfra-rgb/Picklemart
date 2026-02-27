import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../features/profile/data/location_repository.dart';
import 'widgets/admin_navigation.dart';
import 'widgets/admin_auth_guard.dart';

/// Admin screen to view user locations
class UserLocationScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;

  const UserLocationScreen({super.key, required this.userId, this.userName});

  @override
  ConsumerState<UserLocationScreen> createState() => _UserLocationScreenState();
}

class _UserLocationScreenState extends ConsumerState<UserLocationScreen> {
  List<UserLocation>? _locations;
  bool _isRefreshing = false;
  bool _isLoadingAddresses = false;
  Set<String> _fetchingAddressIds = {};
  int _currentLimit = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations({bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMore)) {
      return;
    }

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isRefreshing = true;
        _locations = null;
        _currentLimit = 50;
        _hasMore = true;
      }
    });

    try {
      final locationRepo = ref.read(locationRepositoryProvider);
      final limit = loadMore ? _currentLimit + 50 : 50;
      final locations = await locationRepo.getLocationHistory(
        widget.userId,
        limit: limit,
        onAddressFetched: (updatedLocation) {
          // Update location in real-time as address is fetched
          if (mounted && _locations != null) {
            setState(() {
              final index = _locations!.indexWhere(
                (loc) => loc.id == updatedLocation.id,
              );
              if (index != -1) {
                _locations![index] = updatedLocation;
                _fetchingAddressIds.remove(updatedLocation.id);
                if (_fetchingAddressIds.isEmpty) {
                  _isLoadingAddresses = false;
                }
              }
            });
          }
        },
      );

      // Check if any locations need addresses
      final needsAddresses = locations.any(
        (loc) => loc.address == null || loc.address!.isEmpty,
      );

      if (needsAddresses && mounted) {
        // Track which locations are fetching addresses
        setState(() {
          _fetchingAddressIds = locations
              .where((loc) => loc.address == null || loc.address!.isEmpty)
              .map((loc) => loc.id)
              .toSet();
          _isLoadingAddresses = true;
        });
      }

      if (mounted) {
        setState(() {
          // When loading more, replace the list with the new larger list
          // (since query always returns most recent locations up to limit)
          // This ensures we have the latest data including any address updates
          _locations = locations;
          _currentLimit = limit;
          _hasMore = locations.length >= limit;
          _isRefreshing = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isLoadingAddresses = false;
        });

        // Show error message
        final error = e.toString();
        final isTableError =
            error.contains('user_locations') ||
            error.contains('does not exist') ||
            error.contains('PGRST');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isTableError
                    ? 'Database table not found. Please run migration: 010_create_user_sessions_and_locations.sql'
                    : 'Error loading locations: $error',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        appBar: AdminAppBar(
          title:
              widget.userName != null
                  ? '${widget.userName}\'s Locations'
                  : 'User Locations',
          showBackButton: true,
          onBackPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('admin-customers');
            }
          },
          actions: [
            if (_isRefreshing || _isLoadingAddresses)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Ionicons.refresh),
                onPressed: _loadLocations,
                tooltip: 'Refresh locations and fetch addresses',
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isRefreshing && _locations == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_locations == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final locations = _locations!;

    // Show error state if we have an error (locations is empty but we tried to load)
    // This is handled by the empty state below

    if (locations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Ionicons.location_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No location data available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Location data will appear here once the user:\n'
                '1. Logs in to the app\n'
                '2. Grants location permission\n'
                '3. Their location is captured',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: locations.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Load More button
            if (index == locations.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: _isLoadingMore
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () => _loadLocations(loadMore: true),
                          child: const Text('Load More'),
                        ),
                ),
              );
            }

            final location = locations[index];
            final isFetchingAddress = _fetchingAddressIds.contains(location.id);
            final hasAddress = location.address != null &&
                location.address!.isNotEmpty;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Ionicons.location, color: Colors.white),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasAddress
                            ? location.address!
                            : 'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isFetchingAddress)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (location.address != null &&
                        location.address!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${location.latitude.toStringAsFixed(6)}, '
                        'Lng: ${location.longitude.toStringAsFixed(6)}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                    if (location.accuracy != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Accuracy: ${location.accuracy!.toStringAsFixed(2)}m',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Ionicons.time_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(location.capturedAt),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Icon(Ionicons.chevron_forward, color: Colors.grey),
                onTap: () {
                  _showLocationDetails(context, location);
                },
              ),
            );
          },
        ),
        if (_isLoadingAddresses)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Fetching addresses...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showLocationDetails(BuildContext context, UserLocation location) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Location Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (location.address != null &&
                      location.address!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.location,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location.address!,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Coordinates:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text('Latitude: ${location.latitude.toStringAsFixed(8)}'),
                  Text('Longitude: ${location.longitude.toStringAsFixed(8)}'),
                  if (location.accuracy != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Accuracy:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('${location.accuracy!.toStringAsFixed(2)} meters'),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Captured At:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(_formatDateTime(location.capturedAt)),
                  if (location.sessionId != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Session ID:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.sessionId!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
