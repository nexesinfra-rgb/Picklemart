import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/environment.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/customer_browsing_analytics.dart';

/// Repository interface for customer browsing analytics
abstract class CustomerBrowsingRepository {
  Future<CustomerBrowsingAnalytics> getCustomerBrowsingAnalytics(
    String customerId, {
    String? customerName,
    String? customerEmail,
  });
  Stream<CustomerBrowsingAnalytics> subscribeToCustomerBrowsingAnalytics(
    String customerId, {
    String? customerName,
    String? customerEmail,
  });
}

/// Supabase implementation of CustomerBrowsingRepository
class CustomerBrowsingRepositorySupabase implements CustomerBrowsingRepository {
  final SupabaseClient _supabase;

  CustomerBrowsingRepositorySupabase(this._supabase);

  /// Fix image URL by replacing old domain with new one
  String _fixImageUrl(String url) {
    if (url.isEmpty) return url;

    // Replace old sslip.io domain with new custom domain
    const oldDomain =
        'supabasekong-ogw8kswcww8swko0c8gswsks.72.62.229.227.sslip.io';
    if (url.contains(oldDomain)) {
      // Use the configured Supabase URL from environment
      final baseUrl = Environment.supabaseUrl;

      // Handle both http and https in the old URL
      if (url.startsWith('http://$oldDomain')) {
        return url.replaceFirst('http://$oldDomain', baseUrl);
      } else if (url.startsWith('https://$oldDomain')) {
        return url.replaceFirst('https://$oldDomain', baseUrl);
      } else {
        // Fallback for partial matches
        return url.replaceAll(
          oldDomain,
          baseUrl.replaceFirst('https://', '').replaceFirst('http://', ''),
        );
      }
    }
    return url;
  }

  @override
  Future<CustomerBrowsingAnalytics> getCustomerBrowsingAnalytics(
    String customerId, {
    String? customerName,
    String? customerEmail,
  }) async {
    try {
      // Get customer profile info (optional, use provided values if available)
      String finalCustomerName = customerName ?? 'Unknown';
      String finalCustomerEmail = customerEmail ?? '';

      // Only query profile if name/email not provided
      if (customerName == null || customerEmail == null) {
        try {
          final profileResponse =
              await _supabase
                  .from('profiles')
                  .select('id, name, email')
                  .eq('id', customerId)
                  .maybeSingle();

          if (profileResponse != null) {
            finalCustomerName =
                profileResponse['name'] as String? ?? customerName ?? 'Unknown';
            finalCustomerEmail =
                profileResponse['email'] as String? ?? customerEmail ?? '';
          }
        } catch (e) {
          // If profile query fails, use provided values or defaults
          // This allows analytics to still load even if profile query fails
          if (customerName == null) finalCustomerName = 'Unknown';
          if (customerEmail == null) finalCustomerEmail = '';
        }
      }

      // Get product views for this customer
      // Handle case where product_views table doesn't exist yet
      List<Map<String, dynamic>> viewsResponse;
      try {
        // Select viewed_at (primary field) and started_at if it exists
        viewsResponse = await _supabase
            .from('product_views')
            .select(
              'id, product_id, viewed_at, started_at, ended_at, duration_seconds, user_id',
            )
            .eq('user_id', customerId)
            .order('viewed_at', ascending: false);
      } catch (e) {
        // If table doesn't exist (PGRST205 error), return empty analytics
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('product_views') ||
            errorString.contains('pgrst205') ||
            errorString.contains('could not find the table') ||
            errorString.contains('does not exist')) {
          return CustomerBrowsingAnalytics(
            customerId: customerId,
            customerName: finalCustomerName,
            customerEmail: finalCustomerEmail,
            productViews: [],
            lastViewedAt: DateTime.now(),
            totalBrowsingTime: Duration.zero,
            totalProductsViewed: 0,
            totalViewSessions: 0,
          );
        }
        // Re-throw other errors
        rethrow;
      }

      // Get unique product IDs
      final productIds =
          viewsResponse
              .map((v) => v['product_id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .toSet()
              .toList();

      // Fetch product details
      final productsMap = <String, Map<String, dynamic>>{};
      if (productIds.isNotEmpty) {
        final productsResponse = await _supabase
            .from('products')
            .select('id, name, image_url, price')
            .inFilter('id', productIds);

        for (final product in productsResponse) {
          final id = product['id'] as String?;
          if (id != null) {
            productsMap[id] = product;
          }
        }
      }

      final viewsData = List<Map<String, dynamic>>.from(viewsResponse);

      // Group views by product_id to create sessions
      final productViewMap = <String, List<Map<String, dynamic>>>{};
      for (final view in viewsData) {
        final productId = view['product_id'] as String? ?? '';
        if (productId.isNotEmpty) {
          productViewMap.putIfAbsent(productId, () => []).add(view);
        }
      }

      // Convert to ProductViewSession objects
      final productViews = <ProductViewSession>[];
      for (final entry in productViewMap.entries) {
        final productId = entry.key;
        final views = entry.value;

        if (views.isEmpty) continue;

        // Get product info
        final productData = productsMap[productId];
        final productName =
            productData?['name'] as String? ?? 'Unknown Product';
        final productImage = _fixImageUrl(
          productData?['image_url'] as String? ?? '',
        );
        final productPrice = (productData?['price'] as num?)?.toDouble() ?? 0.0;

        // Calculate session times
        final viewTimes =
            views.map((v) {
                // Use viewed_at as primary, fallback to started_at if viewed_at doesn't exist
                final viewedAt = v['viewed_at'] as String?;
                final startedAt = v['started_at'] as String?;
                final timeStr = viewedAt ?? startedAt;
                if (timeStr != null) {
                  return DateTime.parse(timeStr);
                }
                return DateTime.now();
              }).toList()
              ..sort();

        final startTime = viewTimes.first;
        final endTime = viewTimes.last;

        // Calculate total duration with live calculation for active views
        final now = DateTime.now();
        final totalDurationSeconds = views.fold<int>(0, (sum, view) {
          final storedDuration = view['duration_seconds'] as int?;
          final endedAt = view['ended_at'] as String?;

          // Ensure stored duration is never negative
          final safeStoredDuration =
              (storedDuration != null && storedDuration > 0)
                  ? storedDuration
                  : 0;

          // If view has ended_at or has a stored duration > 0, use stored duration
          if (endedAt != null || safeStoredDuration > 0) {
            return sum + safeStoredDuration;
          }

          // For active views (no ended_at and duration is 0/null), calculate live duration
          // BUT only if the view is recent (within last 2 hours) to avoid huge durations
          final viewedAt = view['viewed_at'] as String?;
          final startedAt = view['started_at'] as String?;
          final timeStr = viewedAt ?? startedAt;
          if (timeStr != null) {
            try {
              final viewStartTime = DateTime.parse(timeStr);
              final timeSinceView = now.difference(viewStartTime);

              // Only calculate live duration for views within the last 2 hours
              // This prevents old views from showing massive durations
              if (timeSinceView.inHours < 2) {
                final liveDuration = timeSinceView.inSeconds;
                // Ensure duration is never negative and cap at 2 hours (7200 seconds)
                final positiveDuration = liveDuration > 0 ? liveDuration : 0;
                final cappedDuration =
                    positiveDuration > 7200 ? 7200 : positiveDuration;
                return sum + cappedDuration;
              } else {
                // For old views, just use stored duration (which is 0)
                return sum + safeStoredDuration;
              }
            } catch (_) {
              // If parsing fails, use stored duration or 0
              return sum + safeStoredDuration;
            }
          }

          // Fallback to stored duration or 0
          return sum + safeStoredDuration;
        });

        // Final safety check: ensure totalDurationSeconds is never negative
        final safeTotalDurationSeconds =
            totalDurationSeconds > 0 ? totalDurationSeconds : 0;

        productViews.add(
          ProductViewSession(
            productId: productId,
            productName: productName,
            productImage:
                productImage.isNotEmpty
                    ? productImage
                    : 'assets/placeholder.png',
            productPrice: productPrice,
            startTime: startTime,
            endTime: endTime,
            duration: Duration(seconds: safeTotalDurationSeconds),
            viewCount: views.length,
          ),
        );
      }

      // Calculate aggregate statistics
      final lastViewedAt =
          productViews.isNotEmpty
              ? productViews
                  .map((v) => v.endTime)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : DateTime.now();

      final totalBrowsingTime = productViews.fold<Duration>(
        Duration.zero,
        (total, view) => total + view.duration,
      );

      final totalProductsViewed = productViews.length;
      final totalViewSessions = productViews.fold<int>(
        0,
        (total, view) => total + view.viewCount,
      );

      return CustomerBrowsingAnalytics(
        customerId: customerId,
        customerName: finalCustomerName,
        customerEmail: finalCustomerEmail,
        productViews: productViews,
        lastViewedAt: lastViewedAt,
        totalBrowsingTime: totalBrowsingTime,
        totalProductsViewed: totalProductsViewed,
        totalViewSessions: totalViewSessions,
      );
    } catch (e) {
      throw Exception('Failed to fetch customer browsing analytics: $e');
    }
  }

  @override
  Stream<CustomerBrowsingAnalytics> subscribeToCustomerBrowsingAnalytics(
    String customerId, {
    String? customerName,
    String? customerEmail,
  }) {
    final controller = StreamController<CustomerBrowsingAnalytics>();

    // Initial fetch to ensure data is displayed even if realtime fails
    getCustomerBrowsingAnalytics(
          customerId,
          customerName: customerName,
          customerEmail: customerEmail,
        )
        .then((analytics) {
          if (!controller.isClosed) {
            controller.add(analytics);
          }
        })
        .catchError((e) {
          if (!controller.isClosed) {
            // Only add error if it's not a table missing error (which returns empty analytics in getCustomerBrowsingAnalytics)
            controller.addError(e);
          }
        });

    try {
      final subscription = _supabase
          .from('product_views')
          .stream(primaryKey: ['id'])
          .listen(
            (data) async {
              try {
                // Check if any changes are for this customer
                final hasRelevantChanges = data.any((item) {
                  final userId = item['user_id'] as String?;
                  return userId == customerId;
                });

                // Only reload if there are changes for this customer, or if it's the first load via stream
                if (hasRelevantChanges || data.isEmpty) {
                  final analytics = await getCustomerBrowsingAnalytics(
                    customerId,
                    customerName: customerName,
                    customerEmail: customerEmail,
                  );
                  if (!controller.isClosed) {
                    controller.add(analytics);
                  }
                }
              } catch (e) {
                if (!controller.isClosed) {
                  controller.addError(e);
                }
              }
            },
            onError: (error) {
              // Log error but don't crash the stream if it's a realtime connection error
              final errorString = error.toString().toLowerCase();
              if (errorString.contains('product_views') ||
                  errorString.contains('pgrst205') ||
                  errorString.contains('could not find the table') ||
                  errorString.contains('does not exist')) {
                // Table doesn't exist, we can ignore this for stream as initial fetch handles it
                return;
              }

              if (kDebugMode) {
                print('Supabase Realtime Error (Customer Browsing): $error');
              }
              // Suppress error to keep UI stable
            },
          );

      controller.onCancel = () {
        subscription.cancel();
      };
    } catch (e) {
      // If immediate stream creation fails (e.g. table doesn't exist), we already did initial fetch
      if (kDebugMode) {
        print('Supabase Stream Creation Error (Customer Browsing): $e');
      }
    }

    return controller.stream;
  }
}

/// Provider for customer browsing repository
final customerBrowsingRepositoryProvider = Provider<CustomerBrowsingRepository>(
  (ref) {
    final supabase = ref.watch(supabaseClientProvider);
    return CustomerBrowsingRepositorySupabase(supabase);
  },
);
