import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../data/order_model.dart';
import '../../data/orders_infinite_scroll_provider.dart';
import '../../../../core/layout/responsive.dart';
import '../../../../core/utils/order_utils.dart';

class SelectOrdersDialog extends ConsumerStatefulWidget {
  final Function(List<Order>) onOrdersSelected;

  const SelectOrdersDialog({
    super.key,
    required this.onOrdersSelected,
  });

  @override
  ConsumerState<SelectOrdersDialog> createState() =>
      _SelectOrdersDialogState();
}

class _SelectOrdersDialogState extends ConsumerState<SelectOrdersDialog> {
  final Set<String> _selectedOrderIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _addSelectedOrders() {
    final ordersState = ref.read(ordersInfiniteScrollProvider);
    final selectedOrders = ordersState.orders
        .where((order) => _selectedOrderIds.contains(order.id))
        .toList();

    if (selectedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one order'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.onOrdersSelected(selectedOrders);
    if (context.mounted) {
      context.pop();
    }
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_searchQuery.isEmpty) return orders;

    return orders.where((order) {
      final orderTag = order.orderTag.toLowerCase();
      final dateStr = DateFormat('MMM dd, yyyy').format(order.orderDate);
      return orderTag.contains(_searchQuery) ||
          dateStr.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersInfiniteScrollProvider);
    final orders = _getFilteredOrders(ordersState.orders);
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);

    return Dialog(
      child: Container(
        width: width > 600 ? 600 : width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Ionicons.close_outline),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Ionicons.search_outline),
                hintText: 'Search by order number or date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Orders List
            Expanded(
              child: orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Ionicons.receipt_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No orders found'
                                : 'No orders match your search',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final isSelected = _selectedOrderIds.contains(order.id);

                        return Card(
                          margin: EdgeInsets.only(bottom: cardPadding * 0.5),
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : null,
                          child: InkWell(
                            onTap: () => _toggleOrderSelection(order.id),
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        _toggleOrderSelection(order.id),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.orderTag,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(order.orderDate),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Ionicons.checkmark_circle
                                        : Ionicons.ellipse_outline,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _addSelectedOrders,
                    icon: const Icon(Ionicons.add_outline),
                    label: Text(
                      'Add ${_selectedOrderIds.isEmpty ? '' : '(${_selectedOrderIds.length}) '}Selected',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

