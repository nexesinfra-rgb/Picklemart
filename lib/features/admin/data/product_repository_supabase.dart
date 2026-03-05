import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/environment.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/measurement.dart';
import '../../catalog/data/product_repository.dart';
import '../../../media_upload_widget.dart';

/// Supabase product repository for managing products in the database
class ProductRepositorySupabase implements ProductRepository {
  final SupabaseClient _supabase;

  ProductRepositorySupabase(this._supabase);

  /// Get Content-Type MIME type from file name based on extension
  String _getContentTypeFromFileName(String fileName) {
    String extension = 'jpg'; // Default extension
    if (fileName.contains('.')) {
      extension = fileName.split('.').last.toLowerCase();
    }

    // Map extension to MIME type
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'tiff':
        return 'image/tiff';
      case 'heic':
        return 'image/heic';
      case 'svg':
        return 'image/svg+xml';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Fix image URL by replacing old domain with new one
  String _fixImageUrl(String? url) {
    if (url == null) return '';
    if (url.trim().isEmpty) return '';
    
    // Work with a non-null string from here
    String fixedUrl = url.trim();

    // Fix for relative paths stored in DB (e.g. "products/...")
    // This happens if the full URL wasn't saved, just the storage path
    if (!fixedUrl.startsWith('http') && !fixedUrl.startsWith('https')) {
      // Clean up leading slash
      var path = fixedUrl.startsWith('/') ? fixedUrl.substring(1) : fixedUrl;

      // If it looks like a storage path or just a filename, construct the full URL
      // We assume any non-http string that isn't clearly an asset is a storage path
      if (!path.startsWith('assets/')) {
        final baseUrl = Environment.supabaseUrl;

        // Remove bucket name if it's already in the path to avoid duplication
        if (path.startsWith('product-images/')) {
          path = path.substring('product-images/'.length);
        }
        
        // Handle cases where path might start with a slash after removing bucket
        if (path.startsWith('/')) {
            path = path.substring(1);
        }

        return '$baseUrl/storage/v1/object/public/product-images/$path';
      }
    }

    // Replace old sslip.io domain with new custom domain
    const oldDomain =
        'supabasekong-ogw8kswcww8swko0c8gswsks.72.62.229.227.sslip.io';
    if (fixedUrl.contains(oldDomain)) {
      // Use the configured Supabase URL from environment
      // Ensure we don't duplicate https:// if it's already in the replacement
      final baseUrl = Environment.supabaseUrl;

      // Handle both http and https in the old URL
      if (fixedUrl.startsWith('http://$oldDomain')) {
        return fixedUrl.replaceFirst('http://$oldDomain', baseUrl);
      } else if (fixedUrl.startsWith('https://$oldDomain')) {
        return fixedUrl.replaceFirst('https://$oldDomain', baseUrl);
      } else {
        // Fallback for partial matches
        return fixedUrl.replaceAll(
          oldDomain,
          baseUrl.replaceFirst('https://', '').replaceFirst('http://', ''),
        );
      }
    }
    return fixedUrl;
  }

  /// Upload product images to Supabase Storage
  /// Returns list of public URLs for the uploaded images
  Future<List<String>> uploadProductImages(
    List<MediaUploadResult> images,
    String productId,
  ) async {
    try {
      final List<String> imageUrls = [];
      final bucket = _supabase.storage.from('product-images');

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        try {
          // Generate unique file name
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName =
              'products/$productId/${timestamp}_${i}_${image.fileName}';

          // Determine Content-Type based on file extension
          final contentType = _getContentTypeFromFileName(image.fileName);

          // Read file bytes based on platform
          Uint8List bytes;
          if (kIsWeb) {
            // On web, use XFile to read bytes from blob URLs or file paths
            // XFile works with blob URLs on web
            try {
              final xFile = XFile(image.path);
              bytes = await xFile.readAsBytes();
            } catch (e) {
              // If XFile fails, try handling data URLs or HTTP URLs
              if (image.path.startsWith('data:')) {
                // Handle data URL (base64 encoded)
                final base64String = image.path.split(',')[1];
                bytes = base64Decode(base64String);
              } else if (image.path.startsWith('http://') ||
                  image.path.startsWith('https://')) {
                // Fetch from HTTP URL (existing image URL)
                final response = await http.get(Uri.parse(image.path));
                if (response.statusCode == 200) {
                  bytes = response.bodyBytes;
                } else {
                  throw Exception(
                    'Failed to fetch image from URL: ${response.statusCode}',
                  );
                }
              } else {
                throw Exception('Unable to read image file on web: $e');
              }
            }
          } else {
            // On mobile, read from File path
            final file = File(image.path);
            if (await file.exists()) {
              bytes = await file.readAsBytes();
            } else {
              throw Exception('File not found: ${image.path}');
            }
          }

          if (bytes.isEmpty) {
            throw Exception('Image bytes are empty');
          }

          // Upload to Supabase Storage
          // Use platform-specific approach: uploadBinary on web, File upload on mobile
          if (kIsWeb) {
            // On web, use uploadBinary with bytes directly
            await bucket.uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: contentType,
                cacheControl: '3600',
              ),
            );
          } else {
            // On mobile, use File object with Supabase storage API
            final file = File(image.path);
            await bucket.upload(
              fileName,
              file,
              fileOptions: FileOptions(upsert: true, contentType: contentType),
            );
          }

          // Get public URL
          final publicUrl = bucket.getPublicUrl(fileName);
          imageUrls.add(publicUrl);
        } catch (e) {
          if (kDebugMode) {
            print('Error uploading image ${image.fileName}: $e');
          }
          // Continue with other images even if one fails
          // Log error but don't rethrow to allow other images to upload
          if (kDebugMode) {
            print('Skipping image ${image.fileName} due to error');
          }
        }
      }

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload any images');
      }

      return imageUrls;
    } catch (e) {
      if (kDebugMode) {
        print('Error in uploadProductImages: $e');
      }
      rethrow;
    }
  }

  /// Check if a SKU already exists in the database
  Future<bool> checkSkuExists(String? sku) async {
    if (sku == null || sku.isEmpty) {
      return false; // Empty SKU is allowed (not unique constraint)
    }

    try {
      final response = await _supabase
          .from('products')
          .select('id')
          .eq('sku', sku)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking SKU existence: $e');
      }
      // If check fails, let the insert proceed and handle error there
      return false;
    }
  }

  /// Insert product into Supabase database
  Future<Map<String, dynamic>> insertProduct(
    Product product,
    List<String> imageUrls,
  ) async {
    try {
      // Allow placeholder image for initial insert if needed
      final finalImageUrls =
          imageUrls.isEmpty ? ['https://via.placeholder.com/400'] : imageUrls;

      if (finalImageUrls.isEmpty || finalImageUrls.first.isEmpty) {
        throw Exception('At least one image is required');
      }

      // Check if SKU already exists
      if (product.sku != null && product.sku!.isNotEmpty) {
        final skuExists = await checkSkuExists(product.sku);
        if (skuExists) {
          throw Exception(
            'A product with SKU "${product.sku}" already exists. '
            'Please use a different SKU or update the existing product.',
          );
        }
      }

      final productData = <String, dynamic>{
        'name': product.name,
        'subtitle': product.subtitle,
        'description': product.description,
        'price': product.price,
        'brand': product.brand,
        'sku': product.sku,
        'stock': product.stock,
        'image_url': finalImageUrls.first, // Primary image
        'images': finalImageUrls, // All images
        'categories': product.categories,
        'tags': product.tags,
        'alternative_names': product.alternativeNames,
        'is_active': true,
        'is_out_of_stock': product.isOutOfStock,
      };

      // Only include nullable fields if they have values
      if (product.costPrice != null) {
        productData['cost_price'] = product.costPrice;
      }
      if (product.tax != null) {
        productData['tax'] = product.tax;
      }

      final response =
          await _supabase
              .from('products')
              .insert(productData)
              .select()
              .single();

      return response;
    } on PostgrestException catch (e) {
      // Handle PostgrestException specifically for better error messages
      if (e.code == '23505') {
        // Duplicate key violation
        String errorMessage = 'A product with this SKU already exists. ';
        if (product.sku != null && product.sku!.isNotEmpty) {
          errorMessage = 'A product with SKU "${product.sku}" already exists. ';
        }
        errorMessage +=
            'Please use a different SKU or update the existing product.';
        throw Exception(errorMessage);
      }
      // Rethrow other PostgrestExceptions with original message
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in insertProduct: $e');
      }
      rethrow;
    }
  }

  /// Update product in Supabase database
  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Product product,
    List<String>? imageUrls,
  ) async {
    try {
      final productData = <String, dynamic>{
        'name': product.name,
        'subtitle': product.subtitle,
        'description': product.description,
        'price': product.price,
        'brand': product.brand,
        'sku': product.sku,
        'stock': product.stock,
        'categories': product.categories,
        'tags': product.tags,
        'alternative_names': product.alternativeNames,
        'is_out_of_stock': product.isOutOfStock,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only include nullable fields if they have values
      if (product.costPrice != null) {
        productData['cost_price'] = product.costPrice;
      }
      if (product.tax != null) {
        productData['tax'] = product.tax;
      }

      // Update images if provided
      if (imageUrls != null && imageUrls.isNotEmpty) {
        productData['image_url'] = imageUrls.first;
        productData['images'] = imageUrls;
      }

      final response =
          await _supabase
              .from('products')
              .update(productData)
              .eq('id', productId)
              .select()
              .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateProduct: $e');
      }
      rethrow;
    }
  }

  /// Insert product variants into Supabase database
  Future<void> insertProductVariants(
    String productId,
    List<Variant> variants,
  ) async {
    try {
      if (variants.isEmpty) return;

      // Delete existing variants
      await _supabase
          .from('product_variants')
          .delete()
          .eq('product_id', productId);

      // Insert new variants
      final variantsData =
          variants.map((variant) {
            final variantData = <String, dynamic>{
              'product_id': productId,
              'sku': variant.sku,
              'attributes': variant.attributes, // JSONB
              'price': variant.price,
              'stock': variant.stock,
              'images': variant.images,
            };

            // Only include nullable fields if they have values
            if (variant.costPrice != null) {
              variantData['cost_price'] = variant.costPrice;
            }
            if (variant.tax != null) {
              variantData['tax'] = variant.tax;
            }

            return variantData;
          }).toList();

      await _supabase.from('product_variants').insert(variantsData);
    } catch (e) {
      if (kDebugMode) {
        print('Error in insertProductVariants: $e');
      }
      rethrow;
    }
  }

  /// Insert product measurement into Supabase database
  Future<void> insertProductMeasurement(
    String productId,
    ProductMeasurement measurement,
  ) async {
    try {
      // Delete existing measurement
      await _supabase
          .from('product_measurements')
          .delete()
          .eq('product_id', productId);

      // Convert pricing options to JSON
      final pricingOptions =
          measurement.pricingOptions.map((pricing) {
            return {
              'unit': pricing.unit.name,
              'price': pricing.price,
              'stock': pricing.stock,
            };
          }).toList();

      final measurementData = {
        'product_id': productId,
        'default_unit': measurement.defaultUnit.name,
        'category': measurement.category,
        'pricing_options': pricingOptions, // JSONB
      };

      await _supabase.from('product_measurements').insert(measurementData);
    } catch (e) {
      if (kDebugMode) {
        print('Error in insertProductMeasurement: $e');
      }
      rethrow;
    }
  }

  /// Convert string to MeasurementUnit enum
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
        if (kDebugMode) {
          print('Unknown measurement unit: $unit, defaulting to piece');
        }
        return MeasurementUnit.piece;
    }
  }

  /// Helper method to chunk a list into smaller lists
  /// Used to avoid hitting PostgreSQL/Supabase limits on IN clauses (~1000 items)
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    if (list.isEmpty) return [];
    if (chunkSize <= 0) return [list];

    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  /// Fetch product variants from Supabase
  Future<List<Variant>> fetchProductVariants(String productId) async {
    try {
      final response = await _supabase
          .from('product_variants')
          .select('*')
          .eq('product_id', productId);

      final variantsData = List<Map<String, dynamic>>.from(response);
      return variantsData.map((variantData) {
        // Parse attributes from JSONB
        final attributes = variantData['attributes'] as Map<String, dynamic>?;
        final attributesMap = <String, String>{};
        if (attributes != null) {
          attributes.forEach((key, value) {
            attributesMap[key] = value.toString();
          });
        }

        // Parse images array
        final images = variantData['images'] as List<dynamic>?;
        final imagesList =
            images?.map((img) => _fixImageUrl(img.toString())).toList() ?? [];

        return Variant(
          sku: variantData['sku'] as String? ?? '',
          attributes: attributesMap,
          price: (variantData['price'] as num?)?.toDouble() ?? 0.0,
          costPrice: (variantData['cost_price'] as num?)?.toDouble(),
          tax: (variantData['tax'] as num?)?.toDouble(),
          stock: variantData['stock'] as int? ?? 0,
          images: imagesList,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchProductVariants: $e');
      }
      return [];
    }
  }

  /// Fetch product variants in batch for multiple products
  /// Returns a map keyed by product ID with list of variants for each product
  /// Handles large product ID lists by chunking to avoid PostgreSQL IN clause limits
  Future<Map<String, List<Variant>>> _fetchProductVariantsBatch(
    List<String> productIds,
  ) async {
    try {
      if (productIds.isEmpty) return {};

      // Chunk product IDs to avoid hitting PostgreSQL/Supabase IN clause limits (~1000 items)
      const maxChunkSize = 1000;
      final chunks = _chunkList(productIds, maxChunkSize);

      // If only one chunk, use the original single query approach for efficiency
      if (chunks.length == 1) {
        final response = await _supabase
            .from('product_variants')
            .select('*')
            .inFilter('product_id', productIds);

        final variantsData = List<Map<String, dynamic>>.from(response);
        final variantsMap = <String, List<Variant>>{};

        for (final variantData in variantsData) {
          final productId = variantData['product_id'] as String? ?? '';

          // Parse attributes from JSONB
          final attributes = variantData['attributes'] as Map<String, dynamic>?;
          final attributesMap = <String, String>{};
          if (attributes != null) {
            attributes.forEach((key, value) {
              attributesMap[key] = value.toString();
            });
          }

          // Parse images array
          final images = variantData['images'] as List<dynamic>?;
          final imagesList =
              images?.map((img) => _fixImageUrl(img.toString())).toList() ?? [];

          final variant = Variant(
            sku: variantData['sku'] as String? ?? '',
            attributes: attributesMap,
            price: (variantData['price'] as num?)?.toDouble() ?? 0.0,
            costPrice: (variantData['cost_price'] as num?)?.toDouble(),
            tax: (variantData['tax'] as num?)?.toDouble(),
            stock: variantData['stock'] as int? ?? 0,
            images: imagesList,
          );

          variantsMap.putIfAbsent(productId, () => []).add(variant);
        }

        // Initialize empty lists for products without variants
        for (final productId in productIds) {
          variantsMap.putIfAbsent(productId, () => []);
        }

        return variantsMap;
      }

      // Multiple chunks: fetch in parallel and merge results
      final futures = chunks.map((chunk) async {
        final response = await _supabase
            .from('product_variants')
            .select('*')
            .inFilter('product_id', chunk);

        final variantsData = List<Map<String, dynamic>>.from(response);
        final chunkMap = <String, List<Variant>>{};

        for (final variantData in variantsData) {
          final productId = variantData['product_id'] as String? ?? '';

          // Parse attributes from JSONB
          final attributes = variantData['attributes'] as Map<String, dynamic>?;
          final attributesMap = <String, String>{};
          if (attributes != null) {
            attributes.forEach((key, value) {
              attributesMap[key] = value.toString();
            });
          }

          // Parse images array
          final images = variantData['images'] as List<dynamic>?;
          final imagesList =
              images?.map((img) => _fixImageUrl(img.toString())).toList() ?? [];

          final variant = Variant(
            sku: variantData['sku'] as String? ?? '',
            attributes: attributesMap,
            price: (variantData['price'] as num?)?.toDouble() ?? 0.0,
            costPrice: (variantData['cost_price'] as num?)?.toDouble(),
            tax: (variantData['tax'] as num?)?.toDouble(),
            stock: variantData['stock'] as int? ?? 0,
            images: imagesList,
          );

          chunkMap.putIfAbsent(productId, () => []).add(variant);
        }

        return chunkMap;
      });

      // Wait for all chunks to complete
      final chunkResults = await Future.wait(futures);

      // Merge all chunk results
      final variantsMap = <String, List<Variant>>{};
      for (final chunkMap in chunkResults) {
        chunkMap.forEach((productId, variants) {
          variantsMap.putIfAbsent(productId, () => []).addAll(variants);
        });
      }

      // Initialize empty lists for products without variants
      for (final productId in productIds) {
        variantsMap.putIfAbsent(productId, () => []);
      }

      return variantsMap;
    } catch (e) {
      if (kDebugMode) {
        print('Error in _fetchProductVariantsBatch: $e');
      }
      // Return empty map with empty lists for all product IDs on error
      return {for (final id in productIds) id: <Variant>[]};
    }
  }

  /// Fetch product measurement from Supabase
  Future<ProductMeasurement?> fetchProductMeasurement(String productId) async {
    try {
      final response =
          await _supabase
              .from('product_measurements')
              .select('*')
              .eq('product_id', productId)
              .maybeSingle();

      if (response == null) return null;

      // Parse pricing options from JSONB
      final pricingOptionsData = response['pricing_options'] as List<dynamic>?;
      final pricingOptions = <MeasurementPricing>[];

      if (pricingOptionsData != null) {
        for (final pricingData in pricingOptionsData) {
          final pricingMap = pricingData as Map<String, dynamic>;
          final unitStr = pricingMap['unit'] as String? ?? 'piece';
          final unit = _parseMeasurementUnit(unitStr);

          pricingOptions.add(
            MeasurementPricing(
              unit: unit,
              price: (pricingMap['price'] as num?)?.toDouble() ?? 0.0,
              stock: pricingMap['stock'] as int? ?? 0,
            ),
          );
        }
      }

      final defaultUnitStr = response['default_unit'] as String? ?? 'piece';
      final defaultUnit = _parseMeasurementUnit(defaultUnitStr);

      return ProductMeasurement(
        productId: productId,
        pricingOptions: pricingOptions,
        defaultUnit: defaultUnit,
        category: response['category'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchProductMeasurement: $e');
      }
      return null;
    }
  }

  /// Fetch product measurements in batch for multiple products
  /// Returns a map keyed by product ID with measurement for each product (null if no measurement)
  /// Handles large product ID lists by chunking to avoid PostgreSQL IN clause limits
  Future<Map<String, ProductMeasurement?>> _fetchProductMeasurementsBatch(
    List<String> productIds,
  ) async {
    try {
      if (productIds.isEmpty) return {};

      // Chunk product IDs to avoid hitting PostgreSQL/Supabase IN clause limits (~1000 items)
      const maxChunkSize = 1000;
      final chunks = _chunkList(productIds, maxChunkSize);

      // If only one chunk, use the original single query approach for efficiency
      if (chunks.length == 1) {
        final response = await _supabase
            .from('product_measurements')
            .select('*')
            .inFilter('product_id', productIds);

        final measurementsData = List<Map<String, dynamic>>.from(response);
        final measurementsMap = <String, ProductMeasurement?>{};

        for (final measurementData in measurementsData) {
          final productId = measurementData['product_id'] as String? ?? '';

          // Parse pricing options from JSONB
          final pricingOptionsData =
              measurementData['pricing_options'] as List<dynamic>?;
          final pricingOptions = <MeasurementPricing>[];

          if (pricingOptionsData != null) {
            for (final pricingData in pricingOptionsData) {
              final pricingMap = pricingData as Map<String, dynamic>;
              final unitStr = pricingMap['unit'] as String? ?? 'piece';
              final unit = _parseMeasurementUnit(unitStr);

              pricingOptions.add(
                MeasurementPricing(
                  unit: unit,
                  price: (pricingMap['price'] as num?)?.toDouble() ?? 0.0,
                  stock: pricingMap['stock'] as int? ?? 0,
                ),
              );
            }
          }

          final defaultUnitStr =
              measurementData['default_unit'] as String? ?? 'piece';
          final defaultUnit = _parseMeasurementUnit(defaultUnitStr);

          measurementsMap[productId] = ProductMeasurement(
            productId: productId,
            pricingOptions: pricingOptions,
            defaultUnit: defaultUnit,
            category: measurementData['category'] as String?,
          );
        }

        // Initialize null for products without measurements
        for (final productId in productIds) {
          measurementsMap.putIfAbsent(productId, () => null);
        }

        return measurementsMap;
      }

      // Multiple chunks: fetch in parallel and merge results
      final futures = chunks.map((chunk) async {
        final response = await _supabase
            .from('product_measurements')
            .select('*')
            .inFilter('product_id', chunk);

        final measurementsData = List<Map<String, dynamic>>.from(response);
        final chunkMap = <String, ProductMeasurement?>{};

        for (final measurementData in measurementsData) {
          final productId = measurementData['product_id'] as String? ?? '';

          // Parse pricing options from JSONB
          final pricingOptionsData =
              measurementData['pricing_options'] as List<dynamic>?;
          final pricingOptions = <MeasurementPricing>[];

          if (pricingOptionsData != null) {
            for (final pricingData in pricingOptionsData) {
              final pricingMap = pricingData as Map<String, dynamic>;
              final unitStr = pricingMap['unit'] as String? ?? 'piece';
              final unit = _parseMeasurementUnit(unitStr);

              pricingOptions.add(
                MeasurementPricing(
                  unit: unit,
                  price: (pricingMap['price'] as num?)?.toDouble() ?? 0.0,
                  stock: pricingMap['stock'] as int? ?? 0,
                ),
              );
            }
          }

          final defaultUnitStr =
              measurementData['default_unit'] as String? ?? 'piece';
          final defaultUnit = _parseMeasurementUnit(defaultUnitStr);

          chunkMap[productId] = ProductMeasurement(
            productId: productId,
            pricingOptions: pricingOptions,
            defaultUnit: defaultUnit,
            category: measurementData['category'] as String?,
          );
        }

        return chunkMap;
      });

      // Wait for all chunks to complete
      final chunkResults = await Future.wait(futures);

      // Merge all chunk results
      final measurementsMap = <String, ProductMeasurement?>{};
      for (final chunkMap in chunkResults) {
        measurementsMap.addAll(chunkMap);
      }

      // Initialize null for products without measurements
      for (final productId in productIds) {
        measurementsMap.putIfAbsent(productId, () => null);
      }

      return measurementsMap;
    } catch (e) {
      if (kDebugMode) {
        print('Error in _fetchProductMeasurementsBatch: $e');
      }
      // Return map with null for all product IDs on error
      return {for (final id in productIds) id: null};
    }
  }

  /// Convert Supabase product data to Product object
  Future<Product> _convertSupabaseToProduct(
    Map<String, dynamic> productData,
  ) async {
    final productId = productData['id'] as String? ?? '';

    // Parse arrays
    final images = productData['images'] as List<dynamic>?;
    final imagesList =
        images?.map((img) => _fixImageUrl(img.toString())).toList() ?? [];

    // Ensure we have a valid image URL by falling back to the first image in gallery if needed
    String imageUrl = _fixImageUrl(productData['image_url'] as String?);
    if (imageUrl.isEmpty && imagesList.isNotEmpty) {
      imageUrl = imagesList.first;
    }

    final categories = productData['categories'] as List<dynamic>?;
    final categoriesList =
        categories?.map((cat) => cat.toString()).toList() ?? [];

    final tags = productData['tags'] as List<dynamic>?;
    final tagsList = tags?.map((tag) => tag.toString()).toList() ?? [];

    final alternativeNames = productData['alternative_names'] as List<dynamic>?;
    final alternativeNamesList =
        alternativeNames
            ?.map((name) => name.toString().trim())
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];

    // Parse dates
    final createdAtString = productData['created_at'] as String?;
    final updatedAtString = productData['updated_at'] as String?;
    final createdAt =
        createdAtString != null ? DateTime.tryParse(createdAtString) : null;
    final updatedAt =
        updatedAtString != null ? DateTime.tryParse(updatedAtString) : null;

    // Fetch variants and measurement
    final variants = await fetchProductVariants(productId);
    final measurement = await fetchProductMeasurement(productId);

    // Parse rating fields
    final averageRating =
        productData['average_rating'] != null
            ? (productData['average_rating'] as num?)?.toDouble()
            : null;
    final ratingCount = productData['rating_count'] as int? ?? 0;

    return Product(
      id: productId,
      name: productData['name'] as String? ?? '',
      subtitle: productData['subtitle'] as String?,
      description: productData['description'] as String?,
      price: (productData['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (productData['cost_price'] as num?)?.toDouble(),
      tax: (productData['tax'] as num?)?.toDouble(),
      brand: productData['brand'] as String?,
      sku: productData['sku'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      stock: productData['stock'] as int? ?? 0,
      imageUrl: imageUrl,
      images: imagesList,
      categories: categoriesList,
      tags: tagsList,
      alternativeNames: alternativeNamesList,
      variants: variants,
      measurement: measurement,
      isFeatured: productData['is_featured'] as bool? ?? false,
      featuredPosition: productData['featured_position'] as int? ?? 0,
      averageRating: averageRating,
      ratingCount: ratingCount,
      isOutOfStock: productData['is_out_of_stock'] as bool? ?? false,
    );
  }

  /// Convert Supabase product data to Product object using pre-fetched batch data
  /// This method does not make any database queries - it uses the provided maps
  Product _convertSupabaseToProductBatch(
    Map<String, dynamic> productData,
    Map<String, List<Variant>> variantsMap,
    Map<String, ProductMeasurement?> measurementsMap,
  ) {
    final productId = productData['id'] as String? ?? '';

    // Parse arrays
    final images = productData['images'] as List<dynamic>?;
    final imagesList =
        images?.map((img) => _fixImageUrl(img.toString())).toList() ?? [];

    // Ensure we have a valid image URL by falling back to the first image in gallery if needed
    String imageUrl = _fixImageUrl(productData['image_url'] as String?);
    if (imageUrl.isEmpty && imagesList.isNotEmpty) {
      imageUrl = imagesList.first;
    }

    final categories = productData['categories'] as List<dynamic>?;
    final categoriesList =
        categories?.map((cat) => cat.toString()).toList() ?? [];

    final tags = productData['tags'] as List<dynamic>?;
    final tagsList = tags?.map((tag) => tag.toString()).toList() ?? [];

    final alternativeNames = productData['alternative_names'] as List<dynamic>?;
    final alternativeNamesList =
        alternativeNames
            ?.map((name) => name.toString().trim())
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];

    // Parse dates
    final createdAtString = productData['created_at'] as String?;
    final updatedAtString = productData['updated_at'] as String?;
    final createdAt =
        createdAtString != null ? DateTime.tryParse(createdAtString) : null;
    final updatedAt =
        updatedAtString != null ? DateTime.tryParse(updatedAtString) : null;

    // Get variants and measurement from pre-fetched maps
    final variants = variantsMap[productId] ?? [];
    final measurement = measurementsMap[productId];

    // Parse rating fields
    final averageRating =
        productData['average_rating'] != null
            ? (productData['average_rating'] as num?)?.toDouble()
            : null;
    final ratingCount = productData['rating_count'] as int? ?? 0;

    return Product(
      id: productId,
      name: productData['name'] as String? ?? '',
      subtitle: productData['subtitle'] as String?,
      description: productData['description'] as String?,
      price: (productData['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (productData['cost_price'] as num?)?.toDouble(),
      tax: (productData['tax'] as num?)?.toDouble(),
      brand: productData['brand'] as String?,
      sku: productData['sku'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      stock: productData['stock'] as int? ?? 0,
      imageUrl: imageUrl,
      images: imagesList,
      categories: categoriesList,
      tags: tagsList,
      alternativeNames: alternativeNamesList,
      variants: variants,
      measurement: measurement,
      isFeatured: productData['is_featured'] as bool? ?? false,
      featuredPosition: productData['featured_position'] as int? ?? 0,
      averageRating: averageRating,
      ratingCount: ratingCount,
      isOutOfStock: productData['is_out_of_stock'] as bool? ?? false,
    );
  }

  /// Fetch all products from Supabase (implements ProductRepository.fetchAll)
  @override
  Future<List<Product>> fetchAll() async {
    try {
      // Limit to last 1000 products to prevent loading all products at once
      final response = await _supabase
          .from('products')
          .select('*')
          .not('is_active', 'is', null)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1000);

      final productsData = List<Map<String, dynamic>>.from(response);
      if (productsData.isEmpty) return [];

      // Extract product IDs for batch fetching
      final productIds =
          productsData
              .map((data) => data['id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toList();

      if (productIds.isEmpty) return [];

      // Batch fetch variants and measurements in parallel
      final variantsFuture = _fetchProductVariantsBatch(productIds);
      final measurementsFuture = _fetchProductMeasurementsBatch(productIds);

      final results = await Future.wait([variantsFuture, measurementsFuture]);

      final variantsMap = results[0] as Map<String, List<Variant>>;
      final measurementsMap = results[1] as Map<String, ProductMeasurement?>;

      // Convert products using batch conversion (no additional queries)
      final products = <Product>[];
      for (final productData in productsData) {
        try {
          // Validate product data before conversion
          if (productData['id'] == null) {
            if (kDebugMode) {
              print('Warning: Skipping product with null ID');
            }
            continue;
          }

          final product = _convertSupabaseToProductBatch(
            productData,
            variantsMap,
            measurementsMap,
          );
          products.add(product);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('Error converting product ${productData['id']}: $e');
            print('Stack trace: $stackTrace');
            print('Product data: ${productData.keys.toList()}');
          }
          // Continue with other products even if one fails
        }
      }

      return products;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in fetchAll: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Fetch all products from Supabase (alias for fetchAll for backward compatibility)
  Future<List<Product>> fetchProducts() async => fetchAll();

  /// Fetch all products for admin (includes inactive/deleted products)
  /// This method does not filter by is_active, allowing admins to see all products
  Future<List<Product>> fetchAllProductsForAdmin() async {
    try {
      // Admin users can see all products (including inactive) per RLS policy
      // Limit to last 100 products to prevent loading all products at once
      final response = await _supabase
          .from('products')
          .select('*')
          .order('created_at', ascending: false)
          .limit(100);

      final productsData = List<Map<String, dynamic>>.from(response);
      if (productsData.isEmpty) return [];

      // Extract product IDs for batch fetching
      final productIds =
          productsData
              .map((data) => data['id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toList();

      if (productIds.isEmpty) return [];

      // Batch fetch variants and measurements in parallel
      final variantsFuture = _fetchProductVariantsBatch(productIds);
      final measurementsFuture = _fetchProductMeasurementsBatch(productIds);

      final results = await Future.wait([variantsFuture, measurementsFuture]);

      final variantsMap = results[0] as Map<String, List<Variant>>;
      final measurementsMap = results[1] as Map<String, ProductMeasurement?>;

      // Convert products using batch conversion (no additional queries)
      final products = <Product>[];
      for (final productData in productsData) {
        try {
          // Validate product data before conversion
          if (productData['id'] == null) {
            if (kDebugMode) {
              print('Warning: Skipping product with null ID');
            }
            continue;
          }

          final product = _convertSupabaseToProductBatch(
            productData,
            variantsMap,
            measurementsMap,
          );
          products.add(product);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('Error converting product ${productData['id']}: $e');
            print('Stack trace: $stackTrace');
            print('Product data: ${productData.keys.toList()}');
          }
          // Continue with other products even if one fails
        }
      }

      return products;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in fetchAllProductsForAdmin: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Fetch all products for admin with pagination
  /// [includeInactive] - Whether to include inactive/deleted products (default: false)
  Future<List<Product>> fetchAllProductsForAdminPaginated({
    int page = 1,
    int limit = 50,
    bool includeInactive = false,
  }) async {
    try {
      final startIndex = (page - 1) * limit;

      var query = _supabase.from('products').select('*');

      if (!includeInactive) {
        query = query.eq('is_active', true);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final productsData = List<Map<String, dynamic>>.from(response);
      if (productsData.isEmpty) return [];

      // Extract product IDs for batch fetching
      final productIds =
          productsData
              .map((data) => data['id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toList();

      if (productIds.isEmpty) return [];

      // Batch fetch variants and measurements in parallel
      final variantsFuture = _fetchProductVariantsBatch(productIds);
      final measurementsFuture = _fetchProductMeasurementsBatch(productIds);

      final results = await Future.wait([variantsFuture, measurementsFuture]);

      final variantsMap = results[0] as Map<String, List<Variant>>;
      final measurementsMap = results[1] as Map<String, ProductMeasurement?>;

      // Convert products using batch conversion (no additional queries)
      final products = <Product>[];
      for (final productData in productsData) {
        try {
          // Validate product data before conversion
          if (productData['id'] == null) {
            if (kDebugMode) {
              print('Warning: Skipping product with null ID');
            }
            continue;
          }

          final product = _convertSupabaseToProductBatch(
            productData,
            variantsMap,
            measurementsMap,
          );
          products.add(product);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('Error converting product ${productData['id']}: $e');
            print('Stack trace: $stackTrace');
            print('Product data: ${productData.keys.toList()}');
          }
          // Continue with other products even if one fails
        }
      }

      return products;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in fetchAllProductsForAdminPaginated: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Fetch featured products from Supabase (implements ProductRepository.fetchFeatured)
  @override
  Future<List<Product>> fetchFeatured() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .not('is_active', 'is', null)
          .eq('is_active', true)
          .not('is_featured', 'is', null)
          .eq('is_featured', true)
          .order('featured_position', ascending: true)
          .order('created_at', ascending: false);

      final productsData = List<Map<String, dynamic>>.from(response);
      if (productsData.isEmpty) return [];

      // Extract product IDs for batch fetching
      final productIds =
          productsData
              .map((data) => data['id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toList();

      if (productIds.isEmpty) return [];

      // Batch fetch variants and measurements in parallel
      final variantsFuture = _fetchProductVariantsBatch(productIds);
      final measurementsFuture = _fetchProductMeasurementsBatch(productIds);

      final results = await Future.wait([variantsFuture, measurementsFuture]);

      final variantsMap = results[0] as Map<String, List<Variant>>;
      final measurementsMap = results[1] as Map<String, ProductMeasurement?>;

      // Convert products using batch conversion (no additional queries)
      final products = <Product>[];
      for (final productData in productsData) {
        try {
          // Validate product data before conversion
          if (productData['id'] == null) {
            if (kDebugMode) {
              print('Warning: Skipping product with null ID in fetchFeatured');
            }
            continue;
          }

          final product = _convertSupabaseToProductBatch(
            productData,
            variantsMap,
            measurementsMap,
          );
          products.add(product);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print(
              'Error converting product ${productData['id']} in fetchFeatured: $e',
            );
            print('Stack trace: $stackTrace');
            print('Product data: ${productData.keys.toList()}');
          }
          // Continue with other products even if one fails
        }
      }

      return products;
    } on PostgrestException catch (e) {
      // Handle case where is_featured column doesn't exist (error code 42703)
      if (e.code == '42703') {
        if (kDebugMode) {
          print(
            '⚠️  Warning: is_featured column does not exist in products table.',
          );
          print(
            '   Please apply migration: supabase_migrations/017_add_featured_flags.sql',
          );
          print('   You can run it via Supabase SQL Editor or CLI.');
        }
        // Return empty list gracefully instead of crashing
        return [];
      }
      // Rethrow other PostgrestExceptions
      if (kDebugMode) {
        print(
          'PostgrestException in fetchFeatured: ${e.message} (code: ${e.code})',
        );
      }
      rethrow;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in fetchFeatured: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Fetch paginated products from Supabase (implements ProductRepository.fetchPaginated)
  @override
  Future<List<Product>> fetchPaginated({int page = 1, int limit = 20}) async {
    try {
      final startIndex = (page - 1) * limit;
      final response = await _supabase
          .from('products')
          .select('*')
          .not('is_active', 'is', null)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final productsData = List<Map<String, dynamic>>.from(response);
      if (productsData.isEmpty) return [];

      // Extract product IDs for batch fetching
      final productIds =
          productsData
              .map((data) => data['id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toList();

      if (productIds.isEmpty) return [];

      // Batch fetch variants and measurements in parallel
      final variantsFuture = _fetchProductVariantsBatch(productIds);
      final measurementsFuture = _fetchProductMeasurementsBatch(productIds);

      final results = await Future.wait([variantsFuture, measurementsFuture]);

      final variantsMap = results[0] as Map<String, List<Variant>>;
      final measurementsMap = results[1] as Map<String, ProductMeasurement?>;

      // Convert products using batch conversion (no additional queries)
      final products = <Product>[];
      for (final productData in productsData) {
        try {
          // Validate product data before conversion
          if (productData['id'] == null) {
            if (kDebugMode) {
              print(
                'Warning: Skipping product with null ID in fetchPaginated (page $page)',
              );
            }
            continue;
          }

          final product = _convertSupabaseToProductBatch(
            productData,
            variantsMap,
            measurementsMap,
          );
          products.add(product);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print(
              'Error converting product ${productData['id']} in fetchPaginated (page $page): $e',
            );
            print('Stack trace: $stackTrace');
            print('Product data: ${productData.keys.toList()}');
          }
          // Continue with other products even if one fails
        }
      }

      return products;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in fetchPaginated (page $page, limit $limit): $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Fetch paginated featured products from Supabase (implements ProductRepository.fetchFeaturedPaginated)
  @override
  Future<List<Product>> fetchFeaturedPaginated({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final startIndex = (page - 1) * limit;
      final response = await _supabase
          .from('products')
          .select('*')
          .not('is_active', 'is', null)
          .eq('is_active', true)
          .not('is_featured', 'is', null)
          .eq('is_featured', true)
          .order('featured_position', ascending: true)
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final productsData = List<Map<String, dynamic>>.from(response);
      if (productsData.isEmpty) return [];

      // Extract product IDs for batch fetching
      final productIds =
          productsData
              .map((data) => data['id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toList();

      if (productIds.isEmpty) return [];

      // Batch fetch variants and measurements in parallel
      final variantsFuture = _fetchProductVariantsBatch(productIds);
      final measurementsFuture = _fetchProductMeasurementsBatch(productIds);

      final results = await Future.wait([variantsFuture, measurementsFuture]);

      final variantsMap = results[0] as Map<String, List<Variant>>;
      final measurementsMap = results[1] as Map<String, ProductMeasurement?>;

      // Convert products using batch conversion (no additional queries)
      final products = <Product>[];
      for (final productData in productsData) {
        try {
          // Validate product data before conversion
          if (productData['id'] == null) {
            if (kDebugMode) {
              print(
                'Warning: Skipping product with null ID in fetchFeaturedPaginated (page $page)',
              );
            }
            continue;
          }

          final product = _convertSupabaseToProductBatch(
            productData,
            variantsMap,
            measurementsMap,
          );
          products.add(product);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print(
              'Error converting product ${productData['id']} in fetchFeaturedPaginated (page $page): $e',
            );
            print('Stack trace: $stackTrace');
            print('Product data: ${productData.keys.toList()}');
          }
          // Continue with other products even if one fails
        }
      }

      return products;
    } on PostgrestException catch (e) {
      // Handle case where is_featured column doesn't exist (error code 42703)
      if (e.code == '42703') {
        if (kDebugMode) {
          print(
            '⚠️  Warning: is_featured column does not exist in products table.',
          );
          print(
            '   Please apply migration: supabase_migrations/017_add_featured_flags.sql',
          );
          print('   You can run it via Supabase SQL Editor or CLI.');
        }
        // Return empty list gracefully instead of crashing
        return [];
      }
      // Rethrow other PostgrestExceptions
      if (kDebugMode) {
        print(
          'PostgrestException in fetchFeaturedPaginated: ${e.message} (code: ${e.code})',
        );
      }
      rethrow;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in fetchFeaturedPaginated (page $page, limit $limit): $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Fetch products by category from Supabase (implements ProductRepository.fetchByCategory)
  ///
  /// **Important Notes:**
  /// - Category matching is **case-sensitive**. The category name must match exactly
  ///   as stored in the database (e.g., "Tools" != "tools").
  /// - For case-insensitive matching, ensure categories are normalized (lowercase)
  ///   when stored in the database, or normalize the input category parameter.
  ///
  /// **Performance:**
  /// - Uses database-level filtering with GIN index on categories array
  /// - Batch fetches variants and measurements in parallel for optimal performance
  ///
  /// **Parameters:**
  /// - [category] - Category name to filter by (case-sensitive, will be trimmed)
  /// - [page] - Page number (1-indexed, must be >= 1)
  /// - [limit] - Number of products per page (must be > 0)
  ///
  /// **Returns:**
  /// - List of products matching the category, empty list if no matches or invalid input
  @override
  Future<List<Product>> fetchByCategory(
    String category, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Input validation: trim and check category
      final normalizedCategory = category.trim();
      if (normalizedCategory.isEmpty) {
        if (kDebugMode) {
          print(
            'fetchByCategory: Empty category provided, returning empty list',
          );
        }
        return [];
      }

      // Input validation: validate pagination parameters
      if (page < 1) {
        if (kDebugMode) {
          print('fetchByCategory: Invalid page number ($page), using page 1');
        }
        page = 1;
      }
      if (limit < 1) {
        if (kDebugMode) {
          print('fetchByCategory: Invalid limit ($limit), using limit 20');
        }
        limit = 20;
      }

      // Enforce maximum limit to prevent excessive queries (optimized for 20k+ products)
      const maxLimit = 100;
      if (limit > maxLimit) {
        if (kDebugMode) {
          print(
            'fetchByCategory: Limit ($limit) exceeds maximum ($maxLimit), capping at $maxLimit',
          );
        }
        limit = maxLimit;
      }

      final startIndex = (page - 1) * limit;

      // Use Supabase array contains operator for efficient database filtering
      // This filters at the database level instead of fetching all products
      // Note: .contains() is case-sensitive - category must match exactly as stored
      final response = await _supabase
          .from('products')
          .select('*')
          .not('is_active', 'is', null)
          .eq('is_active', true)
          .contains('categories', [normalizedCategory])
          .order('created_at', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final productsData = List<Map<String, dynamic>>.from(response);
      if (productsData.isEmpty) {
        if (kDebugMode) {
          print(
            'fetchByCategory: No products found for category "$normalizedCategory"',
          );
        }
        return [];
      }

      // Extract product IDs for batch fetching
      final productIds =
          productsData
              .map((data) => data['id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toList();

      if (productIds.isEmpty) {
        if (kDebugMode) {
          print(
            'fetchByCategory: No valid product IDs found for category "$normalizedCategory"',
          );
        }
        return [];
      }

      // Batch fetch variants and measurements in parallel
      final variantsFuture = _fetchProductVariantsBatch(productIds);
      final measurementsFuture = _fetchProductMeasurementsBatch(productIds);

      final results = await Future.wait([variantsFuture, measurementsFuture]);

      final variantsMap = results[0] as Map<String, List<Variant>>;
      final measurementsMap = results[1] as Map<String, ProductMeasurement?>;

      // Convert products using batch conversion (no additional queries)
      final products = <Product>[];
      for (final productData in productsData) {
        try {
          // Validate product data before conversion
          if (productData['id'] == null) {
            if (kDebugMode) {
              print(
                'fetchByCategory: Warning - Skipping product with null ID for category "$normalizedCategory"',
              );
            }
            continue;
          }

          final product = _convertSupabaseToProductBatch(
            productData,
            variantsMap,
            measurementsMap,
          );
          products.add(product);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print(
              'fetchByCategory: Error converting product ${productData['id']} for category "$normalizedCategory": $e',
            );
            print('Stack trace: $stackTrace');
            print('Product data: ${productData.keys.toList()}');
          }
          // Continue with other products even if one fails
        }
      }

      if (kDebugMode && products.isEmpty && productsData.isNotEmpty) {
        print(
          'fetchByCategory: Warning - ${productsData.length} products found but none could be converted for category "$normalizedCategory"',
        );
      }

      return products;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(
          'fetchByCategory: Error fetching products for category "${category.trim()}": $e',
        );
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Fetch product by ID from Supabase (implements ProductRepository.fetchById)
  @override
  Future<Product?> fetchById(String id) async {
    try {
      final response =
          await _supabase
              .from('products')
              .select('*')
              .eq('id', id)
              .maybeSingle();

      if (response == null) return null;

      return await _convertSupabaseToProduct(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchById: $e');
      }
      return null;
    }
  }

  /// Fetch product by ID from Supabase (alias for fetchById for backward compatibility)
  Future<Product?> fetchProductById(String productId) async =>
      fetchById(productId);

  /// Delete product from Supabase
  Future<void> deleteProduct(String productId) async {
    try {
      // 1. Try to HARD DELETE the product
      // This will cascade delete variants, measurements, wishlist items, cart items, ratings
      // But it will fail if the product is referenced in orders or purchase orders (RESTRICT)
      await _supabase.from('products').delete().eq('id', productId);

      if (kDebugMode) {
        print('Product HARD deleted successfully: $productId');
      }
    } catch (e) {
      // 2. If HARD DELETE fails, check if it's a foreign key constraint violation
      // Postgres error 23503 is foreign_key_violation
      // Error message usually contains "violates foreign key constraint"
      final isForeignKeyError =
          e.toString().contains('violates foreign key constraint') ||
          e.toString().contains('foreign key constraint violation') ||
          e.toString().contains('23503');

      if (isForeignKeyError) {
        if (kDebugMode) {
          print(
            'Hard delete failed due to foreign key constraints. Falling back to SOFT DELETE.',
          );
        }

        // Fallback to SOFT DELETE
        try {
          final updateResponse =
              await _supabase
                  .from('products')
                  .update({'is_active': false})
                  .eq('id', productId)
                  .select();

          // Verify the update succeeded
          if (updateResponse.isEmpty) {
            throw Exception(
              'Product not found or update failed during soft delete fallback. Product ID: $productId',
            );
          }

          // Verify is_active was actually set to false
          final updatedProduct = updateResponse.first;
          if (updatedProduct['is_active'] != false) {
            throw Exception(
              'Failed to deactivate product. Product may still be active.',
            );
          }

          if (kDebugMode) {
            print('Product SOFT deleted successfully: $productId');
          }
        } catch (softDeleteError) {
          if (kDebugMode) {
            print('Error in soft delete fallback: $softDeleteError');
          }
          rethrow;
        }
      } else {
        if (kDebugMode) {
          print('Error in deleteProduct: $e');
          print('Product ID: $productId');
        }
        rethrow;
      }
    }
  }

  /// Update featured flag and position for a single product.
  ///
  /// This keeps all logic in the repository so callers don't have to know
  /// about the underlying Supabase schema.
  Future<void> updateFeaturedStatus(
    String productId, {
    required bool isFeatured,
    required int featuredPosition,
  }) async {
    try {
      await _supabase
          .from('products')
          .update({
            'is_featured': isFeatured,
            'featured_position': featuredPosition,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateFeaturedStatus for $productId: $e');
      }
      rethrow;
    }
  }

  /// Toggle out of stock status for a product.
  ///
  /// This allows admins to quickly mark products as unavailable (seasonal/unavailable)
  /// without needing to update the entire product.
  Future<void> toggleOutOfStockStatus(
    String productId, {
    required bool isOutOfStock,
  }) async {
    try {
      final response =
          await _supabase
              .from('products')
              .update({
                'is_out_of_stock': isOutOfStock,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', productId)
              .select();

      if (response.isEmpty) {
        throw Exception(
          'Product not found or update failed. Product ID: $productId',
        );
      }

      if (kDebugMode) {
        print(
          'Successfully toggled out of stock status for $productId to $isOutOfStock',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in toggleOutOfStockStatus for $productId: $e');
        if (e.toString().contains('column') &&
            e.toString().contains('does not exist')) {
          print(
            'ERROR: The is_out_of_stock column does not exist in the database.',
          );
          print(
            'Please run the migration: supabase_migrations/051_add_is_out_of_stock_to_products.sql',
          );
        }
      }
      rethrow;
    }
  }

  /// Get count of out-of-stock items
  /// Counts products where is_out_of_stock = true
  /// Stock quantity is ignored as it's not used for availability
  Future<int> getOutOfStockItemsCount() async {
    try {
      final response = await _supabase
          .from('products')
          .select('id')
          .eq('is_active', true)
          .eq('is_out_of_stock', true);

      return response.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting out-of-stock items count: $e');
      }
      return 0;
    }
  }
}
