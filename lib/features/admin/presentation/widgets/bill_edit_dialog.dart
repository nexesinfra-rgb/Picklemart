import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../data/bill_model.dart';
import '../../application/bill_controller.dart';
import '../../../catalog/data/product.dart';
import 'product_picker_dialog.dart';

class BillEditDialog extends ConsumerStatefulWidget {
  final Bill bill;

  const BillEditDialog({super.key, required this.bill});

  @override
  ConsumerState<BillEditDialog> createState() => _BillEditDialogState();
}

class _BillEditDialogState extends ConsumerState<BillEditDialog> {
  late List<BillItem> _items;
  late TextEditingController _shippingController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Create a copy of the items to modify
    _items = List.from(widget.bill.billData.items);
    _shippingController = TextEditingController(
      text: widget.bill.billData.shipping.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _shippingController.dispose();
    super.dispose();
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      final item = _items[index];
      final newQuantity = item.quantity + change;

      if (newQuantity > 0) {
        _items[index] = BillItem(
          productId: item.productId,
          productName: item.productName,
          sku: item.sku,
          imageUrl: item.imageUrl,
          quantity: newQuantity,
          unitPrice: item.unitPrice,
          totalPrice: item.unitPrice * newQuantity,
          variantAttributes: item.variantAttributes,
          measurementUnit: item.measurementUnit,
          category: item.category,
        );
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _addProduct() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ProductPickerDialog(),
    );

    if (result != null && result['product'] is Product) {
      final product = result['product'] as Product;
      final quantity = result['quantity'] as int? ?? 1;

      // Check if product already exists
      final existingIndex = _items.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingIndex >= 0) {
        // Update quantity if exists
        _updateQuantity(existingIndex, quantity);
      } else {
        // Add new item
        setState(() {
          _items.add(
            BillItem(
              productId: product.id,
              productName: product.name,
              imageUrl: product.imageUrl,
              quantity: quantity,
              unitPrice: product.finalPrice,
              totalPrice: product.finalPrice * quantity,
              category:
                  product.categories.isNotEmpty
                      ? product.categories.first
                      : null,
            ),
          );
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill must have at least one item')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Recalculate totals
      double subtotal = 0;
      for (final item in _items) {
        subtotal += item.totalPrice;
      }

      final shipping = double.tryParse(_shippingController.text) ?? 0.0;
      final total = subtotal + shipping;

      final newBillData = BillData(
        items: _items,
        subtotal: subtotal,
        tax: 0, // Explicitly removing tax as requested
        shipping: shipping,
        total: total,
        oldDue: widget.bill.billData.oldDue,
        receivedAmount: widget.bill.billData.receivedAmount,
        customerInfo: widget.bill.billData.customerInfo,
        orderInfo: widget.bill.billData.orderInfo,
        companyInfo: widget.bill.billData.companyInfo,
        manufacturerInfo: widget.bill.billData.manufacturerInfo,
      );

      await ref
          .read(billControllerProvider.notifier)
          .updateBill(billId: widget.bill.id, billData: newBillData);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update bill: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Bill Items'),
          leading: IconButton(
            icon: const Icon(Ionicons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Image or Icon
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              image:
                                  item.imageUrl != null
                                      ? DecorationImage(
                                        image: NetworkImage(item.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                item.imageUrl == null
                                    ? const Icon(
                                      Ionicons.image_outline,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${item.unitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Controls
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Ionicons.remove_circle_outline,
                                ),
                                onPressed: () => _updateQuantity(index, -1),
                                color:
                                    item.quantity > 1
                                        ? Colors.blue
                                        : Colors.grey,
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Ionicons.add_circle_outline),
                                onPressed: () => _updateQuantity(index, 1),
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          // Delete
                          IconButton(
                            icon: const Icon(
                              Ionicons.trash_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom Summary and Add Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Shipping Field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _shippingController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Shipping Charges',
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(
                          () {},
                        ); // Trigger rebuild to update total if we show it dynamically
                      },
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${(_items.fold<double>(0, (sum, item) => sum + item.totalPrice) + (double.tryParse(_shippingController.text) ?? 0)).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addProduct,
                      icon: const Icon(Ionicons.add),
                      label: const Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
