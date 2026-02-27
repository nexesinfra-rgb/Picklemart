import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/chat_models.dart';
import 'chat_product_card.dart';
import '../../../../features/catalog/data/product.dart';
import '../../../../features/catalog/data/product_repository.dart';

/// Chat message bubble widget
class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final String? imageUrl; // Signed URL for image messages
  final bool isAdminView; // Indicates if this is viewed by admin (no purchase actions)

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.imageUrl,
    this.isAdminView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isCurrentUser
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: _buildMessageContent(context, ref),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                  ),
                  // Read receipt for sent messages
                  if (isCurrentUser) ...[
                    const SizedBox(width: 4),
                    Builder(
                      builder: (context) {
                        final hasReadReceipt = message.readAt != null;
                        return Icon(
                          hasReadReceipt
                              ? Icons.done_all
                              : Icons.done,
                          size: 16,
                          color: hasReadReceipt
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, WidgetRef ref) {
    switch (message.messageType) {
      case MessageType.text:
        return Text(
          message.content ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
        );
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.product:
        return _buildProductMessage(context, ref);
    }
  }

  Widget _buildImageMessage(BuildContext context) {
    final url = imageUrl ?? message.imageUrl;
    if (url == null) {
      return const Icon(Icons.image_not_supported);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 200,
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Icon(Icons.error_outline),
          );
        },
      ),
    );
  }

  Widget _buildProductMessage(BuildContext context, WidgetRef ref) {
    if (message.productId == null) {
      return Text(
        'Product no longer available',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      );
    }

    // Fetch product asynchronously
    final productFuture = ref.read(productRepositoryProvider).fetchById(message.productId!);

    return FutureBuilder<Product?>(
      future: productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 200,
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final product = snapshot.data;
        if (product == null) {
          return Text(
            'Product no longer available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          );
        }

        return ChatProductCard(
          product: product,
          isAdminView: isAdminView,
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }
}

