import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/layout/responsive.dart';
import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart' as platform;

/// Widget to display order delivery location on an interactive map
class OrderLocationMap extends StatelessWidget {
  final LatLng coordinates;
  final String address;
  final double? height;

  const OrderLocationMap({
    super.key,
    required this.coordinates,
    required this.address,
    this.height,
  });

  Future<void> _openInExternalMap() async {
    final lat = coordinates.latitude;
    final lng = coordinates.longitude;

    Uri url;
    LaunchMode launchMode;

    if (kIsWeb) {
      // For web, use platformDefault to open in browser
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      launchMode = LaunchMode.platformDefault;
    } else {
      // Use conditional import - platform.Platform on mobile, PlatformStub on web
      final isIOS = platform.Platform.isIOS;
      
      if (isIOS) {
        // Apple Maps for iOS
        url = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
        launchMode = LaunchMode.externalApplication;
      } else {
        // Google Maps for Android
        url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        launchMode = LaunchMode.externalApplication;
      }
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: launchMode);
      } else {
        // Fallback to geo URI (Android only, not web)
        if (!kIsWeb) {
          final isAndroid = platform.Platform.isAndroid;
          if (isAndroid) {
            final geoUrl = Uri.parse('geo:$lat,$lng');
            if (await canLaunchUrl(geoUrl)) {
              await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error opening map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);
    final mapHeight = height ?? (screenSize == ScreenSize.mobile ? 250.0 : 300.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Ionicons.map_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Delivery Location',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                  options: MapOptions(
                    initialCenter: coordinates,
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.picklemart.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: coordinates,
                          width: 50,
                          height: 50,
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
                              Ionicons.location,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Address info and external map button
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Ionicons.location_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _openInExternalMap,
              icon: const Icon(Ionicons.open_outline, size: 18),
              label: const Text('Open Map'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

