import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../data/order_model.dart';
import '../../admin/data/order_bill_service.dart';

class OrderPrintService {
  /// Print an order bill as a PDF document
  /// Uses the store bill PDF format that was created when the order was converted to sale
  static Future<void> printOrder(Order order, WidgetRef ref) async {
    try {
      // Get bill service and find or generate bill
      final billService = OrderBillService.fromWidgetRef(ref);
      final pdfBytes = await billService.getOrderBillPdfBytes(order);

      // Print the bill PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error printing order bill: $e');
      }
      rethrow;
    }
  }

}

