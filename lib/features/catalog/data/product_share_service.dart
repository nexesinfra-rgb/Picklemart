import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../../../core/config/environment.dart';
import '../../../core/services/url_launcher_service.dart';
import 'product.dart';

/// Service for sharing products via various platforms
class ProductShareService {
  /// Generate shareable product URL
  static String generateProductUrl(String productId) {
    // Use HTTPS URL for web compatibility
    // In production, replace with your actual domain
    return '${Environment.appBaseUrl}/product/$productId';
  }

  /// Generate share message with product details
  static String generateShareMessage(Product product, String url) {
    return 'Check out this product: ${product.name} - ₹${product.finalPrice.toStringAsFixed(2)}\n\n$url';
  }

  /// Share via WhatsApp
  static Future<bool> shareViaWhatsApp(String message) async {
    try {
      return await UrlLauncherService.launchWhatsAppWithMessage(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing via WhatsApp: $e');
      }
      return false;
    }
  }

  /// Share via SMS
  static Future<bool> shareViaSMS(String message) async {
    try {
      final uri = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');
      if (await launcher.canLaunchUrl(uri)) {
        return await launcher.launchUrl(uri);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing via SMS: $e');
      }
      return false;
    }
  }

  /// Share via Email
  static Future<bool> shareViaEmail(String subject, String body) async {
    try {
      final uri = Uri.parse(
        'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );
      if (await launcher.canLaunchUrl(uri)) {
        return await launcher.launchUrl(uri);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing via Email: $e');
      }
      return false;
    }
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      if (kDebugMode) {
        print('Error copying to clipboard: $e');
      }
      rethrow;
    }
  }

  /// Share via system share sheet (supports all platforms)
  static Future<void> shareViaSystem(String text) async {
    try {
      await Share.share(text);
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing via system: $e');
      }
      rethrow;
    }
  }

  /// Share product via specified platform
  static Future<bool> shareProduct(
    Product product,
    SharePlatform platform,
  ) async {
    try {
      final url = generateProductUrl(product.id);
      final message = generateShareMessage(product, url);

      switch (platform) {
        case SharePlatform.whatsapp:
          return await shareViaWhatsApp(message);
        case SharePlatform.sms:
          return await shareViaSMS(message);
        case SharePlatform.email:
          return await shareViaEmail(
            'Check out this product: ${product.name}',
            message,
          );
        case SharePlatform.copyLink:
          await copyToClipboard(url);
          return true;
        case SharePlatform.more:
          await shareViaSystem(message);
          return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing product: $e');
      }
      return false;
    }
  }
}

/// Enum for sharing platforms
enum SharePlatform {
  whatsapp,
  sms,
  email,
  copyLink,
  more,
}





