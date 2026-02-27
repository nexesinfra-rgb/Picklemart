import 'dart:html' as html;
import 'package:latlong2/latlong.dart';

Future<LatLng?> getBrowserPosition() async {
  try {
    final pos = await html.window.navigator.geolocation.getCurrentPosition();
    final coords = pos.coords;
    final lat = coords?.latitude;
    final lng = coords?.longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat.toDouble(), lng.toDouble());
  } catch (_) {
    // ignore
  }
  return null;
}
