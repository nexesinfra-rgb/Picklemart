import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../catalog/data/product.dart';
import '../../../../core/widgets/lazy_image.dart';
import '../../../profile/application/profile_controller.dart';

class CompareProductItem extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final bool isCurrentProduct;
  final VoidCallback? onTap;

  const CompareProductItem({
    super.key,
    required this.product,
    required this.isSelected,
    this.isCurrentProduct = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: isCurrentProduct ? null : (_) => onTap?.call(),
              ),
              const SizedBox(width: 12),
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LazyImage(
                  imageUrl: product.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(width: 12),
              // Product info - using Expanded to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product name with Current badge in same row if needed
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentProduct) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (product.brand != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.brand!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Price and stock in a flexible row
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final profile = ref.watch(currentProfileProvider);
                            if (profile == null || !profile.priceVisibilityEnabled) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              '₹${product.finalPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            );
                          },
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.stock > 0
                                  ? Ionicons.checkmark_circle
                                  : Ionicons.close_circle,
                              size: 14,
                              color: product.stock > 0 ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.stock > 0 ? 'In stock' : 'Out of stock',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: product.stock > 0 ? Colors.green : Colors.red,
                                      fontSize: 11,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

