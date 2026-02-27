import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'dart:io';
import '../../catalog/data/product.dart';
import '../../catalog/data/measurement.dart';
import '../application/admin_product_controller.dart';
import '../data/category_service.dart';
import '../domain/category.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../../../media_upload_widget.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _taxController = TextEditingController();
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<String> _selectedCategories = [];
  List<String> _tags = [];
  List<String> _alternativeNames = [];
  final _alternativeNameController = TextEditingController();

  // Image management
  List<MediaUploadResult> _selectedImages = <MediaUploadResult>[];
  final _categoryController = TextEditingController();
  final _tagController = TextEditingController();
  String? _selectedCategoryDropdown; // For dropdown selection

  // Variant management
  List<Variant> _variants = [];
  bool _hasVariants = false;
  String _variantAttributeName = '';
  String _variantAttributeValue = '';
  final _variantSkuController = TextEditingController();
  final _variantPriceController = TextEditingController();
  final _variantCostPriceController = TextEditingController();
  final _variantTaxController = TextEditingController();
  final _variantStockController = TextEditingController();

  // Measurement pricing
  bool _hasMeasurementPricing = false;
  String _measurementType = 'weight';
  MeasurementUnit _measurementUnit = MeasurementUnit.kg;
  double _measurementPrice = 0.0;
  int _measurementStock = 0;

  @override
  void initState() {
    super.initState();
    // Explicitly initialize lists to ensure they're not null on web
    _selectedImages = <MediaUploadResult>[];
    _selectedCategories = <String>[];
    _tags = <String>[];
    _alternativeNames = <String>[];
    _variants = <Variant>[];

    if (widget.product != null) {
      _populateForm(widget.product!);
    }
  }

  void _populateForm(Product product) {
    _nameController.text = product.name;
    _subtitleController.text = product.subtitle ?? '';
    _priceController.text = product.price.toString();
    _costPriceController.text = product.costPrice?.toString() ?? '';
    _taxController.text = product.tax?.toString() ?? '';
    _brandController.text = product.brand ?? '';
    _skuController.text = product.sku ?? '';
    _stockController.text = product.stock.toString();
    _descriptionController.text = product.description ?? '';
    _selectedCategories = List.from(product.categories);

    _tags = List.from(product.tags);
    _alternativeNames = List.from(product.alternativeNames);

    // Convert existing image URLs to MediaUploadResult for editing
    // Note: This is a workaround - in a real scenario, we'd load the images
    // For now, we'll keep the URLs and let users re-upload if needed
    if (product.images.isNotEmpty) {
      // Store URLs for display, but mark as existing
      // In edit mode, users can add more images via MediaUploadWidget
    }

    _variants = List.from(product.variants);
    _hasVariants = product.variants.isNotEmpty;
    _hasMeasurementPricing = product.measurement != null;
    if (product.measurement != null) {
      _measurementType = product.measurement!.category ?? 'weight';
      _measurementUnit = product.measurement!.defaultUnit;
      final defaultPricing = product.measurement!.getPricingForUnit(
        product.measurement!.defaultUnit,
      );
      if (defaultPricing != null) {
        _measurementPrice = defaultPricing.price;
        _measurementStock = defaultPricing.stock;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _taxController.dispose();
    _brandController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagController.dispose();
    _alternativeNameController.dispose();
    _variantSkuController.dispose();
    _variantPriceController.dispose();
    _variantCostPriceController.dispose();
    _variantTaxController.dispose();
    _variantStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(adminProductControllerProvider);
    final screenSize = Responsive.getScreenSize(context);
    final isEditing = widget.product != null;

    return AdminAuthGuard(
      child: AdminScaffold(
        title: isEditing ? 'Edit Product' : 'Add Product',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: () => _saveProduct(),
            child:
                productState.loading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(isEditing ? 'Update' : 'Save'),
          ),
        ],
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(screenSize == ScreenSize.mobile ? 16 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    screenSize == ScreenSize.mobile ? double.infinity : 600,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information
                  _buildSectionHeader(context, 'Basic Information'),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      hintText: 'Enter product name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Product name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _subtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Subtitle',
                      hintText: 'Enter product subtitle',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter product description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Alternative Names
                  _buildSectionHeader(context, 'Alternative Names'),
                  const SizedBox(height: 16),

                  Text(
                    'Add alternative names to help customers find this product through search',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _alternativeNames.map((name) {
                          return Chip(
                            label: Text(name),
                            onDeleted: () {
                              setState(() {
                                _alternativeNames.remove(name);
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _alternativeNameController,
                          decoration: const InputDecoration(
                            labelText: 'Add Alternative Name',
                            hintText: 'Enter alternative name for search',
                            prefixIcon: Icon(Ionicons.search_outline),
                          ),
                          onFieldSubmitted: (value) {
                            if (value.isNotEmpty &&
                                !_alternativeNames.contains(value)) {
                              setState(() {
                                _alternativeNames.add(value);
                                _alternativeNameController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (_alternativeNameController.text.isNotEmpty) {
                            final alternativeName =
                                _alternativeNameController.text.trim();
                            if (alternativeName.isNotEmpty &&
                                !_alternativeNames.contains(alternativeName)) {
                              setState(() {
                                _alternativeNames.add(alternativeName);
                                _alternativeNameController.clear();
                              });
                            }
                          }
                        },
                        icon: const Icon(Ionicons.add_outline),
                        tooltip: 'Add Alternative Name',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Image Management
                  _buildSectionHeader(context, 'Product Images'),
                  const SizedBox(height: 16),

                  // MediaUploadWidget for file upload
                  MediaUploadWidget(
                    label: 'Upload Product Images',
                    hint: 'Select images from camera, gallery, or files',
                    allowImages: true,
                    allowPdfs: false,
                    maxImages: 25,
                    onMultipleMediaSelected: (List<MediaUploadResult> results) {
                      if (mounted) {
                        setState(() {
                          _selectedImages.addAll(results);
                        });
                      }
                    },
                    onMediaSelected: (MediaUploadResult result) {
                      if (mounted) {
                        setState(() {
                          if (!_selectedImages.any(
                            (img) => img.path == result.path,
                          )) {
                            _selectedImages.add(result);
                          }
                        });
                      }
                    },
                  ),

                  // Image Preview Grid - safely access _selectedImages for web
                  Builder(
                    builder: (context) {
                      try {
                        // Safely access _selectedImages - use local variable for web compatibility
                        final images = _selectedImages;
                        if (images.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Selected Images (${images.length})',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                final image = images[index];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildImagePreview(image.path),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Primary',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      } catch (e) {
                        // On web, if _selectedImages is undefined, return empty widget
                        // This can happen during hot reload on web
                        if (kDebugMode) {
                          print('Error accessing _selectedImages: $e');
                        }
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Pricing & Inventory
                  _buildSectionHeader(context, 'Pricing & Inventory'),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price *',
                            hintText: '0.00',
                            prefixText: '₹ ',
                            helperText: 'Price for stores',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Price is required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter valid price';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Purchasing Price',
                            hintText: '0.00',
                            prefixText: '₹ ',
                            helperText: 'For manufacturer billing',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (double.tryParse(value) == null) {
                                return 'Enter valid price';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tax field hidden from UI
                  // TextFormField(
                  //   controller: _taxController,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Tax (%)',
                  //     hintText: '0.00',
                  //     prefixText: '% ',
                  //     helperText: 'Tax percentage applicable to selling price only',
                  //   ),
                  //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  //   validator: (value) {
                  //     if (value != null && value.isNotEmpty) {
                  //       final taxValue = double.tryParse(value);
                  //       if (taxValue == null) {
                  //         return 'Enter valid tax percentage';
                  //       }
                  //       if (taxValue < 0 || taxValue > 100) {
                  //         return 'Tax must be between 0 and 100';
                  //       }
                  //     }
                  //     return null;
                  //   },
                  // ),
                  // const SizedBox(height: 16),

                  // Stock and SKU fields hidden from UI
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: TextFormField(
                  //         controller: _stockController,
                  //         decoration: const InputDecoration(
                  //           labelText: 'Stock Quantity',
                  //           hintText: '0',
                  //         ),
                  //         keyboardType: TextInputType.number,
                  //         validator: (value) {
                  //           if (value != null && value.isNotEmpty) {
                  //             if (int.tryParse(value) == null) {
                  //               return 'Enter valid quantity';
                  //             }
                  //           }
                  //           return null;
                  //         },
                  //       ),
                  //     ),
                  //     const SizedBox(width: 16),
                  //     Expanded(
                  //       child: TextFormField(
                  //         controller: _skuController,
                  //         decoration: const InputDecoration(
                  //           labelText: 'SKU',
                  //           hintText: 'Enter SKU',
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 16),

                  // Measurement-based Pricing
                  SwitchListTile(
                    title: const Text('Enable Measurement-based Pricing'),
                    subtitle: const Text(
                      'Allow customers to buy by weight, length, etc.',
                    ),
                    value: _hasMeasurementPricing,
                    onChanged: (value) {
                      setState(() {
                        _hasMeasurementPricing = value;
                      });
                    },
                  ),

                  if (_hasMeasurementPricing) ...[
                    const SizedBox(height: 16),
                    // Use flexible layout to prevent overflow on small screens
                    Column(
                      children: [
                        // Measurement Type and Unit - responsive layout
                        screenSize == ScreenSize.mobile
                            ? Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _measurementType,
                                  decoration: const InputDecoration(
                                    labelText: 'Measurement Type',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'weight',
                                      child: Text('Weight'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'length',
                                      child: Text('Length'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'volume',
                                      child: Text('Volume'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'area',
                                      child: Text('Area'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _measurementType = value ?? 'weight';
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<MeasurementUnit>(
                                  initialValue: _measurementUnit,
                                  decoration: const InputDecoration(
                                    labelText: 'Default Unit',
                                  ),
                                  items:
                                      MeasurementUnit.values.map((unit) {
                                        return DropdownMenuItem(
                                          value: unit,
                                          child: Text(
                                            '${unit.shortName} (${unit.displayName})',
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _measurementUnit =
                                          value ?? MeasurementUnit.kg;
                                    });
                                  },
                                ),
                              ],
                            )
                            : Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _measurementType,
                                    decoration: const InputDecoration(
                                      labelText: 'Measurement Type',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'weight',
                                        child: Text('Weight'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'length',
                                        child: Text('Length'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'volume',
                                        child: Text('Volume'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'area',
                                        child: Text('Area'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _measurementType = value ?? 'weight';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<
                                    MeasurementUnit
                                  >(
                                    initialValue: _measurementUnit,
                                    decoration: const InputDecoration(
                                      labelText: 'Default Unit',
                                    ),
                                    items:
                                        MeasurementUnit.values.map((unit) {
                                          return DropdownMenuItem(
                                            value: unit,
                                            child: Text(
                                              '${unit.shortName} (${unit.displayName})',
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _measurementUnit =
                                            value ?? MeasurementUnit.kg;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                        const SizedBox(height: 16),
                        // Price and Stock - responsive layout
                        screenSize == ScreenSize.mobile
                            ? Column(
                              children: [
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Price per Unit',
                                    prefixText: '₹ ',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged:
                                      (value) =>
                                          _measurementPrice =
                                              double.tryParse(value) ?? 0.0,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Stock per Unit',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged:
                                      (value) =>
                                          _measurementStock =
                                              int.tryParse(value) ?? 0,
                                ),
                              ],
                            )
                            : Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Price per Unit',
                                      prefixText: '₹ ',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged:
                                        (value) =>
                                            _measurementPrice =
                                                double.tryParse(value) ?? 0.0,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Stock per Unit',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged:
                                        (value) =>
                                            _measurementStock =
                                                int.tryParse(value) ?? 0,
                                  ),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Product Details
                  _buildSectionHeader(context, 'Product Details'),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      hintText: 'Enter brand name',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Categories
                  _buildSectionHeader(context, 'Categories'),
                  const SizedBox(height: 16),

                  // Display selected categories as chips
                  if (_selectedCategories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _selectedCategories.map((category) {
                            return Chip(
                              label: Text(category),
                              onDeleted: () {
                                setState(() {
                                  _selectedCategories.remove(category);
                                });
                              },
                            );
                          }).toList(),
                    ),
                  if (_selectedCategories.isNotEmpty) const SizedBox(height: 8),

                  // Category autocomplete input
                  Consumer(
                    builder: (context, ref, child) {
                      final categoriesAsync = ref.watch(categoriesProvider);

                      return categoriesAsync.when(
                        data: (categories) {
                          // Explicitly cast to ensure correct Category type
                          final List<Category> categoryList = categories;
                          final List<String> availableCategories =
                              categoryList
                                  .where((Category cat) => cat.isActive)
                                  .map((Category cat) => cat.name)
                                  .where(
                                    (String name) =>
                                        !_selectedCategories.contains(name),
                                  )
                                  .toList()
                                ..sort();

                          return Autocomplete<String>(
                            optionsBuilder: (
                              TextEditingValue textEditingValue,
                            ) {
                              if (textEditingValue.text.isEmpty) {
                                return availableCategories;
                              }
                              return availableCategories.where((
                                String category,
                              ) {
                                return category.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                );
                              });
                            },
                            onSelected: (String category) {
                              setState(() {
                                if (!_selectedCategories.contains(category)) {
                                  _selectedCategories.add(category);
                                }
                              });
                            },
                            fieldViewBuilder: (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  hintText:
                                      'Type to search or add new category',
                                  suffixIcon: Icon(Icons.search),
                                ),
                                onSubmitted: (value) {
                                  final category = value.trim();
                                  if (category.isNotEmpty &&
                                      !_selectedCategories.contains(category)) {
                                    setState(() {
                                      _selectedCategories.add(category);
                                    });
                                    textEditingController.clear();
                                  }
                                },
                              );
                            },
                          );
                        },
                        loading:
                            () => const TextField(
                              decoration: InputDecoration(
                                labelText: 'Category',
                                hintText: 'Loading categories...',
                              ),
                              enabled: false,
                            ),
                        error:
                            (error, stack) => TextField(
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                hintText: 'Error loading categories',
                              ),
                              enabled: false,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tags section hidden from UI
                  // _buildSectionHeader(context, 'Tags'),
                  // const SizedBox(height: 16),
                  //
                  // Wrap(
                  //   spacing: 8,
                  //   runSpacing: 8,
                  //   children:
                  //       _tags.map((tag) {
                  //         return Chip(
                  //           label: Text(tag),
                  //           onDeleted: () {
                  //             setState(() {
                  //               _tags.remove(tag);
                  //             });
                  //           },
                  //         );
                  //       }).toList(),
                  // ),
                  // const SizedBox(height: 8),
                  //
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: TextFormField(
                  //         controller: _tagController,
                  //         decoration: const InputDecoration(
                  //           labelText: 'Add Tag',
                  //           hintText: 'Enter tag',
                  //         ),
                  //         onFieldSubmitted: (value) {
                  //           if (value.isNotEmpty && !_tags.contains(value)) {
                  //             setState(() {
                  //               _tags.add(value);
                  //               _tagController.clear();
                  //             });
                  //           }
                  //         },
                  //       ),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     IconButton(
                  //       onPressed: () {
                  //         final tag = _tagController.text.trim();
                  //         if (tag.isNotEmpty && !_tags.contains(tag)) {
                  //           setState(() {
                  //             _tags.add(tag);
                  //             _tagController.clear();
                  //           });
                  //         }
                  //       },
                  //       icon: const Icon(Ionicons.add_outline),
                  //       tooltip: 'Add Tag',
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 24),

                  // Product Variants
                  _buildSectionHeader(context, 'Product Variants'),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Enable Product Variants'),
                    subtitle: const Text('Add different sizes, colors, etc.'),
                    value: _hasVariants,
                    onChanged: (value) {
                      setState(() {
                        _hasVariants = value;
                        if (!value) {
                          _variants.clear();
                        }
                      });
                    },
                  ),

                  if (_hasVariants) ...[
                    const SizedBox(height: 16),

                    // Add Variant Form
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Variant',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Attribute Name',
                                      hintText: 'e.g., Size, Color',
                                    ),
                                    onChanged:
                                        (value) =>
                                            _variantAttributeName = value,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Attribute Value',
                                      hintText: 'e.g., Large, Red',
                                    ),
                                    onChanged:
                                        (value) =>
                                            _variantAttributeValue = value,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _variantSkuController,
                                    decoration: const InputDecoration(
                                      labelText: 'Variant SKU',
                                      hintText: 'Enter SKU',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _variantPriceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Selling Price',
                                      prefixText: '₹ ',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _variantCostPriceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Purchasing Price',
                                      prefixText: '₹ ',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always,
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _variantStockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock',
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _addVariant,
                                    icon: const Icon(Ionicons.add_outline),
                                    label: const Text('Add Variant'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Variants List
                    if (_variants.isNotEmpty) ...[
                      Text(
                        'Current Variants',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ..._variants.map((variant) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(variant.sku),
                            subtitle: Text(
                              variant.attributes.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(' • '),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${variant.finalPrice.toStringAsFixed(2)}',
                                ),
                                const SizedBox(width: 8),
                                Text('Stock: ${variant.stock}'),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _removeVariant(variant),
                                  icon: const Icon(Ionicons.trash_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ResponsiveOutlinedButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            }
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ResponsiveFilledButton(
                          onPressed: productState.loading ? null : _saveProduct,
                          child:
                              productState.loading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    isEditing
                                        ? 'Update Product'
                                        : 'Create Product',
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildImagePreview(String imagePath) {
    // Handle web (blob URLs) and mobile (File paths)
    if (kIsWeb) {
      // On web, use Image.network for blob URLs
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.red),
            ),
          );
        },
      );
    } else {
      // On mobile, use Image.file
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.red),
            ),
          );
        },
      );
    }
  }

  void _addVariant() {
    if (_variantAttributeName.isNotEmpty &&
        _variantAttributeValue.isNotEmpty &&
        _variantSkuController.text.isNotEmpty &&
        _variantPriceController.text.isNotEmpty &&
        _variantStockController.text.isNotEmpty) {
      final costPrice =
          _variantCostPriceController.text.trim().isNotEmpty
              ? double.tryParse(_variantCostPriceController.text)
              : null;
      final tax =
          _variantTaxController.text.trim().isNotEmpty
              ? double.tryParse(_variantTaxController.text)
              : null;

      final variant = Variant(
        sku: _variantSkuController.text.trim(),
        attributes: {_variantAttributeName: _variantAttributeValue},
        price: double.parse(_variantPriceController.text),
        costPrice: costPrice,
        tax: tax,
        stock: int.parse(_variantStockController.text),
      );

      setState(() {
        _variants.add(variant);
        _variantSkuController.clear();
        _variantPriceController.clear();
        _variantCostPriceController.clear();
        _variantTaxController.clear();
        _variantStockController.clear();
        _variantAttributeName = '';
        _variantAttributeValue = '';
      });
    }
  }

  void _removeVariant(Variant variant) {
    setState(() {
      _variants.remove(variant);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Create measurement object if measurement pricing is enabled
    ProductMeasurement? measurement;
    if (_hasMeasurementPricing) {
      final productId =
          widget.product?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();
      measurement = ProductMeasurement(
        productId: productId,
        defaultUnit: _measurementUnit,
        category: _measurementType,
        pricingOptions: [
          MeasurementPricing(
            unit: _measurementUnit,
            price: _measurementPrice,
            stock: _measurementStock,
          ),
        ],
      );
    }

    // For now, we'll pass the MediaUploadResult objects to the controller
    // The controller will handle uploading to Supabase and getting URLs.
    // Safely access _selectedImages for web compatibility.
    List<MediaUploadResult> selectedImagesForProduct;
    try {
      selectedImagesForProduct = _selectedImages;
    } catch (e) {
      selectedImagesForProduct = <MediaUploadResult>[];
    }

    // When editing a product, reuse existing image URLs from the database
    // if the admin does not select any new images. This prevents forcing
    // a re-upload on every update. Consider both the primary imageUrl and
    // the images list from the existing product.
    final existingImageUrls = <String>[];
    final existingProduct = widget.product;
    if (existingProduct != null) {
      if (existingProduct.imageUrl.isNotEmpty) {
        existingImageUrls.add(existingProduct.imageUrl);
      }
      if (existingProduct.images.isNotEmpty) {
        existingImageUrls.addAll(
          existingProduct.images.where((path) => path.isNotEmpty),
        );
      }
    }

    List<String> imagePaths;
    if (selectedImagesForProduct.isNotEmpty) {
      imagePaths = selectedImagesForProduct.map((img) => img.path).toList();
    } else if (existingImageUrls.isNotEmpty) {
      imagePaths = List<String>.from(existingImageUrls);
    } else {
      imagePaths = <String>[];
    }

    final primaryImagePath = imagePaths.isNotEmpty ? imagePaths.first : '';

    final product = Product(
      id:
          widget.product?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      subtitle:
          _subtitleController.text.trim().isEmpty
              ? null
              : _subtitleController.text.trim(),
      imageUrl:
          imagePaths.isNotEmpty
              ? imagePaths.first
              : 'https://picsum.photos/seed/sm-product/600/600',
      images:
          imagePaths.isNotEmpty
              ? imagePaths
              : ['https://picsum.photos/seed/sm-product/600/600'],
      price: double.parse(_priceController.text),
      costPrice:
          _costPriceController.text.trim().isNotEmpty
              ? double.tryParse(_costPriceController.text)
              : null,
      tax:
          _taxController.text.trim().isNotEmpty
              ? double.tryParse(_taxController.text)
              : null,
      brand:
          _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
      sku:
          _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
      stock:
          _stockController.text.trim().isNotEmpty
              ? int.tryParse(_stockController.text) ?? 0
              : 0,
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      tags: _tags,
      categories: _selectedCategories,
      variants: _variants,
      measurement: measurement,
      alternativeNames: _alternativeNames,
    );

    // Pass the selected images to the controller for upload.
    // Validate that at least one image exists (newly selected or already
    // stored in the database for this product).
    // Safely access _selectedImages for web compatibility.
    List<MediaUploadResult> selectedImagesList;
    try {
      selectedImagesList = _selectedImages;
    } catch (e) {
      selectedImagesList = <MediaUploadResult>[];
    }

    // Treat images as existing if either the primary imageUrl or the images
    // list for this product is non-empty.
    bool hasExistingImages = false;
    final existingProductForValidation = widget.product;
    if (existingProductForValidation != null) {
      if (existingProductForValidation.imageUrl.isNotEmpty) {
        hasExistingImages = true;
      } else if (existingProductForValidation.images.isNotEmpty) {
        hasExistingImages = existingProductForValidation.images.any(
          (path) => path.isNotEmpty,
        );
      }
    }

    // When creating a new product, require at least one image to be provided.
    // When editing an existing product, allow updates without selecting new
    // images as long as the product already has images in the database.
    if (selectedImagesList.isEmpty && !hasExistingImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload at least one product image'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Save product with images to Supabase
    final success =
        widget.product != null
            ? await ref
                .read(adminProductControllerProvider.notifier)
                .updateProduct(product, selectedImages: selectedImagesList)
            : await ref
                .read(adminProductControllerProvider.notifier)
                .addProduct(product, selectedImages: selectedImagesList);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product != null
                ? 'Product updated successfully'
                : 'Product created successfully',
          ),
        ),
      );
      if (context.canPop()) {
        context.pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product != null
                ? 'Failed to update product'
                : 'Failed to create product',
          ),
        ),
      );
    }
  }
}
