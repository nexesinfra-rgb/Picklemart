import 'package:supabase_flutter/supabase_flutter.dart';
import 'saved_order_template_repository.dart';
import 'saved_order_template_model.dart';
import 'order_model.dart';

class SavedOrderTemplateRepositorySupabase
    implements SavedOrderTemplateRepository {
  final SupabaseClient _supabase;

  SavedOrderTemplateRepositorySupabase(this._supabase);

  @override
  Future<String> saveTemplate({
    required String userId,
    required String templateName,
    required List<OrderItem> items,
  }) async {
    // Feature disabled: return a synthetic ID without persisting
    return 'disabled_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<List<SavedOrderTemplate>> getTemplates(String userId) async {
    // Feature disabled: always return empty list
    return [];
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    // Feature disabled: no-op
    return;
  }

  @override
  Future<void> updateTemplate({
    required String templateId,
    required String templateName,
    required List<OrderItem> items,
  }) async {
    // Feature disabled: no-op
    return;
  }

  @override
  Future<SavedOrderTemplate?> getTemplateById(String templateId) async {
    // Feature disabled: always return null
    return null;
  }
}
