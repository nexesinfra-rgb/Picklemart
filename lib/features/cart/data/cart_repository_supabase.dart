import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../application/cart_controller.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/measurement.dart';
import '../../admin/data/product_repository_supabase.dart';
import 'cart_repository.dart';

/// Supabase cart repository for managing cart items in the database
class CartRepositorySupabase implements CartRepository {
  final SupabaseClient _supabase;
  final ProductRepositorySupabase _productRepository;

  CartRepositorySupabase(
    this._supabase,
    this._productRepository,
  );

  /// Fetch all cart items for a user
  @override
  Future<List<CartItem>> fetchCartItems(String userId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final cartItemsData = List<Map<String, dynamic>>.from(response);
      if (cartItemsData.isEmpty) return [];

      // Use batch conversion to avoid N+1 queries
      return await _convertSupabaseToCartItemsBatch(cartItemsData);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchCartItems: $e');
      }
      rethrow;
    }
  }

  /// Add cart item as a new entry
  /// Returns the cart item ID from the database
  @override
  Future<String> addCartItem(CartItem cartItem, String userId) async {
    try {
      final itemData = await _convertCartItemToSupabase(cartItem, userId);

      // Insert new item and get the ID
      // Always create a new entry instead of updating existing ones
      final response = await _supabase
          .from('cart_items')
          .insert(itemData)
          .select('id')
          .single();
      
      final cartItemId = response['id'] as String;
      
      if (kDebugMode) {
        print('DEBUG: Added new cart item entry - ID: $cartItemId, Product: ${cartItem.product.name}, Quantity: ${cartItem.quantity}');
      }

      return cartItemId;
    } catch (e) {
      if (kDebugMode) {
        print('Error in addCartItem: $e');
      }
      rethrow;
    }
  }

  /// Set cart item quantity (upsert with exact quantity)
  /// Returns the cart item ID from the database
  @override
  Future<String> setCartItemQuantity(CartItem cartItem, String userId) async {
    try {
      final itemData = await _convertCartItemToSupabase(cartItem, userId);

      if (cartItem.quantity <= 0) {
        // Don't insert items with quantity 0 or less
        throw ArgumentError('Cannot insert cart item with quantity <= 0');
      }
      
      // Insert new item with exact quantity
      // Always create a new entry instead of updating existing ones
      final response = await _supabase
          .from('cart_items')
          .insert(itemData)
          .select('id')
          .single();
      
      final cartItemId = response['id'] as String;
      
      if (kDebugMode) {
        print('DEBUG: Set cart item quantity - ID: $cartItemId, Product: ${cartItem.product.name}, Quantity: ${cartItem.quantity}');
      }

      return cartItemId;
    } catch (e) {
      if (kDebugMode) {
        print('Error in setCartItemQuantity: $e');
      }
      rethrow;
    }
  }

  /// Update cart item quantity
  @override
  Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        // If quantity is 0 or less, remove the item
        await removeCartItem(cartItemId);
        return;
      }

      await _supabase
          .from('cart_items')
          .update({'quantity': quantity})
          .eq('id', cartItemId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateCartItemQuantity: $e');
      }
      rethrow;
    }
  }

  /// Remove cart item
  @override
  Future<void> removeCartItem(String cartItemId) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('id', cartItemId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in removeCartItem: $e');
      }
      rethrow;
    }
  }

  /// Clear all cart items for a user
  @override
  Future<void> clearCart(String userId) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in clearCart: $e');
      }
      rethrow;
    }
  }

  /// Subscribe to real-time cart changes for a user
  @override
  Stream<List<CartItem>> subscribeToCartChanges(String userId) {
    final controller = StreamController<List<CartItem>>();

    // Initial fetch
    fetchCartItems(userId).then((items) {
      if (!controller.isClosed) {
        controller.add(items);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Subscribe to real-time changes
    final subscription = _supabase
        .from('cart_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
      (data) {
        // SOCKET OPTIMIZATION: Process in microtask to prevent blocking UI thread
        scheduleMicrotask(() async {
          try {
            // Use batch conversion for stream updates too
            final cartItemsData = List<Map<String, dynamic>>.from(data);
            final cartItems = await _convertSupabaseToCartItemsBatch(cartItemsData);
            if (!controller.isClosed) {
              controller.add(cartItems);
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        });
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Cancel subscription when stream is closed
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Convert multiple Supabase cart items to CartItem objects using batch fetching
  /// This method eliminates N+1 queries by batch fetching all products and variants
  Future<List<CartItem>> _convertSupabaseToCartItemsBatch(
    List<Map<String, dynamic>> cartItemsData,
  ) async {
    try {
      if (cartItemsData.isEmpty) return [];

      // Collect all product IDs and variant IDs
      final productIds = <String>{};
      final variantIds = <String>{};

      for (final itemData in cartItemsData) {
        final productId = itemData['product_id'] as String?;
        if (productId != null && productId.isNotEmpty) {
          productIds.add(productId);
        }

        final variantId = itemData['variant_id'] as String?;
        if (variantId != null && variantId.isNotEmpty) {
          variantIds.add(variantId);
        }
      }

      if (productIds.isEmpty) return [];

      // Batch fetch all products with variants and measurements in parallel
      // This parallelizes the queries instead of sequential N+1
      final productsMap = <String, Product>{};
      if (productIds.isNotEmpty) {
        try {
          // Fetch all products in parallel using Future.wait
          // This is much faster than sequential fetches
          final productFutures = productIds.map((productId) async {
            try {
              final product = await _productRepository.fetchById(productId);
              return MapEntry(productId, product);
            } catch (e) {
              if (kDebugMode) {
                print('Error fetching product $productId: $e');
              }
              return MapEntry<String, Product?>(productId, null);
            }
          });

          final productResults = await Future.wait(productFutures);
          for (final entry in productResults) {
            if (entry.value != null) {
              productsMap[entry.key] = entry.value!;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error batch fetching products: $e');
          }
        }
      }

      // Batch fetch all variants if needed
      final variantsMap = <String, Variant>{};
      if (variantIds.isNotEmpty) {
        try {
          final variantsResponse = await _supabase
              .from('product_variants')
              .select('*')
              .inFilter('id', variantIds.toList());

          final variantsData = List<Map<String, dynamic>>.from(variantsResponse);

          for (final variantData in variantsData) {
            final variantId = variantData['id'] as String? ?? '';
            final productId = variantData['product_id'] as String? ?? '';
            final product = productsMap[productId];
            
            if (product != null) {
              // Parse variant from data
              final attributes = variantData['attributes'] as Map<String, dynamic>?;
              final attributesMap = <String, String>{};
              if (attributes != null) {
                attributes.forEach((key, value) {
                  attributesMap[key] = value.toString();
                });
              }

              final images = variantData['images'] as List<dynamic>?;
              final imagesList = images?.map((img) => img.toString()).toList() ?? [];

              final variant = Variant(
                sku: variantData['sku'] as String? ?? '',
                attributes: attributesMap,
                price: (variantData['price'] as num?)?.toDouble() ?? 0.0,
                stock: variantData['stock'] as int? ?? 0,
                images: imagesList,
              );

              // Find matching variant in product by SKU
              try {
                final matchingVariant = product.variants.firstWhere(
                  (v) => v.sku == variant.sku,
                );
                variantsMap[variantId] = matchingVariant;
              } catch (e) {
                // Variant not found in product, use the one we created
                variantsMap[variantId] = variant;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error batch fetching variants: $e');
          }
        }
      }

      // Convert cart items using pre-fetched data
      final cartItems = <CartItem>[];
      for (final itemData in cartItemsData) {
        try {
          final productId = itemData['product_id'] as String? ?? '';
          final variantId = itemData['variant_id'] as String?;
          final quantity = itemData['quantity'] as int? ?? 1;
          final measurementUnitStr = itemData['measurement_unit'] as String?;

          final product = productsMap[productId];
          if (product == null) {
            if (kDebugMode) {
              print('Product not found: $productId');
            }
            continue;
          }

          // Find variant if variant_id is provided
          Variant? variant;
          if (variantId != null && variantsMap.containsKey(variantId)) {
            variant = variantsMap[variantId];
          }

          // Parse measurement unit
          MeasurementUnit? measurementUnit;
          if (measurementUnitStr != null) {
            measurementUnit = _parseMeasurementUnit(measurementUnitStr);
          }

          final cartItemId = itemData['id'] as String?;

          cartItems.add(
            CartItem(
              product,
              quantity,
              id: cartItemId,
              variant: variant,
              measurementUnit: measurementUnit,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error converting cart item ${itemData['id']}: $e');
          }
          // Continue with other items even if one fails
        }
      }

      return cartItems;
    } catch (e) {
      if (kDebugMode) {
        print('Error in _convertSupabaseToCartItemsBatch: $e');
      }
      rethrow;
    }
  }

  /// Convert Supabase cart item data to CartItem object (legacy method for single items)
  Future<CartItem?> _convertSupabaseToCartItem(
    Map<String, dynamic> itemData,
  ) async {
    try {
      final productId = itemData['product_id'] as String? ?? '';
      final variantId = itemData['variant_id'] as String?;
      final quantity = itemData['quantity'] as int? ?? 1;
      final measurementUnitStr = itemData['measurement_unit'] as String?;

      // Fetch product
      final product = await _productRepository.fetchById(productId);
      if (product == null) {
        if (kDebugMode) {
          print('Product not found: $productId');
        }
        return null;
      }

      // Find variant if variant_id is provided
      Variant? variant;

      // Fetch variant from Supabase if variant_id is provided
      if (variantId != null) {
        try {
          final variantResponse = await _supabase
              .from('product_variants')
              .select('*')
              .eq('id', variantId)
              .maybeSingle();

          if (variantResponse != null) {
            final variantSku = variantResponse['sku'] as String? ?? '';
            // Find matching variant in product variants
            try {
              variant = product.variants.firstWhere(
                (v) => v.sku == variantSku,
              );
            } catch (e) {
              // Variant not found in product variants, create a temporary variant
              // or skip this cart item
              if (kDebugMode) {
                print('Variant $variantSku not found in product variants');
              }
              // Skip this cart item if variant is required but not found
              return null;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching variant: $e');
          }
          // Skip this cart item if variant fetch fails
          return null;
        }
      }

      // Parse measurement unit
      MeasurementUnit? measurementUnit;
      if (measurementUnitStr != null) {
        measurementUnit = _parseMeasurementUnit(measurementUnitStr);
      }

      // Get database ID
      final cartItemId = itemData['id'] as String?;

      return CartItem(
        product,
        quantity,
        id: cartItemId,
        variant: variant,
        measurementUnit: measurementUnit,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in _convertSupabaseToCartItem: $e');
      }
      return null;
    }
  }

  /// Convert CartItem to Supabase row format
  Future<Map<String, dynamic>> _convertCartItemToSupabase(
    CartItem cartItem,
    String userId,
  ) async {
    final itemData = <String, dynamic>{
      'user_id': userId,
      'product_id': cartItem.product.id,
      'quantity': cartItem.quantity,
    };

    // Add variant_id if variant exists
    if (cartItem.variant != null) {
      try {
        // Find variant ID from Supabase using product_id and SKU
        final variantResponse = await _supabase
            .from('product_variants')
            .select('id')
            .eq('product_id', cartItem.product.id)
            .eq('sku', cartItem.variant!.sku)
            .maybeSingle();

        if (variantResponse != null) {
          itemData['variant_id'] = variantResponse['id'] as String;
        } else {
          // Variant not found in database, set to null
          itemData['variant_id'] = null;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching variant ID: $e');
        }
        itemData['variant_id'] = null;
      }
    } else {
      itemData['variant_id'] = null;
    }

    // Add measurement_unit if exists
    if (cartItem.measurementUnit != null) {
      itemData['measurement_unit'] = cartItem.measurementUnit!.shortName;
    } else {
      itemData['measurement_unit'] = null;
    }

    return itemData;
  }

  /// Parse measurement unit string to enum
  MeasurementUnit _parseMeasurementUnit(String unit) {
    final unitLower = unit.toLowerCase().trim();
    switch (unitLower) {
      case 'kg':
        return MeasurementUnit.kg;
      case 'gram':
      case 'g':
        return MeasurementUnit.gram;
      case 'liter':
      case 'l':
        return MeasurementUnit.liter;
      case 'ml':
        return MeasurementUnit.ml;
      case 'piece':
      case 'pc':
        return MeasurementUnit.piece;
      case 'dozen':
      case 'dz':
        return MeasurementUnit.dozen;
      case 'pack':
        return MeasurementUnit.pack;
      case 'box':
        return MeasurementUnit.box;
      case 'bag':
        return MeasurementUnit.bag;
      case 'bottle':
        return MeasurementUnit.bottle;
      case 'can':
        return MeasurementUnit.can;
      case 'roll':
        return MeasurementUnit.roll;
      case 'meter':
      case 'm':
        return MeasurementUnit.meter;
      case 'cm':
        return MeasurementUnit.cm;
      case 'inch':
      case 'in':
        return MeasurementUnit.inch;
      case 'foot':
      case 'ft':
        return MeasurementUnit.foot;
      case 'yard':
      case 'yd':
        return MeasurementUnit.yard;
      default:
        return MeasurementUnit.piece;
    }
  }
}

