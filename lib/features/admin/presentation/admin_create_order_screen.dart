import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../admin/application/admin_customer_controller.dart';
import '../../admin/application/admin_order_controller.dart';
import '../../cart/application/cart_controller.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/product_repository.dart';
import '../../catalog/data/measurement.dart';
import '../../orders/data/order_model.dart';
import '../../../core/ui/safe_scaffold.dart';

class AdminCreateOrderScreen extends ConsumerStatefulWidget {
  final String? customerId;
  const AdminCreateOrderScreen({super.key, this.customerId});

  @override
  ConsumerState<AdminCreateOrderScreen> createState() =>
      _AdminCreateOrderScreenState();
}

class _AdminCreateOrderScreenState
    extends ConsumerState<AdminCreateOrderScreen> {
  Customer? _selectedCustomer;
  final List<CartItem> _cartItems = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _shippingController = TextEditingController();
  final TextEditingController _oldDueController = TextEditingController();

  // Totals
  double _subtotal = 0.0;
  double _shipping = 0.0;
  double _tax = 0.0;
  double _total = 0.0;
  double _oldDue = 0.0;

  @override
  void initState() {
    super.initState();
    _shippingController.addListener(_onShippingChanged);
    _oldDueController.addListener(_onOldDueChanged);

    // Pre-select customer if customerId is provided
    if (widget.customerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final customerState = ref.read(adminCustomerControllerProvider);
          final customer = customerState.customers.firstWhere(
            (c) => c.id == widget.customerId,
            orElse:
                () => customerState.filteredCustomers.firstWhere(
                  (c) => c.id == widget.customerId,
                  orElse:
                      () => Customer(
                        id: widget.customerId!,
                        name: 'Unknown',
                        email: '',
                        phone: '',
                        createdAt: DateTime.now(),
                      ),
                ),
          );
          if (customer.name != 'Unknown') {
            setState(() {
              _selectedCustomer = customer;
              _oldDue = 0.0;
              _oldDueController.text = '0.00';
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _shippingController.dispose();
    _oldDueController.dispose();
    super.dispose();
  }

  void _onShippingChanged() {
    final val = double.tryParse(_shippingController.text) ?? 0.0;
    if (_shipping != val) {
      _shipping = val;
      _calculateTotals();
    }
  }

  void _onOldDueChanged() {
    final val = double.tryParse(_oldDueController.text) ?? 0.0;
    if (_oldDue != val) {
      setState(() {
        _oldDue = val;
      });
    }
  }

  void _calculateTotals() {
    double sub = 0.0;
    double t = 0.0;

    for (var item in _cartItems) {
      double price;
      if (item.measurementUnit != null && item.product.hasMeasurementPricing) {
        final measurement = item.product.measurement!;
        final pricing = measurement.getPricingForUnit(item.measurementUnit!);
        price = pricing?.price ?? item.product.price;
      } else if (item.variant != null) {
        price = item.variant!.price;
      } else {
        price = item.product.price;
      }

      double itemTotal = price * item.quantity;

      // Add tax if applicable
      double itemTax = 0.0;
      double taxRate = item.variant?.tax ?? item.product.tax ?? 0.0;
      if (taxRate > 0) {
        itemTax = itemTotal * taxRate / 100;
      }

      sub += itemTotal;
      t += itemTotal + itemTax;
    }

    setState(() {
      _subtotal = sub;
      _tax = t - sub; // Approximate tax calculation
      _total = t + _shipping;
    });
  }

  void _addCartItem(
    Product product, {
    Variant? variant,
    MeasurementUnit? unit,
  }) {
    setState(() {
      // Check if item already exists
      final existingIndex = _cartItems.indexWhere((item) {
        if (unit != null) {
          return item.product.id == product.id && item.measurementUnit == unit;
        }
        if (variant != null) {
          return item.product.id == product.id &&
              item.variant?.sku == variant.sku;
        }
        return item.product.id == product.id;
      });

      if (existingIndex >= 0) {
        // Increment quantity
        final existing = _cartItems[existingIndex];
        _cartItems[existingIndex] = existing.copyWith(
          quantity: existing.quantity + 1,
        );
      } else {
        // Add new item
        _cartItems.add(
          CartItem(product, 1, variant: variant, measurementUnit: unit),
        );
      }
      _calculateTotals();
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final item = _cartItems[index];
      final newQuantity = item.quantity + delta;

      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = item.copyWith(quantity: newQuantity);
      }
      _calculateTotals();
    });
  }

  Future<void> _showProductSelectionDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => _ProductSelectionSheet(
                  scrollController: scrollController,
                  onProductSelected: (product, variant, unit) {
                    _addCartItem(product, variant: variant, unit: unit);
                    Navigator.pop(context);
                  },
                ),
          ),
    );
  }

  Future<void> _createOrder() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add products to the order')),
      );
      return;
    }

    // Create Order Address from Customer Address
    // Improved parsing logic
    final rawAddress = _selectedCustomer!.address ?? '';
    final addressParts = rawAddress.split(',');

    String city = '-';
    String state = '-';
    String pincode = '000000';
    String addressLine = rawAddress;

    // Simple heuristic parsing if address is comma separated
    if (addressParts.length >= 3) {
      // Format assumption: "Street, City, State Pincode" or "Street, City, State-Pincode"

      // Last part often contains State and Pincode
      final lastPart = addressParts.last.trim();

      // Try to find pincode (6 digits)
      final pincodeMatch = RegExp(r'\b\d{6}\b').firstMatch(lastPart);
      if (pincodeMatch != null) {
        pincode = pincodeMatch.group(0)!;
        // State is what remains after removing pincode
        final potentialState =
            lastPart.replaceAll(pincode, '').replaceAll('-', '').trim();
        if (potentialState.isNotEmpty) {
          state = potentialState;
        } else {
          // Maybe state is in the previous part?
          state = addressParts[addressParts.length - 2].trim();
        }
      } else {
        // No pincode found in last part, maybe just state
        state = lastPart;
      }

      // City is likely the second to last part (or third to last if we used second to last for state)
      if (state != lastPart && addressParts.length > 2) {
        city = addressParts[addressParts.length - 2].trim();
        addressLine =
            addressParts.sublist(0, addressParts.length - 2).join(', ').trim();
      } else if (addressParts.length >= 2) {
        city = addressParts[addressParts.length - 2].trim();
        addressLine =
            addressParts.sublist(0, addressParts.length - 2).join(', ').trim();
      }
    } else if (addressParts.length == 2) {
      // "Street, City" or "City, State"
      city = addressParts.last.trim();
      addressLine = addressParts.first.trim();
    }

    final deliveryAddress = OrderAddress(
      name: _selectedCustomer!.name,
      phone: _selectedCustomer!.phone,
      address: addressLine.isNotEmpty ? addressLine : '-',
      city: city,
      state: state,
      pincode: pincode,
    );

    final success = await ref
        .read(adminOrderControllerProvider.notifier)
        .createOrder(
          cartItems: _cartItems,
          deliveryAddress: deliveryAddress,
          subtotal: _subtotal,
          shipping: _shipping,
          tax: _tax,
          total: _total,
          notes: _notesController.text,
          userId: _selectedCustomer!.id,
          status: OrderStatus.confirmed, // Directly accepted/converted to sale
          oldDue: _oldDue,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order created and confirmed successfully'),
        ),
      );
      context.goNamed('admin-dashboard'); // Redirect to admin dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(adminCustomerControllerProvider);
    final orderState = ref.watch(adminOrderControllerProvider);

    return SafeScaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body:
          orderState.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer Selection
                    DropdownButtonFormField<Customer>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Customer/Store',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Ionicons.person_outline),
                      ),
                      initialValue: _selectedCustomer,
                      items:
                          customersAsync.customers.map((c) {
                            return DropdownMenuItem<Customer>(
                              value: c,
                              child: Text(
                                '${c.name} (${c.phone})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomer = value;
                          // Reset old due to 0.00 when customer changes, as per requirement
                          // Admin will manually add old due if needed
                          _oldDue = 0.0;
                          _oldDueController.text = '0.00';
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Products Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Products',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        FilledButton.icon(
                          onPressed: _showProductSelectionDialog,
                          icon: const Icon(Ionicons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Product List
                    if (_cartItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('No products added yet'),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cartItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: NetworkImage(item.product.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(item.product.name),
                            subtitle: Text(
                              item.measurementUnit != null
                                  ? '${item.measurementUnit!.displayName} - ₹${_getPrice(item).toStringAsFixed(2)}'
                                  : item.variant != null
                                  ? '${item.variant!.sku} - ₹${_getPrice(item).toStringAsFixed(2)}'
                                  : '₹${_getPrice(item).toStringAsFixed(2)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Ionicons.remove_circle_outline,
                                  ),
                                  onPressed: () => _updateQuantity(index, -1),
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  icon: const Icon(Ionicons.add_circle_outline),
                                  onPressed: () => _updateQuantity(index, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Order Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Shipping Charges
                    TextField(
                      controller: _shippingController,
                      decoration: const InputDecoration(
                        labelText: 'Shipping / Delivery Charges',
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Old Due Input
                    TextField(
                      controller: _oldDueController,
                      decoration: const InputDecoration(
                        labelText: 'Old Due',
                        prefixText: 'Rs ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Subtotal', value: _subtotal),
                          _SummaryRow(label: 'Shipping', value: _shipping),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Current Total',
                            value: _total,
                            isBold: true,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Old Due',
                            value: _oldDue,
                            color: Colors.red,
                          ),
                          const Divider(),
                          _SummaryRow(
                            label: 'Grand Total',
                            value: _total + _oldDue,
                            isBold: true,
                            fontSize: 18.0,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _createOrder,
                        child: const Text('Create Order'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  double _getPrice(CartItem item) {
    if (item.measurementUnit != null && item.product.hasMeasurementPricing) {
      final measurement = item.product.measurement!;
      final pricing = measurement.getPricingForUnit(item.measurementUnit!);
      return pricing?.price ?? item.product.price;
    } else if (item.variant != null) {
      return item.variant!.price;
    }
    return item.product.price;
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final Color? color;
  final double? fontSize;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              fontSize: fontSize ?? (isBold ? 16.0 : null),
              color: color,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : null,
              fontSize: fontSize ?? (isBold ? 16.0 : null),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSelectionSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Function(Product, Variant?, MeasurementUnit?) onProductSelected;

  const _ProductSelectionSheet({
    required this.scrollController,
    required this.onProductSelected,
  });

  @override
  ConsumerState<_ProductSelectionSheet> createState() =>
      _ProductSelectionSheetState();
}

class _ProductSelectionSheetState
    extends ConsumerState<_ProductSelectionSheet> {
  String _searchQuery = '';
  List<Product> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final repository = ref.read(productRepositoryProvider);
      final products = await repository.fetchAll();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _allProducts;
    return _allProducts
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Ionicons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                    controller: widget.scrollController,
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ListTile(
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(Ionicons.image),
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Text('₹${product.price}'),
                        onTap: () {
                          if (product.hasMeasurementPricing) {
                            _showMeasurementDialog(product);
                          } else {
                            widget.onProductSelected(product, null, null);
                          }
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }

  void _showMeasurementDialog(Product product) {
    if (product.measurement == null) return;

    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('Select Unit for ${product.name}'),
            children:
                product.measurement!.availableUnits.map((unit) {
                  return SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onProductSelected(product, null, unit);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(unit.displayName),
                          Text(
                            '₹${product.measurement!.getPricingForUnit(unit)?.price ?? product.price}',
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
    );
  }
}
