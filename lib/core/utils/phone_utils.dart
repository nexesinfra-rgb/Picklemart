import '../config/environment.dart';

/// Utility class for handling phone number operations and conversions
class PhoneUtils {
  /// Converts a mobile number to a deterministic email format
  /// Example: 9876543210 -> 919876543210@phone.local
  static String mobileToEmail(String mobile) {
    // Remove any non-digit characters
    String cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');

    // If it's a 10-digit number, always prepend the country code
    if (cleanMobile.length == 10) {
      cleanMobile = Environment.phoneDefaultCountryCode + cleanMobile;
    }
    // Otherwise, add default country code only if not already present
    else if (!cleanMobile.startsWith(Environment.phoneDefaultCountryCode)) {
      cleanMobile = Environment.phoneDefaultCountryCode + cleanMobile;
    }

    return '$cleanMobile@${Environment.phoneEmailDomain}';
  }

  /// Extracts mobile number from email format
  /// Example: 919876543210@phone.local -> 9876543210
  static String emailToMobile(String email) {
    if (!email.endsWith('@${Environment.phoneEmailDomain}')) {
      throw ArgumentError('Invalid phone email format');
    }

    String phoneWithCountryCode = email.split('@')[0];

    // Remove country code if present
    if (phoneWithCountryCode.startsWith(Environment.phoneDefaultCountryCode)) {
      return phoneWithCountryCode.substring(
        Environment.phoneDefaultCountryCode.length,
      );
    }

    return phoneWithCountryCode;
  }

  /// Validates if the mobile number is valid
  static bool isValidMobile(String mobile) {
    String cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid 10-digit Indian mobile number
    if (cleanMobile.length == 10) {
      return RegExp(r'^[6-9]\d{9}$').hasMatch(cleanMobile);
    }

    // Check if it's a valid mobile number with country code
    if (cleanMobile.length == 12 && cleanMobile.startsWith('91')) {
      String mobileWithoutCode = cleanMobile.substring(2);
      return RegExp(r'^[6-9]\d{9}$').hasMatch(mobileWithoutCode);
    }

    return false;
  }

  /// Formats mobile number for display
  /// Example: 9876543210 -> +91 98765 43210
  static String formatMobileForDisplay(String mobile) {
    String cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanMobile.length == 10) {
      return '+91 ${cleanMobile.substring(0, 5)} ${cleanMobile.substring(5)}';
    }

    if (cleanMobile.length == 12 && cleanMobile.startsWith('91')) {
      String mobileWithoutCode = cleanMobile.substring(2);
      return '+91 ${mobileWithoutCode.substring(0, 5)} ${mobileWithoutCode.substring(5)}';
    }

    return mobile;
  }

  /// Checks if an email is a phone-based email
  static bool isPhoneEmail(String email) {
    return email.endsWith('@${Environment.phoneEmailDomain}');
  }
}
