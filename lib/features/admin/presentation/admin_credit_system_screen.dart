import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../application/credit_system_controller.dart';
import '../domain/credit_transaction.dart';
import '../application/admin_auth_controller.dart';
import '../application/cash_book_controller.dart';
import '../domain/cash_book_entry.dart';

class AdminCreditSystemScreen extends ConsumerStatefulWidget {
  const AdminCreditSystemScreen({super.key});

  @override
  ConsumerState<AdminCreditSystemScreen> createState() =>
      _AdminCreditSystemScreenState();
}

class _AdminCreditSystemScreenState
    extends ConsumerState<AdminCreditSystemScreen> {
  int _selectedTab = 0; // 0: Overview, 1: Transactions, 2: Balances

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(creditSystemControllerProvider.notifier).refresh();
        ref.read(cashBookControllerProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);
    final creditState = ref.watch(creditSystemControllerProvider);
    final cashBookState = ref.watch(cashBookControllerProvider);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Cash Book',
        showBackButton: true,
        actions: [
          ResponsiveIconButton(
            icon: const Icon(Ionicons.refresh_outline),
            onPressed: () {
              ref.read(creditSystemControllerProvider.notifier).refresh();
              ref.read(cashBookControllerProvider.notifier).refresh();
            },
            tooltip: 'Refresh',
          ),
          ResponsiveIconButton(
            icon: const Icon(Ionicons.add_outline),
            onPressed: () => _showAddTransactionDialog(context),
            tooltip: 'Add Transaction',
          ),
        ],
        body: Column(
          children: [
            // Tabs
            _buildTabs(context, spacing),
            // Content
            Expanded(
              child:
                  _selectedTab == 0
                      ? _buildOverviewTab(
                        context,
                        creditState,
                        cashBookState,
                        spacing,
                      )
                      : _selectedTab == 1
                      ? _buildTransactionsTab(context, cashBookState, spacing)
                      : _buildBalancesTab(context, creditState, spacing),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, double spacing) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton(context, 0, 'Overview', Ionicons.grid, spacing),
          _buildTabButton(
            context,
            1,
            'Transactions',
            Ionicons.receipt,
            spacing,
          ),
          _buildTabButton(context, 2, 'Balances', Ionicons.wallet, spacing),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    int index,
    String label,
    IconData icon,
    double spacing,
  ) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: spacing),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected
                        ? const Color(0xFFFFC107) // Amber/Yellow
                        : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    isSelected
                        ? const Color(0xFFFFC107) // Amber
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      isSelected
                          ? const Color(0xFFFFC107) // Amber
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    CreditSystemState creditState,
    CashBookState cashBookState,
    double spacing,
  ) {
    if (creditState.isLoading || cashBookState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cashBookState.error != null) {
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
              'Error loading cash book',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(cashBookState.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(cashBookControllerProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards (using Cash Book data)
          _buildSummaryCards(context, cashBookState, spacing),
          SizedBox(height: spacing),
          // Recent Transactions (using Cash Book data)
          _buildRecentTransactions(context, cashBookState, spacing),
          SizedBox(height: spacing),
          // Top Balances (using Credit System data - manufacturers)
          _buildTopBalances(context, creditState, spacing),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    CashBookState state,
    double spacing,
  ) {
    // Total Payin and Payout from state (database calculated)
    final totalPayin = state.totalPayin;
    final totalPayout = state.totalPayout;
    final cashBalance = state.balance;
    final totalTransactions = state.totalCount;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                'TOTAL PAYIN',
                '₹${totalPayin.toStringAsFixed(0)}',
                Ionicons.arrow_down_circle_outline,
                const Color(0xFF00C853), // Green
                spacing,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _buildSummaryCard(
                context,
                'TOTAL PAYOUT',
                '₹${totalPayout.toStringAsFixed(0)}',
                Ionicons.arrow_up_circle_outline,
                const Color(0xFF2962FF), // Blue
                spacing,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _buildSummaryCard(
                context,
                'BALANCE',
                '₹${cashBalance.toStringAsFixed(0)}',
                Ionicons.wallet_outline,
                const Color(0xFFD50000), // Red
                spacing,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(spacing * 1.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Transactions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacing * 0.5),
                    Text(
                      '$totalTransactions',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A148C), // Deep Purple
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(spacing),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6), // Light Deep Purple
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Ionicons.bar_chart_outline,
                    color: Color(0xFF673AB7), // Deep Purple
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    double spacing,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            SizedBox(height: spacing),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    CashBookState state,
    double spacing,
  ) {
    final recentTransactions = state.entries.take(10).toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedTab = 1),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            if (recentTransactions.isEmpty)
              Padding(
                padding: EdgeInsets.all(spacing),
                child: Center(
                  child: Text(
                    'No transactions yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...recentTransactions.map(
                (entry) => _buildCashBookEntryTile(context, entry, spacing),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashBookEntryTile(
    BuildContext context,
    CashBookEntry entry,
    double spacing,
  ) {
    Color color;
    IconData icon;
    String typeLabel;
    String amountPrefix = '';

    switch (entry.type) {
      case CashBookEntryType.payin:
        color = const Color(0xFF00C853); // Green
        icon = Ionicons.arrow_down;
        typeLabel = 'PAYIN';
        amountPrefix = '';
        break;
      case CashBookEntryType.payout:
        color = const Color(0xFFD50000); // Red
        icon = Ionicons.arrow_up;
        typeLabel = 'PAYOUT';
        amountPrefix = '- ';
        break;
    }

    // Override color for Payin to match the light green circle in image
    final circleColor =
        entry.type == CashBookEntryType.payin
            ? const Color(0xFFE8F5E9) // Light Green
            : const Color(0xFFFFEBEE); // Light Red

    final iconColor =
        entry.type == CashBookEntryType.payin
            ? const Color(0xFF00C853) // Green
            : const Color(0xFFD50000); // Red

    // Amount color in image is green for Payin.
    final amountColor =
        entry.type == CashBookEntryType.payin
            ? const Color(0xFF00C853)
            : const Color(0xFFD50000);

    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      padding: EdgeInsets.symmetric(vertical: spacing * 0.5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(width: spacing),
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      typeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Date and Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(entry.date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
              SizedBox(height: spacing * 0.5),
              Text(
                '$amountPrefix₹${entry.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBalances(
    BuildContext context,
    CreditSystemState state,
    double spacing,
  ) {
    final topBalances = List<ManufacturerCreditBalance>.from(
      state.balances,
    )..sort((a, b) => a.currentBalance.abs().compareTo(b.currentBalance.abs()));
    final top5 = topBalances.take(5).toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Top Balances',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedTab = 2),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            if (top5.isEmpty)
              Padding(
                padding: EdgeInsets.all(spacing),
                child: Center(
                  child: Text(
                    'No balances yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...top5.map(
                (balance) => _buildBalanceTile(context, balance, spacing),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(
    BuildContext context,
    CashBookState state,
    double spacing,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Transactions List
        Expanded(
          child:
              state.entries.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Ionicons.receipt_outline,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: EdgeInsets.all(spacing),
                    itemCount: state.entries.length,
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      return _buildCashBookEntryCard(context, entry, spacing);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCashBookEntryCard(
    BuildContext context,
    CashBookEntry entry,
    double spacing,
  ) {
    Color color;
    IconData icon;
    String typeLabel;
    String amountPrefix = '';

    switch (entry.type) {
      case CashBookEntryType.payin:
        color = const Color(0xFF00C853); // Green
        icon = Ionicons.arrow_down;
        typeLabel = 'PAYIN';
        amountPrefix = '';
        break;
      case CashBookEntryType.payout:
        color = const Color(0xFFD50000); // Red
        icon = Ionicons.arrow_up;
        typeLabel = 'PAYOUT';
        amountPrefix = '- ';
        break;
    }

    // Override color for Payin to match the light green circle in image
    final circleColor =
        entry.type == CashBookEntryType.payin
            ? const Color(0xFFE8F5E9) // Light Green
            : const Color(0xFFFFEBEE); // Light Red

    final iconColor =
        entry.type == CashBookEntryType.payin
            ? const Color(0xFF00C853) // Green
            : const Color(0xFFD50000); // Red

    // Amount color in image is green for Payin.
    final amountColor =
        entry.type == CashBookEntryType.payin
            ? const Color(0xFF00C853)
            : const Color(0xFFD50000);

    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      padding: EdgeInsets.symmetric(
        vertical: spacing * 0.5,
        horizontal: spacing,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(width: spacing),
          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          typeLabel,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (entry.paymentMethod.isNotEmpty) ...[
                          Text(
                            ' • ${entry.paymentMethod}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Date and Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(entry.date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
              SizedBox(height: spacing * 0.5),
              Text(
                '$amountPrefix₹${entry.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesTab(
    BuildContext context,
    CreditSystemState state,
    double spacing,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return state.balances.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.wallet_outline,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No balances found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        )
        : ListView.builder(
          padding: EdgeInsets.all(spacing),
          itemCount: state.balances.length,
          itemBuilder: (context, index) {
            final balance = state.balances[index];
            return _buildBalanceCard(context, balance, spacing);
          },
        );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    ManufacturerCreditBalance balance,
    double spacing,
  ) {
    final isNegative = balance.currentBalance < 0;

    return Card(
      margin: EdgeInsets.only(bottom: spacing * 0.75),
      child: InkWell(
        onTap: () {
          ref
              .read(creditSystemControllerProvider.notifier)
              .selectEntity(
                manufacturerId: balance.manufacturerId,
                entityName:
                    balance.manufacturerId == null ? balance.entityName : null,
              );
          setState(() => _selectedTab = 1);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    isNegative
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                radius: 22,
                child: Icon(
                  isNegative ? Ionicons.arrow_down : Ionicons.arrow_up,
                  color: isNegative ? Colors.orange : Colors.green,
                  size: 18,
                ),
              ),
              SizedBox(width: spacing * 0.75),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      balance.entityName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Transactions: ${balance.transactionCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Payin: ₹${balance.totalPayin.toStringAsFixed(2)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '|',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Payout: ₹${balance.totalPayout.toStringAsFixed(2)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (balance.lastTransactionDate != null) ...[
                      SizedBox(height: 2),
                      Text(
                        'Last: ${_formatDate(balance.lastTransactionDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: spacing * 0.5),
              Flexible(
                child: Text(
                  balance.balanceDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isNegative ? Colors.orange : Colors.green,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceTile(
    BuildContext context,
    ManufacturerCreditBalance balance,
    double spacing,
  ) {
    final isNegative = balance.currentBalance < 0;

    return ListTile(
      leading: Icon(
        isNegative ? Ionicons.arrow_down_circle : Ionicons.arrow_up_circle,
        color: isNegative ? Colors.orange : Colors.green,
      ),
      title: Text(
        balance.entityName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('${balance.transactionCount} transactions'),
      trailing: Text(
        balance.balanceDisplay,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isNegative ? Colors.orange : Colors.green,
        ),
      ),
      onTap: () {
        ref
            .read(creditSystemControllerProvider.notifier)
            .selectEntity(
              manufacturerId: balance.manufacturerId,
              entityName:
                  balance.manufacturerId == null ? balance.entityName : null,
            );
        setState(() => _selectedTab = 1);
      },
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddCreditTransactionDialog(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Add Transaction Dialog
class AddCreditTransactionDialog extends ConsumerStatefulWidget {
  const AddCreditTransactionDialog({super.key});

  @override
  ConsumerState<AddCreditTransactionDialog> createState() =>
      _AddCreditTransactionDialogState();
}

class _AddCreditTransactionDialogState
    extends ConsumerState<AddCreditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _entityNameController = TextEditingController();
  CreditTransactionType? _selectedType;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  PaymentMethod? _selectedPaymentMethod;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _entityNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(currentAdminProvider);
    final creditState = ref.watch(creditSystemControllerProvider);
    final cashBookState = ref.watch(cashBookControllerProvider);
    final isLoading = creditState.isLoading || cashBookState.isLoading;

    return AlertDialog(
      title: const Text('Add Credit Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _entityNameController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Name/Description *',
                  border: OutlineInputBorder(),
                  hintText:
                      'e.g., Rent, Electricity Bill, Manufacturer Name, etc.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name/description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CreditTransactionType>(
                decoration: const InputDecoration(
                  labelText: 'Transaction Type *',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedType,
                items:
                    CreditTransactionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                onChanged:
                    isLoading
                        ? null
                        : (value) {
                          setState(() => _selectedType = value);
                        },
                validator: (value) {
                  if (value == null) return 'Please select transaction type';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referenceController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Reference Number',
                  border: OutlineInputBorder(),
                  hintText: 'Bill number, order number, etc.',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedPaymentMethod,
                items:
                    PaymentMethod.values.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method.displayName),
                      );
                    }).toList(),
                onChanged:
                    isLoading
                        ? null
                        : (value) {
                          setState(() => _selectedPaymentMethod = value);
                        },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Transaction Date'),
                enabled: !isLoading,
                subtitle: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select date (default: today)',
                ),
                trailing: const Icon(Ionicons.calendar_outline),
                onTap:
                    isLoading
                        ? null
                        : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              isLoading
                  ? null
                  : () async {
                    if (_formKey.currentState!.validate() &&
                        authState != null) {
                      try {
                        // 1. Add to Credit System (Legacy/Manufacturer Balance)
                        final success = await ref
                            .read(creditSystemControllerProvider.notifier)
                            .createTransaction(
                              entityName: _entityNameController.text.trim(),
                              transactionType: _selectedType!,
                              amount: double.parse(_amountController.text),
                              createdBy: authState.id,
                              description:
                                  _descriptionController.text.isEmpty
                                      ? null
                                      : _descriptionController.text,
                              referenceNumber:
                                  _referenceController.text.isEmpty
                                      ? null
                                      : _referenceController.text,
                              paymentMethod: _selectedPaymentMethod,
                              transactionDate: _selectedDate,
                            );

                        if (!success) {
                          final error =
                              ref.read(creditSystemControllerProvider).error;
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to add transaction: $error',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        // 2. Add to Cash Book (New System)
                        // Map CreditTransactionType to CashBookEntryType
                        CashBookEntryType cashBookType;
                        if (_selectedType == CreditTransactionType.payout) {
                          // Payout from Admin (e.g. Rent) is a Payout in Cash Book
                          cashBookType = CashBookEntryType.payout;
                        } else {
                          // Payin to Admin is a Payin in Cash Book
                          cashBookType = CashBookEntryType.payin;
                        }

                        // Use the cashBookController to add the entry which handles refresh automatically
                        await ref
                            .read(cashBookControllerProvider.notifier)
                            .addEntry(
                              CashBookEntry(
                                amount: double.parse(_amountController.text),
                                type: cashBookType,
                                category: _entityNameController.text.trim(),
                                description:
                                    _descriptionController.text.isEmpty
                                        ? 'Manual Transaction'
                                        : _descriptionController.text,
                                date: _selectedDate ?? DateTime.now(),
                                paymentMethod:
                                    _selectedPaymentMethod?.displayName ??
                                    'Cash',
                                createdBy: authState.id,
                              ),
                            );

                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction added successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error in add transaction: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
          child:
              isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Add Transaction'),
        ),
      ],
    );
  }
}
