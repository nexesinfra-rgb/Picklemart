import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'bill_model.dart';
import '../../../media_upload_widget.dart';

/// Repository for managing bills and bill templates in Supabase
class BillRepositorySupabase {
  final SupabaseClient _supabase;

  BillRepositorySupabase(this._supabase);

  /// Generate a unique bill number
  /// If orderNumber is provided, format: Bill_ORD50EE
  /// Otherwise, format: Bill_MANXXXX (where XXXX is a unique code for manual bills)
  String _generateBillNumber(BillType billType, {String? orderNumber}) {
    if (orderNumber != null && orderNumber.isNotEmpty) {
      // Use format: Bill_ORD50EE (for order-based bills)
      return 'Bill_$orderNumber';
    }
    // For bills without orders (manual bills), generate a unique identifier
    // Format: Bill_MANXXXX (where XXXX is a unique code)
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    // Use last 4 characters of timestamp converted to hex, uppercase
    final uniqueCode = timestamp.toRadixString(16).toUpperCase();
    final code = uniqueCode.length >= 4 
        ? uniqueCode.substring(uniqueCode.length - 4)
        : uniqueCode.padLeft(4, '0');
    return 'Bill_MAN$code';
  }

  /// Create a new bill
  Future<Bill> createBill({
    required BillType billType,
    required String userId,
    required BillData billData,
    String? orderId,
    String? productId,
    String? pdfUrl,
    String? orderNumber,
  }) async {
    try {
      // If orderId is provided, fetch order number if not already provided
      String? finalOrderNumber = orderNumber;
      if (orderId != null && finalOrderNumber == null) {
        try {
          final orderResponse = await _supabase
              .from('orders')
              .select('order_number')
              .eq('id', orderId)
              .maybeSingle();
          if (orderResponse != null) {
            finalOrderNumber = orderResponse['order_number'] as String?;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Could not fetch order number: $e');
          }
        }
      }
      
      final billNumber = _generateBillNumber(billType, orderNumber: finalOrderNumber);

      final billDataMap = {
        'bill_number': billNumber,
        'bill_type': billType.name,
        'user_id': userId,
        'bill_data': billData.toJson(),
        if (orderId != null) 'order_id': orderId,
        if (productId != null) 'product_id': productId,
        if (pdfUrl != null) 'pdf_url': pdfUrl,
      };

      final response = await _supabase
          .from('bills')
          .insert(billDataMap)
          .select()
          .single();

      return Bill.fromSupabaseRow(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating bill: $e');
      }
      throw Exception('Failed to create bill: $e');
    }
  }

  /// Get all bills with optional filters
  Future<List<Bill>> getBills({
    BillType? billType,
    String? orderId,
    String? userId,
    int? limit,
  }) async {
    try {
      var query = _supabase.from('bills').select('*');

      if (billType != null) {
        query = query.eq('bill_type', billType.name);
      }

      if (orderId != null) {
        query = query.eq('order_id', orderId);
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      // Order by created_at descending, with nulls last
      final orderedQuery = query.order('created_at', ascending: false);

      final response = limit != null
          ? await orderedQuery.limit(limit)
          : await orderedQuery;

      return (response as List)
          .map((row) => Bill.fromSupabaseRow(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      // Handle PostgrestException specifically for better error messages
      String errorMessage = 'Failed to fetch bills';
      
      if (kDebugMode) {
        print('PostgrestException in getBills:');
        print('  Code: ${e.code}');
        print('  Message: ${e.message}');
        print('  Details: ${e.details}');
        print('  Hint: ${e.hint}');
      }

      // Handle specific error codes
      if (e.code == 'PGRST116' || (e.message.contains('relation') && e.message.contains('does not exist'))) {
        errorMessage = 'Bills table does not exist. Please run the migration: supabase_migrations/035_create_bills_table.sql';
      } else if (e.code == '42501' || e.message.toLowerCase().contains('permission denied')) {
        errorMessage = 'Permission denied. Please check RLS policies for the bills table. Admin role may be required.';
      } else if (e.code == 'PGRST301' || e.message.contains('JWT')) {
        errorMessage = 'Authentication error. Please ensure you are logged in as an admin.';
      } else {
        errorMessage = 'Database error: ${e.message}';
        if (e.code != null) {
          errorMessage += ' (code: ${e.code})';
        }
      }
      
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      // Handle any other errors (including ClientException, network errors, etc.)
      String errorMessage = 'Failed to fetch bills';
      final errorString = e.toString().toLowerCase();
      
      if (kDebugMode) {
        print('Error in getBills (type: ${e.runtimeType}):');
        print('  Error: $e');
        print('  Stack trace: $stackTrace');
      }

      // Check for network/connection errors
      if (errorString.contains('failed to fetch') || 
          errorString.contains('clientexception') ||
          errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('socket')) {
        errorMessage = 'Network error: Unable to connect to the server. Please check your internet connection and try again.';
      } 
      // Check for RLS/permission errors
      else if (errorString.contains('permission denied') || 
               errorString.contains('row-level security') ||
               errorString.contains('policy')) {
        errorMessage = 'Permission denied. Please check RLS policies for the bills table. Admin role may be required.';
      }
      // Check for table not found errors
      else if (errorString.contains('does not exist') || 
               errorString.contains('relation') ||
               errorString.contains('table')) {
        errorMessage = 'Bills table does not exist. Please run the migration: supabase_migrations/035_create_bills_table.sql';
      }
      // Generic error
      else {
        errorMessage = 'Failed to fetch bills: $e';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Get a bill by ID
  Future<Bill?> getBillById(String billId) async {
    try {
      final response = await _supabase
          .from('bills')
          .select('*')
          .eq('id', billId)
          .single();

      return Bill.fromSupabaseRow(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching bill: $e');
      }
      return null;
    }
  }

  /// Get unpaid balance for a user (old due from previous bills)
  /// This calculates the sum of all unpaid balances from previous bills
  Future<double> getUnpaidBalanceForUser(String userId) async {
    try {
      // Get all bills for this user
      final bills = await getBills(userId: userId);
      
      // Calculate total unpaid balance
      double totalUnpaid = 0.0;
      
      for (final bill in bills) {
        final balanceDue = bill.billData.balanceDue;
        if (balanceDue > 0) {
          totalUnpaid += balanceDue;
        }
      }
      
      return totalUnpaid;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating unpaid balance: $e');
      }
      // Return 0 if there's an error to avoid blocking bill generation
      return 0.0;
    }
  }

  /// Update bill data (for editing shipping, old due, received amount)
  Future<Bill> updateBillData(String billId, BillData newBillData) async {
    try {
      final response = await _supabase
          .from('bills')
          .update({'bill_data': newBillData.toJson()})
          .eq('id', billId)
          .select()
          .single();

      return Bill.fromSupabaseRow(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating bill data: $e');
      }
      throw Exception('Failed to update bill data: $e');
    }
  }

  /// Delete a bill
  Future<void> deleteBill(String billId) async {
    try {
      await _supabase.from('bills').delete().eq('id', billId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting bill: $e');
      }
      throw Exception('Failed to delete bill: $e');
    }
  }

  /// Update bill PDF URL
  Future<void> updateBillPdfUrl(String billId, String pdfUrl) async {
    try {
      await _supabase
          .from('bills')
          .update({'pdf_url': pdfUrl})
          .eq('id', billId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating bill PDF URL: $e');
      }
      throw Exception('Failed to update bill PDF URL: $e');
    }
  }

  /// Upload bill template image
  Future<String> uploadBillTemplate({
    required BillType templateType,
    required String templateName,
    required MediaUploadResult image,
  }) async {
    try {
      final bucket = _supabase.storage.from('bill-templates');

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${templateType.name}/${timestamp}_${image.fileName}';

      // Determine content type
      final contentType = image.fileName.toLowerCase().endsWith('.png')
          ? 'image/png'
          : image.fileName.toLowerCase().endsWith('.gif')
              ? 'image/gif'
              : image.fileName.toLowerCase().endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg';

      // Read file bytes
      Uint8List bytes;
      if (kIsWeb) {
        final xFile = XFile(image.path);
        bytes = await xFile.readAsBytes();
      } else {
        final file = File(image.path);
        if (!await file.exists()) {
          throw Exception('File not found: ${image.path}');
        }
        bytes = await file.readAsBytes();
      }

      if (bytes.isEmpty) {
        throw Exception('Image bytes are empty');
      }

      // Upload to Supabase Storage
      if (kIsWeb) {
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
        final file = File(image.path);
        await bucket.upload(
          fileName,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
      }

      // Get public URL
      final publicUrl = bucket.getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading bill template: $e');
      }
      throw Exception('Failed to upload bill template: $e');
    }
  }

  /// Create or update bill template
  Future<BillTemplate> createBillTemplate({
    required BillType templateType,
    required String templateName,
    required String imageUrl,
    bool isActive = true,
  }) async {
    try {
      // Deactivate other templates of the same type if this one is active
      if (isActive) {
        await _supabase
            .from('bill_templates')
            .update({'is_active': false})
            .eq('template_type', templateType.name)
            .eq('is_active', true);
      }

      final templateData = {
        'template_type': templateType.name,
        'template_name': templateName,
        'image_url': imageUrl,
        'is_active': isActive,
      };

      final response = await _supabase
          .from('bill_templates')
          .insert(templateData)
          .select()
          .single();

      return BillTemplate.fromSupabaseRow(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating bill template: $e');
      }
      throw Exception('Failed to create bill template: $e');
    }
  }

  /// Get bill templates
  Future<List<BillTemplate>> getBillTemplates({
    BillType? templateType,
    bool? isActive,
  }) async {
    try {
      var query = _supabase.from('bill_templates').select('*');

      if (templateType != null) {
        query = query.eq('template_type', templateType.name);
      }

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final orderedQuery = query.order('created_at', ascending: false);

      final response = await orderedQuery;

      return (response as List)
          .map((row) => BillTemplate.fromSupabaseRow(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching bill templates: $e');
      }
      throw Exception('Failed to fetch bill templates: $e');
    }
  }

  /// Get active bill template for a type
  Future<BillTemplate?> getActiveBillTemplate(BillType templateType) async {
    try {
      final templates = await getBillTemplates(
        templateType: templateType,
        isActive: true,
      );
      return templates.isNotEmpty ? templates.first : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching active bill template: $e');
      }
      return null;
    }
  }

  /// Set template as active (deactivates others of same type)
  Future<void> setActiveTemplate(String templateId) async {
    try {
      // Get template to find its type
      final templateResponse = await _supabase
          .from('bill_templates')
          .select('template_type')
          .eq('id', templateId)
          .single();

      final templateType = templateResponse['template_type'] as String;

      // Deactivate all templates of this type
      await _supabase
          .from('bill_templates')
          .update({'is_active': false})
          .eq('template_type', templateType);

      // Activate this template
      await _supabase
          .from('bill_templates')
          .update({'is_active': true})
          .eq('id', templateId);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting active template: $e');
      }
      throw Exception('Failed to set active template: $e');
    }
  }

  /// Delete bill template
  Future<void> deleteBillTemplate(String templateId) async {
    try {
      await _supabase.from('bill_templates').delete().eq('id', templateId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting bill template: $e');
      }
      throw Exception('Failed to delete bill template: $e');
    }
  }

  /// Get manufacturer details by ID
  Future<Map<String, dynamic>?> getManufacturerById(String manufacturerId) async {
    try {
      // Explicitly select all required fields to ensure they are fetched
      final response = await _supabase
          .from('manufacturers')
          .select('id, name, gst_number, business_name, business_address, city, state, pincode, email, phone, is_active, created_at, updated_at')
          .eq('id', manufacturerId)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) {
          print('Manufacturer not found with ID: $manufacturerId');
        }
        return null;
      }

      final manufacturerData = response;
      
      // Validate required fields
      final requiredFields = ['id', 'name', 'gst_number', 'business_name', 'business_address', 'city', 'state', 'pincode'];
      final missingFields = <String>[];
      
      for (final field in requiredFields) {
        if (manufacturerData[field] == null || manufacturerData[field].toString().isEmpty) {
          missingFields.add(field);
        }
      }
      
      if (missingFields.isNotEmpty) {
        if (kDebugMode) {
          print('Manufacturer data missing required fields: ${missingFields.join(", ")}');
        }
        // Still return the data but log the issue
      }
      
      if (kDebugMode) {
        print('Manufacturer fetched successfully: ${manufacturerData['business_name']} (ID: ${manufacturerData['id']})');
      }
      
      return manufacturerData;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching manufacturer: $e');
        print('Manufacturer ID: $manufacturerId');
      }
      return null;
    }
  }

  /// Get user profile details by ID
  Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user profile: $e');
      }
      return null;
    }
  }

  /// Get product with cost price by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, product_variants(*)')
          .eq('id', productId)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching product: $e');
      }
      return null;
    }
  }

  /// Get order items with product cost prices
  Future<List<Map<String, dynamic>>> getOrderItemsWithCostPrices(String orderId) async {
    try {
      // First get order items
      final orderItemsResponse = await _supabase
          .from('order_items')
          .select('*')
          .eq('order_id', orderId);

      final orderItems = List<Map<String, dynamic>>.from(orderItemsResponse);
      final result = <Map<String, dynamic>>[];

      // For each order item, fetch product and variant details
      for (final item in orderItems) {
        final productId = item['product_id'] as String?;
        final variantId = item['variant_id'] as String?;

        Map<String, dynamic>? productData;
        List<Map<String, dynamic>>? variantData;

        if (productId != null) {
          try {
            final productResponse = await _supabase
                .from('products')
                .select('id, name, cost_price, price, categories')
                .eq('id', productId)
                .maybeSingle();
            productData = productResponse;
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching product $productId: $e');
            }
          }
        }

        if (variantId != null) {
          try {
            final variantResponse = await _supabase
                .from('product_variants')
                .select('id, cost_price, price')
                .eq('id', variantId)
                .maybeSingle();
            variantData = variantResponse != null ? [variantResponse] : null;
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching variant $variantId: $e');
            }
          }
        }

        result.add({
          ...item,
          'products': productData,
          'product_variants': variantData,
        });
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching order items with cost prices: $e');
      }
      return [];
    }
  }

  /// Upload PDF to storage
  Future<String> uploadBillPdf(Uint8List pdfBytes, String billNumber) async {
    try {
      final bucket = _supabase.storage.from('bill-pdfs');
      final fileName = 'bills/$billNumber.pdf';

      if (kIsWeb) {
        await bucket.uploadBinary(
          fileName,
          pdfBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'application/pdf',
            cacheControl: '3600',
          ),
        );
      } else {
        // For mobile, we need to create a temporary file
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File('${tempDir.path}/$billNumber.pdf');
        await tempFile.writeAsBytes(pdfBytes);

        await bucket.upload(
          fileName,
          tempFile,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'application/pdf',
          ),
        );

        // Clean up temp file
        await tempFile.delete();
        await tempDir.delete();
      }

      // Get public URL
      final publicUrl = bucket.getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading bill PDF: $e');
      }
      throw Exception('Failed to upload bill PDF: $e');
    }
  }

  /// Get categories for a list of products
  Future<Map<String, String>> getProductsCategories(List<String> productIds) async {
    if (productIds.isEmpty) return {};
    try {
      final response = await _supabase
          .from('products')
          .select('id, categories')
          .inFilter('id', productIds);

      final result = <String, String>{};
      final data = List<Map<String, dynamic>>.from(response);
      
      for (final item in data) {
        final id = item['id'] as String;
        final categoriesValue = item['categories'];
        String? category;

        // Handle different possible types for categories
        if (categoriesValue is List) {
          if (categoriesValue.isNotEmpty) {
            final firstCategory = categoriesValue.first;
            if (firstCategory is String) {
              category = firstCategory;
            } else if (firstCategory is Map) {
              category = (firstCategory['name'] ??
                      firstCategory['id'] ??
                      firstCategory.toString())
                  as String?;
            } else {
              category = firstCategory.toString();
            }
          }
        } else if (categoriesValue is String) {
          category = categoriesValue;
        } else if (categoriesValue is Map) {
           category = (categoriesValue['name'] ??
                      categoriesValue['id'] ??
                      categoriesValue.toString())
                  as String?;
        }

        if (category != null) {
          result[id] = category;
        }
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching categories: $e');
      }
      return {};
    }
  }
}

