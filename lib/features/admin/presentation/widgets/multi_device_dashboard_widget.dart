import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../data/multi_device_repository.dart';
import '../../../../core/providers/supabase_provider.dart';

/// Widget showing multi-device login statistics
class MultiDeviceDashboardWidget extends ConsumerWidget {
  const MultiDeviceDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getMultiDeviceStats(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Ionicons.phone_portrait_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Multi-Device Tracking',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Ionicons.phone_portrait_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Multi-Device Tracking',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load statistics',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final usersWithMultipleDevices = stats['users_with_multiple_devices'] ?? 0;
        final totalMultiDeviceLogins = stats['total_multi_device_logins'] ?? 0;

        return Card(
          child: InkWell(
            onTap: () => context.pushNamed('admin-multi-device-tracking'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Ionicons.phone_portrait_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Multi-Device Tracking',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Icon(
                        Ionicons.chevron_forward_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Users with Multiple Devices',
                          usersWithMultipleDevices.toString(),
                          Ionicons.people_outline,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Multi-Device Logins',
                          totalMultiDeviceLogins.toString(),
                          Ionicons.log_in_outline,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to view detailed device tracking',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getMultiDeviceStats(WidgetRef ref) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final repository = MultiDeviceRepositorySupabase(supabase);

      // Get all profiles with phone numbers
      final profilesResponse = await supabase
          .from('profiles')
          .select('id, mobile')
          .not('mobile', 'is', null);

      final profiles = profilesResponse;
      int usersWithMultipleDevices = 0;
      int totalMultiDeviceLogins = 0;

      // Check each phone number for multiple devices
      final phoneNumbers = <String>{};
      for (final profile in profiles) {
        final mobile = profile['mobile'] as String?;
        if (mobile != null && mobile.isNotEmpty) {
          phoneNumbers.add(mobile);
        }
      }

      // Sample a subset for performance (check first 50 phone numbers)
      final phoneNumbersToCheck = phoneNumbers.take(50).toList();

      for (final phoneNumber in phoneNumbersToCheck) {
        try {
          final uniqueCount = await repository.getUniqueDeviceCount(phoneNumber);
          if (uniqueCount > 1) {
            usersWithMultipleDevices++;
            totalMultiDeviceLogins += uniqueCount;
          }
        } catch (e) {
          // Skip errors for individual phone numbers
          continue;
        }
      }

      // Extrapolate based on sample
      if (phoneNumbers.length > 50) {
        final ratio = phoneNumbers.length / 50;
        usersWithMultipleDevices = (usersWithMultipleDevices * ratio).round();
        totalMultiDeviceLogins = (totalMultiDeviceLogins * ratio).round();
      }

      return {
        'users_with_multiple_devices': usersWithMultipleDevices,
        'total_multi_device_logins': totalMultiDeviceLogins,
      };
    } catch (e) {
      return {'users_with_multiple_devices': 0, 'total_multi_device_logins': 0};
    }
  }
}

