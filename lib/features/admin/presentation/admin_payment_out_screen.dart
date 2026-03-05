import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

// Core Imports
import '../../../core/providers/supabase_provider.dart';

// Application Imports
import '../application/admin_customer_controller.dart';
import '../application/admin_dashboard_controller.dart';
import '../application/admin_order_controller.dart';
import '../application/cash_book_controller.dart';
import '../application/manufacturer_controller.dart';
import '../application/purchase_order_controller.dart';
import '../services/purchase_order_pdf_service.dart';
import '../../orders/data/order_repository_provider.dart';

// Data Imports
import '../data/cash_book_repository.dart';
import '../data/credit_transaction_repository.dart';
import '../data/payment_receipt_repository.dart';
import '../data/payment_cashbook_link_repository.dart';
import '../data/purchase_order_repository_supabase.dart';
import '../../orders/data/order_model.dart' as order_model;

// Domain Imports
import '../domain/credit_transaction.dart';
import '../domain/manufacturer.dart';
import '../domain/purchase_order.dart';
import '../domain/cash_book_entry.dart';

// Widget Imports
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_auth_guard.dart';

class AdminPaymentOutScreen extends ConsumerStatefulWidget {
  final String? manufacturerId;
  final String? customerId;
  final String? purchaseOrderId;
  final PurchaseOrder? purchaseOrder;
  final CreditTransaction? transaction;

  const AdminPaymentOutScreen({
    super.key,
    this.manufacturerId,
    this.customerId,
    this.purchaseOrderId,
    this.purchaseOrder,
    this.transaction,
  });

  @override
  ConsumerState<AdminPaymentOutScreen> createState() =>
      _AdminPaymentOutScreenState();
}

class _AdminPaymentOutScreenState extends ConsumerState<AdminPaymentOutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  PaymentType _selectedPaymentType = PaymentType.cash;
  bool _isSaving = false;
  bool _isLoadingBalance = true;
  double _currentBalance = 0.0;
  String? _selectedManufacturerId;
  String? _selectedCustomerId;
  bool _isManufacturerMode = true;
  order_model.Order? _associatedOrder;
  bool _isLoadingOrder = false;

  // Related Orders for Manufacturer
  List<PurchaseOrder> _relatedOrders = [];
  bool _isLoadingRelatedOrders = false;
  PurchaseOrder? _selectedOrderForPayment;

  @override
  void initState() {
    super.initState();
    _selectedManufacturerId = widget.manufacturerId;
    _selectedCustomerId = widget.customerId;
    _isManufacturerMode =
        widget.manufacturerId != null || widget.purchaseOrderId != null;

    if (widget.customerId != null) {
      _isManufacturerMode = false;
    }

    if (widget.purchaseOrder != null) {
      _selectedOrderForPayment = widget.purchaseOrder;
      _referenceController.text = widget.purchaseOrder!.purchaseNumber;
    }

    // Initialize from transaction if present
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _selectedManufacturerId = t.manufacturerId;
      // If transaction has manufacturerId, it's manufacturer mode
      if (t.manufacturerId != null) {
        _isManufacturerMode = true;
      }

      _paymentAmountController.text = t.amount.toStringAsFixed(2);
      _descriptionController.text = t.description ?? '';
      _referenceController.text = t.referenceNumber ?? '';
      _selectedDate = t.transactionDate;

      // Map PaymentMethod to PaymentType
      if (t.paymentMethod != null) {
        try {
          _selectedPaymentType = PaymentType.values.firstWhere(
            (e) => e.name.toLowerCase() == t.paymentMethod!.name.toLowerCase(),
            orElse: () => PaymentType.other,
          );
        } catch (_) {
          _selectedPaymentType = PaymentType.other;
        }
      }
    } else {
      _referenceController.text = '${DateTime.now().millisecondsSinceEpoch}';
      _paymentAmountController.text = '0.00';
    }

    _paymentAmountController.addListener(() {
      if (mounted) setState(() {});
    });

    if (_selectedManufacturerId != null || _selectedCustomerId != null) {
      Future.microtask(() {
        _loadBalance();
        if (_selectedManufacturerId != null) {
          _loadRelatedOrders(_selectedManufacturerId!);
        }
      });
    } else {
      _isLoadingBalance = false;
    }

    if (widget.purchaseOrderId != null) {
      Future.microtask(() => _loadAssociatedOrder(widget.purchaseOrderId!));
    }
  }

  Future<void> _loadRelatedOrders(String manufacturerId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingRelatedOrders = true;
    });

    try {
      final orders = await ref
          .read(purchaseOrderRepositoryProvider)
          .getPurchaseOrders(manufacturerId: manufacturerId);

      if (mounted) {
        setState(() {
          // Filter for pending or partially paid orders
          if (widget.purchaseOrderId != null) {
            // If specific order ID provided, show and select that order
            // Try matching by ID or purchaseNumber
            final matchingOrders =
                orders
                    .where(
                      (o) =>
                          o.id == widget.purchaseOrderId ||
                          o.purchaseNumber == widget.purchaseOrderId,
                    )
                    .toList();

            if (matchingOrders.isNotEmpty) {
              _relatedOrders = matchingOrders;
              _selectedOrderForPayment = _relatedOrders.first;
              _referenceController.text =
                  _selectedOrderForPayment!.purchaseNumber;

              // Only auto-fill amount if it's a NEW payment, not an EDIT
              if (widget.transaction == null) {
                final balance =
                    _selectedOrderForPayment!.total -
                    _selectedOrderForPayment!.paidAmount;
                _paymentAmountController.text = balance.toStringAsFixed(2);
                _descriptionController.text =
                    'Payment for Order #${_selectedOrderForPayment!.purchaseNumber}';
              }
            } else {
              // If not found by ID/Number, show all unpaid orders
              _relatedOrders =
                  orders.where((o) => o.paidAmount < o.total).toList();
            }
          } else {
            // Check if we can find a linked order from transaction reference
            if (widget.transaction != null &&
                widget.transaction!.referenceNumber != null) {
              try {
                final refNum = widget.transaction!.referenceNumber!;
                final matchedOrder = orders.firstWhere(
                  (o) => o.id == refNum || o.purchaseNumber == refNum,
                );
                _selectedOrderForPayment = matchedOrder;
              } catch (_) {}
            }

            _relatedOrders =
                orders.where((o) => o.paidAmount < o.total).toList();
          }
          _isLoadingRelatedOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRelatedOrders = false;
        });
      }
    }
  }

  Future<void> _loadAssociatedOrder(String orderId) async {
    setState(() {
      _isLoadingOrder = true;
    });
    try {
      if (_isManufacturerMode) {
        final po = await ref
            .read(purchaseOrderControllerProvider.notifier)
            .getPurchaseOrderById(orderId);
        if (mounted && po != null) {
          setState(() {
            _selectedOrderForPayment = po;
            _referenceController.text = po.purchaseNumber;
            _isLoadingOrder = false;
          });
        }
      } else {
        final order = await ref
            .read(orderRepositoryProvider)
            .getOrderById(orderId);
        if (mounted) {
          setState(() {
            _associatedOrder = order;
            _isLoadingOrder = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrder = false;
        });
      }
    }
  }

  Future<void> _loadBalance() async {
    final id =
        _isManufacturerMode ? _selectedManufacturerId : _selectedCustomerId;
    if (id == null) return;

    setState(() {
      _isLoadingBalance = true;
    });

    try {
      if (_isManufacturerMode) {
        final repository = ref.read(creditTransactionRepositoryProvider);
        final balance = await repository.getManufacturerBalance(id);

        if (mounted) {
          setState(() {
            _currentBalance = balance.currentBalance;
            // Outstanding debt is absolute value of negative balance (Manufacturer owes us if positive, we owe them if negative)
            final outstanding =
                balance.currentBalance < 0 ? balance.currentBalance.abs() : 0.0;

            if (widget.transaction != null) {
              final t = widget.transaction!;
              _selectedManufacturerId = t.manufacturerId;
              _isManufacturerMode = t.manufacturerId != null;
              _paymentAmountController.text = t.amount.toStringAsFixed(2);
              _descriptionController.text = t.description ?? '';
              _referenceController.text = t.referenceNumber ?? '';
              _selectedDate = t.transactionDate;

              // Map PaymentMethod to PaymentType
              if (t.paymentMethod != null) {
                try {
                  // Simple name matching since values are similar
                  _selectedPaymentType = PaymentType.values.firstWhere(
                    (e) =>
                        e.name.toLowerCase() ==
                        t.paymentMethod!.name.toLowerCase(),
                    orElse: () => PaymentType.other,
                  );
                } catch (_) {
                  _selectedPaymentType = PaymentType.other;
                }
              }
            } else if (widget.purchaseOrder != null) {
              // final poOutstanding =
              //     widget.purchaseOrder!.total -
              //     widget.purchaseOrder!.paidAmount; // Removed unused variable
              // Remove auto-filling of payment amount
              /*
              if (poOutstanding > 0) {
                _paymentAmountController.text = poOutstanding.toStringAsFixed(
                  2,
                );
              }
              */
            } else if (outstanding > 0) {
              // Remove auto-filling of payment amount
              // _paymentAmountController.text = outstanding.toStringAsFixed(2);
            }
          });
        }
      } else {
        // For Customer, we use adminCustomerController
        final customerState = ref.read(adminCustomerControllerProvider);

        dynamic customer;
        try {
          customer = customerState.customers.firstWhere((c) => c.id == id);
        } catch (_) {
          try {
            customer = customerState.filteredCustomers.firstWhere(
              (c) => c.id == id,
            );
          } catch (_) {}
        }

        if (customer != null && mounted) {
          setState(() {
            _currentBalance = customer.totalBalance;
            // For customers, negative balance means they paid more/we owe them (Refund)
            /*
            final outstanding =
                customer.totalBalance < 0 ? customer.totalBalance.abs() : 0.0;
            if (outstanding > 0) {
              _paymentAmountController.text = outstanding.toStringAsFixed(2);
            }
            */
          });
        }
      }

      // Refresh data
      if (mounted) {
        ref.read(adminCustomerControllerProvider.notifier).refresh();
        ref.read(manufacturerControllerProvider.notifier).loadManufacturers();

        try {
          ref.read(adminDashboardControllerProvider.notifier).refresh();
        } catch (e) {}
      }

      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });

        // Show snackbar if editing to display remaining values
        if (widget.transaction != null) {
          double beforeBalance;
          if (widget.purchaseOrder != null) {
            beforeBalance =
                widget.purchaseOrder!.total -
                widget.purchaseOrder!.paidAmount +
                widget.transaction!.amount;
          } else {
            beforeBalance = _currentBalance - widget.transaction!.amount;
          }

          final displayBalance = beforeBalance.abs();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Remaining Balance: Rs ${displayBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _showPartySelection() {
    final manufacturers =
        ref.read(manufacturerControllerProvider).manufacturers;
    final customers =
        ref
            .read(adminCustomerControllerProvider)
            .filteredCustomers
            .where((c) => !c.isManufacturer)
            .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Select Party',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          if (manufacturers.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Manufacturers',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...manufacturers.map(
                              (m) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.2),
                                  child: Text(
                                    m.businessName.isNotEmpty
                                        ? m.businessName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  m.businessName.isNotEmpty
                                      ? m.businessName
                                      : m.name,
                                ),
                                subtitle: Text('${m.name} • ${m.phone ?? ''}'),
                                trailing: const Icon(Ionicons.business_outline),
                                onTap: () {
                                  setState(() {
                                    _isManufacturerMode = true;
                                    _selectedManufacturerId = m.id;
                                    _selectedCustomerId = null;
                                    _selectedOrderForPayment = null;
                                  });
                                  Navigator.pop(context);
                                  _loadBalance();
                                  _loadRelatedOrders(m.id);
                                },
                              ),
                            ),
                          ],
                          if (customers.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Stores (Customers)',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...customers.map(
                              (c) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                  child: Text(
                                    c.name.isNotEmpty
                                        ? c.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  c.alias != null && c.alias!.isNotEmpty
                                      ? c.alias!
                                      : c.name,
                                ),
                                subtitle: Text('${c.name} • ${c.phone}'),
                                trailing: Text(
                                  'Rs ${c.totalBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color:
                                        c.totalBalance > 0
                                            ? Colors.red
                                            : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _isManufacturerMode = false;
                                    _selectedCustomerId = c.id;
                                    _selectedManufacturerId = null;
                                    _relatedOrders = [];
                                    _selectedOrderForPayment = null;
                                  });
                                  Navigator.pop(context);
                                  _loadBalance();
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manufacturerState = ref.watch(manufacturerControllerProvider);
    final customerState = ref.watch(adminCustomerControllerProvider);
    final adminOrderState = ref.watch(adminOrderControllerProvider);
    Manufacturer? manufacturer;

    // We use dynamic type or a common interface if possible, but for now we'll just fetch separately
    // based on mode to avoid complexity.
    dynamic selectedParty;

    if (_isManufacturerMode && _selectedManufacturerId != null) {
      try {
        manufacturer = manufacturerState.manufacturers.firstWhere(
          (m) => m.id == _selectedManufacturerId,
        );
        selectedParty = manufacturer;
      } catch (_) {}
    } else if (!_isManufacturerMode && _selectedCustomerId != null) {
      try {
        // Try to find in main list first
        selectedParty = customerState.customers.firstWhere(
          (c) => c.id == _selectedCustomerId,
        );
      } catch (_) {
        try {
          // Fallback to filtered list if needed
          selectedParty = customerState.filteredCustomers.firstWhere(
            (c) => c.id == _selectedCustomerId,
          );
        } catch (_) {}
      }
    }

    // Calculate outstanding and display totals
    double outstandingAmount;
    double displaySubtotal;
    double displayGrandTotal;

    if (_selectedOrderForPayment != null) {
      displaySubtotal = _selectedOrderForPayment!.total;
      displayGrandTotal = _selectedOrderForPayment!.total;
      outstandingAmount =
          _selectedOrderForPayment!.total -
          _selectedOrderForPayment!.paidAmount;
      // If editing, add back the transaction amount to show balance before payment
      if (widget.transaction != null) {
        outstandingAmount += widget.transaction!.amount;
      }
    } else if (_associatedOrder != null) {
      // Calculate order total (fallback to items sum if 0)
      double orderTotal = _associatedOrder!.total;
      if (orderTotal == 0 && _associatedOrder!.items.isNotEmpty) {
        orderTotal =
            _associatedOrder!.items.fold(
              0.0,
              (sum, item) => sum + (item.price * item.quantity),
            ) +
            _associatedOrder!.shipping +
            _associatedOrder!.tax;
      }
      displaySubtotal = orderTotal;
      displayGrandTotal = orderTotal;

      final paymentData = adminOrderState.orderPaymentMap[_associatedOrder!.id];
      outstandingAmount = paymentData?.balanceAmount ?? orderTotal;

      // If editing, add back the transaction amount if it was included in paymentData
      if (widget.transaction != null && paymentData != null) {
        outstandingAmount += widget.transaction!.amount;
      }
    } else if (widget.purchaseOrder != null) {
      displaySubtotal = widget.purchaseOrder!.total;
      displayGrandTotal = widget.purchaseOrder!.total;
      outstandingAmount =
          widget.purchaseOrder!.total - widget.purchaseOrder!.paidAmount;
      if (widget.transaction != null) {
        outstandingAmount += widget.transaction!.amount;
      }
    } else {
      // If editing an existing transaction, we need to back out its effect
      // to show the balance "before" this payment.
      // Payment Out (payin) increases the balance (reduces debt).
      // So Balance Before = Current Balance - Transaction Amount.
      if (widget.transaction != null) {
        outstandingAmount = _currentBalance - widget.transaction!.amount;
      } else {
        outstandingAmount = _currentBalance;
      }
      displaySubtotal = outstandingAmount;
      displayGrandTotal = outstandingAmount;
    }

    final paymentAmount = double.tryParse(_paymentAmountController.text) ?? 0.0;

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
            IconButton(
              icon: const Icon(
                Ionicons.settings_outline,
                color: AppColors.textPrimary,
              ),
              onPressed: () {},
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Receipt No. & Date Row
                Row(
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
                          Row(
                            children: [
                              Text(
                                _referenceController.text.isEmpty
                                    ? '-'
                                    : _referenceController.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Color(0xFF5F6368),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Ionicons.chevron_down,
                                size: 16,
                                color: AppColors.outlineMedium,
                              ),
                            ],
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
                      child: InkWell(
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
                            Row(
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Color(0xFF5F6368),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Ionicons.chevron_down,
                                  size: 16,
                                  color: AppColors.outlineMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),

                // 2. Firm Name Card (Our Business)
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
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
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

                // 3. Party Name Card
                InkWell(
                  onTap: _showPartySelection,
                  child: Container(
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
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            if (selectedParty != null)
                              RichText(
                                text: TextSpan(
                                  text: 'Party Balance: ',
                                  style: TextStyle(
                                    color: Color(0xFF5F6368),
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          'Rs ${(outstandingAmount.abs() - paymentAmount).abs().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' You\'ll Get',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedParty != null
                                        ? (selectedParty is Manufacturer
                                            ? (selectedParty
                                                    .businessName
                                                    .isNotEmpty
                                                ? selectedParty.businessName
                                                : selectedParty.name)
                                            : (selectedParty is Customer &&
                                                    selectedParty.alias !=
                                                        null &&
                                                    selectedParty
                                                        .alias!
                                                        .isNotEmpty
                                                ? selectedParty.alias!
                                                : selectedParty.name))
                                        : 'Select Party',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          selectedParty == null
                                              ? AppColors.outlineMedium
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (selectedParty != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedParty is Manufacturer
                                          ? 'Manufacturer: ${selectedParty.name}'
                                          : 'Customer: ${selectedParty.name}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Ionicons.chevron_down, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Phone Number
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outlineSoft),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selectedParty != null &&
                                selectedParty.phone != null &&
                                selectedParty.phone.isNotEmpty == true
                            ? selectedParty.phone!
                            : '-',
                        style: TextStyle(
                          color:
                              selectedParty != null &&
                                      selectedParty.phone != null &&
                                      selectedParty.phone.isNotEmpty == true
                                  ? AppColors.textPrimary
                                  : AppColors.outlineMedium,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Balance Calculation Section
                Container(
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
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: TextFormField(
                              controller: _paymentAmountController,
                              textAlign: TextAlign.right,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Color(0xFF2E7D32), // Green color
                              ),
                              decoration: InputDecoration(
                                prefixText: 'Rs ',
                                prefixStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Color(0xFF2E7D32),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final remaining =
                              outstandingAmount.abs() - paymentAmount;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Remaining Balance',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Rs ${remaining.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF2E7D32), // Green color
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

                // 7. Description Section
                Text(
                  'Description',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineSoft),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'Add Note',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outlineSoft),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Ionicons.image_outline,
                        color: AppColors.outlineMedium,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 8. Payment Type Section
                const Text(
                  'Payment Type*',
                  style: TextStyle(
                    color: Color(0xFF5F6368),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineSoft),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PaymentType>(
                            value: _selectedPaymentType,
                            isExpanded: true,
                            icon: const Icon(Ionicons.chevron_down, size: 20),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF5F6368),
                              fontWeight: FontWeight.w500,
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Ionicons.add,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 9. Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              widget.transaction == null
                                  ? 'Save'
                                  : 'Update Payment',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                if (widget.transaction != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _deleteTransaction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Ionicons.trash_outline,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Delete Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
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

  Widget _buildGroupedItems(BuildContext context, order_model.Order order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Map<String, List<order_model.OrderItem>> groupedItems = {};
    for (final item in order.items) {
      final category = item.category ?? 'Uncategorized';
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    return Column(
      children:
          groupedItems.entries.map((entry) {
            final category = entry.key;
            final items = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...items.asMap().entries.map((itemEntry) {
                  final itemIndex = itemEntry.key;
                  final item = itemEntry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineSoft),
                    ),
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
                                      '#${itemIndex + 1}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
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
                              '${item.quantity} Qty x Rs ${item.price.toStringAsFixed(0)} = Rs ${item.totalPrice.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildPurchaseOrderItems(BuildContext context, PurchaseOrder order) {
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
                // Image
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

                // Details
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
                            '${item.quantity} x ₹${item.unitPrice.toStringAsFixed(0)} = ₹${item.totalPrice.toStringAsFixed(0)}',
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

  Widget _buildPurchasingDetails(PurchaseOrder order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Purchasing Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: order.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Order Items',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.measurementUnit != null)
                          Text(
                            'Unit: ${item.measurementUnit}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${item.quantity} x',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item.totalPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 24, thickness: 1),
          _buildSummaryRow('Subtotal', order.subtotal),
          if (order.tax > 0) _buildSummaryRow('Tax', order.tax),
          if (order.shipping > 0) _buildSummaryRow('Shipping', order.shipping),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'Rs ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Paid So Far', style: TextStyle(fontSize: 12)),
                    Text(
                      '₹${order.paidAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rs ${(order.total - order.paidAmount).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            'Rs ${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Payment'),
            content: const Text(
              'Are you sure you want to delete this payment? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isSaving = true;
      });

      try {
        final repository = ref.read(creditTransactionRepositoryProvider);
        final amountToDelete = widget.transaction!.amount;

        // Determine the order being updated
        final orderToUpdate =
            _selectedOrderForPayment ??
            (widget.purchaseOrder is PurchaseOrder
                ? widget.purchaseOrder as PurchaseOrder
                : null);

        await repository.deleteCreditTransaction(widget.transaction!.id);

        // Update Purchase Order paid amount if linked
        if (orderToUpdate != null) {
          // Invalidate PDF cache
          PurchaseOrderPdfService.clearCache(purchaseOrderId: orderToUpdate.id);

          final updatedPO = orderToUpdate.copyWith(
            paidAmount: orderToUpdate.paidAmount - amountToDelete,
          );

          ref
              .read(purchaseOrderControllerProvider.notifier)
              .updatePurchaseOrder(updatedPO, skipSyncCredit: true);
        }

        // Refresh cashbook totals and customer balance
        ref.read(cashBookControllerProvider.notifier).refresh();
        try {
          ref.read(adminCustomerControllerProvider.notifier).refresh();
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _savePayment() async {
    print('💰 _savePayment called');

    if (_isSaving) {
      print('⚠️ Already saving, ignoring request');
      return;
    }

    if (_isLoadingBalance) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for balance to load...'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isManufacturerMode && _selectedManufacturerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a manufacturer first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isManufacturerMode && _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a store (customer) first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final amountStr = _paymentAmountController.text.trim();
      final amount = double.tryParse(amountStr) ?? 0.0;

      if (amount <= 0) {
        print('❌ Amount is <= 0: $amount');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment amount must be greater than zero'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;

      if (user == null) throw Exception('User not authenticated');

      // For Payment-Out screen, we are always paying out.
      const transactionDescription = 'Payment Out';
      const cashBookType = CashBookEntryType.payout;

      if (_isManufacturerMode) {
        const transactionType =
            CreditTransactionType.payin; // Admin pays manufacturer

        // Determine the order being updated
        final orderToUpdate =
            _selectedOrderForPayment ??
            (widget.purchaseOrder is PurchaseOrder
                ? widget.purchaseOrder as PurchaseOrder
                : null);

        if (widget.transaction != null) {
          // Update existing transaction
          final oldAmount = widget.transaction!.amount;
          final updatedTransaction = widget.transaction!.copyWith(
            amount: amount,
            description:
                _descriptionController.text.isNotEmpty
                    ? _descriptionController.text
                    : transactionDescription,
            referenceNumber: _referenceController.text,
            paymentMethod: _selectedPaymentType.toPaymentMethod(),
            transactionDate: _selectedDate,
          );

          await ref
              .read(creditTransactionRepositoryProvider)
              .updateCreditTransaction(updatedTransaction);

          // Update Purchase Order paid amount if linked
          if (orderToUpdate != null) {
            final diff = amount - oldAmount;
            if (diff != 0) {
              // Invalidate PDF cache
              PurchaseOrderPdfService.clearCache(
                purchaseOrderId: orderToUpdate.id,
              );

              final updatedPO = orderToUpdate.copyWith(
                paidAmount: orderToUpdate.paidAmount + diff,
              );

              ref
                  .read(purchaseOrderControllerProvider.notifier)
                  .updatePurchaseOrder(updatedPO, skipSyncCredit: true);
            }
          }

          // Update Cash Book entry if it exists
          try {
            final cashBookRepo = ref.read(cashBookRepositoryProvider);
            final entries = await cashBookRepo.getEntries();
            // Find the entry that matches this transaction's ID or description/date/amount
            final matchingEntry = entries.cast<CashBookEntry?>().firstWhere(
              (e) =>
                  e != null &&
                  e.relatedId == _selectedManufacturerId &&
                  e.amount == oldAmount &&
                  e.date.day == widget.transaction!.transactionDate.day &&
                  e.date.month == widget.transaction!.transactionDate.month,
              orElse: () => null,
            );

            if (matchingEntry != null) {
              final updatedEntry = matchingEntry.copyWith(
                amount: amount,
                description:
                    updatedTransaction.description ?? matchingEntry.description,
                date: updatedTransaction.transactionDate,
                paymentMethod: _selectedPaymentType.dbValue,
              );
              cashBookRepo.updateEntry(
                matchingEntry.id!,
                updatedEntry.toJson()..remove('id'),
                relatedId: updatedEntry.relatedId,
              );
            }
          } catch (e) {
            debugPrint('Could not update matching cash book entry: $e');
          }
        } else {
          // Create new transaction

          // 1. Create Credit Transaction
          final newTransaction = await ref
              .read(creditTransactionRepositoryProvider)
              .createCreditTransaction(
                manufacturerId: _selectedManufacturerId!,
                transactionType: transactionType,
                amount: amount,
                createdBy: user.id,
                description:
                    _descriptionController.text.isNotEmpty
                        ? _descriptionController.text
                        : '$transactionDescription${orderToUpdate != null ? " for PO #${orderToUpdate.purchaseNumber}" : ""}',
                referenceNumber:
                    orderToUpdate?.purchaseNumber ?? _referenceController.text,
                paymentMethod: _selectedPaymentType.toPaymentMethod(),
                transactionDate: _selectedDate,
              );

          // 2. If Purchase Order exists, update paid amount
          if (orderToUpdate != null) {
            // Invalidate PDF cache before updating to ensure next generation uses new data
            PurchaseOrderPdfService.clearCache(
              purchaseOrderId: orderToUpdate.id,
            );

            final updatedPO = orderToUpdate.copyWith(
              paidAmount: orderToUpdate.paidAmount + amount,
            );

            ref
                .read(purchaseOrderControllerProvider.notifier)
                .updatePurchaseOrder(updatedPO, skipSyncCredit: true);
          }

          // 3. Record in Cash Book
          debugPrint('DEBUG: Starting cashbook entry creation for amount: $amount, manufacturerId: $_selectedManufacturerId');
          try {
            // Use cashBookController.addEntry which handles refresh automatically
            await ref
                .read(cashBookControllerProvider.notifier)
                .addEntry(
                  CashBookEntry(
                    amount: amount,
                    type: cashBookType,
                    category: 'Manufacturer Payment',
                    description:
                        _descriptionController.text.isNotEmpty
                            ? _descriptionController.text
                            : '$transactionDescription${_selectedOrderForPayment != null ? " for PO #${_selectedOrderForPayment!.purchaseNumber}" : (widget.purchaseOrder != null ? " for PO #${widget.purchaseOrder!.purchaseNumber}" : "")}',
                    date: _selectedDate,
                    relatedId: _selectedManufacturerId!,
                    referenceId: newTransaction.id,
                    referenceType: 'payment_out',
                    paymentMethod: _selectedPaymentType.dbValue,
                    createdBy: user.id,
                  ),
                );
            debugPrint('DEBUG: Cashbook entry created successfully');

            // Refresh cashbook and dashboard after saving
            try {
              debugPrint('DEBUG: About to refresh cashbook controller');
              ref.read(cashBookControllerProvider.notifier).refresh();
              debugPrint('DEBUG: About to refresh dashboard controller');
              ref.read(adminDashboardControllerProvider.notifier).refresh();
              debugPrint('DEBUG: Both controllers refreshed');
            } catch (e) {
              debugPrint('DEBUG: Error refreshing cashbook/dashboard: $e');
            }

            // Final success message
            debugPrint('DEBUG: Payment save flow completed successfully');
          } catch (e) {
            debugPrint('DEBUG: Error adding to cash book: $e');
            // Show error to user - don't silently swallow
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving to cash book: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        // Customer Mode
        // We are paying money -> Receipt with REFUND prefix (which backend treats as balance increase).
        final finalAmount = amount;

        String description =
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : transactionDescription;

        // Enforce REFUND prefix for payouts so backend calculates balance correctly
        // In Payment-Out screen, this is always a "refund" of value to the customer (increasing balance)
        if (!description.startsWith('REFUND:')) {
          description = 'REFUND: $description';
        }

        await ref
            .read(paymentReceiptRepositoryProvider)
            .createPaymentReceipt(
              customerId: _selectedCustomerId!,
              receiptNumber: _referenceController.text,
              paymentDate: _selectedDate,
              amount: finalAmount,
              paymentType: _selectedPaymentType.dbValue,
              description: description,
              createdBy: user.id,
            );

        // Refresh cashbook after customer payment
        try {
          ref.read(cashBookControllerProvider.notifier).refresh();
        } catch (e) {
          debugPrint('Error refreshing cashbook after customer payment: $e');
        }
      }

      // Refresh data (fire and forget)
      if (mounted) {
        if (_isManufacturerMode) {
          ref
              .read(manufacturerControllerProvider.notifier)
              .loadManufacturers()
              .catchError((e) => debugPrint('Error loading manufacturers: $e'));
        } else {
          ref
              .read(adminCustomerControllerProvider.notifier)
              .refresh()
              .catchError((e) => debugPrint('Error refreshing customers: $e'));
        }

        ref
            .read(adminDashboardControllerProvider.notifier)
            .refresh()
            .catchError((e) => debugPrint('Error refreshing dashboard: $e'));
      }

      if (mounted) {
        // Calculate remaining balance for snackbar
        double outstandingAmount = 0.0;
        if (_selectedOrderForPayment != null) {
          outstandingAmount =
              _selectedOrderForPayment!.total -
              _selectedOrderForPayment!.paidAmount;
          if (widget.transaction != null) {
            outstandingAmount += widget.transaction!.amount;
          }
        } else if (_associatedOrder != null) {
          final paymentData =
              ref
                  .read(adminOrderControllerProvider)
                  .orderPaymentMap[_associatedOrder!.id];
          outstandingAmount =
              paymentData?.balanceAmount ?? _associatedOrder!.total;
          if (widget.transaction != null && paymentData != null) {
            outstandingAmount += widget.transaction!.amount;
          }
        } else if (widget.purchaseOrder != null) {
          outstandingAmount =
              widget.purchaseOrder!.total - widget.purchaseOrder!.paidAmount;
          if (widget.transaction != null) {
            outstandingAmount += widget.transaction!.amount;
          }
        } else {
          outstandingAmount =
              widget.transaction != null
                  ? _currentBalance - widget.transaction!.amount
                  : _currentBalance;
        }

        final remaining = outstandingAmount.abs() - amount;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining Balance: ₹ ${remaining.abs().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${widget.transaction == null ? "Payment saved" : "Payment updated"} successfully',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Check for specific Supabase Auth server mismatch error
        if (errorMessage.contains('oauth_client_id') &&
            errorMessage.contains('models.Session')) {
          errorMessage =
              'Server Configuration Error: The authentication server version is incompatible with the database schema. Please contact support to resolve the Supabase Auth version mismatch.';
        } else if (errorMessage.contains('AuthRetryableFetchException')) {
          errorMessage =
              'Authentication Error: Please check your internet connection or try logging in again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Error Details'),
                        content: SingleChildScrollView(
                          child: Text(e.toString()),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

extension PaymentTypeToMethod on PaymentType {
  PaymentMethod toPaymentMethod() {
    switch (this) {
      case PaymentType.cash:
        return PaymentMethod.cash;
      case PaymentType.bankTransfer:
        return PaymentMethod.bankTransfer;
      case PaymentType.cheque:
        return PaymentMethod.cheque;
      case PaymentType.upi:
        return PaymentMethod.upi;
      case PaymentType.creditCard:
      case PaymentType.other:
        return PaymentMethod.other;
    }
  }
}

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
