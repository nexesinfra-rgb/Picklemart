import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/purchase_order.dart';
import '../domain/manufacturer.dart';
import '../data/store_company_info.dart';
import '../../../core/utils/number_to_words.dart';

/// Serializable data for PDF generation in isolate
class _PurchaseOrderPdfData {
  final Map<String, dynamic> purchaseOrderJson;
  final Map<String, dynamic>? manufacturerJson;
  final Uint8List? logoBytes;
  final String amountInWords;
  final Map<String, List<Map<String, dynamic>>> groupedItems;
  final List<String> sortedCategories;
  final bool hasMultipleCategories;

  _PurchaseOrderPdfData({
    required this.purchaseOrderJson,
    this.manufacturerJson,
    this.logoBytes,
    required this.amountInWords,
    required this.groupedItems,
    required this.sortedCategories,
    required this.hasMultipleCategories,
  });
}

class PurchaseOrderPdfService {
  // Color scheme matching BillPdfService
  static PdfColor _colorFromFlutter(int colorInt) {
    return PdfColor.fromInt(colorInt | 0xFF000000);
  }

  static PdfColor get _borderColor => _colorFromFlutter(0xFFE5E7EB);
  static PdfColor get _textColor => PdfColors.black;
  static PdfColor get _orangeColor => PdfColor.fromInt(0xFFFFA726);

  // Static cache for logo
  static Uint8List? _cachedLogoBytes;
  static pw.MemoryImage? _cachedLogoImage;

  // Cache for generated PDFs to speed up repeated shares/prints
  static final Map<String, Uint8List> _pdfCache = {};

  /// Clears the PDF cache. If [purchaseOrderId] is provided, only that order's cache is cleared.
  static void clearCache({String? purchaseOrderId}) {
    if (purchaseOrderId == null) {
      _pdfCache.clear();
    } else {
      _pdfCache.removeWhere((key, value) => key.startsWith(purchaseOrderId));
    }
  }

  /// Preloads the logo so the first share/print does not wait on asset load.
  static Future<void> preloadLogo() async {
    await _loadLogo();
  }

  static Future<void> _loadLogo() async {
    if (_cachedLogoImage != null) return;

    try {
      final ByteData data = await rootBundle.load('assets/picklemart.png');
      final Uint8List bytes = data.buffer.asUint8List();
      _cachedLogoBytes = bytes;
      _cachedLogoImage = pw.MemoryImage(bytes);
    } catch (e) {
      if (kDebugMode) print('Error loading logo: $e');
    }
  }

  static Future<Uint8List> generatePurchaseOrderPdf(
    PurchaseOrder purchaseOrder,
    Manufacturer? manufacturer,
  ) async {
    // Return from cache if available and order hasn't changed
    final cacheKey =
        '${purchaseOrder.id}_${purchaseOrder.updatedAt.millisecondsSinceEpoch}';
    if (_pdfCache.containsKey(cacheKey)) {
      return _pdfCache[cacheKey]!;
    }

    await _loadLogo();

    Map<String, dynamic>? manufacturerJson;
    if (manufacturer != null) {
      manufacturerJson = {
        'id': manufacturer.id,
        'name': manufacturer.name,
        'gst_number': manufacturer.gstNumber,
        'business_name': manufacturer.businessName,
        'business_address': manufacturer.businessAddress,
        'city': manufacturer.city,
        'state': manufacturer.state,
        'pincode': manufacturer.pincode,
        'email': manufacturer.email,
        'phone': manufacturer.phone,
        'is_active': manufacturer.isActive,
        'created_at': manufacturer.createdAt?.toIso8601String(),
        'updated_at': manufacturer.updatedAt?.toIso8601String(),
      };
    }

    // Pre-calculate expensive operations outside isolate
    final amountInWords = NumberToWords.convert(purchaseOrder.total);

    // Group items by category
    final groupedItemsRaw = <String, List<PurchaseOrderItem>>{};
    for (var item in purchaseOrder.items) {
      final category = item.category ?? 'Uncategorized';
      if (!groupedItemsRaw.containsKey(category)) {
        groupedItemsRaw[category] = [];
      }
      groupedItemsRaw[category]!.add(item);
    }

    // Sort categories based on app priority standards
    final sortedCategories =
        groupedItemsRaw.keys.toList()..sort((a, b) {
          final priorityA = _getCategoryPriority(a);
          final priorityB = _getCategoryPriority(b);
          if (priorityA != priorityB) {
            return priorityA.compareTo(priorityB);
          }
          return a.compareTo(b);
        });

    final hasMultipleCategories =
        groupedItemsRaw.length > 1 ||
        (groupedItemsRaw.isNotEmpty &&
            groupedItemsRaw.keys.first != 'Uncategorized' &&
            groupedItemsRaw.keys.first.isNotEmpty);

    // Convert grouped items to JSON for isolate safety
    final Map<String, List<Map<String, dynamic>>> groupedItemsJson = {};
    groupedItemsRaw.forEach((key, value) {
      groupedItemsJson[key] = value.map((item) => item.toJson()).toList();
    });

    final data = _PurchaseOrderPdfData(
      purchaseOrderJson: purchaseOrder.toJson(),
      manufacturerJson: manufacturerJson,
      logoBytes: _cachedLogoBytes,
      amountInWords: amountInWords,
      groupedItems: groupedItemsJson,
      sortedCategories: sortedCategories,
      hasMultipleCategories: hasMultipleCategories,
    );

    final pdfBytes = await compute(_generatePdfInIsolate, data);

    // Cache the result
    _pdfCache[cacheKey] = pdfBytes;

    // Limit cache size to prevent memory issues (last 10 unique PDFs)
    if (_pdfCache.length > 10) {
      _pdfCache.remove(_pdfCache.keys.first);
    }

    return pdfBytes;
  }

  static Future<Uint8List> _generatePdfInIsolate(
    _PurchaseOrderPdfData data,
  ) async {
    if (data.logoBytes != null) {
      _cachedLogoBytes = data.logoBytes;
      _cachedLogoImage = pw.MemoryImage(data.logoBytes!);
    }

    final purchaseOrder = PurchaseOrder.fromJson(data.purchaseOrderJson);
    final manufacturer =
        data.manufacturerJson != null
            ? Manufacturer.fromSupabaseJson(data.manufacturerJson!)
            : null;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            _buildHeader(purchaseOrder, manufacturer),
            pw.SizedBox(height: 16),
            _buildItemsTable(purchaseOrder, data),
            pw.SizedBox(height: 20),
            _buildFooter(purchaseOrder, data.amountInWords),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    PurchaseOrder purchaseOrder,
    Manufacturer? manufacturer,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildCompanyHeader(),
        pw.SizedBox(height: 12),
        pw.Center(
          child: pw.Text(
            'PURCHASE ORDER',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _orangeColor,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildBillToSection(manufacturer)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: _buildShipToSection(purchaseOrder)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: _buildTransportationDetails(purchaseOrder)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: _buildOrderDetails(purchaseOrder)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCompanyHeader() {
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
        if (_cachedLogoImage != null)
          pw.Container(
            width: 100,
            height: 100,
            alignment: pw.Alignment.topRight,
            child: pw.Image(_cachedLogoImage!, fit: pw.BoxFit.contain),
          ),
      ],
    );
  }

  static pw.Widget _buildBillToSection(Manufacturer? manufacturer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bill To:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
          pw.SizedBox(height: 4),
          if (manufacturer != null) ...[
            pw.Text(
              manufacturer.businessName,
              style: pw.TextStyle(fontSize: 9, color: _textColor),
            ),
            pw.Text(
              '${manufacturer.city ?? ''}-${manufacturer.state ?? ''}',
              style: pw.TextStyle(fontSize: 9, color: _textColor),
            ),
          ] else
            pw.Text(
              'Unknown Manufacturer',
              style: pw.TextStyle(fontSize: 9, color: _textColor),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildShipToSection(PurchaseOrder purchaseOrder) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Ship To:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            StoreCompanyInfo.name,
            style: pw.TextStyle(fontSize: 9, color: _textColor),
          ),
          pw.Text(
            StoreCompanyInfo.address,
            style: pw.TextStyle(fontSize: 8, color: _textColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransportationDetails(PurchaseOrder purchaseOrder) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Transportation Details',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Delivery Location:',
            style: pw.TextStyle(fontSize: 8, color: _textColor),
          ),
          pw.Text(
            purchaseOrder.deliveryLocation ?? '-',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
          pw.Text(
            'NAME: ${purchaseOrder.transportationName ?? '-'}',
            style: pw.TextStyle(fontSize: 8, color: _textColor),
          ),
          pw.Text(
            'PHONE: ${purchaseOrder.transportationPhone ?? '-'}',
            style: pw.TextStyle(fontSize: 8, color: _textColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOrderDetails(PurchaseOrder purchaseOrder) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Order Details:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'PO No.: ${purchaseOrder.purchaseNumber}',
            style: pw.TextStyle(fontSize: 9, color: _textColor),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Date: ${DateFormat('dd-MM-yy').format(purchaseOrder.purchaseDate)}',
            style: pw.TextStyle(fontSize: 9, color: _textColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    PurchaseOrder purchaseOrder,
    _PurchaseOrderPdfData data,
  ) {
    final columnWidths = {
      0: const pw.FixedColumnWidth(30),
      1: const pw.FlexColumnWidth(4),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1.5),
      5: const pw.FlexColumnWidth(1.5),
    };

    final rows = <pw.TableRow>[];

    // Header
    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _orangeColor),
        children: [
          _buildTableCell('#', PdfColors.white, isHeader: true),
          _buildTableCell('Item name', PdfColors.white, isHeader: true),
          _buildTableCell('Quantity', PdfColors.white, isHeader: true),
          _buildTableCell('Unit', PdfColors.white, isHeader: true),
          _buildTableCell('Price/ Unit', PdfColors.white, isHeader: true),
          _buildTableCell('Amount', PdfColors.white, isHeader: true),
        ],
      ),
    );

    var globalIndex = 1;

    // Items grouped by category
    for (var category in data.sortedCategories) {
      final itemsJson = data.groupedItems[category]!;
      // Category Header Row - only if we have meaningful categories
      if (data.hasMultipleCategories) {
        rows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Container(),
              _buildTableCell(category.toUpperCase(), _textColor, isBold: true),
              pw.Container(),
              pw.Container(),
              pw.Container(),
              pw.Container(),
            ],
          ),
        );
      }

      for (var itemJson in itemsJson) {
        final item = PurchaseOrderItem.fromJson(itemJson);
        rows.add(
          pw.TableRow(
            children: [
              _buildTableCell(globalIndex.toString(), _textColor),
              _buildTableCell(item.name, _textColor),
              _buildTableCell(
                item.quantity.toString(),
                _textColor,
                align: pw.Alignment.center,
              ),
              _buildTableCell(
                item.measurementUnit ?? '-',
                _textColor,
                align: pw.Alignment.center,
              ),
              _buildTableCell(
                'Rs ${item.unitPrice.toStringAsFixed(2)}',
                _textColor,
                align: pw.Alignment.centerRight,
              ),
              _buildTableCell(
                'Rs ${item.totalPrice.toStringAsFixed(2)}',
                _textColor,
                align: pw.Alignment.centerRight,
              ),
            ],
          ),
        );
        globalIndex++;
      }
    }

    // Total row in table
    rows.add(
      pw.TableRow(
        children: [
          pw.Container(),
          _buildTableCell('Total', _textColor, isBold: true),
          _buildTableCell(
            purchaseOrder.items
                .fold<int>(0, (sum, item) => sum + item.quantity)
                .toString(),
            _textColor,
            isBold: true,
            align: pw.Alignment.center,
          ),
          pw.Container(),
          pw.Container(),
          _buildTableCell(
            'Rs ${purchaseOrder.subtotal.toStringAsFixed(2)}',
            _textColor,
            isBold: true,
            align: pw.Alignment.centerRight,
          ),
        ],
      ),
    );

    return pw.Table(
      columnWidths: columnWidths,
      border: pw.TableBorder.all(color: _borderColor, width: 0.5),
      children: rows,
    );
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

  static pw.Widget _buildTableCell(
    String text,
    PdfColor color, {
    bool isHeader = false,
    bool isBold = false,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight:
              (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(
    PurchaseOrder purchaseOrder,
    String amountInWords,
  ) {
    final currentBalance = purchaseOrder.total - purchaseOrder.paidAmount;
    final paymentMode = currentBalance > 0 ? 'Credit' : 'Cash';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
                  color: _textColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                amountInWords,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Terms And Conditions',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                purchaseOrder.notes ?? 'Thanks for doing business with us!',
                style: pw.TextStyle(fontSize: 9, color: _textColor),
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
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderColor, width: 0.5),
                ),
                child: pw.Column(
                  children: [
                    _buildFinancialRow('Sub Total', purchaseOrder.subtotal),
                    if (purchaseOrder.tax > 0)
                      _buildFinancialRow('Tax', purchaseOrder.tax),
                    _buildFinancialRow('Shipping', purchaseOrder.shipping),
                    pw.Container(
                      color: _orangeColor,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            'Rs ${purchaseOrder.total.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildFinancialRow('Received', purchaseOrder.paidAmount),
                    _buildFinancialRow(
                      'Balance Due',
                      currentBalance,
                      isBold: true,
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Payment Mode',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: _textColor,
                            ),
                          ),
                          pw.Text(
                            paymentMode,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'For: ${StoreCompanyInfo.name}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Authorized Signatory',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFinancialRow(
    String label,
    double amount, {
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: _textColor,
            ),
          ),
          pw.Text(
            'Rs ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printPurchaseOrder(
    PurchaseOrder purchaseOrder,
    Manufacturer? manufacturer,
  ) async {
    final pdfBytes = await generatePurchaseOrderPdf(
      purchaseOrder,
      manufacturer,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'PO_${purchaseOrder.purchaseNumber}',
    );
  }

  static Future<void> sharePurchaseOrder(
    PurchaseOrder purchaseOrder,
    Manufacturer? manufacturer,
  ) async {
    final pdfBytes = await generatePurchaseOrderPdf(
      purchaseOrder,
      manufacturer,
    );
    final fileName = 'PO_${purchaseOrder.purchaseNumber}.pdf';

    final xFile = XFile.fromData(
      pdfBytes,
      name: fileName,
      mimeType: 'application/pdf',
    );

    final buffer = StringBuffer();
    buffer.writeln('Purchase Order: ${purchaseOrder.purchaseNumber}');
    buffer.writeln(
      'Date: ${DateFormat('dd-MM-yy').format(purchaseOrder.purchaseDate)}',
    );
    buffer.writeln('Total Amount: ₹${purchaseOrder.total.toStringAsFixed(2)}');

    if (purchaseOrder.items.isNotEmpty) {
      buffer.writeln('Items:');
      // Only show first 5 items in text to keep it concise, others in PDF
      final displayItems = purchaseOrder.items.take(5).toList();
      for (var item in displayItems) {
        buffer.writeln('- ${item.name} x ${item.quantity}');
      }
      if (purchaseOrder.items.length > 5) {
        buffer.writeln(
          '- ... and ${purchaseOrder.items.length - 5} more items',
        );
      }
    }

    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
