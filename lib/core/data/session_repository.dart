import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/supabase_provider.dart';
import 'package:latlong2/latlong.dart';

/// Repository interface for session operations
abstract class SessionRepository {
  Future<UserSession> createSession({
    required String userId,
    required String sessionId,
    Map<String, dynamic>? deviceInfo,
    LatLng? location,
    String? address,
  });

  Future<void> updateActivity(String sessionId);
  Future<void> endSession(String sessionId);
  Future<UserSession?> getActiveSession(String userId);
  Future<List<UserSession>> getSessionHistory(String userId, {int? limit});
}

/// Supabase implementation of SessionRepository
class SessionRepositorySupabase implements SessionRepository {
  final SupabaseClient _supabase;

  SessionRepositorySupabase(this._supabase);

  @override
  Future<UserSession> createSession({
    required String userId,
    required String sessionId,
    Map<String, dynamic>? deviceInfo,
    LatLng? location,
    String? address,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final sessionData = {
        'user_id': userId,
        'session_id': sessionId,
        'device_info': deviceInfo ?? {},
        'location_latitude': location?.latitude,
        'location_longitude': location?.longitude,
        'location_address': address,
        'started_at': now,
        'last_activity_at': now,
        'is_active': true,
      };

      final response = await _supabase
          .from('user_sessions')
          .insert(sessionData)
          .select()
          .single();

      return UserSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  @override
  Future<void> updateActivity(String sessionId) async {
    try {
      await _supabase
          .from('user_sessions')
          .update({'last_activity_at': DateTime.now().toIso8601String()})
          .eq('session_id', sessionId)
          .eq('is_active', true);
    } catch (e) {
      throw Exception('Failed to update session activity: $e');
    }
  }

  @override
  Future<void> endSession(String sessionId) async {
    try {
      await _supabase
          .from('user_sessions')
          .update({
            'is_active': false,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('session_id', sessionId);
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }

  @override
  Future<UserSession?> getActiveSession(String userId) async {
    try {
      final response = await _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return UserSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get active session: $e');
    }
  }

  @override
  Future<List<UserSession>> getSessionHistory(
    String userId, {
    int? limit,
  }) async {
    try {
      var query = _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .order('started_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List)
          .map((json) => UserSession.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get session history: $e');
    }
  }
}

/// User session model
class UserSession {
  final String id;
  final String userId;
  final String sessionId;
  final Map<String, dynamic> deviceInfo;
  final String? ipAddress;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationAddress;
  final DateTime startedAt;
  final DateTime lastActivityAt;
  final DateTime? endedAt;
  final bool isActive;

  UserSession({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.deviceInfo,
    this.ipAddress,
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
    required this.startedAt,
    required this.lastActivityAt,
    this.endedAt,
    required this.isActive,
  });

  LatLng? get location {
    if (locationLatitude != null && locationLongitude != null) {
      return LatLng(locationLatitude!, locationLongitude!);
    }
    return null;
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sessionId: json['session_id'] as String,
      deviceInfo: json['device_info'] as Map<String, dynamic>? ?? {},
      ipAddress: json['ip_address'] as String?,
      locationLatitude: json['location_latitude'] != null
          ? (json['location_latitude'] as num).toDouble()
          : null,
      locationLongitude: json['location_longitude'] != null
          ? (json['location_longitude'] as num).toDouble()
          : null,
      locationAddress: json['location_address'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      lastActivityAt: DateTime.parse(json['last_activity_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'device_info': deviceInfo,
      'ip_address': ipAddress,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'location_address': locationAddress,
      'started_at': startedAt.toIso8601String(),
      'last_activity_at': lastActivityAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }
}

/// Provider for session repository
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SessionRepositorySupabase(supabase);
});






