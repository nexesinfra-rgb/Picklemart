import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

class AdminActionBottomBar extends StatelessWidget {
  final String? customerId;
  final String? manufacturerId;
  final VoidCallback? onRefresh;

  const AdminActionBottomBar({
    super.key,
    this.customerId,
    this.manufacturerId,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.pushNamed(
                    'admin-purchase-order-form',
                    queryParameters:
                        manufacturerId != null
                            ? {'manufacturerId': manufacturerId}
                            : {},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Add Purchase'),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _showTransactionOptions(context),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Ionicons.add, color: Colors.blue, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  context.pushNamed(
                    'admin-create-order',
                    queryParameters:
                        customerId != null ? {'customerId': customerId} : {},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Add Sale'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Transactions',
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Ionicons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(sheetContext, 'Sale Transactions'),
                        const SizedBox(height: 16),
                        _buildGridOptions(sheetContext, [
                          _OptionItem(
                            icon: Ionicons.receipt_outline,
                            label: 'Sale',
                            onTap: () {
                              Navigator.pop(sheetContext);
                              context.pushNamed('admin-create-order');
                            },
                          ),
                          _OptionItem(
                            icon: Ionicons.download_outline,
                            label: 'Payment-In',
                            onTap: () {
                              Navigator.pop(sheetContext);
                              context
                                  .pushNamed(
                                    'admin-add-payment',
                                    extra: {
                                      'customerId': customerId,
                                      'manufacturerId': manufacturerId,
                                    },
                                  )
                                  .then((saved) {
                                    if (!context.mounted) return;
                                    if (saved == true) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Payment In saved successfully',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      if (onRefresh != null) {
                                        onRefresh!();
                                      }
                                    }
                                  });
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          sheetContext,
                          'Manufacturer Transactions',
                        ),
                        const SizedBox(height: 16),
                        _buildGridOptions(sheetContext, [
                          _OptionItem(
                            icon: Ionicons.business_outline,
                            label: 'Payment Out',
                            onTap: () {
                              Navigator.pop(sheetContext);
                              context
                                  .pushNamed(
                                    'admin-payment-out',
                                    extra: {
                                      'manufacturerId': manufacturerId,
                                      'customerId': customerId,
                                    },
                                  )
                                  .then((saved) {
                                    if (!context.mounted) return;
                                    if (saved == true && onRefresh != null) {
                                      onRefresh!();
                                    }
                                  });
                            },
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSectionHeader(sheetContext, 'Other Transactions'),
                        const SizedBox(height: 16),
                        _buildGridOptions(sheetContext, [
                          _OptionItem(
                            icon: Ionicons.book_outline,
                            label: 'Cash Book',
                            onTap: () {
                              Navigator.pop(sheetContext);
                              context.pushNamed('admin-credit-system');
                            },
                          ),
                        ]),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildGridOptions(BuildContext context, List<_OptionItem> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 8, // Reduced spacing
      childAspectRatio:
          0.7, // Adjusted aspect ratio to give more vertical space
      children:
          items.map((item) {
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Align to top
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    // Use Expanded to handle text overflow
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _OptionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _OptionItem({required this.icon, required this.label, required this.onTap});
}
