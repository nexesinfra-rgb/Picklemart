import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/hero_image_controller.dart';
import '../../data/hero_image_model.dart';
import '../../../../core/widgets/lazy_image.dart';
import '../../../../media_upload_widget.dart';

/// Widget for managing hero images in admin panel
class HeroImageManagementWidget extends ConsumerStatefulWidget {
  const HeroImageManagementWidget({super.key});

  @override
  ConsumerState<HeroImageManagementWidget> createState() =>
      _HeroImageManagementWidgetState();
}

class _HeroImageManagementWidgetState
    extends ConsumerState<HeroImageManagementWidget> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(heroImageControllerProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hero Images',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                OutlinedButton.icon(
                  onPressed: state.loading
                      ? null
                      : () => _showCleanupDialog(context),
                  icon: const Icon(Icons.cleaning_services, size: 18),
                  label: const Text('Cleanup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.loading)
              const Center(child: CircularProgressIndicator())
            else if (state.error != null)
              _buildErrorState(state.error!)
            else if (state.heroImages.isEmpty)
              _buildEmptyState()
            else
              _buildHeroImagesList(state.heroImages),
            // Add Image button at the bottom
            if (!state.loading && state.error == null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: state.loading
                        ? null
                        : () => _showUploadDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading hero images',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(heroImageControllerProvider.notifier).loadHeroImages();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hero images yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add images to display in the home screen carousel',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImagesList(List<HeroImage> images) {
    // Calculate crossAxisCount based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : screenWidth < 1024 ? 3 : 4;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return _buildHeroImageGridItem(images[index]);
      },
    );
  }

  Widget _buildHeroImageGridItem(HeroImage image) {
    return GestureDetector(
      onLongPress: () => _showImageOptions(context, image),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LazyImage(
              imageUrl: image.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Status indicator (border)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image.isActive ? Colors.green : Colors.grey,
                width: 3,
              ),
            ),
          ),
          // Order badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${image.displayOrder}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Active/Inactive indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: image.isActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          // Tap overlay
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showImageOptions(context, image),
                borderRadius: BorderRadius.circular(12),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions(BuildContext context, HeroImage image) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
              ),
              child: LazyImage(
                imageUrl: image.imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            const Divider(),
            // Options
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, image);
              },
            ),
            ListTile(
              leading: Icon(
                image.isActive ? Icons.visibility_off : Icons.visibility,
              ),
              title: Text(image.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(heroImageControllerProvider.notifier)
                    .toggleActiveStatus(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, image);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upload Hero Image'),
        content: SizedBox(
          width: double.maxFinite,
          child: MediaUploadWidget(
            onMediaSelected: (_) {
              // Single image upload not used, but required by widget
            },
            onMultipleMediaSelected: (images) async {
              Navigator.pop(dialogContext);
              
              // Show loading indicator
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Uploading images...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              // Upload images
              final created = await ref
                  .read(heroImageControllerProvider.notifier)
                  .createMultipleHeroImages(images: images);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Successfully uploaded ${created.length} image(s)',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            allowPdfs: false,
            maxImages: 10,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, HeroImage image) {
    final titleController = TextEditingController(text: image.title ?? '');
    final subtitleController = TextEditingController(text: image.subtitle ?? '');
    final ctaTextController = TextEditingController(text: image.ctaText ?? '');
    final ctaLinkController = TextEditingController(text: image.ctaLink ?? '');
    final orderController = TextEditingController(
      text: image.displayOrder.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Hero Image'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'Enter hero title (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Subtitle',
                  hintText: 'Enter subtitle text (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctaTextController,
                decoration: const InputDecoration(
                  labelText: 'CTA Button Text',
                  hintText: 'e.g., Shop Now, Learn More (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctaLinkController,
                decoration: const InputDecoration(
                  labelText: 'CTA Link/Route',
                  hintText: 'e.g., catalog, products, or URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Display Order',
                  hintText: 'Order in carousel',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final order = int.tryParse(orderController.text) ?? image.displayOrder;
              
              final updated = image.copyWith(
                title: titleController.text.isEmpty
                    ? null
                    : titleController.text.trim(),
                subtitle: subtitleController.text.isEmpty
                    ? null
                    : subtitleController.text.trim(),
                ctaText: ctaTextController.text.isEmpty
                    ? null
                    : ctaTextController.text.trim(),
                ctaLink: ctaLinkController.text.isEmpty
                    ? null
                    : ctaLinkController.text.trim(),
                displayOrder: order,
              );

              final success = await ref
                  .read(heroImageControllerProvider.notifier)
                  .updateHeroImage(updated);

              if (context.mounted) {
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Image updated successfully'
                          : 'Failed to update image',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, HeroImage image) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Hero Image'),
        content: Text(
          'Are you sure you want to delete this hero image? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              final success = await ref
                  .read(heroImageControllerProvider.notifier)
                  .deleteHeroImage(image.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Image deleted successfully'
                          : 'Failed to delete image',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog(BuildContext context) async {
    // Show loading while checking for old images
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get old images
      final oldImages = await ref
          .read(heroImageControllerProvider.notifier)
          .getOldHeroImages(days: 30);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (oldImages.isEmpty) {
        // Show message that no old images found
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No images older than 1 month found'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      // Show confirmation dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cleanup Old Images'),
            content: Text(
              'Found ${oldImages.length} image(s) older than 1 month. Do you want to delete them? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  
                  // Show loading
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  try {
                    final deletedCount = await ref
                        .read(heroImageControllerProvider.notifier)
                        .cleanupOldHeroImages(days: 30);

                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Successfully deleted $deletedCount image(s)',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking old images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

