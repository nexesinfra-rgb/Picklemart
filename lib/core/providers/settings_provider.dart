import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fcm_service.dart';

// Settings state class
class SettingsState {
  final bool infiniteScrollEnabled;
  final bool pushNotificationsEnabled;
  final bool darkModeEnabled;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.infiniteScrollEnabled = false,
    this.pushNotificationsEnabled = true,
    this.darkModeEnabled = false,
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    bool? infiniteScrollEnabled,
    bool? pushNotificationsEnabled,
    bool? darkModeEnabled,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      infiniteScrollEnabled:
          infiniteScrollEnabled ?? this.infiniteScrollEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  static const String _infiniteScrollKey = 'infinite_scroll_enabled';
  static const String _pushNotificationsKey = 'push_notifications_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final infiniteScrollEnabled = prefs.getBool(_infiniteScrollKey) ?? false;
      final pushNotificationsEnabled = prefs.getBool(_pushNotificationsKey) ?? true;
      final darkModeEnabled = prefs.getBool(_darkModeKey) ?? false;

      state = state.copyWith(
        infiniteScrollEnabled: infiniteScrollEnabled,
        pushNotificationsEnabled: pushNotificationsEnabled,
        darkModeEnabled: darkModeEnabled,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleInfiniteScroll(bool enabled) async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_infiniteScrollKey, enabled);

      state = state.copyWith(
        infiniteScrollEnabled: enabled,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> togglePushNotifications(bool enabled) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // If enabling notifications, request permission first
      if (enabled) {
        try {
          final fcmService = FcmService();
          if (!fcmService.isInitialized) {
            state = state.copyWith(
              isLoading: false,
              error: 'Notification service is not initialized. Please restart the app.',
            );
            return false;
          }

          // Request notification permission
          final granted = await fcmService.requestNotificationPermission();
          if (!granted) {
            // Permission denied - don't enable notifications
            state = state.copyWith(
              isLoading: false,
              error: 'Notification permission was denied. Please enable it in your device settings to receive push notifications.',
            );
            return false;
          }
        } catch (e) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to request notification permission: ${e.toString()}',
          );
          return false;
        }
      }

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pushNotificationsKey, enabled);

      state = state.copyWith(
        pushNotificationsEnabled: enabled,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> toggleDarkMode(bool enabled) async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, enabled);

      state = state.copyWith(
        darkModeEnabled: enabled,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await _loadSettings();
  }
}

// Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);

// Convenience providers
final infiniteScrollEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).infiniteScrollEnabled;
});

final pushNotificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).pushNotificationsEnabled;
});

// Helper function to safely get darkModeEnabled from settings state
// Handles hot reload cases where the field might not exist in cached state instances
bool _getDarkModeEnabled(dynamic settings) {
  try {
    // Use dynamic access first to avoid triggering type errors on missing fields
    final dynamicSettings = settings as dynamic;
    final value = dynamicSettings?.darkModeEnabled;
    // Check if we got a valid bool value
    if (value is bool) {
      return value;
    }
    // Fallback: try normal access if dynamic didn't work
    if (settings is SettingsState) {
      return settings.darkModeEnabled;
    }
  } catch (e) {
    // If any error occurs, return safe default
  }
  return false;
}

final darkModeEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return _getDarkModeEnabled(settings);
});

final settingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).isLoading;
});

