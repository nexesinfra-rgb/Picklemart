import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'bill_model.dart';
import 'bill_repository_supabase.dart';
import 'store_company_info.dart';
import '../../../core/utils/number_to_words.dart';
import '../../../core/utils/customer_code_generator.dart';
import '../../orders/data/order_model.dart' as order_model;

/// Precomputed data for PDF generation to improve performance
class _PrecomputedBillData {
  final String customerCode;
  final String amountInWords;
  final Map<String, List<BillItem>> groupedItems;
  final List<String> sortedCategories;
  final Map<String, dynamic> companyInfo;

  _PrecomputedBillData({
    required this.customerCode,
    required this.amountInWords,
    required this.groupedItems,
    required this.sortedCategories,
    required this.companyInfo,
  });
}

/// Serializable data for PDF generation in isolate
/* class _PdfGenerationData {
  final Map<String, dynamic> billJson;
  final Uint8List? logoBytes;
  final double? receivedAmountOverride;
  final Map<String, dynamic> precomputedData;

  _PdfGenerationData({
    required this.billJson,
    this.logoBytes,
    this.receivedAmountOverride,
    required this.precomputedData,
  });

  Map<String, dynamic> toJson() {
    return {
      'bill_json': billJson,
      'logo_bytes': logoBytes,
      'received_amount_override': receivedAmountOverride,
      'precomputed_data': precomputedData,
    };
  }

  factory _PdfGenerationData.fromJson(Map<String, dynamic> json) {
    return _PdfGenerationData(
      billJson: json['bill_json'] as Map<String, dynamic>,
      logoBytes: json['logo_bytes'] as Uint8List?,
      receivedAmountOverride: json['received_amount_override'] as double?,
      precomputedData: json['precomputed_data'] as Map<String, dynamic>,
    );
  }
} */

/// Service for generating PDF bills in the invoice format
class BillPdfService {
  // final BillRepositorySupabase _billRepository; // Removed unused field

  BillPdfService(
    BillRepositorySupabase billRepository,
  ); // Changed constructor to avoid unused field warning

  // Static cache for logo image to avoid reloading/decoding on every PDF generation
  // static pw.MemoryImage? _cachedLogoImage; // Removed unused variable
  static Uint8List? _cachedLogoBytes;
  static bool _logoLoading = false;

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

  // Helper method to convert Flutter Color to PDF Color
  static PdfColor _colorFromFlutter(int colorInt) {
    // Remove alpha channel for PDF (use full opacity)
    return PdfColor.fromInt(colorInt | 0xFF000000);
  }

  // Color scheme using AppColors design tokens
  /* static PdfColor get _primaryColor =>
      _colorFromFlutter(0xFFFBC801); // AppColors.primary (Yellow)
  static PdfColor get _borderColor =>
      _colorFromFlutter(0xFFE5E7EB); // AppColors.outlineSoft
  static PdfColor get _textColor => PdfColors.black; // AppColors.textPrimary
  static PdfColor get _textSecondary =>
      _colorFromFlutter(0xFF6B7280); // AppColors.textSecondary
  static PdfColor get _categoryBgColor =>
      _colorFromFlutter(0xFFF3F4F6); // AppColors.thumbBg
  static PdfColor get _orangeColor =>
      PdfColor.fromInt(0xFFFFA726); // Orange for "Tax Invoice" title */

  // Static versions for isolate use
  /* static PdfColor get _primaryColorStatic => _colorFromFlutter(0xFFFBC801); */
  static PdfColor get _borderColorStatic => _colorFromFlutter(0xFFE5E7EB);
  static PdfColor get _textColorStatic => PdfColors.black;
  static PdfColor get _categoryBgColorStatic => _colorFromFlutter(0xFFF3F4F6);
  static PdfColor get _orangeColorStatic => PdfColor.fromInt(0xFFFFA726);

  // PO Style Matches
  static PdfColor get _poTitleColorStatic => PdfColors.blue800;
  static PdfColor get _poHeaderBgColorStatic => PdfColors.grey100;
  static PdfColor get _poTableBorderColorStatic => PdfColors.grey300;
  static PdfColor get _poBoxBgColorStatic => PdfColors.grey50;

  /// Generate PDF bill with two-page layout
  /// If receivedAmountOverride is provided, it will be used instead of bill.billData.receivedAmount
  /// If order is provided, bill amounts will be recalculated from current order data
  /// If recalculatedBillData is provided, it will be used instead of bill.billData
  /// Runs PDF generation in an isolate to prevent blocking the UI thread
  Future<Uint8List> generateBillPdf({
    required Bill bill,
    BillTemplate? template,
    double? receivedAmountOverride,
    order_model.Order? order,
    BillData? recalculatedBillData,
    Future<BillData> Function({
      required order_model.Order order,
      required BillType billType,
      double? shipping,
      double? oldDue,
      double? receivedAmount,
    })?
    calculateBillDataFromOrder,
  }) async {
    try {
      // Recalculate bill data from order if order is provided
      BillData billDataToUse;
      if (recalculatedBillData != null) {
        billDataToUse = recalculatedBillData;
        if (kDebugMode) {
          print('Using recalculated bill data for PDF generation');
        }
      } else if (order != null && calculateBillDataFromOrder != null) {
        // Recalculate from current order data
        if (kDebugMode) {
          print(
            'Recalculating bill data from current order for PDF generation',
          );
        }
        billDataToUse = await calculateBillDataFromOrder(
          order: order,
          billType: bill.billType,
          shipping: null, // Use order's shipping
          oldDue: bill.billData.oldDue,
          receivedAmount:
              receivedAmountOverride ?? bill.billData.receivedAmount,
        );
      } else {
        // Use stored bill data
        billDataToUse = bill.billData;
      }

      // Pre-compute expensive operations before PDF building (on main thread - fast)
      // Create a temporary bill with recalculated data for precomputation
      final tempBill = Bill(
        id: bill.id,
        billNumber: bill.billNumber,
        billType: bill.billType,
        orderId: bill.orderId,
        userId: bill.userId,
        billData: billDataToUse,
        pdfUrl: bill.pdfUrl,
        createdAt: bill.createdAt,
        updatedAt: bill.updatedAt,
      );
      final precomputed = _precomputeBillData(tempBill, receivedAmountOverride);

      // Load logo bytes from assets (cached) - on main thread
      Uint8List? logoBytes;
      try {
        logoBytes = await _loadLogoBytesFromAssets();
        // Limit logo size to prevent serialization issues (max 2MB)
        if (logoBytes != null && logoBytes.length > 2 * 1024 * 1024) {
          if (kDebugMode) {
            print(
              'Warning: Logo is too large (${logoBytes.length} bytes), skipping to prevent serialization issues',
            );
          }
          logoBytes = null;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Could not load logo: $e');
        }
      }

      // Prepare minimal serializable data for isolate (avoid full Bill serialization)
      // Only pass what's needed: bill number, date, and bill data fields
      final billData = billDataToUse;
      final minimalBillData = {
        'bill_number': bill.billNumber,
        'created_at': bill.createdAt.toIso8601String(),
        'subtotal': billData.subtotal,
        'tax': billData.tax,
        'shipping': billData.shipping,
        'total': billData.total,
        'old_due': billData.oldDue,
        'received_amount': billData.receivedAmount,
        'customer_info': billData.customerInfo,
      };

      // Prepare precomputed data for serialization
      final groupedItemsJson = <String, List<Map<String, dynamic>>>{};
      for (final entry in precomputed.groupedItems.entries) {
        groupedItemsJson[entry.key] =
            entry.value.map((item) => item.toJson()).toList();
      }

      final precomputedJson = {
        'customer_code': precomputed.customerCode,
        'amount_in_words': precomputed.amountInWords,
        'grouped_items': groupedItemsJson,
        'sorted_categories': precomputed.sortedCategories,
        'company_info': precomputed.companyInfo,
      };

      if (kDebugMode) {
        print(
          'Prepared precomputed data: ${precomputedJson.keys.length} keys, ${groupedItemsJson.length} categories',
        );
      }

      // Run PDF generation in isolate to prevent blocking
      if (kDebugMode) {
        print('Starting PDF generation in isolate...');
        print('Bill data items count: ${billData.items.length}');
        print('Logo bytes: ${logoBytes?.length ?? 0} bytes');
      }

      try {
        return await compute(BillPdfService.generatePdfInIsolate, {
          'minimal_bill_data': minimalBillData,
          'logo_bytes': logoBytes,
          'received_amount_override': receivedAmountOverride,
          'precomputed_data': precomputedJson,
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
              'PDF generation timed out. Please try again or contact support if the issue persists.',
            );
          },
        );
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('Error in compute() call: $e');
          print('Stack trace: $stackTrace');
        }
        // Re-throw with more context
        if (e.toString().contains('timeout')) {
          rethrow;
        }
        throw Exception('Failed to generate PDF in isolate: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating PDF: $e');
      }
      throw Exception('Failed to generate PDF: $e');
    }
  }

  /// Static function to generate PDF in isolate
  /// This function must be public static to work with compute()
  static Future<Uint8List> generatePdfInIsolate(
    Map<String, dynamic> data,
  ) async {
    try {
      if (kDebugMode) {
        print('PDF isolate started, processing data...');
      }

      final minimalBillData = data['minimal_bill_data'] as Map<String, dynamic>;
      final receivedAmountOverride =
          data['received_amount_override'] as double?;
      final precomputedJson = data['precomputed_data'] as Map<String, dynamic>;

      if (kDebugMode) {
        print('Extracted data from isolate input');
      }

      // Extract bill fields (avoid full Bill reconstruction)
      final billNumber = minimalBillData['bill_number'] as String;
      final createdAt = DateTime.parse(minimalBillData['created_at'] as String);

      // Reconstruct precomputed data (minimal reconstruction)
      final groupedItems = <String, List<BillItem>>{};
      final groupedItemsMap =
          precomputedJson['grouped_items'] as Map<String, dynamic>;
      for (final entry in groupedItemsMap.entries) {
        groupedItems[entry.key] =
            (entry.value as List)
                .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
                .toList();
      }

      final precomputed = _PrecomputedBillData(
        customerCode: precomputedJson['customer_code'] as String,
        amountInWords: precomputedJson['amount_in_words'] as String,
        groupedItems: groupedItems,
        sortedCategories: List<String>.from(
          precomputedJson['sorted_categories'] as List,
        ),
        companyInfo: Map<String, dynamic>.from(
          precomputedJson['company_info'] as Map,
        ),
      );

      // Create MemoryImage from logo bytes if available
      pw.MemoryImage? logoImage;
      final logoBytes = data['logo_bytes'] as Uint8List?;
      if (logoBytes != null) {
        logoImage = pw.MemoryImage(logoBytes);
      }

      // Extract bill data fields for PDF building
      final subtotal = (minimalBillData['subtotal'] as num).toDouble();
      // final tax = (minimalBillData['tax'] as num).toDouble(); // Removed unused variable
      final shipping = (minimalBillData['shipping'] as num).toDouble();
      final total = (minimalBillData['total'] as num).toDouble();
      final oldDue = (minimalBillData['old_due'] as num).toDouble();
      final receivedAmount =
          (minimalBillData['received_amount'] as num).toDouble();
      final customerInfo = Map<String, dynamic>.from(
        minimalBillData['customer_info'] as Map,
      );

      // Get all items from grouped items
      final allItems = <BillItem>[];
      for (final categoryItems in groupedItems.values) {
        allItems.addAll(categoryItems);
      }

      final pdf = pw.Document();

      // Use MultiPage for continuous layout
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              _buildHeaderStaticOptimized(
                billNumber: billNumber,
                createdAt: createdAt,
                customerInfo: customerInfo,
                logoImage: logoImage,
                precomputed: precomputed,
              ),
              pw.SizedBox(height: 16),
              _buildItemsTableStatic(
                allItems,
                precomputed.groupedItems,
                precomputed.sortedCategories,
              ),
              pw.SizedBox(height: 20),
              _buildFooterStaticOptimized(
                billNumber: billNumber,
                subtotal: subtotal,
                shipping: shipping,
                total: total,
                oldDue: oldDue,
                receivedAmount: receivedAmountOverride ?? receivedAmount,
                logoImage: logoImage,
                precomputed: precomputed,
              ),
            ];
          },
        ),
      );

      // This save() call runs in isolate, so it won't block the UI
      if (kDebugMode) {
        print('Saving PDF document...');
      }

      final pdfBytes = await pdf.save();

      if (kDebugMode) {
        print(
          'PDF generated successfully in isolate, size: ${pdfBytes.length} bytes',
        );
      }

      return pdfBytes;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in PDF isolate: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Failed to generate PDF in isolate: $e');
    }
  }

  /// Pre-compute expensive operations before PDF building
  /// Returns safe default values if precomputation fails to prevent PDF generation from hanging
  _PrecomputedBillData _precomputeBillData(
    Bill bill,
    double? receivedAmountOverride,
  ) {
    try {
      final billData = bill.billData;
      final companyInfo = billData.companyInfo ?? StoreCompanyInfo.toMap();

      // Pre-compute customer code
      final customerCode = CustomerCodeGenerator.generate(
        customerName: billData.customerInfo['name'] ?? '',
        city: billData.customerInfo['city'],
        state: billData.customerInfo['state'],
        customerId: billData.customerInfo['id'],
      );

      // Pre-compute number to words conversion
      final total = billData.total;
      // Amount in words should only reflect the current bill total, not old due
      final amountInWords = NumberToWords.convert(total);

      // Pre-compute grouped items by category
      final Map<String, List<BillItem>> groupedItems = {};
      final items = billData.items;
      if (items.isEmpty) {
        if (kDebugMode) {
          print('Warning: Bill has no items');
        }
      }
      for (final item in items) {
        final category = item.category ?? 'Uncategorized';
        groupedItems.putIfAbsent(category, () => []).add(item);
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

      return _PrecomputedBillData(
        customerCode: customerCode,
        amountInWords: amountInWords,
        groupedItems: groupedItems,
        sortedCategories: sortedCategories,
        companyInfo: companyInfo,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in precomputation: $e');
        print('Stack trace: $stackTrace');
        print('Bill ID: ${bill.id}, Bill Number: ${bill.billNumber}');
      }
      // Return safe default values to prevent complete failure
      // This allows PDF generation to continue even with malformed data
      return _PrecomputedBillData(
        customerCode: 'N/A',
        amountInWords: 'Zero Rupees only',
        groupedItems: {},
        sortedCategories: [],
        companyInfo: StoreCompanyInfo.toMap(),
      );
    }
  }

  static int _getCategoryPriority(String categoryName) {
    final normalized = categoryName.trim().toUpperCase();

    // App standard priority order:
    // 1. VEG PICKLES
    // 2. NON-VEG PICKLES
    // 3. KARAPODULU
    // 4. VADIYALU
    // 5. SNACKS
    if (normalized.contains('VEG PICKLE') && !normalized.contains('NON')) {
      return 1;
    }
    if (normalized.contains('NON') &&
        normalized.contains('VEG') &&
        normalized.contains('PICKLE')) {
      return 2;
    }
    if (normalized.contains('KARAPODULU')) {
      return 3;
    }
    if (normalized.contains('VADIYALU')) {
      return 4;
    }
    if (normalized.contains('SNACK')) {
      return 5;
    }
    return 999; // Others
  }

  /// Build Header: PO Style Layout (Logo/Company Left, Title Right)
  /// Build Header: Payment Receipt Style Layout (Company Left, Logo Right, Title Center)
  static pw.Widget _buildHeaderStaticOptimized({
    required String billNumber,
    required DateTime createdAt,
    required Map<String, dynamic> customerInfo,
    pw.MemoryImage? logoImage,
    required _PrecomputedBillData precomputed,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Top Section: Company Left, Logo Right
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Left: Company Info
            pw.Expanded(
              child: _buildCompanyInfoTextStatic(precomputed.companyInfo),
            ),
            // Right: Logo
            if (logoImage != null)
              pw.Container(
                width: 100,
                height: 100,
                alignment: pw.Alignment.topRight,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
          ],
        ),
        pw.SizedBox(height: 12),

        // Center Title
        pw.Center(
          child: pw.Text(
            'TAX INVOICE',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _poTitleColorStatic, // Blue
            ),
          ),
        ),
        pw.SizedBox(height: 20),

        // Address Boxes Row (4 Columns)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _buildBoxedSectionStatic(
                'Bill To',
                _buildBillToContent(customerInfo, precomputed.customerCode),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildBoxedSectionStatic(
                'Ship To',
                _buildShipToContent(customerInfo),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildBoxedSectionStatic(
                'Transportation Details',
                _buildTransportationContent(customerInfo),
              ),
            ),
            pw.SizedBox(width: 8),
            // Invoice Details Box
            pw.Expanded(
              child: _buildBoxedSectionStatic(
                'Invoice Details',
                _buildInvoiceDetailsContent(billNumber, createdAt),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper: Company Info Text Block
  static pw.Widget _buildCompanyInfoTextStatic(
    Map<String, dynamic> companyInfo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _cleanText(companyInfo['name'] ?? StoreCompanyInfo.name),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _textColorStatic,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _cleanText(companyInfo['address'] ?? StoreCompanyInfo.address),
          style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
        ),
        pw.Text(
          _cleanText('${companyInfo['city'] ?? StoreCompanyInfo.city}, ${companyInfo['state'] ?? StoreCompanyInfo.state} - ${companyInfo['pincode'] ?? StoreCompanyInfo.pincode}'),
          style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
        ),
        pw.Text(
          _cleanText('Phone: ${companyInfo['phone'] ?? StoreCompanyInfo.phone}'),
          style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
        ),
        pw.Text(
          _cleanText('Email: ${companyInfo['email'] ?? StoreCompanyInfo.email}'),
          style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
        ),
        if (companyInfo['gst'] != null)
          pw.Text(
            _cleanText('GSTIN: ${companyInfo['gst']}'),
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
        if (companyInfo['fssai_no'] != null)
          pw.Text(
            _cleanText('FSSAI NO: ${companyInfo['fssai_no']}'),
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
      ],
    );
  }

  // Helper: Invoice Details Content (Left Aligned for Box)
  static pw.Widget _buildInvoiceDetailsContent(
    String billNumber,
    DateTime createdAt,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _cleanText('Invoice No: $billNumber'),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _cleanText('Date: ${_formatDateStatic(createdAt)}'),
          style: pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  // Helper: Box Section (White Background)
  static pw.Widget _buildBoxedSectionStatic(String title, pw.Widget content) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        // color: _poBoxBgColorStatic, // Removed grey background
        border: pw.Border.all(color: _borderColorStatic), // Use lighter border
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          content,
        ],
      ),
    );
  }

  // Helper: Bill To Content
  static pw.Widget _buildBillToContent(
    Map<String, dynamic> customerInfo,
    String customerCode,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _cleanText('${customerInfo['name'] ?? ''}'),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        if (customerInfo['city'] != null || customerInfo['state'] != null)
          pw.Text(
            _cleanText('${customerInfo['city'] ?? ''}, ${customerInfo['state'] ?? ''}'),
            style: pw.TextStyle(fontSize: 9),
          ),
        if (customerInfo['phone'] != null)
          pw.Text(
            _cleanText('Phone: ${customerInfo['phone']}'),
            style: pw.TextStyle(fontSize: 9),
          ),
      ],
    );
  }

  // Helper: Ship To Content
  static pw.Widget _buildShipToContent(Map<String, dynamic> customerInfo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _cleanText('${customerInfo['address'] ?? ''}'),
          style: pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          _cleanText('${customerInfo['city'] ?? ''}, ${customerInfo['state'] ?? ''}'),
          style: pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  // Helper: Transportation Content
  static pw.Widget _buildTransportationContent(
    Map<String, dynamic> customerInfo,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Delivery Location:',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Text(
          _cleanText(customerInfo['city'] ?? 'N/A'),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ],
    );
  }

  /// Optimized version that doesn't require full Bill object
  /// Build Footer: Terms and Financials side by side
  static pw.Widget _buildFooterStaticOptimized({
    required String billNumber,
    required double subtotal,
    required double shipping,
    required double total,
    required double oldDue,
    required double receivedAmount,
    pw.MemoryImage? logoImage,
    required _PrecomputedBillData precomputed,
  }) {
    // Grand Total includes old due: Total + Old Due
    final grandTotal = total + oldDue;
    // Balance Due: Grand Total - Received Amount
    final balanceDue = grandTotal - receivedAmount;
    final paymentMode = balanceDue > 0 ? 'Credit' : 'Cash';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Column: Amount in Words, Terms
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Invoice Amount In Words',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColorStatic,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _cleanText(precomputed.amountInWords),
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColorStatic,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Terms And Conditions',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColorStatic,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Thanks for doing business with us!',
                style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),

        // Right Column: Financial Summary and Signature
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Financial Summary Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderColorStatic, width: 0.5),
                ),
                child: pw.Column(
                  children: [
                    _buildFinancialRowStatic('Sub Total', subtotal),
                    _buildFinancialRowStatic('Delivery Charges', shipping),
                    // Total with Orange Background
                    pw.Container(
                      color: _orangeColorStatic,
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
                            'Rs ${total.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (oldDue > 0) ...[
                      _buildFinancialRowStatic('Old Due', oldDue),
                      _buildFinancialRowStatic(
                        'Grand Total',
                        grandTotal,
                        isBold: true,
                      ),
                    ],
                    _buildFinancialRowStatic('Received', receivedAmount),
                    _buildFinancialRowStatic(
                      'Balance Due',
                      balanceDue,
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
                              color: _textColorStatic,
                            ),
                          ),
                          pw.Text(
                            paymentMode,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _textColorStatic,
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
                _cleanText('For: ${StoreCompanyInfo.name}'),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColorStatic,
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'Authorized Signatory',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColorStatic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Load logo from assets with caching
  /// Returns cached logo bytes if available, otherwise loads and caches it
  /// Properly handles concurrent loads by waiting for the first load to complete
  /// Caches both raw bytes and processed image for optimal performance
  Future<Uint8List?> _loadLogoBytesFromAssets() async {
    // Return cached logo bytes if available
    if (_cachedLogoBytes != null) {
      if (kDebugMode) {
        print('Using cached logo bytes');
      }
      return _cachedLogoBytes;
    }

    // If already loading, wait for it to complete with a timeout
    if (_logoLoading) {
      // Wait for the loading to complete (with timeout to prevent infinite wait)
      int retries = 0;
      const maxRetries =
          20; // 2 seconds max wait (20 * 100ms) - reduced for faster response
      while (_logoLoading && retries < maxRetries) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_cachedLogoBytes != null) {
          if (kDebugMode) {
            print('Logo loaded by concurrent request, using cached version');
          }
          return _cachedLogoBytes;
        }
        retries++;
      }
      // If still loading after timeout, return null to avoid infinite wait
      if (_logoLoading) {
        if (kDebugMode) {
          print('Warning: Logo loading timeout, proceeding without logo');
        }
        return null;
      }
    }

    _logoLoading = true;
    try {
      if (kDebugMode) {
        print('Loading logo from assets: assets/picklemart.png');
      }
      final ByteData data = await rootBundle.load('assets/picklemart.png');
      final Uint8List bytes = data.buffer.asUint8List();

      if (kDebugMode) {
        print('Logo loaded successfully, ${bytes.length} bytes');
      }

      // OPTIMIZATION: Skip decode/re-encode if file is already PNG
      // Check PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
      bool isPng =
          bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0D &&
          bytes[5] == 0x0A &&
          bytes[6] == 0x1A &&
          bytes[7] == 0x0A;

      Uint8List finalBytes = bytes;

      // Only decode/re-encode if NOT already PNG (saves significant processing time)
      if (!isPng) {
        if (kDebugMode) {
          print('Logo is not PNG format, decoding and encoding...');
        }
        try {
          final image = img.decodeImage(bytes);
          if (image != null) {
            // Re-encode as PNG to ensure compatibility
            final encodedBytes = Uint8List.fromList(img.encodePng(image));
            if (kDebugMode) {
              print('Logo encoded successfully, ${encodedBytes.length} bytes');
            }
            finalBytes = encodedBytes;
          } else {
            // If decode fails, use original bytes
            if (kDebugMode) {
              print('Could not decode logo, using original bytes');
            }
          }
        } catch (e) {
          // If decode/encode fails, use original bytes
          if (kDebugMode) {
            print('Logo processing skipped, using original bytes: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print(
            'Logo is already PNG format, skipping decode/encode (much faster)',
          );
        }
      }

      // Cache both bytes and image
      _cachedLogoBytes = finalBytes;

      return _cachedLogoBytes;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error loading logo from assets: $e');
        print('Stack trace: $stackTrace');
      }
      return null;
    } finally {
      _logoLoading = false;
    }
  }

  /* /// Format date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString().substring(2)}';
  } */

  // Static helper methods for isolate use
  static String _formatDateStatic(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString().substring(2)}';
  }

  static pw.Widget _buildCompanyHeaderStatic(
    Map<String, dynamic> companyInfo,
    pw.MemoryImage? logoImage,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _cleanText(companyInfo['name'] ?? StoreCompanyInfo.name),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _textColorStatic,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _cleanText(companyInfo['address'] ?? StoreCompanyInfo.address),
                style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _cleanText('Phone no.: ${companyInfo['phone'] ?? StoreCompanyInfo.phone}'),
                style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _cleanText('Email: ${companyInfo['email'] ?? StoreCompanyInfo.email}'),
                style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _cleanText('State: ${companyInfo['state'] ?? StoreCompanyInfo.state}'),
                style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _cleanText('FSSAI NO: ${companyInfo['fssai_no'] ?? StoreCompanyInfo.fssaiNo}'),
                style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
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

  static pw.Widget _buildBillToSectionStatic(
    Map<String, dynamic> customerInfo,
    String customerCode,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColorStatic, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bill To:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textColorStatic,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _cleanText('${customerInfo['name'] ?? ''}'),
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
          if (customerInfo['city'] != null ||
              customerInfo['state'] != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              _cleanText('${customerInfo['city'] ?? ''}-${customerInfo['state'] ?? ''}'),
              style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildShipToSectionStatic(
    Map<String, dynamic> customerInfo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColorStatic, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Ship To:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textColorStatic,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _cleanText('${customerInfo['address'] ?? ''}, ${customerInfo['city'] ?? ''}, ${customerInfo['state'] ?? ''}'),
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
        ],
      ),
    );
  }

  /* static pw.Widget _buildManufacturerDetailsStatic(
    Map<String, dynamic> customerInfo,
    Map<String, dynamic> companyInfo,
  ) {
    final addressParts = <String>[];
    if (customerInfo['address'] != null &&
        customerInfo['address'].toString().isNotEmpty) {
      addressParts.add(customerInfo['address'].toString());
    }
    if (customerInfo['city'] != null &&
        customerInfo['city'].toString().isNotEmpty) {
      addressParts.add(customerInfo['city'].toString());
    }
    if (customerInfo['state'] != null &&
        customerInfo['state'].toString().isNotEmpty) {
      addressParts.add(customerInfo['state'].toString());
    }
    if (customerInfo['pincode'] != null &&
        customerInfo['pincode'].toString().isNotEmpty) {
      addressParts.add(customerInfo['pincode'].toString());
    }
    final deliveryLocation =
        addressParts.isNotEmpty ? addressParts.join(', ') : '';
    final storeName = companyInfo['name'] ?? StoreCompanyInfo.name;
    final storePhone = companyInfo['phone'] ?? StoreCompanyInfo.phone;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColorStatic, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Manufacturer Details:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textColorStatic,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Name: $storeName',
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Address: ${deliveryLocation.isNotEmpty ? deliveryLocation : ''}',
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Phone: $storePhone',
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
        ],
      ),
    );
  } */

  /* static pw.Widget _buildInvoiceDetailsStatic(Bill bill) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColorStatic, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Invoice Details:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textColorStatic,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Invoice No.: ${bill.billNumber}',
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Date: ${_formatDateStatic(bill.createdAt)}',
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
        ],
      ),
    );
  } */

  static pw.Widget _buildInvoiceDetailsStaticOptimized(
    String billNumber,
    DateTime createdAt,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColorStatic, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Invoice Details:',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _textColorStatic,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Invoice No.: $billNumber',
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Date: ${_formatDateStatic(createdAt)}',
            style: pw.TextStyle(fontSize: 9, color: _textColorStatic),
          ),
        ],
      ),
    );
  }

  /// Build items table with 6 columns: #, Item name, Quantity, Unit, Price/Unit, Amount
  /// Grouped by category with headers
  static pw.Widget _buildItemsTableStatic(
    List<BillItem> items,
    Map<String, List<BillItem>> groupedItems,
    List<String> sortedCategories,
  ) {
    const columnWidths = {
      0: pw.FixedColumnWidth(30),
      1: pw.FlexColumnWidth(4),
      2: pw.FlexColumnWidth(1),
      3: pw.FlexColumnWidth(1),
      4: pw.FlexColumnWidth(1.5),
      5: pw.FlexColumnWidth(1.5),
    };

    final contentList = <pw.Widget>[];

    // 1. Main Header Table
    contentList.add(
      pw.Table(
        columnWidths: columnWidths,
        border: pw.TableBorder.all(
          color: _poTableBorderColorStatic,
          width: 0.5,
        ),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _orangeColorStatic),
            children: [
              _buildTableCellStatic(
                '#',
                PdfColors.white,
                _orangeColorStatic,
                isHeader: true,
                alignment: pw.Alignment.center,
              ),
              _buildTableCellStatic(
                'Description of Goods',
                PdfColors.white,
                _orangeColorStatic,
                isHeader: true,
                alignment: pw.Alignment.centerLeft,
              ),
              _buildTableCellStatic(
                'Quantity',
                PdfColors.white,
                _orangeColorStatic,
                isHeader: true,
                alignment: pw.Alignment.center,
              ),
              _buildTableCellStatic(
                'Unit',
                PdfColors.white,
                _orangeColorStatic,
                isHeader: true,
                alignment: pw.Alignment.center,
              ),
              _buildTableCellStatic(
                'Rate',
                PdfColors.white,
                _orangeColorStatic,
                isHeader: true,
                alignment: pw.Alignment.centerRight,
              ),
              _buildTableCellStatic(
                'Amount',
                PdfColors.white,
                _orangeColorStatic,
                isHeader: true,
                alignment: pw.Alignment.centerRight,
              ),
            ],
          ),
        ],
      ),
    );

    int serialNumber = 1;

    // 2. Iterate Categories
    for (final category in sortedCategories) {
      final categoryItems = groupedItems[category] ?? [];
      if (categoryItems.isEmpty) continue;

      // Category Header - Aligned with Item Name column (2nd column)
      contentList.add(
        pw.Table(
          columnWidths: columnWidths,
          border: pw.TableBorder.all(
            color: _poTableBorderColorStatic,
            width: 0.5,
          ),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _categoryBgColorStatic),
              children: [
                pw.Container(), // #
                _buildTableCellStatic(
                  category.toUpperCase(),
                  _textColorStatic,
                  _categoryBgColorStatic,
                  isBold: true,
                  alignment: pw.Alignment.centerLeft,
                ), // Item Name
                pw.Container(), // Quantity
                pw.Container(), // Unit
                pw.Container(), // Price/Unit
                pw.Container(), // Amount
              ],
            ),
          ],
        ),
      );

      // Items Table for this category
      final itemRows = <pw.TableRow>[];
      for (final item in categoryItems) {
        final unit = item.measurementUnit ?? '-';
        itemRows.add(
          pw.TableRow(
            children: [
              _buildTableCellStatic(
                serialNumber.toString(),
                _textColorStatic,
                PdfColors.white,
                alignment: pw.Alignment.center,
              ),
              _buildTableCellStatic(
                item.productName,
                _textColorStatic,
                PdfColors.white,
                alignment: pw.Alignment.centerLeft,
                isBold: false, // Match PO style (not bold)
              ),
              _buildTableCellStatic(
                item.quantity.toString(),
                _textColorStatic,
                PdfColors.white,
                alignment: pw.Alignment.center,
              ),
              _buildTableCellStatic(
                unit,
                _textColorStatic,
                PdfColors.white,
                alignment: pw.Alignment.center,
              ),
              _buildTableCellStatic(
                'Rs ${item.unitPrice.toStringAsFixed(2)}',
                _textColorStatic,
                PdfColors.white,
                alignment: pw.Alignment.centerRight,
              ),
              _buildTableCellStatic(
                'Rs ${item.totalPrice.toStringAsFixed(2)}',
                _textColorStatic,
                PdfColors.white,
                alignment: pw.Alignment.centerRight,
              ),
            ],
          ),
        );
        serialNumber++;
      }

      contentList.add(
        pw.Table(
          columnWidths: columnWidths,
          border: pw.TableBorder.all(
            color: _poTableBorderColorStatic,
            width: 0.5,
          ),
          children: itemRows,
        ),
      );
    }

    // 3. Total Section
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final totalAmount = items.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    contentList.add(
      pw.Table(
        columnWidths: columnWidths,
        border: pw.TableBorder.all(
          color: _poTableBorderColorStatic,
          width: 0.5,
        ),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(
              border: const pw.Border(
                top: pw.BorderSide(width: 0.5, color: PdfColors.black),
              ),
            ),
            children: [
              _buildTableCellStatic('', _textColorStatic, PdfColors.white),
              _buildTableCellStatic(
                'Total',
                _textColorStatic,
                PdfColors.white,
                isBold: true,
              ),
              _buildTableCellStatic(
                totalQuantity.toString(),
                _textColorStatic,
                PdfColors.white,
                isBold: true,
                alignment: pw.Alignment.center,
              ),
              _buildTableCellStatic('', _textColorStatic, PdfColors.white),
              _buildTableCellStatic('', _textColorStatic, PdfColors.white),
              _buildTableCellStatic(
                'Rs ${totalAmount.toStringAsFixed(2)}',
                _textColorStatic,
                PdfColors.white,
                isBold: true,
                alignment: pw.Alignment.centerRight,
              ),
            ],
          ),
        ],
      ),
    );

    return pw.Column(children: contentList);
  }

  static pw.Widget _buildFinancialRowStatic(
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
            _cleanText(label),
            style: pw.TextStyle(
              fontSize: isBold ? 11 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: _textColorStatic,
            ),
          ),
          pw.Text(
            'Rs ${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: isBold ? 11 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: _textColorStatic,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCellStatic(
    String text,
    PdfColor textColor,
    PdfColor bgColor, {
    bool isHeader = false,
    bool isBold = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: bgColor,
      alignment: alignment,
      child: pw.Text(
        _cleanText(text),
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight:
              (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }
}
