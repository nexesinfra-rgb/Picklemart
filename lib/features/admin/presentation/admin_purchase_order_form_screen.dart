import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/product_picker_dialog.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/measurement.dart';
import '../domain/purchase_order.dart';
import '../application/purchase_order_controller.dart';
import '../application/manufacturer_controller.dart';
import '../application/bill_controller.dart';
import '../services/purchase_order_pdf_service.dart';
import '../domain/manufacturer.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/order_repository_provider.dart';

class AdminPurchaseOrderFormScreen extends ConsumerStatefulWidget {
  final String? purchaseOrderId; // If provided, we're editing
  final String? manufacturerId; // If provided, pre-select manufacturer
  final String? orderId; // If provided, we're converting from an order
  final String?
  paymentReceiptId; // If provided, we're converting from a payment receipt
  final String? customerId; // If provided with payment receipt
  final String? receiptNumber; // If provided with payment receipt
  final double? paymentAmount;
  final double? initialShipping;

  const AdminPurchaseOrderFormScreen({
    super.key,
    this.purchaseOrderId,
    this.manufacturerId,
    this.orderId,
    this.paymentReceiptId,
    this.customerId,
    this.receiptNumber,
    this.paymentAmount,
    this.initialShipping,
  });

  @override
  ConsumerState<AdminPurchaseOrderFormScreen> createState() =>
      _AdminPurchaseOrderFormScreenState();
}

class _AdminPurchaseOrderFormScreenState
    extends ConsumerState<AdminPurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late TextEditingController _shippingController;
  late TextEditingController _paidAmountController;
  final _shippingFocusNode = FocusNode();

  String? _selectedEntityId; // Manufacturer ID
  String? _selectedEntityName; // Display name
  Manufacturer? _selectedManufacturer;
  DateTime _purchaseDate = DateTime.now();
  DateTime? _expectedDeliveryDate;
  PurchaseOrderStatus _status = PurchaseOrderStatus.pending;
  final double _tax = 0.0;
  double _shipping = 0.0;
  double _paidAmount = 0.0;
  String _notes = '';
  String? _deliveryLocation;
  String? _transportationName;
  String? _transportationPhone;

  List<PurchaseOrderItem> _items = [];
  Order? _sourceOrder;
  bool _isLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _shippingController = TextEditingController(text: '0.00');
    // Initialize Paid Amount Controller early to avoid LateInitializationError
    _paidAmountController = TextEditingController(text: '');
    // Use addPostFrameCallback to avoid modifying providers during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  @override
  void dispose() {
    _shippingController.dispose();
    _paidAmountController.dispose();
    _shippingFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (_isInitialized) return;
    _isInitialized = true;

    setState(() => _isLoading = true);

    try {
      // Load manufacturers if not loaded
      var manufacturerState = ref.read(manufacturerControllerProvider);
      if (manufacturerState.manufacturers.isEmpty) {
        await ref
            .read(manufacturerControllerProvider.notifier)
            .loadManufacturers();
        if (!mounted) return;
        // Refresh local state variable after loading
        manufacturerState = ref.read(manufacturerControllerProvider);
      }

      // If initial manufacturer is provided
      if (widget.manufacturerId != null && _selectedEntityId == null) {
        _selectedEntityId = widget.manufacturerId;
        final matching =
            manufacturerState.manufacturers
                .where((m) => m.id == _selectedEntityId)
                .toList();
        if (matching.isNotEmpty) {
          _selectedManufacturer = matching.first;
          _selectedEntityName = _selectedManufacturer!.businessName;
        }
      }

      // If editing, load existing purchase order
      final purchaseOrderId = widget.purchaseOrderId;
      if (purchaseOrderId != null && purchaseOrderId.isNotEmpty) {
        final purchaseOrder = await ref
            .read(purchaseOrderControllerProvider.notifier)
            .getPurchaseOrderById(purchaseOrderId);

        if (!mounted) return;

        if (purchaseOrder != null) {
          _selectedEntityId = purchaseOrder.manufacturerId;

          // Load manufacturer name for display
          if (_selectedEntityId != null) {
            final manufacturerState = ref.read(manufacturerControllerProvider);
            if (manufacturerState.manufacturers.isEmpty) {
              await ref
                  .read(manufacturerControllerProvider.notifier)
                  .loadManufacturers();
              if (!mounted) return;
            }
            final matching =
                manufacturerState.manufacturers
                    .where((m) => m.id == _selectedEntityId)
                    .toList();
            if (matching.isNotEmpty) {
              _selectedManufacturer = matching.first;
              _selectedEntityName = _selectedManufacturer!.businessName;
            }
          }

          _purchaseDate = purchaseOrder.purchaseDate;
          _expectedDeliveryDate = purchaseOrder.expectedDeliveryDate;
          _status = purchaseOrder.status;
          _shipping = purchaseOrder.shipping;
          _paidAmount = purchaseOrder.paidAmount;
          _notes = purchaseOrder.notes ?? '';
          _deliveryLocation = purchaseOrder.deliveryLocation;
          _transportationName = purchaseOrder.transportationName;
          _transportationPhone = purchaseOrder.transportationPhone;
          _items = List.from(purchaseOrder.items);

          // Update controller with total shipping
          _updateShippingController();
          _updatePaidAmountController();
        }
      }
      // If converting from payment receipt
      else if (widget.paymentReceiptId != null) {
        _paidAmount = 0.0; // Don't auto-fill paid amount from receipt
        _notes =
            'Created from Payment Receipt #${widget.receiptNumber ?? widget.paymentReceiptId}';

        // Load order items if orderId is provided via receipt
        if (widget.orderId != null && widget.orderId!.isNotEmpty) {
          await _loadSourceOrderItems(widget.orderId!);
        }
        _updatePaidAmountController();
      }
      // If converting from order, load order data and include ALL products
      else if (widget.orderId != null) {
        await _loadSourceOrderItems(widget.orderId!);
      }

      // If initial shipping is provided and not already set by loading order/edit
      if (widget.initialShipping != null && _shipping == 0.0) {
        _shipping = widget.initialShipping!;
        _updateShippingController();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSourceOrderItems(String orderId) async {
    final orderRepository = ref.read(orderRepositoryProvider);
    final order = await orderRepository.getOrderById(orderId);

    // Fetch items with cost prices for accurate purchase order creation
    final itemsWithCost = await ref
        .read(billRepositoryProvider)
        .getOrderItemsWithCostPrices(orderId);

    if (order != null) {
      _sourceOrder = order;
      // Use explicitly passed shipping if available, otherwise use order shipping
      _shipping = widget.initialShipping ?? order.shipping;

      if (itemsWithCost.isNotEmpty) {
        _items =
            itemsWithCost.map((item) {
              final productData = item['products'] as Map<String, dynamic>?;
              final variantsList = item['product_variants'] as List<dynamic>?;
              final variantData =
                  (variantsList != null && variantsList.isNotEmpty)
                      ? variantsList.first as Map<String, dynamic>?
                      : null;

              double unitPrice = 0.0;

              // Try variant cost price first
              if (variantData != null && variantData['cost_price'] != null) {
                unitPrice = (variantData['cost_price'] as num).toDouble();
              }
              // Then try product cost price
              else if (productData != null &&
                  productData['cost_price'] != null) {
                unitPrice = (productData['cost_price'] as num).toDouble();
              }

              final quantity = (item['quantity'] as num).toInt();

              // Get category from product data to follow app standards
              String? category;
              if (productData != null && productData['categories'] != null) {
                final categories = productData['categories'];
                if (categories is List && categories.isNotEmpty) {
                  category = categories.first.toString();
                } else if (categories is String && categories.isNotEmpty) {
                  category = categories;
                }
              }

              return PurchaseOrderItem(
                id: '',
                productId: item['product_id'] as String,
                name: item['name'] as String,
                image: item['image'] as String,
                quantity: quantity,
                unitPrice: unitPrice,
                totalPrice: unitPrice * quantity,
                category: category ?? 'Uncategorized',
                variantId: item['variant_id'] as String?,
                measurementUnit: item['measurement_unit'] as String?,
              );
            }).toList();
      } else {
        // Fallback to order items if cost fetching fails
        _items =
            order.items.map((orderItem) {
              return PurchaseOrderItem(
                id: '',
                productId: orderItem.id,
                name: orderItem.name,
                image: orderItem.image,
                quantity: orderItem.quantity,
                unitPrice: 0.0, // Default to 0 to encourage manual check
                totalPrice: 0.0,
                category: 'Uncategorized',
              );
            }).toList();
      }

      // Update controller with total shipping
      _updateShippingController();

      // Show confirmation that all products are included
      if (mounted && _items.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${_items.length} product(s) from order ${order.orderNumber} included',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    }
  }

  double get _subtotal {
    return _items.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _itemsShipping {
    return _items.fold<double>(0.0, (sum, item) => sum + item.shippingCost);
  }

  double get _total {
    return _subtotal + _shipping + _itemsShipping;
  }

  void _updateShippingController() {
    _shippingController.text = _shipping.toStringAsFixed(2);
  }

  void _updatePaidAmountController() {
    if (_paidAmount == 0) {
      _paidAmountController.text = '';
    } else {
      _paidAmountController.text =
          _paidAmount % 1 == 0
              ? _paidAmount.toInt().toString()
              : _paidAmount.toStringAsFixed(2);
    }
  }

  void _updateItemQuantity(int index, int quantity) {
    if (quantity <= 0) return;
    setState(() {
      final item = _items[index];
      _items[index] = item.copyWith(
        quantity: quantity,
        totalPrice: quantity * item.unitPrice,
      );
    });
  }

  void _updateItemPrice(int index, double price) {
    if (price < 0) return;
    setState(() {
      final item = _items[index];
      _items[index] = item.copyWith(
        unitPrice: price,
        totalPrice: item.quantity * price,
      );
    });
  }

  void _updateItemShipping(int index, double shipping) {
    if (shipping < 0) return;
    setState(() {
      final item = _items[index];
      _items[index] = item.copyWith(shippingCost: shipping);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _addProductItem() async {
    final excludeIds = _items.map((item) => item.productId).toList();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ProductPickerDialog(excludeProductIds: excludeIds),
    );

    if (result != null && mounted) {
      final product = result['product'] as Product?;
      final quantity = result['quantity'] as int?;

      if (product == null || quantity == null) return;

      setState(() {
        // Try to get measurement value from different sources
        String? mUnit;
        if (product.measurement != null) {
          // 1. Try default unit pricing
          var pricing = product.measurement!.getPricingForUnit(
            product.measurement!.defaultUnit,
          );

          // 2. Fallback to first available pricing
          if (pricing == null &&
              product.measurement!.pricingOptions.isNotEmpty) {
            pricing = product.measurement!.pricingOptions.first;
          }

          if (pricing != null) {
            if (pricing.weight != null && pricing.weight! > 0) {
              mUnit = pricing.weight!.toStringAsFixed(0);
            } else if (pricing.volume != null && pricing.volume! > 0) {
              mUnit = pricing.volume!.toStringAsFixed(0);
            } else if (pricing.count != null && pricing.count! > 0) {
              mUnit = pricing.count!.toString();
            } else {
              mUnit = pricing.unit.shortName;
            }
          }
        }

        // 3. Fallback to SKU if it looks like a measurement (numeric or starts with number)
        if ((mUnit == null || mUnit.isEmpty) &&
            product.sku != null &&
            product.sku!.isNotEmpty) {
          // If SKU contains numbers, try to extract them
          final match = RegExp(r'\d+').firstMatch(product.sku!);
          if (match != null) {
            mUnit = match.group(0);
          }
        }

        // 4. Final fallback to subtitle - extract numeric value if possible
        if ((mUnit == null || mUnit.isEmpty) &&
            product.subtitle != null &&
            product.subtitle!.isNotEmpty) {
          final match = RegExp(r'\d+').firstMatch(product.subtitle!);
          if (match != null) {
            mUnit = match.group(0);
          } else {
            mUnit = product.subtitle;
          }
        }

        _items.add(
          PurchaseOrderItem(
            id: '',
            productId: product.id,
            name: product.name,
            image: product.imageUrl,
            quantity: quantity,
            unitPrice: product.costPrice ?? 0.0,
            totalPrice: quantity * (product.costPrice ?? 0.0),
            category:
                product.categories.isNotEmpty
                    ? product.categories.first
                    : 'Uncategorized',
            measurementUnit: mUnit,
          ),
        );
      });
    }
  }

  Future<void> _savePurchaseOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEntityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a manufacturer')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      PurchaseOrder? purchaseOrder;

      if (widget.purchaseOrderId != null) {
        // Update existing purchase order
        final existing = await ref
            .read(purchaseOrderControllerProvider.notifier)
            .getPurchaseOrderById(widget.purchaseOrderId!);

        if (existing != null) {
          // Invalidate PDF cache before updating
          PurchaseOrderPdfService.clearCache(purchaseOrderId: existing.id);

          purchaseOrder = await ref
              .read(purchaseOrderControllerProvider.notifier)
              .updatePurchaseOrder(
                existing.copyWith(
                  manufacturerId: _selectedEntityId,
                  customerId: null,
                  purchaseDate: _purchaseDate,
                  expectedDeliveryDate: _expectedDeliveryDate,
                  status: _status,
                  subtotal: _subtotal,
                  tax: _tax,
                  shipping: _shipping,
                  total: _total,
                  paidAmount: _paidAmount,
                  notes: _notes.isEmpty ? null : _notes,
                  deliveryLocation:
                      _deliveryLocation?.isEmpty ?? true
                          ? null
                          : _deliveryLocation,
                  transportationName:
                      _transportationName?.isEmpty ?? true
                          ? null
                          : _transportationName,
                  transportationPhone:
                      _transportationPhone?.isEmpty ?? true
                          ? null
                          : _transportationPhone,
                  items: _items,
                ),
              );
        }
      } else if (widget.orderId != null && _sourceOrder != null) {
        // Create from order
        purchaseOrder = await ref
            .read(purchaseOrderControllerProvider.notifier)
            .createPurchaseOrderFromOrder(
              order: _sourceOrder!,
              manufacturerId: _selectedEntityId,
              customerId: null,
              purchaseDate: _purchaseDate,
              expectedDeliveryDate: _expectedDeliveryDate,
              tax: 0.0,
              shipping: _shipping,
              notes: _notes.isEmpty ? null : _notes,
              deliveryLocation:
                  _deliveryLocation?.isEmpty ?? true ? null : _deliveryLocation,
              transportationName:
                  _transportationName?.isEmpty ?? true
                      ? null
                      : _transportationName,
              transportationPhone:
                  _transportationPhone?.isEmpty ?? true
                      ? null
                      : _transportationPhone,
              customItems: _items,
              paidAmount: _paidAmount,
            );
      } else {
        // Create new purchase order
        purchaseOrder = await ref
            .read(purchaseOrderControllerProvider.notifier)
            .createPurchaseOrder(
              manufacturerId: _selectedEntityId,
              customerId: null,
              purchaseDate: _purchaseDate,
              items: _items,
              expectedDeliveryDate: _expectedDeliveryDate,
              tax: _tax,
              shipping: _shipping,
              notes: _notes.isEmpty ? null : _notes,
              deliveryLocation:
                  _deliveryLocation?.isEmpty ?? true ? null : _deliveryLocation,
              transportationName:
                  _transportationName?.isEmpty ?? true
                      ? null
                      : _transportationName,
              transportationPhone:
                  _transportationPhone?.isEmpty ?? true
                      ? null
                      : _transportationPhone,
              status: _status,
              paidAmount: _paidAmount,
            );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (purchaseOrder != null) {
          final balance = purchaseOrder.total - purchaseOrder.paidAmount;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Due: ₹ ${balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.purchaseOrderId != null
                        ? 'Purchase order updated successfully'
                        : 'Purchase order created successfully',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          // Redirect back to list
          if (context.canPop()) {
            context.pop(true);
          } else {
            // Fallback if can't pop (e.g. deep link)
            context.pushReplacementNamed(
              'admin-purchase-order-detail',
              pathParameters: {'id': purchaseOrder.id},
            );
          }
        } else {
          final error = ref.read(purchaseOrderControllerProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save purchase order: ${error ?? "Unknown error"}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title:
            widget.purchaseOrderId != null
                ? 'Edit Purchase Order'
                : 'Create Purchase Order',
        showBackButton: true,
        body:
            _isLoading && !_isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(spacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Manufacturer Selection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Party Selection',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildEntitySelector(
                                        context,
                                        label: 'Select Manufacturer',
                                        value: _selectedEntityName,
                                        onTap: _showEntitySelectionDialog,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Order Details
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.outlineSoft,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Details',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDatePicker(
                                        context,
                                        label: 'Purchase Date',
                                        value: _purchaseDate,
                                        onChanged: (date) {
                                          setState(() => _purchaseDate = date);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDatePicker(
                                        context,
                                        label: 'Expected Delivery',
                                        value: _expectedDeliveryDate,
                                        onChanged: (date) {
                                          setState(
                                            () => _expectedDeliveryDate = date,
                                          );
                                        },
                                        isOptional: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Items
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.outlineSoft,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Items',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    FilledButton.icon(
                                      onPressed: _addProductItem,
                                      icon: const Icon(Ionicons.add, size: 18),
                                      label: const Text('Add Item'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_items.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Ionicons.cart_outline,
                                            size: 48,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.outline,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No items added yet',
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _items.length,
                                    separatorBuilder:
                                        (context, index) => Divider(
                                          height: 24,
                                          color: AppColors.outlineSoft,
                                        ),
                                    itemBuilder:
                                        (context, index) =>
                                            _buildItemRow(index),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Payment & Notes
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.outlineSoft,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Payment & Notes',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _paidAmountController,
                                        decoration: InputDecoration(
                                          labelText: 'Paid Amount',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          prefixText: '₹ ',
                                          filled: true,
                                          fillColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withOpacity(0.3),
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        onChanged: (value) {
                                          setState(() {
                                            _paidAmount =
                                                double.tryParse(value) ?? 0.0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _shippingController,
                                  focusNode: _shippingFocusNode,
                                  decoration: InputDecoration(
                                    labelText: 'General Shipping Charges',
                                    prefixText: '₹ ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.3),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (value) {
                                    setState(() {
                                      _shipping = double.tryParse(value) ?? 0.0;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: _notes,
                                  decoration: InputDecoration(
                                    labelText: 'Notes',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.3),
                                  ),
                                  maxLines: 2,
                                  onChanged: (value) => _notes = value,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Delivery & Transport (Moved and made Dropdown)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.outlineSoft,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            title: Text(
                              'Transportation Details',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            leading: Icon(
                              Ionicons.bus_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      initialValue: _deliveryLocation,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter delivery location';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Delivery Location',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: Icon(
                                          Ionicons.location_outline,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.3),
                                      ),
                                      onChanged:
                                          (value) => _deliveryLocation = value,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: _transportationName,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter transport name';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Transport Name',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: Icon(
                                          Ionicons.business_outline,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.3),
                                      ),
                                      onChanged:
                                          (value) =>
                                              _transportationName = value,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      initialValue: _transportationPhone,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter transport phone';
                                        }
                                        if (!RegExp(
                                          r'^\d{10}$',
                                        ).hasMatch(value)) {
                                          return 'Please enter a valid 10-digit phone number';
                                        }
                                        return null;
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Transport Phone',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        prefixIcon: Icon(
                                          Ionicons.call_outline,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.3),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      onChanged:
                                          (value) =>
                                              _transportationPhone = value,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Summary
                        Card(
                          elevation: 0,
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildSummaryRow('Subtotal', _subtotal),
                                if (_itemsShipping > 0)
                                  _buildSummaryRow(
                                    'Items Shipping',
                                    _itemsShipping,
                                  ),
                                _buildSummaryRow(
                                  'General Shipping',
                                  _shipping,
                                  onTap: () {
                                    _shippingFocusNode.requestFocus();
                                  },
                                ),
                                Divider(color: AppColors.outlineSoft),
                                _buildSummaryRow(
                                  'Total Amount',
                                  _total,
                                  isTotal: true,
                                ),
                                _buildSummaryRow(
                                  'Balance Due',
                                  _total - _paidAmount,
                                  isTotal: true,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _savePurchaseOrder,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      widget.purchaseOrderId != null
                                          ? 'Update Purchase Order'
                                          : 'Create Purchase Order',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
            children: [
              Text(
                '₹ ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTotal ? 18 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Ionicons.create_outline,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Ionicons.image_outline,
                          color: colorScheme.outline,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Quantity : ',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Ionicons.remove_circle_outline,
                          onPressed:
                              () =>
                                  _updateItemQuantity(index, item.quantity - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${item.quantity}${item.measurementUnit != null && item.measurementUnit!.isNotEmpty ? ' X ${item.measurementUnit}' : ''}',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Ionicons.add_circle_outline,
                          onPressed:
                              () =>
                                  _updateItemQuantity(index, item.quantity + 1),
                        ),
                      ],
                    ),
                    Text(
                      '${item.quantity} x ₹${item.unitPrice.toStringAsFixed(0)} = ₹${item.totalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (item.shippingCost > 0)
                      Text(
                        'Shipping: ₹${item.shippingCost.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Ionicons.trash_outline, size: 20),
                onPressed: () => _removeItem(index),
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  backgroundColor: colorScheme.errorContainer.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(icon, size: 22, color: colorScheme.primary),
      onPressed: onPressed,
    );
  }

  Widget _buildEntitySelector(
    BuildContext context, {
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(
            Ionicons.business_outline,
            color: colorScheme.primary,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? 'Select Manufacturer',
              style: TextStyle(
                color:
                    value != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
              ),
            ),
            Icon(
              Ionicons.chevron_down_outline,
              size: 20,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required Function(DateTime) onChanged,
    bool isOptional = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(colorScheme: colorScheme),
              child: child!,
            );
          },
        );
        if (date != null) onChanged(date);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(
            Ionicons.calendar_outline,
            color: colorScheme.primary,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value != null ? DateFormat('dd MMM yyyy').format(value) : '-',
                style: TextStyle(
                  color:
                      value != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Ionicons.chevron_down_outline,
              size: 20,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showEntitySelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _EntitySelectionDialog(
            onSelected: (id, name, entity) {
              setState(() {
                _selectedEntityId = id;
                _selectedEntityName = name;
                _selectedManufacturer = entity as Manufacturer;
              });
            },
          ),
    );
  }
}

class _EntitySelectionDialog extends ConsumerStatefulWidget {
  final Function(String id, String name, dynamic entity) onSelected;

  const _EntitySelectionDialog({required this.onSelected});

  @override
  ConsumerState<_EntitySelectionDialog> createState() =>
      _EntitySelectionDialogState();
}

class _EntitySelectionDialogState
    extends ConsumerState<_EntitySelectionDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final manufacturerState = ref.watch(manufacturerControllerProvider);

    final List<dynamic> filteredItems =
        manufacturerState.manufacturers
            .where(
              (m) => m.businessName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();

    return AlertDialog(
      title: const Text('Select Manufacturer'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search manufacturers...',
                prefixIcon: Icon(Ionicons.search_outline),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),

            // List
            Flexible(
              child:
                  filteredItems.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No manufacturers found'),
                      )
                      : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index] as Manufacturer;
                          final String name = item.businessName;
                          final String id = item.id;

                          return ListTile(
                            title: Text(name),
                            onTap: () {
                              widget.onSelected(id, name, item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
