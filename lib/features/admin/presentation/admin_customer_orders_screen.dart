import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../../orders/data/order_model.dart';
import '../application/admin_order_controller.dart';
import '../application/admin_customer_controller.dart';
import '../application/purchase_order_controller.dart';
import '../application/manufacturer_controller.dart';
import '../application/cash_book_controller.dart';
import '../data/payment_receipt_repository.dart';
import '../data/credit_transaction_repository.dart';
import '../domain/purchase_order.dart';
import '../domain/manufacturer.dart';
import '../domain/credit_transaction.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_action_bottom_bar.dart';
import '../../../core/utils/debouncer.dart';
import '../../orders/services/order_print_service.dart';
import '../../orders/services/order_share_service.dart';
import '../services/purchase_order_pdf_service.dart';
import '../data/payment_receipt_pdf_service.dart';
import '../data/payment_out_pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';

class PurchasePayment {
  final PurchaseOrder purchaseOrder;
  PurchasePayment(this.purchaseOrder);

  String get purchaseNumber => purchaseOrder.purchaseNumber;
  DateTime get purchaseDate => purchaseOrder.purchaseDate;
  double get paidAmount => purchaseOrder.paidAmount;
  double get balance => purchaseOrder.balance;
}

enum TransactionSortOrder {
  latest('Latest Activity'),
  oldest('Oldest Activity'),
  balanceHigh('High Balance'),
  balanceLow('Low Balance'),
  amountHigh('High Amount'),
  amountLow('Low Amount');

  final String label;
  const TransactionSortOrder(this.label);
}

class AdminCustomerOrdersScreen extends ConsumerStatefulWidget {
  final String customerId;

  const AdminCustomerOrdersScreen({super.key, required this.customerId});

  @override
  ConsumerState<AdminCustomerOrdersScreen> createState() =>
      _AdminCustomerOrdersScreenState();
}

class _AdminCustomerOrdersScreenState
    extends ConsumerState<AdminCustomerOrdersScreen> {
  final _searchController = TextEditingController();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  final bool _isInitialized = false;
  bool _isSharing = false;
  TransactionSortOrder? _sortOrder;
  List<CreditTransaction> _creditTransactions = [];

  TransactionSortOrder get currentSortOrder =>
      _sortOrder ?? TransactionSortOrder.latest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Clear any existing search query first to prevent interference
      ref.read(adminOrderControllerProvider.notifier).searchOrders('');

      // Await initialization to ensure orders are loaded before filtering
      await ref.read(adminOrderControllerProvider.notifier).initialize();

      // Now filter by customer after orders are loaded
      ref
          .read(adminOrderControllerProvider.notifier)
          .filterByCustomer(widget.customerId);

      // Check if customer is manufacturer
      final customerState = ref.read(adminCustomerControllerProvider);
      final manufacturerState = ref.read(manufacturerControllerProvider);

      final customer =
          customerState.customers
              .followedBy(customerState.filteredCustomers)
              .where((c) => c.id == widget.customerId)
              .firstOrNull;

      final isManufacturer =
          (customer != null && customer.isManufacturer) ||
          manufacturerState.manufacturers.any((m) => m.id == widget.customerId);

      if (isManufacturer) {
        ref
            .read(purchaseOrderControllerProvider.notifier)
            .setEntityFilter(
              manufacturerId: widget.customerId,
              customerId: null,
            );
        _loadCreditTransactions(widget.customerId);
      } else {
        ref
            .read(purchaseOrderControllerProvider.notifier)
            .setEntityFilter(
              customerId: widget.customerId,
              manufacturerId: null,
            );
      }

      ref.read(manufacturerControllerProvider.notifier).loadManufacturers();

      // Preload PDF logos so first share/print does not wait on asset load
      PurchaseOrderPdfService.preloadLogo();
      PaymentOutPdfService.preloadLogo();
    });
  }

  Future<void> _loadCreditTransactions(String manufacturerId) async {
    try {
      final supabaseClient = ref.read(supabaseClientProvider);
      final repository = CreditTransactionRepository(supabaseClient);
      final transactions = await repository.getCreditTransactions(
        manufacturerId: manufacturerId,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _creditTransactions = transactions;
        });
        // Preload linked POs for Payment Out so share/print finds them in cache
        final poState = ref.read(purchaseOrderControllerProvider);
        final existingNumbers = {
          ...poState.purchaseOrders.map((po) => po.purchaseNumber),
          ...poState.filteredPurchaseOrders.map((po) => po.purchaseNumber),
        };
        final refNumbers =
            transactions
                .where(
                  (t) =>
                      t.transactionType == CreditTransactionType.payin &&
                      t.referenceNumber != null &&
                      t.referenceNumber!.isNotEmpty,
                )
                .map((t) => t.referenceNumber!)
                .toSet();
        final toFetch = refNumbers.where(
          (refNo) => !existingNumbers.contains(refNo),
        );
        final notifier = ref.read(purchaseOrderControllerProvider.notifier);
        for (final refNo in toFetch) {
          notifier.getPurchaseOrderByNumber(refNo);
        }
      }
    } catch (e) {
      debugPrint('Error loading credit transactions: $e');
    }
  }

  void _refreshAll() {
    if (!mounted) return;

    // Refresh controllers
    ref.read(adminOrderControllerProvider.notifier).refresh();
    ref.read(adminCustomerControllerProvider.notifier).refresh();
    ref.read(purchaseOrderControllerProvider.notifier).refresh();
    ref.read(manufacturerControllerProvider.notifier).loadManufacturers();
    ref.read(cashBookControllerProvider.notifier).refresh();

    // Reload credit transactions if it's a manufacturer
    final customerState = ref.read(adminCustomerControllerProvider);
    final manufacturerState = ref.read(manufacturerControllerProvider);

    final customer = customerState.customers.cast<Customer?>().firstWhere(
      (c) => c?.id == widget.customerId,
      orElse:
          () => customerState.filteredCustomers.cast<Customer?>().firstWhere(
            (c) => c?.id == widget.customerId,
            orElse: () => null,
          ),
    );

    final isManufacturer =
        (customer != null && customer.isManufacturer) ||
        manufacturerState.manufacturers.any((m) => m.id == widget.customerId);

    if (isManufacturer) {
      _loadCreditTransactions(widget.customerId);
    }
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(adminOrderControllerProvider);
    final purchaseOrderState = ref.watch(purchaseOrderControllerProvider);
    final customerState = ref.watch(adminCustomerControllerProvider);
    var customer = customerState.customers.firstWhere(
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

    // Check if manufacturer from manufacturer state (more reliable)
    // This ensures filters apply even if Customer object hasn't synced isManufacturer yet
    final manufacturerState = ref.watch(manufacturerControllerProvider);
    if (!customer.isManufacturer &&
        manufacturerState.manufacturers.any((m) => m.id == widget.customerId)) {
      customer = customer.copyWith(isManufacturer: true);
    }

    // Combine lists and filter out pending orders (processing status)
    // they will only appear once converted to sale (confirmed or higher)
    final List<dynamic> allTransactions = [
      ...orderState.filteredOrders.where(
        (o) => o.status != OrderStatus.processing,
      ),
      // Only show receipts if NOT a manufacturer
      if (!customer.isManufacturer) ...orderState.filteredReceipts,
    ];

    // Add purchase orders ONLY for manufacturers
    if (customer.isManufacturer) {
      for (final po in purchaseOrderState.filteredPurchaseOrders) {
        allTransactions.add(po);
      }
    }

    // Add Credit Transactions
    for (final t in _creditTransactions) {
      // For manufacturers, exclude Purchase transactions as they are already shown as Purchase Orders.
      // We allow Payout (Payment In) and Payin (Payment Out) to be shown.
      if (customer.isManufacturer &&
          t.transactionType == CreditTransactionType.purchase) {
        continue;
      }

      // Skip credit transactions that are already linked to a purchase order
      // if we are already showing purchase orders to avoid duplicate entries.
      // We identify them by checking if the referenceNumber matches a PO prefix
      // or if the description contains the PO number.
      final isPOLinked =
          (t.referenceNumber != null && t.referenceNumber!.startsWith('PC')) ||
          (t.description != null &&
              (t.description!.contains('PO #') ||
                  t.description!.contains('for PO #')));

      if (isPOLinked) {
        continue;
      }

      allTransactions.add(t);
    }

    // Calculate creation date (latest) for each group to determine sort position
    // We use latest date to ensure the group moves to top on new activity
    // (like payments).
    final groupCreationDates = <String, DateTime>{};
    for (final t in allTransactions) {
      final key = _getTransactionGroupKey(t);
      if (key.isNotEmpty) {
        final date = _getTransactionDate(t);
        if (!groupCreationDates.containsKey(key) ||
            date.isAfter(groupCreationDates[key]!)) {
          groupCreationDates[key] = date;
        }
      }
    }

    final sortedTransactions = List<dynamic>.from(allTransactions)..sort(
      (a, b) => _compareTransactionsGrouped(
        a,
        b,
        groupCreationDates,
        isManufacturer: customer.isManufacturer,
      ),
    );

    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: '${customer.alias ?? customer.name} - Orders',
        actions: [
          IconButton(
            icon: const Icon(Ionicons.refresh_outline),
            onPressed: _refreshAll,
          ),
        ],
        showBackButton: true,
        body: Stack(
          children: [
            ((orderState.loading || purchaseOrderState.loading) &&
                    sortedTransactions.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : orderState.error != null
                ? _buildErrorState(context, orderState.error!)
                : _buildContent(
                  context,
                  orderState,
                  sortedTransactions,
                  screenSize,
                  foldableBreakpoint,
                  customer,
                ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: AdminActionBottomBar(
                customerId: customer.isManufacturer ? null : widget.customerId,
                manufacturerId:
                    customer.isManufacturer ? widget.customerId : null,
                onRefresh: () {
                  _refreshAll();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _compareTransactionsGrouped(
    dynamic a,
    dynamic b,
    Map<String, DateTime> groupCreationDates, {
    bool isManufacturer = false,
  }) {
    // 1. Group-based sorting (Primary)
    // Only applicable for Date-based sorting (Latest/Oldest)
    if (currentSortOrder == TransactionSortOrder.latest ||
        currentSortOrder == TransactionSortOrder.oldest) {
      final keyA = _getTransactionGroupKey(a);
      final keyB = _getTransactionGroupKey(b);

      // If both items belong to groups (and different groups), compare their group's latest activity
      // This ensures related items (like Order and its Payment) stay together
      if (keyA.isNotEmpty && keyB.isNotEmpty && keyA != keyB) {
        final groupDateA = groupCreationDates[keyA] ?? _getTransactionDate(a);
        final groupDateB = groupCreationDates[keyB] ?? _getTransactionDate(b);

        if (!groupDateA.isAtSameMomentAs(groupDateB)) {
          return currentSortOrder == TransactionSortOrder.latest
              ? groupDateB.compareTo(groupDateA)
              : groupDateA.compareTo(groupDateB);
        }
      }
    }

    // 2. Internal sorting (Secondary)
    // We compare the actual transaction dates directly to ensure strict chronological order within the group.
    final dateA = _getTransactionDate(a);
    final dateB = _getTransactionDate(b);

    if (!dateA.isAtSameMomentAs(dateB)) {
      return currentSortOrder == TransactionSortOrder.latest
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    }

    // 3. Tie-breaking for same date
    // If dates are exactly the same, we check for grouping logic to handle
    // simultaneous items (like an Order and its immediate Payment).
    final keyA = _getTransactionGroupKey(a);
    final keyB = _getTransactionGroupKey(b);

    // If same group and same time: prioritize types
    if (keyA == keyB && keyA.isNotEmpty) {
      if (a is PaymentReceipt && b is! PaymentReceipt) return -1;
      if (b is PaymentReceipt && a is! PaymentReceipt) return 1;

      // Payments should be on top of the purchase they refer to
      if (a is PurchasePayment && b is PurchaseOrder) return -1;
      if (b is PurchasePayment && a is PurchaseOrder) return 1;
      if (a is CreditTransaction && b is PurchaseOrder) return -1;
      if (b is CreditTransaction && a is PurchaseOrder) return 1;
    }

    // Fallback: Use numeric ID sorting for stability
    final numA = _extractNumericPortion(a);
    final numB = _extractNumericPortion(b);

    if (numA != null && numB != null) {
      return currentSortOrder == TransactionSortOrder.latest
          ? numB.compareTo(numA)
          : numA.compareTo(numB);
    }

    return 0;
  }

  int _compareTransactions(dynamic a, dynamic b) {
    final keyA = _getTransactionGroupKey(a);
    final keyB = _getTransactionGroupKey(b);
    final baseDateA = _getTransactionDate(a);
    final baseDateB = _getTransactionDate(b);

    // If same group: sort by date then type priority
    if (keyA == keyB && keyA.isNotEmpty) {
      // If dates are different, strictly follow sort order
      if (!baseDateA.isAtSameMomentAs(baseDateB)) {
        return currentSortOrder == TransactionSortOrder.latest
            ? baseDateB.compareTo(baseDateA)
            : baseDateA.compareTo(baseDateB);
      }

      if (a is PaymentReceipt && b is! PaymentReceipt) return -1;
      if (b is PaymentReceipt && a is! PaymentReceipt) return 1;

      // Payments should be on top of the purchase they refer to
      if (a is PurchasePayment && b is PurchaseOrder) return -1;
      if (b is PurchasePayment && a is PurchaseOrder) return 1;
      if (a is CreditTransaction && b is PurchaseOrder) return -1;
      if (b is CreditTransaction && a is PurchaseOrder) return 1;

      // For same date, use numeric portion for proper sorting
      final numA = _extractNumericPortion(a);
      final numB = _extractNumericPortion(b);
      if (numA != null && numB != null) {
        return currentSortOrder == TransactionSortOrder.latest
            ? numB.compareTo(numA)
            : numA.compareTo(numB);
      }
      return currentSortOrder == TransactionSortOrder.latest
          ? baseDateB.compareTo(baseDateA)
          : baseDateA.compareTo(baseDateB);
    }

    // Different groups: sort by group latest activity
    if (baseDateA.isAtSameMomentAs(baseDateB)) {
      final numA = _extractNumericPortion(a);
      final numB = _extractNumericPortion(b);
      if (numA != null && numB != null) {
        return currentSortOrder == TransactionSortOrder.latest
            ? numB.compareTo(numA)
            : numA.compareTo(numB);
      }
    }
    return currentSortOrder == TransactionSortOrder.latest
        ? baseDateB.compareTo(baseDateA)
        : baseDateA.compareTo(baseDateB);
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.warning_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading orders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(adminOrderControllerProvider.notifier).loadOrders();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AdminOrderState orderState,
    List<dynamic> allTransactions,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
    Customer customer,
  ) {
    // Watch purchaseOrderState inside this method since it's not passed as parameter
    final purchaseOrderState = ref.watch(purchaseOrderControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);
    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.viewPadding.bottom;

    final isUltraCompact = width <= 288;
    final isCompact = width <= 400;
    final bottomNavHeight = isUltraCompact ? 56.0 : (isCompact ? 60.0 : 64.0);
    final totalBottomSpacing = bottomNavHeight + systemBottomPadding + 100;

    return RefreshIndicator(
      onRefresh: () async => _refreshAll(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (orderState.loading || purchaseOrderState.loading)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          // Customer Balance Banner
          SliverToBoxAdapter(
            child: _buildCustomerBalanceBanner(context, customer, spacing),
          ),
          SliverPadding(
            padding: EdgeInsets.all(spacing),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Search Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search orders...',
                            prefixIcon: const Icon(Ionicons.search_outline),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Ionicons.close_outline),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(
                                              adminOrderControllerProvider
                                                  .notifier,
                                            )
                                            .searchOrders('');
                                        ref
                                            .read(
                                              purchaseOrderControllerProvider
                                                  .notifier,
                                            )
                                            .searchPurchaseOrders('');
                                      },
                                    )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            ref
                                .read(adminOrderControllerProvider.notifier)
                                .searchOrders(value);
                            ref
                                .read(purchaseOrderControllerProvider.notifier)
                                .searchPurchaseOrders(value);
                            _searchDebouncer.debounce(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton<TransactionSortOrder>(
                          initialValue: currentSortOrder,
                          icon: const Icon(Ionicons.filter_outline),
                          onSelected: (value) {
                            setState(() {
                              _sortOrder = value;
                            });
                          },
                          itemBuilder:
                              (context) =>
                                  TransactionSortOrder.values
                                      .map(
                                        (order) => PopupMenuItem(
                                          value: order,
                                          child: Text(order.label),
                                        ),
                                      )
                                      .toList(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing * 0.75),
                ],
              ),
            ),
          ),

          // Orders List or Empty State
          // Only show empty state after loading is complete
          if (allTransactions.isEmpty &&
              !orderState.loading &&
              !purchaseOrderState.loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context, spacing),
            )
          else
            _buildOrdersList(
              context,
              allTransactions,
              orderState,
              screenSize,
              foldableBreakpoint,
              customer,
            ),

          SliverPadding(padding: EdgeInsets.only(bottom: totalBottomSpacing)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double spacing) {
    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.receipt_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerBalanceBanner(
    BuildContext context,
    Customer customer,
    double spacing,
  ) {
    // Get customer balance from state
    final customerState = ref.watch(adminCustomerControllerProvider);
    final customerData = customerState.customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse: () => customer,
    );

    final balance = customerData.totalBalance ?? 0.0;
    final balanceColor =
        balance > 0 ? Colors.red : (balance < 0 ? Colors.green : Colors.grey);
    final balanceLabel =
        balance > 0 ? 'Balance Due' : (balance < 0 ? 'Advance' : 'Settled');

    return Card(
      elevation: 2,
      margin: EdgeInsets.all(spacing),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.alias ?? customer.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: balanceColor),
                ),
              ],
            ),
            Text(
              '₹${balance.abs().toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    List<dynamic> allTransactions,
    AdminOrderState state,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
    Customer customer,
  ) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index < allTransactions.length) {
            final transaction = allTransactions[index];

            // Check if this is the start of a new group to add extra spacing
            bool isNewGroup = false;
            if (index > 0) {
              final prevKey = _getTransactionGroupKey(
                allTransactions[index - 1],
              );
              final currentKey = _getTransactionGroupKey(transaction);
              if (prevKey != currentKey && currentKey.isNotEmpty) {
                isNewGroup = true;
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: spacing * 0.75,
                top: isNewGroup ? spacing * 0.5 : 0,
              ),
              child: _buildTransactionCard(
                context,
                transaction,
                spacing,
                customer,
              ),
            );
          }
          return null;
        }, childCount: allTransactions.length),
      ),
    );
  }

  String _getTransactionTypeForCard(
    dynamic transaction,
    Customer customer,
    AdminOrderState orderState,
  ) {
    if (transaction is PurchaseOrder) {
      return 'Purchase';
    } else if (transaction is PurchasePayment) {
      return 'Payment Out';
    } else if (transaction is PaymentReceipt) {
      final desc = transaction.description?.toUpperCase() ?? '';
      if (desc.startsWith('REFUND') || desc.contains('PAYMENT OUT')) {
        return 'Payment Out';
      }
      return 'Payment In';
    } else if (transaction is CreditTransaction) {
      if (customer.isManufacturer) {
        // Strict mapping for manufacturer credit transactions
        if (transaction.transactionType == CreditTransactionType.payin) {
          return 'Payment Out';
        }
        // If somehow a purchase/payout slipped through, map correctly but they should be hidden
        if (transaction.transactionType == CreditTransactionType.purchase) {
          return 'Purchase';
        }
        // Default to Payment In for payout, but again, should be hidden
        return 'Payment In';
      }
      return transaction.transactionType == CreditTransactionType.payin
          ? 'Payment Out'
          : 'Payment In';
    } else if (transaction is Order) {
      if (customer.isManufacturer) {
        return 'Payment Out';
      }
      return transaction.status == OrderStatus.processing ? 'Order' : 'Sale';
    } else {
      return '';
    }
  }

  Widget _buildLinkedOrderItems(
    BuildContext context,
    PurchaseOrder purchaseOrder,
    bool isUltraCompact,
  ) {
    if (purchaseOrder.items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Items',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        ...purchaseOrder.items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (item.image.isNotEmpty)
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        item.image,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.image, size: 16),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: isUltraCompact ? 12 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.quantity} x ₹${item.unitPrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${item.totalPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isUltraCompact ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    dynamic transaction,
    double spacing,
    Customer customer,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isUltraCompact = Responsive.isUltraCompactDevice(width);
    final isFoldable = Responsive.isFoldableMobile(width);

    final isSale = transaction is Order;
    final isPurchase = transaction is PurchaseOrder;
    final isPurchasePayment = transaction is PurchasePayment;
    final isReceipt = transaction is PaymentReceipt;
    final isCreditTransaction = transaction is CreditTransaction;

    // Find linked purchase order for Payment Out
    PurchaseOrder? linkedPO;
    if (isPurchasePayment) {
      linkedPO = (transaction).purchaseOrder;
    } else if (isCreditTransaction) {
      final ct = transaction;
      if (customer.isManufacturer &&
          ct.transactionType == CreditTransactionType.payin &&
          ct.referenceNumber != null) {
        final poState = ref.watch(purchaseOrderControllerProvider);
        try {
          // Find PO where purchase number matches reference number or ID
          linkedPO = poState.filteredPurchaseOrders.firstWhere(
            (po) =>
                po.purchaseNumber == ct.referenceNumber ||
                po.id == ct.referenceNumber,
            orElse:
                () => poState.purchaseOrders.firstWhere(
                  (po) =>
                      po.purchaseNumber == ct.referenceNumber ||
                      po.id == ct.referenceNumber,
                ),
          );
        } catch (_) {}
      }
    }

    if (!isSale &&
        !isPurchase &&
        !isReceipt &&
        !isPurchasePayment &&
        !isCreditTransaction) {
      return const SizedBox.shrink();
    }

    // Determine order type and status badge
    final orderType = _getTransactionTypeForCard(
      transaction,
      customer,
      ref.watch(adminOrderControllerProvider),
    );

    // Get values based on type
    final String id =
        isReceipt
            ? (transaction).id
            : (isPurchasePayment
                ? (transaction).purchaseOrder.id
                : (isCreditTransaction
                    ? (transaction).id
                    : (isSale
                        ? (transaction).id
                        : (transaction as PurchaseOrder).id)));
    final String number =
        isReceipt
            ? ((transaction).orderNumber != null
                ? '#${(transaction).receiptNumber} (#${(transaction).orderNumber!})'
                : '#${(transaction).receiptNumber}')
            : (isPurchasePayment
                ? '#${(transaction).purchaseOrder.purchaseNumber}'
                : (isCreditTransaction
                    ? '#${(transaction).referenceNumber ?? '-'}'
                    : (isSale
                        ? (transaction).orderTag
                        : '#${(transaction as PurchaseOrder).purchaseNumber}')));
    DateTime rawDate =
        isReceipt
            ? (transaction).paymentDate
            : (isPurchasePayment
                ? (transaction).purchaseOrder.purchaseDate
                : (isCreditTransaction
                    ? (transaction).transactionDate
                    : (isSale
                        ? (transaction).orderDate
                        : (transaction as PurchaseOrder).purchaseDate)));

    // Fix for Purchase Order time being 00:00:00
    if ((isPurchase || isPurchasePayment) &&
        rawDate.hour == 0 &&
        rawDate.minute == 0 &&
        rawDate.second == 0) {
      final po =
          isPurchasePayment
              ? (transaction).purchaseOrder
              : (transaction as PurchaseOrder);
      final createdAtLocal = po.createdAt.toLocal();
      rawDate = DateTime(
        rawDate.year,
        rawDate.month,
        rawDate.day,
        createdAtLocal.hour,
        createdAtLocal.minute,
        createdAtLocal.second,
      );
    }
    final DateTime date = rawDate;
    final double total =
        isReceipt
            ? (transaction).amount
            : (isPurchasePayment
                ? (transaction).purchaseOrder.paidAmount
                : (isCreditTransaction
                    ? (transaction).amount
                    : (isSale
                        ? (transaction).total
                        : (transaction as PurchaseOrder).total)));

    // Use payment status for badge if available, otherwise fall back to order status
    Map<String, dynamic> statusBadge;

    if (isReceipt) {
      final desc = (transaction).description?.toUpperCase() ?? '';
      if (desc.startsWith('REFUND') || desc.contains('PAYMENT OUT')) {
        statusBadge = {'label': 'PAYMENT OUT', 'color': Colors.red};
      } else {
        statusBadge = {'label': 'RECEIVED', 'color': Colors.green};
      }
    } else if (isPurchasePayment) {
      statusBadge = {'label': 'PAID', 'color': Colors.green};
    } else if (isCreditTransaction) {
      final type = (transaction).transactionType;
      if (type == CreditTransactionType.payin) {
        statusBadge = {'label': 'PAID', 'color': Colors.red};
      } else {
        statusBadge = {'label': 'RECEIVED', 'color': Colors.green};
      }
    } else if (isSale) {
      final order = transaction;
      final orderState = ref.watch(adminOrderControllerProvider);
      final paymentData = orderState.orderPaymentMap[order.id];
      statusBadge =
          paymentData != null
              ? _getPaymentStatusBadge(paymentData.paymentStatus)
              : _getStatusBadge(order.status);
    } else {
      final purchase = transaction as PurchaseOrder;
      statusBadge = {
        'label': purchase.status.displayName,
        'color': purchase.status.color,
      };
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isUltraCompact ? 12 : 16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isSale) {
              context.pushNamed(
                'admin-order-detail',
                pathParameters: {'id': id},
              );
            } else if (isPurchase || isPurchasePayment) {
              final poId =
                  isPurchasePayment
                      ? (transaction).purchaseOrder.id
                      : (transaction as PurchaseOrder).id;

              if (isPurchasePayment) {
                // For Payment Out cards, navigate to payment-out screen
                context
                    .pushNamed(
                      'admin-payment-out',
                      queryParameters: {
                        'manufacturerId':
                            (transaction).purchaseOrder.manufacturerId,
                        'purchaseOrderId': poId,
                      },
                    )
                    .then((_) {
                      if (mounted) _refreshAll();
                    });
              } else {
                // For Purchase cards, navigate to purchase form
                context
                    .pushNamed(
                      'admin-purchase-order-form',
                      queryParameters: {'id': poId},
                    )
                    .then((updated) {
                      if (updated == true && mounted) {
                        ref
                            .read(purchaseOrderControllerProvider.notifier)
                            .refresh();
                      }
                    });
              }
            } else if (isReceipt) {
              context
                  .pushNamed('admin-payment-receipt-detail', extra: transaction)
                  .then((updated) {
                    if (updated == true && mounted) {
                      _refreshAll();
                    }
                  });
            } else if (isCreditTransaction) {
              context
                  .pushNamed(
                    'admin-payment-out-detail',
                    extra: {'transaction': transaction},
                  )
                  .then((_) {
                    if (mounted) _refreshAll();
                  });
            }
          },
          borderRadius: BorderRadius.circular(isUltraCompact ? 12 : 16),
          child: Padding(
            padding: EdgeInsets.all(
              isUltraCompact ? 12 : (isFoldable ? 14 : 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side - Order type and status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderType,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isUltraCompact ? 14 : null,
                            ),
                          ),
                          // Show manufacturer name for purchase orders
                          if (isPurchase || isPurchasePayment) ...[
                            SizedBox(height: isUltraCompact ? 2 : 4),
                            Consumer(
                              builder: (context, ref, child) {
                                final manufacturers = ref.watch(
                                  manufacturerControllerProvider,
                                );
                                final manufacturerId =
                                    isPurchasePayment
                                        ? (transaction)
                                            .purchaseOrder
                                            .manufacturerId
                                        : (transaction as PurchaseOrder)
                                            .manufacturerId;
                                final manufacturer = manufacturers.manufacturers
                                    .firstWhere(
                                      (m) => m.id == manufacturerId,
                                      orElse:
                                          () => Manufacturer(
                                            id: '',
                                            name: 'Unknown Manufacturer',
                                            gstNumber: '',
                                            businessName: '',
                                            businessAddress: '',
                                            city: '',
                                            state: '',
                                            pincode: '',
                                            email: '',
                                            phone: '',
                                            createdAt: DateTime.now(),
                                            updatedAt: DateTime.now(),
                                          ),
                                    );
                                return Text(
                                  manufacturer.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ],
                          SizedBox(height: isUltraCompact ? 4 : 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isUltraCompact ? 8 : 10,
                              vertical: isUltraCompact ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: (statusBadge['color'] as Color)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                isUltraCompact ? 12 : 16,
                              ),
                            ),
                            child: Text(
                              statusBadge['label'] as String,
                              style: TextStyle(
                                color: statusBadge['color'] as Color,
                                fontSize: isUltraCompact ? 10 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right side - Transaction ID and Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (isPurchase ||
                                  isPurchasePayment ||
                                  customer.isManufacturer)
                              ? (isCreditTransaction
                                  ? 'Ref: $number'
                                  : 'Bill No: $number')
                              : (isReceipt
                                  ? 'RCPT: $number'
                                  : (isSale ? number : '#$number')),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: isUltraCompact ? 10 : null,
                          ),
                        ),
                        SizedBox(height: isUltraCompact ? 2 : 4),
                        Text(
                          DateFormat('dd MMM, yy • hh:mm a').format(date),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: isUltraCompact ? 10 : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isUltraCompact ? 12 : 16),

                // Amounts Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReceipt ||
                                    isPurchasePayment ||
                                    isCreditTransaction
                                ? 'Amount'
                                : 'Total',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: isUltraCompact ? 10 : null,
                            ),
                          ),
                          SizedBox(height: isUltraCompact ? 2 : 4),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  isReceipt &&
                                          ((transaction).description
                                                      ?.toUpperCase()
                                                      .startsWith('REFUND') ==
                                                  true ||
                                              (transaction).description
                                                      ?.toUpperCase()
                                                      .contains(
                                                        'PAYMENT OUT',
                                                      ) ==
                                                  true)
                                      ? Colors.red
                                      : (isPurchase ||
                                          isPurchasePayment ||
                                          customer.isManufacturer)
                                      ? (isCreditTransaction &&
                                              (transaction).transactionType ==
                                                  CreditTransactionType.payin
                                          ? Colors.red
                                          : (isCreditTransaction
                                              ? Colors.green
                                              : Colors.red))
                                      : null,
                              fontSize: isUltraCompact ? 14 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSale ||
                        isPurchase ||
                        isReceipt ||
                        isPurchasePayment ||
                        isCreditTransaction)
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            double balance;
                            String label;
                            Color color;
                            String? subLabel;

                            if (isSale) {
                              final order = transaction;
                              final orderState = ref.watch(
                                adminOrderControllerProvider,
                              );
                              final paymentData =
                                  orderState.orderPaymentMap[order.id];

                              if (paymentData == null) {
                                return const SizedBox.shrink();
                              }

                              balance = paymentData.balanceAmount;
                              // Ensure balance is not negative on Sale card (Excess is shown on Payment card)
                              if (balance < 0) balance = 0;

                              final paymentStatus = paymentData.paymentStatus;

                              if (paymentStatus == PaymentStatus.used) {
                                label = 'Unused';
                                color = Colors.green;
                              } else if (paymentStatus ==
                                  PaymentStatus.partial) {
                                label = 'Balance';
                                color = Colors.blue;
                              } else {
                                label = 'Unpaid';
                                color = Colors.orange;
                              }
                            } else if (isReceipt) {
                              // Payment In (Receipt)
                              final receipt = transaction;
                              final orderState = ref.watch(
                                adminOrderControllerProvider,
                              );

                              // Try to find the linked order to calculate unused amount
                              final order = orderState.orders.firstWhere(
                                (o) => o.id == receipt.orderId,
                                orElse:
                                    () => Order(
                                      id: '',
                                      orderTag: '',
                                      orderNumber: '',
                                      orderDate: DateTime.now(),
                                      status: OrderStatus.processing,
                                      items: [],
                                      deliveryAddress: const OrderAddress(
                                        name: '',
                                        address: '',
                                        city: '',
                                        state: '',
                                        pincode: '',
                                        phone: '',
                                      ),
                                      subtotal: 0,
                                      shipping: 0,
                                      tax: 0,
                                      total: 0,
                                    ),
                              );

                              if (order.id.isNotEmpty) {
                                final unusedAmount =
                                    receipt.amount - order.total;
                                if (unusedAmount > 0.01) {
                                  balance = unusedAmount;
                                  label = 'Unused'; // Excess payment
                                  color = Colors.green;
                                } else {
                                  // Show remaining due amount if not overpaid
                                  final paymentData =
                                      orderState.orderPaymentMap[order.id];
                                  if (paymentData != null) {
                                    balance = paymentData.balanceAmount;
                                    label = 'Due';
                                    color = Colors.orange;
                                  } else {
                                    balance = 0.0;
                                    label = 'Balance';
                                    color = Colors.grey;
                                  }
                                }
                              } else {
                                balance = 0.0;
                                label = 'Balance';
                                color = Colors.grey;
                              }
                            } else if (isPurchasePayment) {
                              final purchase = (transaction).purchaseOrder;
                              balance = purchase.total - purchase.paidAmount;
                              final total = purchase.total;

                              if (balance <= 0.01) {
                                label = 'Settled';
                                color = Colors.green;
                              } else {
                                label = 'Balance';
                                color = Colors.red;
                              }
                              subLabel = 'Total: ₹${total.toStringAsFixed(2)}';
                            } else if (isCreditTransaction) {
                              final ct = transaction;

                              if (linkedPO != null) {
                                balance = linkedPO.balance;
                                if (balance <= 0.01) {
                                  label = 'Settled';
                                  color = Colors.green;
                                } else {
                                  label = 'Balance';
                                  color = Colors.red;
                                }
                              } else {
                                balance = ct.balanceAfter.abs();

                                if (ct.balanceAfter.abs() < 0.01) {
                                  label = 'Settled';
                                  color = Colors.green;
                                } else if (ct.balanceAfter < 0) {
                                  label = 'Due';
                                  color = Colors.red;
                                } else {
                                  label = 'Advance';
                                  color = Colors.green;
                                }
                              }
                            } else {
                              // Purchase Order
                              final purchase = transaction as PurchaseOrder;
                              balance = purchase.balance;
                              final total = purchase.total;

                              if (balance <= 0.01) {
                                label = 'Paid';
                                color = Colors.green;
                              } else if (balance >= total - 0.01) {
                                label = 'Unpaid';
                                color = Colors.orange;
                              } else {
                                label = 'Balance';
                                color = Colors.blue;
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: isUltraCompact ? 10 : null,
                                  ),
                                ),
                                SizedBox(height: isUltraCompact ? 2 : 4),
                                Text(
                                  '₹${balance.toStringAsFixed(2)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: isUltraCompact ? 14 : null,
                                  ),
                                ),
                                if (subLabel != null) ...[
                                  SizedBox(height: isUltraCompact ? 2 : 4),
                                  Text(
                                    subLabel,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: isUltraCompact ? 10 : 12,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      )
                    else
                      const Spacer(),
                    // Action Icons (Now visible for ALL types including Receipts)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Ionicons.print_outline,
                            size: isUltraCompact ? 18 : 20,
                          ),
                          onPressed: () => _printOrder(transaction),
                          tooltip: 'Print',
                        ),
                        IconButton(
                          icon:
                              _isSharing
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(
                                    Ionicons.share_social_outline,
                                    size: isUltraCompact ? 18 : 20,
                                  ),
                          onPressed:
                              _isSharing
                                  ? null
                                  : () => _shareOrder(transaction),
                          tooltip: _isSharing ? 'Sharing...' : 'Share',
                        ),
                        IconButton(
                          icon: Icon(
                            Ionicons.ellipsis_vertical_outline,
                            size: isUltraCompact ? 18 : 20,
                          ),
                          onPressed:
                              () => _showMoreOptionsBottomSheet(
                                context,
                                transaction,
                              ),
                          tooltip: 'More Options',
                        ),
                      ],
                    ),
                  ],
                ),

                // Linked Items for Payment Out
                // if (linkedPO != null)
                //   _buildLinkedOrderItems(context, linkedPO, isUltraCompact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReceiptOptions(BuildContext context, PaymentReceipt receipt) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Ionicons.print_outline),
                  title: const Text('Print Receipt'),
                  onTap: () {
                    Navigator.pop(context);
                    // Receipt printing can be added here
                  },
                ),
                ListTile(
                  leading: const Icon(Ionicons.share_social_outline),
                  title: const Text('Share Receipt'),
                  onTap: () {
                    Navigator.pop(context);
                    // Receipt sharing can be added here
                  },
                ),
              ],
            ),
          ),
    );
  }

  Map<String, dynamic> _getStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return {'label': 'UNPAID', 'color': Colors.orange};
      case OrderStatus.processing:
        return {'label': 'PARTIAL', 'color': Colors.blue};
      case OrderStatus.cancelled:
        return {'label': 'CANCELLED', 'color': Colors.red};
      default:
        return {'label': 'UNPAID', 'color': Colors.orange};
    }
  }

  Map<String, dynamic> _getPaymentStatusBadge(PaymentStatus paymentStatus) {
    switch (paymentStatus) {
      case PaymentStatus.unpaid:
        return {'label': 'UNPAID', 'color': Colors.orange};
      case PaymentStatus.partial:
        return {'label': 'BALANCE', 'color': Colors.blue};
      case PaymentStatus.used:
        return {'label': 'SETTLED', 'color': Colors.green};
    }
  }

  String _getTransactionGroupKey(dynamic t) {
    if (t is Order) {
      return t.orderNumber;
    } else if (t is PurchaseOrder) {
      return t.purchaseNumber;
    } else if (t is PurchasePayment) {
      return t.purchaseNumber;
    } else if (t is CreditTransaction) {
      return t.referenceNumber ?? t.id;
    } else if (t is PaymentReceipt) {
      return t.orderNumber ?? t.receiptNumber;
    }
    return '';
  }

  DateTime _getTransactionDate(dynamic t) {
    DateTime date;
    DateTime? createdAt;

    if (t is Order) {
      // Use orderDate instead of updatedAt to ensure sorting stability
      // (Order stays in place even if updated)
      date = t.orderDate;
    } else if (t is PurchaseOrder) {
      date = t.purchaseDate;
      createdAt = t.createdAt;
    } else if (t is PurchasePayment) {
      date = t.purchaseDate;
      createdAt = t.purchaseOrder.createdAt;
    } else if (t is CreditTransaction) {
      date = t.transactionDate;
    } else if (t is PaymentReceipt) {
      date = t.paymentDate;
    } else {
      date = DateTime(2000);
    }

    // Fix for Purchase Order time being 00:00:00
    // We apply this BEFORE normalization to ensure the time is correct for sorting
    if (createdAt != null &&
        date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0) {
      final createdAtLocal = createdAt.toLocal();
      date = DateTime(
        date.year,
        date.month,
        date.day,
        createdAtLocal.hour,
        createdAtLocal.minute,
        createdAtLocal.second,
      );
    }

    // Normalize to local time keeping the face value to ensure sorting matches display
    // This handles cases where some dates are UTC and others Local but displayed as-is
    return DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  double _getTransactionBalance(dynamic t) {
    if (t is Order) {
      final orderState = ref.read(adminOrderControllerProvider);
      return orderState.orderPaymentMap[t.id]?.balanceAmount ?? t.total;
    } else if (t is PurchaseOrder) {
      return t.balance;
    } else if (t is PurchasePayment) {
      return t.balance;
    } else if (t is CreditTransaction) {
      return t.balanceAfter;
    } else if (t is PaymentReceipt) {
      return 0; // Receipts usually don't carry balance themselves
    }
    return 0;
  }

  double _getTransactionAmount(dynamic t) {
    if (t is Order) {
      return t.total;
    } else if (t is PurchaseOrder) {
      return t.total;
    } else if (t is PurchasePayment) {
      return t.paidAmount;
    } else if (t is CreditTransaction) {
      return t.amount;
    } else if (t is PaymentReceipt) {
      return t.amount;
    }
    return 0;
  }

  Future<void> _deleteCreditTransaction(CreditTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text(
              'Are you sure you want to delete this transaction? This action cannot be undone.',
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
      try {
        final supabaseClient = ref.read(supabaseClientProvider);
        final repository = CreditTransactionRepository(supabaseClient);
        await repository.deleteCreditTransaction(transaction.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePurchaseOrder(PurchaseOrder purchaseOrder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Purchase Order'),
            content: const Text(
              'Are you sure you want to delete this purchase order? This action cannot be undone.',
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
      try {
        final success = await ref
            .read(purchaseOrderControllerProvider.notifier)
            .deletePurchaseOrder(purchaseOrder.id);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Purchase order deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _refreshAll();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete purchase order'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showMoreOptionsBottomSheet(
    BuildContext screenContext,
    dynamic transaction,
  ) {
    showModalBottomSheet(
      context: screenContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'More Options',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Ionicons.close_outline),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Options List
                if (transaction is Order) ...[
                  _buildMenuOption(
                    context,
                    icon: Ionicons.create_outline,
                    label: 'Edit',
                    onTap: () {
                      Navigator.of(context).pop();
                      screenContext.pushNamed(
                        'admin-order-detail',
                        pathParameters: {'id': transaction.id},
                      );
                    },
                  ),
                  _buildMenuOption(
                    context,
                    icon: Ionicons.cash_outline,
                    label: 'Receive Payment',
                    onTap: () {
                      Navigator.of(context).pop();
                      screenContext
                          .pushNamed(
                            'admin-payment-receipt',
                            pathParameters: {
                              'customerId': widget.customerId,
                              'orderId': transaction.id,
                            },
                            extra: transaction,
                          )
                          .then((paymentSaved) {
                            if (paymentSaved == true && mounted) {
                              ScaffoldMessenger.of(screenContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Payment In saved successfully',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _refreshAll();
                            }
                          });
                    },
                  ),
                  _buildMenuOption(
                    context,
                    icon: Ionicons.business_outline,
                    label: 'Convert to Purchase',
                    onTap: () {
                      Navigator.of(context).pop();
                      screenContext.pushNamed(
                        'admin-purchase-order-form',
                        queryParameters: {'orderId': transaction.id},
                      );
                    },
                  ),
                ] else if (transaction is PurchaseOrder ||
                    transaction is PurchasePayment) ...[
                  if (transaction is PurchaseOrder &&
                      transaction.balance > 0 &&
                      transaction.manufacturerId != null)
                    _buildMenuOption(
                      context,
                      icon: Ionicons.cash_outline,
                      label: 'Make a Payment',
                      onTap: () {
                        Navigator.of(context).pop();
                        screenContext
                            .pushNamed(
                              'admin-payment-out',
                              extra: {
                                'manufacturerId': transaction.manufacturerId!,
                                'purchaseOrderId': transaction.id,
                                'purchaseOrder': transaction,
                              },
                            )
                            .then((paymentSaved) {
                              if (paymentSaved == true && mounted) {
                                _refreshAll();
                              }
                            });
                      },
                    ),
                  _buildMenuOption(
                    context,
                    icon: Ionicons.create_outline,
                    label: 'Edit',
                    onTap: () {
                      Navigator.of(context).pop();
                      final poId =
                          transaction is PurchasePayment
                              ? transaction.purchaseOrder.id
                              : transaction.id;
                      screenContext
                          .pushNamed(
                            'admin-purchase-order-form',
                            queryParameters: {'id': poId},
                          )
                          .then((updated) {
                            // Always refresh to ensure list is in sync with details
                            if (mounted) {
                              _refreshAll();
                            }
                          });
                    },
                  ),
                  _buildMenuOption(
                    context,
                    icon: Ionicons.trash_outline,
                    label: 'Delete',
                    onTap: () {
                      Navigator.of(context).pop();
                      final po =
                          transaction is PurchasePayment
                              ? transaction.purchaseOrder
                              : transaction;
                      _deletePurchaseOrder(po);
                    },
                  ),
                ] else if (transaction is CreditTransaction) ...[
                  _buildMenuOption(
                    context,
                    icon: Ionicons.create_outline,
                    label: 'Edit',
                    onTap: () {
                      Navigator.of(context).pop();
                      screenContext
                          .pushNamed(
                            'admin-payment-out-detail',
                            extra: {'transaction': transaction},
                          )
                          .then((saved) {
                            if (saved == true) {
                              _refreshAll();
                            }
                          });
                    },
                  ),
                  _buildMenuOption(
                    context,
                    icon: Ionicons.trash_outline,
                    label: 'Delete',
                    onTap: () {
                      Navigator.of(context).pop();
                      _deleteCreditTransaction(transaction);
                    },
                  ),
                ],
                _buildMenuOption(
                  context,
                  icon: Ionicons.share_social_outline,
                  label: _isSharing ? 'Sharing...' : 'Share Order',
                  onTap:
                      _isSharing
                          ? null
                          : () async {
                            Navigator.of(context).pop();
                            await _shareOrder(transaction);
                          },
                ),
                _buildMenuOption(
                  context,
                  icon: Ionicons.print_outline,
                  label: 'Print Order',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _printOrder(transaction);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(label),
      trailing: const Icon(Ionicons.chevron_forward_outline, size: 20),
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  void _handleMenuAction(String action, dynamic transaction) {
    if (transaction is Order) {
      switch (action) {
        case 'view':
          context.pushNamed(
            'admin-order-detail',
            pathParameters: {'id': transaction.id},
          );
          break;
        case 'print':
          _printOrder(transaction);
          break;
        case 'share':
          _shareOrder(transaction);
          break;
        case 'cancel':
          _cancelOrder(transaction);
          break;
      }
    } else if (transaction is PurchaseOrder || transaction is PurchasePayment) {
      switch (action) {
        case 'print':
          _printOrder(transaction);
          break;
        case 'share':
          _shareOrder(transaction);
          break;
      }
    }
  }

  Future<Uint8List> _generateCreditTransactionPdf(
    CreditTransaction transaction,
    String manufacturerName, {
    required PurchaseOrder linkedPO,
  }) async {
    final manufacturers =
        ref.read(manufacturerControllerProvider).manufacturers;
    Manufacturer? manufacturer;
    try {
      manufacturer = manufacturers.firstWhere(
        (m) => m.id == transaction.manufacturerId,
      );
    } catch (_) {}
    final paidTo = PaidToInfo(
      name: manufacturer?.businessName ?? manufacturerName,
      address: manufacturer?.businessAddress,
      phone: manufacturer?.phone,
      gstNumber: manufacturer?.gstNumber,
    );
    return PaymentOutPdfService.generatePaymentOutPdf(
      transaction: transaction,
      paidTo: paidTo,
      linkedPO: linkedPO,
    );
  }

  Future<PurchaseOrder?> _resolveLinkedPurchaseOrder(
    CreditTransaction transaction,
  ) async {
    final refNo = transaction.referenceNumber;
    if (refNo == null || refNo.isEmpty) return null;

    final purchaseOrderState = ref.read(purchaseOrderControllerProvider);
    // Search in both filtered and all orders to be safe
    final fromState =
        purchaseOrderState.purchaseOrders
            .followedBy(purchaseOrderState.filteredPurchaseOrders)
            .where((po) => po.purchaseNumber == refNo || po.id == refNo)
            .firstOrNull;
    if (fromState != null) return fromState;

    try {
      return await ref
          .read(purchaseOrderControllerProvider.notifier)
          .getPurchaseOrderByNumber(refNo);
    } catch (_) {
      return null;
    }
  }

  Future<void> _printOrder(dynamic transaction) async {
    if (transaction is PurchaseOrder || transaction is PurchasePayment) {
      try {
        final po =
            transaction is PurchasePayment
                ? transaction.purchaseOrder
                : transaction as PurchaseOrder;
        final manufacturerState = ref.read(manufacturerControllerProvider);
        final manufacturer =
            manufacturerState.manufacturers
                .where((m) => m.id == po.manufacturerId)
                .firstOrNull;

        await PurchaseOrderPdfService.printPurchaseOrder(po, manufacturer);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error printing purchase order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    if (transaction is CreditTransaction) {
      final linkedPO = await _resolveLinkedPurchaseOrder(transaction);
      if (linkedPO == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Purchase Order not found for Ref No: ${transaction.referenceNumber ?? "-"}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        final customerState = ref.read(adminCustomerControllerProvider);
        final customer =
            customerState.customers
                .where((c) => c.id == widget.customerId)
                .firstOrNull;

        final pdfBytes = await _generateCreditTransactionPdf(
          transaction,
          customer?.alias ?? customer?.name ?? 'Unknown',
          linkedPO: linkedPO,
        );

        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'PO_${linkedPO.purchaseNumber}.pdf',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error printing payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    if (transaction is PaymentReceipt) {
      try {
        final pdfService = PaymentReceiptPdfService(ref);
        final pdfBytes = await pdfService.getPaymentReceiptPdfBytes(
          transaction,
        );
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error printing receipt: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Handle Order (Sale)
    try {
      await OrderPrintService.printOrder(transaction as Order, ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing order: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _shareOrder(dynamic transaction) async {
    if (transaction is PurchaseOrder || transaction is PurchasePayment) {
      if (_isSharing) return;
      setState(() => _isSharing = true);

      try {
        final po =
            transaction is PurchasePayment
                ? transaction.purchaseOrder
                : transaction as PurchaseOrder;
        final manufacturerState = ref.read(manufacturerControllerProvider);
        final manufacturer =
            manufacturerState.manufacturers
                .where((m) => m.id == po.manufacturerId)
                .firstOrNull;

        await PurchaseOrderPdfService.sharePurchaseOrder(po, manufacturer);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sharing purchase order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSharing = false);
        }
      }
      return;
    }

    if (transaction is PaymentReceipt) {
      if (_isSharing) return;
      setState(() => _isSharing = true);

      try {
        final pdfService = PaymentReceiptPdfService(ref);
        final pdfBytes = await pdfService.getPaymentReceiptPdfBytes(
          transaction,
        );

        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'Receipt_${transaction.receiptNumber}.pdf',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sharing receipt: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSharing = false);
        }
      }
      return;
    }

    if (transaction is CreditTransaction) {
      if (_isSharing) return;
      setState(() => _isSharing = true);

      try {
        final linkedPO = await _resolveLinkedPurchaseOrder(transaction);
        if (linkedPO == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Purchase Order not found for Ref No: ${transaction.referenceNumber ?? "-"}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final customerState = ref.read(adminCustomerControllerProvider);
        final customer =
            customerState.customers
                .followedBy(customerState.filteredCustomers)
                .where((c) => c.id == widget.customerId)
                .firstOrNull;

        final pdfBytes = await _generateCreditTransactionPdf(
          transaction,
          customer?.alias ?? customer?.name ?? 'Unknown',
          linkedPO: linkedPO,
        );

        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'PO_${linkedPO.purchaseNumber}.pdf',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sharing payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSharing = false);
        }
      }
      return;
    }

    // Handle Order (Sale)
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      await OrderShareService.shareOrder(transaction as Order, ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing order: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Order'),
            content: const Text('Are you sure you want to cancel this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(adminOrderControllerProvider.notifier)
          .updateOrderStatus(order.id, OrderStatus.cancelled);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
        _refreshAll();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Extract numeric portion from purchase/order numbers for proper numeric sorting
  /// Handles formats like PO00-000097, ORD0001, etc.
  int? _extractNumericPortion(dynamic transaction) {
    String number = '';
    if (transaction is PurchaseOrder) {
      number = transaction.purchaseNumber;
    } else if (transaction is PurchasePayment) {
      number = transaction.purchaseNumber;
    } else if (transaction is Order) {
      number = transaction.orderNumber;
    } else if (transaction is CreditTransaction) {
      number = transaction.referenceNumber ?? '';
    } else if (transaction is PaymentReceipt) {
      number = transaction.receiptNumber;
    }

    // Extract numeric portion (handles formats like PO00-000097, ORD0001, etc.)
    final numericPart = number.replaceAll(RegExp(r'[^0-9]'), '');
    return numericPart.isNotEmpty ? int.tryParse(numericPart) : null;
  }
}
