import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ionicons/ionicons.dart';
import '../domain/multi_device_tracking.dart';

class MultiDeviceMapView extends StatelessWidget {
  final List<DeviceLoginInfo> devices;
  final List<DeviceLocationInfo> locations;

  const MultiDeviceMapView({
    super.key,
    required this.devices,
    required this.locations,
  });

  @override
  Widget build(BuildContext context) {
    // Get all locations from devices and location history
    final allLocations = <LatLng>[];
    final locationInfo = <LatLng, String>{};

    // Add device locations
    for (final device in devices) {
      if (device.location != null) {
        allLocations.add(device.location!);
        locationInfo[device.location!] = device.deviceName;
      }
    }

    // Add location history
    for (final loc in locations) {
      if (!allLocations.contains(loc.location)) {
        allLocations.add(loc.location);
        locationInfo[loc.location] = 'Location History';
      }
    }

    if (allLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.map_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Location Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No location information available for these devices',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      );
    }

    // Calculate center point
    double avgLat = 0;
    double avgLng = 0;
    for (final loc in allLocations) {
      avgLat += loc.latitude;
      avgLng += loc.longitude;
    }
    avgLat /= allLocations.length;
    avgLng /= allLocations.length;

    // Calculate bounds
    double minLat = allLocations.first.latitude;
    double maxLat = allLocations.first.latitude;
    double minLng = allLocations.first.longitude;
    double maxLng = allLocations.first.longitude;

    for (final loc in allLocations) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    // Calculate appropriate zoom level based on location spread
    double zoomLevel = 12.0;
    if (allLocations.length == 1) {
      zoomLevel = 15.0;
    } else {
      // Adjust zoom based on spread
      final latSpread = maxLat - minLat;
      final lngSpread = maxLng - minLng;
      final maxSpread = latSpread > lngSpread ? latSpread : lngSpread;
      if (maxSpread > 1.0) {
        zoomLevel = 8.0;
      } else if (maxSpread > 0.5) {
        zoomLevel = 10.0;
      } else {
        zoomLevel = 12.0;
      }
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(avgLat, avgLng),
        initialZoom: zoomLevel,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.sm',
        ),
        MarkerLayer(
          markers: allLocations.asMap().entries.map((entry) {
            final index = entry.key;
            final location = entry.value;
            final device = devices.firstWhere(
              (d) => d.location == location,
              orElse: () => devices.first,
            );

            return Marker(
              point: location,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  _showLocationInfo(context, device, location);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: device.isActive ? Colors.green : Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    device.platform == 'android' || device.platform == 'ios'
                        ? Ionicons.phone_portrait_outline
                        : Ionicons.desktop_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showLocationInfo(
    BuildContext context,
    DeviceLoginInfo device,
    LatLng location,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.deviceName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${device.manufacturer} • ${device.platform}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Ionicons.location_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device.locationAddress ?? 
                    '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (device.userName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Ionicons.person_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    device.userName!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

