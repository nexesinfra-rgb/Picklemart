import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/environment.dart';
import '../data/order_model.dart';
import '../../admin/data/order_bill_service.dart';

// Web-specific imports
import 'web_download_helper.dart'
    if (dart.library.html) 'web_download_helper_web.dart';

enum OrderSharePlatform { whatsapp, sms, email, copyLink, more }

class OrderShareService {
  // Flag to track if a share operation is in progress
  static bool _isSharing = false;

  /// Share order bill PDF via specified platform
  /// Uses the store bill PDF format that was created when the order was converted to sale
  static Future<void> shareOrder(
    Order order,
    WidgetRef ref, {
    OrderSharePlatform? platform,
  }) async {
    // Check if a share operation is already in progress
    if (_isSharing) {
      throw Exception('Please wait for the current share to complete');
    }

    try {
      _isSharing = true;

      // Get bill service and find or generate bill
      final billService = OrderBillService.fromWidgetRef(ref);
      final pdfBytes = await billService.getOrderBillPdfBytes(order);

      // Create XFile from PDF bytes
      final xFile = XFile.fromData(
        pdfBytes,
        name: 'Bill_${order.orderNumber}.pdf',
        mimeType: 'application/pdf',
      );

      final message = _generateShareMessage(order);

      if (platform == null) {
        // Show share dialog with PDF file
        try {
          await _shareWithGuard([xFile], text: message);
        } catch (e) {
          // On web, if share fails due to user gesture requirement,
          // fall back to downloading the file
          if (kIsWeb && e.toString().contains('user gesture')) {
            await _downloadPdfOnWeb(pdfBytes, 'Bill_${order.orderNumber}.pdf');
            // Re-throw with a more user-friendly message
            throw Exception(
              'Please click the share button again to share the bill. The file has been prepared.',
            );
          }
          rethrow;
        }
        return;
      }

      switch (platform) {
        case OrderSharePlatform.whatsapp:
          await _shareViaWhatsAppWithFile(xFile, message, order);
          break;
        case OrderSharePlatform.sms:
          // SMS doesn't support files, fall back to text
          await _shareViaSMS(
            _generateShareMessage(order),
            _generateOrderUrl(order.id),
          );
          break;
        case OrderSharePlatform.email:
          await _shareViaEmailWithFile(xFile, order, message);
          break;
        case OrderSharePlatform.copyLink:
          await _copyToClipboard(_generateOrderUrl(order.id));
          break;
        case OrderSharePlatform.more:
          try {
            await _shareWithGuard([xFile], text: message);
          } catch (e) {
            if (kIsWeb && e.toString().contains('user gesture')) {
              await _downloadPdfOnWeb(
                pdfBytes,
                'Bill_${order.orderNumber}.pdf',
              );
              throw Exception(
                'Please click the share button again to share the bill. The file has been prepared.',
              );
            }
            rethrow;
          }
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing order bill: $e');
      }
      rethrow;
    } finally {
      _isSharing = false;
    }
  }

  /// Helper method to share files with guard against multiple simultaneous shares
  static Future<void> _shareWithGuard(
    List<XFile> files, {
    String? text,
    String? subject,
  }) async {
    try {
      await Share.shareXFiles(files, text: text, subject: subject);
    } catch (e) {
      // Handle the specific "earlier share has not yet completed" error
      if (e.toString().contains('earlier share has not yet completed') ||
          e.toString().contains('InvalidStateError')) {
        throw Exception('Please wait for the current share to complete');
      }
      rethrow;
    }
  }

  /// Download PDF on web as fallback when share fails
  static Future<void> _downloadPdfOnWeb(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    if (!kIsWeb) return;

    try {
      // Create a blob URL and trigger download
      downloadPdfOnWebHelper(pdfBytes, fileName);
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading PDF on web: $e');
      }
      // If download also fails, at least copy to clipboard as text
      await Clipboard.setData(
        ClipboardData(text: 'Bill PDF is ready. Please try sharing again.'),
      );
    }
  }

  /// Share PDF via WhatsApp (uses share_plus which handles file sharing)
  static Future<bool> _shareViaWhatsAppWithFile(
    XFile file,
    String message,
    Order order,
  ) async {
    try {
      // WhatsApp supports file sharing through the system share sheet
      await _shareWithGuard([file], text: message);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing via WhatsApp: $e');
      }
      return false;
    }
  }

  /// Share PDF via Email (uses share_plus which handles file sharing)
  static Future<bool> _shareViaEmailWithFile(
    XFile file,
    Order order,
    String message,
  ) async {
    try {
      // Email supports file sharing through the system share sheet
      await _shareWithGuard([file], text: message);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing via Email: $e');
      }
      return false;
    }
  }

  /// Generate shareable message for order
  static String _generateShareMessage(Order order) {
    final buffer = StringBuffer();
    buffer.writeln('Order #${order.orderNumber}');
    buffer.writeln('Status: ${order.status.displayName}');
    buffer.writeln(
      'Date: ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
    );
    buffer.writeln('Total: Rs ${order.total.toStringAsFixed(2)}');
    buffer.writeln('Items: ${order.items.length}');
    return buffer.toString();
  }

  /// Generate shareable URL for order
  static String _generateOrderUrl(String orderId) {
    // In a real app, this would be a deep link or web URL
    return '${Environment.appBaseUrl}/orders/$orderId';
  }

  /// Share via SMS
  static Future<bool> _shareViaSMS(String message, String url) async {
    try {
      final text = Uri.encodeComponent('$message\n\n$url');
      final uri = Uri.parse('sms:?body=$text');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing via SMS: $e');
      }
      return false;
    }
  }

  /// Copy text to clipboard
  static Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      if (kDebugMode) {
        print('Error copying to clipboard: $e');
      }
      rethrow;
    }
  }
}
