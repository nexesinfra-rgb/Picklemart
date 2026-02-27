import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/multi_device_tracking.dart';

/// Repository interface for multi-device tracking operations
abstract class MultiDeviceRepository {
  Future<List<DeviceLoginInfo>> getDevicesByPhoneNumber(String phoneNumber);
  Future<int> getUniqueDeviceCount(String phoneNumber);
  Future<List<DeviceLocationInfo>> getDeviceLocations(String phoneNumber);
  Future<MultiDeviceSummary> getMultiDeviceSummary(String phoneNumber);
  Future<List<DeviceLoginInfo>> getUserDevices(String userId);
  Future<bool> deleteSession(String sessionId);
  Future<bool> deleteUserSession(String sessionId, String userId);
  Future<List<DeviceLoginInfo>> getActiveSessions();
  // New methods for all users data
  Future<List<DeviceLoginInfo>> getAllDevices();
  Future<List<DeviceLocationInfo>> getAllDeviceLocations();
  Future<MultiDeviceSummary> getAllUsersSummary();
}

/// Supabase implementation of MultiDeviceRepository
class MultiDeviceRepositorySupabase implements MultiDeviceRepository {
  final SupabaseClient _supabase;

  MultiDeviceRepositorySupabase(this._supabase);

  @override
  Future<List<DeviceLoginInfo>> getDevicesByPhoneNumber(String phoneNumber) async {
    try {
      // First, get all user IDs with this phone number
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, name, mobile')
          .eq('mobile', phoneNumber);

      if ((profilesResponse as List).isEmpty) {
        return [];
      }

      final profiles = profilesResponse;
      final userIds = profiles.map((p) => p['id'] as String).toList();
      final profileMap = {
        for (var p in profiles)
          p['id'] as String: {
            'name': p['name'],
            'mobile': p['mobile'],
          }
      };

      // Then get all sessions for these user IDs
      final sessionsResponse = await _supabase
          .from('user_sessions')
          .select('*')
          .inFilter('user_id', userIds)
          .order('started_at', ascending: false);

      return (sessionsResponse as List)
          .map((json) {
            final userId = json['user_id'] as String;
            final profile = profileMap[userId];
            return DeviceLoginInfo.fromJson({
              ...json,
              'user_name': profile?['name'],
              'phone_number': profile?['mobile'],
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get devices by phone number: $e');
    }
  }

  @override
  Future<int> getUniqueDeviceCount(String phoneNumber) async {
    try {
      final devices = await getDevicesByPhoneNumber(phoneNumber);
      final uniqueDeviceIds = <String>{};
      
      for (final device in devices) {
        final deviceId = device.deviceId;
        if (deviceId.isNotEmpty) {
          uniqueDeviceIds.add(deviceId);
        }
      }
      
      return uniqueDeviceIds.length;
    } catch (e) {
      throw Exception('Failed to get unique device count: $e');
    }
  }

  @override
  Future<List<DeviceLocationInfo>> getDeviceLocations(String phoneNumber) async {
    try {
      // Get all sessions for this phone number first
      final sessions = await getDevicesByPhoneNumber(phoneNumber);
      final sessionIds = sessions.map((s) => s.sessionId).toList();

      if (sessionIds.isEmpty) return [];

      // Query user_locations for these sessions
      final response = await _supabase
          .from('user_locations')
          .select()
          .inFilter('session_id', sessionIds)
          .order('captured_at', ascending: false);

      return (response as List)
          .map((json) => DeviceLocationInfo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get device locations: $e');
    }
  }

  @override
  Future<MultiDeviceSummary> getMultiDeviceSummary(String phoneNumber) async {
    try {
      final devices = await getDevicesByPhoneNumber(phoneNumber);
      final locations = await getDeviceLocations(phoneNumber);

      String? userName;
      if (devices.isNotEmpty) {
        userName = devices.first.userName;
      }

      return MultiDeviceSummary.fromDevices(
        phoneNumber: phoneNumber,
        userName: userName,
        devices: devices,
        locations: locations,
      );
    } catch (e) {
      throw Exception('Failed to get multi-device summary: $e');
    }
  }

  @override
  Future<List<DeviceLoginInfo>> getUserDevices(String userId) async {
    try {
      // Get user profile first
      final profileResponse = await _supabase
          .from('profiles')
          .select('name, mobile')
          .eq('id', userId)
          .maybeSingle();

      // Query user_sessions for a specific user
      final response = await _supabase
          .from('user_sessions')
          .select('*')
          .eq('user_id', userId)
          .order('started_at', ascending: false);

      final profile = profileResponse;

      return (response as List)
          .map((json) {
            return DeviceLoginInfo.fromJson({
              ...json,
              'user_name': profile?['name'],
              'phone_number': profile?['mobile'],
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get user devices: $e');
    }
  }

  @override
  Future<bool> deleteSession(String sessionId) async {
    try {
      // Delete session (hard delete)
      await _supabase
          .from('user_sessions')
          .delete()
          .eq('session_id', sessionId);

      // Also delete associated locations
      await _supabase
          .from('user_locations')
          .delete()
          .eq('session_id', sessionId);

      return true;
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  @override
  Future<bool> deleteUserSession(String sessionId, String userId) async {
    try {
      // Verify the session belongs to the user before deleting
      final sessionResponse = await _supabase
          .from('user_sessions')
          .select('user_id')
          .eq('session_id', sessionId)
          .maybeSingle();

      if (sessionResponse == null) {
        throw Exception('Session not found');
      }

      final sessionUserId = sessionResponse['user_id'] as String;
      if (sessionUserId != userId) {
        throw Exception('Unauthorized: Session does not belong to user');
      }

      // Delete session (hard delete)
      await _supabase
          .from('user_sessions')
          .delete()
          .eq('session_id', sessionId)
          .eq('user_id', userId);

      // Also delete associated locations
      await _supabase
          .from('user_locations')
          .delete()
          .eq('session_id', sessionId);

      return true;
    } catch (e) {
      throw Exception('Failed to delete user session: $e');
    }
  }

  @override
  Future<List<DeviceLoginInfo>> getActiveSessions() async {
    try {
      // Get active sessions - only show sessions with recent activity (within 15 minutes)
      // This ensures we only show truly "live" users, not old inactive sessions
      final now = DateTime.now().toUtc();
      final fifteenMinutesAgo = now.subtract(const Duration(minutes: 15));

      // Get sessions that are active AND have recent activity (within last 15 minutes)
      final sessionsResponse = await _supabase
          .from('user_sessions')
          .select('*')
          .eq('is_active', true)
          .gte('last_activity_at', fifteenMinutesAgo.toIso8601String())
          .order('last_activity_at', ascending: false);

      if ((sessionsResponse as List).isEmpty) {
        return [];
      }

      final sessions = sessionsResponse;
      final userIds = sessions.map((s) => s['user_id'] as String).toSet().toList();

      // Get profiles for these user IDs
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, name, mobile')
          .inFilter('id', userIds);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final profile in profilesResponse as List) {
        profileMap[profile['id'] as String] = {
          'name': profile['name'],
          'mobile': profile['mobile'],
        };
      }
    
      // Combine sessions with profile data
      final allSessions = sessions
          .map((json) {
            final userId = json['user_id'] as String;
            final profile = profileMap[userId];
            return DeviceLoginInfo.fromJson({
              ...json,
              'user_name': profile?['name'],
              'phone_number': profile?['mobile'],
            });
          })
          .toList();

      // Deduplicate by user_id - keep only the most recent session per user
      final userSessionMap = <String, DeviceLoginInfo>{};
      for (final session in allSessions) {
        final userId = session.userId;
        if (!userSessionMap.containsKey(userId) || 
            session.lastActivityAt.isAfter(userSessionMap[userId]!.lastActivityAt)) {
          userSessionMap[userId] = session;
        }
      }

      final result = userSessionMap.values.toList();
      
      // Sort by last activity (most recent first)
      result.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('MultiDeviceRepository: Error getting active sessions: $e');
        print('MultiDeviceRepository: Error type: ${e.runtimeType}');
      }
      throw Exception('Failed to get active sessions: $e');
    }
  }

  @override
  Future<List<DeviceLoginInfo>> getAllDevices() async {
    try {
      // Get all sessions from all users
      final sessionsResponse = await _supabase
          .from('user_sessions')
          .select('*')
          .order('started_at', ascending: false);

      if ((sessionsResponse as List).isEmpty) {
        return [];
      }

      final sessions = sessionsResponse;
      final userIds = sessions.map((s) => s['user_id'] as String).toSet().toList();

      // Get profiles for all user IDs
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, name, mobile')
          .inFilter('id', userIds);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final profile in profilesResponse as List) {
        profileMap[profile['id'] as String] = {
          'name': profile['name'],
          'mobile': profile['mobile'],
        };
      }
    
      // Combine sessions with profile data
      return sessions
          .map((json) {
            final userId = json['user_id'] as String;
            final profile = profileMap[userId];
            return DeviceLoginInfo.fromJson({
              ...json,
              'user_name': profile?['name'],
              'phone_number': profile?['mobile'],
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to get all devices: $e');
    }
  }

  @override
  Future<List<DeviceLocationInfo>> getAllDeviceLocations() async {
    try {
      // Query all locations from user_locations table
      final response = await _supabase
          .from('user_locations')
          .select()
          .order('captured_at', ascending: false);

      return (response as List)
          .map((json) => DeviceLocationInfo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all device locations: $e');
    }
  }

  @override
  Future<MultiDeviceSummary> getAllUsersSummary() async {
    try {
      final devices = await getAllDevices();
      final locations = await getAllDeviceLocations();

      return MultiDeviceSummary.fromDevices(
        phoneNumber: 'All Users',
        userName: null,
        devices: devices,
        locations: locations,
      );
    } catch (e) {
      throw Exception('Failed to get all users summary: $e');
    }
  }
}

/// Provider for multi-device repository
final multiDeviceRepositoryProvider = Provider<MultiDeviceRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return MultiDeviceRepositorySupabase(supabase);
});

