import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/manufacturer.dart';

class ManufacturerRepository {
  final SupabaseClient _supabase;

  ManufacturerRepository(this._supabase);

  /// Get all manufacturers from Supabase (optimized query)
  Future<List<Manufacturer>> getAllManufacturers() async {
    try {
      final response = await _supabase
          .from('manufacturers')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Manufacturer.fromSupabaseJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch manufacturers: $e');
    }
  }

  /// Get active manufacturers only (optimized with composite index)
  Future<List<Manufacturer>> getActiveManufacturers() async {
    try {
      final response = await _supabase
          .from('manufacturers')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Manufacturer.fromSupabaseJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active manufacturers: $e');
    }
  }

  /// Get manufacturer by ID
  Future<Manufacturer?> getManufacturerById(String id) async {
    try {
      final response = await _supabase
          .from('manufacturers')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Manufacturer.fromSupabaseJson(response);
    } catch (e) {
      throw Exception('Failed to fetch manufacturer: $e');
    }
  }

  /// Create a new manufacturer
  Future<Manufacturer> createManufacturer(Manufacturer manufacturer) async {
    try {
      final data = manufacturer.toSupabaseJson();
      // Remove id from data if it's empty (let database generate it)
      if (manufacturer.id.isEmpty) {
        data.remove('id');
      } else {
        data['id'] = manufacturer.id;
      }
      
      final response = await _supabase
          .from('manufacturers')
          .insert(data)
          .select()
          .single();

      return Manufacturer.fromSupabaseJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505' && e.message.contains('gst_number')) {
        throw Exception('A manufacturer with this GST number already exists.');
      }
      throw Exception('Failed to create manufacturer: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create manufacturer: $e');
    }
  }

  /// Update an existing manufacturer
  Future<Manufacturer> updateManufacturer(Manufacturer manufacturer) async {
    try {
      final data = manufacturer.toSupabaseJson();
      // Don't include id in update
      data.remove('id');
      
      final response = await _supabase
          .from('manufacturers')
          .update(data)
          .eq('id', manufacturer.id)
          .select()
          .single();

      return Manufacturer.fromSupabaseJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505' && e.message.contains('gst_number')) {
        throw Exception('A manufacturer with this GST number already exists.');
      }
      throw Exception('Failed to update manufacturer: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update manufacturer: $e');
    }
  }

  /// Delete a manufacturer
  Future<void> deleteManufacturer(String id) async {
    try {
      // Deleting the manufacturer will automatically delete related records 
      // (credit_transactions, purchase_orders, etc.) due to SQL CASCADE constraints.
      await _supabase.from('manufacturers').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete manufacturer: $e');
    }
  }

  /// Search manufacturers by name, business name, or GST number
  Future<List<Manufacturer>> searchManufacturers(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllManufacturers();
      }

      final searchTerm = query.toLowerCase().trim();
      
      // Use ILIKE for case-insensitive search on indexed columns
      final response = await _supabase
          .from('manufacturers')
          .select()
          .eq('is_deleted', false)
          .or('name.ilike.%$searchTerm%,business_name.ilike.%$searchTerm%,gst_number.ilike.%$searchTerm%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Manufacturer.fromSupabaseJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search manufacturers: $e');
    }
  }
}

