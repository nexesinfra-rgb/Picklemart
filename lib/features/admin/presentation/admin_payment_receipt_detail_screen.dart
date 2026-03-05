import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../data/payment_receipt_pdf_service.dart';
import '../data/payment_receipt_repository.dart';
import '../data/store_company_info.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/order_repository.dart';
import '../application/cash_book_controller.dart';
import '../application/admin_customer_controller.dart';

class AdminPaymentReceiptDetailScreen extends ConsumerStatefulWidget {
  final PaymentReceipt receipt;

  const AdminPaymentReceiptDetailScreen({super.key, required this.receipt});

  @override
  ConsumerState<AdminPaymentReceiptDetailScreen> createState() =>
      _AdminPaymentReceiptDetailScreenState();
}

class _AdminPaymentReceiptDetailScreenState
    extends ConsumerState<AdminPaymentReceiptDetailScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _paymentType = '';
  bool _isEditing = false;
  bool _isSaving = false;
  double _totalPaidForOrder = 0.0;
  bool _isLoadingBalance = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.receipt.amount.toStringAsFixed(2);
    _descriptionController.text = widget.receipt.description ?? '';
    _nameController.text = widget.receipt.customerName?.trim() ?? '';
    _phoneController.text = widget.receipt.customerPhone?.trim() ?? '';
    _paymentType = widget.receipt.paymentType;
    _loadTotalPaid();
    _amountController.addListener(_updateBalanceUI);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateBalanceUI);
    _amountController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateBalanceUI() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTotalPaid() async {
    if (widget.receipt.orderId == null) return;

    setState(() => _isLoadingBalance = true);
    try {
      final repo = ref.read(paymentReceiptRepositoryProvider);
      final paid = await repo.getTotalPaidForOrder(widget.receipt.orderId!);
      if (mounted) {
        setState(() {
          _totalPaidForOrder = paid;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _saveChanges() async {
    final newAmount = double.tryParse(_amountController.text);
    if (newAmount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final repository = ref.read(paymentReceiptRepositoryProvider);
    String description = _descriptionController.text;
    // If original receipt was a refund, ensure we keep the REFUND prefix
    // unless the user completely changed it to something else (which is rare)
    // This prevents accidental conversion to "Payment In" when editing description
    if (widget.receipt.description?.startsWith('REFUND:') == true &&
        !description.startsWith('REFUND:')) {
      description = 'REFUND: $description';
    }

    final success = await repository.updatePaymentReceipt(
      id: widget.receipt.id,
      amount: newAmount,
      paymentType: _paymentType,
      description: description,
      customerName: _nameController.text,
      customerPhone: _phoneController.text,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt updated successfully')),
        );
        // Return true to indicate changes
        if (context.canPop()) {
          context.pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update receipt')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final receipt = widget.receipt;

    final orderAsync =
        receipt.orderId != null
            ? ref.watch(orderByIdProvider(receipt.orderId!))
            : const AsyncValue<Order?>.data(null);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          (receipt.description?.toUpperCase().startsWith('REFUND') == true ||
                  receipt.description?.toUpperCase().contains('PAYMENT OUT') ==
                      true)
              ? 'Payment Out'
              : 'Payment-In',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () => _shareReceipt(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Handle more menu
            },
          ),
        ],
      ),
      body: orderAsync.when(
        data:
            (order) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfoRow(context),
                  _buildFirmNameRow(context),
                  const SizedBox(height: 16),
                  _buildCustomerCard(context, order),
                  const SizedBox(height: 12),
                  _buildPhoneNumberSection(context, order),
                  const SizedBox(height: 24),
                  _buildReceivedSection(context, order),
                  const Divider(height: 32),
                  _buildOldDueSection(context, order),
                  const Divider(height: 32),
                  _buildNoteSection(context),
                  const Divider(height: 32),
                  _buildPaymentTypeSection(context),
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading order: $err')),
      ),
      bottomSheet: _buildPersistentBottomButtons(context, ref),
    );
  }

  Widget _buildHeaderInfoRow(BuildContext context) {
    final receipt = widget.receipt;
    final dateFormatted = DateFormat('dd/MM/yyyy').format(receipt.paymentDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Receipt No.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Row(
                  children: [
                    Text(
                      receipt.receiptNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey[200],
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Row(
                  children: [
                    Text(
                      dateFormatted,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirmNameRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          const Text(
            'Firm Name: ',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          Text(
            StoreCompanyInfo.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Order? order) {
    final receipt = widget.receipt;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Name *',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Party Balance: ',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    TextSpan(
                      text: 'Rs ${order?.total.toStringAsFixed(2) ?? "0.00"}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_isEditing)
            TextField(
              controller: _nameController,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
          else
            Text(
              order != null
                  ? (order.deliveryAddress.alias?.isNotEmpty == true
                      ? '${order.deliveryAddress.alias!.trim()} ${order.deliveryAddress.name.trim()}'
                          .trim()
                      : order.deliveryAddress.name.trim())
                  : receipt.customerName?.trim() ?? "N/A",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberSection(BuildContext context, Order? order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              if (_isEditing)
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Enter Phone Number',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  keyboardType: TextInputType.phone,
                )
              else
                Text(
                  _phoneController.text.isNotEmpty
                      ? _phoneController.text
                      : "Not Provided",
                  style: TextStyle(
                    color:
                        _phoneController.text.isNotEmpty
                            ? Colors.black
                            : Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          // Spacer to push width to match customer name container
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildReceivedSection(BuildContext context, Order? order) {
    final theme = Theme.of(context);
    final receipt = widget.receipt;
    final isRefund = receipt.description?.startsWith('REFUND:') == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            isRefund ? 'Paid' : 'Received',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isRefund ? Colors.red : null,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  'Link',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Rs ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          const SizedBox(width: 12),
          if (_isEditing)
            SizedBox(
              width: 120,
              child: TextField(
                controller: _amountController,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            )
          else
            Text(
              receipt.amount.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildOldDueSection(BuildContext context, Order? order) {
    final receipt = widget.receipt;

    // Calculate Remaining Balance
    double balanceDue = 0.0;
    if (order != null && !_isLoadingBalance) {
      final currentUiAmount = double.tryParse(_amountController.text) ?? 0.0;
      final originalAmount = receipt.amount;

      // Adjusted Total Paid = (Total Paid from DB) - (Original Receipt Amount) + (Current UI Amount)
      final adjustedTotalPaid =
          _totalPaidForOrder - originalAmount + currentUiAmount;

      balanceDue = order.total - adjustedTotalPaid;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Remaining Balance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              const Text('Rs ', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                balanceDue.toStringAsFixed(2),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Simple dotted line representation
          Row(
            children: List.generate(
              40,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: index % 2 == 0 ? Colors.transparent : Colors.grey[300],
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSection(BuildContext context) {
    final receipt = widget.receipt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Payment Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 14, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'History',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.money, size: 20, color: Colors.green[700]),
              const SizedBox(width: 8),
              if (_isEditing)
                DropdownButton<String>(
                  value: _paymentType.toLowerCase(),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  ],
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _paymentType = newValue);
                    }
                  },
                  underline: const SizedBox(),
                )
              else
                Row(
                  children: [
                    Text(
                      receipt.paymentType.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Payment Type'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _isEditing
                          ? TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              hintText: 'Add Note',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            maxLines: 3,
                          )
                          : Text(
                            _descriptionController.text.isNotEmpty
                                ? _descriptionController.text
                                : "Add Note",
                            style: TextStyle(
                              color:
                                  _descriptionController.text.isNotEmpty
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: Colors.grey[300],
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildPersistentBottomButtons(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showDeleteConfirmation(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _isEditing
                      ? (_isSaving ? null : _saveChanges)
                      : () => setState(() => _isEditing = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        _isEditing ? 'Save' : 'Edit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 16),
              Text('Generating PDF for printing...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Get the PDF service and generate PDF bytes
      final pdfService = PaymentReceiptPdfService(ref);
      final pdfBytes = await pdfService.getPaymentReceiptPdfBytes(
        widget.receipt,
      );

      // Remove loading indicator
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      // Print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Receipt_${widget.receipt.receiptNumber}',
      );
    } catch (e) {
      // Remove loading indicator if present
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      if (kDebugMode) {
        print('Error printing payment receipt: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error printing: $e')));
      }
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Receipt'),
            content: const Text(
              'Are you sure you want to delete this payment receipt? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final receipt = widget.receipt;
      final repository = ref.read(paymentReceiptRepositoryProvider);
      final success = await repository.deletePaymentReceipt(receipt.id);
      if (success) {
        // Refresh cashbook totals and customer balance
        ref.read(cashBookControllerProvider.notifier).refresh();
        try {
          ref.read(adminCustomerControllerProvider.notifier).refresh();
        } catch (_) {}
        
        if (context.mounted) {
          context.pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt deleted successfully')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete receipt')),
          );
        }
      }
    }
  }

  Future<void> _shareReceipt(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Get the PDF service and generate PDF bytes
      final pdfService = PaymentReceiptPdfService(ref);
      final pdfBytes = await pdfService.getPaymentReceiptPdfBytes(
        widget.receipt,
      );

      // Remove loading indicator
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      // Share the PDF file
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'PaymentReceipt_${widget.receipt.receiptNumber}.pdf',
      );
    } catch (e) {
      // Remove loading indicator if present
      ScaffoldMessenger.of(context).removeCurrentSnackBar();

      if (kDebugMode) {
        print('Error sharing payment receipt: $e');
      }

      // Fallback to text sharing if Printing fails (unlikely for PDF)
      try {
        final text = _generateShareText();
        await Share.share(text);
      } catch (shareError) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error sharing: $shareError')));
        }
      }
    }
  }

  String _generateShareText() {
    final receipt = widget.receipt;
    return 'Payment Receipt\n'
        'Receipt #: ${receipt.receiptNumber}\n'
        'Date: ${DateFormat('dd MMM yyyy').format(receipt.paymentDate)}\n'
        'Amount: ₹${receipt.amount.toStringAsFixed(2)}\n'
        'Customer: ${receipt.customerName ?? "N/A"}\n'
        'Payment Type: ${receipt.paymentType.toUpperCase()}';
  }
}
