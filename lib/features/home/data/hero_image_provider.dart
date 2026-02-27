import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/data/hero_image_model.dart';
import '../../admin/data/hero_image_repository_provider.dart';

/// Provider for active hero images (for home screen display)
final heroImagesProvider = FutureProvider<List<HeroImage>>((ref) async {
  final repository = ref.watch(heroImageRepositoryProvider);
  
  try {
    final heroImages = await repository.getActiveHeroImages();
    // Return full HeroImage objects for carousel with title, subtitle, and CTA
    return heroImages;
  } catch (e) {
    // Return empty list on error (carousel will handle empty state)
    return [];
  }
});

