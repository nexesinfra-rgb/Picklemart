import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';
import 'cash_book_repository.dart';
import '../domain/cash_book_entry.dart';

class PaymentReceipt {
  final String id;
  final String? orderId;
  final String customerId;
  final String receiptNumber;
  final DateTime paymentDate;
  final double amount;
  final String paymentType;
  final String? description;
  final String? attachmentUrl;
  final String createdBy;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final String? orderNumber;

  const PaymentReceipt({
    required this.id,
    this.orderId,
    required this.customerId,
    required this.receiptNumber,
    required this.paymentDate,
    required this.amount,
    required this.paymentType,
    this.description,
    this.attachmentUrl,
    required this.createdBy,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.orderNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId,
      'receipt_number': receiptNumber,
      'payment_date': paymentDate.toIso8601String(),
      'amount': amount,
      'payment_type': paymentType,
      'description': description,
      'attachment_url': attachmentUrl,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static PaymentReceipt fromJson(Map<String, dynamic> json) {
    // Extract customer details if available from joined query
    String? customerName;
    String? customerPhone;
    String? orderNumber;

    if (json['profiles'] != null) {
      final profile = json['profiles'];
      if (profile is Map<String, dynamic>) {
        customerName = profile['name'] as String?;
        customerPhone = profile['mobile'] as String?;
      }
    }

    if (json['orders'] != null) {
      final order = json['orders'];
      if (order is Map<String, dynamic>) {
        orderNumber = order['order_number'] as String?;
      }
    }

    return PaymentReceipt(
      id: json['id'] as String,
      orderId: json['order_id'] as String?,
      customerId: json['customer_id'] as String,
      receiptNumber: json['receipt_number'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      paymentType: json['payment_type'] as String,
      description: json['description'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      customerName: customerName,
      customerPhone: customerPhone,
      orderNumber: orderNumber,
    );
  }
}

class PaymentReceiptRepository {
  final SupabaseClient _supabase;
  final CashBookRepository? _cashBookRepository;

  PaymentReceiptRepository(this._supabase, [this._cashBookRepository]);

  /// Get total paid amount for an order
  Future<double> getTotalPaidForOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('payment_receipts')
          .select('amount, description')
          .eq('order_id', orderId);

      if (response.isEmpty) {
        return 0.0;
      }

      final payments = response as List<dynamic>;
      return payments.fold<double>(0.0, (sum, payment) {
        final amount = (payment['amount'] as num).toDouble();
        final description = payment['description'] as String?;
        final descUpper = (description ?? '').toUpperCase();
        final isRefund =
            descUpper.startsWith('REFUND') || descUpper.contains('PAYMENT OUT');

        return isRefund ? sum - amount : sum + amount;
      });
    } catch (e) {
      // Silently handle table not found errors - table may not exist yet
      // Only log if it's a different type of error
      final errorMessage = e.toString();
      if (!errorMessage.contains('Could not find the table') &&
          !errorMessage.contains('PGRST205')) {
        if (kDebugMode) {
          print('Error getting total paid for order: $e');
        }
      }
      // If table doesn't exist yet, return 0
      return 0.0;
    }
  }

  /// Get all payments for an order
  Future<List<PaymentReceipt>> getPaymentsForOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('payment_receipts')
          .select('*')
          .eq('order_id', orderId)
          .order('payment_date', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      return (response as List<dynamic>)
          .map((json) => PaymentReceipt.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Silently handle table not found errors - table may not exist yet
      final errorMessage = e.toString();
      if (!errorMessage.contains('Could not find the table') &&
          !errorMessage.contains('PGRST205')) {
        if (kDebugMode) {
          print('Error getting payments for order: $e');
        }
      }
      return [];
    }
  }

  /// Get total paid amount for all orders (bulk retrieval for efficiency)
  /// Returns a map of order_id -> total paid amount
  Future<Map<String, double>> getTotalPaidForAllOrders({
    List<String>? orderIds,
  }) async {
    try {
      var query = _supabase
          .from('payment_receipts')
          .select('order_id, amount, description');

      if (orderIds != null && orderIds.isNotEmpty) {
        query = query.inFilter('order_id', orderIds);
      } else {
        // If no orderIds provided, at least filter out null order_ids
        // to reduce data transfer if we only care about order-linked payments
        query = query.not('order_id', 'is', null);
      }

      final response = await query;

      if (response.isEmpty) {
        return {};
      }

      final payments = response as List<dynamic>;
      final paidByOrder = <String, double>{};

      for (final payment in payments) {
        final orderId = payment['order_id'] as String?;
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
        final description = payment['description'] as String?;
        final isRefund =
            description != null && description.startsWith('REFUND:');

        if (orderId != null) {
          final currentAmount = isRefund ? -amount : amount;
          paidByOrder[orderId] = (paidByOrder[orderId] ?? 0.0) + currentAmount;
        }
      }

      return paidByOrder;
    } catch (e) {
      // Silently handle table not found errors - table may not exist yet
      final errorMessage = e.toString();
      if (!errorMessage.contains('Could not find the table') &&
          !errorMessage.contains('PGRST205')) {
        if (kDebugMode) {
          print('Error getting total paid for all orders: $e');
        }
      }
      // If table doesn't exist yet, return empty map
      return {};
    }
  }

  /// Get total paid amount for all customers (bulk retrieval for efficiency)
  /// Returns a map of customer_id -> total paid amount
  Future<Map<String, double>> getTotalPaidForAllCustomers({
    List<String>? customerIds,
  }) async {
    try {
      var query = _supabase
          .from('payment_receipts')
          .select('customer_id, amount, description');

      if (customerIds != null && customerIds.isNotEmpty) {
        query = query.inFilter('customer_id', customerIds);
      }

      final response = await query;

      if (response.isEmpty) {
        return {};
      }

      final payments = response as List<dynamic>;
      final paidByCustomer = <String, double>{};

      for (final payment in payments) {
        final customerId = payment['customer_id'] as String?;
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
        final description = payment['description'] as String?;
        final descUpper = (description ?? '').toUpperCase();
        final isRefund =
            descUpper.startsWith('REFUND') || descUpper.contains('PAYMENT OUT');

        if (customerId != null) {
          final currentAmount = isRefund ? -amount : amount;
          paidByCustomer[customerId] =
              (paidByCustomer[customerId] ?? 0.0) + currentAmount;
        }
      }

      return paidByCustomer;
    } catch (e) {
      // Silently handle table not found errors - table may not exist yet
      final errorMessage = e.toString();
      if (!errorMessage.contains('Could not find the table') &&
          !errorMessage.contains('PGRST205')) {
        if (kDebugMode) {
          print('Error getting total paid for all customers: $e');
        }
      }
      return {};
    }
  }

  /// Get all payment receipts with pagination
  Future<List<PaymentReceipt>> getAllPaymentReceipts({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final startIndex = (page - 1) * limit;

    // Helper to apply filters to a query
    dynamic applyFilters(dynamic query) {
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Simple search on receipt number
        query = query.ilike('receipt_number', '%$searchQuery%');
      }

      if (startDate != null) {
        query = query.gte('payment_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('payment_date', endDate.toIso8601String());
      }

      return query
          .order('payment_date', ascending: false)
          .range(startIndex, startIndex + limit - 1);
    }

    try {
      // Try fetching with joins first
      var query = _supabase
          .from('payment_receipts')
          .select(
            '*, profiles!customer_id(name, mobile), orders(order_number)',
          );

      final response = await applyFilters(query);

      if (response.isEmpty) {
        return [];
      }

      return (response as List<dynamic>)
          .map((json) => PaymentReceipt.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all payment receipts with joins: $e');
        print('Falling back to simple query...');
      }

      try {
        // Fallback: Fetch without orders join
        var query = _supabase
            .from('payment_receipts')
            .select('*, profiles!customer_id(name, mobile)');

        final response = await applyFilters(query);

        if (response.isEmpty) {
          return [];
        }

        final receiptsData = response as List<dynamic>;

        // Manually fetch order numbers
        final orderIds =
            receiptsData
                .map((r) => r['order_id'] as String?)
                .where((id) => id != null)
                .toSet()
                .toList();

        final Map<String, String> orderNumberMap = {};
        if (orderIds.isNotEmpty) {
          try {
            // Fetch orders in chunks to avoid URL length limits if many orders
            final orders = await _supabase
                .from('orders')
                .select('id, order_number')
                .filter('id', 'in', '(${orderIds.join(',')})');

            for (final o in orders) {
              orderNumberMap[o['id'] as String] = o['order_number'] as String;
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching order numbers manually: $e');
            }
          }
        }

        return receiptsData.map((json) {
          final data = json as Map<String, dynamic>;
          // Inject order number
          final orderId = data['order_id'] as String?;
          if (orderId != null && orderNumberMap.containsKey(orderId)) {
            // Simulate the structure expected by fromJson
            data['orders'] = {'order_number': orderNumberMap[orderId]};
          }
          return PaymentReceipt.fromJson(data);
        }).toList();
      } catch (e2) {
        if (kDebugMode) {
          print('Error in fallback query: $e2');
        }
        rethrow;
      }
    }
  }

  /// Create a new payment receipt
  Future<PaymentReceipt> createPaymentReceipt({
    String? orderId,
    required String customerId,
    required String receiptNumber,
    required DateTime paymentDate,
    required double amount,
    required String paymentType,
    String? description,
    String? attachmentUrl,
    required String createdBy,
  }) async {
    try {
      // Get current user ID
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final paymentData = {
        'order_id': orderId,
        'customer_id': customerId,
        'receipt_number': receiptNumber,
        'payment_date': paymentDate.toIso8601String(),
        'amount': amount,
        'payment_type': paymentType,
        'description': description,
        'attachment_url': attachmentUrl,
        'created_by': createdBy,
      };

      final response =
          await _supabase
              .from('payment_receipts')
              .insert(paymentData)
              .select()
              .single();

      // Add to Cash Book if repository is available
      if (_cashBookRepository != null) {
        try {
          final isRefund =
              description != null && description.startsWith('REFUND:');

          await _cashBookRepository.addEntry(
            CashBookEntry(
              amount: amount,
              type:
                  isRefund ? CashBookEntryType.payout : CashBookEntryType.payin,
              category: isRefund ? 'Customer Refund' : 'Order Payment',
              description: description ?? 'Payment Receipt $receiptNumber',
              date: paymentDate,
              relatedId: response['id'],
              paymentMethod: paymentType,
              createdBy: createdBy,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error adding to cash book: $e');
          }
        }
      }

      return PaymentReceipt.fromJson(response);
    } catch (e) {
      final errorMessage = e.toString();

      // If table doesn't exist, show helpful message
      if (errorMessage.contains('Could not find the table') ||
          errorMessage.contains('PGRST205')) {
        if (kDebugMode) {
          print(
            'Payment receipts table does not exist. Please run migration: 048_create_payment_receipts_table.sql',
          );
        }
        throw Exception(
          'Payment receipts table not found. Please run the database migration first.',
        );
      }

      if (kDebugMode) {
        print('Error creating payment receipt: $e');
      }
      rethrow;
    }
  }

  /// Get payment receipts for a specific customer
  Future<List<PaymentReceipt>> getReceiptsByCustomer(
    String customerId, {
    int page = 1,
    int limit = 50,
  }) async {
    final startIndex = (page - 1) * limit;

    try {
      // Try fetching with joins
      final response = await _supabase
          .from('payment_receipts')
          .select('*, profiles!customer_id(name, mobile), orders(order_number)')
          .eq('customer_id', customerId)
          .order('payment_date', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      if ((response as List).isEmpty) {
        return [];
      }

      return (response as List<dynamic>)
          .map((json) => PaymentReceipt.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting receipts by customer: $e');
      }

      try {
        // Fallback: Fetch without joins
        final response = await _supabase
            .from('payment_receipts')
            .select('*')
            .eq('customer_id', customerId)
            .order('payment_date', ascending: false)
            .range(startIndex, startIndex + limit - 1);

        if ((response as List).isEmpty) {
          return [];
        }

        return (response as List<dynamic>)
            .map(
              (json) => PaymentReceipt.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } catch (e2) {
        if (kDebugMode) {
          print('Error in fallback receipts by customer query: $e2');
        }
        return [];
      }
    }
  }

  /// Update a payment receipt
  Future<bool> updatePaymentReceipt({
    required String id,
    double? amount,
    String? paymentType,
    String? description,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (amount != null) updates['amount'] = amount;
      if (paymentType != null) updates['payment_type'] = paymentType;
      if (description != null) updates['description'] = description;

      if (updates.isNotEmpty) {
        await _supabase.from('payment_receipts').update(updates).eq('id', id);
      }

      // Update customer name and phone if provided
      if (customerName != null || customerPhone != null) {
        // Get customer_id from receipt
        final receipt =
            await _supabase
                .from('payment_receipts')
                .select('customer_id')
                .eq('id', id)
                .single();

        final customerId = receipt['customer_id'] as String;

        final profileUpdates = <String, dynamic>{};
        if (customerName != null) profileUpdates['name'] = customerName;
        if (customerPhone != null) {
          // Clean the phone number before saving
          final cleanPhone = customerPhone.replaceAll(RegExp(r'[^\d]'), '');
          profileUpdates['mobile'] = cleanPhone;
          // Also update display_mobile or clear it to ensure the new number is shown
          profileUpdates['display_mobile'] = customerPhone;
        }

        if (profileUpdates.isNotEmpty) {
          await _supabase
              .from('profiles')
              .update(profileUpdates)
              .eq('id', customerId);
        }
      }

      // Also update Cash Book if repository is available
      if (_cashBookRepository != null) {
        try {
          // We need to fetch the cash book entry first to check if it exists
          // For now, we'll try to update by relatedId
          final cashBookUpdates = <String, dynamic>{};
          if (amount != null) cashBookUpdates['amount'] = amount;
          if (paymentType != null) {
            cashBookUpdates['payment_method'] = paymentType;
          }
          if (description != null) cashBookUpdates['description'] = description;

          if (cashBookUpdates.isNotEmpty) {
            await _cashBookRepository.updateEntryByRelatedId(
              id,
              cashBookUpdates,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error updating cash book: $e');
          }
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating payment receipt: $e');
      }
      return false;
    }
  }

  /// Delete a payment receipt
  Future<bool> deletePaymentReceipt(String id) async {
    try {
      await _supabase.from('payment_receipts').delete().eq('id', id);

      // Also delete from Cash Book
      if (_cashBookRepository != null) {
        try {
          await _cashBookRepository.deleteEntryByRelatedId(id);
        } catch (e) {
          if (kDebugMode) {
            print('Error deleting from cash book: $e');
          }
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting payment receipt: $e');
      }
      return false;
    }
  }
}

final paymentReceiptRepositoryProvider = Provider<PaymentReceiptRepository>((
  ref,
) {
  final supabase = ref.watch(supabaseClientProvider);
  final cashBookRepo = ref.watch(cashBookRepositoryProvider);
  return PaymentReceiptRepository(supabase, cashBookRepo);
});
