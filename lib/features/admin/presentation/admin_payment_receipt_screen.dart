import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../../orders/data/order_model.dart';
import '../application/admin_customer_controller.dart';
import '../data/payment_receipt_repository.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/providers/supabase_provider.dart';
import 'widgets/admin_auth_guard.dart';

enum PaymentType { cash, bankTransfer, cheque, upi, creditCard, other }

extension PaymentTypeExtension on PaymentType {
  String get dbValue {
    switch (this) {
      case PaymentType.cash:
        return 'cash';
      case PaymentType.bankTransfer:
        return 'bank_transfer';
      case PaymentType.cheque:
        return 'cheque';
      case PaymentType.upi:
        return 'upi';
      case PaymentType.creditCard:
        return 'credit_card';
      case PaymentType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentType.cash:
        return 'Cash';
      case PaymentType.bankTransfer:
        return 'Bank Transfer';
      case PaymentType.cheque:
        return 'Cheque';
      case PaymentType.upi:
        return 'UPI';
      case PaymentType.creditCard:
        return 'Credit Card';
      case PaymentType.other:
        return 'Other';
    }
  }
}

class AdminPaymentReceiptScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String orderId;
  final Order? order;

  const AdminPaymentReceiptScreen({
    super.key,
    required this.customerId,
    required this.orderId,
    this.order,
  });

  @override
  ConsumerState<AdminPaymentReceiptScreen> createState() =>
      _AdminPaymentReceiptScreenState();
}

class _AdminPaymentReceiptScreenState
    extends ConsumerState<AdminPaymentReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receivedAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _receiptNoController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  PaymentType _selectedPaymentType = PaymentType.cash;
  bool _isSaving = false;

  double _totalPaid = 0.0;
  bool _isLoadingBalance = true;

  // Calculate balance due (order total - total paid so far)
  double get _balanceDue => (widget.order?.total ?? 0.0) - _totalPaid;

  // Calculate remaining balance (balance due - received)
  double get _remainingBalance {
    final received = double.tryParse(_receivedAmountController.text) ?? 0.0;
    return _balanceDue - received;
  }

  @override
  void initState() {
    super.initState();
    // Generate receipt number (can be enhanced later)
    _receiptNoController.text = '${DateTime.now().millisecondsSinceEpoch}';

    // Initialize received amount to the balance due
    _receivedAmountController.text = _balanceDue.toStringAsFixed(2);
    _receivedAmountController.addListener(() {
      if (mounted) {
        setState(() {}); // Update remaining balance in real-time
      }
    });

    // Load existing payments to calculate balance
    _loadPaymentBalance();
  }

  Future<void> _loadPaymentBalance() async {
    try {
      final repository = ref.read(paymentReceiptRepositoryProvider);
      final totalPaid = await repository.getTotalPaidForOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _totalPaid = totalPaid;
          _isLoadingBalance = false;
          // Automatically fill the received amount with the updated balance due
          _receivedAmountController.text = _balanceDue.toStringAsFixed(2);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalPaid = 0.0;
          _isLoadingBalance = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _receivedAmountController.dispose();
    _descriptionController.dispose();
    _receiptNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(adminCustomerControllerProvider);
    final customer = customerState.customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse:
          () => customerState.filteredCustomers.firstWhere(
            (c) => c.id == widget.customerId,
            orElse:
                () => Customer(
                  id: widget.customerId,
                  name: 'Unknown',
                  email: '',
                  phone: '',
                  createdAt: DateTime.now(),
                ),
          ),
    );
    final screenSize = Responsive.getScreenSize(context);

    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Ionicons.arrow_back_outline),
            onPressed: () => context.pop(),
          ),
          title: const Text('Payment-In'),
          actions: [
            IconButton(
              icon: const Icon(Ionicons.settings_outline),
              onPressed: () {
                // Settings action (placeholder)
              },
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(screenSize == ScreenSize.mobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receipt No. and Date Row
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Receipt No.',
                        value: _receiptNoController.text,
                        onTap: () {
                          // Can be made editable if needed
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDateField()),
                  ],
                ),
                const SizedBox(height: 16),

                // Customer Name
                _buildTextField(
                  label: 'Customer Name',
                  initialValue: customer.alias ?? customer.name,
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                // Phone Number
                _buildTextField(
                  label: 'Phone Number',
                  initialValue:
                      customer.phone.isEmpty ? 'Not Provided' : customer.phone,
                  readOnly: true,
                ),
                const SizedBox(height: 24),

                // Balance Due
                _isLoadingBalance
                    ? const Center(child: CircularProgressIndicator())
                    : _buildAmountDisplay(
                      label: 'Balance Due',
                      amount: _balanceDue,
                      color: Colors.black87,
                    ),
                const SizedBox(height: 16),

                // Remaining Balance
                _isLoadingBalance
                    ? const SizedBox.shrink()
                    : _buildAmountDisplay(
                      label: 'Remaining Balance',
                      amount: _remainingBalance,
                      color:
                          _remainingBalance > 0 ? Colors.orange : Colors.green,
                    ),
                const SizedBox(height: 16),

                // Received Amount
                _buildAmountInput(
                  label: 'Received',
                  controller: _receivedAmountController,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),

                // OLD DUE Payment line
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'OLD DUE Payment',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Container(
                        width: 100,
                        height: 1,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade400,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                _buildDescriptionField(),
                const SizedBox(height: 16),

                // Payment Type
                _buildPaymentTypeField(),
                const SizedBox(height: 16),

                // Add Payment Type link
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Ionicons.add_outline, size: 16),
                  label: const Text('+ Add Payment Type'),
                ),
                const SizedBox(height: 16),

                // Image attachment option
                _buildImageAttachmentOption(),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _savePayment,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isSaving
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text('Save'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          suffixIcon: const Icon(Ionicons.chevron_down_outline),
        ),
        child: Text(value),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Ionicons.calendar_outline),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    bool readOnly = false,
  }) {
    return TextFormField(
      initialValue: initialValue,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAmountDisplay({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            'Rs ${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput({
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
        prefixText: 'Rs ',
        prefixStyle: TextStyle(
          fontSize: 22,
          color: color,
          fontWeight: FontWeight.bold,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        suffixIcon: Icon(Ionicons.cash_outline, color: color),
      ),
      style: TextStyle(
        color: color,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
        decorationColor: color.withOpacity(0.5),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter received amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount < 0) {
          return 'Please enter a valid amount';
        }
        if (amount > _balanceDue) {
          return 'Received amount cannot exceed balance due';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentTypeField() {
    return DropdownButtonFormField<PaymentType>(
      initialValue: _selectedPaymentType,
      decoration: InputDecoration(
        labelText: 'Payment Type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(Ionicons.wallet_outline, color: Colors.green),
        suffixIcon: const Icon(Ionicons.chevron_down_outline),
      ),
      items:
          PaymentType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(
                    type == PaymentType.cash
                        ? Ionicons.cash_outline
                        : type == PaymentType.upi
                        ? Ionicons.phone_portrait_outline
                        : Ionicons.card_outline,
                    size: 18,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(type.displayName),
                ],
              ),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPaymentType = value;
          });
        }
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Add Note',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildImageAttachmentOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            Ionicons.image_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            // Image attachment action (placeholder)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image attachment coming soon')),
            );
          },
          tooltip: 'Add Image',
        ),
      ],
    );
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final receivedAmount = double.parse(_receivedAmountController.text);

      if (receivedAmount <= 0) {
        throw Exception('Received amount must be greater than 0');
      }

      if (receivedAmount > _balanceDue) {
        throw Exception('Received amount cannot exceed balance due');
      }

      // Get current user
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Save payment receipt
      final repository = ref.read(paymentReceiptRepositoryProvider);
      await repository.createPaymentReceipt(
        orderId: widget.orderId,
        customerId: widget.customerId,
        receiptNumber: _receiptNoController.text,
        paymentDate: _selectedDate,
        amount: receivedAmount,
        paymentType: _selectedPaymentType.name,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
        attachmentUrl: null, // TODO: Implement image upload
        createdBy: user.id,
      );

      // Refresh customer list to update sorting (stores with recent payments will appear at top)
      if (mounted) {
        ref
            .read(adminCustomerControllerProvider.notifier)
            .loadCustomers()
            .catchError((e) {
              // Silently handle refresh errors - payment was still saved successfully
              if (kDebugMode) {
                print('⚠️ Error refreshing customer list after payment: $e');
              }
            });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of ₹${receivedAmount.toStringAsFixed(2)} saved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back and refresh orders
        context.pop(true); // Pass true to indicate payment was saved
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
