import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../data/measurement.dart';

class MeasurementSelector extends StatelessWidget {
  final ProductMeasurement measurement;
  final MeasurementUnit selectedUnit;
  final ValueChanged<MeasurementUnit> onUnitChanged;
  final double? productTax;

  const MeasurementSelector({
    super.key,
    required this.measurement,
    required this.selectedUnit,
    required this.onUnitChanged,
    this.productTax,
  });

  @override
  Widget build(BuildContext context) {
    final availableUnits = measurement.availableUnits;

    if (availableUnits.length <= 1) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MeasurementUnit>(
              value: selectedUnit,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              items:
                  availableUnits.map((unit) {
                    final pricing = measurement.getPricingForUnit(unit);

                    return DropdownMenuItem<MeasurementUnit>(
                      value: unit,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  unit.displayName,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                if (pricing != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${_calculateFinalPrice(pricing.price).toStringAsFixed(2)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (pricing != null) ...[
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (pricing.stock > 0)
                                  Icon(
                                    Ionicons.checkmark_circle,
                                    size: 16,
                                    color: Colors.green.shade600,
                                  )
                                else
                                  Icon(
                                    Ionicons.close_circle,
                                    size: 16,
                                    color: Colors.red.shade600,
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  pricing.stock > 0
                                      ? 'In Stock'
                                      : 'Out of Stock',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        pricing.stock > 0
                                            ? Colors.green.shade600
                                            : Colors.red.shade600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (unit) {
                if (unit != null) {
                  onUnitChanged(unit);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  double _calculateFinalPrice(double basePrice) {
    if (productTax != null && productTax! > 0) {
      return basePrice + (basePrice * productTax! / 100);
    }
    return basePrice;
  }
}

class MeasurementPriceDisplay extends StatelessWidget {
  final ProductMeasurement measurement;
  final MeasurementUnit selectedUnit;
  final int quantity;
  final double? productTax;

  const MeasurementPriceDisplay({
    super.key,
    required this.measurement,
    required this.selectedUnit,
    this.quantity = 1,
    this.productTax,
  });

  @override
  Widget build(BuildContext context) {
    final pricing = measurement.getPricingForUnit(selectedUnit);
    if (pricing == null) return const SizedBox.shrink();

    final basePrice = pricing.price;
    final finalUnitPrice = _calculateFinalPrice(basePrice);
    final totalPrice = finalUnitPrice * quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Text(
              'per ${selectedUnit.shortName}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        if (quantity > 1) ...[
          const SizedBox(height: 4),
          Text(
            'Unit price: ₹${finalUnitPrice.toStringAsFixed(2)} per ${selectedUnit.shortName}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  double _calculateFinalPrice(double basePrice) {
    if (productTax != null && productTax! > 0) {
      return basePrice + (basePrice * productTax! / 100);
    }
    return basePrice;
  }
}
