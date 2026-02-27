import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/hero_image_model.dart';
import '../data/hero_image_repository.dart';
import '../data/hero_image_repository_provider.dart';
import '../../../media_upload_widget.dart';

/// State for hero image management
class HeroImageState {
  final bool loading;
  final String? error;
  final List<HeroImage> heroImages;

  const HeroImageState({
    this.loading = false,
    this.error,
    this.heroImages = const [],
  });

  HeroImageState copyWith({
    bool? loading,
    String? error,
    List<HeroImage>? heroImages,
  }) {
    return HeroImageState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      heroImages: heroImages ?? this.heroImages,
    );
  }
}

/// Controller for managing hero images
class HeroImageController extends StateNotifier<HeroImageState> {
  HeroImageController(this._ref) : super(const HeroImageState()) {
    loadHeroImages();
  }

  final Ref _ref;
  HeroImageRepository get _repository => _ref.read(heroImageRepositoryProvider);

  /// Load all hero images
  Future<void> loadHeroImages() async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }
    try {
      final images = await _repository.getAllHeroImages();
      if (mounted) {
        state = state.copyWith(heroImages: images, loading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  /// Upload and create a new hero image
  Future<HeroImage?> createHeroImage({
    required MediaUploadResult image,
    String? title,
    String? subtitle,
    String? ctaText,
    String? ctaLink,
    String? slackUrl,
    int? displayOrder,
  }) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }
    try {
      // Upload image to storage
      final imageUrl = await _repository.uploadHeroImage(image);

      // Create hero image record
      final heroImage = await _repository.createHeroImage(
        imageUrl: imageUrl,
        title: title,
        subtitle: subtitle,
        ctaText: ctaText,
        ctaLink: ctaLink,
        slackUrl: slackUrl,
        displayOrder: displayOrder,
      );

      // Reload images
      await loadHeroImages();

      return heroImage;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return null;
    }
  }

  /// Upload multiple hero images
  Future<List<HeroImage>> createMultipleHeroImages({
    required List<MediaUploadResult> images,
    String? titlePrefix,
  }) async {
    state = state.copyWith(loading: true, error: null);
    final List<HeroImage> createdImages = [];

    try {
      for (int i = 0; i < images.length; i++) {
        try {
          // Upload image to storage
          final imageUrl = await _repository.uploadHeroImage(images[i]);

          // Create hero image record
          final title =
              titlePrefix != null
                  ? '$titlePrefix ${i + 1}'
                  : images[i].fileName;

          final heroImage = await _repository.createHeroImage(
            imageUrl: imageUrl,
            title: title,
          );

          createdImages.add(heroImage);
        } catch (e) {
          // Continue with other images even if one fails
          if (kDebugMode) {
            print('Error creating hero image ${i + 1}: $e');
          }
        }
      }

      // Reload images
      await loadHeroImages();

      return createdImages;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return createdImages;
    }
  }

  /// Update a hero image
  Future<bool> updateHeroImage(HeroImage heroImage) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repository.updateHeroImage(heroImage);
      await loadHeroImages();
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  /// Delete a hero image
  Future<bool> deleteHeroImage(String id) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repository.deleteHeroImage(id);
      await loadHeroImages();
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  /// Reorder hero images
  Future<bool> reorderHeroImages(List<String> orderedIds) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repository.reorderHeroImages(orderedIds);
      await loadHeroImages();
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  /// Toggle active status of a hero image
  Future<bool> toggleActiveStatus(HeroImage heroImage) async {
    return await updateHeroImage(
      heroImage.copyWith(isActive: !heroImage.isActive),
    );
  }

  /// Get old hero images (older than 1 month)
  Future<List<HeroImage>> getOldHeroImages({int days = 30}) async {
    try {
      return await _repository.getOldHeroImages(days: days);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting old hero images: $e');
      }
      return [];
    }
  }

  /// Cleanup old hero images (delete images older than specified days)
  Future<int> cleanupOldHeroImages({int days = 30}) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }
    try {
      final oldImages = await _repository.getOldHeroImages(days: days);

      if (oldImages.isEmpty) {
        if (mounted) {
          state = state.copyWith(loading: false);
        }
        return 0;
      }

      final ids = oldImages.map((img) => img.id).toList();
      await _repository.deleteHeroImages(ids);

      // Reload images
      await loadHeroImages();

      return oldImages.length;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      rethrow;
    }
  }

  /// Update display order for a hero image (for up/down button reordering)
  Future<bool> updateDisplayOrder(String heroId, int newOrder) async {
    if (mounted) {
      state = state.copyWith(loading: true, error: null);
    }
    try {
      await _repository.updateDisplayOrder(heroId, newOrder);
      await loadHeroImages();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }

  /// Move hero image up in order
  Future<bool> moveHeroImageUp(HeroImage heroImage) async {
    try {
      final sortedImages = List<HeroImage>.from(state.heroImages)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      final currentIndex = sortedImages.indexWhere(
        (img) => img.id == heroImage.id,
      );
      if (currentIndex <= 0) return false; // Already at top

      final targetImage = sortedImages[currentIndex - 1];
      final currentOrder = heroImage.displayOrder;
      final targetOrder = targetImage.displayOrder;

      // Swap orders
      await _repository.updateDisplayOrder(heroImage.id, targetOrder);
      await _repository.updateDisplayOrder(targetImage.id, currentOrder);

      await loadHeroImages();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }

  /// Move hero image down in order
  Future<bool> moveHeroImageDown(HeroImage heroImage) async {
    try {
      final sortedImages = List<HeroImage>.from(state.heroImages)
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      final currentIndex = sortedImages.indexWhere(
        (img) => img.id == heroImage.id,
      );
      if (currentIndex < 0 || currentIndex >= sortedImages.length - 1) {
        return false; // Already at bottom
      }

      final targetImage = sortedImages[currentIndex + 1];
      final currentOrder = heroImage.displayOrder;
      final targetOrder = targetImage.displayOrder;

      // Swap orders
      await _repository.updateDisplayOrder(heroImage.id, targetOrder);
      await _repository.updateDisplayOrder(targetImage.id, currentOrder);

      await loadHeroImages();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
      return false;
    }
  }
}

/// Provider for HeroImageController
final heroImageControllerProvider =
    StateNotifierProvider<HeroImageController, HeroImageState>((ref) {
      return HeroImageController(ref);
    });
