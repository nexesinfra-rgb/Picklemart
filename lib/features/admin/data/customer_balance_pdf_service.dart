import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'customer_analytics_repository.dart';
import 'customer_analytics_repository_provider.dart';
import 'payment_receipt_repository.dart';
import 'store_company_info.dart';
import '../application/admin_customer_controller.dart';

/// Service for generating customer balance statement PDFs
class CustomerBalancePdfService {
  final CustomerAnalyticsRepository _customerAnalyticsRepository;
  final PaymentReceiptRepository _paymentReceiptRepository;

  CustomerBalancePdfService(
    this._customerAnalyticsRepository,
    this._paymentReceiptRepository,
  );

  // Helper method to convert Flutter Color to PDF Color
  static PdfColor _colorFromFlutter(int colorInt) {
    return PdfColor.fromInt(colorInt | 0xFF000000);
  }

  // Color scheme matching BillPdfService
  static PdfColor get _primaryColor => _colorFromFlutter(0xFFFBC801); // Yellow
  static PdfColor get _primaryColorLight => _colorFromFlutter(0xFFFEF4CC); // Yellow with opacity (lighter)
  static PdfColor get _borderColor => _colorFromFlutter(0xFFE5E7EB);
  static PdfColor get _textColor => PdfColors.black;
  static PdfColor get _textSecondary => _colorFromFlutter(0xFF6B7280);

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

  /// Generate PDF balance statement for a customer
  /// Fetches all orders and their payment information
  Future<Uint8List> generateBalancePdf(Customer customer) async {
    try {
      if (kDebugMode) {
        print('Generating balance PDF for customer: ${customer.name}');
      }

      // Fetch all orders for the customer (handle pagination)
      List<Map<String, dynamic>> allOrders = [];
      int page = 1;
      const int limit = 50;
      bool hasMore = true;

      while (hasMore) {
        final orders = await _customerAnalyticsRepository.getCustomerOrders(
          customer.id,
          page: page,
          limit: limit,
        );
        allOrders.addAll(orders);
        hasMore = orders.length == limit;
        page++;
      }

      if (kDebugMode) {
        print('Fetched ${allOrders.length} orders for customer ${customer.name}');
      }

      // Fetch payment totals for all orders
      final orderIds = allOrders.map((o) => o['id'] as String).toList();
      final paidByOrderId = <String, double>{};

      // Use bulk method if available, otherwise fetch individually
      try {
        final allPayments = await _paymentReceiptRepository.getTotalPaidForAllOrders();
        for (final orderId in orderIds) {
          paidByOrderId[orderId] = allPayments[orderId] ?? 0.0;
        }
      } catch (e) {
        // Fallback to individual fetches
        if (kDebugMode) {
          print('Bulk payment fetch failed, using individual fetches: $e');
        }
        for (final orderId in orderIds) {
          paidByOrderId[orderId] = await _paymentReceiptRepository.getTotalPaidForOrder(orderId);
        }
      }

      // Prepare order data with balances
      final orderData = <_OrderBalanceData>[];
      double totalSpent = 0.0;
      double totalPaid = 0.0;
      double totalBalance = 0.0;

      for (final order in allOrders) {
        final orderId = order['id'] as String;
        final orderNumber = order['order_number'] as String? ?? orderId.substring(0, 8);
        final orderDate = DateTime.parse(order['created_at'] as String);
        final orderTotal = (order['total'] as num?)?.toDouble() ?? 0.0;
        final paidAmount = paidByOrderId[orderId] ?? 0.0;
        final balance = orderTotal - paidAmount;

        orderData.add(_OrderBalanceData(
          orderNumber: orderNumber,
          date: orderDate,
          total: orderTotal,
          paid: paidAmount,
          balance: balance,
        ));

        totalSpent += orderTotal;
        totalPaid += paidAmount;
        totalBalance += balance;
      }

      // Sort by date (newest first)
      orderData.sort((a, b) => b.date.compareTo(a.date));

      // Generate PDF
      return await _generatePdf(
        customer: customer,
        orders: orderData,
        totalSpent: totalSpent,
        totalPaid: totalPaid,
        totalBalance: totalBalance,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error generating customer balance PDF: $e');
      }
      rethrow;
    }
  }

  /// Generate PDF document
  Future<Uint8List> _generatePdf({
    required Customer customer,
    required List<_OrderBalanceData> orders,
    required double totalSpent,
    required double totalPaid,
    required double totalBalance,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'RS ',
      decimalDigits: 0,
    );

    // Company info
    final companyInfo = StoreCompanyInfo.toMap();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Header
              _buildCompanyHeader(companyInfo),
              pw.SizedBox(height: 20),

              // Title
              pw.Center(
                child: pw.Text(
                  'BALANCE STATEMENT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Customer Information
              _buildCustomerInfo(customer, dateFormat),
              pw.SizedBox(height: 20),

              // Summary Section
              _buildSummarySection(
                totalOrders: orders.length,
                totalSpent: totalSpent,
                totalPaid: totalPaid,
                totalBalance: totalBalance,
                currencyFormat: currencyFormat,
              ),
              pw.SizedBox(height: 20),

              // Orders Table
              _buildOrdersTable(orders, dateFormat, currencyFormat, totalSpent, totalPaid, totalBalance),
              pw.SizedBox(height: 20),

              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Build company header
  pw.Widget _buildCompanyHeader(Map<String, dynamic> companyInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _cleanText(companyInfo['name'] as String? ?? 'PICKLE MART'),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            _cleanText(companyInfo['address'] as String? ?? ''),
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _cleanText('Phone: ${companyInfo['phone'] as String? ?? ''} | Email: ${companyInfo['email'] as String? ?? ''}'),
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build customer information section
  pw.Widget _buildCustomerInfo(Customer customer, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer Details',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _textColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Name:', customer.alias ?? customer.name),
                    _buildInfoRow('Email:', customer.email),
                    _buildInfoRow('Phone:', customer.phone),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Member Since:',
                      dateFormat.format(customer.createdAt),
                    ),
                    if (customer.lastOrderDate != null)
                      _buildInfoRow(
                        'Last Order:',
                        dateFormat.format(customer.lastOrderDate!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build info row
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              _cleanText(label),
              style: pw.TextStyle(
                fontSize: 10,
                color: _textSecondary,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _cleanText(value),
              style: pw.TextStyle(
                fontSize: 10,
              color: _textColor,
              fontWeight: pw.FontWeight.normal,
            ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build summary section
  pw.Widget _buildSummarySection({
    required int totalOrders,
    required double totalSpent,
    required double totalPaid,
    required double totalBalance,
    required NumberFormat currencyFormat,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _primaryColorLight,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _primaryColor, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Orders', totalOrders.toString()),
          _buildSummaryItem('Total Spent', currencyFormat.format(totalSpent)),
          _buildSummaryItem('Total Paid', currencyFormat.format(totalPaid)),
          _buildSummaryItem(
            'Balance Due',
            currencyFormat.format(totalBalance),
            isHighlight: totalBalance > 0,
          ),
        ],
      ),
    );
  }

  /// Build summary item
  pw.Widget _buildSummaryItem(String label, String value, {bool isHighlight = false}) {
    return pw.Column(
      children: [
        pw.Text(
          _cleanText(label),
          style: pw.TextStyle(
            fontSize: 9,
            color: _textSecondary,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _cleanText(value),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: isHighlight ? PdfColors.red : _textColor,
          ),
        ),
      ],
    );
  }

  /// Build orders table
  pw.Widget _buildOrdersTable(
    List<_OrderBalanceData> orders,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
    double totalSpent,
    double totalPaid,
    double totalBalance,
  ) {
    if (orders.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'No orders found',
          style: pw.TextStyle(
            fontSize: 12,
            color: _textSecondary,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _borderColor, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primaryColor),
          children: [
            _buildTableCell('Order #', PdfColors.white, isHeader: true),
            _buildTableCell('Date', PdfColors.white, isHeader: true),
            _buildTableCell('Total', PdfColors.white, isHeader: true, alignRight: true),
            _buildTableCell('Paid', PdfColors.white, isHeader: true, alignRight: true),
            _buildTableCell('Balance', PdfColors.white, isHeader: true, alignRight: true),
          ],
        ),
        // Data rows
        ...orders.map((order) {
          final balanceColor = order.balance > 0 ? PdfColors.red : _textColor;
          return pw.TableRow(
            children: [
              _buildTableCell(order.orderNumber, _textColor),
              _buildTableCell(dateFormat.format(order.date), _textColor),
              _buildTableCell(
                currencyFormat.format(order.total),
                _textColor,
                alignRight: true,
              ),
              _buildTableCell(
                currencyFormat.format(order.paid),
                _textColor,
                alignRight: true,
              ),
              _buildTableCell(
                currencyFormat.format(order.balance),
                balanceColor,
                alignRight: true,
                isBold: order.balance > 0,
              ),
            ],
          );
        }),
        // Total row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primaryColorLight),
          children: [
            _buildTableCell('TOTAL', _textColor, isHeader: true, isBold: true),
            _buildTableCell('', _textColor),
            _buildTableCell(
              currencyFormat.format(totalSpent),
              _textColor,
              alignRight: true,
              isBold: true,
            ),
            _buildTableCell(
              currencyFormat.format(totalPaid),
              _textColor,
              alignRight: true,
              isBold: true,
            ),
            _buildTableCell(
              currencyFormat.format(totalBalance),
              totalBalance > 0 ? PdfColors.red : _textColor,
              alignRight: true,
              isBold: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Build table cell
  pw.Widget _buildTableCell(
    String text,
    PdfColor textColor, {
    bool isHeader = false,
    bool alignRight = false,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        _cleanText(text),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }

  /// Build footer
  pw.Widget _buildFooter() {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: _borderColor),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on ${dateFormat.format(now)}',
          style: pw.TextStyle(
            fontSize: 8,
            color: _textSecondary,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'This is a computer-generated statement',
          style: pw.TextStyle(
            fontSize: 8,
            color: _textSecondary,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Data class for order balance information
class _OrderBalanceData {
  final String orderNumber;
  final DateTime date;
  final double total;
  final double paid;
  final double balance;

  _OrderBalanceData({
    required this.orderNumber,
    required this.date,
    required this.total,
    required this.paid,
    required this.balance,
  });
}

/// Provider for CustomerBalancePdfService
final customerBalancePdfServiceProvider = Provider<CustomerBalancePdfService>((ref) {
  final customerAnalyticsRepo = ref.watch(customerAnalyticsRepositoryProvider);
  final paymentRepo = ref.watch(paymentReceiptRepositoryProvider);
  return CustomerBalancePdfService(customerAnalyticsRepo, paymentRepo);
});

