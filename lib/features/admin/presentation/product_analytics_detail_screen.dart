import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../application/product_analytics_controller.dart';

class ProductAnalyticsDetailScreen extends ConsumerWidget {
  final String productId;
  final String productName;

  const ProductAnalyticsDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productAnalyticsControllerProvider(productId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Product Insights')),
      body:
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    Text(
                      productName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Customer engagement overview',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _summaryCard(context, state),
                    const SizedBox(height: 18),
                    _section(
                      context,
                      title: 'Views by user',
                      icon: Ionicons.eye_outline,
                      items:
                          state.viewsByUser.map((e) {
                            final parts = <String>[];
                            parts.add(e.label);
                            if (e.email != null && e.email!.isNotEmpty) {
                              parts.add(e.email!);
                            }
                            if (e.phone != null && e.phone!.isNotEmpty) {
                              parts.add(e.phone!);
                            }
                            parts.add('Views: ${e.count}');
                            return parts.join(' • ');
                          }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      context,
                      title: 'Orders by user',
                      icon: Ionicons.people_outline,
                      items:
                          state.ordersByUser.map((e) {
                            final parts = <String>[];
                            parts.add(e.label);
                            if (e.email != null && e.email!.isNotEmpty) {
                              parts.add(e.email!);
                            }
                            if (e.phone != null && e.phone!.isNotEmpty) {
                              parts.add(e.phone!);
                            }
                            parts.add('Orders: ${e.count}');
                            return parts.join(' • ');
                          }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _ordersByDateSection(context, dates: state.ordersByDate),
                    const SizedBox(height: 12),
                    _section(
                      context,
                      title: 'Orders by area',
                      icon: Ionicons.location_outline,
                      items:
                          state.ordersByArea
                              .map((e) => '${e.label}: ${e.count}')
                              .toList(),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _summaryCard(BuildContext context, ProductAnalyticsState state) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            _summaryTile(
              context,
              label: 'Views',
              value: state.totalViews.toString(),
              icon: Ionicons.eye_outline,
            ),
            const SizedBox(width: 10),
            _summaryTile(
              context,
              label: 'Orders',
              value: state.totalOrders.toString(),
              icon: Ionicons.cart_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withOpacity(0.15),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasData = items.isNotEmpty;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withOpacity(0.12),
                  child: Icon(icon, color: colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasData)
              Text(
                'No data yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              )
            else
              ...items.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.35,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(i, style: theme.textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ordersByDateSection(
    BuildContext context, {
    required List<DateCount> dates,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasData = dates.isNotEmpty;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withOpacity(0.12),
                  child: Icon(
                    Ionicons.calendar_outline,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Orders by date',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!hasData)
              Text(
                'No data yet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              )
            else
              _OrdersCalendar(dates: dates),
          ],
        ),
      ),
    );
  }
}

class _OrdersCalendar extends StatelessWidget {
  const _OrdersCalendar({required this.dates});

  final List<DateCount> dates;

  DateTime? _parseLabel(String label) {
    final parts = label.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final today = DateTime.now();

    final Map<DateTime, int> counts = {};
    for (final d in dates) {
      final parsed = _parseLabel(d.label);
      if (parsed != null) {
        final key = DateTime(parsed.year, parsed.month, parsed.day);
        counts[key] = d.count;
      }
    }

    final DateTime baseDate =
        counts.keys.isNotEmpty
            ? counts.keys.reduce((a, b) => a.isAfter(b) ? a : b)
            : DateTime(today.year, today.month);
    final firstDay = DateTime(baseDate.year, baseDate.month, 1);
    final daysInMonth = DateTime(baseDate.year, baseDate.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1; // Monday as first day

    final cells = <Widget>[];
    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(baseDate.year, baseDate.month, day);
      final count = counts[date] ?? 0;
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      cells.add(
        _DayCell(
          day: day,
          count: count,
          isToday: isToday,
          colorScheme: colorScheme,
        ),
      );
    }
    final remainder = cells.length % 7;
    if (remainder != 0) {
      for (int i = 0; i < 7 - remainder; i++) {
        cells.add(const SizedBox.shrink());
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _monthLabel(baseDate),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                _legendDot(colorScheme.primary),
                const SizedBox(width: 6),
                Text('Has orders', style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                _legendDot(AppColors.outlineSoft),
                const SizedBox(width: 6),
                Text('No orders', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _WeekdayLabel(text: 'M'),
            _WeekdayLabel(text: 'T'),
            _WeekdayLabel(text: 'W'),
            _WeekdayLabel(text: 'T'),
            _WeekdayLabel(text: 'F'),
            _WeekdayLabel(text: 'S'),
            _WeekdayLabel(text: 'S'),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
          children: cells,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              dates
                  .take(8)
                  .map(
                    (d) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${d.label} • ${d.count} orders',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.isToday,
    required this.colorScheme,
  });

  final int day;
  final int count;
  final bool isToday;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final hasOrders = count > 0;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color:
                hasOrders
                    ? colorScheme.primary.withOpacity(0.12)
                    : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isToday
                      ? colorScheme.primary.withOpacity(0.7)
                      : hasOrders
                      ? colorScheme.primary.withOpacity(0.25)
                      : AppColors.outlineSoft,
            ),
          ),
          child: Center(
            child: Text(
              '$day',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (hasOrders)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
