import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/purchase_order.dart';
import '../domain/manufacturer.dart';
import 'store_company_info.dart';

final purchaseOrderPdfServiceProvider = Provider<PurchaseOrderPdfService>((
  ref,
) {
  return PurchaseOrderPdfService();
});

class PurchaseOrderPdfService {
  PurchaseOrderPdfService();

  static final Map<String, Uint8List> _pdfCache = {};

  /// Helper to clean text for PDF generation
  static String _cleanText(String? text) {
    if (text == null) return '';
    // Replace rupee symbol with Rs
    var cleaned = text.replaceAll('₹', 'Rs ');
    // Remove any other non-ASCII characters that might cause issues with the font
    // Keep basic ASCII printable characters (space to tilde)
    cleaned = cleaned.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    return cleaned;
  }

  Future<Uint8List> generatePurchaseOrderPdf({
    required PurchaseOrder purchaseOrder,
    required Manufacturer? manufacturer,
  }) async {
    final cacheKey =
        '${purchaseOrder.id}_${purchaseOrder.updatedAt.millisecondsSinceEpoch}';
    if (_pdfCache.containsKey(cacheKey)) {
      return _pdfCache[cacheKey]!;
    }

    final pdf = pw.Document();

    // Load font
    final font = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final boldFont = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    final ttf = pw.Font.ttf(font);
    final boldTtf = pw.Font.ttf(boldFont);

    // Load logo
    final logoBytes = await rootBundle.load('assets/picklemart.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(
        symbol: 'Rs ',
        decimalDigits: 2,
        locale: 'en_IN',
      );

    // Company Info
    final companyInfo = StoreCompanyInfo.toMap();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(logoImage, width: 80),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      companyInfo['name'],
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(companyInfo['address']),
                    pw.Text(
                      '${companyInfo['city']}, ${companyInfo['state']} - ${companyInfo['pincode']}',
                    ),
                    pw.Text('Phone: ${companyInfo['phone']}'),
                    if (companyInfo['gst'] != null)
                      pw.Text('GSTIN: ${companyInfo['gst']}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'PURCHASE ORDER',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'PO Number: ${purchaseOrder.purchaseNumber}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Date: ${dateFormat.format(purchaseOrder.purchaseDate)}',
                    ),
                    if (purchaseOrder.expectedDeliveryDate != null)
                      pw.Text(
                        'Expected Delivery: ${dateFormat.format(purchaseOrder.expectedDeliveryDate!)}',
                      ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Status: ${purchaseOrder.status.name.toUpperCase()}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: _getStatusColor(purchaseOrder.status),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Manufacturer Info
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                color: PdfColors.grey50,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MANUFACTURER',
                          style: pw.TextStyle(
                            color: PdfColors.grey600,
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (manufacturer != null) ...[
                          pw.Text(
                            manufacturer.businessName,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(manufacturer.name),
                          if (manufacturer.businessAddress.isNotEmpty)
                            pw.Text(manufacturer.businessAddress),
                          pw.Text(
                            '${manufacturer.city}, ${manufacturer.state}',
                          ),
                          pw.Text('Phone: ${manufacturer.phone}'),
                          if (manufacturer.gstNumber.isNotEmpty)
                            pw.Text('GSTIN: ${manufacturer.gstNumber}'),
                        ] else ...[
                          pw.Text(
                            'Unknown Manufacturer',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Item
                1: const pw.FlexColumnWidth(1), // Qty
                2: const pw.FlexColumnWidth(1.5), // Unit Price
                3: const pw.FlexColumnWidth(1.5), // Total
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('Item Description', isHeader: true),
                    _buildTableCell(
                      'Qty',
                      isHeader: true,
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      'Unit Price',
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _buildTableCell(
                      'Total',
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                // Items
                ...purchaseOrder.items.map(
                  (item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.name,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Quantity : ${item.quantity}${item.measurementUnit != null && item.measurementUnit!.isNotEmpty ? 'X${item.measurementUnit}' : ''}',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTableCell(
                        '${item.quantity}${item.measurementUnit != null && item.measurementUnit!.isNotEmpty ? 'X${item.measurementUnit}' : ''}',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        currencyFormat.format(item.unitPrice),
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        currencyFormat.format(item.totalPrice),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    children: [
                      _buildTotalRow(
                        'Subtotal',
                        currencyFormat.format(purchaseOrder.subtotal),
                      ),
                      if (purchaseOrder.tax > 0)
                        _buildTotalRow(
                          'Tax',
                          currencyFormat.format(purchaseOrder.tax),
                        ),
                      if (purchaseOrder.shipping > 0)
                        _buildTotalRow(
                          'Shipping',
                          currencyFormat.format(purchaseOrder.shipping),
                        ),
                      pw.Divider(),
                      _buildTotalRow(
                        'Total',
                        currencyFormat.format(purchaseOrder.total),
                        isBold: true,
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Notes
            if (purchaseOrder.notes != null &&
                purchaseOrder.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Text(
                'Notes:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(purchaseOrder.notes!),
            ],

            // Footer
            pw.Spacer(),
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                'This is a computer generated document.',
                style: const pw.TextStyle(
                  color: PdfColors.grey500,
                  fontSize: 10,
                ),
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    _pdfCache[cacheKey] = bytes;
    if (_pdfCache.length > 20) {
      _pdfCache.remove(_pdfCache.keys.first);
    }
    return bytes;
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 10,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  PdfColor _getStatusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.pending:
        return PdfColors.orange;
      case PurchaseOrderStatus.confirmed:
        return PdfColors.blue;
      case PurchaseOrderStatus.received:
        return PdfColors.green;
      case PurchaseOrderStatus.cancelled:
        return PdfColors.red;
      default:
        return PdfColors.black;
    }
  }
}
