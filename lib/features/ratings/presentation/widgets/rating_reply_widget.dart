import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive.dart';
import '../../data/rating_repository.dart';
import '../../../../core/providers/supabase_provider.dart';

/// Widget for displaying a single rating reply with threading support
class RatingReplyWidget extends ConsumerStatefulWidget {
  final RatingReplyWithUser reply;
  final int depth; // Threading depth (0 = top level, 1+ = nested)
  final String? currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUpdated;

  const RatingReplyWidget({
    super.key,
    required this.reply,
    this.depth = 0,
    this.currentUserId,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onUpdated,
  });

  @override
  ConsumerState<RatingReplyWidget> createState() => _RatingReplyWidgetState();
}

class _RatingReplyWidgetState extends ConsumerState<RatingReplyWidget> {
  bool _isEditing = false;
  final TextEditingController _editController = TextEditingController();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _editController.text = widget.reply.reply.replyText;
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Reply'),
            content: const Text('Are you sure you want to delete this reply?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final repository = ref.read(ratingRepositoryProvider);
      await repository.deleteReply(widget.reply.reply.id);

      if (mounted) {
        widget.onDelete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting reply: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _handleSaveEdit() async {
    if (_editController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reply cannot be empty')));
      return;
    }

    if (_editController.text.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply cannot exceed 1000 characters')),
      );
      return;
    }

    setState(() => _isEditing = false);

    try {
      final repository = ref.read(ratingRepositoryProvider);
      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to edit replies'),
            ),
          );
        }
        return;
      }

      await repository.updateReply(
        replyId: widget.reply.reply.id,
        userId: userId,
        replyText: _editController.text.trim(),
      );

      if (mounted) {
        widget.onUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEditing = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating reply: $e')));
      }
    }
  }

  void _handleCancelEdit() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.reply.reply.replyText;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(width);
    final isTablet = Responsive.isTablet(width);
    // final isDesktop = Responsive.isDesktop(width); // Removed unused variable

    // Responsive sizing
    final avatarSize = isMobile ? 32.0 : (isTablet ? 40.0 : 48.0);
    final indentSize = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final padding = Responsive.getCardPadding(width) * 0.75;

    final isOwnReply = widget.currentUserId == widget.reply.reply.userId;
    final canEdit = isOwnReply && !_isDeleting;
    final canDelete = isOwnReply && !_isEditing;

    if (_isDeleting) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: widget.depth > 0 ? indentSize * widget.depth : 0,
        top: padding * 0.5,
        bottom: padding * 0.5,
      ),
      child: Container(
        decoration: BoxDecoration(
          color:
              widget.depth > 0
                  ? Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : null,
          borderRadius: BorderRadius.circular(12),
          border:
              widget.depth > 0
                  ? Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  )
                  : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      (widget.reply.userName?.substring(0, 1).toUpperCase() ??
                          widget.reply.userEmail
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          'U'),
                      style: TextStyle(
                        fontSize: avatarSize * 0.4,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  SizedBox(width: padding),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User name and timestamp
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.reply.userName ??
                                    widget.reply.userEmail ??
                                    'Anonymous',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatDate(widget.reply.reply.createdAt),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: padding * 0.5),
                        // Reply text or edit field
                        if (_isEditing)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextField(
                                controller: _editController,
                                maxLines: 4,
                                maxLength: 1000,
                                decoration: InputDecoration(
                                  hintText: 'Edit your reply...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(context).colorScheme.surface,
                                ),
                                autofocus: true,
                              ),
                              SizedBox(height: padding * 0.5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _handleCancelEdit,
                                    child: const Text('Cancel'),
                                  ),
                                  SizedBox(width: padding * 0.5),
                                  FilledButton(
                                    onPressed: _handleSaveEdit,
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Text(
                            widget.reply.reply.replyText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // Actions
              if (!_isEditing) ...[
                SizedBox(height: padding * 0.5),
                Row(
                  children: [
                    // Reply button
                    TextButton.icon(
                      onPressed: widget.onReply,
                      icon: const Icon(Ionicons.arrow_undo_outline, size: 16),
                      label: const Text('Reply'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.5,
                          vertical: padding * 0.25,
                        ),
                      ),
                    ),
                    // Edit button (own replies only)
                    if (canEdit) ...[
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _isEditing = true);
                        },
                        icon: const Icon(Ionicons.create_outline, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding * 0.5,
                            vertical: padding * 0.25,
                          ),
                        ),
                      ),
                    ],
                    // Delete button (own replies only)
                    if (canDelete) ...[
                      TextButton.icon(
                        onPressed: _handleDelete,
                        icon: const Icon(Ionicons.trash_outline, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            horizontal: padding * 0.5,
                            vertical: padding * 0.25,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
