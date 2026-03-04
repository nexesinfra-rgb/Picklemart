import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'payment_receipt_repository.dart';
import 'store_company_info.dart';
import '../../../core/utils/number_to_words.dart';
import '../../../core/utils/customer_code_generator.dart';
import '../../orders/data/order_model.dart' as order_model;
import '../../orders/data/order_repository_provider.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/product_repository.dart';

/// Precomputed data for PDF generation to improve performance
class _PrecomputedReceiptData {
  final String customerCode;
  final String amountInWords;
  final Map<String, List<order_model.OrderItem>> groupedItems;
  final List<String> sortedCategories;
  final Map<String, dynamic> companyInfo;

  /// Balance due before this payment (shown as "Old Due" when present)
  final double? oldDue;

  /// Balance due after this payment
  final double? balanceDue;

  _PrecomputedReceiptData({
    required this.customerCode,
    required this.amountInWords,
    required this.groupedItems,
    required this.sortedCategories,
    required this.companyInfo,
    this.oldDue,
    this.balanceDue,
  });
}

/// Service for generating PDF payment receipts
class PaymentReceiptPdfService {
  final WidgetRef _ref;

  PaymentReceiptPdfService(this._ref);

  // Static colors from BillPdfService
  static PdfColor _colorFromFlutter(int colorInt) {
    return PdfColor.fromInt(colorInt | 0xFF000000);
  }

  static PdfColor get _borderColorStatic => _colorFromFlutter(0xFFE5E7EB);
  static PdfColor get _textColorStatic => PdfColors.black;
  static PdfColor get _categoryBgColorStatic => _colorFromFlutter(0xFFF3F4F6);
  static PdfColor get _orangeColorStatic => PdfColor.fromInt(0xFFFFA726);

  /// Helper to clean text for PDF generation
  /// Replaces ₹ with Rs and removes other non-ASCII characters
  /// This prevents "Helvetica has no Unicode support" errors
  static String _cleanText(String? text) {
    if (text == null) return '';
    // Replace Rupee symbol with Rs
    var cleaned = text.replaceAll('₹', 'Rs ');
    // Remove any other non-ASCII characters (keep only printable ASCII 32-126)
    cleaned = cleaned.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    return cleaned;
  }

  /// Generate PDF bytes for a payment receipt
  Future<Uint8List> getPaymentReceiptPdfBytes(PaymentReceipt receipt) async {
    try {
      if (kDebugMode) {
        print('Generating PDF for payment receipt: ${receipt.receiptNumber}');
      }

      // Fetch order if orderId is present
      order_model.Order? order;
      Map<String, Product> productsMap = {};

      if (receipt.orderId != null) {
        order = await _ref
            .read(orderRepositoryProvider)
            .getOrderById(receipt.orderId!);

        // Fetch products to get categories
        if (order != null) {
          try {
            final productRepository = _ref.read(productRepositoryProvider);
            for (final item in order.items) {
              if (!productsMap.containsKey(item.id)) {
                final product = await productRepository.fetchById(item.id);
                if (product != null) {
                  productsMap[item.id] = product;
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching products for receipt: $e');
            }
          }
        }
      }

      // Compute old due and balance when receipt is linked to an order
      double? oldDue;
      double? balanceDue;
      if (receipt.orderId != null && order != null) {
        final paymentRepo = _ref.read(paymentReceiptRepositoryProvider);
        final totalPaid = await paymentRepo.getTotalPaidForOrder(
          receipt.orderId!,
        );
        oldDue = (order.total - (totalPaid - receipt.amount)).clamp(
          0.0,
          double.infinity,
        );
        balanceDue = (order.total - totalPaid).clamp(0.0, double.infinity);
      }

      // Pre-compute data
      final precomputed = _precomputeReceiptData(
        receipt,
        order,
        productsMap,
        oldDue: oldDue,
        balanceDue: balanceDue,
      );

      // Generate the PDF using our custom method
      final pdfBytes = await _generatePaymentReceiptPdf(
        receipt,
        order,
        precomputed,
      );

      if (kDebugMode) {
        print('PDF generated successfully, size: ${pdfBytes.length} bytes');
      }

      return pdfBytes;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating payment receipt PDF: $e');
      }
      rethrow;
    }
  }

  _PrecomputedReceiptData _precomputeReceiptData(
    PaymentReceipt receipt,
    order_model.Order? order,
    Map<String, Product> productsMap, {
    double? oldDue,
    double? balanceDue,
  }) {
    try {
      final companyInfo = StoreCompanyInfo.toMap();

      // Pre-compute customer code
      final customerCode = CustomerCodeGenerator.generate(
        customerName: receipt.customerName ?? '',
        customerId: receipt.customerId,
        city: order?.deliveryAddress.city ?? '',
        state: order?.deliveryAddress.state ?? '',
      );

      // Pre-compute number to words conversion
      final amountInWords = NumberToWords.convert(receipt.amount);

      // Pre-compute grouped items by category if order exists
      final Map<String, List<order_model.OrderItem>> groupedItems = {};
      if (order != null) {
        for (final item in order.items) {
          String category = 'Uncategorized';
          if (productsMap.containsKey(item.id)) {
            final product = productsMap[item.id]!;
            if (product.categories.isNotEmpty) {
              category = product.categories.first;
            }
          }
          groupedItems.putIfAbsent(category, () => []).add(item);
        }
      }

      // Pre-compute sorted categories
      final sortedCategories =
          groupedItems.keys.toList()..sort((a, b) {
            final priorityA = _getCategoryPriority(a);
            final priorityB = _getCategoryPriority(b);
            if (priorityA != priorityB) {
              return priorityA.compareTo(priorityB);
            }
            return a.compareTo(b);
          });

      return _PrecomputedReceiptData(
        customerCode: customerCode,
        amountInWords: amountInWords,
        groupedItems: groupedItems,
        sortedCategories: sortedCategories,
        companyInfo: companyInfo,
        oldDue: oldDue,
        balanceDue: balanceDue,
      );
    } catch (e) {
      return _PrecomputedReceiptData(
        customerCode: 'N/A',
        amountInWords: 'Zero Rupees only',
        groupedItems: {},
        sortedCategories: [],
        companyInfo: StoreCompanyInfo.toMap(),
        oldDue: oldDue,
        balanceDue: balanceDue,
      );
    }
  }

  static int _getCategoryPriority(String categoryName) {
    final normalized = categoryName.trim().toUpperCase();

    // App standard priority order:
    // 1. NON-VEG PICKLES
    // 2. VEG PICKLES
    // 3. KARAPODULU
    // 4. VADIYALU
    // 5. SWEET AND SNACKS
    // 6. SPECIAL ITEMS

    // 1. Non-Veg Pickles
    if (normalized.contains('NON') &&
        normalized.contains('VEG') &&
        normalized.contains('PICKLE')) {
      return 1;
    }

    // 2. Veg Pickles
    if (normalized.contains('VEG') &&
        normalized.contains('PICKLE') &&
        !normalized.contains('NON')) {
      return 2;
    }

    // 3. Karapodhulu
    if (normalized.contains('KARAPOD') || normalized.contains('KARAPPOD')) {
      return 3;
    }

    // 4. Vadiyalu
    if (normalized.contains('VADIYALU')) {
      return 4;
    }

    // 5. Sweet and Snacks
    if (normalized.contains('SWEET') || normalized.contains('SNACK')) {
      return 5;
    }

    // 6. Special Items
    if (normalized.contains('SPECIAL')) {
      return 6;
    }

    return 999; // Others
  }

  /// Generate payment receipt PDF
  Future<Uint8List> _generatePaymentReceiptPdf(
    PaymentReceipt receipt,
    order_model.Order? order,
    _PrecomputedReceiptData precomputed,
  ) async {
    final pdf = pw.Document();

    // Load logo from assets
    Uint8List? logoBytes;
    try {
      logoBytes = await _loadLogoBytesFromAssets();
    } catch (e) {}

    pw.MemoryImage? logoImage;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoImage = pw.MemoryImage(logoBytes);
    }

    // Build the PDF (client layout: header, received from / receipt details, amount & payment, signature, footer)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            _buildPdfHeader(receipt, logoImage, precomputed, order),
            pw.SizedBox(height: 16),
            _buildPdfPaymentDetails(receipt, precomputed),
            pw.SizedBox(height: 24),
            _buildPdfFooter(precomputed.companyInfo),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Build PDF Header: Company info, orange "Payment Receipt" band, Received From | Receipt Details (client layout)
  pw.Widget _buildPdfHeader(
    PaymentReceipt receipt,
    pw.MemoryImage? logoImage,
    _PrecomputedReceiptData precomputed,
    order_model.Order? order,
  ) {
    final fssai =
        precomputed.companyInfo['fssai_no'] ??
        precomputed.companyInfo['fssaiNo'];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Header with logo
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _cleanText(
                      precomputed.companyInfo['name'] ?? 'PICKLE MART',
                    ),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _cleanText(precomputed.companyInfo['address'] ?? ''),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _cleanText(
                      'Phone no: ${precomputed.companyInfo['phone'] ?? ""}',
                    ),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _cleanText(
                      'Email: ${precomputed.companyInfo['email'] ?? "picklemarts@gmail.com"}',
                    ),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _cleanText(
                      'State: ${precomputed.companyInfo['state'] ?? "37-Andhra Pradesh"}',
                    ),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  if (fssai != null && fssai.toString().isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _cleanText('FSSAI NO: $fssai'),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ],
              ),
            ),
            if (logoImage != null)
              pw.Container(
                width: 80,
                height: 80,
                alignment: pw.Alignment.topRight,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 10),

        // Orange band with "Payment Receipt" in white (client design)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          decoration: pw.BoxDecoration(color: _orangeColorStatic),
          child: pw.Center(
            child: pw.Text(
              'Payment Receipt',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 12),

        // Received From (left) | Receipt Details (right)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderColorStatic, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Received From',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _cleanText(receipt.customerName ?? 'N/A'),
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _cleanText(
                        order != null
                            ? '${order.deliveryAddress.city.toUpperCase()}, ${order.deliveryAddress.state.toUpperCase()}'
                            : (receipt.customerPhone ?? '-'),
                      ),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _cleanText('(${precomputed.customerCode})'),
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderColorStatic, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Receipt Details',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Receipt No.: ${receipt.receiptNumber}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Date: ${receipt.paymentDate.day.toString().padLeft(2, '0')}-'
                      '${receipt.paymentDate.month.toString().padLeft(2, '0')}-'
                      '${receipt.paymentDate.year}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build Items Table with category grouping
  pw.Widget _buildItemsTable(
    order_model.Order order,
    _PrecomputedReceiptData precomputed,
  ) {
    final columnWidths = {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FlexColumnWidth(4),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1.5),
      5: const pw.FlexColumnWidth(1.5),
    };

    final rows = <pw.Widget>[];

    // Table Header
    rows.add(
      pw.Table(
        columnWidths: columnWidths,
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _orangeColorStatic),
            children: [
              _tableCell('#', color: PdfColors.white, isHeader: true),
              _tableCell(
                'Description of Goods',
                color: PdfColors.white,
                isHeader: true,
                align: pw.TextAlign.left,
              ),
              _tableCell('Quantity', color: PdfColors.white, isHeader: true),
              _tableCell('Unit', color: PdfColors.white, isHeader: true),
              _tableCell(
                'Rate',
                color: PdfColors.white,
                isHeader: true,
                align: pw.TextAlign.right,
              ),
              _tableCell(
                'Amount',
                color: PdfColors.white,
                isHeader: true,
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );

    // Grouped items
    int globalIndex = 1;
    for (final category in precomputed.sortedCategories) {
      // Category header row
      rows.add(
        pw.Table(
          columnWidths: columnWidths,
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Container(),
                _tableCell(
                  category.toUpperCase(),
                  isBold: true,
                  align: pw.TextAlign.left,
                ),
                pw.Container(),
                pw.Container(),
                pw.Container(),
                pw.Container(),
              ],
            ),
          ],
        ),
      );

      final items = precomputed.groupedItems[category]!;
      final itemRows = <pw.TableRow>[];
      for (final item in items) {
        itemRows.add(
          pw.TableRow(
            children: [
              _tableCell('${globalIndex++}'),
              _tableCell(item.name, align: pw.TextAlign.left),
              _tableCell('${item.quantity}'),
              _tableCell(item.size ?? '-'),
              _tableCell(
                'Rs ${item.price.toStringAsFixed(2)}',
                align: pw.TextAlign.right,
              ),
              _tableCell(
                'Rs ${item.totalPrice.toStringAsFixed(2)}',
                align: pw.TextAlign.right,
              ),
            ],
          ),
        );
      }
      rows.add(
        pw.Table(
          columnWidths: columnWidths,
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: itemRows,
        ),
      );
    }

    // Total row in table
    rows.add(
      pw.Table(
        columnWidths: columnWidths,
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(width: 0.5, color: PdfColors.black),
              ),
            ),
            children: [
              pw.Container(),
              _tableCell('Total', isBold: true, align: pw.TextAlign.left),
              _tableCell(
                order.items
                    .fold<int>(0, (sum, item) => sum + item.quantity)
                    .toString(),
                isBold: true,
              ),
              pw.Container(),
              pw.Container(),
              _tableCell(
                'Rs ${order.subtotal.toStringAsFixed(2)}',
                isBold: true,
                align: pw.TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );

    return pw.Column(children: rows);
  }

  static pw.Widget _tableCell(
    String text, {
    PdfColor color = PdfColors.black,
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        _cleanText(text),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight:
              (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: align,
      ),
    );
  }

  /// Build Footer: Totals and Amount in Words
  pw.Widget _buildFooterFinancials(
    PaymentReceipt receipt,
    order_model.Order order,
    _PrecomputedReceiptData precomputed,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Amount in words
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Order Amount In Words',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _cleanText('${precomputed.amountInWords} only'),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Terms And Conditions',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Thanks for doing business with us!',
                style: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        // Totals
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderColorStatic, width: 0.5),
            ),
            child: pw.Column(
              children: [
                _buildTotalRow('Sub Total', order.subtotal),
                _buildTotalRow('Shipping', order.shipping),
                _buildTotalRow('Total', order.total, isTotal: true),
                _buildTotalRow('Received', receipt.amount),
                _buildTotalRow('Balance Due', order.total - receipt.amount),
                _buildTotalRow(
                  'Payment Mode',
                  0,
                  valueOverride: receipt.paymentType.toUpperCase(),
                ),
                pw.SizedBox(height: 20),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    _cleanText(
                      'For ${precomputed.companyInfo['name'] ?? 'Pickle Mart'}',
                    ),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Authorized Signatory',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    double amount, {
    bool isTotal = false,
    String? valueOverride,
  }) {
    return pw.Container(
      color: isTotal ? _orangeColorStatic : null,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _cleanText(label),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.white : PdfColors.black,
            ),
          ),
          pw.Text(
            _cleanText(valueOverride ?? 'Rs ${amount.toStringAsFixed(2)}'),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.white : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Build PDF Payment Details: Amount in Words, Received, Payment Mode, Old Due, Balance, signature (client layout)
  pw.Widget _buildPdfPaymentDetails(
    PaymentReceipt receipt,
    _PrecomputedReceiptData precomputed,
  ) {
    // Amount in words already includes " only" from NumberToWords.convert
    final amountInWordsText = precomputed.amountInWords;
    final amountStr = receipt.amount.toStringAsFixed(2);
    final parts = amountStr.split('.');
    final intPart = parts.first;
    final decPart = parts.length > 1 ? parts.last : '00';
    final withCommas = intPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    final receivedFormatted = 'Rs $withCommas.$decPart';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: _borderColorStatic),
        pw.SizedBox(height: 12),
        // Amount in Words (left) | Received + Payment Mode (right)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 6,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Amount in Words',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _cleanText(amountInWordsText),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Received',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _cleanText(receivedFormatted),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Payment Mode',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _cleanText(receipt.paymentType.toUpperCase()),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Old Due and Balance Due when available
        if (precomputed.oldDue != null || precomputed.balanceDue != null) ...[
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderColorStatic, width: 0.5),
            ),
            child: pw.Column(
              children: [
                if (precomputed.oldDue != null)
                  _buildDetailRow(
                    'Old Due',
                    'Rs ${precomputed.oldDue!.toStringAsFixed(2)}',
                  ),
                if (precomputed.balanceDue != null)
                  _buildDetailRow(
                    'Balance Due',
                    'Rs ${precomputed.balanceDue!.toStringAsFixed(2)}',
                  ),
              ],
            ),
          ),
        ],
        pw.SizedBox(height: 28),
        // Signature: For PICKLE MART, Authorized Signatory (client layout)
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                _cleanText(
                  'For: ${precomputed.companyInfo['name'] ?? 'PICKLE MART'}',
                ),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Container(width: 120, height: 1, color: _textColorStatic),
              pw.SizedBox(height: 4),
              pw.Text(
                'Authorized Signatory',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _cleanText(label),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(_cleanText(value), style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  /// Build PDF Footer
  pw.Widget _buildPdfFooter(Map<String, dynamic> companyInfo) {
    return pw.Column(
      children: [
        pw.Divider(color: _borderColorStatic),
        pw.SizedBox(height: 12),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _cleanText(
            '${companyInfo['name'] ?? "Pickle Mart"} | Phone: ${companyInfo['phone'] ?? "N/A"}',
          ),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'This is a computer-generated receipt.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  /// Load logo bytes from assets
  Future<Uint8List?> _loadLogoBytesFromAssets() async {
    try {
      final byteData = await rootBundle.load('assets/admin_navbar_logo.png');
      return byteData.buffer.asUint8List();
    } catch (e) {
      try {
        final byteData = await rootBundle.load('assets/picklemart.png');
        return byteData.buffer.asUint8List();
      } catch (e2) {
        return null;
      }
    }
  }

  /// Generate share message for payment receipt
  String generateShareMessage(PaymentReceipt receipt) {
    return 'Payment Receipt\n'
        'Receipt #: ${receipt.receiptNumber}\n'
        'Date: ${receipt.paymentDate.day}/${receipt.paymentDate.month}/${receipt.paymentDate.year}\n'
        'Amount: Rs ${receipt.amount.toStringAsFixed(2)}\n'
        'Customer: ${receipt.customerName ?? "N/A"}\n'
        'Payment Type: ${receipt.paymentType.toUpperCase()}';
  }
}
