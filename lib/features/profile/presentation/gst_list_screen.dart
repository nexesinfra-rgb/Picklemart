import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../application/gst_controller.dart';
import '../data/gst_repository.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/layout/responsive.dart';

class GstListScreen extends ConsumerWidget {
  const GstListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gstState = ref.watch(gstControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Details'),
        actions: [
          ResponsiveIconButton(
            onPressed: () => context.pushNamed('profile-gst-add'),
            icon: const Icon(Ionicons.add),
          ),
        ],
      ),
      body: gstState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (gstDetails) => gstDetails.isEmpty
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Ionicons.document_text_outline,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No GST details saved',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your GST details for business transactions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ResponsiveFilledButton(
                    onPressed: () => context.pushNamed('profile-gst-add'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Ionicons.add),
                        SizedBox(width: 8),
                        Text('Add GST Details'),
                      ],
                    ),
                  ),
                ],
              ),
            )
            : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: gstDetails.length,
              itemBuilder: (context, index) {
                final gst = gstDetails[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Ionicons.document_text,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(gst.businessName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'GST: ${gst.formattedGstNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(gst.fullAddress),
                        if (gst.email != null) ...[
                          const SizedBox(height: 2),
                          Text(gst.email!),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Ionicons.create_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Ionicons.trash_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
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
                            context.pushNamed('profile-gst-edit', pathParameters: {'index': index.toString()});
                            break;
                          case 'delete':
                            _showDeleteDialog(context, ref, gst.id);
                            break;
                        }
                      },
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      ),
      floatingActionButton: gstState.maybeWhen(
        data: (gstDetails) => gstDetails.isNotEmpty
            ? LayoutBuilder(
              builder: (context, constraints) {
                final bp = Responsive.breakpointForWidth(
                  constraints.maxWidth,
                );
                final fabSize = ResponsiveButtons.getFabSize(
                  constraints.maxWidth,
                );
                return SizedBox(
                  width: fabSize,
                  height: fabSize,
                  child: FloatingActionButton(
                    onPressed: () => context.pushNamed('profile-gst-add'),
                    child: Icon(
                      Ionicons.add,
                      size: bp == AppBreakpoint.expanded ? 28 : 24,
                    ),
                  ),
                );
              },
            )
            : null,
        orElse: () => null,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String gstId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete GST Details'),
            content: const Text(
              'Are you sure you want to delete these GST details?',
            ),
            actions: [
              ResponsiveTextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ResponsiveFilledButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await ref.read(gstControllerProvider.notifier).deleteGstDetails(gstId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('GST details deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting GST details: $e')),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
