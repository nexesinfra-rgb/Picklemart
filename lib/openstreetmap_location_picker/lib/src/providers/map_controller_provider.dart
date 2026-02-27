import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapControllerNotifier extends StateNotifier<MapController?> {
  MapControllerNotifier() : super(null);

  void setController(MapController controller) {
    state = controller;
  }

  void moveToLocation(LatLng location, {double zoom = 15.0}) {
    if (state != null) {
      state!.move(location, zoom);
    }
  }

  void animateToLocation(LatLng location, {double zoom = 15.0}) {
    if (state != null) {
      state!.move(location, zoom);
    }
  }

  LatLng? get center {
    if (state != null) {
      return state!.camera.center;
    }
    return null;
  }

  double get zoom {
    if (state != null) {
      return state!.camera.zoom;
    }
    return 13.0;
  }

  @override
  void dispose() {
    state?.dispose();
    state = null;
    super.dispose();
  }
}

final mapControllerProvider = StateNotifierProvider<MapControllerNotifier, MapController?>(
  (ref) => MapControllerNotifier(),
);
