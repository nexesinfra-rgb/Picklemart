import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:picklemart/features/admin/application/admin_order_controller.dart';
import 'package:picklemart/features/orders/data/order_model.dart';
import 'package:picklemart/features/orders/data/order_repository_provider.dart';
import 'package:picklemart/features/orders/data/order_repository_supabase.dart';
import 'package:picklemart/features/admin/data/payment_receipt_repository.dart';
import 'package:picklemart/features/orders/data/shared_orders_provider.dart';

import 'admin_order_controller_update_test.mocks.dart';

@GenerateMocks([OrderRepositorySupabase, PaymentReceiptRepository])
void main() {
  late ProviderContainer container;
  late MockOrderRepositorySupabase mockOrderRepository;
  late MockPaymentReceiptRepository mockPaymentRepository;

  setUp(() {
    mockOrderRepository = MockOrderRepositorySupabase();
    mockPaymentRepository = MockPaymentReceiptRepository();

    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockOrderRepository),
        paymentReceiptRepositoryProvider.overrideWithValue(
          mockPaymentRepository,
        ),
        sharedOrdersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
  });

  test('updateOrder should update order in state and payment map', () async {
    // Arrange
    final originalOrder = Order(
      id: '1',
      orderNumber: 'ORD-1',
      orderDate: DateTime.now(),
      status: OrderStatus.confirmed,
      items: [],
      deliveryAddress: OrderAddress(
        name: 'Test',
        phone: '123',
        address: 'Addr',
        city: 'City',
        state: 'State',
        pincode: '123456',
      ),
      subtotal: 100.0,
      shipping: 0.0,
      tax: 0.0,
      total: 100.0,
      userId: 'user1',
    );

    // Mock initial load
    when(
      mockOrderRepository.getAllOrders(page: 1, limit: 50),
    ).thenAnswer((_) async => [originalOrder]);
    when(
      mockPaymentRepository.getTotalPaidForAllOrders(),
    ).thenAnswer((_) async => {'1': 0.0}); // 0 paid

    final controller = container.read(adminOrderControllerProvider.notifier);
    await controller.loadOrders();

    // Verify initial state
    var state = container.read(adminOrderControllerProvider);
    expect(state.orders.first.total, 100.0);
    expect(state.orderPaymentMap['1']?.balanceAmount, 100.0);

    // Act - Update order with shipping (simulating convertToSale)
    final updatedOrder = Order(
      id: '1',
      orderNumber: 'ORD-1',
      orderDate: DateTime.now(),
      status: OrderStatus.confirmed,
      items: [],
      deliveryAddress: OrderAddress(
        name: 'Test',
        phone: '123',
        address: 'Addr',
        city: 'City',
        state: 'State',
        pincode: '123456',
      ),
      subtotal: 100.0,
      shipping: 50.0, // Added shipping
      tax: 0.0,
      total: 150.0, // New total
      userId: 'user1',
    );

    controller.updateOrder(updatedOrder);

    // Assert
    state = container.read(adminOrderControllerProvider);
    expect(state.orders.first.total, 150.0);
    expect(state.orders.first.shipping, 50.0);

    // Check if balance is updated correctly (Total 150 - Paid 0 = Balance 150)
    expect(state.orderPaymentMap['1']?.balanceAmount, 150.0);
    expect(state.orderPaymentMap['1']?.order.total, 150.0);
  });

  test('updateOrder should preserve payment info', () async {
    // Arrange
    final originalOrder = Order(
      id: '1',
      orderNumber: 'ORD-1',
      orderDate: DateTime.now(),
      status: OrderStatus.confirmed,
      items: [],
      deliveryAddress: OrderAddress(
        name: 'Test',
        phone: '123',
        address: 'Addr',
        city: 'City',
        state: 'State',
        pincode: '123456',
      ),
      subtotal: 100.0,
      shipping: 0.0,
      tax: 0.0,
      total: 100.0,
      userId: 'user1',
    );

    // Mock initial load with partial payment
    when(
      mockOrderRepository.getAllOrders(page: 1, limit: 50),
    ).thenAnswer((_) async => [originalOrder]);
    when(
      mockPaymentRepository.getTotalPaidForAllOrders(),
    ).thenAnswer((_) async => {'1': 40.0}); // 40 paid

    final controller = container.read(adminOrderControllerProvider.notifier);
    await controller.loadOrders();

    // Verify initial state
    var state = container.read(adminOrderControllerProvider);
    expect(state.orders.first.total, 100.0);
    expect(state.orderPaymentMap['1']?.balanceAmount, 60.0); // 100 - 40 = 60
    expect(state.orderPaymentMap['1']?.paymentStatus, PaymentStatus.partial);

    // Act - Update order with shipping
    final updatedOrder = Order(
      id: '1',
      orderNumber: 'ORD-1',
      orderDate: DateTime.now(),
      status: OrderStatus.confirmed,
      items: [],
      deliveryAddress: OrderAddress(
        name: 'Test',
        phone: '123',
        address: 'Addr',
        city: 'City',
        state: 'State',
        pincode: '123456',
      ),
      subtotal: 100.0,
      shipping: 50.0,
      tax: 0.0,
      total: 150.0,
      userId: 'user1',
    );

    controller.updateOrder(updatedOrder);

    // Assert
    state = container.read(adminOrderControllerProvider);
    expect(state.orders.first.total, 150.0);

    // Check if balance is updated correctly (New Total 150 - Paid 40 = Balance 110)
    expect(state.orderPaymentMap['1']?.balanceAmount, 110.0);
    expect(state.orderPaymentMap['1']?.paymentStatus, PaymentStatus.partial);
  });
}
