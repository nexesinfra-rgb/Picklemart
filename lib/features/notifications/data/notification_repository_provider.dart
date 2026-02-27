import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import 'notification_repository.dart';

/// Notification repository provider
final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return NotificationRepositorySupabase(supabaseClient, ref);
});

