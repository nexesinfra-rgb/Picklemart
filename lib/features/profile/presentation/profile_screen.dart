import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../application/profile_controller.dart';
import '../data/profile_repository.dart';
import '../data/user_repository.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/navigation/navigation_helper.dart';
import '../../admin/data/admin_features.dart';
import '../../../core/constants/ui_constants.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final userAsync = ref.watch(currentUserProvider);

    // Load profile if not already loaded
    if (profileState.profile == null && !profileState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileControllerProvider.notifier).loadCurrentProfile();
      });
    }

    final width = MediaQuery.of(context).size.width;
    final sectionSpacing = Responsive.getSectionSpacing(width);
    final cardPadding = Responsive.getCardPadding(width);

    return SafeScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back_outline),
          onPressed:
              () => NavigationHelper.handleBackNavigation(context, ref: ref),
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed('profile-settings'),
            icon: const Icon(Ionicons.settings_outline),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: userAsync.when(
        data:
            (user) => _buildProfileContent(
              context,
              ref,
              user,
              profileState,
              authState,
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Ionicons.warning_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text('Error loading profile: $error'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.refresh(currentUserProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
    ProfileState state,
    AuthState authState,
  ) {
    final width = MediaQuery.of(context).size.width;
    final sectionSpacing = Responsive.getSectionSpacing(width);
    final cardPadding = Responsive.getCardPadding(width);
    // Slightly smaller padding for screen edges so content is closer to borders
    final edgePadding = cardPadding * kScreenEdgePaddingFactor;

    // Get name and mobile from ProfileController (source of truth), with fallback to authState and user
    final displayName = state.profile?.name ?? authState.name ?? user.name;
    final displayMobile =
        state.profile?.displayMobile ??
        state.profile?.mobile ??
        authState.displayMobile ??
        authState.mobile ??
        user.phone;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient Header with Profile Info
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: edgePadding,
              vertical: cardPadding,
            ),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildProfileAvatar(state.profile?.avatarUrl),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap:
                                () => _showEditProfileImageDialog(
                                  context,
                                  ref,
                                  state.profile?.avatarUrl,
                                ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Ionicons.camera_outline,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: cardPadding * 0.8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (displayMobile != null) ...[
                            SizedBox(height: cardPadding * 0.2),
                            Row(
                              children: [
                                Icon(
                                  Ionicons.call_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                SizedBox(width: cardPadding * 0.3),
                                Expanded(
                                  child: Text(
                                    displayMobile,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pushNamed('profile-edit'),
                      icon: const Icon(Ionicons.create_outline),
                      tooltip: 'Edit Profile',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),

          // Quick Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: edgePadding),
            child: _buildSectionHeader(
              context,
              'Quick Actions',
              icon: Ionicons.flash_outline,
            ),
          ),
          SizedBox(height: cardPadding * 0.75),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: edgePadding),
            child: Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildActionTile(
                    context,
                    icon: Ionicons.person_outline,
                    title: 'Personal Details',
                    subtitle: 'View and edit your profile information',
                    onTap: () => context.pushNamed('profile-edit'),
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    context,
                    icon: Ionicons.location_outline,
                    title: 'Addresses',
                    subtitle: 'Manage your delivery addresses',
                    onTap: () => context.pushNamed('profile-addresses'),
                  ),
                  // _buildDivider(),
                  // _buildActionTile(
                  //   context,
                  //   icon: Ionicons.receipt_outline,
                  //   title: 'GST Details',
                  //   subtitle: 'Manage your GST information',
                  //   onTap: () => context.pushNamed('profile-gst'),
                  // ),
                  _buildDivider(),
                  _buildActionTile(
                    context,
                    icon: Ionicons.document_text_outline,
                    title: 'Order History',
                    subtitle: 'View your past orders',
                    onTap: () => context.goNamed('orders'),
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    context,
                    icon: Ionicons.heart_outline,
                    title: 'Purchase Later',
                    subtitle: 'View products you want to purchase later',
                    onTap: () => context.pushNamed('profile-wishlist'),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final features = ref.watch(adminFeaturesProvider);
                      // chatEnabled is safely parsed in fromJson with default value
                      if (!features.chatEnabled) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _buildDivider(),
                          _buildActionTile(
                            context,
                            icon: Ionicons.chatbubbles_outline,
                            title: 'Chat with Admin',
                            subtitle: 'Get help and support from our team',
                            onTap: () {
                              try {
                                // Try using the path directly first
                                context.push('/chat');
                              } catch (e) {
                                // Fallback to named route
                                try {
                                  context.pushNamed('chat');
                                } catch (e2) {
                                  // If both fail, show error
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Unable to open chat: $e2'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),

          // Account Settings
          Padding(
            padding: EdgeInsets.symmetric(horizontal: edgePadding),
            child: _buildSectionHeader(
              context,
              'Account',
              icon: Ionicons.settings_outline,
            ),
          ),
          SizedBox(height: cardPadding * 0.75),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: edgePadding),
            child: Card(
              elevation: 2,
              child: Column(
                children: [
                  _buildActionTile(
                    context,
                    icon: Ionicons.settings_outline,
                    title: 'Settings',
                    subtitle: 'App preferences and account settings',
                    onTap: () => context.pushNamed('profile-settings'),
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    context,
                    icon: Ionicons.help_circle_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    onTap: () => context.pushNamed('profile-help-support'),
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    context,
                    icon: Ionicons.log_out_outline,
                    title: 'Sign Out',
                    subtitle: 'Signed in as ${authState.email ?? 'Unknown'}',
                    onTap: () => _showSignOutDialog(context, ref),
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    showTrailing: false,
                  ),
                  _buildDivider(),
                  _buildActionTile(
                    context,
                    icon: Ionicons.trash_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and all data',
                    onTap: () => _showDeleteAccountDialog(context, ref),
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    showTrailing: false,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Data'),
            content: const Text(
              'Are you sure you want to delete all your store, customer, and manufacturer details? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  context.pop(); // Close dialog
                  try {
                    // Using deleteAccount from AuthController to ensure proper cleanup and logout
                    await ref
                        .read(authControllerProvider.notifier)
                        .deleteAccount();
                    // Navigation is handled by the auth state listener in the app router
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete data: $e')),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showTrailing = true,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal:
            Responsive.getCardPadding(MediaQuery.of(context).size.width) * 0.75,
        vertical: 8,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Theme.of(context).colorScheme.primary)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing:
          showTrailing
              ? Icon(
                Ionicons.chevron_forward,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
              )
              : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 60);
  }

  Widget _buildProfileAvatar(String? avatarUrl) {
    return Builder(
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final avatarRadius = width < 600 ? 40.0 : (width < 1024 ? 45.0 : 50.0);
        final iconSize = avatarRadius * 2 * 0.6;

        if (avatarUrl == null || avatarUrl.isEmpty) {
          return CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.grey.shade200,
            child: Icon(
              Ionicons.person,
              size: iconSize,
              color: Colors.grey.shade600,
            ),
          );
        }

        // Ensure URL is properly formatted
        final cleanUrl = avatarUrl.trim();
        if (!cleanUrl.startsWith('http://') &&
            !cleanUrl.startsWith('https://')) {
          // Invalid URL, show default avatar
          return CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.grey.shade200,
            child: Icon(
              Ionicons.person,
              size: iconSize,
              color: Colors.grey.shade600,
            ),
          );
        }

        return Container(
          width: avatarRadius * 2,
          height: avatarRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              cleanUrl,
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // Log error for debugging
                debugPrint('Error loading profile image: $error');
                debugPrint('URL: $cleanUrl');
                return CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(
                    Ionicons.person,
                    size: iconSize,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileImageDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentAvatarUrl,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change Profile Picture',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageOption(
                        context,
                        icon: Ionicons.camera_outline,
                        title: 'Camera',
                        subtitle: 'Take a photo',
                        onTap: () {
                          Navigator.of(context).pop();
                          _pickAndUploadImage(context, ref, ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageOption(
                        context,
                        icon: Ionicons.images_outline,
                        title: 'Gallery',
                        subtitle: 'Choose from gallery',
                        onTap: () {
                          Navigator.of(context).pop();
                          _pickAndUploadImage(
                            context,
                            ref,
                            ImageSource.gallery,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (currentAvatarUrl != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _removeProfileImage(context, ref);
                      },
                      icon: const Icon(
                        Ionicons.trash_outline,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Remove Photo',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildImageOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final imagePicker = ImagePicker();
      final XFile? imageFile = await imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (imageFile == null) {
        // User cancelled
        return;
      }

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Uploading profile image...'),
                      ],
                    ),
                  ),
                ),
              ),
        );
      }

      // Get current user ID
      final authRepo = ref.read(authRepositoryProvider);
      final user = authRepo.currentUser;
      if (user == null) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to upload a profile image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Upload image to Supabase Storage
      final supabase = ref.read(supabaseClientProvider);
      final profileRepo = ProfileRepository(supabase);

      String imageUrl;
      try {
        imageUrl = await profileRepo.uploadProfileAvatar(imageFile, user.id);

        if (kDebugMode) {
          debugPrint('Profile image uploaded. URL: $imageUrl');
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          // Extract user-friendly error message
          String errorMessage = e.toString();
          // Remove "Exception: " prefix if present for cleaner display
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (imageUrl.isEmpty) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get image URL after upload'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Update profile with new image URL
      try {
        await ref
            .read(profileControllerProvider.notifier)
            .updateProfile(avatarUrl: imageUrl);

        if (kDebugMode) {
          debugPrint('Profile updated with avatar URL: $imageUrl');
        }

        // Refresh profile state to get the latest data
        await ref.read(profileControllerProvider.notifier).loadCurrentProfile();

        if (kDebugMode) {
          final updatedProfile = ref.read(profileControllerProvider).profile;
          debugPrint(
            'Profile refreshed. Avatar URL: ${updatedProfile?.avatarUrl}',
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image uploaded but failed to update profile: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        // Extract user-friendly error message
        String errorMessage = e.toString();
        // Remove "Exception: " prefix if present for cleaner display
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.isNotEmpty
                  ? errorMessage
                  : 'Failed to upload profile image. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage(BuildContext context, WidgetRef ref) async {
    try {
      // Update profile to remove avatar
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(removeAvatar: true);

      // Refresh profile state
      await ref.read(profileControllerProvider.notifier).loadCurrentProfile();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove profile image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                  Navigator.of(context).pop();
                  context.goNamed('admin-login');
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Ionicons.warning_outline, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Expanded(child: Text('Delete Account')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to permanently delete your account?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This action cannot be undone. All of your data will be permanently deleted, including:',
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Your profile information'),
                        Text('• Order history'),
                        Text('• Cart items'),
                        Text('• Saved addresses'),
                        Text('• Wishlist items'),
                        Text('• Chat conversations'),
                        Text('• Product ratings'),
                        Text('• All other account data'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Ionicons.alert_circle_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will be signed out immediately after deletion.',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  // Show loading dialog
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (loadingContext) => const Center(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Deleting account...'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    );
                  }

                  try {
                    // Delete the account
                    await ref
                        .read(authControllerProvider.notifier)
                        .deleteAccount();

                    // Close loading dialog
                    if (context.mounted) {
                      Navigator.of(context).pop();

                      // Navigate to role selection/login screen
                      context.goNamed('admin-login');

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deleted successfully'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    // Close loading dialog
                    if (context.mounted) {
                      Navigator.of(context).pop();

                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete account: ${e.toString().replaceFirst('Exception: ', '')}',
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Account'),
              ),
            ],
          ),
    );
  }
}
