import 'saved_order_template_model.dart';
import 'order_model.dart';

abstract class SavedOrderTemplateRepository {
  Future<String> saveTemplate({
    required String userId,
    required String templateName,
    required List<OrderItem> items,
  });

  Future<List<SavedOrderTemplate>> getTemplates(String userId);

  Future<void> deleteTemplate(String templateId);

  Future<void> updateTemplate({
    required String templateId,
    required String templateName,
    required List<OrderItem> items,
  });

  Future<SavedOrderTemplate?> getTemplateById(String templateId);
}

