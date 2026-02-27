import 'dart:typed_data' show Uint8List;

/// Stub implementation for non-web platforms.
/// This file is used when dart:html is not available (mobile).
class WebPdfHelper {
  /// Stub method - does nothing on mobile platforms
  static Future<void> downloadPdf(Uint8List pdfBytes, String fileName) async {
    // No-op on mobile - this method should not be called on mobile
    // as it's only used when kIsWeb is true
  }
}

