import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class AnalyticsTable extends StatelessWidget {
  final List<Map<String, String>> data;
  final List<String> columns;
  final bool isCompact;

  const AnalyticsTable({
    super.key,
    required this.data,
    required this.columns,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: isCompact ? 12 : 16,
        horizontalMargin: isCompact ? 8 : 12,
        headingRowHeight: isCompact ? 40 : 48,
        dataRowHeight: isCompact ? 36 : 44,
        columns:
            columns
                .map(
                  (column) => DataColumn(
                    label: Text(
                      column,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 11 : 12,
                      ),
                    ),
                  ),
                )
                .toList(),
        rows:
            data
                .map(
                  (row) => DataRow(
                    cells:
                        columns
                            .map(
                              (column) => DataCell(
                                Text(
                                  row[column] ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontSize: isCompact ? 10 : 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.grid_outline,
              size: isCompact ? 32 : 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              'No data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: isCompact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
