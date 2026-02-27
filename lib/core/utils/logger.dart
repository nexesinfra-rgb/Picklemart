import 'package:flutter/foundation.dart';

/// Centralized logging utility that automatically strips logs in release builds
/// 
/// Usage:
/// ```dart
/// Logger.debug('Debug message');
/// Logger.info('Info message');
/// Logger.warning('Warning message');
/// Logger.error('Error message', error: e, stackTrace: st);
/// ```
class Logger {
  /// Log debug messages (only in debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      if (error != null) {
        debugPrint('🐛 DEBUG: $message\nError: $error');
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
      } else {
        debugPrint('🐛 DEBUG: $message');
      }
    }
  }

  /// Log info messages (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Log warning messages (only in debug mode)
  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      if (error != null) {
        debugPrint('⚠️ WARNING: $message\nError: $error');
      } else {
        debugPrint('⚠️ WARNING: $message');
      }
    }
  }

  /// Log error messages (only in debug mode)
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Log success messages (only in debug mode)
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ SUCCESS: $message');
    }
  }
}







