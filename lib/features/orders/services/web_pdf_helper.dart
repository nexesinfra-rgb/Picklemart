import 'dart:html' as html show Blob, Url, AnchorElement;
import 'dart:typed_data' show Uint8List;

/// Web implementation for PDF download using dart:html.
/// This file is only imported on web platforms.
class WebPdfHelper {
  /// Download PDF on web by creating a blob URL and triggering download
  static Future<void> downloadPdf(Uint8List pdfBytes, String fileName) async {
    try {
      // Create a blob URL and trigger download
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      rethrow;
    }
  }
}

