import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter/foundation.dart';

/// Service for launching external URLs, particularly WhatsApp
class UrlLauncherService {
  /// WhatsApp phone number (you can change this to your business number)
  static const String _whatsappNumber =
      '+919876543210'; // Replace with actual number

  /// Launch WhatsApp with a specific phone number
  static Future<bool> launchWhatsApp({
    String? phoneNumber,
    String? message,
  }) async {
    try {
      final number = phoneNumber ?? _whatsappNumber;
      final text = message ?? 'Hello! I need help with my order.';

      // Format: whatsapp://send?phone=PHONE_NUMBER&text=MESSAGE
      final uri = Uri.parse(
        'whatsapp://send?phone=$number&text=${Uri.encodeComponent(text)}',
      );

      if (await launcher.canLaunchUrl(uri)) {
        return await launcher.launchUrl(uri);
      } else {
        // Fallback to WhatsApp Web if app is not installed
        final webUri = Uri.parse(
          'https://wa.me/$number?text=${Uri.encodeComponent(text)}',
        );
        return await launcher.launchUrl(
          webUri,
          mode: launcher.LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching WhatsApp: $e');
      }
      return false;
    }
  }

  /// Launch WhatsApp with a specific message
  static Future<bool> launchWhatsAppWithMessage(String message) async {
    return await launchWhatsApp(message: message);
  }

  /// Launch WhatsApp with a specific phone number
  static Future<bool> launchWhatsAppWithNumber(
    String phoneNumber, {
    String? message,
  }) async {
    return await launchWhatsApp(phoneNumber: phoneNumber, message: message);
  }

  /// Launch any URL
  static Future<bool> launchUrl(
    Uri url, {
    launcher.LaunchMode mode = launcher.LaunchMode.platformDefault,
  }) async {
    try {
      if (await launcher.canLaunchUrl(url)) {
        return await launcher.launchUrl(url, mode: mode);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error launching URL: $e');
      }
      return false;
    }
  }
}
