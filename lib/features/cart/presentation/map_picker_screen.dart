import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'web_geo_stub.dart' if (dart.library.html) 'web_geo_impl.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initial;
  const MapPickerScreen({super.key, this.initial});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _controller = MapController();
  late LatLng _center;
  LatLng? _selectedLocation;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _center =
        widget.initial ?? const LatLng(12.9716, 77.5946); // default: Bengaluru
    _selectedLocation = widget.initial;
    // Delay to let map build, then move
    scheduleMicrotask(() {
      _controller.move(_center, 13);
    });
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      LatLng? ll;
      if (kIsWeb) {
        // Fallback to browser Geolocation API on web to avoid MissingPluginException during hot restarts.
        ll = await getBrowserPosition();
        if (ll == null) {
          // try geolocator as secondary attempt (after full restart it should be registered)
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          ll = LatLng(pos.latitude, pos.longitude);
        }
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.unableToDetermine) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        ll = LatLng(pos.latitude, pos.longitude);
      }
      final chosen = ll;
      setState(() {
        _center = chosen;
        _selectedLocation = chosen;
      });
      _controller.move(chosen, 16);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onTap: (tapPosition, location) {
                setState(() {
                  _selectedLocation = location;
                  _center = location;
                });
              },
              onPositionChanged: (pos, _) {
                _center = pos.center ?? _center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sm',
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
                          // When marker is tapped, confirm this location
                          setState(() {
                            _center = _selectedLocation!;
                          });
                          // Show feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Location selected: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
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
          // Center pin (only show when no location is selected)
          if (_selectedLocation == null)
            IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.place,
                  size: 36,
                  color: Colors.redAccent.withOpacity(0.9),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 12),
                    ],
                  ),
                  child: Text(
                    'Lat: ${(_selectedLocation ?? _center).latitude.toStringAsFixed(6)}, Lng: ${(_selectedLocation ?? _center).longitude.toStringAsFixed(6)}',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _locating ? null : _useMyLocation,
                        icon:
                            _locating
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.my_location),
                        label: const Text('Use my location'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, _selectedLocation ?? _center),
                        icon: const Icon(Icons.check),
                        label: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // OSM attribution
          Positioned(
            right: 8,
            bottom: 8 + MediaQuery.of(context).padding.bottom,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.white70,
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
