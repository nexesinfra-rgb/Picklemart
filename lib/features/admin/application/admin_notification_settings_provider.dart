import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final adminNotificationSettingsProvider =
    StateNotifierProvider<AdminNotificationSettingsNotifier, bool>((ref) {
  return AdminNotificationSettingsNotifier();
});

class AdminNotificationSettingsNotifier extends StateNotifier<bool> {
  static const _key = 'admin_notification_sound_enabled';

  AdminNotificationSettingsNotifier() : super(true) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggleSound() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state;
    await prefs.setBool(_key, newValue);
    state = newValue;
  }
}
