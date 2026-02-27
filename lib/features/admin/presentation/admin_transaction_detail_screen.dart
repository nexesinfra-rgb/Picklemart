import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import '../domain/cash_book_entry.dart';
import '../data/cash_book_repository.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_auth_guard.dart';

class AdminTransactionDetailScreen extends ConsumerStatefulWidget {
  final CashBookEntry entry;
  final String accountId;
  final String accountName;

  const AdminTransactionDetailScreen({
    super.key,
    required this.entry,
    required this.accountId,
    required this.accountName,
  });

  @override
  ConsumerState<AdminTransactionDetailScreen> createState() => _AdminTransactionDetailScreenState();
}

class _AdminTransactionDetailScreenState extends ConsumerState<AdminTransactionDetailScreen> {
  late CashBookEntry _entry;
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _amountController = TextEditingController(text: _entry.amount.toString());
    _descriptionController = TextEditingController(text: _entry.description);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_entry.id == null) return;

    setState(() => _isLoading = true);
    try {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final description = _descriptionController.text;

      final updates = {
        'amount': amount,
        'description': description,
      };

      await ref.read(cashBookRepositoryProvider).updateEntry(
        _entry.id!,
        updates,
        relatedId: widget.accountId,
      );

      setState(() {
        _entry = _entry.copyWith(
          amount: amount,
          description: description,
        );
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating transaction: $e')),
        );
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(cashBookRepositoryProvider).deleteEntry(
        _entry.id!,
        relatedId: widget.accountId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );
        Navigator.pop(context, true); // Return true to refresh parent
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPayIn = _entry.type == CashBookEntryType.payin;
    final statusColor = isPayIn ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final statusBgColor = isPayIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final statusText = isPayIn ? 'RECEIVED' : 'PAID';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // Always return true to ensure refresh
        return false;
      },
      child: AdminAuthGuard(
        child: AdminScaffold(
          title: 'Transaction Details',
          showBackButton: true,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),



                      // Amount Field
                      _isEditing
                          ? _buildEditField(
                              controller: _amountController,
                              label: isPayIn ? 'Amount Received' : 'Amount Paid',
                              keyboardType: TextInputType.number,
                            )
                          : _buildDetailRow(
                              label: isPayIn ? 'Amount Received' : 'Amount Paid',
                              value: '₹${_entry.amount.toStringAsFixed(2)}',
                              icon: isPayIn ? Ionicons.arrow_down_circle_outline : Ionicons.arrow_up_circle_outline,
                              valueColor: statusColor,
                              valueSize: 24,
                              valueWeight: FontWeight.bold,
                            ),
                      const SizedBox(height: 16),

                      // Description Field
                      _isEditing
                          ? _buildEditField(
                              controller: _descriptionController,
                              label: 'Description',
                              maxLines: 3,
                            )
                          : _buildDetailRow(
                              label: 'Description',
                              value: _entry.description.isEmpty ? 'No description' : _entry.description,
                              icon: Ionicons.document_text_outline,
                            ),
                      const SizedBox(height: 16),

                      // Date (Read-only for now based on request, but could be editable)
                      _buildDetailRow(
                        label: 'Date',
                        value: DateFormat('dd MMM yyyy, hh:mm a').format(_entry.date),
                        icon: Ionicons.calendar_outline,
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          if (_isEditing)
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _saveChanges,
                                icon: const Icon(Icons.save),
                                label: const Text('Save Changes'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => setState(() => _isEditing = true),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          if (!_isEditing)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _deleteTransaction,
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            )
                          else
                             Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Reset changes
                                  setState(() {
                                    _amountController.text = _entry.amount.toString();
                                    _descriptionController.text = _entry.description;
                                    _isEditing = false;
                                  });
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    double valueSize = 16,
    FontWeight valueWeight = FontWeight.normal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.black87,
                    fontSize: valueSize,
                    fontWeight: valueWeight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
