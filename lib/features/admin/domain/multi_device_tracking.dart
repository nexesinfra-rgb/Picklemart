import 'package:latlong2/latlong.dart';

/// Model for device login information
class DeviceLoginInfo {
  final String sessionId;
  final String userId;
  final String? userName;
  final String? phoneNumber;
  final Map<String, dynamic> deviceInfo;
  final String? ipAddress;
  final DateTime startedAt;
  final DateTime lastActivityAt;
  final DateTime? endedAt;
  final bool isActive;
  final LatLng? location;
  final String? locationAddress;

  DeviceLoginInfo({
    required this.sessionId,
    required this.userId,
    this.userName,
    this.phoneNumber,
    required this.deviceInfo,
    this.ipAddress,
    required this.startedAt,
    required this.lastActivityAt,
    this.endedAt,
    required this.isActive,
    this.location,
    this.locationAddress,
  });

  String get deviceId => deviceInfo['device_id'] as String? ?? 
                         deviceInfo['fingerprint'] as String? ?? 
                         sessionId;

  String get deviceName {
    if (deviceInfo['device_name'] != null) {
      return deviceInfo['device_name'] as String;
    }
    if (deviceInfo['device_model'] != null) {
      return deviceInfo['device_model'] as String;
    }
    return deviceInfo['platform'] as String? ?? 'Unknown Device';
  }

  String get platform => deviceInfo['platform'] as String? ?? 'Unknown';

  String get deviceModel => deviceInfo['device_model'] as String? ?? 
                           deviceInfo['device_name'] as String? ?? 
                           'Unknown';

  String get manufacturer => deviceInfo['device_manufacturer'] as String? ?? 
                            deviceInfo['device_brand'] as String? ?? 
                            'Unknown';

  factory DeviceLoginInfo.fromJson(Map<String, dynamic> json) {
    return DeviceLoginInfo(
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      deviceInfo: json['device_info'] as Map<String, dynamic>? ?? {},
      ipAddress: json['ip_address'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      lastActivityAt: DateTime.parse(json['last_activity_at'] as String),
      endedAt: json['ended_at'] != null 
          ? DateTime.parse(json['ended_at'] as String) 
          : null,
      isActive: json['is_active'] as bool? ?? false,
      location: (json['location_latitude'] != null && json['location_longitude'] != null)
          ? LatLng(
              (json['location_latitude'] as num).toDouble(),
              (json['location_longitude'] as num).toDouble(),
            )
          : null,
      locationAddress: json['location_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'user_name': userName,
      'phone_number': phoneNumber,
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'started_at': startedAt.toIso8601String(),
      'last_activity_at': lastActivityAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_active': isActive,
      'location_latitude': location?.latitude,
      'location_longitude': location?.longitude,
      'location_address': locationAddress,
    };
  }
}

/// Model for device location information
class DeviceLocationInfo {
  final String sessionId;
  final String userId;
  final LatLng location;
  final String? address;
  final double? accuracy;
  final DateTime capturedAt;

  DeviceLocationInfo({
    required this.sessionId,
    required this.userId,
    required this.location,
    this.address,
    this.accuracy,
    required this.capturedAt,
  });

  factory DeviceLocationInfo.fromJson(Map<String, dynamic> json) {
    return DeviceLocationInfo(
      sessionId: json['session_id'] as String? ?? '',
      userId: json['user_id'] as String,
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      address: json['address'] as String?,
      accuracy: json['accuracy'] != null 
          ? (json['accuracy'] as num).toDouble() 
          : null,
      capturedAt: DateTime.parse(json['captured_at'] as String),
    );
  }
}

/// Summary model for multi-device tracking
class MultiDeviceSummary {
  final String phoneNumber;
  final String? userName;
  final int uniqueDeviceCount;
  final int totalSessionCount;
  final List<DeviceLoginInfo> devices;
  final List<DeviceLocationInfo> locations;

  MultiDeviceSummary({
    required this.phoneNumber,
    this.userName,
    required this.uniqueDeviceCount,
    required this.totalSessionCount,
    required this.devices,
    required this.locations,
  });

  factory MultiDeviceSummary.fromDevices({
    required String phoneNumber,
    String? userName,
    required List<DeviceLoginInfo> devices,
    required List<DeviceLocationInfo> locations,
  }) {
    // Count unique devices by device_id or fingerprint
    final uniqueDeviceIds = <String>{};
    for (final device in devices) {
      final deviceId = device.deviceId;
      if (deviceId.isNotEmpty) {
        uniqueDeviceIds.add(deviceId);
      }
    }

    return MultiDeviceSummary(
      phoneNumber: phoneNumber,
      userName: userName,
      uniqueDeviceCount: uniqueDeviceIds.length,
      totalSessionCount: devices.length,
      devices: devices,
      locations: locations,
    );
  }
}

