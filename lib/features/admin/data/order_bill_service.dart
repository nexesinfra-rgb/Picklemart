import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/data/order_model.dart';
import 'bill_model.dart';
import 'bill_repository_supabase.dart';
import 'bill_pdf_service.dart';
import '../application/bill_controller.dart';
import 'payment_receipt_repository.dart';

/// Service for handling bill operations related to orders
/// Used for sharing and printing store bills
class OrderBillService {
  // Use dynamic typing to accept both Ref and WidgetRef
  // Both have the read() method we need
  final dynamic _ref;

  OrderBillService(this._ref);

  /// Create OrderBillService from WidgetRef
  /// This factory method helps bridge the gap between WidgetRef and Ref
  factory OrderBillService.fromWidgetRef(WidgetRef ref) {
    return OrderBillService(ref);
  }

  /// Get bill repository from provider
  BillRepositorySupabase get _billRepository {
    return _ref.read(billRepositoryProvider);
  }

  /// Get bill controller from provider
  BillController get _billController {
    return _ref.read(billControllerProvider.notifier);
  }

  /// Get PDF service from provider
  BillPdfService get _pdfService {
    return _ref.read(billPdfServiceProvider);
  }

  /// Find or generate a store bill for an order
  /// Returns the bill, generating it if it doesn't exist
  Future<Bill> findOrGenerateBill(Order order) async {
    try {
      // Parse current old due from order notes
      final currentOldDue = _parseOldDueFromNotes(order.notes);

      // First, try to find existing bill for this order
      final existingBills = await _billRepository.getBills(
        orderId: order.id,
        billType: BillType.user,
        limit: 1,
      );

      if (existingBills.isNotEmpty) {
        final existingBill = existingBills.first;

        // Check if bill data needs update (if shipping or old due changed)
        // We compare with parsed old due if it exists (> 0), otherwise we might want to check against calculated
        if (existingBill.billData.shipping != order.shipping ||
            (currentOldDue > 0 &&
                (existingBill.billData.oldDue - currentOldDue).abs() > 0.01)) {
          if (kDebugMode) {
            print(
              'Existing bill ${existingBill.billNumber} data is stale (Old Due: ${existingBill.billData.oldDue} vs $currentOldDue). Updating...',
            );
          }

          // Generate updated bill with current values
          final paymentRepo = _ref.read(paymentReceiptRepositoryProvider);
          final totalPaid = await paymentRepo.getTotalPaidForOrder(order.id);

          // Use parsed old due if available. Do NOT recalculate from repository automatically.
          final oldDueToUse = currentOldDue;

          final updatedBill = await _billController.generateBillFromOrder(
            order: order,
            billType: BillType.user,
            shipping: order.shipping,
            oldDue: oldDueToUse,
            receivedAmount: totalPaid,
          );

          if (updatedBill != null) {
            return updatedBill;
          }
        }

        return existingBill;
      }

      // No bill exists, generate one
      if (kDebugMode) {
        print('No bill found for order ${order.id}, generating new bill...');
      }

      // Generate bill using the controller
      // Use current order values for shipping and calculate old due from payments
      final paymentRepo = _ref.read(paymentReceiptRepositoryProvider);
      final totalPaid = await paymentRepo.getTotalPaidForOrder(order.id);

      // Prefer old due from notes if available. Do NOT recalculate from repository automatically.
      final oldDue = currentOldDue;

      final bill = await _billController.generateBillFromOrder(
        order: order,
        billType: BillType.user,
        shipping: order.shipping,
        oldDue: oldDue,
        receivedAmount: totalPaid,
      );

      if (bill == null) {
        throw Exception('Failed to generate bill for order');
      }

      return bill;
    } catch (e) {
      if (kDebugMode) {
        print('Error finding or generating bill: $e');
      }
      rethrow;
    }
  }

  /// Parse old due from order notes
  double _parseOldDueFromNotes(String? notes) {
    if (notes == null || notes.isEmpty) return 0.0;
    try {
      // Match "Old Due: ₹100.00" or "Old Due: Rs 100.00"
      final match = RegExp(r'Old Due: (?:₹|Rs\s*)([\d\.]+)').firstMatch(notes);
      if (match != null) {
        final val = match.group(1);
        if (val != null) {
          return double.tryParse(val) ?? 0.0;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing old due from notes: $e');
      }
    }
    return 0.0;
  }

  /// Get PDF bytes for a bill
  /// Always regenerates the PDF so the user gets the current template, then re-uploads it.
  Future<Uint8List> getBillPdfBytes(Bill bill) async {
    try {
      if (kDebugMode) {
        print('Generating fresh PDF for bill ${bill.billNumber}...');
      }

      final template = await _billRepository.getActiveBillTemplate(
        bill.billType,
      );
      final pdfBytes = await _pdfService.generateBillPdf(
        bill: bill,
        template: template,
      );

      // Optionally upload the generated PDF (truly non-blocking)
      // We don't await this, so the UI is responsive immediately
      _uploadPdfInBackground(bill, pdfBytes);

      return pdfBytes;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting bill PDF bytes: $e');
      }
      rethrow;
    }
  }

  /// Upload PDF in background without blocking the UI
  Future<void> _uploadPdfInBackground(Bill bill, Uint8List pdfBytes) async {
    try {
      if (kDebugMode) {
        print('Starting background PDF upload for bill ${bill.billNumber}...');
      }

      final pdfUrl = await _billRepository.uploadBillPdf(
        pdfBytes,
        bill.billNumber,
      );
      await _billRepository.updateBillPdfUrl(bill.id, pdfUrl);

      if (kDebugMode) {
        print('Background PDF upload successful for bill ${bill.billNumber}');
      }
    } catch (e) {
      // Non-critical error, just log it
      if (kDebugMode) {
        print('Warning: Failed to upload generated PDF in background: $e');
      }
    }
  }

  /// Get PDF bytes for an order (finds or generates bill first)
  Future<Uint8List> getOrderBillPdfBytes(Order order) async {
    final bill = await findOrGenerateBill(order);
    return await getBillPdfBytes(bill);
  }
}

/// Provider for OrderBillService
final orderBillServiceProvider = Provider<OrderBillService>((ref) {
  return OrderBillService(ref);
});
