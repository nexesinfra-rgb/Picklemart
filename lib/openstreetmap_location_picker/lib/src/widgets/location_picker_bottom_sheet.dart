import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_state_provider.dart';
import '../models/location_data.dart';
import 'map_view.dart';
import 'search_bar_widget.dart';
import 'location_display.dart';

class LocationPickerBottomSheet extends ConsumerStatefulWidget {
  final Function(LocationData) onLocationSelected;

  const LocationPickerBottomSheet({
    super.key,
    required this.onLocationSelected,
  });

  @override
  ConsumerState<LocationPickerBottomSheet> createState() => _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState extends ConsumerState<LocationPickerBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Initialize with manual mode and get user's current location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationStateProvider.notifier).setMode(LocationMode.manual);
      // Get user's current location so map shows their location instead of Delhi
      ref.read(locationStateProvider.notifier).getCurrentLocation();
    });
  }

  void _handleLocationSelected(LocationData location) {
    // Call the callback which will handle closing the bottom sheet with the location
    // The callback should use Navigator.of(sheetContext).pop(location) to ensure
    // only the bottom sheet closes, not the parent screen
    widget.onLocationSelected(location);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationStateProvider);
    final isManualMode = locationState.mode == LocationMode.manual;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      child: Stack(
        children: [
          // Full-screen map
          Positioned.fill(
            child: MapView(
              isManualMode: isManualMode,
            ),
          ),
          // Draggable handle above search
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Close button overlay
          Positioned(
            top: 20,
            right: 16,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 4,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Search bar overlay
          Positioned(
            top: 20,
            left: 16,
            right: 70,
            child: const SearchBarWidget(),
          ),
          // Bottom location display
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location display with integrated mode toggle
                  if (locationState.hasValidLocation)
                    LocationDisplay(
                      onLocationSelected: _handleLocationSelected,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isManualMode
                                  ? 'Pan the map to select your location'
                                  : 'Getting your current location...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Error display
                  if (locationState.error != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationState.error!,
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(locationStateProvider.notifier).clearError();
                            },
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// Helper function to show the bottom sheet
void showLocationPickerBottomSheet(
  BuildContext context,
  Function(LocationData) onLocationSelected,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LocationPickerBottomSheet(
      onLocationSelected: onLocationSelected,
    ),
  );
}
