import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_out_pdf_service.dart';
import '../domain/manufacturer.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/layout/responsive.dart';
import '../data/credit_transaction_repository.dart';
import '../data/purchase_order_repository_supabase.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/credit_transaction.dart';
import '../domain/purchase_order.dart';
import '../application/manufacturer_controller.dart';
import '../application/purchase_order_controller.dart';
import '../application/cash_book_controller.dart';
import 'widgets/admin_auth_guard.dart';

class _TransactionItem {
  final DateTime date;
  final String title;
  final double amount;
  final String? reference;
  final String? status;
  final Color? statusColor;
  final dynamic originalObject;
  final bool isPurchase;
  final double? balanceAfter;

  _TransactionItem({
    required this.date,
    required this.title,
    required this.amount,
    this.reference,
    this.status,
    this.statusColor,
    required this.originalObject,
    required this.isPurchase,
    this.balanceAfter,
  });
}

class AdminPaymentOutListScreen extends ConsumerStatefulWidget {
  final String? manufacturerId;

  const AdminPaymentOutListScreen({super.key, this.manufacturerId});

  @override
  ConsumerState<AdminPaymentOutListScreen> createState() =>
      _AdminPaymentOutListScreenState();
}

class _AdminPaymentOutListScreenState
    extends ConsumerState<AdminPaymentOutListScreen> {
  final _searchController = TextEditingController();
  List<_TransactionItem> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _manufacturerName;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadTransactions());
    PaymentOutPdfService.preloadLogo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseClient = ref.read(supabaseClientProvider);
      final creditRepo = CreditTransactionRepository(supabaseClient);
      final purchaseRepo = PurchaseOrderRepositorySupabase(supabaseClient);

      // Ensure manufacturers are loaded
      await ref
          .read(manufacturerControllerProvider.notifier)
          .loadManufacturers();

      if (!mounted) return;

      final manufacturers =
          ref.read(manufacturerControllerProvider).manufacturers;
      final manufacturerMap = {
        for (var m in manufacturers) m.id: m.businessName,
      };

      if (widget.manufacturerId != null) {
        _manufacturerName = manufacturerMap[widget.manufacturerId];
      }

      List<CreditTransaction> manufacturerTransactions;
      List<PurchaseOrder> purchaseOrders;

      if (widget.manufacturerId != null) {
        manufacturerTransactions = await creditRepo.getCreditTransactions(
          manufacturerId: widget.manufacturerId,
          limit: 100,
        );
        purchaseOrders = await purchaseRepo.getPurchaseOrders(
          manufacturerId: widget.manufacturerId,
          limit: 100,
        );
      } else {
        // Fetch only manufacturer related transactions and orders from database
        manufacturerTransactions = await creditRepo.getCreditTransactions(
          onlyManufacturers: true,
          limit: 100,
        );
        purchaseOrders = await purchaseRepo.getPurchaseOrders(
          onlyManufacturers: true,
          limit: 100,
        );
      }

      if (!mounted) return;

      // Optimization: Prefetch Purchase Orders for these transactions
      // This ensures that when user clicks "Print", the data is likely already in cache
      final purchaseNumbersToPrefetch =
          manufacturerTransactions
              .map((t) => t.referenceNumber)
              .where((ref) => ref != null && ref.isNotEmpty)
              .cast<String>()
              .toList();

      if (purchaseNumbersToPrefetch.isNotEmpty) {
        // Fire and forget prefetching
        ref
            .read(purchaseOrderControllerProvider.notifier)
            .prefetchPurchaseOrders(purchaseNumbersToPrefetch);
      }

      final List<_TransactionItem> items = [];

      // Process Credit Transactions
      for (var t in manufacturerTransactions) {
        // Hide Payment In (Payout) from Manufacturer view as requested
        if (t.transactionType == CreditTransactionType.payout) {
          continue;
        }

        String statusLabel;
        Color statusColor;

        switch (t.transactionType) {
          case CreditTransactionType.payin:
            statusLabel = 'Payment Out';
            statusColor = Colors.red;
            break;
          case CreditTransactionType.payout:
            statusLabel = 'Payment In';
            statusColor = Colors.green;
            break;
          case CreditTransactionType.purchase:
            statusLabel = 'Purchase';
            statusColor = Colors.orange;
            break;
        }

        items.add(
          _TransactionItem(
            date: t.transactionDate,
            title: t.displayName,
            amount: t.amount,
            reference: t.referenceNumber,
            status: statusLabel,
            statusColor: statusColor,
            originalObject: t,
            isPurchase: false,
            balanceAfter: t.balanceAfter,
          ),
        );
      }

      // Process Purchase Orders
      for (var po in purchaseOrders) {
        final manufacturerName =
            manufacturerMap[po.manufacturerId] ?? 'Unknown Manufacturer';

        // Use createdAt for time if purchaseDate is midnight (likely due to DB truncation)
        DateTime displayDate = po.purchaseDate;
        if (displayDate.hour == 0 &&
            displayDate.minute == 0 &&
            displayDate.second == 0) {
          final createdAtLocal = po.createdAt.toLocal();
          // Combine purchaseDate date with createdAt time to show meaningful time
          displayDate = DateTime(
            displayDate.year,
            displayDate.month,
            displayDate.day,
            createdAtLocal.hour,
            createdAtLocal.minute,
            createdAtLocal.second,
          );
        }

        items.add(
          _TransactionItem(
            date: displayDate,
            title: manufacturerName,
            amount: po.total,
            reference: po.purchaseNumber,
            status: po.status.displayName,
            statusColor: po.status.color,
            originalObject: po,
            isPurchase: true,
          ),
        );
      }

      // Sort by date descending
      items.sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;

        // Tie-breaker: if same date and same reference, put payment on top of purchase
        if (a.reference == b.reference && a.reference != null) {
          if (!a.isPurchase && b.isPurchase) return -1;
          if (a.isPurchase && !b.isPurchase) return 1;
        }
        return 0;
      });

      if (mounted) {
        setState(() {
          _transactions = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  List<_TransactionItem> get _filteredTransactions {
    if (_searchController.text.isEmpty) {
      return _transactions;
    }
    final query = _searchController.text.toLowerCase();
    return _transactions.where((t) {
      final name = t.title.toLowerCase();
      final ref = t.reference?.toLowerCase() ?? '';
      return name.contains(query) || ref.contains(query);
    }).toList();
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final transactions = _filteredTransactions;
    // final font = await PdfGoogleFonts.nunitoExtraLight();
    final font = pw.Font.helvetica(); // Use standard PDF font
    final title =
        _manufacturerName != null
            ? 'Transactions: $_manufacturerName'
            : 'Manufacturer Transactions Report';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(title, style: pw.TextStyle(fontSize: 24, font: font)),
                  pw.Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: pw.TextStyle(font: font),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                font: font,
              ),
              cellStyle: pw.TextStyle(font: font),
              headers: <String>[
                'Date',
                'Manufacturer',
                'Type',
                'Reference',
                'Amount',
              ],
              data:
                  transactions.map((t) {
                    return [
                      DateFormat('dd/MM/yyyy').format(t.date),
                      t.title,
                      t.status ?? '-',
                      t.reference ?? '-',
                      'Rs. ${t.amount.toStringAsFixed(2)}',
                    ];
                  }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total: Rs. ${transactions.fold<double>(0, (sum, t) => sum + t.amount).toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    font: font,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<Uint8List> _generateSingleTransactionPdf(
    _TransactionItem transaction,
  ) async {
    final ct = transaction.originalObject as CreditTransaction;
    final refNo = ct.referenceNumber;
    if (refNo == null || refNo.isEmpty) {
      throw Exception('Missing Purchase Order reference number');
    }

    // Resolve linked Purchase Order (required for PO-style PDF)
    // Use controller to benefit from cache
    final controller = ref.read(purchaseOrderControllerProvider.notifier);

    // Try by purchase number first (most common)
    PurchaseOrder? linkedPO = await controller.getPurchaseOrderByNumber(refNo);

    // If not found, check if refNo is a valid UUID before trying to fetch by ID
    // This prevents wasted network calls for non-UUID reference numbers (e.g. "PO-123")
    if (linkedPO == null) {
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(refNo);
      if (isUuid) {
        linkedPO = await controller.getPurchaseOrderById(refNo);
        if (!mounted) throw Exception('Widget disposed');
      }
    }

    if (linkedPO == null) {
      throw Exception('Purchase Order not found for Ref No: $refNo');
    }

    final manufacturers =
        ref.read(manufacturerControllerProvider).manufacturers;
    Manufacturer? manufacturer;
    try {
      manufacturer = manufacturers.firstWhere((m) => m.id == ct.manufacturerId);
    } catch (_) {}
    final paidTo = PaidToInfo(
      name: manufacturer?.businessName ?? _manufacturerName ?? 'Unknown',
      address: manufacturer?.businessAddress,
      phone: manufacturer?.phone,
      gstNumber: manufacturer?.gstNumber,
    );
    return PaymentOutPdfService.generatePaymentOutPdf(
      transaction: ct,
      paidTo: paidTo,
      linkedPO: linkedPO,
    );
  }

  Future<void> _printTransaction(_TransactionItem transaction) async {
    try {
      final data = await _generateSingleTransactionPdf(transaction);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => data,
        name: 'PO_${transaction.reference ?? "Receipt"}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error printing: $e')));
      }
    }
  }

  Future<void> _shareTransaction(_TransactionItem transaction) async {
    try {
      final data = await _generateSingleTransactionPdf(transaction);
      await Printing.sharePdf(
        bytes: data,
        filename: 'PO_${transaction.reference ?? "Receipt"}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  Future<void> _deleteTransaction(_TransactionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: Text(
              'Are you sure you want to delete this ${item.status}? This action cannot be undone.',
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
      setState(() {
        _isLoading = true;
      });

      try {
        final ct = item.originalObject as CreditTransaction;

        // Try to find the linked purchase order if it exists
        if (ct.referenceNumber != null && ct.referenceNumber!.isNotEmpty) {
          final supabaseClient = ref.read(supabaseClientProvider);
          final purchaseRepo = PurchaseOrderRepositorySupabase(supabaseClient);
          final linkedPO =
              await purchaseRepo.getPurchaseOrderByNumber(
                ct.referenceNumber!,
              ) ??
              await purchaseRepo.getPurchaseOrderById(ct.referenceNumber!);

          if (linkedPO != null) {
            // Update Purchase Order paid amount
            final updatedPO = linkedPO.copyWith(
              paidAmount: linkedPO.paidAmount - ct.amount,
            );

            await ref
                .read(purchaseOrderControllerProvider.notifier)
                .updatePurchaseOrder(updatedPO, skipSyncCredit: true);

            if (!mounted) return;
          }
        }

        await ref
            .read(creditTransactionRepositoryProvider)
            .deleteCreditTransaction(ct.id);

        // Refresh cashbook totals
        ref.read(cashBookControllerProvider.notifier).refresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
          _loadTransactions();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final title =
        _manufacturerName != null
            ? 'Transactions: $_manufacturerName'
            : 'Manufacturer Transactions';

    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/picklemart.png',
                height: 32,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Ionicons.print_outline),
              onPressed: filtered.isEmpty ? null : _generatePdf,
              tooltip: 'Download PDF',
            ),
            IconButton(
              icon: const Icon(Ionicons.refresh_outline),
              onPressed: _loadTransactions,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by manufacturer or reference...',
                  prefixIcon: const Icon(Ionicons.search_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(child: Text('Error: $_errorMessage'))
                      : filtered.isEmpty
                      ? const Center(child: Text('No transactions found'))
                      : ListView.builder(
                        itemCount: filtered.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final transaction = filtered[index];
                          return _buildTransactionCard(context, transaction);
                        },
                      ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context
                .pushNamed(
                  'admin-payment-out',
                  extra: {
                    if (widget.manufacturerId != null)
                      'manufacturerId': widget.manufacturerId!,
                  },
                )
                .then((_) => _loadTransactions());
          },
          label: const Text('Payment Out'),
          icon: const Icon(Ionicons.cash_outline),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    _TransactionItem transaction,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isUltraCompact = Responsive.isUltraCompactDevice(width);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            transaction.isPurchase
                ? () {
                  final po = transaction.originalObject as PurchaseOrder;
                  context.pushNamed(
                    'admin-purchase-order-detail',
                    pathParameters: {'id': po.id},
                  );
                }
                : (!transaction.isPurchase &&
                    transaction.status == 'Payment Out')
                ? () {
                  final ct = transaction.originalObject as CreditTransaction;
                  context
                      .pushNamed(
                        'admin-payment-out-detail',
                        extra: {
                          if (widget.manufacturerId != null)
                            'manufacturerId': widget.manufacturerId!,
                          'transaction': ct,
                        },
                      )
                      .then((saved) {
                        if (saved == true) {
                          _loadTransactions();
                        }
                      });
                }
                : null,
        child: Padding(
          padding: EdgeInsets.all(isUltraCompact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM, yy • hh:mm a').format(transaction.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (transaction.reference != null)
                          Text(
                            'Ref: ${transaction.reference}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (transaction.statusColor ?? Colors.grey)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            transaction.status ?? 'Unknown',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: transaction.statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs ${transaction.amount.toStringAsFixed(2)}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              transaction.isPurchase
                                  ? Colors.black
                                  : Colors.red,
                        ),
                      ),
                      if (transaction.balanceAfter != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Bal: Rs ${transaction.balanceAfter!.abs().toStringAsFixed(2)}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (!transaction.isPurchase &&
                  transaction.status == 'Payment Out') ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _printTransaction(transaction),
                      icon: const Icon(Ionicons.print_outline, size: 20),
                      tooltip: 'Print',
                    ),
                    IconButton(
                      onPressed: () => _shareTransaction(transaction),
                      icon: const Icon(Ionicons.share_social_outline, size: 20),
                      tooltip: 'Share',
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          final ct =
                              transaction.originalObject as CreditTransaction;

                          // Try to find the linked purchase order if it exists
                          PurchaseOrder? linkedPO;
                          if (ct.referenceNumber != null &&
                              ct.referenceNumber!.isNotEmpty) {
                            // We can't await here easily without making the whole thing async
                            // But we can fetch it in the screen or pass a function to fetch it
                          }

                          context
                              .pushNamed(
                                'admin-payment-out',
                                extra: {
                                  if (widget.manufacturerId != null)
                                    'manufacturerId': widget.manufacturerId!,
                                  'transaction': ct,
                                  // Passing the purchase number as reference if it looks like one
                                  if (ct.referenceNumber != null &&
                                      ct.referenceNumber!.startsWith('PO'))
                                    'purchaseOrderId': ct.referenceNumber,
                                },
                              )
                              .then((saved) {
                                if (saved == true) {
                                  _loadTransactions();
                                }
                              });
                        } else if (value == 'delete') {
                          _deleteTransaction(transaction);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Ionicons.create_outline, size: 18),
                                  SizedBox(width: 8),
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
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      icon: const Icon(Icons.more_vert, size: 20),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
