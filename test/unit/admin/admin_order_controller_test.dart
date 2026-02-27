import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/admin/application/admin_order_controller.dart';
import 'package:picklemart/features/orders/data/order_model.dart';

void main() {
  group('AdminOrderController Unit Tests', () {
    late ProviderContainer container;
    late AdminOrderController adminOrderController;

    setUp(() {
      container = ProviderContainer();
      adminOrderController = container.read(
        adminOrderControllerProvider.notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
      final state = container.read(adminOrderControllerProvider);

      expect(state.orders, isEmpty);
      expect(state.filteredOrders, isEmpty);
        expect(state.searchQuery, equals(''));
        expect(state.selectedStatus, isNull);
        expect(state.loading, isFalse);
        expect(state.error, isNull);
        expect(state.selectedOrder, isNull);
      });
    });

    group('loadOrders()', () {
      test('should load orders successfully', () async {
        // Act
        await adminOrderController.loadOrders();

        // Assert
      final state = container.read(adminOrderControllerProvider);
      expect(state.orders, isNotEmpty);
      expect(state.filteredOrders, isNotEmpty);
        expect(state.loading, isFalse);
        expect(state.error, isNull);
        expect(state.orders.length, equals(5)); // Mock data has 5 orders
      });

      test('should set loading state during load', () async {
        // Act
        final future = adminOrderController.loadOrders();

        // Assert - Check loading state
        final loadingState = container.read(adminOrderControllerProvider);
        expect(loadingState.loading, isTrue);

        // Wait for completion
        await future;

        // Check final state
        final finalState = container.read(adminOrderControllerProvider);
        expect(finalState.loading, isFalse);
      });

      test('should handle error when loading fails', () async {
        // Arrange
        final controller = AdminOrderController(container.read);

        // Mock the loadOrders method to throw an error
        controller.loadOrders = () async {
          state = state.copyWith(loading: true, error: null);
          try {
            await Future.delayed(const Duration(milliseconds: 100));
            throw Exception('Network error');
          } catch (e) {
            state = state.copyWith(loading: false, error: e.toString());
          }
        };

        // Act
        await controller.loadOrders();

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, contains('Network error'));
        expect(state.orders, isEmpty);
      });
    });

    group('searchOrders()', () {
      setUp(() async {
        await adminOrderController.loadOrders();
      });

      test('should filter orders by order number', () {
        // Act
        adminOrderController.searchOrders('ORD-001234');

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.searchQuery, equals('ORD-001234'));
        expect(state.filteredOrders.length, equals(1));
        expect(state.filteredOrders.first.orderNumber, equals('ORD-001234'));
      });

      test('should filter orders by customer name', () {
        // Act
        adminOrderController.searchOrders('John Doe');

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders.length, equals(1));
        expect(
          state.filteredOrders.first.deliveryAddress.name,
          equals('John Doe'),
        );
      });

      test('should filter orders by phone number', () {
        // Act
        adminOrderController.searchOrders('+1234567890');

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders.length, equals(1));
        expect(
          state.filteredOrders.first.deliveryAddress.phone,
          equals('+1234567890'),
        );
      });

      test('should be case insensitive', () {
        // Act
        adminOrderController.searchOrders('john doe');

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders.length, equals(1));
        expect(
          state.filteredOrders.first.deliveryAddress.name,
          equals('John Doe'),
        );
      });

      test('should return all orders for empty search', () {
        // Act
        adminOrderController.searchOrders('');

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders.length, equals(5));
      });

      test('should return empty list for non-matching search', () {
        // Act
        adminOrderController.searchOrders('NonExistent');

        // Assert
      final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders, isEmpty);
      });
    });

    group('filterByStatus()', () {
      setUp(() async {
        await adminOrderController.loadOrders();
      });

      test('should filter orders by confirmed status', () {
        // Act
        adminOrderController.filterByStatus(OrderStatus.confirmed);

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.selectedStatus, equals(OrderStatus.confirmed));
        expect(state.filteredOrders.length, equals(1));
        expect(
          state.filteredOrders.first.status,
          equals(OrderStatus.confirmed),
        );
      });

      test('should filter orders by processing status', () {
        // Act
        adminOrderController.filterByStatus(OrderStatus.processing);

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders.length, equals(1));
        expect(
          state.filteredOrders.first.status,
          equals(OrderStatus.processing),
        );
      });

      test('should filter orders by shipped status', () {
        // Act
        adminOrderController.filterByStatus(OrderStatus.shipped);

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders.length, equals(1));
        expect(state.filteredOrders.first.status, equals(OrderStatus.shipped));
      });

      test('should filter orders by delivered status', () {
        // Act
        adminOrderController.filterByStatus(OrderStatus.delivered);

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders.length, equals(1));
        expect(
          state.filteredOrders.first.status,
          equals(OrderStatus.delivered),
        );
      });

      test('should filter orders by cancelled status', () {
        // Act
        adminOrderController.filterByStatus(OrderStatus.cancelled);

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders.length, equals(1));
        expect(
          state.filteredOrders.first.status,
          equals(OrderStatus.cancelled),
        );
      });

      test('should show all orders when status is null', () {
        // Act
        adminOrderController.filterByStatus(null);

        // Assert
      final state = container.read(adminOrderControllerProvider);
        expect(state.selectedStatus, isNull);
        expect(state.filteredOrders.length, equals(5));
      });
    });

    group('Combined Search and Status Filter', () {
      setUp(() async {
        await adminOrderController.loadOrders();
      });

      test('should apply both search and status filters', () {
        // Act
        adminOrderController.searchOrders('John');
        adminOrderController.filterByStatus(OrderStatus.confirmed);

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders.length, equals(1));
        expect(
          state.filteredOrders.first.deliveryAddress.name,
          equals('John Doe'),
        );
        expect(
          state.filteredOrders.first.status,
          equals(OrderStatus.confirmed),
        );
      });

      test('should return empty when no orders match both filters', () {
        // Act
        adminOrderController.searchOrders('John');
        adminOrderController.filterByStatus(OrderStatus.cancelled);

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.filteredOrders, isEmpty);
      });
    });

    group('selectOrder()', () {
      setUp(() async {
        await adminOrderController.loadOrders();
      });

      test('should select an order', () {
        // Arrange
        final order = adminOrderController.state.orders.first;

        // Act
        adminOrderController.selectOrder(order);

        // Assert
      final state = container.read(adminOrderControllerProvider);
        expect(state.selectedOrder, equals(order));
      });
    });

    group('clearSelection()', () {
      setUp(() async {
        await adminOrderController.loadOrders();
      });

      test('should clear selected order', () {
        // Arrange
        final order = adminOrderController.state.orders.first;
        adminOrderController.selectOrder(order);

        // Act
        adminOrderController.clearSelection();

        // Assert
        final state = container.read(adminOrderControllerProvider);
        expect(state.selectedOrder, isNull);
      });
    });

    group('updateOrderStatus()', () {
      setUp(() async {
        await adminOrderController.loadOrders();
      });

      test('should update order status successfully', () async {
        // Arrange
        const orderId = '1';
        const newStatus = OrderStatus.shipped;

        // Act
        final result = await adminOrderController.updateOrderStatus(
          orderId,
          newStatus,
        );

        // Assert
        expect(result, isTrue);
        final state = container.read(adminOrderControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, isNull);

        final updatedOrder = state.orders.firstWhere(
          (order) => order.id == orderId,
        );
        expect(updatedOrder.status, equals(newStatus));
      });

      test('should handle error when updating status fails', () async {
        // Arrange
        const orderId = '1';
        const newStatus = OrderStatus.shipped;

        final controller = AdminOrderController(container.read);
        controller.updateOrderStatus = (id, status) async {
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
        final result = await controller.updateOrderStatus(orderId, newStatus);

        // Assert
        expect(result, isFalse);
        final state = container.read(adminOrderControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, contains('Update failed'));
      });

      test('should set loading state during update', () async {
        // Arrange
        const orderId = '1';
        const newStatus = OrderStatus.shipped;

        // Act
        final future = adminOrderController.updateOrderStatus(
          orderId,
          newStatus,
        );

        // Assert - Check loading state
        final loadingState = container.read(adminOrderControllerProvider);
        expect(loadingState.loading, isTrue);

        // Wait for completion
        await future;

        // Check final state
        final finalState = container.read(adminOrderControllerProvider);
        expect(finalState.loading, isFalse);
      });
    });

    group('addTrackingNumber()', () {
      setUp(() async {
        await adminOrderController.loadOrders();
      });

      test('should add tracking number successfully', () async {
        // Arrange
        const orderId = '1';
        const trackingNumber = 'TRK123456789';

        // Act
        final result = await adminOrderController.addTrackingNumber(
          orderId,
          trackingNumber,
        );

        // Assert
        expect(result, isTrue);
        final state = container.read(adminOrderControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, isNull);

        final updatedOrder = state.orders.firstWhere(
          (order) => order.id == orderId,
        );
        expect(updatedOrder.trackingNumber, equals(trackingNumber));
      });

      test('should handle error when adding tracking number fails', () async {
        // Arrange
        const orderId = '1';
        const trackingNumber = 'TRK123456789';

        final controller = AdminOrderController(container.read);
        controller.addTrackingNumber = (id, tracking) async {
          state = state.copyWith(loading: true, error: null);
          try {
            await Future.delayed(const Duration(milliseconds: 100));
            throw Exception('Tracking update failed');
          } catch (e) {
            state = state.copyWith(loading: false, error: e.toString());
            return false;
          }
        };

        // Act
        final result = await controller.addTrackingNumber(
          orderId,
          trackingNumber,
        );

        // Assert
        expect(result, isFalse);
        final state = container.read(adminOrderControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, contains('Tracking update failed'));
      });

      test('should set loading state during tracking update', () async {
        // Arrange
        const orderId = '1';
        const trackingNumber = 'TRK123456789';

        // Act
        final future = adminOrderController.addTrackingNumber(
          orderId,
          trackingNumber,
        );

        // Assert - Check loading state
        final loadingState = container.read(adminOrderControllerProvider);
        expect(loadingState.loading, isTrue);

        // Wait for completion
        await future;

        // Check final state
        final finalState = container.read(adminOrderControllerProvider);
        expect(finalState.loading, isFalse);
      });
    });

    group('clearError()', () {
      test('should clear error state', () async {
        // Arrange
        final controller = AdminOrderController(container.read);
        controller.loadOrders = () async {
          state = state.copyWith(loading: true, error: null);
          try {
            await Future.delayed(const Duration(milliseconds: 100));
            throw Exception('Test error');
          } catch (e) {
            state = state.copyWith(loading: false, error: e.toString());
          }
        };

        await controller.loadOrders();

        // Verify error is set
        expect(container.read(adminOrderControllerProvider).error, isNotNull);

        // Act
        adminOrderController.clearError();

        // Assert
      final state = container.read(adminOrderControllerProvider);
        expect(state.error, isNull);
      });
    });

    group('Mock Data Validation', () {
      setUp(() async {
        await adminOrderController.loadOrders();
      });

      test('should have valid order data', () {
        final state = container.read(adminOrderControllerProvider);

        for (final order in state.orders) {
          expect(order.id, isNotEmpty);
          expect(order.orderNumber, isNotEmpty);
          expect(order.items, isNotEmpty);
          expect(order.deliveryAddress.name, isNotEmpty);
          expect(order.deliveryAddress.phone, isNotEmpty);
          expect(order.total, greaterThan(0));
        }
      });

      test('should have different order statuses', () {
        final state = container.read(adminOrderControllerProvider);
        final statuses = state.orders.map((order) => order.status).toSet();

        expect(statuses.length, greaterThan(1));
        expect(statuses, contains(OrderStatus.confirmed));
        expect(statuses, contains(OrderStatus.processing));
        expect(statuses, contains(OrderStatus.shipped));
        expect(statuses, contains(OrderStatus.delivered));
        expect(statuses, contains(OrderStatus.cancelled));
      });

      test('should have orders with different dates', () {
        final state = container.read(adminOrderControllerProvider);
        final dates = state.orders.map((order) => order.orderDate).toList();

        // Sort dates to check they are different
        dates.sort();
        expect(dates.length, equals(5));

        // Check that dates are in descending order (newest first)
        for (int i = 0; i < dates.length - 1; i++) {
          expect(dates[i].isAfter(dates[i + 1]), isTrue);
        }
      });
    });
  });
}
