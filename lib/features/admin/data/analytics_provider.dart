import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_models.dart';
import '../../../core/providers/supabase_provider.dart';

// Analytics Provider
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsData?>((ref) {
      return AnalyticsNotifier();
    });

// Analytics Filter Provider
final analyticsFilterProvider = StateProvider<AnalyticsFilter>((ref) {
  return const AnalyticsFilter(period: AnalyticsPeriod.today);
});

// Real-time Analytics Provider
final realTimeAnalyticsProvider =
    StateNotifierProvider<RealTimeAnalyticsNotifier, RealTimeMetrics>((ref) {
      return RealTimeAnalyticsNotifier(ref);
    });

class AnalyticsNotifier extends StateNotifier<AnalyticsData?> {
  AnalyticsNotifier() : super(null);

  void refreshData() {
    // No-op for now: this notifier is currently unused.
    // It is kept only for backwards compatibility.
  }

  void updateFilter(AnalyticsFilter filter) {
    // No-op for now: filters are handled in AdminAnalyticsController.
  }
}

class RealTimeAnalyticsNotifier extends StateNotifier<RealTimeMetrics> {
  final Ref _ref;
  Timer? _timer;

  RealTimeAnalyticsNotifier(this._ref)
      : super(
          const RealTimeMetrics(
            currentActiveUsers: 0,
            currentSessions: 0,
            currentOrders: 0,
            currentCartAdditions: 0,
            currentProductViews: 0,
            liveUsers: [],
            liveOrders: [],
          ),
        ) {
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    // Poll Supabase every 10 seconds for updated metrics
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshMetrics();
    });
    // Load immediately
    _refreshMetrics();
  }

  Future<void> _refreshMetrics() async {
    try {
      final supabase = _ref.read(supabaseClientProvider);
      final now = DateTime.now().toUtc();
      final todayStart = DateTime.utc(now.year, now.month, now.day);
      final sessionWindowStart = now.subtract(const Duration(minutes: 15));
      final ordersWindowStart = now.subtract(const Duration(days: 7));

      // 1) Active Users: distinct users with sessions started today
      final sessionsTodayResponse = await supabase
          .from('user_sessions')
          .select('user_id')
          .gte('started_at', todayStart.toIso8601String());

      final activeUserIds = <String>{};
      for (final row in sessionsTodayResponse) {
        final userId = row['user_id'];
        if (userId is String && userId.isNotEmpty) {
          activeUserIds.add(userId);
        }
      }
          var currentActiveUsers = activeUserIds.length;

      // 2) Current Sessions: active sessions in last 15 minutes
      final activeSessionsResponse = await supabase
          .from('user_sessions')
          .select('id')
          .eq('is_active', true)
          .gte('last_activity_at', sessionWindowStart.toIso8601String());

      var currentSessions = 0;
      currentSessions = activeSessionsResponse.length;
    
      // 3) Current Orders: confirmed/processing in last 7 days
      final currentOrdersResponse = await supabase
          .from('orders')
          .select('id')
          .or('status.eq.confirmed,status.eq.processing')
          .gte('created_at', ordersWindowStart.toIso8601String());

      var currentOrders = 0;
      currentOrders = currentOrdersResponse.length;
    
      // Fallback for Active Users if no sessions today:
      if (currentActiveUsers == 0) {
        // Fallback 1: distinct users who placed orders today
        final ordersTodayResponse = await supabase
            .from('orders')
            .select('user_id')
            .gte('created_at', todayStart.toIso8601String());

        final orderUserIds = <String>{};
        for (final row in ordersTodayResponse) {
          final userId = row['user_id'];
          if (userId is String && userId.isNotEmpty) {
            orderUserIds.add(userId);
          }
        }
              currentActiveUsers = orderUserIds.length;

        // Fallback 2: if still zero, count users who viewed products today
        if (currentActiveUsers == 0) {
          final viewsTodayResponse = await supabase
              .from('product_views')
              .select('user_id')
              .gte('viewed_at', todayStart.toIso8601String());

          final viewUserIds = <String>{};
          for (final row in viewsTodayResponse) {
            final userId = row['user_id'];
            if (userId is String && userId.isNotEmpty) {
              viewUserIds.add(userId);
            }
          }
                  currentActiveUsers = viewUserIds.length;
        }
      }

      state = RealTimeMetrics(
        currentActiveUsers: currentActiveUsers,
        currentSessions: currentSessions,
        currentOrders: currentOrders,
        // Cart and product view metrics will be wired when those analytics are added
        currentCartAdditions: state.currentCartAdditions,
        currentProductViews: state.currentProductViews,
        liveUsers: state.liveUsers,
        liveOrders: state.liveOrders,
      );
    } catch (e) {
      // Swallow errors to avoid breaking the UI; keep last known good state.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
