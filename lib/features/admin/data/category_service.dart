import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/category.dart';

class CategoryService {
  final SupabaseClient _supabase;

  CategoryService(this._supabase);

  /// Get all categories from Supabase
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('sort_order')
          .order('name');

      // Get product counts for each category
      final categories = <Category>[];
      for (final row in response) {
        final category = Category.fromSupabaseJson(row);
        // Count products with this category
        final productCount = await _getProductCountForCategory(category.name);
        categories.add(category.copyWith(productCount: productCount));
      }

      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get all categories from Supabase with pagination
  Future<List<Category>> getAllCategoriesPaginated({int page = 1, int limit = 50}) async {
    try {
      final startIndex = (page - 1) * limit;
      final response = await _supabase
          .from('categories')
          .select()
          .order('sort_order')
          .order('name')
          .range(startIndex, startIndex + limit - 1);

      // Get product counts for each category
      final categories = <Category>[];
      for (final row in response) {
        final category = Category.fromSupabaseJson(row);
        // Count products with this category
        final productCount = await _getProductCountForCategory(category.name);
        categories.add(category.copyWith(productCount: productCount));
      }

      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get product count for a category
  Future<int> _getProductCountForCategory(String categoryName) async {
    try {
      // Query products where categories array contains the category name
      final response = await _supabase.from('products').select('id').contains(
        'categories',
        [categoryName],
      );

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  /// Subscribe to real-time category changes
  Stream<List<Category>> subscribeToCategories() {
    final controller = StreamController<List<Category>>();

    // Initial fetch to ensure data is displayed even if realtime fails
    getAllCategories().then((categories) {
      if (!controller.isClosed) {
        controller.add(categories);
      }
    }).catchError((e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    });

    // Subscribe to real-time changes
    final subscription = _supabase.from('categories').stream(primaryKey: ['id']).listen(
      (data) async {
        try {
          // Get product counts for each category
          final categories = <Category>[];
          for (final row in data) {
            final category = Category.fromSupabaseJson(row);
            final productCount = await _getProductCountForCategory(category.name);
            categories.add(category.copyWith(productCount: productCount));
          }
          if (!controller.isClosed) {
            controller.add(categories);
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
          print('Supabase Realtime Error (Categories): $error');
        }
        // Only add error if it's not a channel error, or if we really want to show it.
        // For now, we suppress it to keep the UI stable with the initial fetch data.
      },
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

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
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Upload category image to Supabase Storage
  /// Returns public URL for the uploaded image
  Future<String?> _uploadCategoryImage(
    Uint8List imageBytes,
    String imageName,
    String categoryId,
  ) async {
    try {
      final bucket = _supabase.storage.from('category-images');
      
      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'categories/$categoryId/${timestamp}_$imageName';
      
      // Determine Content-Type based on file extension
      final contentType = _getContentTypeFromFileName(imageName);
      
      if (imageBytes.isEmpty) {
        throw Exception('Image bytes are empty');
      }
      
      // Upload to Supabase Storage
      // Use platform-specific approach: uploadBinary on web, File upload on mobile
      if (kIsWeb) {
        // On web, use uploadBinary with bytes directly
        await bucket.uploadBinary(
          fileName,
          imageBytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
      } else {
        // On mobile, write bytes to temp file and upload
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/${timestamp}_$imageName');
        await tempFile.writeAsBytes(imageBytes);
        
        try {
          await bucket.upload(
            fileName,
            tempFile,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
              cacheControl: '3600',
            ),
          );
        } finally {
          // Clean up temp file
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }
      
      // Get public URL
      final publicUrl = bucket.getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading category image: $e');
      }
      rethrow;
    }
  }

  /// Create a new category
  Future<Category> createCategory(Category category) async {
    try {
      // First, create the category to get the ID
      // We'll use a temporary ID for image upload if needed
      String? imageUrl;
      
      // Upload image if provided
      if (category.imageBytes != null && 
          category.imageName != null && 
          category.imageName!.isNotEmpty) {
        // Create category first with temporary data to get ID
        final tempData = category.toSupabaseJson();
        final tempResponse = await _supabase
            .from('categories')
            .insert(tempData)
            .select()
            .single();
        
        final createdCategory = Category.fromSupabaseJson(tempResponse);
        
        // Upload image using the created category ID
        try {
          imageUrl = await _uploadCategoryImage(
            category.imageBytes!,
            category.imageName!,
            createdCategory.id,
          );
          
          // Update category with image URL
          final updatedResponse = await _supabase
              .from('categories')
              .update({'image_url': imageUrl})
              .eq('id', createdCategory.id)
              .select()
              .single();
          
          return Category.fromSupabaseJson(updatedResponse);
        } catch (e) {
          // If image upload fails, delete the category and rethrow
          await _supabase.from('categories').delete().eq('id', createdCategory.id);
          throw Exception('Failed to upload category image: $e');
        }
      } else {
        // No image to upload, create category normally
        final data = category.toSupabaseJson();
        final response =
            await _supabase.from('categories').insert(data).select().single();

        return Category.fromSupabaseJson(response);
      }
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update an existing category
  Future<Category> updateCategory(Category category) async {
    try {
      String? imageUrl = category.imageUrl;
      
      // Upload new image if provided
      if (category.imageBytes != null && 
          category.imageName != null && 
          category.imageName!.isNotEmpty) {
        try {
          imageUrl = await _uploadCategoryImage(
            category.imageBytes!,
            category.imageName!,
            category.id,
          );
        } catch (e) {
          // If image upload fails, continue with existing imageUrl or null
          if (kDebugMode) {
            print('Warning: Failed to upload category image during update: $e');
          }
          // Don't throw - allow category update to proceed without image update
        }
      }
      
      // Update category data with image URL
      final data = category.toSupabaseJson();
      if (imageUrl != null) {
        data['image_url'] = imageUrl;
      }
      
      final response =
          await _supabase
              .from('categories')
              .update(data)
              .eq('id', category.id)
              .select()
              .single();

      return Category.fromSupabaseJson(response);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category
  /// Returns true if deletion was successful, false otherwise
  /// Also removes the category name from all products' categories arrays to prevent auto-recreation
  Future<bool> deleteCategory(String categoryId) async {
    String? categoryName;
    
    try {
      // Step 1: Get the category name before deletion
      final categoryResponse = await _supabase
          .from('categories')
          .select('name')
          .eq('id', categoryId)
          .maybeSingle();
      
      if (categoryResponse == null) {
        if (kDebugMode) {
          print('Warning: Category not found: $categoryId');
        }
        return false;
      }
      
      categoryName = categoryResponse['name'] as String?;
      if (categoryName == null || categoryName.isEmpty) {
        if (kDebugMode) {
          print('Warning: Category name is null or empty for category: $categoryId');
        }
        return false;
      }
      
      // Step 2: Delete the category from the database
      final response = await _supabase
          .from('categories')
          .delete()
          .eq('id', categoryId)
          .select();
      
      // Check if deletion was successful
      // Response should contain the deleted row(s) if successful
      if (kDebugMode) {
        print('Category deletion response: $response');
      }
      
      // If response is empty, the category might not exist or RLS blocked it
      if (response.isEmpty) {
        if (kDebugMode) {
          print('Warning: Category deletion returned empty response. Category may not exist or RLS policy blocked deletion.');
        }
        return false;
      }
      
      // Verify the deleted category matches the requested ID
      if (response.isNotEmpty) {
        final deletedCategory = response.first;
        if (deletedCategory['id'] == categoryId) {
          if (kDebugMode) {
            print('Category deleted successfully: $categoryId');
          }
          
          // Step 3: Remove the category name from all products' categories arrays
          try {
            await _removeCategoryFromProducts(categoryName);
          } catch (e) {
            // Log the error but don't fail the deletion
            // The category is already deleted, so we continue
            if (kDebugMode) {
              print('Warning: Failed to remove category from products: $e');
              print('Category "$categoryName" was deleted but may still exist in some products.');
            }
          }
          
          return true;
        }
      }
      
      return false;
    } on PostgrestException catch (e) {
      // Handle Supabase-specific errors
      String errorMessage = 'Failed to delete category';
      
      if (e.code == 'PGRST116' || e.message.contains('permission denied') || e.message.contains('policy')) {
        errorMessage = 'Permission denied. You may not have admin privileges to delete categories.';
      } else if (e.message.contains('foreign key') || e.message.contains('constraint')) {
        errorMessage = 'Cannot delete category. It may be in use by products or have child categories.';
      } else {
        errorMessage = 'Failed to delete category: ${e.message}';
      }
      
      if (kDebugMode) {
        print('Category deletion error: ${e.code} - ${e.message}');
        print('Error details: ${e.details}');
        print('Error hint: ${e.hint}');
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      // Handle other errors
      String errorMessage = 'Failed to delete category';
      
      if (e.toString().contains('permission') || e.toString().contains('policy')) {
        errorMessage = 'Permission denied. You may not have admin privileges to delete categories.';
      } else if (e.toString().contains('foreign key') || e.toString().contains('constraint')) {
        errorMessage = 'Cannot delete category. It may be in use by products or have child categories.';
      } else {
        errorMessage = 'Failed to delete category: ${e.toString()}';
      }
      
      if (kDebugMode) {
        print('Category deletion error: $e');
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Helper method to remove a category name from all products' categories arrays
  /// This prevents the auto-sync from recreating deleted categories
  Future<void> _removeCategoryFromProducts(String categoryName) async {
    try {
      // Find all products that contain this category in their categories array
      final productsResponse = await _supabase
          .from('products')
          .select('id, categories')
          .contains('categories', [categoryName]);
      
      if (productsResponse.isEmpty) {
        if (kDebugMode) {
          print('No products found with category "$categoryName"');
        }
        return;
      }
      
      if (kDebugMode) {
        print('Found ${productsResponse.length} product(s) with category "$categoryName"');
      }
      
      // Update each product to remove the category from its categories array
      int updatedCount = 0;
      int errorCount = 0;
      
      for (final product in productsResponse) {
        try {
          final productId = product['id'] as String?;
          if (productId == null || productId.isEmpty) {
            if (kDebugMode) {
              print('Warning: Product with null or empty ID found, skipping');
            }
            errorCount++;
            continue;
          }
          
          final categories = product['categories'] as List<dynamic>?;
          
          // Handle null or empty categories arrays
          if (categories == null || categories.isEmpty) {
            // Product has no categories, nothing to remove
            continue;
          }
          
          // Convert to List<String> and remove the category name
          // Also filter out empty strings to clean up the array
          final categoriesList = categories
              .map((e) => e.toString())
              .where((cat) => cat.isNotEmpty && cat != categoryName)
              .toList();
          
          // Only update if the list actually changed
          if (categoriesList.length == categories.length) {
            // Category wasn't in the list, skip update
            continue;
          }
          
          // Update the product with the new categories array
          await _supabase
              .from('products')
              .update({'categories': categoriesList})
              .eq('id', productId);
          
          updatedCount++;
        } on PostgrestException catch (e) {
          // Handle Supabase-specific errors for individual products
          errorCount++;
          if (kDebugMode) {
            print('Error updating product ${product['id']}: ${e.code} - ${e.message}');
          }
        } catch (e) {
          // Handle other errors for individual products
          errorCount++;
          if (kDebugMode) {
            print('Error updating product ${product['id']}: $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('Removed category "$categoryName" from $updatedCount product(s)');
        if (errorCount > 0) {
          print('Warning: Failed to update $errorCount product(s)');
        }
      }
    } on PostgrestException catch (e) {
      // Handle Supabase-specific errors
      if (kDebugMode) {
        print('Error querying products for category removal: ${e.code} - ${e.message}');
        print('Error details: ${e.details}');
      }
      // Re-throw to let caller handle it
      rethrow;
    } catch (e) {
      // Handle other errors
      if (kDebugMode) {
        print('Error in _removeCategoryFromProducts: $e');
      }
      // Re-throw to let caller handle it
      rethrow;
    }
  }

  /// Get category by ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final response =
          await _supabase
              .from('categories')
              .select()
              .eq('id', categoryId)
              .single();

      final category = Category.fromSupabaseJson(response);
      final productCount = await _getProductCountForCategory(category.name);
      return category.copyWith(productCount: productCount);
    } catch (e) {
      return null;
    }
  }

  /// Sync categories from products - auto-create categories that don't exist
  Future<void> syncCategoriesFromProducts() async {
    try {
      // Get all unique category names from products
      final productsResponse = await _supabase
          .from('products')
          .select('categories')
          .not('categories', 'is', null);

      final categoryNames = <String>{};
      for (final product in productsResponse) {
        final categories = product['categories'] as List<dynamic>?;
        if (categories != null) {
          for (final cat in categories) {
            if (cat is String && cat.isNotEmpty) {
              categoryNames.add(cat);
            }
          }
        }
      }

      // For each category name, check if it exists in categories table
      for (final categoryName in categoryNames) {
        try {
          // Check if category exists
          final existing =
              await _supabase
                  .from('categories')
                  .select('id')
                  .eq('name', categoryName)
                  .maybeSingle();

          // If doesn't exist, create it
          if (existing == null) {
            await _supabase.from('categories').insert({
              'name': categoryName,
              'description': 'Auto-created from products',
              'is_active': true,
              'sort_order': 0,
            });
          }
        } catch (e) {
          // Skip if there's an error (e.g., duplicate key)
          continue;
        }
      }
    } catch (e) {
      throw Exception('Failed to sync categories from products: $e');
    }
  }

  /// Subscribe to products changes - handles both auto-category creation and category refresh
  /// This is a single subscription that replaces the previous two separate subscriptions
  Stream<List<Category>> subscribeToProductsForCategoryRefresh() {
    return _supabase.from('products').stream(primaryKey: ['id']).asyncMap((
      data,
    ) async {
      // When products change:
      // 1. Sync categories (auto-create missing categories)
      await syncCategoriesFromProducts();
      // 2. Reload all categories with updated product counts
      return await getAllCategories();
    });
  }
}

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CategoryService(supabase);
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final service = ref.watch(categoryServiceProvider);

  // Use StreamController to properly merge both streams
  // Riverpod's StreamProvider will handle cleanup when the provider is disposed
  final controller = StreamController<List<Category>>.broadcast();
  
  // Track last emitted categories to prevent duplicate emissions
  List<Category>? lastEmittedCategories;
  Timer? debounceTimer;
  bool isSyncing = false;
  
  // Debounce function to prevent rapid reloads
  void debouncedEmit(List<Category> categories) {
    // Cancel any pending emission
    debounceTimer?.cancel();
    
    // Check if categories actually changed
    if (lastEmittedCategories != null) {
      final lastIds = lastEmittedCategories!.map((c) => c.id).toSet();
      final newIds = categories.map((c) => c.id).toSet();
      
      // If categories are the same, skip emission
      if (lastIds.length == newIds.length && 
          lastIds.every((id) => newIds.contains(id))) {
        // Check if any category data changed
        bool hasChanges = false;
        for (final category in categories) {
          final lastCategory = lastEmittedCategories!.firstWhere(
            (c) => c.id == category.id,
            orElse: () => category,
          );
          if (lastCategory.name != category.name ||
              lastCategory.isActive != category.isActive ||
              lastCategory.productCount != category.productCount) {
            hasChanges = true;
            break;
          }
        }
        if (!hasChanges) {
          return; // No changes, skip emission
        }
      }
    }
    
    // Debounce the emission to prevent rapid reloads
    debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!controller.isClosed) {
        lastEmittedCategories = categories;
        controller.add(categories);
      }
    });
  }
  
  // Initial sync of categories from products (fire and forget, only once)
  bool initialSyncDone = false;
  if (!initialSyncDone) {
    initialSyncDone = true;
    service.syncCategoriesFromProducts().catchError((e) {
      // Silently handle errors during initial sync
      if (kDebugMode) {
        print('Initial category sync error: $e');
      }
    });
  }

  // Listen to category changes (primary source)
  final categoryStream = service.subscribeToCategories();
  StreamSubscription? categorySubscription;
  
  categorySubscription = categoryStream.listen(
    (categories) {
      if (!controller.isClosed && !isSyncing) {
        debouncedEmit(categories);
      }
    },
    onError: (error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    },
  );
  
  // Listen to product changes with debouncing to prevent reload loops
  // Only sync if categories haven't been updated recently
  final productStream = service.subscribeToProductsForCategoryRefresh();
  StreamSubscription? productSubscription;
  DateTime? lastProductSync;
  
  productSubscription = productStream.listen(
    (categories) {
      // Prevent sync if it was done recently (within 2 seconds)
      final now = DateTime.now();
      if (lastProductSync != null && 
          now.difference(lastProductSync!).inSeconds < 2) {
        // Skip this sync to prevent loops
        return;
      }
      
      if (!controller.isClosed) {
        isSyncing = true;
        lastProductSync = now;
        
        // Use debounced emit for product-triggered updates
        debouncedEmit(categories);
        
        // Reset syncing flag after a delay
        Timer(const Duration(milliseconds: 500), () {
          isSyncing = false;
        });
      }
    },
    onError: (error) {
      isSyncing = false;
      // Log error but don't crash the stream if it's a realtime connection error
      if (kDebugMode) {
        print('Supabase Realtime Error (Categories Provider): $error');
      }
      // Suppress error to keep UI stable
    },
  );
  
  // Cleanup when stream is cancelled
  // Riverpod will cancel the stream when the provider is disposed
  controller.onCancel = () {
    categorySubscription?.cancel();
    productSubscription?.cancel();
    debounceTimer?.cancel();
  };
  
  // Return the merged stream
  return controller.stream;
});
