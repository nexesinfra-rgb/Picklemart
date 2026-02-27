import 'dart:async';
import '../application/admin_customer_controller.dart';

/// Abstract interface for customer repository operations
abstract class CustomerRepository {
  /// Fetch all customers from the database
  /// [page] and [pageSize] are optional for backward compatibility
  /// When provided, returns paginated results; otherwise returns all customers
  Future<List<Customer>> getAllCustomers({int? page, int? pageSize});

  /// Fetch paginated customers with metadata
  /// Returns pagination metadata including total count
  Future<PaginatedCustomersResult> getAllCustomersPaginated({
    int page = 1,
    int pageSize = 50,
  });

  /// Subscribe to real-time customer changes
  Stream<List<Customer>> subscribeToCustomers();

  /// Update customer price visibility
  Future<void> updateCustomerPriceVisibility(String customerId, bool enabled);

  /// Update customer active status
  Future<void> updateCustomerStatus(String customerId, bool isActive);

  /// Create a new customer account (admin only)
  /// Returns the created user information including credentials for manual sharing
  Future<Map<String, dynamic>> createCustomerAccount({
    required String name,
    required String mobile,
    required String password,
    String? gstNumber,
  });

  /// Update an existing customer's details
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
  });

  /// Delete a customer and all related data
  Future<void> deleteCustomer(String id);

  /// Get summary metrics for customers (optimized for dashboard)
  Future<Map<String, dynamic>> getCustomerMetrics();
}
