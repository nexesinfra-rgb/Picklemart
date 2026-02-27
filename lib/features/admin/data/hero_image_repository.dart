import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../media_upload_widget.dart';
import 'hero_image_model.dart';

/// Repository for managing hero images in Supabase
class HeroImageRepository {
  final SupabaseClient _supabase;

  HeroImageRepository(this._supabase);

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

  /// Upload hero image to Supabase Storage
  /// Returns public URL for the uploaded image
  Future<String> uploadHeroImage(MediaUploadResult image) async {
    try {
      final bucket = _supabase.storage.from('hero-images');

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'hero/${timestamp}_${image.fileName}';

      // Determine Content-Type based on file extension
      final contentType = _getContentTypeFromFileName(image.fileName);

      // Read file bytes based on platform
      Uint8List bytes;
      if (kIsWeb) {
        // On web, handle different path formats
        if (image.path.startsWith('data:')) {
          // Handle data URL (base64 encoded) - this is the standard format for web files
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
          // Try XFile as fallback (for blob URLs or other formats)
          try {
            final xFile = XFile(image.path);
            bytes = await xFile.readAsBytes();
          } catch (e) {
            throw Exception(
              'Unable to read image file on web. Please try using Gallery or Camera option instead. Error: $e',
            );
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
        print('Error uploading hero image: $e');
      }
      rethrow;
    }
  }

  /// Get all hero images (admin only - includes inactive)
  Future<List<HeroImage>> getAllHeroImages() async {
    try {
      final response = await _supabase
          .from('hero_images')
          .select()
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => HeroImage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching all hero images: $e');
      }
      rethrow;
    }
  }

  /// Get active hero images (public - for home screen)
  Future<List<HeroImage>> getActiveHeroImages() async {
    try {
      final response = await _supabase
          .from('hero_images')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => HeroImage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching active hero images: $e');
      }
      rethrow;
    }
  }

  /// Create a new hero image
  Future<HeroImage> createHeroImage({
    required String imageUrl,
    String? title,
    String? subtitle,
    String? ctaText,
    String? ctaLink,
    String? slackUrl,
    int? displayOrder,
  }) async {
    try {
      // Get current max display_order if not provided
      int order = displayOrder ?? 0;
      if (displayOrder == null) {
        final existing = await getAllHeroImages();
        if (existing.isNotEmpty) {
          order = existing.map((e) => e.displayOrder).reduce((a, b) => a > b ? a : b) + 1;
        }
      }

      final response = await _supabase
          .from('hero_images')
          .insert({
            'image_url': imageUrl,
            'title': title,
            'subtitle': subtitle,
            'cta_text': ctaText,
            'cta_link': ctaLink,
            'slack_url': slackUrl,
            'display_order': order,
            'is_active': true,
          })
          .select()
          .single();

      return HeroImage.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating hero image: $e');
      }
      rethrow;
    }
  }

  /// Update a hero image
  Future<HeroImage> updateHeroImage(HeroImage heroImage) async {
    try {
      final response = await _supabase
          .from('hero_images')
          .update({
            'image_url': heroImage.imageUrl,
            'title': heroImage.title,
            'subtitle': heroImage.subtitle,
            'cta_text': heroImage.ctaText,
            'cta_link': heroImage.ctaLink,
            'slack_url': heroImage.slackUrl,
            'display_order': heroImage.displayOrder,
            'is_active': heroImage.isActive,
          })
          .eq('id', heroImage.id)
          .select()
          .single();

      return HeroImage.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating hero image: $e');
      }
      rethrow;
    }
  }

  /// Delete a hero image
  Future<void> deleteHeroImage(String id) async {
    try {
      // Get the image URL first to delete from storage
      final response = await _supabase
          .from('hero_images')
          .select('image_url')
          .eq('id', id)
          .single();

      final imageUrl = (response)['image_url'] as String;

      // Delete from database
      await _supabase.from('hero_images').delete().eq('id', id);

      // Try to delete from storage (extract path from URL)
      try {
        if (imageUrl.contains('/storage/v1/object/public/hero-images/')) {
          final path = imageUrl.split('/storage/v1/object/public/hero-images/')[1];
          await _supabase.storage.from('hero-images').remove([path]);
        }
      } catch (e) {
        // Log but don't fail if storage deletion fails
        if (kDebugMode) {
          print('Error deleting hero image from storage: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting hero image: $e');
      }
      rethrow;
    }
  }

  /// Reorder hero images
  Future<void> reorderHeroImages(List<String> orderedIds) async {
    try {
      // Update display_order for each image
      for (int i = 0; i < orderedIds.length; i++) {
        await _supabase
            .from('hero_images')
            .update({'display_order': i})
            .eq('id', orderedIds[i]);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reordering hero images: $e');
      }
      rethrow;
    }
  }

  /// Update display order for a single hero image
  Future<void> updateDisplayOrder(String heroId, int newOrder) async {
    try {
      await _supabase
          .from('hero_images')
          .update({'display_order': newOrder})
          .eq('id', heroId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating display order: $e');
      }
      rethrow;
    }
  }

  /// Get hero images older than specified days
  Future<List<HeroImage>> getOldHeroImages({int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final response = await _supabase
          .from('hero_images')
          .select()
          .lt('created_at', cutoffDate.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => HeroImage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching old hero images: $e');
      }
      rethrow;
    }
  }

  /// Delete multiple hero images by IDs
  Future<void> deleteHeroImages(List<String> ids) async {
    try {
      if (ids.isEmpty) return;

      // Get image URLs first to delete from storage
      final response = await _supabase
          .from('hero_images')
          .select('id, image_url')
          .inFilter('id', ids);

      final images = (response as List).cast<Map<String, dynamic>>();

      // Delete from database - delete one by one to avoid issues
      for (final id in ids) {
        await _supabase.from('hero_images').delete().eq('id', id);
      }

      // Try to delete from storage
      for (final image in images) {
        try {
          final imageUrl = image['image_url'] as String;
          if (imageUrl.contains('/storage/v1/object/public/hero-images/')) {
            final path = imageUrl.split('/storage/v1/object/public/hero-images/')[1];
            await _supabase.storage.from('hero-images').remove([path]);
          }
        } catch (e) {
          // Log but don't fail if storage deletion fails
          if (kDebugMode) {
            print('Error deleting hero image from storage: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting hero images: $e');
      }
      rethrow;
    }
  }
}

