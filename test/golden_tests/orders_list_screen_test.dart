import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/orders/presentation/orders_list_screen.dart';
import 'package:picklemart/features/orders/data/order_repository.dart';
import 'package:picklemart/features/orders/data/order_model.dart';

void main() {
  group('Orders List Screen Golden Tests', () {
    testWidgets('Orders List Screen - Mobile Portrait (375x812)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersListScreen(),
          ),
          GoRoute(
            path: '/order-detail/:id',
            name: 'order-detail',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Order Detail Screen')),
                ),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Home Screen'))),
          ),
        ],
      );

      // Create mock orders
      final mockOrders = [
        Order(
          id: '1',
          orderNumber: 'ORD-001',
          orderDate: DateTime.now().subtract(const Duration(days: 2)),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: '1',
              name: 'Test Product 1',
              image: 'https://via.placeholder.com/150',
              quantity: 2,
              price: 100.0,
            ),
            OrderItem(
              id: '2',
              name: 'Test Product 2',
              image: 'https://via.placeholder.com/150',
              quantity: 1,
              price: 200.0,
            ),
          ],
          deliveryAddress: OrderAddress(
            name: 'John Doe',
            phone: '+1234567890',
            address: '123 Main St',
            city: 'Test City',
            state: 'Test State',
            pincode: '12345',
          ),
          subtotal: 300.0,
          shipping: 10.0,
          tax: 30.0,
          total: 340.0,
        ),
        Order(
          id: '2',
          orderNumber: 'ORD-002',
          orderDate: DateTime.now().subtract(const Duration(days: 5)),
          status: OrderStatus.delivered,
          items: [
            OrderItem(
              id: '3',
              name: 'Test Product 3',
              image: 'https://via.placeholder.com/150',
              quantity: 1,
              price: 150.0,
            ),
          ],
          deliveryAddress: OrderAddress(
            name: 'Jane Doe',
            phone: '+0987654321',
            address: '456 Oak Ave',
            city: 'Test City',
            state: 'Test State',
            pincode: '12345',
          ),
          subtotal: 150.0,
          shipping: 10.0,
          tax: 15.0,
          total: 175.0,
        ),
      ];

      // Create a mock order repository
      final mockOrderRepository = InMemoryOrderRepository();
      for (final order in mockOrders) {
        await mockOrderRepository.createOrder(
          orderNumber: order.orderNumber,
          cartItems: [], // Empty for this test
          deliveryAddress: order.deliveryAddress,
          subtotal: order.subtotal,
          shipping: order.shipping,
          tax: order.tax,
          total: order.total,
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          ],
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the screen elements are present
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('Order #ORD-001'), findsOneWidget);
      expect(find.text('Order #ORD-002'), findsOneWidget);
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Rs. 340.00'), findsOneWidget);
      expect(find.text('Rs. 175.00'), findsOneWidget);
      expect(find.text('View Details'), findsNWidgets(2));

      // Generate golden file
      await expectLater(
        find.byType(OrdersListScreen),
        matchesGoldenFile('orders_list_screen_mobile_portrait.png'),
      );
    });

    testWidgets('Orders List Screen - Mobile Landscape (812x375)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(812, 375));

      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersListScreen(),
          ),
        ],
      );

      final mockOrders = [
        Order(
          id: '1',
          orderNumber: 'ORD-001',
          orderDate: DateTime.now().subtract(const Duration(days: 2)),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: '1',
              name: 'Test Product 1',
              image: 'https://via.placeholder.com/150',
              quantity: 2,
              price: 100.0,
            ),
          ],
          deliveryAddress: OrderAddress(
            name: 'John Doe',
            phone: '+1234567890',
            address: '123 Main St',
            city: 'Test City',
            state: 'Test State',
            pincode: '12345',
          ),
          subtotal: 100.0,
          shipping: 10.0,
          tax: 10.0,
          total: 120.0,
        ),
      ];

      final mockOrderRepository = InMemoryOrderRepository();
      for (final order in mockOrders) {
        await mockOrderRepository.createOrder(
          orderNumber: order.orderNumber,
          cartItems: [],
          deliveryAddress: order.deliveryAddress,
          subtotal: order.subtotal,
          shipping: order.shipping,
          tax: order.tax,
          total: order.total,
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          ],
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(OrdersListScreen),
        matchesGoldenFile('orders_list_screen_mobile_landscape.png'),
      );
    });

    testWidgets('Orders List Screen - Tablet Portrait (768x1024)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersListScreen(),
          ),
        ],
      );

      final mockOrders = [
        Order(
          id: '1',
          orderNumber: 'ORD-001',
          orderDate: DateTime.now().subtract(const Duration(days: 2)),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: '1',
              name: 'Test Product 1',
              image: 'https://via.placeholder.com/150',
              quantity: 2,
              price: 100.0,
            ),
          ],
          deliveryAddress: OrderAddress(
            name: 'John Doe',
            phone: '+1234567890',
            address: '123 Main St',
            city: 'Test City',
            state: 'Test State',
            pincode: '12345',
          ),
          subtotal: 100.0,
          shipping: 10.0,
          tax: 10.0,
          total: 120.0,
        ),
      ];

      final mockOrderRepository = InMemoryOrderRepository();
      for (final order in mockOrders) {
        await mockOrderRepository.createOrder(
          orderNumber: order.orderNumber,
          cartItems: [],
          deliveryAddress: order.deliveryAddress,
          subtotal: order.subtotal,
          shipping: order.shipping,
          tax: order.tax,
          total: order.total,
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          ],
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(OrdersListScreen),
        matchesGoldenFile('orders_list_screen_tablet_portrait.png'),
      );
    });

    testWidgets('Orders List Screen - Tablet Landscape (1024x768)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersListScreen(),
          ),
        ],
      );

      final mockOrders = [
        Order(
          id: '1',
          orderNumber: 'ORD-001',
          orderDate: DateTime.now().subtract(const Duration(days: 2)),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: '1',
              name: 'Test Product 1',
              image: 'https://via.placeholder.com/150',
              quantity: 2,
              price: 100.0,
            ),
          ],
          deliveryAddress: OrderAddress(
            name: 'John Doe',
            phone: '+1234567890',
            address: '123 Main St',
            city: 'Test City',
            state: 'Test State',
            pincode: '12345',
          ),
          subtotal: 100.0,
          shipping: 10.0,
          tax: 10.0,
          total: 120.0,
        ),
      ];

      final mockOrderRepository = InMemoryOrderRepository();
      for (final order in mockOrders) {
        await mockOrderRepository.createOrder(
          orderNumber: order.orderNumber,
          cartItems: [],
          deliveryAddress: order.deliveryAddress,
          subtotal: order.subtotal,
          shipping: order.shipping,
          tax: order.tax,
          total: order.total,
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          ],
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(OrdersListScreen),
        matchesGoldenFile('orders_list_screen_tablet_landscape.png'),
      );
    });

    testWidgets('Orders List Screen - Desktop (1440x900)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));

      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersListScreen(),
          ),
        ],
      );

      final mockOrders = [
        Order(
          id: '1',
          orderNumber: 'ORD-001',
          orderDate: DateTime.now().subtract(const Duration(days: 2)),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: '1',
              name: 'Test Product 1',
              image: 'https://via.placeholder.com/150',
              quantity: 2,
              price: 100.0,
            ),
          ],
          deliveryAddress: OrderAddress(
            name: 'John Doe',
            phone: '+1234567890',
            address: '123 Main St',
            city: 'Test City',
            state: 'Test State',
            pincode: '12345',
          ),
          subtotal: 100.0,
          shipping: 10.0,
          tax: 10.0,
          total: 120.0,
        ),
      ];

      final mockOrderRepository = InMemoryOrderRepository();
      for (final order in mockOrders) {
        await mockOrderRepository.createOrder(
          orderNumber: order.orderNumber,
          cartItems: [],
          deliveryAddress: order.deliveryAddress,
          subtotal: order.subtotal,
          shipping: order.shipping,
          tax: order.tax,
          total: order.total,
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          ],
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(OrdersListScreen),
        matchesGoldenFile('orders_list_screen_desktop.png'),
      );
    });

    testWidgets('Orders List Screen - Empty State', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));

      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersListScreen(),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Home Screen'))),
          ),
        ],
      );

      // Create empty order repository
      final emptyOrderRepository = InMemoryOrderRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(emptyOrderRepository),
          ],
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No orders yet'), findsOneWidget);
      expect(find.text('Your orders will appear here'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);

      await expectLater(
        find.byType(OrdersListScreen),
        matchesGoldenFile('orders_list_screen_empty.png'),
      );
    });

    testWidgets('Orders List Screen - Order Detail Navigation', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));

      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersListScreen(),
          ),
          GoRoute(
            path: '/order-detail/:id',
            name: 'order-detail',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Order Detail Screen')),
                ),
          ),
        ],
      );

      final mockOrders = [
        Order(
          id: '1',
          orderNumber: 'ORD-001',
          orderDate: DateTime.now().subtract(const Duration(days: 2)),
          status: OrderStatus.confirmed,
          items: [
            OrderItem(
              id: '1',
              name: 'Test Product 1',
              image: 'https://via.placeholder.com/150',
              quantity: 2,
              price: 100.0,
            ),
          ],
          deliveryAddress: OrderAddress(
            name: 'John Doe',
            phone: '+1234567890',
            address: '123 Main St',
            city: 'Test City',
            state: 'Test State',
            pincode: '12345',
          ),
          subtotal: 100.0,
          shipping: 10.0,
          tax: 10.0,
          total: 120.0,
        ),
      ];

      final mockOrderRepository = InMemoryOrderRepository();
      for (final order in mockOrders) {
        await mockOrderRepository.createOrder(
          orderNumber: order.orderNumber,
          cartItems: [],
          deliveryAddress: order.deliveryAddress,
          subtotal: order.subtotal,
          shipping: order.shipping,
          tax: order.tax,
          total: order.total,
        );
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockOrderRepository),
          ],
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test order detail navigation
      await tester.tap(find.text('View Details').first);
      await tester.pumpAndSettle();

      expect(find.text('Order Detail Screen'), findsOneWidget);
    });
  });
}
