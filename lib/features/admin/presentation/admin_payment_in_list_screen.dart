import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../data/payment_receipt_pdf_service.dart';
import '../../../core/layout/responsive.dart';
import '../data/payment_receipt_repository.dart' as repo;
import 'admin_payment_receipt_screen.dart';
import 'widgets/admin_auth_guard.dart';
// For _showPartySelectionDialog logic if I can reuse it or I'll implement similar

class AdminPaymentInListScreen extends ConsumerStatefulWidget {
  const AdminPaymentInListScreen({super.key});

  @override
  ConsumerState<AdminPaymentInListScreen> createState() =>
      _AdminPaymentInListScreenState();
}

class _AdminPaymentInListScreenState
    extends ConsumerState<AdminPaymentInListScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<repo.PaymentReceipt> _receipts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  static const int _limit = 20;
  bool _hasMore = true;
  String? _errorMessage;

  ThemeData get theme => Theme.of(context);

  @override
  void initState() {
    super.initState();
    _loadReceipts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreReceipts();
    }
  }

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _receipts = [];
      _hasMore = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(repo.paymentReceiptRepositoryProvider);
      final receipts = await repository.getAllPaymentReceipts(
        page: 1,
        limit: _limit,
        searchQuery:
            _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _receipts = receipts;
          _isLoading = false;
          _hasMore = receipts.length >= _limit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading receipts: $e')));
      }
    }
  }

  Future<void> _loadMoreReceipts() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final repository = ref.read(repo.paymentReceiptRepositoryProvider);
      final receipts = await repository.getAllPaymentReceipts(
        page: _currentPage + 1,
        limit: _limit,
        searchQuery:
            _searchController.text.trim().isEmpty
                ? null
                : _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _receipts.addAll(receipts);
          _currentPage++;
          _isLoadingMore = false;
          _hasMore = receipts.length >= _limit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment-In Transactions'),
          actions: [
            IconButton(
              icon: const Icon(Ionicons.refresh_outline),
              onPressed: _loadReceipts,
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
                  hintText: 'Search by receipt number...',
                  prefixIcon: const Icon(Ionicons.search_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _loadReceipts(),
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Ionicons.alert_circle_outline,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                              ),
                              child: Text(
                                'Error: $_errorMessage',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadReceipts,
                              icon: const Icon(Ionicons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                      : _receipts.isEmpty
                      ? const Center(child: Text('No payment receipts found'))
                      : RefreshIndicator(
                        onRefresh: _loadReceipts,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            bottom: 16,
                          ), // Standard bottom padding
                          itemCount:
                              _receipts.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index == _receipts.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final receipt = _receipts[index];
                            return _buildPaymentReceiptCard(
                              context,
                              receipt,
                              16.0,
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await context.pushNamed('admin-add-payment');
            if (result == true) {
              _loadReceipts();
            }
          },
          icon: const Icon(Ionicons.add_outline),
          label: const Text('Add Payment'),
        ),
      ),
    );
  }

  Widget _buildPaymentReceiptCard(
    BuildContext context,
    repo.PaymentReceipt receipt,
    double spacing,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isUltraCompact = Responsive.isUltraCompactDevice(width);
    final isFoldable = Responsive.isFoldableMobile(width);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Find PaymentType enum value from string
    PaymentType paymentType;
    try {
      paymentType = PaymentType.values.firstWhere(
        (e) => e.name == receipt.paymentType,
        orElse: () => PaymentType.cash,
      );
    } catch (_) {
      paymentType = PaymentType.cash;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          context.pushNamed('admin-payment-receipt-detail', extra: receipt);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Top Section: Info & Status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receipt No.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            receipt.receiptNumber,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Date',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(receipt.paymentDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              receipt.customerName ?? 'Unknown',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'PAYMENT IN',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Middle Section: Order Reference if available
            if (receipt.orderNumber != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                    bottom: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Ionicons.receipt_outline,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Order #${receipt.orderNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Section: Amount & Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount Paid',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rs ${receipt.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          paymentType.displayName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Ionicons.ellipsis_vertical),
                        onPressed: () => _showMoreOptions(context, receipt),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surface,
                          side: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, repo.PaymentReceipt receipt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Ionicons.print_outline),
                  title: const Text('Print Receipt'),
                  trailing: const Icon(
                    Ionicons.chevron_forward_outline,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _printReceipt(receipt);
                  },
                ),
                ListTile(
                  leading: const Icon(Ionicons.share_social_outline),
                  title: const Text('Share Receipt'),
                  trailing: const Icon(
                    Ionicons.chevron_forward_outline,
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _shareReceipt(receipt);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Future<void> _printReceipt(repo.PaymentReceipt receipt) async {
    try {
      final pdfService = PaymentReceiptPdfService(ref);
      final pdfBytes = await pdfService.getPaymentReceiptPdfBytes(receipt);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Receipt_${receipt.receiptNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error printing receipt: $e')));
      }
    }
  }

  Future<void> _shareReceipt(repo.PaymentReceipt receipt) async {
    try {
      final pdfService = PaymentReceiptPdfService(ref);
      final pdfBytes = await pdfService.getPaymentReceiptPdfBytes(receipt);

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Receipt_${receipt.receiptNumber}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing receipt: $e')));
      }
    }
  }
}
