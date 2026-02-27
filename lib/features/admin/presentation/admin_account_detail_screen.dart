import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/logger.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_auth_guard.dart';
import 'admin_cash_transaction_screen.dart';
import 'admin_transaction_detail_screen.dart';
import '../data/cash_book_repository.dart';
import '../domain/cash_book_entry.dart';

class AdminAccountDetailScreen extends ConsumerStatefulWidget {
  final String accountId;
  final String accountName;

  const AdminAccountDetailScreen({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  @override
  ConsumerState<AdminAccountDetailScreen> createState() =>
      _AdminAccountDetailScreenState();
}

class _AdminAccountDetailScreenState
    extends ConsumerState<AdminAccountDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CashBookEntry> _transactions = [];
  Map<String, dynamic>? _accountDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([_fetchAccountDetails(), _fetchTransactions()]);
  }

  Future<void> _fetchAccountDetails() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final response =
          await supabase
              .from('accounts')
              .select()
              .eq('id', widget.accountId)
              .single();

      if (mounted) {
        setState(() {
          _accountDetails = response;
        });
      }
    } catch (e) {
      Logger.error('Failed to fetch account details', error: e);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions({bool background = false}) async {
    if (!mounted) return;
    if (!background) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repository = ref.read(cashBookRepositoryProvider);

      // Removed sync call since balance column doesn't exist in accounts table
      // await repository.updateAccountBalance(widget.accountId);

      final transactions = await repository.getEntries(
        relatedId: widget.accountId,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load transactions: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addTransaction(CashBookEntryType type) async {
    final result = await context.pushNamed(
      'admin-transaction-add',
      pathParameters: {'id': widget.accountId},
      queryParameters: {'type': type.index.toString()},
      extra: {'accountName': _accountDetails?['name'] ?? widget.accountName},
    );

    if (result == true) {
      _fetchData();
    }
  }

  Future<void> _editTransaction(CashBookEntry entry) async {
    final result = await context.pushNamed(
      'admin-transaction-edit',
      pathParameters: {'id': widget.accountId},
      extra: {
        'accountName': _accountDetails?['name'] ?? widget.accountName,
        'entry': entry,
      },
    );

    if (result == true) {
      _fetchData();
    }
  }

  Future<void> _openTransactionDetail(CashBookEntry entry) async {
    final result = await context.pushNamed(
      'admin-transaction-detail',
      pathParameters: {
        'id': widget.accountId,
        'transactionId': entry.id ?? 'new',
      },
      extra: {
        'entry': entry,
        'accountName': _accountDetails?['name'] ?? widget.accountName,
      },
    );

    if (result == true) {
      _fetchData();
    }
  }

  Future<void> _deleteTransaction(CashBookEntry entry) async {
    if (entry.id == null || entry.id!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete: Invalid Transaction ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text(
              'Are you sure you want to delete this transaction?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(cashBookRepositoryProvider);
      if (entry.id != null) {
        await repository.deleteEntry(entry.id!, relatedId: widget.accountId);

        // Update local state directly to reflect change immediately
        if (mounted) {
          setState(() {
            _transactions.removeWhere((t) => t.id == entry.id);
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Delay slightly to ensure DB propagation before fetching
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _fetchTransactions(background: true);
      }
    } catch (e) {
      if (mounted) {
        // If it was already deleted/not found, we should still remove it from UI
        if (e.toString().contains('not found') ||
            e.toString().contains('already deleted')) {
          setState(() {
            _transactions.removeWhere((t) => t.id == entry.id);
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction synced (already deleted)'),
              backgroundColor: Colors.orange,
            ),
          );
          _fetchTransactions(background: true);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions =
        _transactions.where((t) {
          final search = _searchController.text.toLowerCase();
          return t.description.toLowerCase().contains(search);
        }).toList();

    double totalIn = 0;
    double totalOut = 0;
    for (var t in _transactions) {
      if (t.type == CashBookEntryType.payin) {
        totalIn += t.amount;
      } else {
        totalOut += t.amount;
      }
    }
    final balance = totalIn - totalOut;
    final isNegative = balance < 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdminAuthGuard(
      child: AdminScaffold(
        title: _accountDetails?['name'] ?? widget.accountName,
        showBackButton: true,
        body: Column(
          children: [
            // Account Info Section (Phone & Address)
            if (_accountDetails != null &&
                (_accountDetails!['phone'] != null ||
                    _accountDetails!['address'] != null))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_accountDetails!['phone'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _accountDetails!['phone'],
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_accountDetails!['address'] != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _accountDetails!['address'],
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            // Summary Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Balance',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${balance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color:
                              isNegative
                                  ? const Color(0xFFC62828)
                                  : const Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Received (+)',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalIn.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Paid (-)',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${totalOut.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: const Color(0xFFC62828),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: Icon(
                    Ionicons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),

            // List
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : filteredTransactions.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Ionicons.receipt_outline,
                              size: 64,
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          100,
                        ), // Space for FABs
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final t = filteredTransactions[index];
                          final isPayIn = t.type == CashBookEntryType.payin;
                          return Card(
                            key: ValueKey(t.id),
                            clipBehavior: Clip.antiAlias,
                            elevation: 0,
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () => _openTransactionDetail(t),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isPayIn
                                                  ? 'Payment In'
                                                  : 'Payment Out',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (t.description.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  t.description,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          DateFormat(
                                            'dd MMM, yy',
                                          ).format(t.date),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isPayIn
                                                    ? const Color(0xFFE8F5E9)
                                                    : const Color(0xFFFFEBEE),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            isPayIn ? 'RECEIVED' : 'PAID',
                                            style: TextStyle(
                                              color:
                                                  isPayIn
                                                      ? const Color(0xFF2E7D32)
                                                      : const Color(0xFFC62828),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${t.paymentMethod}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isPayIn
                                                  ? 'Amount Received'
                                                  : 'Amount Paid',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${t.amount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isPayIn
                                                        ? const Color(
                                                          0xFF2E7D32,
                                                        )
                                                        : const Color(
                                                          0xFFC62828,
                                                        ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.grey,
                                          ),
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editTransaction(t);
                                            } else if (value == 'delete') {
                                              _deleteTransaction(t);
                                            }
                                          },
                                          itemBuilder:
                                              (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        size: 20,
                                                      ),
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
                                                        Icons.delete_outline,
                                                        size: 20,
                                                        color: Colors.red,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(left: 14.0, right: 0.0),
          child: Transform.translate(
            offset: const Offset(10, 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _addTransaction(CashBookEntryType.payin),
                      label: const Text('Payment In'),
                      icon: const Icon(Icons.arrow_downward),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20), // Dark Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          () => _addTransaction(CashBookEntryType.payout),
                      label: const Text('Payment Out'),
                      icon: const Icon(Icons.arrow_upward),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
