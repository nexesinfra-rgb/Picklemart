import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive.dart';
import '../../data/analytics_models.dart';

class RealTimeMetricsWidget extends ConsumerStatefulWidget {
  final RealTimeMetrics realTime;

  const RealTimeMetricsWidget({super.key, required this.realTime});

  @override
  ConsumerState<RealTimeMetricsWidget> createState() =>
      _RealTimeMetricsWidgetState();
}

class _RealTimeMetricsWidgetState extends ConsumerState<RealTimeMetricsWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);
    final isCompact = bp == AppBreakpoint.compact;
    final isMobile = width < 600;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(
                        Ionicons.pulse_outline,
                        color: Colors.red,
                        size: isCompact ? 16 : 20,
                      ),
                    );
                  },
                ),
                SizedBox(width: isCompact ? 8 : 12),
                Text(
                  'Real-time Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 14 : 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 6 : 8,
                    vertical: isCompact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 8 : 10,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 16),
            if (isMobile) ...[
              _buildMobileMetrics(context, isCompact),
            ] else ...[
              _buildDesktopMetrics(context, isCompact),
            ],
            SizedBox(height: isCompact ? 12 : 16),
            _buildLiveUsersSection(context, isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMetrics(BuildContext context, bool isCompact) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                'Active Users',
                widget.realTime.currentActiveUsers.toString(),
                Ionicons.people_outline,
                Colors.blue,
                isCompact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricItem(
                context,
                'Sessions',
                widget.realTime.currentSessions.toString(),
                Ionicons.desktop_outline,
                Colors.green,
                isCompact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                context,
                'Orders',
                widget.realTime.currentOrders.toString(),
                Ionicons.receipt_outline,
                Colors.orange,
                isCompact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricItem(
                context,
                'Cart Adds',
                widget.realTime.currentCartAdditions.toString(),
                Ionicons.cart_outline,
                Colors.purple,
                isCompact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopMetrics(BuildContext context, bool isCompact) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricItem(
            context,
            'Active Users',
            widget.realTime.currentActiveUsers.toString(),
            Ionicons.people_outline,
            Colors.blue,
            isCompact,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricItem(
            context,
            'Sessions',
            widget.realTime.currentSessions.toString(),
            Ionicons.desktop_outline,
            Colors.green,
            isCompact,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricItem(
            context,
            'Orders',
            widget.realTime.currentOrders.toString(),
            Ionicons.receipt_outline,
            Colors.orange,
            isCompact,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricItem(
            context,
            'Cart Adds',
            widget.realTime.currentCartAdditions.toString(),
            Ionicons.cart_outline,
            Colors.purple,
            isCompact,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricItem(
            context,
            'Product Views',
            widget.realTime.currentProductViews.toString(),
            Ionicons.eye_outline,
            Colors.teal,
            isCompact,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isCompact ? 16 : 20),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 16 : 20,
              color: color,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isCompact ? 9 : 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveUsersSection(BuildContext context, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Users',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
        SizedBox(height: isCompact ? 8 : 12),
        ...widget.realTime.liveUsers
            .take(3)
            .map(
              (user) => Padding(
                padding: EdgeInsets.only(bottom: isCompact ? 4 : 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isCompact ? 12 : 16,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: Icon(
                        Ionicons.person_outline,
                        size: isCompact ? 12 : 16,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: isCompact ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontSize: isCompact ? 11 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.currentPage,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontSize: isCompact ? 9 : 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 4 : 6,
                        vertical: isCompact ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
                      ),
                      child: Text(
                        _formatLastActivity(user.lastActivity),
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: isCompact ? 8 : 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (widget.realTime.liveUsers.length > 3) ...[
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            '+${widget.realTime.liveUsers.length - 3} more users',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isCompact ? 9 : 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  String _formatLastActivity(DateTime lastActivity) {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
