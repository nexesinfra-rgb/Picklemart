import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../domain/customer_browsing_analytics.dart';
import 'widgets/admin_auth_guard.dart';
import '../../../core/layout/responsive.dart';

class CustomerProductViewDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final ProductViewSession product;

  const CustomerProductViewDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.product,
  });

  @override
  ConsumerState<CustomerProductViewDetailScreen> createState() =>
      _CustomerProductViewDetailScreenState();
}

class _CustomerProductViewDetailScreenState
    extends ConsumerState<CustomerProductViewDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        body: _buildMainContent(context),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = Responsive.getResponsivePadding(width);
        final sectionSpacing = Responsive.getSectionSpacing(width);
        final isMobile = Responsive.isMobile(width);
        final isTablet = Responsive.isTablet(width);
        final isDesktop = Responsive.isDesktop(width);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: isDesktop
                ? Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, width),
                          SizedBox(height: sectionSpacing),
                          _buildProductOverviewCard(context, width),
                          SizedBox(height: sectionSpacing),
                          _buildViewingSessions(context, width),
                          SizedBox(height: sectionSpacing),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, width),
                        SizedBox(height: sectionSpacing),
                        _buildProductOverviewCard(context, width),
                        SizedBox(height: sectionSpacing),
                        _buildViewingSessions(context, width),
                        SizedBox(height: sectionSpacing),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, double width) {
    final isMobile = Responsive.isMobile(width);
    final spacing = Responsive.getResponsiveSpacing(width);

    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/customers');
            }
          },
          icon: const Icon(Ionicons.arrow_back),
          style: IconButton.styleFrom(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product View Details',
                style: isMobile
                    ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )
                    : Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.customerName} - ${widget.product.productName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductOverviewCard(BuildContext context, double width) {
    final isMobile = Responsive.isMobile(width);
    final isTablet = Responsive.isTablet(width);
    final cardPadding = Responsive.getCardPadding(width);
    final spacing = Responsive.getResponsiveSpacing(width);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: isMobile
            ? _buildMobileProductLayout(context, width, spacing)
            : _buildDesktopProductLayout(context, width, spacing),
      ),
    );
  }

  Widget _buildMobileProductLayout(
      BuildContext context, double width, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Product Image
        Center(
          child: _buildProductImage(
            widget.product.productImage,
            width * 0.6,
            isHero: true,
          ),
        ),
        SizedBox(height: spacing),
        // Product Info
        _buildProductInfo(context, width),
        SizedBox(height: spacing),
        // Stats Section
        _buildStatsSection(context, width),
      ],
    );
  }

  Widget _buildDesktopProductLayout(
      BuildContext context, double width, double spacing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        _buildProductImage(
          widget.product.productImage,
          width < 1024 ? 160 : 200,
          isHero: false,
        ),
        SizedBox(width: spacing),
        // Product Info and Stats
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductInfo(context, width),
              SizedBox(height: spacing),
              _buildStatsSection(context, width),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(BuildContext context, double width) {
    final isMobile = Responsive.isMobile(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.productName,
          style: isMobile
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${widget.product.productPrice.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, double width) {
    final isMobile = Responsive.isMobile(width);
    final spacing = Responsive.getResponsiveSpacing(width);

    final avgTime = widget.product.viewCount > 0
        ? Duration(
            milliseconds: widget.product.duration.inMilliseconds ~/
                widget.product.viewCount,
          )
        : Duration.zero;

    if (isMobile) {
      // Mobile: 2 columns grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Views',
                  widget.product.viewCount.toString(),
                  Ionicons.eye_outline,
                  Colors.blue,
                  width,
                ),
              ),
              SizedBox(width: spacing * 0.75),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Time',
                  _formatDuration(widget.product.duration),
                  Ionicons.time_outline,
                  Colors.orange,
                  width,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 0.75),
          _buildStatItem(
            context,
            'Avg. Time/View',
            _formatDuration(avgTime),
            Ionicons.timer_outline,
            Colors.purple,
            width,
          ),
        ],
      );
    } else {
      // Tablet/Desktop: Horizontal row
      return Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Total Views',
              widget.product.viewCount.toString(),
              Ionicons.eye_outline,
              Colors.blue,
              width,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildStatItem(
              context,
              'Total Time',
              _formatDuration(widget.product.duration),
              Ionicons.time_outline,
              Colors.orange,
              width,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildStatItem(
              context,
              'Avg. Time/View',
              _formatDuration(avgTime),
              Ionicons.timer_outline,
              Colors.purple,
              width,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    final isMobile = Responsive.isMobile(width);
    final padding = isMobile ? 12.0 : 16.0;
    final iconSize = isMobile ? 20.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: isMobile ? 18 : 22,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: isMobile ? 11 : 12,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildViewingSessions(BuildContext context, double width) {
    final sessions = _generateMockViewingSessions();
    final isMobile = Responsive.isMobile(width);
    final spacing = Responsive.getResponsiveSpacing(width);

    if (sessions.isEmpty) {
      return _buildEmptySessionsState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viewing Sessions',
          style: isMobile
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
        ),
        SizedBox(height: spacing),
        ...sessions.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < sessions.length - 1 ? spacing : 0,
            ),
            child: _buildSessionCard(context, session, width),
          );
        }),
      ],
    );
  }

  Widget _buildEmptySessionsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.eye_off_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No viewing sessions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
      BuildContext context, ViewingSession session, double width) {
    final isMobile = Responsive.isMobile(width);
    final cardPadding = Responsive.getCardPadding(width);
    final spacing = Responsive.getResponsiveSpacing(width);
    final sessionColor = _getSessionColor(session.duration);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showSessionDetails(context, session),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: isMobile
              ? _buildMobileSessionLayout(context, session, sessionColor, spacing)
              : _buildDesktopSessionLayout(context, session, sessionColor, spacing),
        ),
      ),
    );
  }

  Widget _buildMobileSessionLayout(
    BuildContext context,
    ViewingSession session,
    Color sessionColor,
    double spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: sessionColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Ionicons.play_circle_outline,
                color: sessionColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Session ${session.sessionNumber}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      _buildDurationChip(
                        context,
                        _formatDuration(session.duration),
                        sessionColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(session.startTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1),
        const SizedBox(height: 12),
        _buildSessionMetadata(context, session, spacing),
      ],
    );
  }

  Widget _buildDesktopSessionLayout(
    BuildContext context,
    ViewingSession session,
    Color sessionColor,
    double spacing,
  ) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: sessionColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Ionicons.play_circle_outline,
            color: sessionColor,
            size: 28,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Session ${session.sessionNumber}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 12),
                  _buildDurationChip(
                    context,
                    _formatDuration(session.duration),
                    sessionColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDateTime(session.startTime)} - ${_formatDateTime(session.endTime)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 8),
              _buildSessionMetadata(context, session, spacing),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showSessionDetails(context, session),
          icon: const Icon(Ionicons.information_circle_outline),
          tooltip: 'View Details',
        ),
      ],
    );
  }

  Widget _buildSessionMetadata(
      BuildContext context, ViewingSession session, double spacing) {
    return Wrap(
      spacing: spacing,
      runSpacing: 8,
      children: [
        _buildMetadataChip(
          context,
          Ionicons.phone_portrait_outline,
          session.deviceInfo,
        ),
        _buildMetadataChip(
          context,
          Ionicons.globe_outline,
          session.browserInfo,
        ),
      ],
    );
  }

  Widget _buildMetadataChip(
      BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(BuildContext context, String duration, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        duration,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSessionDetails(BuildContext context, ViewingSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session ${session.sessionNumber} Details'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Duration', _formatDuration(session.duration)),
                _buildDetailRow('Start Time', _formatDateTime(session.startTime)),
                _buildDetailRow('End Time', _formatDateTime(session.endTime)),
                _buildDetailRow('Device', session.deviceInfo),
                _buildDetailRow('Browser', session.browserInfo),
                _buildDetailRow('IP Address', session.ipAddress),
                _buildDetailRow('Location', session.location),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, double size, {bool isHero = false}) {
    Widget placeholder() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(isHero ? 20 : 16),
          ),
          child: Icon(
            Ionicons.image_outline,
            size: size * 0.3,
            color: Colors.grey.shade400,
          ),
        );

    if (imageUrl.isEmpty) return placeholder();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isHero ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isHero ? 20 : 16),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(isHero ? 20 : 16),
              ),
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
        ),
      ),
    );
  }

  Color _getSessionColor(Duration duration) {
    if (duration.inMinutes >= 10) {
      return Colors.green;
    } else if (duration.inMinutes >= 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatDuration(Duration duration) {
    // Ensure duration is always positive (defensive coding for edge cases)
    final absDuration = duration.isNegative ? duration.abs() : duration;
    
    if (absDuration.inHours > 0) {
      return '${absDuration.inHours}h ${absDuration.inMinutes.remainder(60)}m';
    } else if (absDuration.inMinutes > 0) {
      return '${absDuration.inMinutes}m ${absDuration.inSeconds.remainder(60)}s';
    } else {
      return '${absDuration.inSeconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  List<ViewingSession> _generateMockViewingSessions() {
    final now = DateTime.now();
    return [
      ViewingSession(
        sessionNumber: 1,
        startTime: now.subtract(const Duration(minutes: 45)),
        endTime: now.subtract(const Duration(minutes: 30)),
        duration: const Duration(minutes: 15),
        deviceInfo: 'iPhone 13 Pro',
        browserInfo: 'Safari 16.0',
        ipAddress: '192.168.1.100',
        location: 'Mumbai, India',
      ),
      ViewingSession(
        sessionNumber: 2,
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1, minutes: 45)),
        duration: const Duration(minutes: 15),
        deviceInfo: 'MacBook Pro',
        browserInfo: 'Chrome 118.0',
        ipAddress: '192.168.1.101',
        location: 'Mumbai, India',
      ),
      ViewingSession(
        sessionNumber: 3,
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now.subtract(const Duration(days: 1, minutes: -5)),
        duration: const Duration(minutes: 5),
        deviceInfo: 'Samsung Galaxy S23',
        browserInfo: 'Chrome Mobile',
        ipAddress: '192.168.1.102',
        location: 'Mumbai, India',
      ),
    ];
  }
}

class ViewingSession {
  final int sessionNumber;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final String deviceInfo;
  final String browserInfo;
  final String ipAddress;
  final String location;

  const ViewingSession({
    required this.sessionNumber,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.deviceInfo,
    required this.browserInfo,
    required this.ipAddress,
    required this.location,
  });
}
