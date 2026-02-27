import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../application/admin_customer_controller.dart';
import '../application/admin_dashboard_controller.dart';
import '../application/cash_book_controller.dart';
import '../data/payment_receipt_repository.dart' as repo;
import '../domain/cash_book_entry.dart';
import '../domain/manufacturer.dart';
import '../application/manufacturer_controller.dart';
import '../data/credit_transaction_repository.dart';
import '../domain/credit_transaction.dart';
import '../../../core/providers/supabase_provider.dart';
import 'widgets/admin_auth_guard.dart';
import 'admin_payment_receipt_screen.dart';
import '../../../core/theme/app_colors.dart';

enum PaymentEntityType { customer, manufacturer }

class AdminAddPaymentScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? manufacturerId;

  const AdminAddPaymentScreen({
    super.key,
    this.customerId,
    this.manufacturerId,
  });

  @override
  ConsumerState<AdminAddPaymentScreen> createState() =>
      _AdminAddPaymentScreenState();
}

class _AdminAddPaymentScreenState extends ConsumerState<AdminAddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receivedAmountController = TextEditingController();
  final _receiptNoController = TextEditingController();
  final _descriptionController = TextEditingController();

  PaymentEntityType _entityType = PaymentEntityType.customer;
  Customer? _selectedCustomer;
  Manufacturer? _selectedManufacturer;
  double _manufacturerBalance = 0.0;

  DateTime _selectedDate = DateTime.now();
  PaymentType _selectedPaymentType = PaymentType.cash;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _receiptNoController.text = '${DateTime.now().millisecondsSinceEpoch}';

    // Pre-selection logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.customerId != null) {
        _preSelectCustomer(widget.customerId!);
      } else if (widget.manufacturerId != null) {
        _preSelectManufacturer(widget.manufacturerId!);
      }
    });
  }

  void _preSelectCustomer(String id) {
    final customerState = ref.read(adminCustomerControllerProvider);
    final customer =
        customerState.customers.where((c) => c.id == id).firstOrNull ??
        customerState.filteredCustomers.where((c) => c.id == id).firstOrNull;

    if (customer != null) {
      setState(() {
        _entityType = PaymentEntityType.customer;
        _selectedCustomer = customer;
      });
    }
  }

  Future<void> _preSelectManufacturer(String id) async {
    final manufacturerState = ref.read(manufacturerControllerProvider);
    final manufacturer =
        manufacturerState.manufacturers.where((m) => m.id == id).firstOrNull ??
        manufacturerState.filteredManufacturers
            .where((m) => m.id == id)
            .firstOrNull;

    if (manufacturer != null) {
      setState(() {
        _entityType = PaymentEntityType.manufacturer;
        _selectedManufacturer = manufacturer;
      });
      await _fetchManufacturerBalance(id);
    }
  }

  @override
  void dispose() {
    _receivedAmountController.dispose();
    _receiptNoController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _fetchManufacturerBalance(String manufacturerId) async {
    try {
      final balanceData = await ref
          .read(creditTransactionRepositoryProvider)
          .getEntityBalance(manufacturerId: manufacturerId);
      if (mounted) {
        setState(() {
          _manufacturerBalance = balanceData.currentBalance;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching manufacturer balance: $e');
      }
    }
  }

  PaymentMethod _toPaymentMethod(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return PaymentMethod.cash;
      case PaymentType.bankTransfer:
        return PaymentMethod.bankTransfer;
      case PaymentType.cheque:
        return PaymentMethod.cheque;
      case PaymentType.upi:
        return PaymentMethod.upi;
      case PaymentType.creditCard:
        return PaymentMethod.other;
      case PaymentType.other:
        return PaymentMethod.other;
    }
  }

  void _showManufacturerSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _ManufacturerSelectionSheet(),
    ).then((selected) {
      if (!mounted) return;
      if (selected != null && selected is Manufacturer) {
        setState(() {
          _selectedManufacturer = selected;
        });
        _fetchManufacturerBalance(selected.id);
      }
    });
  }

  void _showCustomerSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _CustomerSelectionSheet(),
    ).then((selected) {
      if (!mounted) return;
      if (selected != null && selected is Customer) {
        setState(() {
          _selectedCustomer = selected;
        });
      }
    });
  }

  Future<void> _savePayment({bool saveAndNew = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_entityType == PaymentEntityType.customer &&
        _selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    if (_entityType == PaymentEntityType.manufacturer &&
        _selectedManufacturer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a manufacturer')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = ref.read(supabaseClientProvider).auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final amount = double.parse(_receivedAmountController.text);

      if (_entityType == PaymentEntityType.customer) {
        // Customer Payment Logic (Payment In)

        // Save payment receipt
        final repository = ref.read(repo.paymentReceiptRepositoryProvider);
        await repository.createPaymentReceipt(
          orderId: null, // General payment
          customerId: _selectedCustomer!.id,
          receiptNumber: _receiptNoController.text,
          paymentDate: _selectedDate,
          amount: amount,
          paymentType: _selectedPaymentType.dbValue,
          description:
              _descriptionController.text.isEmpty
                  ? 'Payment In'
                  : _descriptionController.text,
          attachmentUrl: null,
          createdBy: user.id,
        );

      } else {
        // Manufacturer Payment Logic (Payment In / Refund)

        // Create Credit Transaction (Payout = Manufacturer pays Admin)
        await ref
            .read(creditTransactionRepositoryProvider)
            .createCreditTransaction(
              manufacturerId: _selectedManufacturer!.id,
              transactionType: CreditTransactionType.payout,
              amount: amount,
              createdBy: user.id,
              description:
                  _descriptionController.text.isEmpty
                      ? 'Payment In'
                      : _descriptionController.text,
              referenceNumber: _receiptNoController.text,
              paymentMethod: _toPaymentMethod(_selectedPaymentType),
              transactionDate: _selectedDate,
            );

        // Record in Cash Book (Payin)
        // Use cashBookController.addEntry which handles refresh automatically
        ref
            .read(cashBookControllerProvider.notifier)
            .addEntry(
              CashBookEntry(
                amount: amount,
                type: CashBookEntryType.payin,
                category: 'Manufacturer Refund',
                description:
                    'Payment In from ${_selectedManufacturer!.name}. ${_descriptionController.text}',
                date: _selectedDate,
                relatedId: _selectedManufacturer!.id,
                paymentMethod: _selectedPaymentType.displayName,
                createdBy: user.id,
              ),
            )
            .catchError((e) {
          if (kDebugMode) {
            print('Error recording cash book entry: $e');
          }
        });
      }

      // Refresh admin data to update balances for both customers and manufacturers
      ref.read(adminCustomerControllerProvider.notifier).refresh();
      ref.read(manufacturerControllerProvider.notifier).refresh();

      // Always refresh dashboard for total balance stats
      try {
        ref.read(adminDashboardControllerProvider.notifier).refresh();
      } catch (e) {
        // Ignore dashboard refresh errors
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment saved successfully')),
        );

        // After successful save, navigate to the receipt screen
        if (_entityType == PaymentEntityType.manufacturer &&
            _selectedManufacturer != null) {
          // For manufacturer, we just go back as we don't have a receipt screen yet
          // and the previous screen will refresh to show the new transaction
          if (!saveAndNew) {
             context.pop(true);
             return;
          }
        }

        if (saveAndNew) {
          setState(() {
            _selectedCustomer = null;
            _selectedManufacturer = null;
            _manufacturerBalance = 0.0;
            _receivedAmountController.clear();
            _descriptionController.clear();
            _receiptNoController.text =
                '${DateTime.now().millisecondsSinceEpoch}';
          });
        } else {
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving payment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment-In'),
          actions: [
            IconButton(
              icon: const Icon(Ionicons.settings_outline),
              onPressed: () {},
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Entity Type Toggle
              SegmentedButton<PaymentEntityType>(
                segments: const [
                  ButtonSegment(
                    value: PaymentEntityType.customer,
                    label: Text('Customer/Store'),
                    icon: Icon(Ionicons.person),
                  ),
                  ButtonSegment(
                    value: PaymentEntityType.manufacturer,
                    label: Text('Manufacturer'),
                    icon: Icon(Ionicons.business),
                  ),
                ],
                selected: {_entityType},
                onSelectionChanged: (Set<PaymentEntityType> newSelection) {
                  setState(() {
                    _entityType = newSelection.first;
                    // Reset selections when switching
                    _selectedCustomer = null;
                    _selectedManufacturer = null;
                    _manufacturerBalance = 0.0;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 24),

              // Receipt No & Date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _entityType == PaymentEntityType.customer
                              ? 'Receipt No.'
                              : 'Reference No.',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _receiptNoController.text,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Ionicons.chevron_down_outline,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Firm Name
              Text(
                'Firm Name: PICKLE MART',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Customer/Manufacturer Selection Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.outlineSoft),
                ),
                child: InkWell(
                  onTap:
                      _entityType == PaymentEntityType.customer
                          ? _showCustomerSelection
                          : _showManufacturerSelection,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _entityType == PaymentEntityType.customer
                                  ? 'Customer Name *'
                                  : 'Manufacturer Name *',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (_entityType == PaymentEntityType.customer)
                              Text(
                                'Party Balance: ₹${_selectedCustomer?.totalBalance.toStringAsFixed(2) ?? '0.00'}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      (_selectedCustomer?.totalBalance ?? 0) > 0
                                          ? Colors.red
                                          : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Text(
                                'Balance: ₹${_manufacturerBalance.toStringAsFixed(2)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      _manufacturerBalance > 0
                                          ? Colors.red
                                          : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_entityType == PaymentEntityType.customer &&
                            _selectedCustomer != null) ...[
                          Text(
                            _selectedCustomer!.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedCustomer!.phone.isNotEmpty)
                            Text(
                              _selectedCustomer!.phone,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ] else if (_entityType ==
                                PaymentEntityType.manufacturer &&
                            _selectedManufacturer != null) ...[
                          Text(
                            _selectedManufacturer!.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedManufacturer!.phone != null)
                            Text(
                              _selectedManufacturer!.phone!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ] else
                          Text(
                            _entityType == PaymentEntityType.customer
                                ? 'Select Customer'
                                : 'Select Manufacturer',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_entityType == PaymentEntityType.customer &&
                  _selectedCustomer != null &&
                  _selectedCustomer!.phone.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _selectedCustomer!.phone,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              if (_entityType == PaymentEntityType.manufacturer &&
                  _selectedManufacturer != null &&
                  _selectedManufacturer!.phone != null) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _selectedManufacturer!.phone,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Payment Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _entityType == PaymentEntityType.customer
                          ? theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3)
                          : Colors.orange.withOpacity(
                            0.1,
                          ), // Distinct color for payout
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _entityType == PaymentEntityType.customer
                                ? 'Received'
                                : 'Received (Refund)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Ionicons.sync_outline,
                                size: 16,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Link',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _receivedAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: '0.00',
                        border: UnderlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // Total Amount Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹ ${_receivedAmountController.text.isEmpty ? '0.00' : double.tryParse(_receivedAmountController.text)?.toStringAsFixed(2) ?? '0.00'}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // OLD DUE Payment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OLD DUE Payment',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs ${_entityType == PaymentEntityType.customer ? (_selectedCustomer?.totalBalance.toStringAsFixed(2) ?? '0.00') : _manufacturerBalance.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Remaining Balance
                    Builder(
                      builder: (context) {
                        final currentBalance =
                            _entityType == PaymentEntityType.customer
                                ? (_selectedCustomer?.totalBalance ?? 0.0)
                                : _manufacturerBalance;
                        final amount =
                            double.tryParse(_receivedAmountController.text) ??
                            0.0;
                        final remainingBalance = currentBalance - amount;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remaining Balance',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '₹ ${remainingBalance.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    remainingBalance > 0
                                        ? Colors.red
                                        : Colors.green,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Note
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add Note',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              // Payment Type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment Type', style: theme.textTheme.titleSmall),
                  DropdownButton<PaymentType>(
                    value: _selectedPaymentType,
                    underline: const SizedBox(),
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Icon(
                          _selectedPaymentType == PaymentType.cash
                              ? Ionicons.cash_outline
                              : Ionicons.card_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedPaymentType.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Icon(Ionicons.chevron_down_outline, size: 16),
                      ],
                    ),
                    items:
                        PaymentType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentType = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Ionicons.add_outline, size: 18),
                label: const Text('Add Payment Type'),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(height: 32),

              // Save Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : () => _savePayment(saveAndNew: true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save & New'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _savePayment(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isSaving
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerSelectionSheet extends ConsumerStatefulWidget {
  const _CustomerSelectionSheet();

  @override
  ConsumerState<_CustomerSelectionSheet> createState() =>
      _CustomerSelectionSheetState();
}

class _CustomerSelectionSheetState
    extends ConsumerState<_CustomerSelectionSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(adminCustomerControllerProvider);
    final customers =
        customerState.filteredCustomers
            .where((c) => !c.isManufacturer)
            .toList();

    return Container(
      padding: const EdgeInsets.only(top: 16),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Select Customer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Ionicons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customer...',
                prefixIcon: const Icon(Ionicons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                ref
                    .read(adminCustomerControllerProvider.notifier)
                    .searchCustomers(value);
              },
            ),
          ),
          Expanded(
            child:
                customerState.loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: customers.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              customer.name[0].toUpperCase(),
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(customer.phone),
                          trailing: Text(
                            '₹${customer.totalBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color:
                                  customer.totalBalance > 0
                                      ? Colors.red
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, customer);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _ManufacturerSelectionSheet extends ConsumerStatefulWidget {
  const _ManufacturerSelectionSheet();

  @override
  ConsumerState<_ManufacturerSelectionSheet> createState() =>
      _ManufacturerSelectionSheetState();
}

class _ManufacturerSelectionSheetState
    extends ConsumerState<_ManufacturerSelectionSheet> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load manufacturers if not already loaded or just to be safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(manufacturerControllerProvider.notifier).loadManufacturers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manufacturerState = ref.watch(manufacturerControllerProvider);
    final manufacturers = manufacturerState.filteredManufacturers;

    return Container(
      padding: const EdgeInsets.only(top: 16),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Select Manufacturer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Ionicons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search manufacturer...',
                prefixIcon: const Icon(Ionicons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                ref
                    .read(manufacturerControllerProvider.notifier)
                    .searchManufacturers(value);
              },
            ),
          ),
          Expanded(
            child:
                manufacturerState.loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: manufacturers.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final manufacturer = manufacturers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                            child: Text(
                              manufacturer.name[0].toUpperCase(),
                              style: TextStyle(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          title: Text(
                            manufacturer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(manufacturer.phone ?? 'No phone'),
                          onTap: () {
                            Navigator.pop(context, manufacturer);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
