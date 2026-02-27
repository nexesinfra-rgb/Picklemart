import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/services/location_service.dart';
import '../../../core/ui/responsive_buttons.dart';

/// Dialog to request location permission from user
class LocationPermissionDialog extends ConsumerStatefulWidget {
  final Function(bool granted, {String? error})? onResult;

  const LocationPermissionDialog({
    super.key,
    this.onResult,
  });

  /// Show the location permission dialog
  static Future<bool?> show(BuildContext context) async {
    bool? result;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationPermissionDialog(
        onResult: (granted, {error}) {
          result = granted;
          Navigator.of(context).pop();
        },
      ),
    );
    return result;
  }

  @override
  ConsumerState<LocationPermissionDialog> createState() =>
      _LocationPermissionDialogState();
}

class _LocationPermissionDialogState
    extends ConsumerState<LocationPermissionDialog> {
  bool _isLoading = false;
  String? _error;

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locationResult = await LocationService.getCurrentLocation();

      if (locationResult?.success == true) {
        widget.onResult?.call(true);
      } else if (locationResult?.permissionDeniedForever == true) {
        setState(() {
          _error = 'Location permission is permanently denied. Please enable it in app settings.';
        });
        widget.onResult?.call(false, error: locationResult?.error);
      } else {
        setState(() {
          _error = locationResult?.error ?? 'Failed to get location permission.';
        });
        widget.onResult?.call(false, error: locationResult?.error);
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
      });
      widget.onResult?.call(false, error: e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    final opened = await LocationService.openAppSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open app settings'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Ionicons.location_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Enable Location Access'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We need your location to provide you with the best experience:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildReasonItem(
              icon: Ionicons.navigate_outline,
              text: 'Show nearby delivery options',
            ),
            const SizedBox(height: 8),
            _buildReasonItem(
              icon: Ionicons.map_outline,
              text: 'Auto-detect your delivery address',
            ),
            const SizedBox(height: 8),
            _buildReasonItem(
              icon: Ionicons.shield_checkmark_outline,
              text: 'Improve app security and analytics',
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Ionicons.alert_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_error != null && _error!.contains('permanently denied')) ...[
          TextButton(
            onPressed: _openSettings,
            child: const Text('Open Settings'),
          ),
        ],
        // Skip button hidden as requested
        ResponsiveFilledButton(
          onPressed: _isLoading ? null : _requestPermission,
          isLoading: _isLoading,
          child: const Text('Enable Location'),
        ),
      ],
    );
  }

  Widget _buildReasonItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}






