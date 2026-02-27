import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/number_to_words.dart';
import '../domain/credit_transaction.dart';
import '../domain/purchase_order.dart';
import 'store_company_info.dart';

/// Paid-to info for Payment Out PDF. Pass name and optional address/phone/GST.
class PaidToInfo {
  final String name;
  final String? address;
  final String? phone;
  final String? gstNumber;

  const PaidToInfo({
    required this.name,
    this.address,
    this.phone,
    this.gstNumber,
  });
}

/// Shared service to generate Payment Out PDFs with heading "Payment Out",
/// and Amount Paid + Balance visible. Used by admin_payment_out_list_screen
/// and admin_customer_orders_screen.
class PaymentOutPdfService {
  PaymentOutPdfService._();

  static final PdfColor _orangeColor = PdfColor.fromInt(0xFFFFA726);
  static final PdfColor _borderColor = PdfColor.fromInt(0xFFE5E7EB);
  static final PdfColor _textColor = PdfColors.black;

  static pw.MemoryImage? _cachedLogo;

  static final Map<String, Uint8List> _pdfCache = {};
  static const int _maxCacheSize = 10;

  /// Clears the PDF cache. If [transactionId] is provided, only that transaction's cache is cleared.
  static void clearCache({String? transactionId}) {
    if (transactionId == null) {
      _pdfCache.clear();
    } else {
      _pdfCache.remove(transactionId);
    }
  }

  /// Preloads the logo so the first share/print does not wait on asset load.
  static Future<void> preloadLogo() async {
    await _loadLogo();
  }

  static Future<pw.MemoryImage?> _loadLogo() async {
    if (_cachedLogo != null) return _cachedLogo;
    try {
      final data = await rootBundle.load('assets/picklemart.png');
      final bytes = data.buffer.asUint8List();
      _cachedLogo = pw.MemoryImage(bytes);
      return _cachedLogo;
    } catch (_) {
      return null;
    }
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
  );

  /// Generates Payment Out PDF bytes in client receipt layout: company header,
  /// "Payment Out" title, two-column body (Paid To + Amount In Words |
  /// Receipt Details, Date, Paid, Payment Mode), and signature block.
  static Future<Uint8List> generatePaymentOutPdf({
    required CreditTransaction transaction,
    required PaidToInfo paidTo,
    required PurchaseOrder linkedPO,
  }) async {
    final cacheKey = transaction.id;
    if (_pdfCache.containsKey(cacheKey)) {
      return _pdfCache[cacheKey]!;
    }

    await _loadLogo();

    final logoImage = _cachedLogo;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            _buildCompanyHeader(logoImage),
            pw.SizedBox(height: 8),
            pw.Divider(color: _orangeColor, thickness: 1),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'Payment Out',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _orangeColor,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            _buildReceiptBody(transaction: transaction, paidTo: paidTo),
          ];
        },
      ),
    );
    final pdfBytes = await pdf.save();

    _pdfCache[cacheKey] = pdfBytes;
    if (_pdfCache.length > _maxCacheSize) {
      _pdfCache.remove(_pdfCache.keys.first);
    }

    return pdfBytes;
  }

  static pw.Widget _buildReceiptBody({
    required CreditTransaction transaction,
    required PaidToInfo paidTo,
  }) {
    final dateStr = DateFormat(
      'dd-MM-yyyy',
    ).format(transaction.transactionDate);
    final paidFormatted = _currencyFormat.format(transaction.amount);
    final amountInWords = NumberToWords.convert(transaction.amount);
    final paymentMode = transaction.paymentMethod?.displayName ?? 'Cash';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Paid To',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                paidTo.name,
                style: pw.TextStyle(fontSize: 10, color: _textColor),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Amount In Words',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                amountInWords,
                style: pw.TextStyle(fontSize: 10, color: _textColor),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Receipt Details',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Date: $dateStr',
                  style: pw.TextStyle(fontSize: 10, color: _textColor),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Paid',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  pw.Text(
                    paidFormatted,
                    style: pw.TextStyle(fontSize: 10, color: _textColor),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Payment Mode',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  pw.Text(
                    paymentMode,
                    style: pw.TextStyle(fontSize: 10, color: _textColor),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'For: ${StoreCompanyInfo.name}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 120,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: _textColor, width: 0.5),
                    ),
                  ),
                  height: 16,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Authorized Signatory',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCompanyHeader(pw.MemoryImage? logoImage) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                StoreCompanyInfo.name,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                StoreCompanyInfo.address,
                style: pw.TextStyle(fontSize: 9, color: _textColor),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Phone no.: ${StoreCompanyInfo.phone}',
                style: pw.TextStyle(fontSize: 9, color: _textColor),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Email: ${StoreCompanyInfo.email}',
                style: pw.TextStyle(fontSize: 9, color: _textColor),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'State: ${StoreCompanyInfo.state}',
                style: pw.TextStyle(fontSize: 9, color: _textColor),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'FSSAI NO: ${StoreCompanyInfo.fssaiNo}',
                style: pw.TextStyle(fontSize: 9, color: _textColor),
              ),
            ],
          ),
        ),
        if (logoImage != null)
          pw.Container(
            width: 100,
            height: 100,
            alignment: pw.Alignment.topRight,
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),
      ],
    );
  }
}
