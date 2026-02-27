import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'location_service.dart';
import 'geocoding_service.dart';
import '../data/session_repository.dart';
import '../../features/profile/data/location_repository.dart';

/// Service for tracking user sessions with location data
class SessionTrackingService {
  final SessionRepository _sessionRepository;
  final LocationRepository _locationRepository;
  final Uuid _uuid = const Uuid();

  String? _currentSessionId;
  String? _currentUserId;

  SessionTrackingService({
    required SessionRepository sessionRepository,
    required LocationRepository locationRepository,
  }) : _sessionRepository = sessionRepository,
       _locationRepository = locationRepository;

  /// Start a new session for a user
  /// Captures location and creates session record
  Future<SessionStartResult> startSession(String userId) async {
    try {
      _currentUserId = userId;
      _currentSessionId = _uuid.v4();

      // Get device info
      final deviceInfo = await _getDeviceInfo();

      // Try to get location with address
      debugPrint(
        'SessionTrackingService: Starting session for user $userId. '
        'Fetching location with address...',
      );

      final locationResult = await LocationService.getCurrentLocation(
        includeAddress: true,
      );
      LatLng? location;
      String? address;
      double? accuracy;

      if (locationResult?.success == true && locationResult?.location != null) {
        location = locationResult!.location;
        accuracy = locationResult.accuracy;
        address = locationResult.address;

        debugPrint(
          'SessionTrackingService: Location captured: '
          'lat=${location?.latitude}, lng=${location?.longitude}, '
          'address=${address ?? "null"}',
        );

        // If address wasn't included in result, try to get it separately
        if (address == null && location != null) {
          debugPrint(
            'SessionTrackingService: Address not included in location result. '
            'Fetching address via geocoding...',
          );
          address = await GeocodingService.getAddressFromLatLng(location);
          debugPrint(
            'SessionTrackingService: Geocoded address: ${address ?? "null"}',
          );
        }
      } else {
        debugPrint(
          'SessionTrackingService: Failed to get location. '
          'Result: ${locationResult?.success}, Error: ${locationResult?.error}',
        );
      }

      // Create session in database
      debugPrint(
        'SessionTrackingService: Creating session in database with '
        'location: ${location != null}, address: ${address != null && address.isNotEmpty}',
      );

      await _sessionRepository.createSession(
        userId: userId,
        sessionId: _currentSessionId!,
        deviceInfo: deviceInfo,
        location: location,
        address: address,
      );

      // Save location if we have it
      if (location != null) {
        debugPrint(
          'SessionTrackingService: Saving location to database with address: '
          '${address != null && address.isNotEmpty}',
        );

        await _locationRepository.saveLocation(
          userId: userId,
          sessionId: _currentSessionId!,
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
          accuracy: accuracy,
        );

        debugPrint(
          'SessionTrackingService: Location saved successfully with address: '
          '${address ?? "none"}',
        );
      }

      return SessionStartResult(
        success: true,
        sessionId: _currentSessionId!,
        locationCaptured: location != null,
      );
    } catch (e) {
      return SessionStartResult(success: false, error: e.toString());
    }
  }

  /// Update session activity timestamp
  Future<void> updateActivity() async {
    if (_currentSessionId == null || _currentUserId == null) {
      return;
    }

    try {
      await _sessionRepository.updateActivity(_currentSessionId!);
    } catch (e) {
      // Silently fail - activity updates are not critical
      debugPrint('Failed to update session activity: $e');
    }
  }

  /// End the current session
  Future<void> endSession() async {
    if (_currentSessionId == null) {
      return;
    }

    try {
      await _sessionRepository.endSession(_currentSessionId!);
      _currentSessionId = null;
      _currentUserId = null;
    } catch (e) {
      debugPrint('Failed to end session: $e');
    }
  }

  /// Get current session ID
  String? get currentSessionId => _currentSessionId;

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (kIsWeb) {
      return {
        'platform': 'web',
        'userAgent': 'web',
        'app_version': packageInfo.version,
        'app_build': packageInfo.buildNumber,
      };
    }

    Map<String, dynamic> deviceData = {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'app_version': packageInfo.version,
      'app_build': packageInfo.buildNumber,
    };

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData.addAll({
          'device_id': androidInfo.id,
          'device_model': androidInfo.model,
          'device_manufacturer': androidInfo.manufacturer,
          'device_brand': androidInfo.brand,
          'device_product': androidInfo.product,
          'device_device': androidInfo.device,
          'android_version': androidInfo.version.release,
          'android_sdk': androidInfo.version.sdkInt,
          'fingerprint': '${androidInfo.manufacturer}_${androidInfo.model}_${androidInfo.id}',
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData.addAll({
          'device_id': iosInfo.identifierForVendor ?? 'unknown',
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
          'device_system_name': iosInfo.systemName,
          'ios_version': iosInfo.systemVersion,
          'fingerprint': '${iosInfo.model}_${iosInfo.identifierForVendor ?? 'unknown'}',
        });
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceData.addAll({
          'device_id': windowsInfo.computerName,
          'device_model': '${windowsInfo.productName} ${windowsInfo.displayVersion}',
          'fingerprint': '${windowsInfo.computerName}_${windowsInfo.productName}',
        });
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceData.addAll({
          'device_id': macInfo.computerName,
          'device_model': '${macInfo.model} ${macInfo.kernelVersion}',
          'fingerprint': '${macInfo.computerName}_${macInfo.model}',
        });
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceData.addAll({
          'device_id': linuxInfo.machineId ?? 'unknown',
          'device_model': '${linuxInfo.prettyName} ${linuxInfo.version}',
          'fingerprint': '${linuxInfo.machineId ?? 'unknown'}_${linuxInfo.prettyName}',
        });
      }
    } catch (e) {
      debugPrint('Error getting detailed device info: $e');
      // Continue with basic info if detailed info fails
    }

    return deviceData;
  }

  /// Capture and save location update for current session
  Future<bool> captureLocationUpdate() async {
    if (_currentSessionId == null || _currentUserId == null) {
      return false;
    }

    try {
      final locationResult = await LocationService.getCurrentLocation(
        includeAddress: true,
      );
      if (locationResult?.success == true && locationResult?.location != null) {
        final location = locationResult!.location!;
        String? address = locationResult.address;

        // If address wasn't included, try to get it
        address ??= await GeocodingService.getAddressFromLatLng(location);

        await _locationRepository.saveLocation(
          userId: _currentUserId!,
          sessionId: _currentSessionId!,
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
          accuracy: locationResult.accuracy,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to capture location update: $e');
      return false;
    }
  }
}

/// Provider for session tracking service
final sessionTrackingServiceProvider = Provider<SessionTrackingService>((ref) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final locationRepo = ref.watch(locationRepositoryProvider);
  return SessionTrackingService(
    sessionRepository: sessionRepo,
    locationRepository: locationRepo,
  );
});

/// Result of starting a session
class SessionStartResult {
  final bool success;
  final String? sessionId;
  final bool locationCaptured;
  final String? error;

  SessionStartResult({
    required this.success,
    this.sessionId,
    this.locationCaptured = false,
    this.error,
  });
}
