import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/bill_model.dart';
import '../data/bill_repository_supabase.dart';
import '../data/bill_pdf_service.dart';
import '../data/store_company_info.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../orders/data/order_model.dart' as order_model;
import '../../catalog/data/product.dart';
import '../../../media_upload_widget.dart';

/// State for bill management
class BillState {
  final List<Bill> bills;
  final List<BillTemplate> templates;
  final bool isLoading;
  final String? error;
  final BillType? selectedBillType;

  const BillState({
    this.bills = const [],
    this.templates = const [],
    this.isLoading = false,
    this.error,
    this.selectedBillType,
  });

  BillState copyWith({
    List<Bill>? bills,
    List<BillTemplate>? templates,
    bool? isLoading,
    String? error,
    BillType? selectedBillType,
  }) {
    return BillState(
      bills: bills ?? this.bills,
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedBillType: selectedBillType ?? this.selectedBillType,
    );
  }
}

/// Controller for managing bills
class BillController extends StateNotifier<BillState> {
  final BillRepositorySupabase _billRepository;
  final BillPdfService _pdfService;

  BillController(this._billRepository, this._pdfService)
    : super(const BillState()) {
    loadBills();
    loadTemplates();
  }

  /// Load all bills
  Future<void> loadBills({BillType? billType}) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final bills = await _billRepository.getBills(billType: billType);
      if (mounted) {
        state = state.copyWith(bills: bills, isLoading: false);
      }
    } catch (e) {
      // The repository already provides detailed error messages
      // Extract the error message from the exception
      String errorMessage = 'Failed to load bills';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = 'Failed to load bills: $e';
      }

      if (mounted) {
        state = state.copyWith(error: errorMessage, isLoading: false);
      }
    }
  }

  /// Load bill templates
  Future<void> loadTemplates({BillType? templateType}) async {
    try {
      final templates = await _billRepository.getBillTemplates(
        templateType: templateType,
      );
      if (mounted) {
        state = state.copyWith(templates: templates);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: 'Failed to load templates: $e');
      }
    }
  }

  /// Delete a bill
  Future<void> deleteBill(String billId) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      await _billRepository.deleteBill(billId);
      // Refresh list
      await loadBills(billType: state.selectedBillType);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          error: 'Failed to delete bill: $e',
          isLoading: false,
        );
      }
    }
  }

  /// Update bill data
  Future<void> updateBill({
    required String billId,
    required BillData billData,
  }) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      // Update bill data
      final updatedBill = await _billRepository.updateBillData(
        billId,
        billData,
      );

      // Get active template
      final template = await _billRepository.getActiveBillTemplate(
        updatedBill.billType,
      );

      // Regenerate PDF
      final pdfBytes = await _pdfService.generateBillPdf(
        bill: updatedBill,
        template: template,
      );

      // Upload PDF in background
      _uploadPdfInBackground(updatedBill, pdfBytes);

      // Refresh list
      await loadBills(billType: state.selectedBillType);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          error: 'Failed to update bill: $e',
          isLoading: false,
        );
      }
    }
  }

  /// Generate bill from order
  Future<Bill?> generateBillFromOrder({
    required order_model.Order order,
    required BillType billType,
    double? shipping,
    double? oldDue,
    double? receivedAmount,
  }) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      // Get active template for this bill type
      final template = await _billRepository.getActiveBillTemplate(billType);

      // Fetch order items with cost prices (needed for category info and manufacturer bills)
      List<Map<String, dynamic>> orderItemsWithCost = [];
      if (billType == BillType.manufacturer) {
        orderItemsWithCost = await _billRepository.getOrderItemsWithCostPrices(
          order.id,
        );
      } else {
        // For store bills, fetch to get category information
        orderItemsWithCost = await _billRepository.getOrderItemsWithCostPrices(
          order.id,
        );
      }

      // Build lookup map from orderItemsWithCost keyed by product_id
      // Since multiple items can have the same product_id, we use a list
      final Map<String, List<Map<String, dynamic>>> itemsLookup = {};
      for (final itemData in orderItemsWithCost) {
        final productId = itemData['product_id'] as String?;
        if (productId != null) {
          itemsLookup.putIfAbsent(productId, () => []).add(itemData);
        }
      }

      // Validate that we have data for all order items (warn if not)
      final unmatchedItems = <String>[];
      for (final orderItem in order.items) {
        if (!itemsLookup.containsKey(orderItem.id)) {
          unmatchedItems.add(orderItem.id);
        }
      }
      if (unmatchedItems.isNotEmpty && kDebugMode) {
        print(
          'Warning: ${unmatchedItems.length} order items have no matching data in orderItemsWithCost: ${unmatchedItems.join(", ")}',
        );
      }

      // Track which items from the lookup we've used to handle duplicates
      final Map<String, int> itemsUsedCount = {};

      // Create bill items from order items
      final billItems = <BillItem>[];
      for (final orderItem in order.items) {
        double unitPrice;
        String? category;

        // Find matching item data from orderItemsWithCost using product_id
        final matchingItems = itemsLookup[orderItem.id];
        final itemIndex = itemsUsedCount[orderItem.id] ?? 0;
        Map<String, dynamic>? itemData;

        if (matchingItems != null && itemIndex < matchingItems.length) {
          itemData = matchingItems[itemIndex];
          itemsUsedCount[orderItem.id] = itemIndex + 1;
        }

        if (billType == BillType.user) {
          // Store bill: use selling price from order
          unitPrice = orderItem.price;
        } else {
          // Manufacturer bill: use cost price from product
          if (itemData != null) {
            // Try to get cost price from variant first, then product
            final variant = itemData['product_variants'] as List?;
            final product = itemData['products'] as Map<String, dynamic>?;

            if (variant != null && variant.isNotEmpty) {
              final variantData = variant.first as Map<String, dynamic>;
              unitPrice =
                  (variantData['cost_price'] as num?)?.toDouble() ??
                  (variantData['price'] as num?)?.toDouble() ??
                  orderItem.price;
            } else if (product != null) {
              unitPrice =
                  (product['cost_price'] as num?)?.toDouble() ??
                  (product['price'] as num?)?.toDouble() ??
                  orderItem.price;
            } else {
              // Fallback: use 90% of selling price
              unitPrice = orderItem.price * 0.9;
            }
          } else {
            // Fallback: use 90% of selling price
            if (kDebugMode) {
              print(
                'Warning: No matching item data found for product ${orderItem.id}, using fallback price',
              );
            }
            unitPrice = orderItem.price * 0.9;
          }
        }

        // Extract category from product data with safe type checking
        if (itemData != null) {
          try {
            final product = itemData['products'] as Map<String, dynamic>?;
            if (product != null && product['categories'] != null) {
              final categoriesValue = product['categories'];

              // Handle different possible types for categories
              if (categoriesValue is List) {
                if (categoriesValue.isNotEmpty) {
                  final firstCategory = categoriesValue.first;
                  if (firstCategory is String) {
                    category = firstCategory;
                  } else if (firstCategory is Map) {
                    // If it's a map, try to get a name or id field
                    category =
                        (firstCategory['name'] ??
                                firstCategory['id'] ??
                                firstCategory.toString())
                            as String?;
                  } else {
                    category = firstCategory.toString();
                  }
                }
              } else if (categoriesValue is String) {
                // If it's a string, use it directly
                category = categoriesValue;
              } else if (categoriesValue is Map) {
                // If it's a single map, extract name or id
                category =
                    (categoriesValue['name'] ??
                            categoriesValue['id'] ??
                            categoriesValue.toString())
                        as String?;
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Warning: Error extracting category from product data: $e');
            }
            // Continue without category if extraction fails
            category = null;
          }
        }

        billItems.add(
          BillItem(
            productId: orderItem.id,
            productName: orderItem.name,
            imageUrl: orderItem.image,
            quantity: orderItem.quantity,
            unitPrice: unitPrice,
            totalPrice: unitPrice * orderItem.quantity,
            category: category,
          ),
        );
      }

      // Batch fetch missing categories
      final itemsWithMissingCategory =
          billItems.where((item) => item.category == null).toList();
      if (itemsWithMissingCategory.isNotEmpty) {
        if (kDebugMode) {
          print(
            'Fetching categories for ${itemsWithMissingCategory.length} items...',
          );
        }
        final productIds =
            itemsWithMissingCategory
                .map((item) => item.productId)
                .toSet()
                .toList();
        final categoryMap = await _billRepository.getProductsCategories(
          productIds,
        );

        // Update billItems with fetched categories
        for (int i = 0; i < billItems.length; i++) {
          final item = billItems[i];
          if (item.category == null &&
              categoryMap.containsKey(item.productId)) {
            billItems[i] = BillItem(
              productId: item.productId,
              productName: item.productName,
              sku: item.sku,
              imageUrl: item.imageUrl,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              totalPrice: item.totalPrice,
              variantAttributes: item.variantAttributes,
              measurementUnit: item.measurementUnit,
              category: categoryMap[item.productId],
            );
          }
        }
      }

      // Calculate totals
      final subtotal = billItems.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      final tax = order.tax;
      final shippingAmount = shipping ?? order.shipping;
      final oldDueAmount = oldDue ?? 0.0;
      final receivedAmountValue = receivedAmount ?? 0.0;
      // Total includes subtotal + shipping + tax (complete bill amount)
      final total = subtotal + shippingAmount + tax;

      // Fetch user profile for complete customer info
      Map<String, dynamic> customerInfo;
      if (order.userId != null && order.userId!.isNotEmpty) {
        final userProfile = await _billRepository.getUserProfileById(
          order.userId!,
        );
        if (userProfile != null) {
          customerInfo = {
            'name': userProfile['name'] ?? order.deliveryAddress.name,
            'email': userProfile['email'],
            'phone': userProfile['mobile'] ?? order.deliveryAddress.phone,
            'address': order.deliveryAddress.fullAddress,
            'city': order.deliveryAddress.city,
            'state': order.deliveryAddress.state,
            'pincode': order.deliveryAddress.pincode,
          };
        } else {
          // Fallback to order address
          customerInfo = {
            'name': order.deliveryAddress.name,
            'phone': order.deliveryAddress.phone,
            'address': order.deliveryAddress.fullAddress,
            'city': order.deliveryAddress.city,
            'state': order.deliveryAddress.state,
            'pincode': order.deliveryAddress.pincode,
          };
        }
      } else {
        // Fallback to order address
        customerInfo = {
          'name': order.deliveryAddress.name,
          'phone': order.deliveryAddress.phone,
          'address': order.deliveryAddress.fullAddress,
          'city': order.deliveryAddress.city,
          'state': order.deliveryAddress.state,
          'pincode': order.deliveryAddress.pincode,
        };
      }

      // Create order info
      final orderInfo = {
        'order_number': order.orderNumber,
        'status': order.status.toString(),
        'order_date': order.orderDate.toIso8601String(),
        'total_items': order.totalItems,
      };

      // Get company info
      final companyInfo = StoreCompanyInfo.toMap();

      // Create bill data
      final billData = BillData(
        items: billItems,
        subtotal: subtotal,
        tax: tax,
        shipping: shippingAmount,
        total: total,
        oldDue: oldDueAmount,
        receivedAmount: receivedAmountValue,
        customerInfo: customerInfo,
        orderInfo: orderInfo,
        companyInfo: companyInfo,
      );

      // Create bill
      final bill = await _billRepository.createBill(
        billType: billType,
        userId: order.userId ?? '',
        billData: billData,
        orderId: order.id,
        orderNumber: order.orderNumber,
      );

      // Generate PDF
      final pdfBytes = await _pdfService.generateBillPdf(
        bill: bill,
        template: template,
      );

      // Upload PDF in background
      _uploadPdfInBackground(bill, pdfBytes);

      // Reload bills immediately
    await loadBills();

    if (mounted) {
      state = state.copyWith(isLoading: false);
    }
    return bill;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to generate bill: $e',
        isLoading: false,
      );
      return null;
    }
  }

  /// Generate manufacturer bill from order
  Future<Bill?> generateManufacturerBill({
    required String manufacturerId,
    required order_model.Order order,
    double? shipping,
    double? oldDue,
    double? receivedAmount,
  }) async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      if (kDebugMode) {
        print(
          'Generating manufacturer bill for manufacturer ID: $manufacturerId, order: ${order.orderNumber}',
        );
      }

      // Get manufacturer details with validation
      final manufacturer = await _billRepository.getManufacturerById(
        manufacturerId,
      );
      if (manufacturer == null) {
        throw Exception('Manufacturer not found with ID: $manufacturerId');
      }

      // Validate required manufacturer fields
      final requiredFields = [
        'id',
        'name',
        'gst_number',
        'business_name',
        'business_address',
        'city',
        'state',
        'pincode',
      ];
      final missingFields = <String>[];
      for (final field in requiredFields) {
        if (manufacturer[field] == null ||
            manufacturer[field].toString().trim().isEmpty) {
          missingFields.add(field);
        }
      }

      if (missingFields.isNotEmpty) {
        if (kDebugMode) {
          print(
            'Warning: Manufacturer missing required fields: ${missingFields.join(", ")}',
          );
        }
        // Continue but log the issue
      }

      if (kDebugMode) {
        print('Manufacturer data retrieved: ${manufacturer['business_name']}');
        print('Manufacturer fields: ${manufacturer.keys.toList()}');
      }

      // Get active template for manufacturer bills
      final template = await _billRepository.getActiveBillTemplate(
        BillType.manufacturer,
      );

      // Fetch order items with cost prices
      final orderItemsWithCost = await _billRepository
          .getOrderItemsWithCostPrices(order.id);

      // Build lookup map from orderItemsWithCost keyed by product_id
      // Since multiple items can have the same product_id, we use a list
      final Map<String, List<Map<String, dynamic>>> itemsLookup = {};
      for (final itemData in orderItemsWithCost) {
        final productId = itemData['product_id'] as String?;
        if (productId != null) {
          itemsLookup.putIfAbsent(productId, () => []).add(itemData);
        }
      }

      // Validate that we have data for all order items (warn if not)
      final unmatchedItems = <String>[];
      for (final orderItem in order.items) {
        if (!itemsLookup.containsKey(orderItem.id)) {
          unmatchedItems.add(orderItem.id);
        }
      }
      if (unmatchedItems.isNotEmpty && kDebugMode) {
        print(
          'Warning: ${unmatchedItems.length} order items have no matching data in orderItemsWithCost: ${unmatchedItems.join(", ")}',
        );
      }

      // Track which items from the lookup we've used to handle duplicates
      final Map<String, int> itemsUsedCount = {};

      // Create bill items with cost prices
      final billItems = <BillItem>[];
      for (final orderItem in order.items) {
        double unitPrice;
        String? category;

        // Find matching item data from orderItemsWithCost using product_id
        final matchingItems = itemsLookup[orderItem.id];
        final itemIndex = itemsUsedCount[orderItem.id] ?? 0;
        Map<String, dynamic>? itemData;

        if (matchingItems != null && itemIndex < matchingItems.length) {
          itemData = matchingItems[itemIndex];
          itemsUsedCount[orderItem.id] = itemIndex + 1;
        }

        if (itemData != null) {
          // Try to get cost price from variant first, then product
          final variant = itemData['product_variants'] as List?;
          final product = itemData['products'] as Map<String, dynamic>?;

          if (variant != null && variant.isNotEmpty) {
            final variantData = variant.first as Map<String, dynamic>;
            unitPrice =
                (variantData['cost_price'] as num?)?.toDouble() ??
                (variantData['price'] as num?)?.toDouble() ??
                orderItem.price * 0.9;
          } else if (product != null) {
            unitPrice =
                (product['cost_price'] as num?)?.toDouble() ??
                (product['price'] as num?)?.toDouble() ??
                orderItem.price * 0.9;
          } else {
            // Fallback: use 90% of selling price
            unitPrice = orderItem.price * 0.9;
          }

          // Extract category from product data with safe type checking
          try {
            if (product != null && product['categories'] != null) {
              final categoriesValue = product['categories'];

              // Handle different possible types for categories
              if (categoriesValue is List) {
                if (categoriesValue.isNotEmpty) {
                  final firstCategory = categoriesValue.first;
                  if (firstCategory is String) {
                    category = firstCategory;
                  } else if (firstCategory is Map) {
                    // If it's a map, try to get a name or id field
                    category =
                        (firstCategory['name'] ??
                                firstCategory['id'] ??
                                firstCategory.toString())
                            as String?;
                  } else {
                    category = firstCategory.toString();
                  }
                }
              } else if (categoriesValue is String) {
                // If it's a string, use it directly
                category = categoriesValue;
              } else if (categoriesValue is Map) {
                // If it's a single map, extract name or id
                category =
                    (categoriesValue['name'] ??
                            categoriesValue['id'] ??
                            categoriesValue.toString())
                        as String?;
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Warning: Error extracting category from product data: $e');
            }
            // Continue without category if extraction fails
            category = null;
          }
        } else {
          // Fallback: use 90% of selling price
          if (kDebugMode) {
            print(
              'Warning: No matching item data found for product ${orderItem.id}, using fallback price',
            );
          }
          unitPrice = orderItem.price * 0.9;
        }

        billItems.add(
          BillItem(
            productId: orderItem.id,
            productName: orderItem.name,
            imageUrl: orderItem.image,
            quantity: orderItem.quantity,
            unitPrice: unitPrice,
            totalPrice: unitPrice * orderItem.quantity,
            category: category,
          ),
        );
      }

      // Calculate totals
      final subtotal = billItems.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      final tax = order.tax;
      final shippingAmount = shipping ?? order.shipping;
      final oldDueAmount = oldDue ?? 0.0;
      final receivedAmountValue = receivedAmount ?? 0.0;
      // Total includes subtotal + shipping + tax (complete bill amount)
      final total = subtotal + shippingAmount + tax;

      // Extract manufacturer fields with null safety and defaults
      final manufacturerIdValue =
          manufacturer['id']?.toString() ?? manufacturerId;
      final manufacturerName = manufacturer['name']?.toString() ?? '';
      final businessName = manufacturer['business_name']?.toString() ?? '';
      final gstNumber = manufacturer['gst_number']?.toString() ?? '';
      final businessAddress =
          manufacturer['business_address']?.toString() ?? '';
      final city = manufacturer['city']?.toString() ?? '';
      final manufacturerState = manufacturer['state']?.toString() ?? '';
      final pincode = manufacturer['pincode']?.toString() ?? '';
      final email = manufacturer['email']?.toString();
      final phone = manufacturer['phone']?.toString();

      // Create manufacturer info with all fields properly mapped
      final manufacturerInfo = <String, dynamic>{
        'id': manufacturerIdValue,
        'name': manufacturerName,
        'business_name': businessName,
        'gst_number': gstNumber,
        'business_address': businessAddress,
        'city': city,
        'state': manufacturerState,
        'pincode': pincode,
      };

      // Add optional fields only if they exist
      if (email != null && email.isNotEmpty) {
        manufacturerInfo['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        manufacturerInfo['phone'] = phone;
      }

      if (kDebugMode) {
        print('Manufacturer info created: $manufacturerInfo');
      }

      // Create order info
      final orderInfo = {
        'order_number': order.orderNumber,
        'status': order.status.toString(),
        'order_date': order.orderDate.toIso8601String(),
        'total_items': order.totalItems,
      };

      // Create customer info (for manufacturer bills, this is the company receiving the bill)
      final customerInfo = <String, dynamic>{
        'name': businessName.isNotEmpty ? businessName : manufacturerName,
      };

      if (email != null && email.isNotEmpty) {
        customerInfo['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        customerInfo['phone'] = phone;
      }

      // Build full address
      final addressParts = <String>[];
      if (businessAddress.isNotEmpty) addressParts.add(businessAddress);
      if (city.isNotEmpty) addressParts.add(city);
      if (manufacturerState.isNotEmpty) addressParts.add(manufacturerState);
      if (pincode.isNotEmpty) addressParts.add(pincode);

      if (addressParts.isNotEmpty) {
        customerInfo['address'] = addressParts.join(', ');
        customerInfo['city'] = city;
        customerInfo['state'] = manufacturerState;
        customerInfo['pincode'] = pincode;
      }

      // Validate manufacturer info before creating bill
      if (manufacturerInfo['business_name'] == null ||
          manufacturerInfo['business_name'].toString().isEmpty) {
        throw Exception('Manufacturer business name is required but missing');
      }
      if (manufacturerInfo['gst_number'] == null ||
          manufacturerInfo['gst_number'].toString().isEmpty) {
        if (kDebugMode) {
          print('Warning: Manufacturer GST number is missing');
        }
      }

      if (kDebugMode) {
        print('Customer info created: $customerInfo');
        print('Manufacturer info validated and ready for bill creation');
      }

      // Validate manufacturer info before creating bill
      if (manufacturerInfo.isEmpty) {
        throw Exception(
          'Manufacturer info is empty and cannot be used for bill creation',
        );
      }

      // Create bill data with validated manufacturer info
      final billData = BillData(
        items: billItems,
        subtotal: subtotal,
        tax: tax,
        shipping: shippingAmount,
        total: total,
        oldDue: oldDueAmount,
        receivedAmount: receivedAmountValue,
        customerInfo: customerInfo,
        orderInfo: orderInfo,
        manufacturerInfo: manufacturerInfo,
      );

      // Validate bill data before creation
      if (billData.manufacturerInfo == null ||
          billData.manufacturerInfo!.isEmpty) {
        throw Exception('Manufacturer info is missing from bill data');
      }

      if (kDebugMode) {
        print(
          'Creating bill with manufacturer info: ${billData.manufacturerInfo}',
        );
      }

      // Create bill
      final bill = await _billRepository.createBill(
        billType: BillType.manufacturer,
        userId: order.userId ?? '',
        billData: billData,
        orderId: order.id,
        orderNumber: order.orderNumber,
      );

      if (kDebugMode) {
        print('Bill created successfully: ${bill.billNumber}');
        print('Bill data manufacturer info: ${bill.billData.manufacturerInfo}');
      }

      // Verify manufacturer info is in the created bill
      if (bill.billData.manufacturerInfo == null ||
          bill.billData.manufacturerInfo!.isEmpty) {
        if (kDebugMode) {
          print('ERROR: Manufacturer info is missing from created bill!');
        }
        throw Exception('Manufacturer info was not saved in bill data');
      }

      // Generate PDF
      final pdfBytes = await _pdfService.generateBillPdf(
        bill: bill,
        template: template,
      );

      if (kDebugMode) {
        print('PDF generated successfully, size: ${pdfBytes.length} bytes');
      }

      // Upload PDF in background
      _uploadPdfInBackground(bill, pdfBytes);

      // Reload bills immediately
      await loadBills();

      state = state.copyWith(isLoading: false);

      if (kDebugMode) {
        print('Manufacturer bill generation completed successfully');
      }

      return bill;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error generating manufacturer bill: $e');
        print('Stack trace: $stackTrace');
      }

      String errorMessage = 'Failed to generate manufacturer bill';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = 'Failed to generate manufacturer bill: $e';
      }

      state = state.copyWith(error: errorMessage, isLoading: false);
      return null;
    }
  }

  /// Generate standalone bill for a product
  Future<Bill?> generateStandaloneBill({
    required Product product,
    required String userId,
    required Map<String, dynamic> customerInfo,
    required int quantity,
    required BillType billType,
    double? tax,
    double? shipping,
    Map<String, dynamic>? companyInfo,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Get active template
      final template = await _billRepository.getActiveBillTemplate(billType);

      // Determine unit price based on bill type
      final unitPrice =
          billType == BillType.user
              ? product.price
              : (product.costPrice ?? product.price * 0.9);

      final totalPrice = unitPrice * quantity;

      // Extract category from product (use first category if multiple exist)
      final category =
          product.categories.isNotEmpty ? product.categories.first : null;

      // Create bill item
      final billItem = BillItem(
        productId: product.id,
        productName: product.name,
        sku: product.sku,
        imageUrl: product.imageUrl,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        category: category,
      );

      // Calculate totals
      final subtotal = totalPrice;
      final taxAmount = tax ?? 0.0;
      final shippingAmount = shipping ?? 0.0;
      final total = subtotal + taxAmount + shippingAmount;

      // Create bill data
      final billData = BillData(
        items: [billItem],
        subtotal: subtotal,
        tax: taxAmount,
        shipping: shippingAmount,
        total: total,
        customerInfo: customerInfo,
        companyInfo: companyInfo,
      );

      // Create bill
      final bill = await _billRepository.createBill(
        billType: billType,
        userId: userId,
        billData: billData,
        productId: product.id,
      );

      // Generate PDF
      final pdfBytes = await _pdfService.generateBillPdf(
        bill: bill,
        template: template,
      );

      // Upload PDF
      final pdfUrl = await _billRepository.uploadBillPdf(
        pdfBytes,
        bill.billNumber,
      );

      // Update bill with PDF URL
      await _billRepository.updateBillPdfUrl(bill.id, pdfUrl);

      // Reload bills
      await loadBills();

      state = state.copyWith(isLoading: false);
      return bill;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to generate bill: $e',
        isLoading: false,
      );
      return null;
    }
  }

  /// Download bill PDF
  Future<Uint8List?> downloadBillPdf(Bill bill) async {
    try {
      // Validate bill data before processing
      if (bill.billData.items.isEmpty) {
        throw Exception(
          'Bill has no items. Cannot generate PDF for empty bill.',
        );
      }

      // Validate bill items for any potential issues
      for (int i = 0; i < bill.billData.items.length; i++) {
        final item = bill.billData.items[i];
        if (item.productName.isEmpty) {
          if (kDebugMode) {
            print('Warning: Bill item at index $i has empty product name');
          }
        }
        if (item.quantity <= 0) {
          if (kDebugMode) {
            print(
              'Warning: Bill item at index $i has invalid quantity: ${item.quantity}',
            );
          }
        }
      }

      // Always regenerate PDF so the user gets the current template
      final template = await _billRepository.getActiveBillTemplate(
        bill.billType,
      );

      try {
        final pdfBytes = await _pdfService.generateBillPdf(
          bill: bill,
          template: template,
        );

        // Upload and update bill
        final pdfUrl = await _billRepository.uploadBillPdf(
          pdfBytes,
          bill.billNumber,
        );
        await _billRepository.updateBillPdfUrl(bill.id, pdfUrl);

        return pdfBytes;
      } catch (e) {
        // Handle specific RangeError with better message
        if (e is RangeError) {
          if (kDebugMode) {
            print('RangeError in PDF generation: $e');
            print('Bill ID: ${bill.id}');
            print('Bill Number: ${bill.billNumber}');
            print('Number of items: ${bill.billData.items.length}');
          }
          throw Exception(
            'PDF generation failed due to data access error. This may be caused by corrupted bill data. Please try regenerating the bill.',
          );
        }
        // Re-throw to be caught by outer catch
        rethrow;
      }
    } on RangeError catch (e) {
      // Catch RangeError specifically with detailed message
      String errorMessage =
          'PDF generation failed: Data access error (${e.message}). ';
      errorMessage +=
          'This may be caused by corrupted or malformed bill data. ';
      errorMessage += 'Please try regenerating the bill.';

      if (kDebugMode) {
        print('RangeError in downloadBillPdf: $e');
        print('Bill ID: ${bill.id}');
        print('Bill Number: ${bill.billNumber}');
      }

      state = state.copyWith(error: errorMessage);
      return null;
    } catch (e, stackTrace) {
      // Handle all other errors
      String errorMessage = 'Failed to download PDF';

      if (e is Exception) {
        final errorString = e.toString();
        if (errorString.contains('RangeError') ||
            errorString.contains('index')) {
          errorMessage =
              'PDF generation failed: Data access error. This may be caused by corrupted bill data. Please try regenerating the bill.';
        } else {
          errorMessage = errorString.replaceFirst('Exception: ', '');
        }
      } else {
        errorMessage = 'Failed to download PDF: $e';
      }

      if (kDebugMode) {
        print('Error in downloadBillPdf: $e');
        print('Stack trace: $stackTrace');
        print('Bill ID: ${bill.id}');
        print('Bill Number: ${bill.billNumber}');
      }

      state = state.copyWith(error: errorMessage);
      return null;
    }
  }

  /// Upload bill template
  Future<void> uploadBillTemplate({
    required BillType templateType,
    required String templateName,
    required MediaUploadResult image,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Upload image
      final imageUrl = await _billRepository.uploadBillTemplate(
        templateType: templateType,
        templateName: templateName,
        image: image,
      );

      // Create template record
      await _billRepository.createBillTemplate(
        templateType: templateType,
        templateName: templateName,
        imageUrl: imageUrl,
        isActive: true,
      );

      // Reload templates
      await loadTemplates();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to upload template: $e',
        isLoading: false,
      );
    }
  }

  /// Set active template
  Future<void> setActiveTemplate(String templateId) async {
    try {
      await _billRepository.setActiveTemplate(templateId);
      await loadTemplates();
    } catch (e) {
      state = state.copyWith(error: 'Failed to set active template: $e');
    }
  }

  /// Upload PDF in background to prevent UI blocking
  Future<void> _uploadPdfInBackground(Bill bill, Uint8List pdfBytes) async {
    try {
      if (kDebugMode) {
        print('Starting background PDF upload for bill ${bill.billNumber}...');
      }
      final pdfUrl = await _billRepository.uploadBillPdf(
        pdfBytes,
        bill.billNumber,
      );
      await _billRepository.updateBillPdfUrl(bill.id, pdfUrl);

      if (kDebugMode) {
        print('Background PDF upload successful for bill ${bill.billNumber}');
      }

      // Reload bills to update UI with PDF URL
      await loadBills();
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to upload generated PDF in background: $e');
      }
    }
  }

  /// Filter bills by type
  void filterBillsByType(BillType? billType) {
    state = state.copyWith(selectedBillType: billType);
    loadBills(billType: billType);
  }
}

// Providers
final billRepositoryProvider = Provider<BillRepositorySupabase>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BillRepositorySupabase(supabase);
});

final billPdfServiceProvider = Provider<BillPdfService>((ref) {
  final repository = ref.watch(billRepositoryProvider);
  return BillPdfService(repository);
});

final billControllerProvider = StateNotifierProvider<BillController, BillState>(
  (ref) {
    final repository = ref.watch(billRepositoryProvider);
    final pdfService = ref.watch(billPdfServiceProvider);
    return BillController(repository, pdfService);
  },
);
