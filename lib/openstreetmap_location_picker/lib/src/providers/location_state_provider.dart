import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';
import '../services/location_service.dart';

enum LocationMode { auto, manual }

class LocationState {
  final LocationData? currentLocation;
  final LocationData? selectedLocation;
  final LocationMode mode;
  final bool isLoading;
  final String? error;
  final bool hasPermission;

  const LocationState({
    this.currentLocation,
    this.selectedLocation,
    this.mode = LocationMode.manual,
    this.isLoading = false,
    this.error,
    this.hasPermission = false,
  });

  LocationState copyWith({
    LocationData? currentLocation,
    LocationData? selectedLocation,
    LocationMode? mode,
    bool? isLoading,
    String? error,
    bool? hasPermission,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }

  bool get hasValidLocation => selectedLocation != null;
  
  String get coordinatesString => 
      selectedLocation?.coordinatesString ?? 'No location selected';
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState()) {
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final permission = await LocationService.checkPermission();
      state = state.copyWith(
        hasPermission: permission == LocationPermission.denied ||
                     permission == LocationPermission.whileInUse ||
                     permission == LocationPermission.always,
      );
    } catch (e) {
      state = state.copyWith(error: 'Permission check failed: $e');
    }
  }

  Future<void> setMode(LocationMode mode) async {
    state = state.copyWith(mode: mode, error: null);
    
    if (mode == LocationMode.auto) {
      await getCurrentLocation();
    }
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final location = await LocationService.getCurrentLocation();
      state = state.copyWith(
        currentLocation: location,
        selectedLocation: location,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void updateSelectedLocation(LocationData location) {
    state = state.copyWith(
      selectedLocation: location,
      error: null,
    );
  }

  void clearSelectedLocation() {
    state = state.copyWith(
      selectedLocation: null,
      error: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const LocationState();
    _checkPermissions();
  }
}

final locationStateProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) => LocationNotifier(),
);
