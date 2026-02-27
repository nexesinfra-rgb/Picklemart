import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';

/// Service to test Supabase connection
class SupabaseTestService {
  static Future<bool> testConnection() async {
    try {
      final supabase = Supabase.instance.client;

      // Simple test query - this will fail if not connected, but that's okay
      // We're just checking if the client is initialized
      await supabase.from('_test').select().limit(1);

      return true;
    } catch (e) {
      // If the table doesn't exist, that's fine - we just want to check connectivity
      // Any other error means connection failed
      if (e.toString().contains('relation') ||
          e.toString().contains('does not exist')) {
        return true; // Connection works, table just doesn't exist yet
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>> getConnectionInfo() async {
    final supabase = Supabase.instance.client;
    return {
      'url': Environment.supabaseUrl,
      'initialized': true,
      'hasSession': supabase.auth.currentSession != null,
    };
  }
}
