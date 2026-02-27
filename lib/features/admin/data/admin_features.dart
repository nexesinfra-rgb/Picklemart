import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_features_repository.dart';
import '../../../core/providers/supabase_provider.dart';

class AdminFeatures {
  final bool infinityScrollEnabled;
  final bool infinityScrollProductsEnabled;
  final bool darkModeEnabled;
  final bool notificationsEnabled;
  final bool analyticsEnabled;
  final bool ratesEnabled;
  final bool starRatingsEnabled;
  final bool chatEnabled;
  final bool priceVisibilityEnabled;

  const AdminFeatures({
    this.infinityScrollEnabled = true,
    this.infinityScrollProductsEnabled = false,
    this.darkModeEnabled = false,
    this.notificationsEnabled = true,
    this.analyticsEnabled = true,
    this.ratesEnabled = true,
    this.starRatingsEnabled = true,
    this.chatEnabled = true,
    this.priceVisibilityEnabled = false,
  });

  /// Safely parse a boolean value from JSON
  /// Handles null, missing keys, string "true"/"false", and boolean values
  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value == null) {
      return defaultValue;
    }
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final lowerValue = value.toLowerCase().trim();
      if (lowerValue == 'true' || lowerValue == '1') {
        return true;
      }
      if (lowerValue == 'false' || lowerValue == '0') {
        return false;
      }
    }
    // For any other type, return default
    return defaultValue;
  }

  /// Create AdminFeatures from JSON map (from database)
  factory AdminFeatures.fromJson(Map<String, dynamic> json) {
    return AdminFeatures(
      infinityScrollEnabled: _parseBool(
        json['infinity_scroll_enabled'],
        true,
      ),
      infinityScrollProductsEnabled: _parseBool(
        json['infinity_scroll_products_enabled'],
        false,
      ),
      darkModeEnabled: _parseBool(
        json['dark_mode_enabled'],
        false,
      ),
      notificationsEnabled: _parseBool(
        json['notifications_enabled'],
        true,
      ),
      analyticsEnabled: _parseBool(
        json['analytics_enabled'],
        true,
      ),
      ratesEnabled: _parseBool(
        json['rates_enabled'],
        true,
      ),
      starRatingsEnabled: _parseBool(
        json['star_ratings_enabled'],
        true,
      ),
      chatEnabled: _parseBool(
        json['chat_enabled'],
        true,
      ),
      priceVisibilityEnabled: _parseBool(
        json['price_visibility_enabled'],
        false,
      ),
    );
  }

  /// Convert AdminFeatures to JSON map (for database)
  Map<String, dynamic> toJson() {
    return {
      'infinity_scroll_enabled': infinityScrollEnabled,
      'infinity_scroll_products_enabled': infinityScrollProductsEnabled,
      'dark_mode_enabled': darkModeEnabled,
      'notifications_enabled': notificationsEnabled,
      'analytics_enabled': analyticsEnabled,
      'rates_enabled': ratesEnabled,
      'star_ratings_enabled': starRatingsEnabled,
      'chat_enabled': chatEnabled,
      'price_visibility_enabled': priceVisibilityEnabled,
    };
  }

  AdminFeatures copyWith({
    bool? infinityScrollEnabled,
    bool? infinityScrollProductsEnabled,
    bool? darkModeEnabled,
    bool? notificationsEnabled,
    bool? analyticsEnabled,
    bool? ratesEnabled,
    bool? starRatingsEnabled,
    bool? chatEnabled,
    bool? priceVisibilityEnabled,
  }) {
    return AdminFeatures(
      infinityScrollEnabled:
          infinityScrollEnabled ?? this.infinityScrollEnabled,
      infinityScrollProductsEnabled:
          infinityScrollProductsEnabled ?? this.infinityScrollProductsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      ratesEnabled: ratesEnabled ?? this.ratesEnabled,
      starRatingsEnabled: starRatingsEnabled ?? this.starRatingsEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      priceVisibilityEnabled: priceVisibilityEnabled ?? this.priceVisibilityEnabled,
    );
  }
}

class AdminFeaturesNotifier extends StateNotifier<AdminFeatures> {
  final AdminFeaturesRepository _repository;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  AdminFeaturesNotifier(this._repository) : super(const AdminFeatures()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize default features if needed
      await _repository.initializeDefaultFeatures();

      // Load initial state from database
      final features = await _repository.getAllFeatures();
      state = AdminFeatures.fromJson(features);

      // Subscribe to real-time changes
      _subscription = _repository.subscribeToFeatures().listen(
        (features) {
          state = AdminFeatures.fromJson(features);
        },
        onError: (e) {
          // Handle error silently or log it
        },
      );
    } catch (e) {
      // If loading fails, use default values
      state = const AdminFeatures();
    }
  }

  Future<void> _updateFeature(String key, bool value) async {
    try {
      // Update database (optimistic update already done in toggle methods)
      await _repository.updateFeature(key, value);
      
      // State will be updated via real-time subscription
    } catch (e) {
      // Revert on error - reload from database
      try {
        final features = await _repository.getAllFeatures();
        state = AdminFeatures.fromJson(features);
      } catch (_) {
        // If reload fails, keep current state
      }
      rethrow;
    }
  }

  Future<void> toggleInfinityScroll() async {
    final newValue = !state.infinityScrollEnabled;
    state = state.copyWith(infinityScrollEnabled: newValue);
    await _updateFeature('infinity_scroll_enabled', newValue);
  }

  Future<void> toggleInfinityScrollProducts() async {
    final newValue = !state.infinityScrollProductsEnabled;
    state = state.copyWith(infinityScrollProductsEnabled: newValue);
    await _updateFeature('infinity_scroll_products_enabled', newValue);
  }

  Future<void> toggleDarkMode() async {
    final newValue = !state.darkModeEnabled;
    state = state.copyWith(darkModeEnabled: newValue);
    await _updateFeature('dark_mode_enabled', newValue);
  }

  Future<void> toggleNotifications() async {
    final newValue = !state.notificationsEnabled;
    state = state.copyWith(notificationsEnabled: newValue);
    await _updateFeature('notifications_enabled', newValue);
  }

  Future<void> toggleAnalytics() async {
    final newValue = !state.analyticsEnabled;
    state = state.copyWith(analyticsEnabled: newValue);
    await _updateFeature('analytics_enabled', newValue);
  }

  Future<void> toggleRates() async {
    final newValue = !state.ratesEnabled;
    state = state.copyWith(ratesEnabled: newValue);
    await _updateFeature('rates_enabled', newValue);
  }

  Future<void> toggleStarRatings() async {
    final newValue = !state.starRatingsEnabled;
    state = state.copyWith(starRatingsEnabled: newValue);
    await _updateFeature('star_ratings_enabled', newValue);
  }

  Future<void> toggleChat() async {
    final newValue = !state.chatEnabled;
    state = state.copyWith(chatEnabled: newValue);
    await _updateFeature('chat_enabled', newValue);
  }

  Future<void> togglePriceVisibility() async {
    final newValue = !state.priceVisibilityEnabled;
    state = state.copyWith(priceVisibilityEnabled: newValue);
    await _updateFeature('price_visibility_enabled', newValue);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final adminFeaturesRepositoryProvider =
    Provider<AdminFeaturesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AdminFeaturesRepository(supabase);
});

final adminFeaturesProvider =
    StateNotifierProvider<AdminFeaturesNotifier, AdminFeatures>(
      (ref) {
        final repository = ref.watch(adminFeaturesRepositoryProvider);
        return AdminFeaturesNotifier(repository);
      },
    );
