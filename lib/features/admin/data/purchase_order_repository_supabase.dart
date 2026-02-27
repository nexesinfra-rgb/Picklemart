import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/purchase_order.dart';
import '../../orders/data/order_model.dart';

/// Repository for managing purchase orders in Supabase
class PurchaseOrderRepositorySupabase {
  final SupabaseClient _supabase;

  PurchaseOrderRepositorySupabase(this._supabase);

  /// Convert Supabase purchase order data to PurchaseOrder model
  Future<PurchaseOrder> _convertSupabaseToPurchaseOrder(
    Map<String, dynamic> purchaseOrderData, {
    List<Map<String, dynamic>>? preFetchedItems,
  }) async {
    final purchaseOrderId = purchaseOrderData['id'] as String;
    List<Map<String, dynamic>> itemsData;

    if (preFetchedItems != null) {
      itemsData = preFetchedItems;
    } else {
      // Fetch purchase order items
      final itemsResponse = await _supabase
          .from('purchase_order_items')
          .select('*')
          .eq('purchase_order_id', purchaseOrderId)
          .order('created_at', ascending: true);
      itemsData = List<Map<String, dynamic>>.from(itemsResponse as List);
    }

    // Check for items missing category (legacy data fix)
    final missingCategoryItems =
        itemsData.where((item) => item['category'] == null).toList();

    if (missingCategoryItems.isNotEmpty) {
      try {
        final productIds =
            missingCategoryItems
                .map((item) => item['product_id'] as String)
                .toSet()
                .toList();

        if (productIds.isNotEmpty) {
          final productsResponse = await _supabase
              .from('products')
              .select('id, categories')
              .inFilter('id', productIds);

          final categoryMap = <String, String>{};
          for (final product in productsResponse) {
            final id = product['id'] as String;
            final categories = product['categories'];
            if (categories != null &&
                categories is List &&
                categories.isNotEmpty) {
              final firstCat = categories.first;
              if (firstCat != null) {
                categoryMap[id] = firstCat.toString();
              }
            }
          }

          // Backfill categories
          for (var item in itemsData) {
            if (item['category'] == null) {
              item['category'] = categoryMap[item['product_id']];
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error backfilling categories: $e');
        }
      }
    }

    final items =
        itemsData.map((item) => PurchaseOrderItem.fromJson(item)).toList();

    // Parse dates
    final purchaseDateString = purchaseOrderData['purchase_date'] as String;
    final expectedDeliveryDateString =
        purchaseOrderData['expected_delivery_date'] as String?;
    final createdAtString = purchaseOrderData['created_at'] as String;
    final updatedAtString = purchaseOrderData['updated_at'] as String;

    return PurchaseOrder(
      id: purchaseOrderId,
      purchaseNumber: purchaseOrderData['purchase_number'] as String,
      orderId: purchaseOrderData['order_id'] as String?,
      manufacturerId: purchaseOrderData['manufacturer_id'] as String?,
      customerId: purchaseOrderData['customer_id'] as String?,
      status:
          PurchaseOrderStatusExtension.fromDatabaseValue(
            purchaseOrderData['status'] as String,
          ) ??
          PurchaseOrderStatus.pending,
      subtotal: (purchaseOrderData['subtotal'] as num).toDouble(),
      tax: (purchaseOrderData['tax'] as num).toDouble(),
      shipping: (purchaseOrderData['shipping'] as num).toDouble(),
      total: (purchaseOrderData['total'] as num).toDouble(),
      paidAmount: (purchaseOrderData['paid_amount'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: DateTime.parse(purchaseDateString),
      expectedDeliveryDate:
          expectedDeliveryDateString != null
              ? DateTime.parse(expectedDeliveryDateString)
              : null,
      notes: purchaseOrderData['notes'] as String?,
      deliveryLocation: purchaseOrderData['delivery_location'] as String?,
      transportationName: purchaseOrderData['transportation_name'] as String?,
      transportationPhone: purchaseOrderData['transportation_phone'] as String?,
      createdAt: DateTime.parse(createdAtString),
      updatedAt: DateTime.parse(updatedAtString),
      items: items,
    );
  }

  /// Create a purchase order from an existing order (sale)
  Future<PurchaseOrder> createPurchaseOrderFromOrder({
    required Order order,
    String? manufacturerId,
    String? customerId,
    required DateTime purchaseDate,
    DateTime? expectedDeliveryDate,
    double? tax,
    double? shipping,
    String? notes,
    String? deliveryLocation,
    String? transportationName,
    String? transportationPhone,
    List<PurchaseOrderItem>? customItems,
    double? paidAmount,
  }) async {
    try {
      // Fetch product categories to ensure items are grouped correctly in PDF
      Map<String, String> productCategories = {};
      if (customItems == null) {
        try {
          final productIds = order.items.map((e) => e.id).toList();
          if (productIds.isNotEmpty) {
            final productsResponse = await _supabase
                .from('products')
                .select('id, categories')
                .inFilter('id', productIds);

            for (final product in productsResponse) {
              final id = product['id'] as String;
              final categories = product['categories'];
              // Handle categories whether they are List<dynamic> or List<String>
              if (categories != null &&
                  categories is List &&
                  categories.isNotEmpty) {
                final firstCat = categories.first;
                if (firstCat != null) {
                  productCategories[id] = firstCat.toString();
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching product categories: $e');
          }
          // Continue without categories if fetch fails
        }
      }

      // Use custom items if provided, otherwise convert order items
      final items =
          customItems ??
          order.items.map((orderItem) {
            return PurchaseOrderItem(
              id: '', // Will be generated by database
              productId: orderItem.id,
              name: orderItem.name,
              image: orderItem.image,
              quantity: orderItem.quantity,
              unitPrice: orderItem.price,
              totalPrice: orderItem.totalPrice,
              category: productCategories[orderItem.id],
            );
          }).toList();

      // Calculate totals
      final subtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final taxAmount = tax ?? 0.0;
      final shippingAmount = shipping ?? 0.0;
      final total = subtotal + taxAmount + shippingAmount;

      // Create purchase order
      final purchaseOrderData = {
        'order_id': order.id,
        if (manufacturerId != null) 'manufacturer_id': manufacturerId,
        if (customerId != null) 'customer_id': customerId,
        'status': PurchaseOrderStatus.pending.databaseValue,
        'subtotal': subtotal,
        'tax': taxAmount,
        'shipping': shippingAmount,
        'total': total,
        'paid_amount': paidAmount ?? 0.0,
        'purchase_date': purchaseDate.toIso8601String(),
        if (expectedDeliveryDate != null)
          'expected_delivery_date':
              expectedDeliveryDate.toIso8601String().split('T')[0],
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (deliveryLocation != null && deliveryLocation.isNotEmpty)
          'delivery_location': deliveryLocation,
        if (transportationName != null && transportationName.isNotEmpty)
          'transportation_name': transportationName,
        if (transportationPhone != null && transportationPhone.isNotEmpty)
          'transportation_phone': transportationPhone,
      };

      final purchaseOrderResponse =
          await _supabase
              .from('purchase_orders')
              .insert(purchaseOrderData)
              .select()
              .single();

      final purchaseOrderId = purchaseOrderResponse['id'] as String;

      // Create purchase order items
      final itemsData =
          items.map((item) {
            return {
              'purchase_order_id': purchaseOrderId,
              'product_id': item.productId,
              if (item.variantId != null) 'variant_id': item.variantId,
              if (item.measurementUnit != null)
                'measurement_unit': item.measurementUnit,
              'name': item.name,
              'image': item.image,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
              if (item.category != null) 'category': item.category,
              if (item.notes != null && item.notes!.isNotEmpty)
                'notes': item.notes,
            };
          }).toList();

      await _supabase.from('purchase_order_items').insert(itemsData);

      // Fetch and return the complete purchase order
      return await _convertSupabaseToPurchaseOrder(purchaseOrderResponse);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating purchase order from order: $e');
      }
      throw Exception('Failed to create purchase order: $e');
    }
  }

  /// Create a new purchase order
  Future<PurchaseOrder> createPurchaseOrder({
    String? manufacturerId,
    String? customerId,
    required DateTime purchaseDate,
    required List<PurchaseOrderItem> items,
    DateTime? expectedDeliveryDate,
    double? tax,
    double? shipping,
    String? notes,
    String? deliveryLocation,
    String? transportationName,
    String? transportationPhone,
    String? orderId,
    PurchaseOrderStatus? status,
    double? paidAmount,
  }) async {
    try {
      // Calculate totals
      final subtotal = items.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final taxAmount = tax ?? 0.0;
      final shippingAmount = shipping ?? 0.0;
      final total = subtotal + taxAmount + shippingAmount;

      // Create purchase order
      final purchaseOrderData = {
        if (orderId != null) 'order_id': orderId,
        if (manufacturerId != null) 'manufacturer_id': manufacturerId,
        if (customerId != null) 'customer_id': customerId,
        'status': (status ?? PurchaseOrderStatus.pending).databaseValue,
        'subtotal': subtotal,
        'tax': taxAmount,
        'shipping': shippingAmount,
        'total': total,
        'paid_amount': paidAmount ?? 0.0,
        'purchase_date': purchaseDate.toIso8601String(),
        if (expectedDeliveryDate != null)
          'expected_delivery_date':
              expectedDeliveryDate.toIso8601String().split('T')[0],
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (deliveryLocation != null && deliveryLocation.isNotEmpty)
          'delivery_location': deliveryLocation,
        if (transportationName != null && transportationName.isNotEmpty)
          'transportation_name': transportationName,
        if (transportationPhone != null && transportationPhone.isNotEmpty)
          'transportation_phone': transportationPhone,
      };

      final purchaseOrderResponse =
          await _supabase
              .from('purchase_orders')
              .insert(purchaseOrderData)
              .select()
              .single();

      final purchaseOrderId = purchaseOrderResponse['id'] as String;

      // Create purchase order items
      final itemsData =
          items.map((item) {
            return {
              'purchase_order_id': purchaseOrderId,
              'product_id': item.productId,
              if (item.variantId != null) 'variant_id': item.variantId,
              if (item.measurementUnit != null)
                'measurement_unit': item.measurementUnit,
              'name': item.name,
              'image': item.image,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
              if (item.category != null) 'category': item.category,
              if (item.notes != null && item.notes!.isNotEmpty)
                'notes': item.notes,
            };
          }).toList();

      await _supabase.from('purchase_order_items').insert(itemsData);

      // Fetch and return the complete purchase order
      return await _convertSupabaseToPurchaseOrder(purchaseOrderResponse);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating purchase order: $e');
      }
      throw Exception('Failed to create purchase order: $e');
    }
  }

  /// Get all purchase orders
  Future<List<PurchaseOrder>> getPurchaseOrders({
    String? manufacturerId,
    String? customerId,
    PurchaseOrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool onlyManufacturers = false,
    bool onlyCustomers = false,
  }) async {
    try {
      var query = _supabase.from('purchase_orders').select('*');

      if (manufacturerId != null) {
        query = query.eq('manufacturer_id', manufacturerId);
      }

      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }

      if (onlyManufacturers) {
        query = query.not('manufacturer_id', 'is', null);
      }

      if (onlyCustomers) {
        query = query.not('customer_id', 'is', null);
      }

      if (status != null) {
        query = query.eq('status', status.databaseValue);
      }

      if (startDate != null) {
        query = query.gte(
          'purchase_date',
          startDate.toIso8601String().split('T')[0],
        );
      }

      if (endDate != null) {
        query = query.lte(
          'purchase_date',
          endDate.toIso8601String().split('T')[0],
        );
      }

      final orderedQuery = query.order('created_at', ascending: false);

      final response =
          limit != null ? await orderedQuery.limit(limit) : await orderedQuery;

      final purchaseOrdersData = List<Map<String, dynamic>>.from(
        response as List,
      );
      if (purchaseOrdersData.isEmpty) return [];

      // Batch fetch items for all purchase orders
      final purchaseOrderIds =
          purchaseOrdersData.map((e) => e['id'] as String).toList();

      final allItemsResponse = await _supabase
          .from('purchase_order_items')
          .select('*')
          .filter('purchase_order_id', 'in', purchaseOrderIds)
          .order('created_at', ascending: true);

      final allItems = List<Map<String, dynamic>>.from(
        allItemsResponse as List,
      );

      // Group items by purchase_order_id
      final itemsMap = <String, List<Map<String, dynamic>>>{};
      for (final item in allItems) {
        final poId = item['purchase_order_id'] as String;
        if (!itemsMap.containsKey(poId)) {
          itemsMap[poId] = [];
        }
        itemsMap[poId]!.add(item);
      }

      final purchaseOrders = <PurchaseOrder>[];
      for (final row in purchaseOrdersData) {
        try {
          final poId = row['id'] as String;
          final purchaseOrder = await _convertSupabaseToPurchaseOrder(
            row,
            preFetchedItems: itemsMap[poId] ?? [],
          );
          purchaseOrders.add(purchaseOrder);
        } catch (e) {
          if (kDebugMode) {
            print('Error converting purchase order: $e');
          }
        }
      }

      return purchaseOrders;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching purchase orders: $e');
      }
      throw Exception('Failed to fetch purchase orders: $e');
    }
  }

  /// Get a purchase order by ID
  Future<PurchaseOrder?> getPurchaseOrderById(String id) async {
    try {
      final response =
          await _supabase
              .from('purchase_orders')
              .select('*')
              .eq('id', id)
              .single();

      return await _convertSupabaseToPurchaseOrder(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching purchase order: $e');
      }
      return null;
    }
  }

  /// Get a purchase order by purchase number
  Future<PurchaseOrder?> getPurchaseOrderByNumber(String purchaseNumber) async {
    try {
      final response = await _supabase
          .from('purchase_orders')
          .select('*')
          .eq('purchase_number', purchaseNumber);

      if (response.isNotEmpty) {
        return await _convertSupabaseToPurchaseOrder(response.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching purchase order by number: $e');
      }
      return null;
    }
  }

  /// Get multiple purchase orders by their numbers efficiently
  Future<List<PurchaseOrder>> getPurchaseOrdersByNumbers(
    List<String> purchaseNumbers,
  ) async {
    if (purchaseNumbers.isEmpty) return [];

    try {
      final response = await _supabase
          .from('purchase_orders')
          .select('*')
          .filter('purchase_number', 'in', purchaseNumbers);

      final purchaseOrdersData = List<Map<String, dynamic>>.from(
        response as List,
      );
      if (purchaseOrdersData.isEmpty) return [];

      // Batch fetch items
      final purchaseOrderIds =
          purchaseOrdersData.map((e) => e['id'] as String).toList();

      final allItemsResponse = await _supabase
          .from('purchase_order_items')
          .select('*')
          .filter('purchase_order_id', 'in', purchaseOrderIds)
          .order('created_at', ascending: true);

      final allItems = List<Map<String, dynamic>>.from(
        allItemsResponse as List,
      );

      // Group items by purchase_order_id
      final itemsMap = <String, List<Map<String, dynamic>>>{};
      for (final item in allItems) {
        final poId = item['purchase_order_id'] as String;
        if (!itemsMap.containsKey(poId)) {
          itemsMap[poId] = [];
        }
        itemsMap[poId]!.add(item);
      }

      final purchaseOrders = <PurchaseOrder>[];
      for (final row in purchaseOrdersData) {
        try {
          final poId = row['id'] as String;
          final purchaseOrder = await _convertSupabaseToPurchaseOrder(
            row,
            preFetchedItems: itemsMap[poId] ?? [],
          );
          purchaseOrders.add(purchaseOrder);
        } catch (e) {
          if (kDebugMode) {
            print('Error converting purchase order: $e');
          }
        }
      }

      return purchaseOrders;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching purchase orders by numbers: $e');
      }
      return [];
    }
  }

  /// Update a purchase order
  Future<PurchaseOrder> updatePurchaseOrder(PurchaseOrder purchaseOrder) async {
    try {
      // Update purchase order
      final purchaseOrderData = {
        if (purchaseOrder.manufacturerId != null)
          'manufacturer_id': purchaseOrder.manufacturerId,
        if (purchaseOrder.customerId != null)
          'customer_id': purchaseOrder.customerId,
        'status': purchaseOrder.status.databaseValue,
        'subtotal': purchaseOrder.subtotal,
        'tax': purchaseOrder.tax,
        'shipping': purchaseOrder.shipping,
        'total': purchaseOrder.total,
        'paid_amount': purchaseOrder.paidAmount,
        'purchase_date':
            purchaseOrder.purchaseDate.toIso8601String(),
        if (purchaseOrder.expectedDeliveryDate != null)
          'expected_delivery_date':
              purchaseOrder.expectedDeliveryDate!.toIso8601String().split(
                'T',
              )[0],
        if (purchaseOrder.notes != null && purchaseOrder.notes!.isNotEmpty)
          'notes': purchaseOrder.notes,
        if (purchaseOrder.deliveryLocation != null &&
            purchaseOrder.deliveryLocation!.isNotEmpty)
          'delivery_location': purchaseOrder.deliveryLocation,
        if (purchaseOrder.transportationName != null &&
            purchaseOrder.transportationName!.isNotEmpty)
          'transportation_name': purchaseOrder.transportationName,
        if (purchaseOrder.transportationPhone != null &&
            purchaseOrder.transportationPhone!.isNotEmpty)
          'transportation_phone': purchaseOrder.transportationPhone,
      };

      await _supabase
          .from('purchase_orders')
          .update(purchaseOrderData)
          .eq('id', purchaseOrder.id);

      // Delete existing items
      await _supabase
          .from('purchase_order_items')
          .delete()
          .eq('purchase_order_id', purchaseOrder.id);

      // Insert updated items
      final itemsData =
          purchaseOrder.items.map((item) {
            return {
              'purchase_order_id': purchaseOrder.id,
              'product_id': item.productId,
              if (item.variantId != null) 'variant_id': item.variantId,
              if (item.measurementUnit != null)
                'measurement_unit': item.measurementUnit,
              'name': item.name,
              'image': item.image,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'total_price': item.totalPrice,
              if (item.category != null) 'category': item.category,
              if (item.notes != null && item.notes!.isNotEmpty)
                'notes': item.notes,
            };
          }).toList();

      await _supabase.from('purchase_order_items').insert(itemsData);

      // Fetch and return updated purchase order
      return await getPurchaseOrderById(purchaseOrder.id) ?? purchaseOrder;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating purchase order: $e');
      }
      throw Exception('Failed to update purchase order: $e');
    }
  }

  /// Delete a purchase order
  Future<void> deletePurchaseOrder(String id) async {
    try {
      // Items will be deleted automatically due to CASCADE
      await _supabase.from('purchase_orders').delete().eq('id', id);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting purchase order: $e');
      }
      throw Exception('Failed to delete purchase order: $e');
    }
  }

  /// Subscribe to real-time purchase order changes
  Stream<List<PurchaseOrder>> subscribeToPurchaseOrders() {
    final controller = StreamController<List<PurchaseOrder>>();

    // Initial fetch
    getPurchaseOrders()
        .then((purchaseOrders) {
          if (!controller.isClosed) {
            controller.add(purchaseOrders);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });

    // Subscribe to real-time changes
    final subscription = _supabase
        .from('purchase_orders')
        .stream(primaryKey: ['id'])
        .listen(
          (data) async {
            try {
              if (data.isEmpty) {
                if (!controller.isClosed) {
                  controller.add([]);
                }
                return;
              }

              final purchaseOrders = <PurchaseOrder>[];
              for (final row in data) {
                try {
                  final purchaseOrder = await _convertSupabaseToPurchaseOrder(
                    row,
                  );
                  purchaseOrders.add(purchaseOrder);
                } catch (e) {
                  if (kDebugMode) {
                    print('Error converting purchase order in stream: $e');
                  }
                }
              }

              if (!controller.isClosed) {
                controller.add(purchaseOrders);
              }
            } catch (e) {
              if (!controller.isClosed) {
                controller.addError(e);
              }
            }
          },
          onError: (error) {
            // Log error but don't crash the stream if it's a realtime connection error
            if (kDebugMode) {
              print('Supabase Realtime Error (Purchase Orders): $error');
            }
            // Suppress error to keep UI stable
          },
        );

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }
}

/// Provider for PurchaseOrderRepositorySupabase
final purchaseOrderRepositoryProvider =
    Provider<PurchaseOrderRepositorySupabase>((ref) {
      final supabaseClient = ref.watch(supabaseClientProvider);
      return PurchaseOrderRepositorySupabase(supabaseClient);
    });
