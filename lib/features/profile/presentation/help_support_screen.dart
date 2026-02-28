import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../auth/application/auth_controller.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final sectionSpacing = Responsive.getSectionSpacing(width);
    final cardPadding = Responsive.getCardPadding(width);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: EdgeInsets.all(cardPadding),
        children: [
          // Help Section
          _buildSectionHeader(context, 'Help', Ionicons.help_circle_outline),
          SizedBox(height: cardPadding * 0.75),
          Card(
            elevation: 2,
            child: Column(
              children: [
                _buildActionTile(
                  context,
                  icon: Ionicons.document_text_outline,
                  title: 'FAQs',
                  subtitle: 'Frequently asked questions',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FAQs coming soon'),
                      ),
                    );
                  },
                  showTrailing: true,
                ),
                _buildDivider(),
                _buildActionTile(
                  context,
                  icon: Ionicons.chatbubbles_outline,
                  title: 'Contact Support',
                  subtitle: 'Get in touch with our support team',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact Support coming soon'),
                      ),
                    );
                  },
                  showTrailing: true,
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
              ],
            ),
          ),
          SizedBox(height: sectionSpacing),

          // Account Actions
          _buildSectionHeader(context, 'Account Actions', Ionicons.shield_outline),
          SizedBox(height: cardPadding * 0.75),
          Card(
            elevation: 2,
            child: _buildActionTile(
              context,
              icon: Ionicons.log_out_outline,
              title: 'Sign Out',
              subtitle: 'Signed in as ${authState.email ?? 'Unknown'}',
              onTap: () => _showSignOutDialog(context, ref),
              iconColor: Colors.red,
              textColor: Colors.red,
              showTrailing: false,
            ),
          ),
          SizedBox(height: sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
      trailing: showTrailing
          ? Icon(
              Ionicons.chevron_forward,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 60);
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
