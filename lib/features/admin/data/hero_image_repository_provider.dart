import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import 'hero_image_repository.dart';

/// Provider for HeroImageRepository instance
final heroImageRepositoryProvider = Provider<HeroImageRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return HeroImageRepository(supabaseClient);
});

