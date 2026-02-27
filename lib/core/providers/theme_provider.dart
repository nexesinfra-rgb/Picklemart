import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'settings_provider.dart';

/// Cached light theme provider - built only once
final lightThemeProvider = Provider<ThemeData>((ref) {
  return buildAppTheme();
});

/// Cached dark theme provider - built only once
final darkThemeProvider = Provider<ThemeData>((ref) {
  return buildAppDarkTheme();
});

/// Theme mode provider that watches user settings for dark mode preference
final themeModeProvider = Provider<ThemeMode>((ref) {
  final darkModeEnabled = ref.watch(darkModeEnabledProvider);
  return darkModeEnabled ? ThemeMode.dark : ThemeMode.light;
});

/// Combined theme provider that provides both themes and theme mode
/// This ensures themes are cached and only rebuilt when dark mode setting changes
final appThemeProvider = Provider<AppThemeData>((ref) {
  final lightTheme = ref.watch(lightThemeProvider);
  final darkTheme = ref.watch(darkThemeProvider);
  final themeMode = ref.watch(themeModeProvider);
  
  return AppThemeData(
    lightTheme: lightTheme,
    darkTheme: darkTheme,
    themeMode: themeMode,
  );
});

/// Data class to hold both themes and theme mode
class AppThemeData {
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;

  const AppThemeData({
    required this.lightTheme,
    required this.darkTheme,
    required this.themeMode,
  });
}

