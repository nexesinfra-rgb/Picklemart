import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_auth_guard.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/utils/logger.dart';
import '../data/cash_book_repository.dart';

class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  ConsumerState<AdminAccountsScreen> createState() =>
      _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends ConsumerState<AdminAccountsScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Name controller removed as it's moved to separate screen

  bool _isLoading = false;
  // _isCreating removed as it's moved to separate screen
  String? _errorMessage;
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAccounts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = ref.read(supabaseClientProvider);

      // 1. Fetch accounts
      final accountsResponse = await supabase
          .from('accounts')
          .select()
          .order('created_at', ascending: false);

      // 2. Fetch all transactions (lightweight) to calculate live totals
      // This ensures we always show correct values even if sync fails
      final transactionsResponse = await supabase
          .from('cash_book')
          .select('amount, entry_type, related_id');

      final List<Map<String, dynamic>> accounts =
          List<Map<String, dynamic>>.from(accountsResponse);
      final List<dynamic> transactions = transactionsResponse as List<dynamic>;

      // 3. Aggregate totals per account
      for (var account in accounts) {
        final accountId = account['id'];
        double totalIn = 0;
        double totalOut = 0;

        for (var t in transactions) {
          if (t['related_id'] == accountId) {
            final amount = (t['amount'] as num).toDouble();
            final type = (t['entry_type'] as String).toLowerCase().trim();

            if (type == 'payin' || type == 'pay in' || type == 'payment in') {
              totalIn += amount;
            } else if (type == 'payout' ||
                type == 'pay out' ||
                type == 'payment out') {
              totalOut += amount;
            }
          }
        }

        account['total_in'] = totalIn;
        account['total_out'] = totalOut;
        account['calculated_balance'] = totalIn - totalOut;
      }

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Failed to fetch accounts', error: e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load accounts: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editAccount(Map<String, dynamic> account) async {
    final nameController = TextEditingController(
      text: account['name'] as String?,
    );
    final phoneController = TextEditingController(
      text: account['phone'] as String?,
    );
    final addressController = TextEditingController(
      text: account['address'] as String?,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        hintText: '10-digit number',
                        border: OutlineInputBorder(),
                        prefixText: '+91 ',
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      buildCounter:
                          (
                            context, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address (Optional)',
                        hintText: 'Enter full address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name is required')),
                      );
                      return;
                    }

                    if (phone.isNotEmpty) {
                      if (phone.length != 10 ||
                          !RegExp(r'^[0-9]+$').hasMatch(phone)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid 10-digit phone number',
                            ),
                          ),
                        );
                        return;
                      }
                    }

                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && nameController.text.isNotEmpty && mounted) {
      try {
        final supabase = ref.read(supabaseClientProvider);
        await supabase
            .from('accounts')
            .update({
              'name': nameController.text.trim(),
              'phone':
                  phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
              'address':
                  addressController.text.trim().isEmpty
                      ? null
                      : addressController.text.trim(),
            })
            .eq('id', account['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account updated successfully')),
          );
          _fetchAccounts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating account: $e')));
        }
      }
    }
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
  }

  Future<void> _deleteAccount(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete this account? This will also delete all associated transactions.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        // Delete associated transactions first using the repository logic
        // But since we are deleting the account, we can just let Supabase handle cascade if configured,
        // OR manually delete transactions.
        // Let's use the repository to clean up cash_book entries first for safety.
        final repository = ref.read(cashBookRepositoryProvider);
        await repository.deleteEntryByRelatedId(id);

        // Then delete the account
        final supabase = ref.read(supabaseClientProvider);
        await supabase.from('accounts').delete().eq('id', id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          _fetchAccounts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
        }
      }
    }
  }

  void _navigateToCreateAccount() async {
    // Navigate to create account screen and wait for result
    // The result will be true if an account was created
    final result = await context.pushNamed('admin-create-account');
    if (result == true && mounted) {
      _fetchAccounts();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}, ${date.year.toString().substring(2)}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter accounts based on search
    final filteredAccounts =
        _accounts.where((account) {
          final search = _searchController.text.toLowerCase();
          final name = (account['name'] as String? ?? '').toLowerCase();
          return name.contains(search);
        }).toList();

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Accounts',
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToCreateAccount,
          icon: const Icon(Icons.add),
          label: const Text('Add Create Account'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search accounts...',
                  prefixIcon: const Icon(Ionicons.search_outline),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Ionicons.close_outline),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            // Main Content
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                      : filteredAccounts.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Ionicons.card_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            const Text('No accounts found'),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetchAccounts,
                        child: ListView.builder(
                          itemCount: filteredAccounts.length,
                          itemBuilder: (context, index) {
                            final account = filteredAccounts[index];
                            // Use calculated balance if available (from live aggregation), otherwise fallback to DB balance
                            final double balance =
                                (account['calculated_balance'] as num? ??
                                        (account['balance'] as num? ?? 0))
                                    .toDouble();
                            final double totalIn =
                                (account['total_in'] as num? ?? 0).toDouble();
                            final double totalOut =
                                (account['total_out'] as num? ?? 0).toDouble();

                            final bool isNegative = balance < 0;
                            final bool isZero = balance == 0;
                            final Color statusColor =
                                isZero
                                    ? Colors.black
                                    : (isNegative ? Colors.red : Colors.green);
                            final String statusText =
                                isZero
                                    ? ''
                                    : (isNegative
                                        ? "You'll Give"
                                        : "You'll Get");
                            final String? dateStr =
                                account['created_at'] as String?;
                            final String formattedDate = _formatDate(dateStr);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: InkWell(
                                onTap: () {
                                  context
                                      .pushNamed(
                                        'admin-account-detail',
                                        pathParameters: {
                                          'id': account['id'] as String,
                                        },
                                        extra: {'name': account['name']},
                                      )
                                      .then((_) => _fetchAccounts());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Left Side: Name and Date
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              account['name'] as String? ??
                                                  'No Name',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Right Side: Balance and Status + Menu
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₹${balance.abs().toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (!isZero) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  statusText,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editAccount(account);
                                              } else if (value == 'delete') {
                                                _deleteAccount(account['id']);
                                              }
                                            },
                                            itemBuilder:
                                                (
                                                  BuildContext context,
                                                ) => <PopupMenuEntry<String>>[
                                                  const PopupMenuItem<String>(
                                                    value: 'edit',
                                                    child: ListTile(
                                                      leading: Icon(Icons.edit),
                                                      title: Text('Edit'),
                                                    ),
                                                  ),
                                                  const PopupMenuItem<String>(
                                                    value: 'delete',
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      title: Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
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
            ),
          ],
        ),
      ),
    );
  }
}
