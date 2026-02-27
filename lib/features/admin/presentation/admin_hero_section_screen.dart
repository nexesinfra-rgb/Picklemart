import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/hero_image_controller.dart';
import '../data/hero_image_model.dart';
import '../data/hero_image_repository_provider.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/widgets/lazy_image.dart';
import '../../../../media_upload_widget.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';

class AdminHeroSectionScreen extends ConsumerStatefulWidget {
  const AdminHeroSectionScreen({super.key});

  @override
  ConsumerState<AdminHeroSectionScreen> createState() =>
      _AdminHeroSectionScreenState();
}

class _AdminHeroSectionScreenState
    extends ConsumerState<AdminHeroSectionScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(heroImageControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Hero Section',
        showBackButton: true,
        body: state.loading && state.heroImages.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.heroImages.isEmpty
                ? _buildErrorState(state.error!)
                : SingleChildScrollView(
                    padding: EdgeInsets.all(spacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Simple header section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hero Sections',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage hero sections displayed on the home screen',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: state.loading
                                  ? null
                                  : () => _showCreateDialog(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Hero Section'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing),
                        if (state.heroImages.isEmpty)
                          _buildEmptyState()
                        else
                          _buildHeroSectionsList(state.heroImages),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading hero sections',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(heroImageControllerProvider.notifier).loadHeroImages();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: Colors.cyan.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Hero Sections Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first hero section to display on the home screen. Add images, titles, and call-to-action buttons to engage your users.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Create Hero Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSectionsList(List<HeroImage> images) {
    // Sort by display order
    final sortedImages = List<HeroImage>.from(images)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Column(
      children: sortedImages.map((hero) {
        return _buildHeroSectionCard(hero, sortedImages);
      }).toList(),
    );
  }

  Widget _buildHeroSectionCard(HeroImage hero, List<HeroImage> allHeroes) {
    final currentIndex = allHeroes.indexWhere((h) => h.id == hero.id);
    final canMoveUp = currentIndex > 0;
    final canMoveDown = currentIndex < allHeroes.length - 1;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with better styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: LazyImage(
                    imageUrl: hero.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content - properly constrained
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badges row - wrapped to prevent overflow
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.numbers,
                              size: 12,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${hero.displayOrder + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: hero.isActive
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: hero.isActive
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hero.isActive ? Icons.check_circle : Icons.cancel,
                              size: 12,
                              color: hero.isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hero.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: hero.isActive
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  if (hero.title != null && hero.title!.trim().isNotEmpty) ...[
                    Text(
                      hero.title!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Subtitle
                  if (hero.subtitle != null) ...[
                    Text(
                      hero.subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  // CTA Text
                  if (hero.ctaText != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              hero.ctaText!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions - more compact and beautiful
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Order controls - compact buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canMoveUp ? () => _moveUp(hero) : null,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.arrow_upward,
                              size: 16,
                              color: canMoveUp
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.grey.shade300,
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canMoveDown ? () => _moveDown(hero) : null,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: canMoveDown
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Action buttons - compact
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: hero.isActive
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: hero.isActive ? Colors.orange : Colors.green,
                      onPressed: () => _toggleActive(hero),
                      tooltip: hero.isActive ? 'Deactivate' : 'Activate',
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.edit,
                      color: Colors.blue,
                      onPressed: () => _showEditDialog(context, hero),
                      tooltip: 'Edit',
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onPressed: () => _showDeleteConfirmation(context, hero),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  void _moveUp(HeroImage hero) async {
    final success = await ref
        .read(heroImageControllerProvider.notifier)
        .moveHeroImageUp(hero);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Moved up successfully' : 'Failed to move up',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _moveDown(HeroImage hero) async {
    final success = await ref
        .read(heroImageControllerProvider.notifier)
        .moveHeroImageDown(hero);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Moved down successfully' : 'Failed to move down',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _toggleActive(HeroImage hero) async {
    final success = await ref
        .read(heroImageControllerProvider.notifier)
        .toggleActiveStatus(hero);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Status updated successfully'
                : 'Failed to update status',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showCreateDialog(BuildContext context) {
    _showHeroSectionDialog(context, null);
  }

  void _showEditDialog(BuildContext context, HeroImage hero) {
    _showHeroSectionDialog(context, hero);
  }

  void _showHeroSectionDialog(BuildContext context, HeroImage? existingHero) {
    final titleController =
        TextEditingController(text: existingHero?.title ?? '');
    final subtitleController =
        TextEditingController(text: existingHero?.subtitle ?? '');
    final ctaTextController =
        TextEditingController(text: existingHero?.ctaText ?? '');
    final ctaLinkController =
        TextEditingController(text: existingHero?.ctaLink ?? '');
    final slackUrlController =
        TextEditingController(text: existingHero?.slackUrl ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    MediaUploadResult? selectedImage;
    String? imageUrl = existingHero?.imageUrl;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingHero == null ? 'Create Hero Section' : 'Edit Hero Section'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview (show existing image if available and no new image selected)
                    if (imageUrl != null && selectedImage == null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 150,
                          child: LazyImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            imageUrl = null;
                            selectedImage = null;
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Change Image'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // New image selected preview
                    if (selectedImage != null) ...[
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: selectedImage!.path.startsWith('http') || selectedImage!.path.startsWith('data:')
                              ? LazyImage(
                                  imageUrl: selectedImage!.path,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image, size: 48, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          selectedImage!.fileName,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Selected: ${selectedImage!.fileName}',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                selectedImage = null;
                                if (existingHero != null) {
                                  imageUrl = existingHero.imageUrl;
                                }
                              });
                            },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Remove'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Image upload widget (always show, but label changes based on state)
                    MediaUploadWidget(
                      label: existingHero != null && imageUrl != null && selectedImage == null
                          ? 'Replace Image'
                          : 'Upload Image',
                      hint: 'Select image from camera, gallery, or files',
                      allowImages: true,
                      allowPdfs: false,
                      maxImages: 1,
                      onMediaSelected: (result) {
                        setDialogState(() {
                          selectedImage = result;
                          imageUrl = null; // Clear existing image URL when new one is selected
                        });
                      },
                    ),

                    const SizedBox(height: 24),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title (optional)',
                        hintText: 'Enter hero section title (optional)',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle',
                        hintText: 'Enter subtitle text (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: ctaTextController,
                      decoration: const InputDecoration(
                        labelText: 'CTA Button Text',
                        hintText: 'e.g., Shop Now, Learn More (optional)',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: ctaLinkController,
                      decoration: const InputDecoration(
                        labelText: 'CTA URL',
                        hintText: 'Route name or URL (optional)',
                        border: OutlineInputBorder(),
                        helperText: 'For regular navigation routes or URLs',
                      ),
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: slackUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Slack URL',
                        hintText: 'slack:// or https://*.slack.com/* (optional)',
                        border: OutlineInputBorder(),
                        helperText: 'For Slack deep links or web URLs',
                      ),
                      enabled: !isSubmitting,
                    ),
                    if (isSubmitting) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      // Validate: need image or existing image
                      if (imageUrl == null && selectedImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select an image'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      try {
                        if (existingHero == null) {
                          // Create new - must have selected image
                          if (selectedImage == null) {
                            setDialogState(() {
                              isSubmitting = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select an image'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          await ref
                              .read(heroImageControllerProvider.notifier)
                              .createHeroImage(
                                image: selectedImage!,
                                title: titleController.text.trim().isEmpty
                                    ? null
                                    : titleController.text.trim(),
                                subtitle: subtitleController.text.trim().isEmpty
                                    ? null
                                    : subtitleController.text.trim(),
                                ctaText: ctaTextController.text.trim().isEmpty
                                    ? null
                                    : ctaTextController.text.trim(),
                                ctaLink: ctaLinkController.text.trim().isEmpty
                                    ? null
                                    : ctaLinkController.text.trim(),
                                slackUrl: slackUrlController.text.trim().isEmpty
                                    ? null
                                    : slackUrlController.text.trim(),
                              );
                        } else {
                          // Update existing - handle image update if new image selected
                          String finalImageUrl = existingHero.imageUrl;
                          
                          if (selectedImage != null) {
                            // Upload new image
                            final repo = ref.read(heroImageRepositoryProvider);
                            finalImageUrl = await repo.uploadHeroImage(selectedImage!);
                          }

                          final updated = existingHero.copyWith(
                            imageUrl: finalImageUrl,
                            title: titleController.text.trim().isEmpty
                                ? null
                                : titleController.text.trim(),
                            subtitle: subtitleController.text.trim().isEmpty
                                ? null
                                : subtitleController.text.trim(),
                            ctaText: ctaTextController.text.trim().isEmpty
                                ? null
                                : ctaTextController.text.trim(),
                            ctaLink: ctaLinkController.text.trim().isEmpty
                                ? null
                                : ctaLinkController.text.trim(),
                            slackUrl: slackUrlController.text.trim().isEmpty
                                ? null
                                : slackUrlController.text.trim(),
                          );

                          await ref
                              .read(heroImageControllerProvider.notifier)
                              .updateHeroImage(updated);
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                existingHero == null
                                    ? 'Hero section created successfully'
                                    : 'Hero section updated successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setDialogState(() {
                            isSubmitting = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: Text(existingHero == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, HeroImage hero) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Hero Section'),
        content: Text(
          'Are you sure you want to delete this hero section? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await ref
                  .read(heroImageControllerProvider.notifier)
                  .deleteHeroImage(hero.id);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Hero section deleted successfully'
                        : 'Failed to delete hero section',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
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
}

