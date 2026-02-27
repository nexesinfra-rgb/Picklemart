import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../../main.dart';

// Global instance for local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Create Android notification channels
Future<void> _createNotificationChannels() async {
  if (!Platform.isAndroid) return;

  // Admin notification channel
  const adminChannel = AndroidNotificationChannel(
    'admin_notifications',
    'Admin Notifications',
    description: 'Notifications for admin users',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // User notification channel
  const userChannel = AndroidNotificationChannel(
    'user_notifications',
    'User Notifications',
    description: 'Notifications for regular users',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Admin alerts silent channel (for backward compatibility)
  const adminChannelSilent = AndroidNotificationChannel(
    'admin_alerts_silent',
    'Admin Alerts (Silent)',
    description: 'Silent notifications for admin users',
    importance: Importance.high,
    playSound: false,
    enableVibration: true,
  );

  // Create channels
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(adminChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(userChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(adminChannelSilent);
}

/// Determine if message is for admin based on message data
bool _isAdminNotification(RemoteMessage message) {
  final notificationType = message.data['type'] ?? '';
  // Admin notification if type contains 'admin' or has user_name field (admin notifying about user)
  return notificationType.toString().toLowerCase().contains('admin') ||
      message.data.containsKey('user_name');
}

/// Top-level function for handling background messages (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    print('📱 FCM: Background message received: ${message.messageId}');
  }

  // Initialize Local Notifications for background handling
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Create notification channels if on Android
  if (Platform.isAndroid) {
    await _createNotificationChannels();
  }

  // Determine if this is an admin or user notification
  final isAdmin = _isAdminNotification(message);

  // Determine channel and sound preference
  String channelId;
  String channelName;
  bool isSoundEnabled = true;

  if (isAdmin) {
    channelId = 'admin_notifications';
    channelName = 'Admin Notifications';
    // Check admin sound preference
    try {
      final prefs = await SharedPreferences.getInstance();
      isSoundEnabled = prefs.getBool('admin_notification_sound_enabled') ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('Error reading admin prefs in background: $e');
      }
    }
  } else {
    channelId = 'user_notifications';
    channelName = 'User Notifications';
    // Check user sound preference
    try {
      final prefs = await SharedPreferences.getInstance();
      isSoundEnabled = prefs.getBool('user_notification_sound_enabled') ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('Error reading user prefs in background: $e');
      }
    }
  }

  // Extract content
  final title =
      message.notification?.title ?? message.data['title'] ?? 'New Notification';
  final body =
      message.notification?.body ?? message.data['message'] ?? 'You have a new message';

  // Show notification
  await flutterLocalNotificationsPlugin.show(
    message.messageId.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: isSoundEnabled,
        sound: isSoundEnabled ? const RawResourceAndroidNotificationSound('default') : null,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.toString(),
  );
}

/// Service for handling Firebase Cloud Messaging (FCM) notifications
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  FirebaseMessaging? _messaging;
  bool _initialized = false;
  bool _hasPermission = false;
  String? _currentToken;
  Function(RemoteMessage)? _onNotificationTap;
  SupabaseClient? _supabase;

  /// Initialize FCM service
  /// [requestPermissionNow] - If true, requests notification permission immediately.
  /// Default is false to comply with Google Play Store policies.
  /// Permission should be requested contextually (after login or when user enables notifications).
  Future<void> initialize(SupabaseClient supabase, {bool requestPermissionNow = false}) async {
    // Skip FCM initialization on web - FCM doesn't work on web (web uses Web Push API)
    if (kIsWeb) {
      if (kDebugMode) {
        print('📱 FCM: Skipping initialization on web platform (FCM not supported on web)');
      }
      _initialized = true; // Mark as initialized to prevent retries
      return;
    }

    if (_initialized) {
      if (kDebugMode) {
        print('📱 FCM: Already initialized');
      }
      return;
    }

    try {
      _supabase = supabase;

      // Initialize Firebase Messaging
      _messaging = FirebaseMessaging.instance;

      // Initialize Local Notifications Plugin
      await _initializeLocalNotifications();

      // Create Android notification channels
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      // Request permission only if explicitly requested
      if (requestPermissionNow) {
        final granted = await requestNotificationPermission();
        if (!granted) {
          if (kDebugMode) {
            print('⚠️ FCM: Permission not granted, but continuing initialization');
          }
        }
      } else {
        // Check current permission status without requesting
        if (Platform.isIOS) {
          final settings = await _messaging!.getNotificationSettings();
          _hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
        } else if (Platform.isAndroid) {
          // For Android, check if we need to request permission (Android 13+)
          try {
            final deviceInfo = DeviceInfoPlugin();
            final androidInfo = await deviceInfo.androidInfo;
            final sdkInt = androidInfo.version.sdkInt;
            // Android 13 (API 33) and above require explicit notification permission
            if (sdkInt >= 33) {
              // Check actual permission status
              final settings = await _messaging!.getNotificationSettings();
              _hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized;
            } else {
              // Android 12 and below don't need explicit permission
              _hasPermission = true;
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ FCM: Could not check Android version: $e');
            }
            // Assume we need permission for safety
            _hasPermission = false;
          }
        } else {
          // Web or other platforms
          _hasPermission = false;
        }
      }

      // Continue initialization even without permission (for background token management)
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Setup foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Setup notification tap handler
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification (app was terminated)
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Try to get FCM token (may fail if permission not granted)
      try {
        // On iOS, wait for APNs token before requesting FCM token
        if (Platform.isIOS) {
          // Wait for APNs token (required for iOS push notifications)
          String? apnsToken = await _messaging!.getAPNSToken();
          if (apnsToken == null && kDebugMode) {
            print('⚠️ FCM: APNs token not available yet, retrying...');
            // Retry after a short delay
            await Future.delayed(const Duration(seconds: 1));
            apnsToken = await _messaging!.getAPNSToken();
          }
          if (kDebugMode && apnsToken != null) {
            print('📱 FCM: APNs token obtained: ${apnsToken.substring(0, 20)}...');
          }
        }
        _currentToken = await _messaging!.getToken();
        if (kDebugMode) {
          print('📱 FCM: Token obtained: ${_currentToken?.substring(0, 20)}...');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ FCM: Could not get token (permission may be required): $e');
        }
      }

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          print('📱 FCM: Token refreshed: ${newToken.substring(0, 20)}...');
        }
        _currentToken = newToken;
        
        // Automatically update token in database if user is authenticated
        if (_supabase != null) {
          try {
            final currentUser = _supabase!.auth.currentUser;
            if (currentUser != null) {
              // Check if user is admin or regular user
              final profileResponse = await _supabase!
                  .from('profiles')
                  .select('role')
                  .eq('id', currentUser.id)
                  .maybeSingle();
              
              if (profileResponse != null) {
                final role = profileResponse['role'] as String?;
                if (role == 'admin' || role == 'manager' || role == 'support') {
                  // Update admin token
                  await registerToken(currentUser.id);
                } else {
                  // Update user token
                  await registerUserToken(currentUser.id);
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ FCM: Error auto-updating token on refresh: $e');
            }
          }
        }
      });

      _initialized = true;
      if (kDebugMode) {
        print('✅ FCM: Service initialized successfully (permission: $_hasPermission)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM: Initialization error: $e');
      }
      rethrow;
    }
  }

  /// Request notification permission
  /// Returns true if permission is granted, false otherwise
  /// Note: On iOS, this shows a system dialog. On Android 13+ (API 33+), this also shows a system dialog.
  /// On Android 12 and below, notification permission is granted by default.
  Future<bool> requestNotificationPermission() async {
    // FCM doesn't work on web - return false immediately
    if (kIsWeb) {
      if (kDebugMode) {
        print('📱 FCM: Permission request skipped on web platform (FCM not supported on web)');
      }
      return false;
    }

    _messaging ??= FirebaseMessaging.instance;

    try {
      // Check if we're on Android 13+ which requires explicit permission
      bool needsPermission = false;
      if (Platform.isAndroid) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          final sdkInt = androidInfo.version.sdkInt;
          // Android 13 (API 33) and above require explicit notification permission
          needsPermission = sdkInt >= 33;
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ FCM: Could not check Android version, assuming permission needed: $e');
          }
          needsPermission = true; // Assume we need it for safety
        }
      } else if (Platform.isIOS) {
        needsPermission = true; // iOS always needs permission
      }

      if (!needsPermission && Platform.isAndroid) {
        // Android 12 and below - permission is granted by default
        _hasPermission = true;
        if (kDebugMode) {
          print('📱 FCM: Android 12 or below - notification permission granted by default');
        }
        return true;
      }

      // Request permission (iOS or Android 13+)
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('📱 FCM: Permission status: ${settings.authorizationStatus}');
      }

      _hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (_hasPermission) {
        // Try to get token now that we have permission
        try {
          _currentToken = await _messaging!.getToken();
          if (kDebugMode) {
            print('📱 FCM: Token obtained after permission grant: ${_currentToken?.substring(0, 20)}...');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ FCM: Could not get token after permission grant: $e');
          }
        }
      }

      return _hasPermission;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM: Error requesting permission: $e');
      }
      _hasPermission = false;
      return false;
    }
  }

  /// Check if notification permission has been granted
  bool get hasPermission => _hasPermission;

  /// Get current FCM token
  String? get token => _currentToken;

  /// Check if FCM is initialized
  bool get isInitialized => _initialized;

  /// Initialize Local Notifications Plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print('📱 FCM: Local notification tapped: ${response.payload}');
        }
        // Handle notification tap - payload contains message data
        if (response.payload != null && _onNotificationTap != null) {
          // Try to parse payload and create RemoteMessage-like handling
          // For now, just log - actual navigation should be handled by setOnNotificationTap callback
          if (kDebugMode) {
            print('📱 FCM: Handling notification tap with payload: ${response.payload}');
          }
        }
      },
    );
  }

  /// Set callback for notification tap handling
  void setOnNotificationTap(Function(RemoteMessage) callback) {
    _onNotificationTap = callback;
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('📱 FCM: Foreground message received: ${message.messageId}');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');
    }

    // Determine if this is an admin or user notification
    final isAdmin = _isAdminNotification(message);

    // Determine channel and sound preference
    String channelId;
    String channelName;
    bool isSoundEnabled = true;

    if (isAdmin) {
      channelId = 'admin_notifications';
      channelName = 'Admin Notifications';
      // Check admin sound preference
      try {
        final prefs = await SharedPreferences.getInstance();
        isSoundEnabled = prefs.getBool('admin_notification_sound_enabled') ?? true;
      } catch (e) {
        if (kDebugMode) {
          print('Error reading admin prefs: $e');
        }
      }
    } else {
      channelId = 'user_notifications';
      channelName = 'User Notifications';
      // Check user sound preference
      try {
        final prefs = await SharedPreferences.getInstance();
        isSoundEnabled = prefs.getBool('user_notification_sound_enabled') ?? true;
      } catch (e) {
        if (kDebugMode) {
          print('Error reading user prefs: $e');
        }
      }
    }

    // Show local notification for foreground messages
    final title = message.notification?.title ?? message.data['title'] ?? 'New Notification';
    final body = message.notification?.body ?? message.data['message'] ?? 'You have a new message';

    await flutterLocalNotificationsPlugin.show(
      message.messageId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: isSoundEnabled,
          sound: isSoundEnabled ? const RawResourceAndroidNotificationSound('default') : null,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );

    // Also show SnackBar for immediate feedback
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.notification?.title != null)
                Text(
                  message.notification!.title!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (message.notification?.body != null)
                Text(message.notification!.body!),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              _handleNotificationTap(message);
            },
          ),
        ),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('📱 FCM: Notification tapped: ${message.messageId}');
      print('   Data: ${message.data}');
    }

    if (_onNotificationTap != null) {
      _onNotificationTap!(message);
    }
  }

  /// Get device information for token storage
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    if (kIsWeb) {
      return {
        'platform': 'web',
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
          'android_version': androidInfo.version.release,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData.addAll({
          'device_id': iosInfo.identifierForVendor ?? 'unknown',
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
          'ios_version': iosInfo.systemVersion,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ FCM: Error getting device info: $e');
      }
      // Continue with basic info
    }

    return deviceData;
  }

  /// Register FCM token for admin user
  Future<bool> registerToken(String adminId) async {
    if (!_initialized || _currentToken == null || _supabase == null) {
      if (kDebugMode) {
        print('❌ FCM: Cannot register token - service not initialized or token missing');
      }
      return false;
    }

    try {
      final deviceInfo = await _getDeviceInfo();

      // Check if token already exists for this admin
      final existingToken = await _supabase!
          .from('admin_fcm_tokens')
          .select('id, is_active')
          .eq('admin_id', adminId)
          .eq('fcm_token', _currentToken!)
          .maybeSingle();

      if (existingToken != null) {
        // Update existing token to be active
        await _supabase!
            .from('admin_fcm_tokens')
            .update({
              'is_active': true,
              'device_info': deviceInfo,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingToken['id']);

        if (kDebugMode) {
          print('✅ FCM: Token updated in database');
        }
      } else {
        // Insert new token
        await _supabase!.from('admin_fcm_tokens').insert({
          'admin_id': adminId,
          'fcm_token': _currentToken!,
          'device_info': deviceInfo,
          'is_active': true,
        });

        if (kDebugMode) {
          print('✅ FCM: Token registered in database');
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM: Error registering token: $e');
      }
      return false;
    }
  }

  /// Unregister/delete FCM token for admin user
  Future<bool> unregisterToken(String adminId) async {
    if (!_initialized || _currentToken == null || _supabase == null) {
      if (kDebugMode) {
        print('❌ FCM: Cannot unregister token - service not initialized or token missing');
      }
      return false;
    }

    try {
      // Mark token as inactive instead of deleting (allows re-activation)
      await _supabase!
          .from('admin_fcm_tokens')
          .update({'is_active': false})
          .eq('admin_id', adminId)
          .eq('fcm_token', _currentToken!);

      if (kDebugMode) {
        print('✅ FCM: Token unregistered (marked inactive)');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM: Error unregistering token: $e');
      }
      return false;
    }
  }

  /// Delete all tokens for admin user (for logout)
  Future<bool> deleteAllTokens(String adminId) async {
    if (_supabase == null) {
      if (kDebugMode) {
        print('❌ FCM: Cannot delete tokens - Supabase not initialized');
      }
      return false;
    }

    try {
      await _supabase!
          .from('admin_fcm_tokens')
          .update({'is_active': false})
          .eq('admin_id', adminId);

      if (kDebugMode) {
        print('✅ FCM: All tokens marked inactive for admin');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM: Error deleting tokens: $e');
      }
      return false;
    }
  }

  /// Register FCM token for regular user
  Future<bool> registerUserToken(String userId) async {
    if (!_initialized || _currentToken == null || _supabase == null) {
      if (kDebugMode) {
        print('❌ FCM: Cannot register user token - service not initialized or token missing');
      }
      return false;
    }

    try {
      final deviceInfo = await _getDeviceInfo();

      // Check if token already exists for this user
      final existingToken = await _supabase!
          .from('user_fcm_tokens')
          .select('id, is_active')
          .eq('user_id', userId)
          .eq('fcm_token', _currentToken!)
          .maybeSingle();

      if (existingToken != null) {
        // Update existing token to be active
        await _supabase!
            .from('user_fcm_tokens')
            .update({
              'is_active': true,
              'device_info': deviceInfo,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingToken['id']);

        if (kDebugMode) {
          print('✅ FCM: User token updated in database');
        }
      } else {
        // Insert new token
        await _supabase!.from('user_fcm_tokens').insert({
          'user_id': userId,
          'fcm_token': _currentToken!,
          'device_info': deviceInfo,
          'is_active': true,
        });

        if (kDebugMode) {
          print('✅ FCM: User token registered in database');
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM: Error registering user token: $e');
      }
      return false;
    }
  }

  /// Unregister/delete FCM token for regular user
  Future<bool> unregisterUserToken(String userId) async {
    if (!_initialized || _currentToken == null || _supabase == null) {
      if (kDebugMode) {
        print('❌ FCM: Cannot unregister user token - service not initialized or token missing');
      }
      return false;
    }

    try {
      // Mark token as inactive instead of deleting (allows re-activation)
      await _supabase!
          .from('user_fcm_tokens')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('fcm_token', _currentToken!);

      if (kDebugMode) {
        print('✅ FCM: User token unregistered (marked inactive)');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM: Error unregistering user token: $e');
      }
      return false;
    }
  }

  /// Delete all tokens for regular user (for logout)
  Future<bool> deleteAllUserTokens(String userId) async {
    if (_supabase == null) {
      if (kDebugMode) {
        print('❌ FCM: Cannot delete user tokens - Supabase not initialized');
      }
      return false;
    }

    try {
      await _supabase!
          .from('user_fcm_tokens')
          .update({'is_active': false})
          .eq('user_id', userId);

      if (kDebugMode) {
        print('✅ FCM: All user tokens marked inactive');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM: Error deleting user tokens: $e');
      }
      return false;
    }
  }
}

/// Provider for FCM service instance
final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});

