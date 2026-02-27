import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/admin/application/admin_customer_controller.dart';

void main() {
  group('AdminCustomerController Unit Tests', () {
    late ProviderContainer container;
    late AdminCustomerController adminCustomerController;

    setUp(() {
      container = ProviderContainer();
      adminCustomerController = container.read(
        adminCustomerControllerProvider.notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
      final state = container.read(adminCustomerControllerProvider);

      expect(state.customers, isEmpty);
      expect(state.filteredCustomers, isEmpty);
        expect(state.searchQuery, equals(''));
        expect(state.loading, isFalse);
        expect(state.error, isNull);
        expect(state.selectedCustomer, isNull);
      });
    });

    group('loadCustomers()', () {
      test('should load customers successfully', () async {
        // Act
        await adminCustomerController.loadCustomers();

        // Assert
      final state = container.read(adminCustomerControllerProvider);
      expect(state.customers, isNotEmpty);
      expect(state.filteredCustomers, isNotEmpty);
        expect(state.loading, isFalse);
        expect(state.error, isNull);
        expect(state.customers.length, equals(8)); // Mock data has 8 customers
      });

      test('should set loading state during load', () async {
        // Act
        final future = adminCustomerController.loadCustomers();

        // Assert - Check loading state
        final loadingState = container.read(adminCustomerControllerProvider);
        expect(loadingState.loading, isTrue);

        // Wait for completion
        await future;

        // Check final state
        final finalState = container.read(adminCustomerControllerProvider);
        expect(finalState.loading, isFalse);
      });

      test('should handle error when loading fails', () async {
        // Arrange
        final controller = AdminCustomerController(container.read);

        // Mock the loadCustomers method to throw an error
        controller.loadCustomers = () async {
          state = state.copyWith(loading: true, error: null);
          try {
            await Future.delayed(const Duration(milliseconds: 100));
            throw Exception('Network error');
          } catch (e) {
            state = state.copyWith(loading: false, error: e.toString());
          }
        };

        // Act
        await controller.loadCustomers();

        // Assert
        final state = container.read(adminCustomerControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, contains('Network error'));
        expect(state.customers, isEmpty);
      });
    });

    group('searchCustomers()', () {
      setUp(() async {
        await adminCustomerController.loadCustomers();
      });

      test('should filter customers by name', () {
        // Act
        adminCustomerController.searchCustomers('John');

        // Assert
        final state = container.read(adminCustomerControllerProvider);
        expect(state.searchQuery, equals('John'));
        expect(state.filteredCustomers.length, equals(1));
        expect(state.filteredCustomers.first.name, equals('John Doe'));
      });

      test('should filter customers by email', () {
        // Act
        adminCustomerController.searchCustomers('jane.smith@example.com');

        // Assert
        final state = container.read(adminCustomerControllerProvider);
        expect(state.filteredCustomers.length, equals(1));
        expect(
          state.filteredCustomers.first.email,
          equals('jane.smith@example.com'),
        );
      });

      test('should filter customers by phone', () {
        // Act
        adminCustomerController.searchCustomers('+1234567890');

        // Assert
        final state = container.read(adminCustomerControllerProvider);
        expect(state.filteredCustomers.length, equals(1));
        expect(state.filteredCustomers.first.phone, equals('+1234567890'));
      });

      test('should be case insensitive', () {
        // Act
        adminCustomerController.searchCustomers('john');

        // Assert
        final state = container.read(adminCustomerControllerProvider);
        expect(state.filteredCustomers.length, equals(1));
        expect(state.filteredCustomers.first.name, equals('John Doe'));
      });

      test('should return all customers for empty search', () {
        // Act
        adminCustomerController.searchCustomers('');

        // Assert
        final state = container.read(adminCustomerControllerProvider);
        expect(state.filteredCustomers.length, equals(8));
      });

      test('should return empty list for non-matching search', () {
        // Act
        adminCustomerController.searchCustomers('NonExistent');

        // Assert
        final state = container.read(adminCustomerControllerProvider);
        expect(state.filteredCustomers, isEmpty);
      });

      test('should search across multiple fields', () {
        // Act
        adminCustomerController.searchCustomers('example.com');

        // Assert
      final state = container.read(adminCustomerControllerProvider);
        expect(
          state.filteredCustomers.length,
          equals(8),
        ); // All customers have example.com email
      });
    });

    group('selectCustomer()', () {
      setUp(() async {
        await adminCustomerController.loadCustomers();
      });

      test('should select a customer', () {
        // Arrange
        final customer = adminCustomerController.state.customers.first;

        // Act
        adminCustomerController.selectCustomer(customer);

        // Assert
        final state = container.read(adminCustomerControllerProvider);
        expect(state.selectedCustomer, equals(customer));
      });
    });

    group('clearSelection()', () {
      setUp(() async {
        await adminCustomerController.loadCustomers();
      });

      test('should clear selected customer', () {
        // Arrange
        final customer = adminCustomerController.state.customers.first;
        adminCustomerController.selectCustomer(customer);

        // Act
        adminCustomerController.clearSelection();

        // Assert
      final state = container.read(adminCustomerControllerProvider);
        expect(state.selectedCustomer, isNull);
      });
    });

    group('updateCustomerStatus()', () {
      setUp(() async {
        await adminCustomerController.loadCustomers();
      });

      test('should update customer status to active', () async {
        // Arrange
        const customerId = '8'; // Frank Miller is inactive
        const isActive = true;

        // Act
        final result = await adminCustomerController.updateCustomerStatus(
          customerId,
          isActive,
        );

        // Assert
        expect(result, isTrue);
        final state = container.read(adminCustomerControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, isNull);

        final updatedCustomer = state.customers.firstWhere(
          (customer) => customer.id == customerId,
        );
        expect(updatedCustomer.isActive, equals(isActive));
      });

      test('should update customer status to inactive', () async {
        // Arrange
        const customerId = '1'; // John Doe is active
        const isActive = false;

        // Act
        final result = await adminCustomerController.updateCustomerStatus(
          customerId,
          isActive,
        );

        // Assert
        expect(result, isTrue);
        final state = container.read(adminCustomerControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, isNull);

        final updatedCustomer = state.customers.firstWhere(
          (customer) => customer.id == customerId,
        );
        expect(updatedCustomer.isActive, equals(isActive));
      });

      test('should handle error when updating status fails', () async {
        // Arrange
        const customerId = '1';
        const isActive = false;

        final controller = AdminCustomerController(container.read);
        controller.updateCustomerStatus = (id, active) async {
          state = state.copyWith(loading: true, error: null);
          try {
            await Future.delayed(const Duration(milliseconds: 100));
            throw Exception('Update failed');
          } catch (e) {
            state = state.copyWith(loading: false, error: e.toString());
            return false;
          }
        };

        // Act
        final result = await controller.updateCustomerStatus(
          customerId,
          isActive,
        );

        // Assert
        expect(result, isFalse);
      final state = container.read(adminCustomerControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, contains('Update failed'));
      });

      test('should set loading state during update', () async {
        // Arrange
        const customerId = '1';
        const isActive = false;

        // Act
        final future = adminCustomerController.updateCustomerStatus(
          customerId,
          isActive,
        );

        // Assert - Check loading state
        final loadingState = container.read(adminCustomerControllerProvider);
        expect(loadingState.loading, isTrue);

        // Wait for completion
        await future;

        // Check final state
        final finalState = container.read(adminCustomerControllerProvider);
        expect(finalState.loading, isFalse);
      });

      test('should update filtered customers after status change', () async {
        // Arrange
        const customerId = '1';
        const isActive = false;
        adminCustomerController.searchCustomers('John'); // Filter to John Doe

        // Act
        await adminCustomerController.updateCustomerStatus(
          customerId,
          isActive,
        );

        // Assert
      final state = container.read(adminCustomerControllerProvider);
        final filteredCustomer = state.filteredCustomers.first;
        expect(filteredCustomer.isActive, equals(isActive));
      });
    });

    group('clearError()', () {
      test('should clear error state', () async {
        // Arrange
        final controller = AdminCustomerController(container.read);
        controller.loadCustomers = () async {
          state = state.copyWith(loading: true, error: null);
          try {
            await Future.delayed(const Duration(milliseconds: 100));
            throw Exception('Test error');
          } catch (e) {
            state = state.copyWith(loading: false, error: e.toString());
          }
        };

        await controller.loadCustomers();

        // Verify error is set
      expect(
          container.read(adminCustomerControllerProvider).error,
          isNotNull,
        );

        // Act
        adminCustomerController.clearError();

        // Assert
        final state = container.read(adminCustomerControllerProvider);
        expect(state.error, isNull);
      });
    });

    group('Mock Data Validation', () {
      setUp(() async {
        await adminCustomerController.loadCustomers();
      });

      test('should have valid customer data', () {
        final state = container.read(adminCustomerControllerProvider);

        for (final customer in state.customers) {
          expect(customer.id, isNotEmpty);
          expect(customer.name, isNotEmpty);
          expect(customer.email, isNotEmpty);
          expect(customer.phone, isNotEmpty);
          expect(customer.totalOrders, greaterThanOrEqualTo(0));
          expect(customer.totalSpent, greaterThanOrEqualTo(0.0));
        }
      });

      test('should have customers with different activity statuses', () {
        final state = container.read(adminCustomerControllerProvider);
        final activeCustomers = state.customers.where((c) => c.isActive).length;
        final inactiveCustomers =
            state.customers.where((c) => !c.isActive).length;

        expect(activeCustomers, greaterThan(0));
        expect(inactiveCustomers, greaterThan(0));
        expect(activeCustomers + inactiveCustomers, equals(8));
      });

      test('should have customers with different order histories', () {
        final state = container.read(adminCustomerControllerProvider);
        final customersWithOrders =
            state.customers.where((c) => c.totalOrders > 0).length;
        final customersWithoutOrders =
            state.customers.where((c) => c.totalOrders == 0).length;

        expect(customersWithOrders, greaterThan(0));
        expect(customersWithoutOrders, greaterThan(0));
      });

      test('should have customers with different spending amounts', () {
        final state = container.read(adminCustomerControllerProvider);
        final spendingAmounts =
            state.customers.map((c) => c.totalSpent).toList();

        spendingAmounts.sort();
        expect(
          spendingAmounts.first,
          equals(0.0),
        ); // At least one customer with no spending
      expect(
          spendingAmounts.last,
          greaterThan(0.0),
        ); // At least one customer with spending
      });

      test('should have customers with different creation dates', () {
        final state = container.read(adminCustomerControllerProvider);
        final creationDates = state.customers.map((c) => c.createdAt).toList();

        // Sort dates to check they are different
        creationDates.sort();
        expect(creationDates.length, equals(8));

        // Check that dates are in ascending order (oldest first)
        for (int i = 0; i < creationDates.length - 1; i++) {
          expect(creationDates[i].isBefore(creationDates[i + 1]), isTrue);
        }
      });
    });

    group('Customer Model', () {
      test('should create customer with required fields', () {
        // Arrange & Act
      final customer = Customer(
        id: '1',
          name: 'Test Customer',
          email: 'test@example.com',
        phone: '+1234567890',
        createdAt: DateTime.now(),
        );

        // Assert
        expect(customer.id, equals('1'));
        expect(customer.name, equals('Test Customer'));
        expect(customer.email, equals('test@example.com'));
        expect(customer.phone, equals('+1234567890'));
        expect(customer.totalOrders, equals(0));
        expect(customer.totalSpent, equals(0.0));
        expect(customer.isActive, isTrue);
        expect(customer.lastOrderDate, isNull);
      });

      test('should create customer with all fields', () {
        // Arrange
        final now = DateTime.now();
        final lastOrder = now.subtract(const Duration(days: 1));

        // Act
      final customer = Customer(
        id: '1',
          name: 'Test Customer',
          email: 'test@example.com',
        phone: '+1234567890',
          createdAt: now,
          lastOrderDate: lastOrder,
        totalOrders: 5,
          totalSpent: 250.0,
        isActive: false,
      );

        // Assert
        expect(customer.id, equals('1'));
        expect(customer.name, equals('Test Customer'));
        expect(customer.email, equals('test@example.com'));
        expect(customer.phone, equals('+1234567890'));
        expect(customer.createdAt, equals(now));
        expect(customer.lastOrderDate, equals(lastOrder));
        expect(customer.totalOrders, equals(5));
        expect(customer.totalSpent, equals(250.0));
        expect(customer.isActive, isFalse);
      });

      test('should copy customer with updated fields', () {
        // Arrange
        final originalCustomer = Customer(
          id: '1',
          name: 'Original Name',
          email: 'original@example.com',
          phone: '+1234567890',
          createdAt: DateTime.now(),
          totalOrders: 5,
          totalSpent: 250.0,
          isActive: true,
        );

        // Act
        final updatedCustomer = originalCustomer.copyWith(
          name: 'Updated Name',
          isActive: false,
        );

        // Assert
        expect(updatedCustomer.id, equals('1'));
        expect(updatedCustomer.name, equals('Updated Name'));
        expect(updatedCustomer.email, equals('original@example.com'));
        expect(updatedCustomer.phone, equals('+1234567890'));
        expect(updatedCustomer.totalOrders, equals(5));
        expect(updatedCustomer.totalSpent, equals(250.0));
        expect(updatedCustomer.isActive, isFalse);
      });
    });
  });
}
