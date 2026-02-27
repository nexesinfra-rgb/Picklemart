import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
// import '../../auth/application/auth_controller.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
// import '../../../core/utils/password_utils.dart';
// import 'widgets/password_field.dart';
// import 'widgets/password_strength_indicator.dart';
// import 'widgets/password_requirements_checklist.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final sectionSpacing = Responsive.getSectionSpacing(width);
    final cardPadding = Responsive.getCardPadding(width);

    return SafeScaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(cardPadding),
        children: [
          // Account Section
          // _buildSectionHeader(context, 'Account', Ionicons.person_outline),
          // SizedBox(height: cardPadding * 0.75),
          // Card(
          //   elevation: 2,
          //   child: _buildActionTile(
          //     context,
          //     icon: Ionicons.lock_closed_outline,
          //     title: 'Change Password',
          //     subtitle: 'Update your password',
          //     onTap: () => _showChangePasswordDialog(context, ref),
          //     showTrailing: true,
          //   ),
          // ),
          // SizedBox(height: sectionSpacing),

          // Notifications Section
          _buildSectionHeader(
            context,
            'Notifications',
            Ionicons.notifications_outline,
          ),
          SizedBox(height: cardPadding * 0.75),
          Card(
            elevation: 2,
            child: Consumer(
              builder: (context, ref, child) {
                final pushNotificationsEnabled = ref.watch(
                  pushNotificationsEnabledProvider,
                );
                // final settingsState = ref.watch(settingsProvider); // Removed unused variable
                return _buildSwitchTile(
                  context,
                  icon: Ionicons.notifications_outline,
                  title: 'Push Notifications',
                  subtitle: 'Order updates and promotions',
                  value: pushNotificationsEnabled,
                  onChanged: (value) async {
                    // Show loading state immediately
                    final success = await ref
                        .read(settingsProvider.notifier)
                        .togglePushNotifications(value);

                    if (!context.mounted) return;

                    // Show feedback based on result
                    if (success) {
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Push notifications enabled'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Push notifications disabled'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      // Show error message if available
                      final error = ref.read(settingsProvider).error;
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error ?? 'Failed to change notification settings',
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
          SizedBox(height: sectionSpacing),

          // App Section
          _buildSectionHeader(context, 'App', Ionicons.apps_outline),
          SizedBox(height: cardPadding * 0.75),
          Card(
            elevation: 2,
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final darkModeEnabled = ref.watch(darkModeEnabledProvider);
                    return _buildSwitchTile(
                      context,
                      icon: Ionicons.moon_outline,
                      title: 'Dark Mode',
                      subtitle: 'Switch between light and dark theme',
                      value: darkModeEnabled,
                      onChanged: (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .toggleDarkMode(value);
                      },
                    );
                  },
                ),
                _buildDivider(),
                _buildActionTile(
                  context,
                  icon: Ionicons.information_circle_outline,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () => _showAboutDialog(context),
                  showTrailing: true,
                ),
                _buildDivider(),
                _buildActionTile(
                  context,
                  icon: Ionicons.document_text_outline,
                  title: 'Terms & Privacy',
                  subtitle: 'Terms of service and privacy policy',
                  onTap: () => context.pushNamed('profile-terms-privacy'),
                  showTrailing: true,
                ),
              ],
            ),
          ),
          SizedBox(height: sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
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
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: cardPadding * 0.75,
        vertical: 12,
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

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: cardPadding * 0.75,
        vertical: 12,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 60);
  }

  // void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => _ChangePasswordDialog(ref: ref),
  //   );
  // }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Pickle Mart',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Ionicons.storefront, size: 48),
      children: [
        const Text('A modern shopping experience built with Flutter.'),
      ],
    );
  }
}

/*
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _ChangePasswordDialog({required this.ref});

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty) return false;

    final requirements = PasswordUtils.checkRequirements(newPassword);
    if (!requirements.allMet) return false;

    if (newPassword != confirmPassword) return false;

    return true;
  }

  bool? get _passwordsMatch {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (confirmPassword.isEmpty) return null;
    return newPassword == confirmPassword;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await widget.ref
          .read(authControllerProvider.notifier)
          .updatePassword(
            _currentPasswordController.text,
            _newPasswordController.text,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update password: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordField(
                  controller: _currentPasswordController,
                  labelText: 'Current Password',
                  hintText: 'Enter your current password',
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 20),
                PasswordField(
                  controller: _newPasswordController,
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (_newPasswordController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  PasswordStrengthIndicator(
                    password: _newPasswordController.text,
                  ),
                  const SizedBox(height: 12),
                  PasswordRequirementsChecklist(
                    password: _newPasswordController.text,
                  ),
                ],
                const SizedBox(height: 20),
                PasswordField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm New Password',
                  hintText: 'Re-enter your new password',
                  showMatchIndicator: true,
                  matchesPassword: _passwordsMatch,
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isLoading || !_canSubmit ? null : _handleSubmit,
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
*/
