import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../domain/credit_transaction.dart';

class CreditTransactionRepository {
  final SupabaseClient _supabase;

  CreditTransactionRepository(this._supabase);

  /// Get all credit transactions with optional filters and pagination
  Future<List<CreditTransaction>> getCreditTransactions({
    String? manufacturerId,
    String? entityName,
    CreditTransactionType? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
    bool onlyManufacturers = false,
  }) async {
    try {
      final startIndex = (page - 1) * limit;
      dynamic query = _supabase.from('credit_transactions').select('''
            *,
            manufacturers:manufacturer_id (
              name,
              business_name
            )
          ''');

      if (manufacturerId != null) {
        query = query.eq('manufacturer_id', manufacturerId);
      }

      if (onlyManufacturers) {
        query = query.not('manufacturer_id', 'is', null);
      }

      if (entityName != null) {
        query = query.eq('entity_name', entityName);
      }

      if (transactionType != null) {
        query = query.eq('transaction_type', transactionType.name);
      }

      if (startDate != null) {
        query = query.gte('transaction_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('transaction_date', endDate.toIso8601String());
      }

      query = query
          .order('transaction_date', ascending: false)
          .range(startIndex, startIndex + limit - 1);

      final response = await query;

      return (response as List).map((json) {
        final transactionJson = json as Map<String, dynamic>;
        final manufacturerData =
            transactionJson['manufacturers'] as Map<String, dynamic>?;

        if (manufacturerData != null) {
          transactionJson['manufacturer_name'] =
              manufacturerData['name'] as String? ??
              manufacturerData['business_name'] as String?;
        }

        return CreditTransaction.fromSupabaseJson(transactionJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch credit transactions: $e');
    }
  }

  /// Get credit balance for an entity (manufacturer or personal expense)
  Future<ManufacturerCreditBalance> getEntityBalance({
    String? manufacturerId,
    String? entityName,
  }) async {
    try {
      String? entityDisplayName;

      if (manufacturerId != null) {
        // Get manufacturer name
        final manufacturerResponse =
            await _supabase
                .from('manufacturers')
                .select('name, business_name')
                .eq('id', manufacturerId)
                .single();

        entityDisplayName =
            manufacturerResponse['name'] as String? ??
            manufacturerResponse['business_name'] as String? ??
            'Unknown';
      } else if (entityName != null) {
        entityDisplayName = entityName;
      } else {
        throw Exception('Either manufacturerId or entityName must be provided');
      }

      // Build query based on identifier
      dynamic balanceQuery;
      if (manufacturerId != null) {
        balanceQuery = _supabase
            .from('credit_transactions')
            .select('balance_after, transaction_date')
            .eq('manufacturer_id', manufacturerId);
      } else {
        balanceQuery = _supabase
            .from('credit_transactions')
            .select('balance_after, transaction_date')
            .eq('entity_name', entityName!);
      }

      // Get latest transaction to get current balance
      final latestTransaction =
          await balanceQuery
              .order('transaction_date', ascending: false)
              .limit(1)
              .maybeSingle();

      final currentBalance =
          latestTransaction != null
              ? (latestTransaction['balance_after'] as num).toDouble()
              : 0.0;

      // Get totals
      dynamic payinQuery, payoutQuery;
      if (manufacturerId != null) {
        payinQuery = _supabase
            .from('credit_transactions')
            .select('amount')
            .eq('manufacturer_id', manufacturerId)
            .eq('transaction_type', 'payin');
        payoutQuery = _supabase
            .from('credit_transactions')
            .select('amount')
            .eq('manufacturer_id', manufacturerId)
            .eq('transaction_type', 'payout');
      } else {
        payinQuery = _supabase
            .from('credit_transactions')
            .select('amount')
            .eq('entity_name', entityName!)
            .eq('transaction_type', 'payin');
        payoutQuery = _supabase
            .from('credit_transactions')
            .select('amount')
            .eq('entity_name', entityName)
            .eq('transaction_type', 'payout');
      }

      final payinResponse = await payinQuery;
      final payoutResponse = await payoutQuery;

      final payinList = payinResponse as List;
      final payoutList = payoutResponse as List;

      final totalPayin = payinList.fold<double>(
        0.0,
        (sum, item) => sum + ((item['amount'] as num).toDouble()),
      );

      final totalPayout = payoutList.fold<double>(
        0.0,
        (sum, item) => sum + ((item['amount'] as num).toDouble()),
      );

      // Get transaction count
      dynamic countQuery;
      if (manufacturerId != null) {
        countQuery = _supabase
            .from('credit_transactions')
            .select('id')
            .eq('manufacturer_id', manufacturerId);
      } else {
        countQuery = _supabase
            .from('credit_transactions')
            .select('id')
            .eq('entity_name', entityName!);
      }

      final countResponse = await countQuery;
      final transactionCount = (countResponse as List).length;

      return ManufacturerCreditBalance(
        manufacturerId: manufacturerId,
        entityName: entityDisplayName,
        currentBalance: currentBalance,
        totalPayin: totalPayin,
        totalPayout: totalPayout,
        transactionCount: transactionCount,
        lastTransactionDate:
            latestTransaction != null
                ? DateTime.parse(
                  latestTransaction['transaction_date'] as String,
                )
                : null,
      );
    } catch (e) {
      throw Exception('Failed to fetch entity balance: $e');
    }
  }

  /// Get credit balance for a manufacturer (backward compatibility)
  Future<ManufacturerCreditBalance> getManufacturerBalance(
    String manufacturerId,
  ) async {
    return getEntityBalance(manufacturerId: manufacturerId);
  }

  /// Get all entity balances (manufacturers and personal expenses)
  Future<List<ManufacturerCreditBalance>> getAllEntityBalances() async {
    try {
      final List<ManufacturerCreditBalance> balances = [];

      // Get balances for all manufacturers
      final manufacturers = await _supabase
          .from('manufacturers')
          .select('id, name, business_name')
          .eq('is_active', true);

      for (final manufacturer in manufacturers as List) {
        final manufacturerId = manufacturer['id'] as String;
        final balance = await getEntityBalance(manufacturerId: manufacturerId);
        balances.add(balance);
      }

      // Get balances for all unique entity names (personal expenses)
      final entityNamesResponse = await _supabase
          .from('credit_transactions')
          .select('entity_name')
          .filter('manufacturer_id', 'is', null)
          .not('entity_name', 'is', null);

      final entityNamesSet = <String>{};
      for (final row in entityNamesResponse as List) {
        final entityName = row['entity_name'] as String?;
        if (entityName != null && entityName.isNotEmpty) {
          entityNamesSet.add(entityName);
        }
      }

      for (final entityName in entityNamesSet) {
        final balance = await getEntityBalance(entityName: entityName);
        balances.add(balance);
      }

      return balances;
    } catch (e) {
      throw Exception('Failed to fetch entity balances: $e');
    }
  }

  /// Get all manufacturer balances (backward compatibility)
  Future<List<ManufacturerCreditBalance>> getAllManufacturerBalances() async {
    return getAllEntityBalances();
  }

  /// Create a new credit transaction
  Future<CreditTransaction> createCreditTransaction({
    String? manufacturerId,
    String? entityName,
    required CreditTransactionType transactionType,
    required double amount,
    required String createdBy,
    String? description,
    String? referenceNumber,
    PaymentMethod? paymentMethod,
    DateTime? transactionDate,
  }) async {
    try {
      if (manufacturerId == null && entityName == null) {
        throw Exception('Either manufacturerId or entityName must be provided');
      }

      // Get current balance
      final currentBalance = await _getCurrentBalance(
        manufacturerId: manufacturerId,
        entityName: entityName,
      );

      // Calculate new balance
      // Current Balance Logic: Negative = Admin Owes, Positive = Entity Owes
      // Payin: Admin pays entity (Payment Out) -> Reduces Admin Debt (Less Negative) -> +amount
      // Payout: Entity pays admin (Payment In/Refund) -> Increases Admin Debt/Reduces Entity Debt -> -amount
      // Purchase: Admin buys -> Increases Admin Debt (More Negative) -> -amount
      double balanceChange = 0.0;
      switch (transactionType) {
        case CreditTransactionType.payin:
          // Admin pays manufacturer (Payment Out)
          // Example: Balance -1960 (Admin Owes). Pay 600. New Balance -1360.
          // Logic: -1960 + 600 = -1360 (Reduces Admin Debt)
          balanceChange = amount;
          break;
        case CreditTransactionType.payout:
          // Manufacturer pays admin (Payment In / Refund)
          // Example: Balance -1360 (Admin Owes). Manufacturer gives 600 refund.
          // Logic: -1360 - 600 = -1960 (Increases Admin Debt / Reduces Entity Credit)
          balanceChange = -amount;
          break;
        case CreditTransactionType.purchase:
          // Admin buys goods (Purchase)
          // Example: Balance 0. Buy 600. New Balance -600 (Admin Owes).
          // Logic: 0 - 600 = -600
          balanceChange = -amount;
          break;
      }

      final balanceAfter = currentBalance + balanceChange;

      String? manufacturerName;
      if (manufacturerId != null) {
        // Get manufacturer name
        final manufacturerResponse =
            await _supabase
                .from('manufacturers')
                .select('name, business_name')
                .eq('id', manufacturerId)
                .single();

        manufacturerName =
            manufacturerResponse['name'] as String? ??
            manufacturerResponse['business_name'] as String? ??
            'Unknown';
      }

      final transactionData = <String, dynamic>{
        if (manufacturerId != null) 'manufacturer_id': manufacturerId,
        if (entityName != null) 'entity_name': entityName,
        'transaction_type': transactionType.name,
        'amount': amount,
        'balance_after': balanceAfter,
        'description': description,
        'reference_number': referenceNumber,
        'payment_method': paymentMethod?.toDatabaseValue(),
        'transaction_date':
            (transactionDate ?? DateTime.now()).toIso8601String(),
        'created_by': createdBy,
      };

      final response =
          await _supabase
              .from('credit_transactions')
              .insert(transactionData)
              .select()
              .single();

      final transactionJson = response;
      if (manufacturerName != null) {
        transactionJson['manufacturer_name'] = manufacturerName;
      }

      return CreditTransaction.fromSupabaseJson(transactionJson);
    } catch (e) {
      throw Exception('Failed to create credit transaction: $e');
    }
  }

  /// Get current balance for an entity
  Future<double> _getCurrentBalance({
    String? manufacturerId,
    String? entityName,
  }) async {
    try {
      dynamic query;
      if (manufacturerId != null) {
        query = _supabase
            .from('credit_transactions')
            .select('balance_after')
            .eq('manufacturer_id', manufacturerId);
      } else if (entityName != null) {
        query = _supabase
            .from('credit_transactions')
            .select('balance_after')
            .eq('entity_name', entityName);
      } else {
        return 0.0;
      }

      final response =
          await query
              .order('transaction_date', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) return 0.0;
      return (response['balance_after'] as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  /// Update an existing credit transaction
  Future<void> updateCreditTransaction(CreditTransaction transaction) async {
    try {
      await _supabase
          .from('credit_transactions')
          .update({
            'amount': transaction.amount,
            'description': transaction.description,
            'reference_number': transaction.referenceNumber,
            'payment_method': transaction.paymentMethod?.toDatabaseValue(),
            'transaction_date': transaction.transactionDate.toIso8601String(),
          })
          .eq('id', transaction.id);

      // Recalculate balances
      if (transaction.manufacturerId != null) {
        await _recalculateBalances(manufacturerId: transaction.manufacturerId);
      } else if (transaction.entityName != null) {
        await _recalculateBalances(entityName: transaction.entityName);
      }
    } catch (e) {
      throw Exception('Failed to update credit transaction: $e');
    }
  }

  /// Delete a credit transaction
  Future<void> deleteCreditTransaction(String id) async {
    try {
      // Get transaction details first to know which entity to recalculate
      final response =
          await _supabase
              .from('credit_transactions')
              .select('manufacturer_id, entity_name')
              .eq('id', id)
              .single();

      final manufacturerId = response['manufacturer_id'] as String?;
      final entityName = response['entity_name'] as String?;

      // Delete the transaction
      await _supabase.from('credit_transactions').delete().eq('id', id);

      // Recalculate balances
      if (manufacturerId != null) {
        await _recalculateBalances(manufacturerId: manufacturerId);
      } else if (entityName != null) {
        await _recalculateBalances(entityName: entityName);
      }
    } catch (e) {
      throw Exception('Failed to delete credit transaction: $e');
    }
  }

  /// Recalculate balances for an entity
  Future<void> _recalculateBalances({
    String? manufacturerId,
    String? entityName,
  }) async {
    try {
      dynamic query = _supabase.from('credit_transactions').select('*');

      if (manufacturerId != null) {
        query = query.eq('manufacturer_id', manufacturerId);
      } else if (entityName != null) {
        query = query.eq('entity_name', entityName);
      } else {
        return;
      }

      // Get all transactions sorted by date (oldest first)
      // Note: If multiple transactions have same date, order by ID to be deterministic
      final response = await query.order('transaction_date', ascending: true);
      final transactions =
          (response as List)
              .map((json) => CreditTransaction.fromSupabaseJson(json))
              .toList();

      double currentBalance = 0.0;

      for (final transaction in transactions) {
        double balanceChange = 0.0;
        switch (transaction.transactionType) {
          case CreditTransactionType.payin:
            // Admin pays manufacturer (Payment Out) -> Reduces Admin Debt (Less Negative) -> +amount
            balanceChange = transaction.amount;
            break;
          case CreditTransactionType.payout:
            // Manufacturer pays admin (Payment In / Refund) -> Increases Admin Debt -> -amount
            balanceChange = -transaction.amount;
            break;
          case CreditTransactionType.purchase:
            // Admin buys goods (Purchase) -> Increases Admin Debt (More Negative) -> -amount
            balanceChange = -transaction.amount;
            break;
        }

        currentBalance += balanceChange;

        // Update balance_after if different
        // Use a small epsilon for float comparison
        if ((transaction.balanceAfter - currentBalance).abs() > 0.01) {
          await _supabase
              .from('credit_transactions')
              .update({'balance_after': currentBalance})
              .eq('id', transaction.id);
        }
      }
    } catch (e) {
      throw Exception('Failed to recalculate balances: $e');
    }
  }
}

final creditTransactionRepositoryProvider =
    Provider<CreditTransactionRepository>((ref) {
      final supabase = ref.watch(supabaseClientProvider);
      return CreditTransactionRepository(supabase);
    });
