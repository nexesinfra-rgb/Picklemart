import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../data/order_model.dart';
import '../data/order_repository.dart';
import '../../cart/application/cart_controller.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../../catalog/data/product.dart';
import '../../auth/application/auth_controller.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/utils/order_utils.dart';
import 'widgets/select_orders_dialog.dart';

/// Editable order item model to track quantity changes
class EditableOrderItem {
  final OrderItem originalItem;
  int quantity;
  Product? product;
  Variant? variant;

  EditableOrderItem({
    required this.originalItem,
    required this.quantity,
    this.product,
    this.variant,
  });

  double get totalPrice => originalItem.price * quantity;
  bool get isRemoved => quantity <= 0;
}

class EditReorderScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String? templateId;
  const EditReorderScreen({super.key, required this.orderId, this.templateId});

  @override
  ConsumerState<EditReorderScreen> createState() => _EditReorderScreenState();
}

class _EditReorderScreenState extends ConsumerState<EditReorderScreen> {
  List<EditableOrderItem> _editableItems = [];
  bool _isLoading = true;
  bool _isAddingToCart = false;
  Order? _order;

  @override
  void initState() {
    super.initState();
    if (widget.orderId.isNotEmpty) {
      _loadOrder();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTemplate() async {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadOrder() async {
    try {
      final orderAsync = ref.read(orderByIdProvider(widget.orderId));
      final order = await orderAsync.when(
        data: (order) => Future.value(order),
        loading: () => Future.value(null),
        error: (_, __) => Future.value(null),
      );

      if (order == null || !mounted) return;

      // Get all products to match order items
      final products = ref.read(allProductsProvider);

      // Create editable items
      final editableItems = <EditableOrderItem>[];
      for (final orderItem in order.items) {
        try {
          // Find product by ID
          final product = products.firstWhere((p) => p.id == orderItem.id);

          // Find matching variant if size/color exists
          Variant? variant;
          if ((orderItem.size != null || orderItem.color != null) &&
              product.variants.isNotEmpty) {
            try {
              variant = product.variants.firstWhere((v) {
                final sizeMatch =
                    orderItem.size == null ||
                    v.attributes['Size'] == orderItem.size;
                final colorMatch =
                    orderItem.color == null ||
                    v.attributes['Color'] == orderItem.color;
                return sizeMatch && colorMatch;
              });
            } catch (_) {
              // Variant not found, continue without variant
              variant = null;
            }
          }

          editableItems.add(
            EditableOrderItem(
              originalItem: orderItem,
              quantity: orderItem.quantity,
              product: product,
              variant: variant,
            ),
          );
        } catch (e) {
          // Product not found, still add item but mark as unavailable
          editableItems.add(
            EditableOrderItem(
              originalItem: orderItem,
              quantity: orderItem.quantity,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _order = order;
          _editableItems = editableItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      _editableItems[index].quantity = newQuantity.clamp(0, 999);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
    });
  }

  int get _totalItems {
    return _editableItems
        .where((item) => !item.isRemoved && item.product != null)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  double get _estimatedTotal {
    return _editableItems
        .where((item) => !item.isRemoved && item.product != null)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  bool get _hasValidItems {
    return _editableItems.any(
      (item) => !item.isRemoved && item.product != null && item.quantity > 0,
    );
  }

  Future<void> _addItemsFromOrders(List<Order> orders) async {
    // Get all products to match order items
    final products = ref.read(allProductsProvider);

    // Create editable items from selected orders
    final newEditableItems = <EditableOrderItem>[];

    for (final order in orders) {
      for (final orderItem in order.items) {
        // Check if item already exists (by product ID and variant)
        final existingIndex = _editableItems.indexWhere((item) {
          if (item.originalItem.id != orderItem.id) return false;
          if (item.originalItem.size != orderItem.size) return false;
          if (item.originalItem.color != orderItem.color) return false;
          return true;
        });

        if (existingIndex >= 0) {
          // Merge quantities for existing items
          setState(() {
            _editableItems[existingIndex].quantity += orderItem.quantity;
          });
        } else {
          // Add as new item
          try {
            // Find product by ID
            final product = products.firstWhere((p) => p.id == orderItem.id);

            // Find matching variant if size/color exists
            Variant? variant;
            if ((orderItem.size != null || orderItem.color != null) &&
                product.variants.isNotEmpty) {
              try {
                variant = product.variants.firstWhere((v) {
                  final sizeMatch =
                      orderItem.size == null ||
                      v.attributes['Size'] == orderItem.size;
                  final colorMatch =
                      orderItem.color == null ||
                      v.attributes['Color'] == orderItem.color;
                  return sizeMatch && colorMatch;
                });
              } catch (_) {
                variant = null;
              }
            }

            newEditableItems.add(
              EditableOrderItem(
                originalItem: orderItem,
                quantity: orderItem.quantity,
                product: product,
                variant: variant,
              ),
            );
          } catch (e) {
            // Product not found, still add item but mark as unavailable
            newEditableItems.add(
              EditableOrderItem(
                originalItem: orderItem,
                quantity: orderItem.quantity,
              ),
            );
          }
        }
      }
    }

    if (newEditableItems.isNotEmpty && mounted) {
      setState(() {
        _editableItems.addAll(newEditableItems);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${newEditableItems.length} item${newEditableItems.length != 1 ? 's' : ''} from selected orders',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveTemplate() async {
    if (!_hasValidItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show dialog to enter template name
    final templateName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Save Template'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Template Name',
              hintText: 'e.g., Weekly Order, Monthly Supplies',
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (templateName == null || templateName.isEmpty) return;

    try {
      final authState = ref.read(authControllerProvider);
      if (!authState.isAuthenticated || authState.userId == null) {
        throw Exception('User not authenticated');
      }

      // Get valid items (not removed and have product)
      final validItems =
          _editableItems
              .where((item) => !item.isRemoved && item.product != null)
              .map((item) => item.originalItem)
              .toList();

      if (validItems.isEmpty) {
        throw Exception('No valid items to save');
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Saving template...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      await Future.value();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Template saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Templates disabled
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final errorMessage = e.toString();
        String userMessage;

        if (errorMessage.contains('saved_order_templates') &&
            errorMessage.contains('not find')) {
          userMessage =
              'Database table not found. Please run the migration in Supabase SQL Editor.';
        } else if (errorMessage.contains('unique constraint') ||
            errorMessage.contains('duplicate')) {
          userMessage =
              'A template with this name already exists. Please use a different name.';
        } else {
          userMessage =
              'Failed to save template: ${errorMessage.length > 100 ? "${errorMessage.substring(0, 100)}..." : errorMessage}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _addToCartAndContinue() async {
    if (!_hasValidItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to cart'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Adding items to cart...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      int addedCount = 0;
      int notFoundCount = 0;
      final errors = <String>[];

      for (final editableItem in _editableItems) {
        // Skip removed items or items without product
        if (editableItem.isRemoved || editableItem.product == null) {
          continue;
        }

        try {
          // Add to cart with edited quantity
          await ref
              .read(cartProvider.notifier)
              .add(
                editableItem.product!,
                variant: editableItem.variant,
                qty: editableItem.quantity,
              );

          addedCount++;
        } catch (e) {
          notFoundCount++;
          errors.add('${editableItem.originalItem.name}: ${e.toString()}');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (addedCount > 0) {
          // Show brief success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                notFoundCount > 0
                    ? '$addedCount item${addedCount > 1 ? 's' : ''} added. $notFoundCount item${notFoundCount > 1 ? 's' : ''} not available.'
                    : '$addedCount item${addedCount > 1 ? 's' : ''} added to cart',
              ),
              backgroundColor: notFoundCount > 0 ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to home page after a brief delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            context.goNamed('home');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No items could be added to cart. ${errors.isNotEmpty ? errors.first : 'Products may no longer be available.'}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add items to cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    final sectionSpacing = Responsive.getSectionSpacing(width);

    return SafeScaffold(
      appBar: AppBar(
        title: Text(
          _order != null
              ? 'Edit Order ${_order!.orderTag}'
              : 'Edit & Reorder',
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.add_circle_outline),
            tooltip: 'Add from Other Orders',
            onPressed: () async {
              await showDialog(
                context: context,
                builder:
                    (context) => SelectOrdersDialog(
                      onOrdersSelected: _addItemsFromOrders,
                    ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _editableItems.isEmpty
              ? Center(
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.document_text_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Card
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Summary',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Items:',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '$_totalItems',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Estimated Total:',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '₹${_estimatedTotal.toStringAsFixed(2)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: sectionSpacing),

                          // Editable Items List
                          ...List.generate(_editableItems.length, (index) {
                            final item = _editableItems[index];
                            final isUnavailable = item.product == null;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: cardPadding * 0.75,
                              ),
                              child: Card(
                                elevation: 2,
                                clipBehavior: Clip.hardEdge,
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 64,
                                            height: 64,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child:
                                                  item.originalItem.image
                                                          .startsWith('http')
                                                      ? Image.network(
                                                        item.originalItem.image,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Container(
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade200,
                                                              child: Icon(
                                                                Ionicons
                                                                    .image_outline,
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade400,
                                                              ),
                                                            ),
                                                      )
                                                      : Image.asset(
                                                        item.originalItem.image
                                                                .startsWith(
                                                                  'assets/',
                                                                )
                                                            ? item
                                                                .originalItem
                                                                .image
                                                            : 'assets/${item.originalItem.image}',
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Container(
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade200,
                                                              child: Icon(
                                                                Ionicons
                                                                    .image_outline,
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade400,
                                                              ),
                                                            ),
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.originalItem.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (item.originalItem.size !=
                                                        null ||
                                                    item.originalItem.color !=
                                                        null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    [
                                                      if (item
                                                              .originalItem
                                                              .size !=
                                                          null)
                                                        'Size: ${item.originalItem.size}',
                                                      if (item
                                                              .originalItem
                                                              .color !=
                                                          null)
                                                        'Color: ${item.originalItem.color}',
                                                    ].join(' • '),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade600,
                                                        ),
                                                  ),
                                                ],
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      '₹${item.originalItem.price.toStringAsFixed(2)}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade600,
                                                          ),
                                                    ),
                                                    if (isUnavailable)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .orange
                                                                  .shade100,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Unavailable',
                                                          style: Theme.of(
                                                                context,
                                                              )
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color:
                                                                    Colors
                                                                        .orange
                                                                        .shade800,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
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
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          if (!isUnavailable) ...[
                                            Row(
                                              children: [
                                                ResponsiveIconButton(
                                                  onPressed:
                                                      () => _updateQuantity(
                                                        index,
                                                        item.quantity - 1,
                                                      ),
                                                  icon: const Icon(
                                                    Ionicons
                                                        .remove_circle_outline,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16.0,
                                                      ),
                                                  child: Text(
                                                    '${item.quantity}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                ResponsiveIconButton(
                                                  onPressed:
                                                      () => _updateQuantity(
                                                        index,
                                                        item.quantity + 1,
                                                      ),
                                                  icon: const Icon(
                                                    Ionicons.add_circle_outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '₹${item.totalPrice.toStringAsFixed(2)}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed:
                                                      () => _removeItem(index),
                                                  icon: const Icon(
                                                    Ionicons.trash_outline,
                                                    size: 20,
                                                  ),
                                                  color: Colors.red,
                                                  tooltip: 'Remove',
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 40,
                                                        minHeight: 40,
                                                      ),
                                                  padding: EdgeInsets.zero,
                                                ),
                                              ],
                                            ),
                                          ] else ...[
                                            Expanded(
                                              child: Text(
                                                'This product is no longer available',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color: Colors.orange.shade700,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed:
                                                  () => _removeItem(index),
                                              icon: const Icon(
                                                Ionicons.trash_outline,
                                                size: 20,
                                              ),
                                              color: Colors.red,
                                              tooltip: 'Remove',
                                              constraints: const BoxConstraints(
                                                minWidth: 40,
                                                minHeight: 40,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(cardPadding),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_hasValidItems && _editableItems.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                _editableItems.every(
                                      (item) => item.product == null,
                                    )
                                    ? 'All items are unavailable'
                                    : 'Please add at least one item to continue',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.orange.shade700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _isAddingToCart || !_hasValidItems
                                      ? null
                                      : _addToCartAndContinue,
                              icon:
                                  _isAddingToCart
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Icon(Ionicons.cart_outline),
                              label: Text(
                                _isAddingToCart
                                    ? 'Adding to Cart...'
                                    : 'Add to Cart & Continue Shopping',
                              ),
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: cardPadding * 0.75,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
