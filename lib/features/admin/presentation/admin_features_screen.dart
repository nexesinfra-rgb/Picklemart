import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../data/admin_features.dart';
import '../application/admin_notification_settings_provider.dart';

class AdminFeaturesScreen extends ConsumerWidget {
  const AdminFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(adminFeaturesProvider);
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);
    final isSoundEnabled = ref.watch(adminNotificationSettingsProvider);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Admin Features',
        showBackButton: true,
        actions: [],
        body: SingleChildScrollView(
          padding: EdgeInsets.all(spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Feature Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: spacing * 0.5),
              Text(
                'Configure app features and behavior',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: spacing),

              // Feature Toggles
              /*_buildFeatureCard(
                context,
                title: 'Dark Mode',
                subtitle: 'Enable dark theme for the application',
                icon: Ionicons.moon_outline,
                value: features.darkModeEnabled,
                onChanged: (value) {
                  ref.read(adminFeaturesProvider.notifier).toggleDarkMode();
                },
              ),
              SizedBox(height: spacing * 0.75),*/

              _buildFeatureCard(
                context,
                title: 'Store/Admin Notifications',
                subtitle: 'Enable push notifications for admin updates',
                icon: Ionicons.notifications_outline,
                value: features.notificationsEnabled,
                onChanged: (value) {
                  ref
                      .read(adminFeaturesProvider.notifier)
                      .toggleNotifications();
                },
              ),
              SizedBox(height: spacing * 0.75),

              _buildFeatureCard(
                context,
                title: 'Notification Sound',
                subtitle: 'Enable sound for admin notifications',
                icon:
                    isSoundEnabled
                        ? Ionicons.volume_high
                        : Ionicons.volume_mute,
                value: isSoundEnabled,
                onChanged: (value) {
                  ref
                      .read(adminNotificationSettingsProvider.notifier)
                      .toggleSound();
                },
              ),
              SizedBox(height: spacing * 0.75),

              /*_buildFeatureCard(
                context,
                title: 'Analytics',
                subtitle: 'Enable analytics tracking and reporting',
                icon: Ionicons.bar_chart_outline,
                value: features.analyticsEnabled,
                onChanged: (value) {
                  ref.read(adminFeaturesProvider.notifier).toggleAnalytics();
                },
              ),
              SizedBox(height: spacing * 0.75),

              _buildFeatureCard(
                context,
                title: 'Rates',
                subtitle: 'Enable product rating and review system',
                icon: Ionicons.star_outline,
                value: features.ratesEnabled,
                onChanged: (value) {
                  ref.read(adminFeaturesProvider.notifier).toggleRates();
                },
              ),
              SizedBox(height: spacing * 0.75),

              _buildFeatureCard(
                context,
                title: 'Star Ratings',
                subtitle: 'Enable star ratings feature for products',
                icon: Ionicons.star,
                value: features.starRatingsEnabled,
                onChanged: (value) {
                  ref.read(adminFeaturesProvider.notifier).toggleStarRatings();
                },
              ),
              SizedBox(height: spacing * 0.75),*/
              _buildFeatureCard(
                context,
                title: 'Chat',
                subtitle: 'Enable chat feature between users and admin',
                icon: Ionicons.chatbubbles_outline,
                value: features.chatEnabled,
                onChanged: (value) {
                  ref.read(adminFeaturesProvider.notifier).toggleChat();
                },
              ),
              /*SizedBox(height: spacing * 0.75),

              _buildFeatureCard(
                context,
                title: 'Price Visibility',
                subtitle:
                    'Show or hide product prices to users across all views',
                icon: Ionicons.cash_outline,
                value: features.priceVisibilityEnabled,
                onChanged: (value) {
                  ref
                      .read(adminFeaturesProvider.notifier)
                      .togglePriceVisibility();
                },
              ),*/
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }
}
