import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/application/notification_controller.dart';
import '../../features/profile/application/profile_controller.dart';
import 'session_tracking_service.dart';

/// Service to handle app lifecycle states (foreground/background)
/// Manages notification subscriptions based on app state
class AppLifecycleService extends WidgetsBindingObserver {
  final Ref _ref;
  bool _isInitialized = false;
  AppLifecycleState? _currentState;
  Timer? _pauseTimer;

  AppLifecycleService(this._ref);

  /// Initialize the service and start observing lifecycle changes
  void initialize() {
    if (_isInitialized) return;
    
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    _currentState = WidgetsBinding.instance.lifecycleState;
    
    if (kDebugMode) {
      print('📱 AppLifecycleService: Initialized, current state: $_currentState');
    }
  }

  /// Dispose the service and stop observing
  void dispose() {
    if (!_isInitialized) return;
    
    _pauseTimer?.cancel();
    _pauseTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
    
    if (kDebugMode) {
      print('📱 AppLifecycleService: Disposed');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final previousState = _currentState;
    _currentState = state;
    
    if (kDebugMode) {
      print('📱 AppLifecycleService: State changed from $previousState to $state');
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// Handle app resumed (foreground)
  void _handleAppResumed() {
    if (kDebugMode) {
      print('📱 AppLifecycleService: App resumed - refreshing notifications and profile');
    }
    
    // Cancel any pending pause timer since app is back in foreground
    _pauseTimer?.cancel();
    _pauseTimer = null;
    
    // Refresh notifications when app comes to foreground
    // The notification controller will automatically resubscribe if needed
    try {
      _ref.read(notificationControllerProvider.notifier).refresh();
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppLifecycleService: Error refreshing notifications: $e');
      }
    }

    // Refresh profile when app comes to foreground
    // This ensures price visibility changes are picked up even if realtime subscription fails
    try {
      _ref.read(profileControllerProvider.notifier).loadCurrentProfile();
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppLifecycleService: Error refreshing profile: $e');
      }
    }
  }

  /// Handle app paused (background)
  void _handleAppPaused() {
    if (kDebugMode) {
      print('📱 AppLifecycleService: App paused - notifications will continue in background');
    }
    // Cancel any existing pause timer
    _pauseTimer?.cancel();
    // Schedule session end after 5 minutes of being paused (user likely closed app)
    // This handles cases where app is closed but detached event doesn't fire
    _pauseTimer = Timer(const Duration(minutes: 5), () {
      if (_currentState == AppLifecycleState.paused || 
          _currentState == AppLifecycleState.inactive ||
          _currentState == AppLifecycleState.hidden) {
        if (kDebugMode) {
          print('📱 AppLifecycleService: App paused for 5+ minutes - ending session');
        }
        try {
          final sessionService = _ref.read(sessionTrackingServiceProvider);
          sessionService.endSession();
        } catch (e) {
          if (kDebugMode) {
            print('❌ AppLifecycleService: Error ending session after pause: $e');
          }
        }
      }
      _pauseTimer = null;
    });
  }

  /// Handle app detached
  void _handleAppDetached() {
    if (kDebugMode) {
      print('📱 AppLifecycleService: App detached - ending session');
    }
    // End session when app is closed/terminated
    try {
      final sessionService = _ref.read(sessionTrackingServiceProvider);
      sessionService.endSession();
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppLifecycleService: Error ending session on detach: $e');
      }
    }
  }

  /// Handle app hidden
  void _handleAppHidden() {
    if (kDebugMode) {
      print('📱 AppLifecycleService: App hidden');
    }
    // Similar to paused, subscriptions continue
  }

  /// Get current app lifecycle state
  AppLifecycleState? get currentState => _currentState;

  /// Check if app is in foreground
  bool get isInForeground {
    return _currentState == AppLifecycleState.resumed;
  }

  /// Check if app is in background
  bool get isInBackground {
    return _currentState == AppLifecycleState.paused ||
        _currentState == AppLifecycleState.inactive ||
        _currentState == AppLifecycleState.hidden;
  }
}

/// Provider for AppLifecycleService
final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  final service = AppLifecycleService(ref);
  // Initialize automatically when provider is created
  service.initialize();
  // Cleanup when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

