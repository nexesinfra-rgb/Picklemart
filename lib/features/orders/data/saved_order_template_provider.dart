import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import 'saved_order_template_repository.dart';
import 'saved_order_template_repository_supabase.dart';
import 'saved_order_template_model.dart';
import '../../auth/application/auth_controller.dart';

/// Saved order template repository provider
final savedOrderTemplateRepositoryProvider =
    Provider<SavedOrderTemplateRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SavedOrderTemplateRepositorySupabase(supabaseClient);
});

/// Provider for getting all templates for the current user
final savedOrderTemplatesProvider = FutureProvider<List<SavedOrderTemplate>>(
  (ref) async {
    final authState = ref.watch(authControllerProvider);
    if (!authState.isAuthenticated || authState.userId == null) {
      return [];
    }

    final repository = ref.watch(savedOrderTemplateRepositoryProvider);
    return repository.getTemplates(authState.userId!);
  },
);

/// Provider for getting a template by ID
final savedOrderTemplateByIdProvider =
    FutureProvider.family<SavedOrderTemplate?, String>(
  (ref, templateId) async {
    final repository = ref.watch(savedOrderTemplateRepositoryProvider);
    return repository.getTemplateById(templateId);
  },
);

