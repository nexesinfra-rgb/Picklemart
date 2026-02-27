import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../data/analytics_models.dart';

class AnalyticsChart extends StatelessWidget {
  final String title;
  final List<ChartDataPoint> data;
  final ChartType chartType;
  final double height;
  final bool isCompact;

  const AnalyticsChart({
    super.key,
    required this.title,
    required this.data,
    required this.chartType,
    required this.height,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 14 : 16,
                ),
              ),
              SizedBox(height: isCompact ? 8 : 12),
            ],
            SizedBox(height: height, child: _buildChart(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    switch (chartType) {
      case ChartType.line:
        return _buildLineChart(context);
      case ChartType.bar:
        return _buildBarChart(context);
      case ChartType.pie:
        return _buildPieChart(context);
      case ChartType.area:
        return _buildAreaChart(context);
      case ChartType.donut:
        return _buildDonutChart(context);
    }
  }

  Widget _buildLineChart(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart(context);
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    return CustomPaint(
      painter: LineChartPainter(
        data: data,
        maxValue: maxValue,
        minValue: minValue,
        range: range,
        color: Theme.of(context).colorScheme.primary,
        isCompact: isCompact,
      ),
      child: Container(),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart(context);
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return CustomPaint(
      painter: BarChartPainter(
        data: data,
        maxValue: maxValue,
        color: Theme.of(context).colorScheme.primary,
        isCompact: isCompact,
      ),
      child: Container(),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart(context);
    }

    return CustomPaint(
      painter: PieChartPainter(
        data: data,
        colors: _getChartColors(context),
        isCompact: isCompact,
      ),
      child: Container(),
    );
  }

  Widget _buildAreaChart(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart(context);
    }

    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    return CustomPaint(
      painter: AreaChartPainter(
        data: data,
        maxValue: maxValue,
        minValue: minValue,
        range: range,
        color: Theme.of(context).colorScheme.primary,
        isCompact: isCompact,
      ),
      child: Container(),
    );
  }

  Widget _buildDonutChart(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart(context);
    }

    return CustomPaint(
      painter: DonutChartPainter(
        data: data,
        colors: _getChartColors(context),
        isCompact: isCompact,
      ),
      child: Container(),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.bar_chart_outline,
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
    );
  }

  List<Color> _getChartColors(BuildContext context) {
    return [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.green,
    ];
  }
}

// Custom Painters for different chart types
class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double maxValue;
  final double minValue;
  final double range;
  final Color color;
  final bool isCompact;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.minValue,
    required this.range,
    required this.color,
    required this.isCompact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = isCompact ? 2.0 : 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height - ((data[i].value - minValue) / range) * size.height;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, isCompact ? 3.0 : 4.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double maxValue;
  final Color color;
  final bool isCompact;

  BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.isCompact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final barWidth = size.width / data.length * 0.6;
    final spacing = size.width / data.length * 0.2;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i].value / maxValue) * size.height;
      final x = i * (barWidth + spacing) + spacing / 2;
      final y = size.height - barHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          Radius.circular(isCompact ? 2.0 : 4.0),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final List<Color> colors;
  final bool isCompact;

  PieChartPainter({
    required this.data,
    required this.colors,
    required this.isCompact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.fold(0.0, (sum, item) => sum + item.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width < size.height ? size.width : size.height) / 2 - 20;
    double startAngle = -90 * (3.14159 / 180);

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * 3.14159;
      final paint =
          Paint()
            ..color = colors[i % colors.length]
            ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AreaChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double maxValue;
  final double minValue;
  final double range;
  final Color color;
  final bool isCompact;

  AreaChartPainter({
    required this.data,
    required this.maxValue,
    required this.minValue,
    required this.range,
    required this.color,
    required this.isCompact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint =
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.fill;

    final strokePaint =
        Paint()
          ..color = color
          ..strokeWidth = isCompact ? 2.0 : 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y =
          size.height - ((data[i].value - minValue) / range) * size.height;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, size.height);
      path.lineTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.lineTo(points.last.dx, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DonutChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final List<Color> colors;
  final bool isCompact;

  DonutChartPainter({
    required this.data,
    required this.colors,
    required this.isCompact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.fold(0.0, (sum, item) => sum + item.value);
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius =
        (size.width < size.height ? size.width : size.height) / 2 - 20;
    final innerRadius = outerRadius * 0.6;
    double startAngle = -90 * (3.14159 / 180);

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * 3.14159;
      final paint =
          Paint()
            ..color = colors[i % colors.length]
            ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw inner circle to create donut effect
      final innerPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;

      canvas.drawCircle(center, innerRadius, innerPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
