import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../catalog/data/product.dart';
import '../../../catalog/data/measurement.dart';
import '../../../../core/widgets/lazy_image.dart';
import '../../../profile/application/profile_controller.dart';

class CompareProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onRemove;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;

  const CompareProductCard({
    super.key,
    required this.product,
    this.onRemove,
    this.isExpanded = false,
    this.onExpandToggle,
  });

  /// Calculate final price including tax
  double _calculateFinalPrice(double basePrice, double? tax) {
    if (tax != null && tax > 0) {
      return basePrice + (basePrice * tax / 100);
    }
    return basePrice;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and basic info
          InkWell(
            onTap: onExpandToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LazyImage(
                      imageUrl: product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.fill,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Product name and price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            product.subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final profile = ref.watch(currentProfileProvider);
                            if (profile == null || !profile.priceVisibilityEnabled) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              '₹${product.finalPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Remove button and expand icon
                  Column(
                    children: [
                      if (onRemove != null)
                        IconButton(
                          icon: const Icon(Ionicons.close_circle),
                          onPressed: onRemove,
                          tooltip: 'Remove from comparison',
                        ),
                      Icon(
                        isExpanded
                            ? Ionicons.chevron_up
                            : Ionicons.chevron_down,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded details
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  // Product Images Gallery
                  if (product.images.isNotEmpty) ...[
                    Text(
                      'Product Images',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LazyImage(
                                imageUrl: product.images[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.fill,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Key attributes
                  _buildAttributeRow(
                    context,
                    'Product ID',
                    product.id,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeRow(
                    context,
                    'Brand',
                    product.brand ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeRow(
                    context,
                    'SKU',
                    product.sku ?? 'N/A',
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final profile = ref.watch(currentProfileProvider);
                      if (profile == null || !profile.priceVisibilityEnabled) {
                        return const SizedBox.shrink();
                      }
                      return _buildAttributeRow(
                        context,
                        'Price',
                        '₹${product.price.toStringAsFixed(2)}',
                        valueColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeRow(
                    context,
                    'Stock',
                    product.stock > 0
                        ? '${product.stock} in stock'
                        : 'Out of stock',
                    valueColor: product.stock > 0 ? Colors.green : Colors.red,
                  ),
                  if (product.subtitle != null) ...[
                    const SizedBox(height: 12),
                    _buildAttributeRow(
                      context,
                      'Subtitle',
                      product.subtitle!,
                    ),
                  ],
                  if (product.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  // Variants with full details
                  if (product.variants.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Variants (${product.variants.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...product.variants.map((variant) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'SKU: ${variant.sku}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const Spacer(),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final profile = ref.watch(currentProfileProvider);
                                    if (profile == null || !profile.priceVisibilityEnabled) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      '₹${variant.finalPrice.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (variant.attributes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  for (final entry in variant.attributes.entries)
                                    Chip(
                                      label: Text('${entry.key}: ${entry.value}'),
                                      labelStyle: Theme.of(context).textTheme.labelSmall,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  variant.stock > 0
                                      ? Ionicons.checkmark_circle
                                      : Ionicons.close_circle,
                                  size: 14,
                                  color: variant.stock > 0 ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  variant.stock > 0
                                      ? '${variant.stock} in stock'
                                      : 'Out of stock',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: variant.stock > 0 ? Colors.green : Colors.red,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  // Measurement Pricing details
                  if (product.hasMeasurementPricing && product.measurement != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Measurement Pricing',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...product.measurement!.pricingOptions.map((pricing) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pricing.unit.displayName,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  '(${pricing.unit.shortName})',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Consumer(
                                  builder: (context, ref, child) {
                                    final profile = ref.watch(currentProfileProvider);
                                    if (profile == null || !profile.priceVisibilityEnabled) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      '₹${_calculateFinalPrice(pricing.price, product.tax).toStringAsFixed(2)}',
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
                                      pricing.stock > 0
                                          ? Ionicons.checkmark_circle
                                          : Ionicons.close_circle,
                                      size: 12,
                                      color: pricing.stock > 0 ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      pricing.stock > 0
                                          ? '${pricing.stock} in stock'
                                          : 'Out of stock',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: pricing.stock > 0 ? Colors.green : Colors.red,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (product.categories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in product.categories)
                          Chip(
                            label: Text(category),
                            labelStyle: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ],
                  if (product.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in product.tags)
                          Chip(
                            label: Text(tag),
                            labelStyle: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ],
                  if (product.alternativeNames.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Alternative Names',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final altName in product.alternativeNames)
                          if (altName.trim().isNotEmpty)
                            Chip(
                              label: Text(altName),
                              labelStyle: Theme.of(context).textTheme.labelSmall,
                            ),
                      ],
                    ),
                  ],
                  // Additional metadata
                  const SizedBox(height: 16),
                  Text(
                    'Additional Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildAttributeRow(
                    context,
                    'Featured',
                    product.isFeatured ? 'Yes' : 'No',
                  ),
                  if (product.isFeatured) ...[
                    const SizedBox(height: 12),
                    _buildAttributeRow(
                      context,
                      'Featured Position',
                      product.featuredPosition.toString(),
                    ),
                  ],
                  if (product.createdAt != null) ...[
                    const SizedBox(height: 12),
                    _buildAttributeRow(
                      context,
                      'Created',
                      _formatDate(product.createdAt!),
                    ),
                  ],
                  if (product.updatedAt != null) ...[
                    const SizedBox(height: 12),
                    _buildAttributeRow(
                      context,
                      'Updated',
                      _formatDate(product.updatedAt!),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

