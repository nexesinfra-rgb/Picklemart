import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ionicons/ionicons.dart';
import '../layout/responsive.dart';
import 'responsive_buttons.dart';

/// Reusable map picker widget for address selection
class MapPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;
  final Function(LatLng location, String address)? onLocationSelected;
  final Function()? onLocationCleared;
  final bool showCurrentLocationButton;
  final bool showSearchButton;
  final String? title;
  final String? hintText;

  const MapPickerWidget({
    super.key,
    this.initialLocation,
    this.initialAddress,
    this.onLocationSelected,
    this.onLocationCleared,
    this.showCurrentLocationButton = true,
    this.showSearchButton = true,
    this.title,
    this.hintText,
  });

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    _selectedAddress = widget.initialAddress;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      // Mock location for demo - in real app, use geolocator
      await Future.delayed(const Duration(seconds: 1));
      const mockLocation = LatLng(28.6139, 77.2090); // New Delhi
      const mockAddress = "New Delhi, India";

      setState(() {
        _selectedLocation = mockLocation;
        _selectedAddress = mockAddress;
      });

      _mapController.move(mockLocation, 15.0);
      widget.onLocationSelected?.call(mockLocation, mockAddress);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get current location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      _selectedAddress =
          "Selected Location: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}";
    });

    widget.onLocationSelected?.call(location, _selectedAddress!);
  }

  void _clearLocation() {
    setState(() {
      _selectedLocation = null;
      _selectedAddress = null;
    });

    widget.onLocationCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = Responsive.breakpointForWidth(constraints.maxWidth);
        final mapHeight =
            bp == AppBreakpoint.expanded
                ? 400.0
                : bp == AppBreakpoint.medium
                ? 350.0
                : 300.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],

            // Map Container
            Container(
              height: mapHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _selectedLocation ?? const LatLng(28.6139, 77.2090),
                        initialZoom: 15.0,
                        onTap: _onMapTap,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    // When marker is tapped, trigger location selected callback
                                    widget.onLocationSelected?.call(
                                      _selectedLocation!,
                                      _selectedAddress ??
                                          "Location: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}",
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Map Controls
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        children: [
                          if (widget.showCurrentLocationButton)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ResponsiveIconButton(
                                onPressed:
                                    _isLoading ? null : _getCurrentLocation,
                                icon:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Ionicons.locate_outline),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Center crosshair (only show when no location is selected)
                    if (_selectedLocation == null)
                      const Center(
                        child: Icon(Icons.add, color: Colors.red, size: 30),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Selected Location Info
            if (_selectedLocation != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Location',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedAddress ?? 'Location selected',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ResponsiveIconButton(
                      onPressed: _clearLocation,
                      icon: const Icon(Icons.clear, size: 18),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.hintText ??
                            'Tap on the map to select a location',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Compact map picker for smaller spaces
class CompactMapPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;
  final Function(LatLng location, String address)? onLocationSelected;
  final Function()? onLocationCleared;
  final String? title;

  const CompactMapPicker({
    super.key,
    this.initialLocation,
    this.initialAddress,
    this.onLocationSelected,
    this.onLocationCleared,
    this.title,
  });

  @override
  State<CompactMapPicker> createState() => _CompactMapPickerState();
}

class _CompactMapPickerState extends State<CompactMapPicker> {
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = Responsive.breakpointForWidth(constraints.maxWidth);
        final mapHeight =
            bp == AppBreakpoint.expanded
                ? 200.0
                : bp == AppBreakpoint.medium
                ? 180.0
                : 160.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],

            Container(
              height: mapHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter:
                            widget.initialLocation ??
                            const LatLng(28.6139, 77.2090),
                        initialZoom: 13.0,
                        onTap: (tapPosition, location) {
                          setState(() {
                            _selectedLocation = location;
                          });
                          widget.onLocationSelected?.call(
                            location,
                            "Location: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}",
                          );
                        },
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (_selectedLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation!,
                                width: 30,
                                height: 30,
                                child: GestureDetector(
                                  onTap: () {
                                    widget.onLocationSelected?.call(
                                      _selectedLocation!,
                                      "Selected Location",
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Center crosshair (only show when no location is selected)
                    if (_selectedLocation == null)
                      const Center(
                        child: Icon(Icons.add, color: Colors.red, size: 20),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
