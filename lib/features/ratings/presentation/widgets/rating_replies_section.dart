import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive.dart';
import '../../data/rating_repository.dart';
import '../../../../core/providers/supabase_provider.dart';
import 'rating_reply_widget.dart';

/// Widget for displaying all replies to a rating with input field
class RatingRepliesSection extends ConsumerStatefulWidget {
  final String ratingId;
  final bool showInput;
  final int maxInitialReplies;
  final VoidCallback? onReplyAdded;

  const RatingRepliesSection({
    super.key,
    required this.ratingId,
    this.showInput = true,
    this.maxInitialReplies = 5,
    this.onReplyAdded,
  });

  @override
  ConsumerState<RatingRepliesSection> createState() =>
      _RatingRepliesSectionState();
}

class _RatingRepliesSectionState extends ConsumerState<RatingRepliesSection> {
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _nestedReplyController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<RatingReplyWithUser> _replies = [];
  String? _replyingToReplyId;
  bool _showAllReplies = false;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _nestedReplyController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(ratingRepositoryProvider);
      final replies = await repository.getRepliesWithUsers(widget.ratingId);

      if (mounted) {
        setState(() {
          _replies = replies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading replies: $e')));
      }
    }
  }

  Future<void> _submitReply({String? parentReplyId}) async {
    final controller =
        parentReplyId != null ? _nestedReplyController : _replyController;
    final replyText = controller.text.trim();

    if (replyText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a reply')));
      return;
    }

    if (replyText.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply cannot exceed 1000 characters')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(ratingRepositoryProvider);
      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to reply')),
          );
        }
        return;
      }

      await repository.createReply(
        ratingId: widget.ratingId,
        userId: userId,
        replyText: replyText,
        parentReplyId: parentReplyId,
      );

      controller.clear();
      if (parentReplyId != null) {
        setState(() => _replyingToReplyId = null);
      }

      // Reload replies
      await _loadReplies();

      if (mounted) {
        widget.onReplyAdded?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding reply: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Build threaded reply tree
  List<Widget> _buildReplyTree(
    List<RatingReplyWithUser> replies, {
    int depth = 0,
  }) {
    final List<Widget> widgets = [];
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;

    // Filter top-level replies (no parent)
    final topLevelReplies =
        replies.where((r) => r.reply.parentReplyId == null).toList();

    // Sort by creation time
    topLevelReplies.sort(
      (a, b) => a.reply.createdAt.compareTo(b.reply.createdAt),
    );

    for (final reply in topLevelReplies) {
      // Find nested replies
      final nestedReplies =
          replies
              .where((r) => r.reply.parentReplyId == reply.reply.id)
              .toList();
      nestedReplies.sort(
        (a, b) => a.reply.createdAt.compareTo(b.reply.createdAt),
      );

      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingReplyWidget(
              reply: reply,
              depth: depth,
              currentUserId: currentUserId,
              onReply: () {
                setState(() => _replyingToReplyId = reply.reply.id);
              },
              onDelete: _loadReplies,
              onUpdated: _loadReplies,
            ),
            // Nested replies
            if (nestedReplies.isNotEmpty)
              ..._buildReplyTree(nestedReplies, depth: depth + 1),
            // Nested reply input
            if (_replyingToReplyId == reply.reply.id)
              _buildNestedReplyInput(reply.reply.id),
          ],
        ),
      );
    }

    return widgets;
  }

  Widget _buildNestedReplyInput(String parentReplyId) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(width);
    final indentSize =
        isMobile ? 16.0 : (Responsive.isTablet(width) ? 24.0 : 32.0);
    final padding = Responsive.getCardPadding(width) * 0.75;

    return Padding(
      padding: EdgeInsets.only(left: indentSize, top: padding * 0.5),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _nestedReplyController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            SizedBox(height: padding * 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _replyingToReplyId = null;
                      _nestedReplyController.clear();
                    });
                  },
                  child: const Text('Cancel'),
                ),
                SizedBox(width: padding * 0.5),
                FilledButton(
                  onPressed:
                      _isSubmitting
                          ? null
                          : () => _submitReply(parentReplyId: parentReplyId),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Reply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput() {
    final width = MediaQuery.of(context).size.width;
    final padding = Responsive.getCardPadding(width) * 0.75;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _replyController,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Write a reply...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          SizedBox(height: padding * 0.5),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : () => _submitReply(),
            icon:
                _isSubmitting
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Ionicons.send_outline, size: 16),
            label: const Text('Post Reply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = Responsive.getCardPadding(width);
    // final isMobile = Responsive.isMobile(width); // Removed unused variable

    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.all(padding),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayedReplies =
        _showAllReplies
            ? _replies
            : _replies.take(widget.maxInitialReplies).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Replies list
        if (_replies.isEmpty)
          Padding(
            padding: EdgeInsets.all(padding),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Ionicons.chatbubble_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: padding * 0.5),
                  Text(
                    'No replies yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ..._buildReplyTree(displayedReplies),
          // Show more/less button
          if (_replies.length > widget.maxInitialReplies)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: TextButton(
                onPressed: () {
                  setState(() => _showAllReplies = !_showAllReplies);
                },
                child: Text(
                  _showAllReplies
                      ? 'Show less'
                      : 'Show ${_replies.length - widget.maxInitialReplies} more replies',
                ),
              ),
            ),
        ],
        // Reply input
        if (widget.showInput) ...[
          SizedBox(height: padding),
          _buildReplyInput(),
        ],
      ],
    );
  }
}
