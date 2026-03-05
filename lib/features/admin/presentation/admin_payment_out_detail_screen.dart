import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_to_words.dart';
import '../application/manufacturer_controller.dart';
import '../application/cash_book_controller.dart';
import '../data/credit_transaction_repository.dart';
import '../data/payment_out_pdf_service.dart';
import '../data/purchase_order_repository_supabase.dart';
import '../domain/credit_transaction.dart';
import '../domain/manufacturer.dart';
import '../domain/purchase_order.dart';
import 'widgets/admin_auth_guard.dart';

/// Payment Out document detail screen. Shows full document UI when linked to a PO,
/// or simple receipt when no PO. Displays amount and unpaid (Balance Due) correctly.
class AdminPaymentOutDetailScreen extends ConsumerStatefulWidget {
  final CreditTransaction transaction;
  final PurchaseOrder? purchaseOrder;
  final PaidToInfo? paidTo;

  const AdminPaymentOutDetailScreen({
    super.key,
    required this.transaction,
    this.purchaseOrder,
    this.paidTo,
  });

  @override
  ConsumerState<AdminPaymentOutDetailScreen> createState() =>
      _AdminPaymentOutDetailScreenState();
}

class _AdminPaymentOutDetailScreenState
    extends ConsumerState<AdminPaymentOutDetailScreen> {
  PurchaseOrder? _linkedPO;
  PaidToInfo? _paidTo;
  double _currentBalance = 0.0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.purchaseOrder != null && widget.paidTo != null) {
      _linkedPO = widget.purchaseOrder;
      _paidTo = widget.paidTo;
      _isLoading = false;
    } else {
      _resolvePOAndPaidTo();
    }
  }

  Future<void> _resolvePOAndPaidTo() async {
    final refNo = widget.transaction.referenceNumber;
    if (refNo == null || refNo.isEmpty) {
      setState(() {
        _isLoading = false;
        _paidTo = widget.paidTo ?? _paidToFromTransaction();
      });
      return;
    }

    try {
      final supabaseClient = ref.read(supabaseClientProvider);
      final purchaseRepo = PurchaseOrderRepositorySupabase(supabaseClient);
      final linkedPO =
          await purchaseRepo.getPurchaseOrderByNumber(refNo) ??
          await purchaseRepo.getPurchaseOrderById(refNo);

      await ref
          .read(manufacturerControllerProvider.notifier)
          .loadManufacturers();
      final manufacturers =
          ref.read(manufacturerControllerProvider).manufacturers;
      Manufacturer? manufacturer;
      try {
        manufacturer = manufacturers.firstWhere(
          (m) => m.id == widget.transaction.manufacturerId,
        );
      } catch (_) {}

      // Load manufacturer balance if it's a manufacturer transaction
      double balanceAmount = 0.0;
      if (widget.transaction.manufacturerId != null) {
        try {
          final repo = ref.read(creditTransactionRepositoryProvider);
          final balance = await repo.getManufacturerBalance(
            widget.transaction.manufacturerId!,
          );
          balanceAmount = balance.currentBalance;
        } catch (_) {}
      }

      final paidTo =
          widget.paidTo ??
          PaidToInfo(
            name: manufacturer?.businessName ?? widget.transaction.displayName,
            address: manufacturer?.businessAddress,
            phone: manufacturer?.phone,
            gstNumber: manufacturer?.gstNumber,
          );

      if (mounted) {
        setState(() {
          _linkedPO = linkedPO;
          _paidTo = paidTo;
          _currentBalance = balanceAmount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
          _paidTo = widget.paidTo ?? _paidToFromTransaction();
        });
      }
    }
  }

  PaidToInfo _paidToFromTransaction() {
    return PaidToInfo(
      name: widget.transaction.displayName,
      address: null,
      phone: null,
      gstNumber: null,
    );
  }

  static const Color _greenColor = Color(0xFF2E7D32);
  static const Color _grayColor = Color(0xFF5F6368);

  Widget _buildFormStyleBody(BuildContext context) {
    final paidTo = _paidTo ?? _paidToFromTransaction();
    final hasPO = _linkedPO != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReceiptNoDateRow(context),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(height: 1, thickness: 0.5),
        ),
        // Firm Name Card (Our Business)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: AppColors.outlineSoft),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firm Name',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pickle Mart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPartyCard(context, paidTo, hasPO),
        const SizedBox(height: 16),
        _buildContactCard(paidTo),
        const SizedBox(height: 24),
        _buildPaymentSummaryCard(context, hasPO),
      ],
    );
  }

  Widget _buildReceiptNoDateRow(BuildContext context) {
    final refNo = widget.transaction.referenceNumber ?? '-';
    final dateStr = DateFormat(
      'dd/MM/yyyy',
    ).format(widget.transaction.transactionDate);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receipt No.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                refNo,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Color(0xFF5F6368),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 40,
          width: 1,
          color: AppColors.outlineSoft.withOpacity(0.5),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Color(0xFF5F6368),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartyCard(BuildContext context, PaidToInfo paidTo, bool hasPO) {
    final remaining =
        hasPO && _linkedPO != null
            ? (_linkedPO!.total - _linkedPO!.paidAmount).clamp(
              0.0,
              double.infinity,
            )
            : _currentBalance.abs();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineSoft),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Party Name*',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              RichText(
                text: TextSpan(
                  text: 'Party Balance: ',
                  style: TextStyle(color: _grayColor, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'Rs ${remaining.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: _greenColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: " You'll Get",
                      style: TextStyle(
                        color: _greenColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            paidTo.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(PaidToInfo paidTo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineSoft),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Number',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            paidTo.phone ?? '-',
            style: TextStyle(
              color:
                  paidTo.phone != null && paidTo.phone!.isNotEmpty
                      ? AppColors.textPrimary
                      : AppColors.outlineMedium,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilledItemsHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Ionicons.checkmark_circle,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Billed Items',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Rate exl. tax',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Ionicons.chevron_down, size: 14, color: colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOutItemCards(BuildContext context, PurchaseOrder order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...order.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineSoft),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.image.isNotEmpty)
                  Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineSoft),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.image,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Ionicons.image_outline,
                              size: 24,
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    border: Border.all(
                                      color: AppColors.outlineSoft,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rs ${item.totalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Item Subtotal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${item.quantity} x Rs ${item.unitPrice.toStringAsFixed(0)} = Rs ${item.totalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentSummaryCard(BuildContext context, bool hasPO) {
    final subtotal =
        hasPO && _linkedPO != null
            ? _linkedPO!.subtotal
            : widget.transaction.amount;
    final grandTotal =
        hasPO && _linkedPO != null
            ? _linkedPO!.total
            : widget.transaction.amount;
    final paidOut = widget.transaction.amount;
    final remaining =
        hasPO && _linkedPO != null
            ? (_linkedPO!.total - _linkedPO!.paidAmount).clamp(
              0.0,
              double.infinity,
            )
            : _currentBalance.abs();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.outlineSoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid (Out)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              Text(
                'Rs ${paidOut.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining Balance',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              Text(
                'Rs ${remaining.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Ionicons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Row(
            children: [
              Image.asset(
                'assets/picklemart.png',
                height: 32,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment-Out',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(
                Ionicons.settings_outline,
                color: AppColors.textPrimary,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'print':
                    _printPdf(context);
                    break;
                  case 'edit':
                    _edit(context);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    if (_linkedPO != null)
                      const PopupMenuItem(
                        value: 'print',
                        child: Row(
                          children: [
                            Icon(Ionicons.print_outline, size: 20),
                            SizedBox(width: 12),
                            Text('Print'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Ionicons.create_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.trash_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null &&
                    _linkedPO == null &&
                    widget.purchaseOrder == null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Could not load order details',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildSimpleReceipt(context),
                        const SizedBox(height: 24),
                        _buildActionButtons(context),
                      ],
                    ),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormStyleBody(context),
                      const SizedBox(height: 32),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildSimpleReceipt(BuildContext context) {
    final paidTo = _paidTo ?? _paidToFromTransaction();
    final dateFormatted = DateFormat(
      'dd-MM-yyyy',
    ).format(widget.transaction.transactionDate);
    final amountInWords = NumberToWords.convert(widget.transaction.amount);
    final paymentMode = widget.transaction.paymentMethod?.displayName ?? 'Cash';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outlineSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paid To',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              paidTo.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Amount In Words',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amountInWords,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Receipt Details',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: $dateFormatted',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paid',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Rs ${widget.transaction.amount.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Mode',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  paymentMode,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Ionicons.create_outline),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(context),
                icon: const Icon(Ionicons.trash_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_linkedPO != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _printPdf(context),
              icon: const Icon(Ionicons.print_outline),
              label: const Text('Print'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_linkedPO != null) const SizedBox(height: 12),
        if (_linkedPO != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _sharePdf(context),
              icon: const Icon(Ionicons.share_social_outline),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (_linkedPO == null && _errorMessage == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Print and Share are available when this payment is linked to an order.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  void _edit(BuildContext context) {
    context
        .pushNamed(
          'admin-payment-out',
          extra: {
            'transaction': widget.transaction,
            if (widget.transaction.manufacturerId != null)
              'manufacturerId': widget.transaction.manufacturerId,
            if (_linkedPO != null) 'purchaseOrderId': _linkedPO!.id,
            if (_linkedPO != null) 'purchaseOrder': _linkedPO,
          },
        )
        .then((_) {
          if (mounted) context.pop(true);
        });
  }

  Future<void> _printPdf(BuildContext context) async {
    if (_linkedPO == null || _paidTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF is available only for payment linked to an order.',
          ),
        ),
      );
      return;
    }
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      final pdfBytes = await PaymentOutPdfService.generatePaymentOutPdf(
        transaction: widget.transaction,
        paidTo: _paidTo!,
        linkedPO: _linkedPO!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name:
            'PaymentOut_${widget.transaction.referenceNumber ?? "Receipt"}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error printing: $e')));
      }
      if (kDebugMode) {
        print('Error printing payment out: $e');
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    if (_linkedPO == null || _paidTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF is available only for payment linked to an order.',
          ),
        ),
      );
      return;
    }
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      final pdfBytes = await PaymentOutPdfService.generatePaymentOutPdf(
        transaction: widget.transaction,
        paidTo: _paidTo!,
        linkedPO: _linkedPO!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'PaymentOut_${widget.transaction.referenceNumber ?? "Receipt"}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
      if (kDebugMode) {
        print('Error sharing payment out: $e');
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Payment Out'),
            content: const Text(
              'Are you sure you want to delete this payment out? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(creditTransactionRepositoryProvider)
            .deleteCreditTransaction(widget.transaction.id);

        // Refresh cashbook totals
        ref.read(cashBookControllerProvider.notifier).refresh();

        if (mounted) {
          context.pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment out deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
        }
      }
    }
  }
}
