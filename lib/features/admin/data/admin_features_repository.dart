import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for managing admin features in the database
class AdminFeaturesRepository {
  final SupabaseClient _supabase;

  AdminFeaturesRepository(this._supabase);

  /// Get all features from database
  Future<Map<String, dynamic>> getAllFeatures() async {
    try {
      final response = await _supabase.from('admin_features').select();

      final features = <String, dynamic>{};
      for (final row in response) {
        final key = row['feature_key'] as String;
        final value = row['feature_value'];
        features[key] = value;
      }

      return features;
    } catch (e) {
      throw Exception('Failed to fetch admin features: $e');
    }
  }

  /// Update a feature value
  Future<void> updateFeature(String key, dynamic value) async {
    try {
      // First, try to update existing row
      final updateResponse =
          await _supabase
              .from('admin_features')
              .update({
                'feature_value': value,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('feature_key', key)
              .select();

      // If no rows were updated, insert a new row
      if (updateResponse.isEmpty) {
        await _supabase.from('admin_features').insert({
          'feature_key': key,
          'feature_value': value,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update feature $key: $e');
    }
  }

  /// Subscribe to real-time feature changes
  Stream<Map<String, dynamic>> subscribeToFeatures() {
    return _supabase.from('admin_features').stream(primaryKey: ['id']).map((
      data,
    ) {
      final features = <String, dynamic>{};
      for (final row in data) {
        final key = row['feature_key'] as String;
        final value = row['feature_value'];
        features[key] = value;
      }
      return features;
    });
  }

  /// Initialize default features - checks for missing features and inserts them
  Future<void> initializeDefaultFeatures() async {
    try {
      // Get all existing feature keys
      final existingResponse = await _supabase
          .from('admin_features')
          .select('feature_key');
      
      final existingKeys = <String>{};
      for (final row in existingResponse) {
        final key = row['feature_key'] as String?;
        if (key != null) {
          existingKeys.add(key);
        }
      }

      // Define all default features
      final defaultFeatures = [
        {
          'feature_key': 'infinity_scroll_enabled',
          'feature_value': true,
          'description':
              'Enable infinite scrolling for categories on home screen',
        },
        {
          'feature_key': 'infinity_scroll_products_enabled',
          'feature_value': false,
          'description':
              'Enable infinite scrolling for products throughout the app',
        },
        {
          'feature_key': 'dark_mode_enabled',
          'feature_value': false,
          'description': 'Enable dark theme for the application',
        },
        {
          'feature_key': 'notifications_enabled',
          'feature_value': true,
          'description': 'Enable push notifications for admin updates',
        },
        {
          'feature_key': 'analytics_enabled',
          'feature_value': true,
          'description': 'Enable analytics tracking and reporting',
        },
        {
          'feature_key': 'rates_enabled',
          'feature_value': true,
          'description': 'Enable product rating and review system',
        },
        {
          'feature_key': 'star_ratings_enabled',
          'feature_value': true,
          'description': 'Enable star ratings feature for products',
        },
        {
          'feature_key': 'chat_enabled',
          'feature_value': true,
          'description': 'Enable chat feature between users and admin',
        },
        {
          'feature_key': 'price_visibility_enabled',
          'feature_value': false,
          'description': 'Enable price visibility for users in product cards and all views',
        },
      ];

      // Filter out features that already exist
      final missingFeatures = defaultFeatures
          .where((feature) => !existingKeys.contains(feature['feature_key']))
          .toList();

      // Insert only missing features
      if (missingFeatures.isNotEmpty) {
        await _supabase.from('admin_features').insert(missingFeatures);
      }
    } catch (e) {
      // If initialization fails, it's okay - features might already exist
      // or there might be a permission issue
    }
  }
}
