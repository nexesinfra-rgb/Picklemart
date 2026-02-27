// Stub file for web platform detection
// This file is used when dart:io is not available (web)
class Platform {
  static bool get isIOS => false;
  static bool get isAndroid => false;
  static String get operatingSystem => 'web';
}

