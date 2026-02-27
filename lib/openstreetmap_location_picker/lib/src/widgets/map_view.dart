// import 'dart:async';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import '../providers/location_state_provider.dart';
// import '../providers/map_controller_provider.dart';
// import '../models/location_data.dart';

// class MapView extends ConsumerStatefulWidget {
//   final Function(LocationData) onLocationChanged;
//   final bool isManualMode;

//   const MapView({
//     super.key,
//     required this.onLocationChanged,
//     required this.isManualMode,
//   });

//   @override
//   ConsumerState<MapView> createState() => _MapViewState();
// }

// class _MapViewState extends ConsumerState<MapView> {
//   late MapController _mapController;
//   LatLng? _currentCenter;
//   Timer? _debounceTimer;
//   bool _isDraggingMarker = false;
//   Offset? _lastPointerPosition;

//   @override
//   void initState() {
//     super.initState();
//     _mapController = MapController();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(mapControllerProvider.notifier).setController(_mapController);
//     });
//   }

//   @override
//   void dispose() {
//     _debounceTimer?.cancel();
//     _mapController.dispose();
//     super.dispose();
//   }

//   void _onMapMoved() {
//     if (widget.isManualMode && mounted) {
//       // Use shorter debounce for better responsiveness during dragging
//       _debounceTimer?.cancel();
//       _debounceTimer = Timer(const Duration(milliseconds: 200), () {
//         if (mounted) {
//           final center = _mapController.camera.center;
//           _currentCenter = center;
//           final location = LocationData(
//             latitude: center.latitude,
//             longitude: center.longitude,
//           );
//           // Update provider directly - single source of truth
//           ref.read(locationStateProvider.notifier).updateSelectedLocation(location);
//           // Keep callback for backward compatibility
//           widget.onLocationChanged(location);
//         }
//       });
//     }
//   }

//   void _onMapTap(TapPosition tapPosition, LatLng location) {
//     // Handle tap-to-place in both manual and auto modes
//     final locationData = LocationData(
//       latitude: location.latitude,
//       longitude: location.longitude,
//     );
//     // Update provider directly - single source of truth
//     ref.read(locationStateProvider.notifier).updateSelectedLocation(locationData);
//     // Keep callback for backward compatibility
//     widget.onLocationChanged(locationData);
//     // Update local state and force immediate rebuild
//     setState(() {
//       _currentCenter = location;
//     });
//     // Move map to tapped location so marker is visible
//     _mapController.move(location, _mapController.camera.zoom);
//   }

//   void _moveToLocation(LocationData location) {
//     final latLng = LatLng(location.latitude, location.longitude);
//     _mapController.move(
//       latLng,
//       _mapController.camera.zoom,
//     );
//     _currentCenter = latLng;
//   }

//   void _zoomIn() {
//     final currentZoom = _mapController.camera.zoom;
//     final newZoom = (currentZoom + 1).clamp(1.0, 18.0);
//     _mapController.move(_mapController.camera.center, newZoom);
//   }

//   void _zoomOut() {
//     final currentZoom = _mapController.camera.zoom;
//     final newZoom = (currentZoom - 1).clamp(1.0, 18.0);
//     _mapController.move(_mapController.camera.center, newZoom);
//   }

//   void _onMarkerDragUpdate(DragUpdateDetails details) {
//     if (!widget.isManualMode) return;

//     final camera = _mapController.camera;
//     final currentCenter = camera.center;
//     final zoom = camera.zoom;
    
//     // Calculate the LatLng offset based on drag delta
//     // At zoom level z, 1 pixel ≈ 156543.03392 * cos(latitude) / (2^z) meters
//     // We'll use a simpler approximation: convert pixel delta to degrees
//     final latRad = currentCenter.latitude * math.pi / 180.0;
//     final metersPerPixel = (156543.03392 * math.cos(latRad)) / (1 << zoom.toInt());
    
//     // Convert pixel delta to meters, then to degrees
//     // Latitude: 1 degree ≈ 111,000 meters
//     // Longitude: 1 degree ≈ 111,000 * cos(latitude) meters
//     final latDelta = -details.delta.dy * metersPerPixel / 111000.0;
//     final lngDelta = details.delta.dx * metersPerPixel / (111000.0 * math.cos(latRad));
    
//     // Calculate new center position
//     final newLat = (currentCenter.latitude + latDelta).clamp(-85.0, 85.0);
//     final newLng = (currentCenter.longitude + lngDelta).clamp(-180.0, 180.0);
//     final newLatLng = LatLng(newLat, newLng);
    
//     // Update map center to the new position
//     _mapController.move(newLatLng, zoom);
//     _currentCenter = newLatLng;
    
//     // Trigger location update immediately (no debounce for drag)
//     final location = LocationData(
//       latitude: newLatLng.latitude,
//       longitude: newLatLng.longitude,
//     );
//     widget.onLocationChanged(location);
//   }

//   void _onMarkerPointerDown(PointerDownEvent event) {
//     if (!widget.isManualMode) return;
//     setState(() {
//       _isDraggingMarker = true;
//       _lastPointerPosition = event.position;
//     });
//   }

//   void _onMarkerPointerMove(PointerMoveEvent event) {
//     if (!widget.isManualMode || !_isDraggingMarker || _lastPointerPosition == null) return;

//     final delta = event.position - _lastPointerPosition!;
//     _lastPointerPosition = event.position;

//     final camera = _mapController.camera;
//     final currentCenter = camera.center;
//     final zoom = camera.zoom;
    
//     // Calculate the LatLng offset based on drag delta
//     final latRad = currentCenter.latitude * math.pi / 180.0;
//     final metersPerPixel = (156543.03392 * math.cos(latRad)) / (1 << zoom.toInt());
    
//     // Convert pixel delta to meters, then to degrees
//     final latDelta = -delta.dy * metersPerPixel / 111000.0;
//     final lngDelta = delta.dx * metersPerPixel / (111000.0 * math.cos(latRad));
    
//     // Calculate new center position
//     final newLat = (currentCenter.latitude + latDelta).clamp(-85.0, 85.0);
//     final newLng = (currentCenter.longitude + lngDelta).clamp(-180.0, 180.0);
//     final newLatLng = LatLng(newLat, newLng);
    
//     // Update map center to the new position
//     _mapController.move(newLatLng, zoom);
//     _currentCenter = newLatLng;
    
//     // Trigger location update immediately (no debounce for drag)
//     final location = LocationData(
//       latitude: newLatLng.latitude,
//       longitude: newLatLng.longitude,
//     );
//     widget.onLocationChanged(location);
//   }

//   void _onMarkerPointerUp(PointerUpEvent event) {
//     if (!widget.isManualMode || !_isDraggingMarker) return;
    
//     setState(() {
//       _isDraggingMarker = false;
//       _lastPointerPosition = null;
//     });

//     // Final location update after drag ends
//     if (mounted) {
//       final center = _mapController.camera.center;
//       _currentCenter = center;
//       final location = LocationData(
//         latitude: center.latitude,
//         longitude: center.longitude,
//       );
//       widget.onLocationChanged(location);
//     }
//   }

//   void _onMarkerPointerCancel(PointerCancelEvent event) {
//     setState(() {
//       _isDraggingMarker = false;
//       _lastPointerPosition = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final locationState = ref.watch(locationStateProvider);
//     final selectedLocation = locationState.selectedLocation;
//     final currentLocation = locationState.currentLocation;
    
//     // In auto mode, prioritize currentLocation, fallback to selectedLocation
//     // In manual mode, use selectedLocation only
//     final locationToShow = widget.isManualMode
//         ? selectedLocation
//         : (currentLocation ?? selectedLocation);

//     // Move map when location changes (auto mode or search result)
//     if (locationToShow != null && 
//         (_currentCenter == null || 
//          _currentCenter?.latitude != locationToShow.latitude ||
//          _currentCenter?.longitude != locationToShow.longitude)) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _moveToLocation(locationToShow);
//       });
//     }

//     return Stack(
//       children: [
//         FlutterMap(
//           mapController: _mapController,
//           options: MapOptions(
//             initialCenter: locationToShow != null
//                 ? LatLng(locationToShow.latitude, locationToShow.longitude)
//                 : const LatLng(28.6139, 77.2090), // Default to Delhi, India
//             initialZoom: 13.0,
//             onTap: _onMapTap,
//             onMapEvent: (MapEvent event) {
//               if (event is MapEventMove) {
//                 _onMapMoved();
//               } else if (event is MapEventScrollWheelZoom) {
//                 // Handle scroll wheel zoom for better responsiveness
//                 _onMapMoved();
//               } else if (event is MapEventFlingAnimation) {
//                 // Handle fling animations
//                 _onMapMoved();
//               }
//             },
//             interactionOptions: InteractionOptions(
//               flags: _isDraggingMarker 
//                   ? InteractiveFlag.all & ~InteractiveFlag.drag
//                   : InteractiveFlag.all,
//               pinchZoomWinGestures: MultiFingerGesture.pinchZoom,
//               rotationWinGestures: MultiFingerGesture.rotate,
//             ),
//             minZoom: 1.0,
//             maxZoom: 18.0,
//             cameraConstraint: CameraConstraint.contain(
//               bounds: LatLngBounds(
//                 const LatLng(-85.05112878, -180.0),
//                 const LatLng(85.05112878, 180.0),
//               ),
//             ),
//           ),
//           children: [
//             TileLayer(
//               urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//               userAgentPackageName: 'com.example.location',
//               additionalOptions: const {
//                 'User-Agent': 'LocationPicker/1.0.0 (contact@example.com)',
//               },
//               maxZoom: 18,
//               minZoom: 1,
//             ),
//             // Marker layer for selected location (blue marker)
//             // Always show marker when locationToShow is set
//             if (locationToShow != null)
//               MarkerLayer(
//                 key: ValueKey('marker_${locationToShow.latitude}_${locationToShow.longitude}'),
//                 markers: [
//                   Marker(
//                     point: LatLng(locationToShow.latitude, locationToShow.longitude),
//                     width: 60,
//                     height: 60,
//                     alignment: Alignment.center,
//                     child: GestureDetector(
//                       onTap: () {
//                         // When marker is tapped, trigger location changed callback
//                         widget.onLocationChanged(locationToShow);
//                       },
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade700,
//                           shape: BoxShape.circle,
//                           border: Border.all(
//                             color: Colors.white,
//                             width: 4,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.4),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.location_on,
//                           color: Colors.white,
//                           size: 28,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             RichAttributionWidget(
//               attributions: [
//                 const TextSourceAttribution(
//                   'OpenStreetMap contributors',
//                   onTap: null,
//                 ),
//               ],
//             ),
//           ],
//         ),
//         // Loading indicator
//         if (locationState.isLoading)
//           const Center(
//             child: CircularProgressIndicator(),
//           ),
//         // Zoom controls
//         Positioned(
//           right: 16,
//           top: 120,
//           child: Column(
//             children: [
//               Material(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 elevation: 4,
//                 child: InkWell(
//                   onTap: _zoomIn,
//                   borderRadius: BorderRadius.circular(8),
//                   child: Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(Icons.add, size: 20),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Material(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 elevation: 4,
//                 child: InkWell(
//                   onTap: _zoomOut,
//                   borderRadius: BorderRadius.circular(8),
//                   child: Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(Icons.remove, size: 20),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../providers/location_state_provider.dart';
import '../providers/map_controller_provider.dart';
import '../models/location_data.dart';

class MapView extends ConsumerStatefulWidget {
  final bool isManualMode;

  const MapView({
    super.key,
    required this.isManualMode,
  });

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  late final MapController _mapController;
  LatLng? _currentCenter;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).setController(_mapController);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ✅ SINGLE SOURCE OF TRUTH UPDATE
  void _setLocation(LatLng latLng) {
    final location = LocationData(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    ref.read(locationStateProvider.notifier)
        .updateSelectedLocation(location);

    _currentCenter = latLng;
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    _setLocation(latLng);
    _mapController.move(latLng, _mapController.camera.zoom);
  }

  void _onMapMoved() {
    if (!widget.isManualMode) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      final center = _mapController.camera.center;
      _setLocation(center);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationStateProvider);
    final selectedLocation = locationState.selectedLocation;
    final currentLocation = locationState.currentLocation;

    final locationToShow = widget.isManualMode
        ? selectedLocation
        : (currentLocation ?? selectedLocation);

    if (locationToShow != null &&
        (_currentCenter == null ||
            _currentCenter!.latitude != locationToShow.latitude ||
            _currentCenter!.longitude != locationToShow.longitude)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(locationToShow.latitude, locationToShow.longitude),
          _mapController.camera.zoom,
        );
      });
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: locationToShow != null
                ? LatLng(locationToShow.latitude, locationToShow.longitude)
                : const LatLng(28.6139, 77.2090),
            initialZoom: 13,
            onTap: _onMapTap,
            onMapEvent: (event) {
              if (event is MapEventMove) {
                _onMapMoved();
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.location',
            ),

            // ✅ MARKER (NOW GUARANTEED TO SHOW)
            if (locationToShow != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      locationToShow.latitude,
                      locationToShow.longitude,
                    ),
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.red.shade700,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),

        if (locationState.isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
