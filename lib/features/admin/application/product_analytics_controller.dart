import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/product_analytics_repository.dart';

class UserCount {
  final String label; // user id or 'Unknown'
  final String? email;
  final String? phone;
  final int count;
  UserCount(this.label, this.count, {this.email, this.phone});
}

class DateCount {
  final String label; // dd/MM/yyyy
  final int count;
  DateCount(this.label, this.count);
}

class AreaCount {
  final String label; // city/area
  final int count;
  AreaCount(this.label, this.count);
}

class ProductAnalyticsState {
  final bool isLoading;
  final String? error;
  final List<UserCount> viewsByUser;
  final List<UserCount> ordersByUser;
  final List<DateCount> ordersByDate;
  final List<AreaCount> ordersByArea;
  final int totalViews;
  final int totalOrders;

  const ProductAnalyticsState({
    this.isLoading = false,
    this.error,
    this.viewsByUser = const [],
    this.ordersByUser = const [],
    this.ordersByDate = const [],
    this.ordersByArea = const [],
    this.totalViews = 0,
    this.totalOrders = 0,
  });

  ProductAnalyticsState copyWith({
    bool? isLoading,
    String? error,
    List<UserCount>? viewsByUser,
    List<UserCount>? ordersByUser,
    List<DateCount>? ordersByDate,
    List<AreaCount>? ordersByArea,
    int? totalViews,
    int? totalOrders,
  }) {
    return ProductAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      viewsByUser: viewsByUser ?? this.viewsByUser,
      ordersByUser: ordersByUser ?? this.ordersByUser,
      ordersByDate: ordersByDate ?? this.ordersByDate,
      ordersByArea: ordersByArea ?? this.ordersByArea,
      totalViews: totalViews ?? this.totalViews,
      totalOrders: totalOrders ?? this.totalOrders,
    );
  }
}

class ProductAnalyticsController
    extends StateNotifier<ProductAnalyticsState> {
  final ProductAnalyticsRepository _repo;

  ProductAnalyticsController(this._repo)
      : super(const ProductAnalyticsState());

  Future<void> load(String productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final views = await _repo.fetchViews(productId);
      final orders = await _repo.fetchOrders(productId);

      String userLabel({
        String? name,
        String? email,
        String? phone,
        String? id,
      }) {
        if (name != null && name.isNotEmpty) return name;
        if (email != null && email.isNotEmpty) return email;
        if (phone != null && phone.isNotEmpty) return phone;
        return 'Unknown';
      }

      // Aggregate views by user with profile data
      Map<String, Map<String, dynamic>> aggregateUserCountsViews() {
        final map = <String, Map<String, dynamic>>{};
        for (final v in views) {
          final key = userLabel(
            name: v.userName,
            email: v.userEmail,
            phone: v.userPhone,
            id: v.userId,
          );
          final entry = map.putIfAbsent(key, () {
            return {
              'count': 0,
              'email': v.userEmail,
              'phone': v.userPhone,
            };
          });
          entry['count'] = (entry['count'] as int) + 1;
        }
        return map;
      }

      // Aggregate orders by user with profile data
      Map<String, Map<String, dynamic>> aggregateUserCountsOrders() {
        final map = <String, Map<String, dynamic>>{};
        for (final o in orders) {
          final key = userLabel(
            name: o.userName,
            email: o.userEmail,
            phone: o.userPhone,
            id: o.userId,
          );
          final entry = map.putIfAbsent(key, () {
            return {
              'count': 0,
              'email': o.userEmail,
              'phone': o.userPhone,
            };
          });
          entry['count'] = (entry['count'] as int) + 1;
        }
        return map;
      }

      Map<String, int> countByDate(Iterable<DateTime> dates) {
        final map = <String, int>{};
        for (final d in dates) {
          final label =
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
          map[label] = (map[label] ?? 0) + 1;
        }
        return map;
      }

      Map<String, int> countByArea(
        Iterable<Map<String, String?>> locations,
      ) {
        final map = <String, int>{};
        for (final loc in locations) {
          final area = loc['area'];
          final city = loc['city'];
          final label = [
            if (area != null && area.isNotEmpty) area,
            if (city != null && city.isNotEmpty) city,
          ].join(', ');
          final key = label.isEmpty ? 'Unknown' : label;
          map[key] = (map[key] ?? 0) + 1;
        }
        return map;
      }

      final viewsByUserMap = aggregateUserCountsViews().entries.toList()
        ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));
      final ordersByUserMap = aggregateUserCountsOrders().entries.toList()
        ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));
      final ordersByDateMap =
          countByDate(orders.map((o) => o.orderedAt)).entries.toList()
            ..sort((a, b) => b.key.compareTo(a.key));
      final ordersByAreaMap = countByArea(orders.map((o) => {
                'area': o.area,
                'city': o.city,
              })).entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      state = state.copyWith(
        isLoading: false,
        viewsByUser:
            viewsByUserMap
                .map((e) => UserCount(
                      e.key,
                      e.value['count'] as int,
                      email: e.value['email'] as String?,
                      phone: e.value['phone'] as String?,
                    ))
                .toList(),
        ordersByUser:
            ordersByUserMap
                .map((e) => UserCount(
                      e.key,
                      e.value['count'] as int,
                      email: e.value['email'] as String?,
                      phone: e.value['phone'] as String?,
                    ))
                .toList(),
        ordersByDate:
            ordersByDateMap.map((e) => DateCount(e.key, e.value)).toList(),
        ordersByArea:
            ordersByAreaMap.map((e) => AreaCount(e.key, e.value)).toList(),
        totalViews: views.length,
        totalOrders: orders.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final productAnalyticsControllerProvider = StateNotifierProvider.family<
    ProductAnalyticsController, ProductAnalyticsState, String>((ref, productId) {
  final repo = ref.watch(productAnalyticsRepositoryProvider);
  final controller = ProductAnalyticsController(repo);
  controller.load(productId);
  return controller;
});

