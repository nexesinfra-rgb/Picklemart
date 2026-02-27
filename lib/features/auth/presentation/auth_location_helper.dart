import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/session_tracking_service.dart';
import '../application/auth_controller.dart';
import 'location_permission_dialog.dart';

/// Helper to handle location permission and session start after authentication
class AuthLocationHelper {
  /// Handle post-authentication flow: location permission and session start
  /// Returns true immediately to allow navigation, operations run in background
  static Future<bool> handlePostAuth(
    BuildContext context,
    WidgetRef ref,
    AppRole role,
  ) async {
    // Skip location for admin users
    if (role == AppRole.admin) {
      _startSessionInBackground(ref);
      return true;
    }

    // Check permission without blocking
    final permission = await LocationService.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Permission already granted, start session in background
      _startSessionInBackground(ref);
      return true;
    }

    // Show dialog but don't block - start session in background
    _startSessionInBackground(ref);
    LocationPermissionDialog.show(context)
        .then((granted) {
          // Handle result but don't block navigation
          // Session already started in background
        })
        .catchError((e) => debugPrint('Location dialog error: $e'));
    
    return true; // Always proceed immediately
  }

  /// Start a session for the authenticated user in background (non-blocking)
  static void _startSessionInBackground(WidgetRef ref) {
    // Fire and forget - don't await
    _startSession(ref).catchError((e) => 
      debugPrint('Background session start error: $e'));
  }

  /// Start a session for the authenticated user
  static Future<void> _startSession(WidgetRef ref) async {
    try {
      final authState = ref.read(authControllerProvider);
      if (authState.userId != null) {
        final sessionService = ref.read(sessionTrackingServiceProvider);
        await sessionService.startSession(authState.userId!);
      }
    } catch (e) {
      // Silently fail - session tracking is not critical
      debugPrint('Failed to start session: $e');
    }
  }
}

