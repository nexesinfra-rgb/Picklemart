import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../application/admin_customer_controller.dart';
import '../../../core/config/environment.dart';
import '../../../core/utils/phone_utils.dart';
import 'customer_repository.dart';
import 'payment_receipt_repository.dart';

/// Supabase implementation of CustomerRepository
class CustomerRepositorySupabase implements CustomerRepository {
  final SupabaseClient _supabase;

  CustomerRepositorySupabase(this._supabase);

  @override
  Future<List<Customer>> getAllCustomers({int? page, int? pageSize}) async {
    // Backward compatibility: if no pagination params, return all customers
    if (page == null && pageSize == null) {
      return await _getAllCustomersInternal();
    }

    // If pagination params provided, use paginated method
    final result = await getAllCustomersPaginated(
      page: page ?? 1,
      pageSize: pageSize ?? 50,
    );
    return result.customers;
  }

  @override
  Future<PaginatedCustomersResult> getAllCustomersPaginated({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '🔍 getAllCustomersPaginated: Starting (page: $page, pageSize: $pageSize)...',
        );
      }

      // Limit statistics to a recent window to keep analytics queries fast
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      if (kDebugMode) {
        print(
          '🔍 getAllCustomersPaginated: Six months ago = ${sixMonthsAgo.toIso8601String()}',
        );
      }

      // Calculate pagination range (0-indexed)
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;

      // OPTIMIZATION 1: Get total count first using Supabase count option
      int totalCount = 0;
      try {
        if (kDebugMode) {
          print('🔍 getAllCustomersPaginated: Fetching total count...');
        }
        // Use count: CountOption.exact to get the actual total without fetching data
        final countResponse = await _supabase
            .from('profiles')
            .select('id')
            .neq('role', 'admin')
            .eq('is_deleted', false)
            .count(CountOption.exact);

        totalCount = countResponse.count ?? 0;

        if (kDebugMode) {
          print('✅ getAllCustomersPaginated: Total count = $totalCount');
        }
      } catch (e, st) {
        if (kDebugMode) {
          print('❌ getAllCustomersPaginated: ERROR in count query: $e');
          print('Stack trace: $st');
        }
        // If count fails, set to 0 - hasMore will be calculated based on page size
        totalCount = 0;
      }

      // OPTIMIZATION 2: Fetch only paginated profiles
      List<Map<String, dynamic>> profilesData;
      try {
        if (kDebugMode) {
          print(
            '🔍 getAllCustomersPaginated: Fetching paginated profiles ($from-$to)...',
          );
        }
        final profilesResponse = await _supabase
            .from('profiles')
            .select('*')
            .neq('role', 'admin')
            .order('created_at', ascending: false)
            .range(from, to);

        profilesData = List<Map<String, dynamic>>.from(profilesResponse);
        if (kDebugMode) {
          print(
            '✅ getAllCustomersPaginated: Profiles query successful - ${profilesData.length} profiles',
          );
        }
      } catch (e, st) {
        if (kDebugMode) {
          print('❌ getAllCustomersPaginated: ERROR in profiles query: $e');
          print('Stack trace: $st');
        }
        rethrow;
      }

      // Early return if no profiles
      if (profilesData.isEmpty) {
        return PaginatedCustomersResult(
          customers: [],
          totalCount: totalCount,
          page: page,
          pageSize: pageSize,
          hasMore: false,
        );
      }

      // OPTIMIZATION 3: Extract user IDs from paginated profiles only
      final userIds =
          profilesData
              .map((p) => p['id'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toList();

      // OPTIMIZATION 4: Fetch orders only for paginated users (major performance boost!)
      Map<String, Map<String, dynamic>> orderStatsByUserId;
      Map<String, double> paidByOrderId = {};
      Map<String, double> generalPaidByUserId = {};
      Map<String, DateTime?> lastPaymentDateByUserId = {};
      Map<String, String?> addressByUserId = {};
      try {
        if (kDebugMode) {
          print(
            '🔍 getAllCustomersPaginated: Fetching order statistics and addresses for ${userIds.length} users...',
          );
        }

        // Fetch addresses for the paginated users
        try {
          final addressesResponse = await _supabase
              .from('addresses')
              .select('user_id, address')
              .inFilter('user_id', userIds);

          final addressesData = List<Map<String, dynamic>>.from(
            addressesResponse,
          );
          for (final addr in addressesData) {
            final uid = addr['user_id'] as String?;
            if (uid != null) {
              addressByUserId[uid] = addr['address'] as String?;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ getAllCustomersPaginated: Error fetching addresses: $e');
          }
        }

        // Only fetch orders for the paginated user IDs (include id for balance calculation)
        final ordersResponse = await _supabase
            .from('orders')
            .select('id, user_id, total, created_at, status')
            .inFilter(
              'user_id',
              userIds,
            ) // KEY OPTIMIZATION: Only fetch for relevant users
            .gte('created_at', sixMonthsAgo.toIso8601String())
            .order('created_at', ascending: false);

        final ordersData = List<Map<String, dynamic>>.from(ordersResponse);
        if (kDebugMode) {
          print(
            '✅ getAllCustomersPaginated: Orders query successful - ${ordersData.length} orders',
          );
        }

        // Fetch payment totals for all orders in bulk
        try {
          if (kDebugMode) {
            print('🔍 getAllCustomersPaginated: Fetching payment totals...');
          }
          final orderIds =
              ordersData
                  .map((o) => o['id'] as String?)
                  .where((id) => id != null)
                  .cast<String>()
                  .toList();

          if (orderIds.isNotEmpty) {
            final paymentRepository = PaymentReceiptRepository(_supabase);
            final allPayments =
                await paymentRepository.getTotalPaidForAllOrders();
            // Filter to only orders we care about
            for (final orderId in orderIds) {
              paidByOrderId[orderId] = allPayments[orderId] ?? 0.0;
            }
          }

          // Fetch last payment date for each customer
          if (kDebugMode) {
            print(
              '🔍 getAllCustomersPaginated: Fetching last payment dates...',
            );
          }
          if (userIds.isNotEmpty) {
            try {
              final paymentDatesResponse = await _supabase
                  .from('payment_receipts')
                  .select('customer_id, payment_date')
                  .inFilter('customer_id', userIds)
                  .order('payment_date', ascending: false);

              final paymentDatesData = List<Map<String, dynamic>>.from(
                paymentDatesResponse,
              );

              // Group by customer_id and get the latest payment_date for each
              for (final payment in paymentDatesData) {
                final customerId = payment['customer_id'] as String?;
                if (customerId == null) continue;

                // Only store if we don't have a date yet, or if this one is more recent
                if (!lastPaymentDateByUserId.containsKey(customerId)) {
                  final paymentDateString = payment['payment_date'] as String?;
                  if (paymentDateString != null) {
                    try {
                      lastPaymentDateByUserId[customerId] = DateTime.parse(
                        paymentDateString,
                      );
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error parsing payment date: $e');
                      }
                    }
                  }
                }
              }

              if (kDebugMode) {
                print(
                  '✅ getAllCustomersPaginated: Last payment dates fetched for ${lastPaymentDateByUserId.length} customers',
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print(
                  '⚠️ getAllCustomersPaginated: Error fetching last payment dates (continuing without): $e',
                );
              }
              // Continue without last payment date if query fails
            }
          }

          if (kDebugMode) {
            print(
              '✅ getAllCustomersPaginated: Payment totals fetched for ${paidByOrderId.length} orders',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '⚠️ getAllCustomersPaginated: Error fetching payments (continuing without balance): $e',
            );
          }
          // Continue without balance calculation if payments fail
        }

        // Fetch general payments (where order_id is null) for these users
        // These are payments made directly to customer account, not linked to specific orders
        try {
          if (userIds.isNotEmpty) {
            if (kDebugMode) {
              print(
                '🔍 getAllCustomersPaginated: Fetching general payments...',
              );
            }
            final generalPaymentsResponse = await _supabase
                .from('payment_receipts')
                .select('customer_id, amount, description')
                .isFilter('order_id', null)
                .inFilter('customer_id', userIds);

            final generalPayments = List<Map<String, dynamic>>.from(
              generalPaymentsResponse,
            );

            for (final payment in generalPayments) {
              final customerId = payment['customer_id'] as String;
              final amount = (payment['amount'] as num).toDouble();

              // Handle Refunds (Payment Out)
              // If description starts with REFUND:, it means we paid the customer.
              // In the balance formula (Balance = Total Orders - Total Paid),
              // a refund should REDUCE the Total Paid (making it negative payment),
              // which effectively INCREASES the balance (debt).
              final description = payment['description'] as String? ?? '';
              final descUpper = description.toUpperCase();
              final isRefund =
                  descUpper.startsWith('REFUND') ||
                  descUpper.contains('PAYMENT OUT');
              final effectiveAmount = isRefund ? -amount : amount;

              generalPaidByUserId[customerId] =
                  (generalPaidByUserId[customerId] ?? 0.0) + effectiveAmount;
            }

            if (kDebugMode) {
              print(
                '✅ getAllCustomersPaginated: Fetched general payments for ${generalPaidByUserId.length} users',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '⚠️ getAllCustomersPaginated: Error fetching general payments: $e',
            );
          }
        }

        // Aggregate order statistics in a single pass for efficiency
        orderStatsByUserId = <String, Map<String, dynamic>>{};

        // Pre-filter orders to exclude pending ones (processing status)
        // so they don't count towards customer spending stats until converted to sale
        final completedOrders =
            ordersData.where((order) {
              final status = order['status'] as String?;
              return status != 'processing' && status != 'cancelled';
            }).toList();

        for (final order in completedOrders) {
          final userId = order['user_id'] as String?;
          if (userId == null) continue;

          final stats = orderStatsByUserId.putIfAbsent(
            userId,
            () => <String, dynamic>{
              'totalOrders': 0,
              'totalSpent': 0.0,
              'totalBalance': 0.0,
              'lastOrderDate': null as DateTime?,
            },
          );

          // Increment order count
          final currentOrders = (stats['totalOrders'] as int?) ?? 0;
          stats['totalOrders'] = currentOrders + 1;

          // Add to total spent
          final orderTotal = (order['total'] as num?)?.toDouble() ?? 0.0;
          final currentSpent = (stats['totalSpent'] as num?)?.toDouble() ?? 0.0;
          stats['totalSpent'] = currentSpent + orderTotal;

          // Calculate balance for this order and add to total balance
          final orderId = order['id'] as String?;
          final totalPaid =
              orderId != null ? (paidByOrderId[orderId] ?? 0.0) : 0.0;
          final effectiveTotal = orderTotal;
          final orderBalance = effectiveTotal - totalPaid;
          if (orderBalance > 0) {
            final currentBalance =
                (stats['totalBalance'] as num?)?.toDouble() ?? 0.0;
            stats['totalBalance'] = currentBalance + orderBalance;
          }

          // Track latest order date (orders are already sorted DESC by created_at)
          if (stats['lastOrderDate'] == null) {
            final createdAtString = order['created_at'] as String?;
            if (createdAtString != null) {
              try {
                stats['lastOrderDate'] = DateTime.parse(createdAtString);
              } catch (e) {
                if (kDebugMode) {
                  print('Error parsing order date: $e');
                }
              }
            }
          }
        }

        if (kDebugMode) {
          print(
            '✅ getAllCustomersPaginated: Aggregated order stats for ${orderStatsByUserId.length} users',
          );
        }
      } catch (e, st) {
        if (kDebugMode) {
          print('❌ getAllCustomersPaginated: ERROR in orders query: $e');
          print('Stack trace: $st');
        }
        rethrow;
      }

      // Convert profiles to customers with pre-calculated order statistics
      if (kDebugMode) {
        print(
          '🔍 getAllCustomersPaginated: Converting profiles to customers...',
        );
      }
      final customers = <Customer>[];
      for (final profileData in profilesData) {
        final userId = profileData['id'] as String? ?? '';
        final stats = orderStatsByUserId[userId];

        // Get statistics from pre-aggregated data
        final totalOrders = (stats?['totalOrders'] as num?)?.toInt() ?? 0;
        final totalSpent = (stats?['totalSpent'] as num?)?.toDouble() ?? 0.0;
        var totalBalance = (stats?['totalBalance'] as num?)?.toDouble() ?? 0.0;

        // Subtract general payments from balance
        // Balance = (Order Totals - Order Payments) - General Payments
        final generalPaid = generalPaidByUserId[userId] ?? 0.0;
        totalBalance -= generalPaid;

        final lastOrderDate = stats?['lastOrderDate'] as DateTime?;

        // Get email from profile (email is stored in profiles table)
        final email = profileData['email'] as String? ?? '';

        // Get GST number from profile
        final gstNumber = profileData['gst_number'] as String?;

        // Get address from address map
        final address = addressByUserId[userId];

        // Get phone/mobile
        final phone =
            profileData['mobile'] as String? ??
            profileData['display_mobile'] as String? ??
            '';

        // Parse dates
        final createdAtString = profileData['created_at'] as String?;
        final createdAt =
            createdAtString != null
                ? DateTime.parse(createdAtString)
                : DateTime.now();

        // Get last payment date for this customer
        final lastPaymentDate = lastPaymentDateByUserId[userId];

        try {
          final priceVisibilityEnabled =
              profileData['price_visibility_enabled'] as bool? ?? false;
          final isActive = profileData['is_active'] as bool? ?? true;
          customers.add(
            Customer(
              id: userId,
              name: profileData['name'] as String? ?? '',
              alias: profileData['alias'] as String?,
              email: email,
              phone: phone,
              gstNumber: gstNumber,
              address: address,
              createdAt: createdAt,
              lastOrderDate: lastOrderDate,
              lastPaymentDate: lastPaymentDate,
              totalOrders: totalOrders,
              totalSpent: totalSpent,
              totalBalance: totalBalance,
              isActive: isActive,
              priceVisibilityEnabled: priceVisibilityEnabled,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print(
              '⚠️ getAllCustomersPaginated: Error processing profile $userId: $e',
            );
          }
          // Continue with next profile instead of failing completely
        }
      }

      // Sort customers by lastPaymentDate DESC (most recent first), then by created_at DESC
      customers.sort((a, b) {
        // Primary sort: by lastPaymentDate (most recent first, nulls last)
        if (a.lastPaymentDate == null && b.lastPaymentDate == null) {
          // Both null, sort by created_at DESC
          return b.createdAt.compareTo(a.createdAt);
        } else if (a.lastPaymentDate == null) {
          return 1; // a goes after b
        } else if (b.lastPaymentDate == null) {
          return -1; // a goes before b
        } else {
          // Both have dates, sort by lastPaymentDate DESC
          final paymentDateComparison = b.lastPaymentDate!.compareTo(
            a.lastPaymentDate!,
          );
          if (paymentDateComparison != 0) {
            return paymentDateComparison;
          }
          // If payment dates are equal, sort by created_at DESC
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      // Calculate hasMore: if we have totalCount, use it; otherwise, if we got a full page, assume more exists
      final hasMore =
          totalCount > 0
              ? from + customers.length < totalCount
              : customers.length ==
                  pageSize; // If count unavailable, assume more if we got full page

      if (kDebugMode) {
        print(
          '✅ getAllCustomersPaginated: Successfully created ${customers.length} customer objects',
        );
        print(
          '📊 Pagination: page $page, total: $totalCount, hasMore: $hasMore',
        );
      }

      return PaginatedCustomersResult(
        customers: customers,
        totalCount:
            totalCount, // Keep as 0 if count query failed - caller can handle this
        page: page,
        pageSize: pageSize,
        hasMore: hasMore,
      );
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ getAllCustomersPaginated: FATAL ERROR: $e');
        print('Stack trace: $st');
      }
      rethrow;
    }
  }

  // Private method for backward compatibility (original implementation)
  Future<List<Customer>> _getAllCustomersInternal() async {
    try {
      if (kDebugMode) {
        print('🔍 getAllCustomers: Starting (non-paginated)...');
      }

      // Limit statistics to a recent window to keep analytics queries fast
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      if (kDebugMode) {
        print(
          '🔍 getAllCustomers: Six months ago = ${sixMonthsAgo.toIso8601String()}',
        );
      }

      // Fetch all profiles with role='user' (customers)
      List<Map<String, dynamic>> profilesData;
      try {
        if (kDebugMode) {
          print('🔍 getAllCustomers: Fetching profiles from Supabase...');
        }
        final profilesResponse = await _supabase
            .from('profiles')
            .select('*')
            .neq('role', 'admin')
            .order('created_at', ascending: false);

        profilesData = List<Map<String, dynamic>>.from(profilesResponse);
        if (kDebugMode) {
          print(
            '✅ getAllCustomers: Profiles query successful - ${profilesData.length} profiles',
          );
        }
      } catch (e, st) {
        if (kDebugMode) {
          print('❌ getAllCustomers: ERROR in profiles query: $e');
          print('Stack trace: $st');
        }
        rethrow;
      }

      // Fetch aggregated order statistics per user using efficient in-memory processing
      // Note: This could be further optimized with a database function/RPC for true SQL aggregation
      // For now, we optimize by using efficient data structures and single-pass processing
      Map<String, Map<String, dynamic>> orderStatsByUserId;
      Map<String, double> paidByOrderId = {};
      Map<String, DateTime?> lastPaymentDateByUserId = {};
      try {
        if (kDebugMode) {
          print(
            '🔍 getAllCustomers: Fetching order statistics from Supabase...',
          );
        }
        final ordersResponse = await _supabase
            .from('orders')
            .select('id, user_id, total, created_at, status')
            .gte('created_at', sixMonthsAgo.toIso8601String())
            .order('created_at', ascending: false);

        final ordersData = List<Map<String, dynamic>>.from(ordersResponse);
        if (kDebugMode) {
          print(
            '✅ getAllCustomers: Orders query successful - ${ordersData.length} orders',
          );
        }

        // Fetch payment totals for all orders in bulk
        try {
          if (kDebugMode) {
            print('🔍 getAllCustomers: Fetching payment totals...');
          }
          final orderIds =
              ordersData
                  .map((o) => o['id'] as String?)
                  .where((id) => id != null)
                  .cast<String>()
                  .toList();

          if (orderIds.isNotEmpty) {
            final paymentRepository = PaymentReceiptRepository(_supabase);
            final allPayments =
                await paymentRepository.getTotalPaidForAllOrders();
            // Filter to only orders we care about
            for (final orderId in orderIds) {
              paidByOrderId[orderId] = allPayments[orderId] ?? 0.0;
            }
          }

          // Fetch last payment date for each customer
          if (kDebugMode) {
            print('🔍 getAllCustomers: Fetching last payment dates...');
          }
          // Extract all user IDs from profiles
          final allUserIds =
              profilesData
                  .map((p) => p['id'] as String?)
                  .where((id) => id != null)
                  .cast<String>()
                  .toList();

          if (allUserIds.isNotEmpty) {
            try {
              final paymentDatesResponse = await _supabase
                  .from('payment_receipts')
                  .select('customer_id, payment_date')
                  .inFilter('customer_id', allUserIds)
                  .order('payment_date', ascending: false);

              final paymentDatesData = List<Map<String, dynamic>>.from(
                paymentDatesResponse,
              );

              // Group by customer_id and get the latest payment_date for each
              for (final payment in paymentDatesData) {
                final customerId = payment['customer_id'] as String?;
                if (customerId == null) continue;

                // Only store if we don't have a date yet, or if this one is more recent
                if (!lastPaymentDateByUserId.containsKey(customerId)) {
                  final paymentDateString = payment['payment_date'] as String?;
                  if (paymentDateString != null) {
                    try {
                      lastPaymentDateByUserId[customerId] = DateTime.parse(
                        paymentDateString,
                      );
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error parsing payment date: $e');
                      }
                    }
                  }
                }
              }

              if (kDebugMode) {
                print(
                  '✅ getAllCustomers: Last payment dates fetched for ${lastPaymentDateByUserId.length} customers',
                );
              }
            } catch (e) {
              if (kDebugMode) {
                print(
                  '⚠️ getAllCustomers: Error fetching last payment dates (continuing without): $e',
                );
              }
              // Continue without last payment date if query fails
            }
          }

          if (kDebugMode) {
            print(
              '✅ getAllCustomers: Payment totals fetched for ${paidByOrderId.length} orders',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '⚠️ getAllCustomers: Error fetching payments (continuing without balance): $e',
            );
          }
          // Continue without balance calculation if payments fail
        }

        // Aggregate order statistics in a single pass for efficiency
        // This is more memory-efficient than storing all orders
        orderStatsByUserId = <String, Map<String, dynamic>>{};

        // Pre-filter orders to exclude pending ones (processing status)
        // so they don't count towards customer spending stats until converted to sale
        final completedOrders =
            ordersData.where((order) {
              final status = order['status'] as String?;
              return status != 'processing' && status != 'cancelled';
            }).toList();

        for (final order in completedOrders) {
          final userId = order['user_id'] as String?;
          if (userId == null) continue;

          final stats = orderStatsByUserId.putIfAbsent(
            userId,
            () => <String, dynamic>{
              'totalOrders': 0,
              'totalSpent': 0.0,
              'totalBalance': 0.0,
              'lastOrderDate': null as DateTime?,
            },
          );

          // Increment order count
          final currentOrders = (stats['totalOrders'] as int?) ?? 0;
          stats['totalOrders'] = currentOrders + 1;

          // Add to total spent
          final orderTotal = (order['total'] as num?)?.toDouble() ?? 0.0;
          final currentSpent = (stats['totalSpent'] as num?)?.toDouble() ?? 0.0;
          stats['totalSpent'] = currentSpent + orderTotal;

          // Calculate balance for this order and add to total balance
          final orderId = order['id'] as String?;
          final totalPaid =
              orderId != null ? (paidByOrderId[orderId] ?? 0.0) : 0.0;
          final effectiveTotal = orderTotal;
          final orderBalance = effectiveTotal - totalPaid;
          if (orderBalance > 0) {
            final currentBalance =
                (stats['totalBalance'] as num?)?.toDouble() ?? 0.0;
            stats['totalBalance'] = currentBalance + orderBalance;
          }

          // Track latest order date (orders are already sorted DESC by created_at)
          if (stats['lastOrderDate'] == null) {
            final createdAtString = order['created_at'] as String?;
            if (createdAtString != null) {
              try {
                stats['lastOrderDate'] = DateTime.parse(createdAtString);
              } catch (e) {
                if (kDebugMode) {
                  print('Error parsing order date: $e');
                }
              }
            }
          }
        }

        if (kDebugMode) {
          print(
            '✅ getAllCustomers: Aggregated order stats for ${orderStatsByUserId.length} users',
          );
        }
      } catch (e, st) {
        if (kDebugMode) {
          print('❌ getAllCustomers: ERROR in orders query: $e');
          print('Stack trace: $st');
        }
        rethrow;
      }

      // Convert profiles to customers with pre-calculated order statistics
      if (kDebugMode) {
        print('🔍 getAllCustomers: Converting profiles to customers...');
      }
      final customers = <Customer>[];
      for (final profileData in profilesData) {
        final userId = profileData['id'] as String? ?? '';
        final stats = orderStatsByUserId[userId];

        // Get statistics from pre-aggregated data
        final totalOrders = (stats?['totalOrders'] as num?)?.toInt() ?? 0;
        final totalSpent = (stats?['totalSpent'] as num?)?.toDouble() ?? 0.0;
        final totalBalance =
            (stats?['totalBalance'] as num?)?.toDouble() ?? 0.0;
        final lastOrderDate = stats?['lastOrderDate'] as DateTime?;

        // Get last payment date for this customer
        final lastPaymentDate = lastPaymentDateByUserId[userId];

        // Get email from profile (email is stored in profiles table)
        final email = profileData['email'] as String? ?? '';

        // Get phone/mobile
        final phone =
            profileData['mobile'] as String? ??
            profileData['display_mobile'] as String? ??
            '';

        // Parse dates
        final createdAtString = profileData['created_at'] as String?;
        final createdAt =
            createdAtString != null
                ? DateTime.parse(createdAtString)
                : DateTime.now();

        try {
          final priceVisibilityEnabled =
              profileData['price_visibility_enabled'] as bool? ?? false;
          final isActive = profileData['is_active'] as bool? ?? true;
          customers.add(
            Customer(
              id: userId,
              name: profileData['name'] as String? ?? '',
              alias: profileData['alias'] as String?, // Can be enhanced later
              email: email,
              phone: phone,
              createdAt: createdAt,
              lastOrderDate: lastOrderDate,
              lastPaymentDate: lastPaymentDate,
              totalOrders: totalOrders,
              totalSpent: totalSpent,
              totalBalance: totalBalance,
              isActive: isActive,
              priceVisibilityEnabled: priceVisibilityEnabled,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ getAllCustomers: Error processing profile $userId: $e');
          }
          // Continue with next profile instead of failing completely
        }
      }

      // Sort customers by lastPaymentDate DESC (most recent first), then by created_at DESC
      customers.sort((a, b) {
        // Primary sort: by lastPaymentDate (most recent first, nulls last)
        if (a.lastPaymentDate == null && b.lastPaymentDate == null) {
          // Both null, sort by created_at DESC
          return b.createdAt.compareTo(a.createdAt);
        } else if (a.lastPaymentDate == null) {
          return 1; // a goes after b
        } else if (b.lastPaymentDate == null) {
          return -1; // a goes before b
        } else {
          // Both have dates, sort by lastPaymentDate DESC
          final paymentDateComparison = b.lastPaymentDate!.compareTo(
            a.lastPaymentDate!,
          );
          if (paymentDateComparison != 0) {
            return paymentDateComparison;
          }
          // If payment dates are equal, sort by created_at DESC
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      if (kDebugMode) {
        print(
          '✅ getAllCustomers: Successfully created ${customers.length} customer objects',
        );
      }
      return customers;
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ getAllCustomers: FATAL ERROR: $e');
        print('Stack trace: $st');
      }
      rethrow;
    }
  }

  @override
  Stream<List<Customer>> subscribeToCustomers() {
    final controller = StreamController<List<Customer>>();

    // Initial fetch
    getAllCustomers()
        .then((customers) {
          if (!controller.isClosed) {
            if (kDebugMode) {
              print(
                '📊 CustomerRepositorySupabase: initial getAllCustomers returned ${customers.length} customers',
              );
            }
            controller.add(customers);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            if (kDebugMode) {
              print(
                '❌ CustomerRepositorySupabase: error in initial getAllCustomers: $error',
              );
            }
            controller.addError(error);
          }
        });

    // Subscribe to real-time changes in profiles table only
    // Orders subscription removed - orders are handled by sharedOrdersProvider
    // Customer stats will update when profiles change (which triggers getAllCustomers)
    final profilesSubscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .neq('role', 'admin')
        .listen(
          (profilesData) async {
            try {
              // When profiles change, refetch all customers with updated order stats
              // Note: getAllCustomers() is already optimized with efficient aggregation,
              // so this is reasonably performant. Further optimization could update
              // only changed customers incrementally, but would require maintaining
              // state in the repository.
              final customers = await getAllCustomers();
              if (!controller.isClosed) {
                if (kDebugMode) {
                  print(
                    '📊 CustomerRepositorySupabase: profiles change triggered getAllCustomers -> ${customers.length} customers',
                  );
                }
                controller.add(customers);
              }
            } catch (e) {
              if (!controller.isClosed) {
                if (kDebugMode) {
                  print(
                    '❌ CustomerRepositorySupabase: error refreshing customers after profile change: $e',
                  );
                }
                controller.addError(e);
              }
            }
          },
          onError: (error) {
            // Log error but don't crash the stream if it's a realtime connection error
            if (kDebugMode) {
              print('Supabase Realtime Error (Customers): $error');
            }
            // Suppress error to keep UI stable
          },
        );

    // Cancel subscription when stream is closed
    controller.onCancel = () {
      profilesSubscription.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> updateCustomerPriceVisibility(
    String customerId,
    bool enabled,
  ) async {
    try {
      await _supabase
          .from('profiles')
          .update({'price_visibility_enabled': enabled})
          .eq('id', customerId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating customer price visibility: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateCustomerStatus(String customerId, bool isActive) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', customerId);
    } on PostgrestException catch (e) {
      // Fallback: If is_active column is missing, ignore the error
      if (e.message.contains('is_active') ||
          e.details?.toString().contains('is_active') == true ||
          e.message.contains('Could not find the') // General schema error
          ) {
        if (kDebugMode) {
          print(
            '⚠️ Warning: is_active column missing. Skipping status update. Error: ${e.message}',
          );
        }
        return;
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating customer status: $e');
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createCustomerAccount({
    required String name,
    required String mobile,
    required String password,
    String? gstNumber,
  }) async {
    try {
      // Validate mobile number format
      if (!PhoneUtils.isValidMobile(mobile)) {
        throw Exception('Invalid mobile number format. Must be 10 digits.');
      }

      // Validate password length
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }

      // Get current session access token for authentication
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Not authenticated. Please log in as admin.');
      }

      final accessToken = session.accessToken;

      // Build edge function URL
      final functionUrl =
          '${Environment.supabaseUrl}/functions/v1/create-customer-account';

      // Prepare request payload
      final payload = <String, dynamic>{
        'name': name.trim(),
        'mobile': mobile,
        'password': password,
      };

      // Add GST number if provided
      if (gstNumber != null && gstNumber.trim().isNotEmpty) {
        payload['gstNumber'] =
            gstNumber.trim().replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
      }

      // Call edge function
      final response = await http
          .post(
            Uri.parse(functionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              'apikey': Environment.supabaseAnonKey,
            },
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 30));

      final responseBody = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Customer account created successfully');
        }
        return responseBody;
      } else {
        // Try RPC fallback if Edge Function fails (e.g. 500 Internal Server Error)
        // This is useful if the Edge Function is not deployed or misconfigured
        try {
          if (kDebugMode) {
            print(
              '⚠️ Edge Function failed with status ${response.statusCode}. Attempting RPC fallback...',
            );
          }
          final rpcResponse = await _supabase.rpc(
            'create_customer_account_rpc',
            params: {
              'name': name.trim(),
              'mobile': mobile,
              'password': password,
              'gst_number':
                  gstNumber
                      ?.trim()
                      .replaceAll(RegExp(r'[\s-]'), '')
                      .toUpperCase(),
            },
          );
          if (kDebugMode) {
            print('✅ Customer account created via RPC fallback');
          }
          return rpcResponse as Map<String, dynamic>;
        } catch (rpcError) {
          if (kDebugMode) {
            print('❌ RPC fallback failed: $rpcError');
          }
          // Continue to throw the original error if RPC fails (likely not installed)
        }

        String errorMessage =
            responseBody['error'] as String? ??
            'Failed to create customer account';

        // Append details if available and not already part of the error message
        final details = responseBody['details'] as String?;
        if (details != null &&
            details.isNotEmpty &&
            details != errorMessage &&
            !errorMessage.contains(details)) {
          errorMessage = '$errorMessage: $details';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating customer account: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateCustomer({
    required String id,
    String? name,
    String? alias,
    String? phone,
    String? email,
    String? gstNumber,
    String? address,
    bool? isActive,
    String? password,
  }) async {
    try {
      // 1. Update Profile and Address
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (alias != null) updates['alias'] = alias;
      if (phone != null) updates['mobile'] = phone;
      if (email != null) updates['email'] = email;
      if (gstNumber != null) updates['gst_number'] = gstNumber;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', id);
      }

      if (address != null) {
        final existingAddress =
            await _supabase
                .from('addresses')
                .select('id')
                .eq('user_id', id)
                .maybeSingle();

        if (existingAddress != null) {
          final addressUpdates = <String, dynamic>{
            'address': address,
            'updated_at': DateTime.now().toIso8601String(),
          };
          if (name != null) addressUpdates['name'] = name;
          if (phone != null) addressUpdates['phone'] = phone;

          await _supabase
              .from('addresses')
              .update(addressUpdates)
              .eq('user_id', id);
        } else {
          // Fetch profile to get name and phone if they aren't provided in the call
          String finalName = name ?? '';
          String finalPhone = phone ?? '';

          if (finalName.isEmpty || finalPhone.isEmpty) {
            final profile =
                await _supabase
                    .from('profiles')
                    .select('name, mobile')
                    .eq('id', id)
                    .single();
            if (finalName.isEmpty) finalName = profile['name'] ?? 'N/A';
            if (finalPhone.isEmpty) finalPhone = profile['mobile'] ?? 'N/A';
          }

          await _supabase.from('addresses').insert({
            'user_id': id,
            'name': finalName,
            'phone': finalPhone,
            'address': address,
            'city': 'N/A',
            'state': 'N/A',
            'pincode': '000000',
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // 2. Update Auth User if sensitive fields are provided (via Edge Function)
      if ((password != null && password.isNotEmpty) ||
          phone != null ||
          name != null) {
        final session = _supabase.auth.currentSession;
        if (session == null) throw Exception('Not authenticated');

        final accessToken = session.accessToken;
        final functionUrl =
            '${Environment.supabaseUrl}/functions/v1/update-customer-account';

        final payload = <String, dynamic>{'userId': id};
        if (password != null && password.isNotEmpty) {
          payload['password'] = password;
        }
        if (phone != null) payload['mobile'] = phone;
        if (name != null) payload['name'] = name;

        final response = await http
            .post(
              Uri.parse(functionUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
                'apikey': Environment.supabaseAnonKey,
              },
              body: json.encode(payload),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          final body = json.decode(response.body);
          throw Exception(body['error'] ?? 'Failed to update auth account');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating customer: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      // SOFT DELETE IMPLEMENTATION
      // Instead of deleting the auth user and profile (which causes cascading delete of orders),
      // we mark the profile as deleted and inactive. This preserves order history.

      // 1. Soft delete the profile (set is_deleted = true, is_active = false)
      await _supabase
          .from('profiles')
          .update({'is_deleted': true, 'is_active': false})
          .eq('id', id);

      // 2. Verify update (optional, but good practice)
      final check =
          await _supabase
              .from('profiles')
              .select('is_deleted')
              .eq('id', id)
              .maybeSingle();

      if (check == null || check['is_deleted'] != true) {
        throw Exception(
          'Failed to soft delete customer: Database update failed.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting customer: $e');
      }
      rethrow;
    }
  }

  /// Get summary metrics for customers (optimized for dashboard)
  @override
  Future<Map<String, dynamic>> getCustomerMetrics() async {
    try {
      if (kDebugMode) {
        print('🔍 getCustomerMetrics: Starting optimized calculation...');
      }

      // 1. Get total customer count efficiently
      final countResponse = await _supabase
          .from('profiles')
          .select('id')
          .neq('role', 'admin')
          .count(CountOption.exact);

      final totalCustomers = countResponse.count;

      // 2. Get total balance (Sum of all orders - Sum of all payments)
      // Note: We only count completed orders for balance
      final ordersResponse = await _supabase
          .from('orders')
          .select('total')
          .neq('status', 'processing')
          .neq('status', 'cancelled');

      final totalOrderAmount = (ordersResponse as List).fold<double>(
        0.0,
        (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0.0),
      );

      final paymentsResponse = await _supabase
          .from('payment_receipts')
          .select('amount, description');

      final totalPaidAmount = (paymentsResponse as List).fold<double>(0.0, (
        sum,
        payment,
      ) {
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
        final description = (payment['description'] as String? ?? '');
        final descUpper = description.toUpperCase();
        final isRefund =
            descUpper.startsWith('REFUND') || descUpper.contains('PAYMENT OUT');
        // Subtract refunds from total paid (effectively increasing balance)
        return sum + (isRefund ? -amount : amount);
      });

      final totalBalance = totalOrderAmount - totalPaidAmount;

      if (kDebugMode) {
        print(
          '✅ getCustomerMetrics: Count=$totalCustomers, Balance=$totalBalance',
        );
      }

      return {'totalCustomers': totalCustomers, 'totalBalance': totalBalance};
    } catch (e) {
      if (kDebugMode) {
        print('❌ getCustomerMetrics: ERROR: $e');
      }
      return {'totalCustomers': 0, 'totalBalance': 0.0};
    }
  }
}
