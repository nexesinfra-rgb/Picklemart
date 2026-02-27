import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:picklemart/features/orders/application/order_controller.dart';
import 'package:picklemart/features/orders/data/order_repository.dart';
import 'package:picklemart/features/orders/data/order_repository_provider.dart';
import 'package:picklemart/features/orders/data/order_model.dart';
import 'package:picklemart/features/cart/application/cart_controller.dart';
import 'package:picklemart/features/catalog/data/product.dart';

import 'order_controller_test.mocks.dart';

@GenerateMocks([OrderRepository])
void main() {
  group('OrderController Unit Tests', () {
    late MockOrderRepository mockOrderRepository;
    late ProviderContainer container;
    late OrderController orderController;

    setUp(() {
      mockOrderRepository = MockOrderRepository();
      container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(mockOrderRepository),
        ],
      );
      orderController = container.read(orderControllerProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        final state = container.read(orderControllerProvider);

        expect(state.loading, isFalse);
        expect(state.error, isNull);
        expect(state.currentOrder, isNull);
      });
    });

    group('createOrderFromCart()', () {
      test('should create order successfully with cart items', () async {
        // Arrange
        final product1 = Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://example.com/image1.jpg',
          images: ['https://example.com/image1.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        final product2 = Product(
          id: '2',
          name: 'Test Product 2',
          imageUrl: 'https://example.com/image2.jpg',
          images: ['https://example.com/image2.jpg'],
          price: 200.0,
          categories: ['Test'],
        );

        // Add items to cart
        final cartController = container.read(cartProvider.notifier);
        cartController.add(product1);
        cartController.add(product2);

        final deliveryAddress = OrderAddress(
          name: 'Test User',
          phone: '+1234567890',
          address: '123 Test Street',
          city: 'Test City',
          state: 'Test State',
          pincode: '123456',
        );

        final expectedOrder = Order(
          id: 'order1',
          orderNumber: 'ORD-123456',
          orderDate: DateTime.now(),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: 'item1',
              name: 'Test Product 1',
              image: 'https://example.com/image1.jpg',
              price: 100.0,
              quantity: 1,
            ),
            OrderItem(
              id: 'item2',
              name: 'Test Product 2',
              image: 'https://example.com/image2.jpg',
              price: 200.0,
              quantity: 1,
            ),
          ],
          deliveryAddress: deliveryAddress,
          subtotal: 300.0,
          shipping: 0.0, // Free shipping over Rs. 500
          tax: 54.0, // 18% GST
          total: 354.0,
        );

        when(
          mockOrderRepository.createOrder(
            orderNumber: anyNamed('orderNumber'),
            cartItems: anyNamed('cartItems'),
            deliveryAddress: anyNamed('deliveryAddress'),
            subtotal: anyNamed('subtotal'),
            shipping: anyNamed('shipping'),
            tax: anyNamed('tax'),
            total: anyNamed('total'),
            notes: anyNamed('notes'),
          ),
        ).thenAnswer((_) async => expectedOrder);

        // Act
        await orderController.createOrderFromCart(
          deliveryAddress: deliveryAddress,
          notes: 'Test notes',
        );

        // Assert
        verify(
          mockOrderRepository.createOrder(
            orderNumber: anyNamed('orderNumber'),
            cartItems: anyNamed('cartItems'),
            deliveryAddress: anyNamed('deliveryAddress'),
            subtotal: anyNamed('subtotal'),
            shipping: anyNamed('shipping'),
            tax: anyNamed('tax'),
            total: anyNamed('total'),
            notes: anyNamed('notes'),
          ),
        ).called(1);
        final state = container.read(orderControllerProvider);
        expect(state.currentOrder, equals(expectedOrder));
        expect(state.loading, isFalse);
        expect(state.error, isNull);
      });

      test('should handle empty cart', () async {
        // Arrange
        final deliveryAddress = OrderAddress(
          name: 'Test User',
          phone: '+1234567890',
          address: '123 Test Street',
          city: 'Test City',
          state: 'Test State',
          pincode: '123456',
        );

        // Act
        final result = await orderController.createOrderFromCart(
          deliveryAddress: deliveryAddress,
          notes: 'Test notes',
        );

        // Assert
        expect(result, isNull);
        final state = container.read(orderControllerProvider);
        expect(state.error, equals('Cart is empty'));
        expect(state.loading, isFalse);
      });

      test('should calculate shipping correctly', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0, // Below Rs. 500 threshold
          categories: ['Test'],
        );

        final cartController = container.read(cartProvider.notifier);
        cartController.add(product);

        final deliveryAddress = OrderAddress(
          name: 'Test User',
          phone: '+1234567890',
          address: '123 Test Street',
          city: 'Test City',
          state: 'Test State',
          pincode: '123456',
        );

        final expectedOrder = Order(
          id: 'order1',
          orderNumber: 'ORD-123456',
          orderDate: DateTime.now(),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: 'item1',
              name: 'Test Product',
              image: 'https://example.com/image.jpg',
              price: 100.0,
              quantity: 1,
            ),
          ],
          deliveryAddress: deliveryAddress,
          subtotal: 100.0,
          shipping: 50.0, // Shipping charge for orders below Rs. 500
          tax: 27.0, // 18% GST on (100 + 50)
          total: 177.0,
        );

        when(
          mockOrderRepository.createOrder(
            orderNumber: anyNamed('orderNumber'),
            cartItems: anyNamed('cartItems'),
            deliveryAddress: anyNamed('deliveryAddress'),
            subtotal: anyNamed('subtotal'),
            shipping: anyNamed('shipping'),
            tax: anyNamed('tax'),
            total: anyNamed('total'),
            notes: anyNamed('notes'),
          ),
        ).thenAnswer((_) async => expectedOrder);

        // Act
        await orderController.createOrderFromCart(
          deliveryAddress: deliveryAddress,
          notes: 'Test notes',
        );

        // Assert
        verify(
          mockOrderRepository.createOrder(
            orderNumber: anyNamed('orderNumber'),
            cartItems: anyNamed('cartItems'),
            deliveryAddress: anyNamed('deliveryAddress'),
            subtotal: anyNamed('subtotal'),
            shipping: anyNamed('shipping'),
            tax: anyNamed('tax'),
            total: anyNamed('total'),
            notes: anyNamed('notes'),
          ),
        ).called(1);
        final state = container.read(orderControllerProvider);
        expect(state.currentOrder?.shipping, equals(50.0));
      });

      test('should calculate tax correctly', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 1000.0,
          categories: ['Test'],
        );

        final cartController = container.read(cartProvider.notifier);
        cartController.add(product);

        final deliveryAddress = OrderAddress(
          name: 'Test User',
          phone: '+1234567890',
          address: '123 Test Street',
          city: 'Test City',
          state: 'Test State',
          pincode: '123456',
        );

        final expectedOrder = Order(
          id: 'order1',
          orderNumber: 'ORD-123456',
          orderDate: DateTime.now(),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: 'item1',
              name: 'Test Product',
              image: 'https://example.com/image.jpg',
              price: 1000.0,
              quantity: 1,
            ),
          ],
          deliveryAddress: deliveryAddress,
          subtotal: 1000.0,
          shipping: 0.0, // Free shipping over Rs. 500
          tax: 180.0, // 18% GST
          total: 1180.0,
        );

        when(
          mockOrderRepository.createOrder(
            orderNumber: anyNamed('orderNumber'),
            cartItems: anyNamed('cartItems'),
            deliveryAddress: anyNamed('deliveryAddress'),
            subtotal: anyNamed('subtotal'),
            shipping: anyNamed('shipping'),
            tax: anyNamed('tax'),
            total: anyNamed('total'),
            notes: anyNamed('notes'),
          ),
        ).thenAnswer((_) async => expectedOrder);

        // Act
        await orderController.createOrderFromCart(
          deliveryAddress: deliveryAddress,
          notes: 'Test notes',
        );

        // Assert
        verify(
          mockOrderRepository.createOrder(
            orderNumber: anyNamed('orderNumber'),
            cartItems: anyNamed('cartItems'),
            deliveryAddress: anyNamed('deliveryAddress'),
            subtotal: anyNamed('subtotal'),
            shipping: anyNamed('shipping'),
            tax: anyNamed('tax'),
            total: anyNamed('total'),
            notes: anyNamed('notes'),
          ),
        ).called(1);
        final state = container.read(orderControllerProvider);
        expect(state.currentOrder?.tax, equals(180.0));
      });

      test('should handle repository error', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );

        final cartController = container.read(cartProvider.notifier);
        cartController.add(product);

        final deliveryAddress = OrderAddress(
          name: 'Test User',
          phone: '+1234567890',
          address: '123 Test Street',
          city: 'Test City',
          state: 'Test State',
          pincode: '123456',
        );

        when(
          mockOrderRepository.createOrder(
            orderNumber: anyNamed('orderNumber'),
            cartItems: anyNamed('cartItems'),
            deliveryAddress: anyNamed('deliveryAddress'),
            subtotal: anyNamed('subtotal'),
            shipping: anyNamed('shipping'),
            tax: anyNamed('tax'),
            total: anyNamed('total'),
            notes: anyNamed('notes'),
          ),
        ).thenThrow(Exception('Repository error'));

        // Act
        await orderController.createOrderFromCart(
          deliveryAddress: deliveryAddress,
          notes: 'Test notes',
        );

        // Assert
        final state = container.read(orderControllerProvider);
        expect(state.error, equals('Exception: Repository error'));
        expect(state.loading, isFalse);
        expect(state.currentOrder, isNull);
      });
    });

    group('clearError()', () {
      test('should clear error state', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );

        final cartController = container.read(cartProvider.notifier);
        cartController.add(product);

        final deliveryAddress = OrderAddress(
          name: 'Test User',
          phone: '+1234567890',
          address: '123 Test Street',
          city: 'Test City',
          state: 'Test State',
          pincode: '123456',
        );

        when(
          mockOrderRepository.createOrder(
            orderNumber: anyNamed('orderNumber'),
            cartItems: anyNamed('cartItems'),
            deliveryAddress: anyNamed('deliveryAddress'),
            subtotal: anyNamed('subtotal'),
            shipping: anyNamed('shipping'),
            tax: anyNamed('tax'),
            total: anyNamed('total'),
            notes: anyNamed('notes'),
          ),
        ).thenThrow(Exception('Repository error'));
        await orderController.createOrderFromCart(
          deliveryAddress: deliveryAddress,
          notes: 'Test notes',
        );

        // Act
        orderController.clearError();

        // Assert
        final state = container.read(orderControllerProvider);
        expect(state.error, isNull);
      });
    });

    group('clearCurrentOrder()', () {
      test('should clear current order', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );

        final cartController = container.read(cartProvider.notifier);
        cartController.add(product);

        final deliveryAddress = OrderAddress(
          name: 'Test User',
          phone: '+1234567890',
          address: '123 Test Street',
          city: 'Test City',
          state: 'Test State',
          pincode: '123456',
        );

        final expectedOrder = Order(
          id: 'order1',
          orderNumber: 'ORD-123456',
          orderDate: DateTime.now(),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: 'item1',
              name: 'Test Product',
              image: 'https://example.com/image.jpg',
              price: 100.0,
              quantity: 1,
            ),
          ],
          deliveryAddress: deliveryAddress,
          subtotal: 100.0,
          shipping: 50.0,
          tax: 27.0,
          total: 177.0,
        );

        when(
          mockOrderRepository.createOrder(
            orderNumber: anyNamed('orderNumber'),
            cartItems: anyNamed('cartItems'),
            deliveryAddress: anyNamed('deliveryAddress'),
            subtotal: anyNamed('subtotal'),
            shipping: anyNamed('shipping'),
            tax: anyNamed('tax'),
            total: anyNamed('total'),
            notes: anyNamed('notes'),
          ),
        ).thenAnswer((_) async => expectedOrder);
        await orderController.createOrderFromCart(
          deliveryAddress: deliveryAddress,
          notes: 'Test notes',
        );

        // Verify order was created first
        final stateBefore = container.read(orderControllerProvider);
        expect(stateBefore.currentOrder, isNotNull);

        // Act
        orderController.clearCurrentOrder();

        // Assert
        final state = container.read(orderControllerProvider);
        expect(state.currentOrder, isNull);
      });
    });
  });
}
