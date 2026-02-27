import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../data/address_repository.dart';
import '../application/address_controller.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/ui/address_map_view.dart';
import '../../../core/layout/responsive.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressState = ref.watch(addressControllerProvider);
    final addresses = addressState.addresses;
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    final sectionSpacing = Responsive.getSectionSpacing(width);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Addresses'),
        actions: [
          // Only show add button if no address exists
          if (addresses.isEmpty)
            IconButton(
              onPressed: () => context.pushNamed('profile-address-add'),
              icon: const Icon(Ionicons.add),
              tooltip: 'Add Address',
            ),
        ],
      ),
      floatingActionButton: null, // Removed floating action button since only one address is allowed
      body:
          addresses.isEmpty
              ? Center(
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Ionicons.location_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      Text(
                        'No addresses saved',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: cardPadding * 0.5),
                      Text(
                        'Add your first address to get started',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      FilledButton.icon(
                        onPressed: () => context.pushNamed('profile-address-add'),
                        icon: const Icon(Ionicons.add),
                        label: const Text('Add Address'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: cardPadding * 1.5,
                            vertical: cardPadding * 0.75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Builder(
                builder: (context) {
                  // Only one address allowed, so get the first one
                  final address = addresses.first;
                  return ListView(
                    padding: EdgeInsets.all(cardPadding),
                    children: [
                      // Address card
                      Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: cardPadding * 0.75),
                      child: InkWell(
                        onTap: () => context.pushNamed('profile-address-edit', pathParameters: {'id': address.id}),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Ionicons.location,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: cardPadding * 0.75),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                address.name,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (address.isDefault)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Default',
                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: cardPadding * 0.25),
                                        Row(
                                          children: [
                                            Icon(
                                              Ionicons.call_outline,
                                              size: 14,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                            ),
                                            SizedBox(width: cardPadding * 0.3),
                                            Text(
                                              address.phone,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: Icon(
                                      Ionicons.ellipsis_vertical,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                    itemBuilder:
                                        (context) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Ionicons.create_outline, size: 18),
                                                SizedBox(width: cardPadding * 0.5),
                                                const Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Ionicons.trash_outline,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: cardPadding * 0.5),
                                                const Text(
                                                  'Delete',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          context.pushNamed('profile-address-edit', pathParameters: {'id': address.id});
                                          break;
                                        case 'delete':
                                          _showDeleteDialog(context, ref, address);
                                          break;
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: cardPadding * 0.75),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(cardPadding * 0.75),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  address.fullAddress,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    // Map view section
                    if (address.coordinates != null) ...[
                      Text(
                        'Location on Map',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: cardPadding * 0.75),
                      AddressMapView(
                        location: address.coordinates!,
                        addressText: address.fullAddress,
                      ),
                    ],
                    ],
                  );
                },
              ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Address address) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Address'),
            content: const Text(
              'Are you sure you want to delete this address?',
            ),
            actions: [
              ResponsiveTextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ResponsiveFilledButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final addressController = ref.read(addressControllerProvider.notifier);
                  final success = await addressController.deleteAddress(address.id);
                  if (success) {
                    // Refresh addresses to ensure UI updates immediately
                    await addressController.refresh();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Address deleted' : 'Failed to delete address'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
