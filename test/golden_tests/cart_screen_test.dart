import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/cart/presentation/cart_screen.dart';
import 'package:picklemart/features/cart/application/cart_controller.dart';
import 'package:picklemart/features/catalog/data/product.dart';
import 'package:picklemart/features/catalog/data/measurement.dart';

void main() {
  group('Cart Screen Golden Tests', () {
    testWidgets('Cart Screen - Mobile Portrait (375x812)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/cart',
        routes: [
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/checkout-address',
            name: 'checkout-address',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Checkout Address Screen')),
                ),
          ),
        ],
      );

      // Create mock cart items
      final mockProducts = [
        Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://via.placeholder.com/150',
          images: ['https://via.placeholder.com/150'],
          price: 100.0,
          categories: ['Test Category'],
        ),
        Product(
          id: '2',
          name: 'Test Product 2',
          imageUrl: 'https://via.placeholder.com/150',
          images: ['https://via.placeholder.com/150'],
          price: 200.0,
          categories: ['Test Category'],
          measurement: ProductMeasurement(
            productId: '2',
            defaultUnit: MeasurementUnit.kg,
            pricingOptions: [
              MeasurementPricing(unit: MeasurementUnit.kg, price: 200.0),
            ],
          ),
        ),
      ];

      final mockCartItems = [
        CartItem(mockProducts[0], 2),
        CartItem(mockProducts[1], 1, measurementUnit: MeasurementUnit.kg),
      ];

      // Create a mock cart provider
      final mockCartProvider = StateProvider<Map<String, CartItem>>((ref) {
        final cart = <String, CartItem>{};
        for (final item in mockCartItems) {
          cart[item.key] = item;
        }
        return cart;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => CartController())],
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
      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('Test Product 1'), findsOneWidget);
      expect(find.text('Test Product 2'), findsOneWidget);
      expect(find.text('Rs. 100.00'), findsOneWidget);
      expect(find.text('Rs. 200.00'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);

      // Generate golden file
      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_mobile_portrait.png'),
      );
    });

    testWidgets('Cart Screen - Mobile Landscape (812x375)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(812, 375));

      final router = GoRouter(
        initialLocation: '/cart',
        routes: [
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
        ],
      );

      final mockProducts = [
        Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://via.placeholder.com/150',
          images: ['https://via.placeholder.com/150'],
          price: 100.0,
          categories: ['Test Category'],
        ),
      ];

      final mockCartItems = [CartItem(mockProducts[0], 2)];

      final mockCartProvider = StateProvider<Map<String, CartItem>>((ref) {
        final cart = <String, CartItem>{};
        for (final item in mockCartItems) {
          cart[item.key] = item;
        }
        return cart;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => CartController())],
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
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_mobile_landscape.png'),
      );
    });

    testWidgets('Cart Screen - Tablet Portrait (768x1024)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      final router = GoRouter(
        initialLocation: '/cart',
        routes: [
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
        ],
      );

      final mockProducts = [
        Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://via.placeholder.com/150',
          images: ['https://via.placeholder.com/150'],
          price: 100.0,
          categories: ['Test Category'],
        ),
      ];

      final mockCartItems = [CartItem(mockProducts[0], 2)];

      final mockCartProvider = StateProvider<Map<String, CartItem>>((ref) {
        final cart = <String, CartItem>{};
        for (final item in mockCartItems) {
          cart[item.key] = item;
        }
        return cart;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => CartController())],
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
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_tablet_portrait.png'),
      );
    });

    testWidgets('Cart Screen - Tablet Landscape (1024x768)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      final router = GoRouter(
        initialLocation: '/cart',
        routes: [
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
        ],
      );

      final mockProducts = [
        Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://via.placeholder.com/150',
          images: ['https://via.placeholder.com/150'],
          price: 100.0,
          categories: ['Test Category'],
        ),
      ];

      final mockCartItems = [CartItem(mockProducts[0], 2)];

      final mockCartProvider = StateProvider<Map<String, CartItem>>((ref) {
        final cart = <String, CartItem>{};
        for (final item in mockCartItems) {
          cart[item.key] = item;
        }
        return cart;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => CartController())],
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
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_tablet_landscape.png'),
      );
    });

    testWidgets('Cart Screen - Desktop (1440x900)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));

      final router = GoRouter(
        initialLocation: '/cart',
        routes: [
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
        ],
      );

      final mockProducts = [
        Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://via.placeholder.com/150',
          images: ['https://via.placeholder.com/150'],
          price: 100.0,
          categories: ['Test Category'],
        ),
      ];

      final mockCartItems = [CartItem(mockProducts[0], 2)];

      final mockCartProvider = StateProvider<Map<String, CartItem>>((ref) {
        final cart = <String, CartItem>{};
        for (final item in mockCartItems) {
          cart[item.key] = item;
        }
        return cart;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => CartController())],
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
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_desktop.png'),
      );
    });

    testWidgets('Cart Screen - Empty Cart', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));

      final router = GoRouter(
        initialLocation: '/cart',
        routes: [
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
        ],
      );

      // Create empty cart provider
      final emptyCartProvider = StateProvider<Map<String, CartItem>>(
        (ref) => {},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => CartController())],
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

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Cart'), findsOneWidget);

      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_empty.png'),
      );
    });

    testWidgets('Cart Screen - Checkout Navigation', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));

      final router = GoRouter(
        initialLocation: '/cart',
        routes: [
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/checkout-address',
            name: 'checkout-address',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Checkout Address Screen')),
                ),
          ),
        ],
      );

      final mockProducts = [
        Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://via.placeholder.com/150',
          images: ['https://via.placeholder.com/150'],
          price: 100.0,
          categories: ['Test Category'],
        ),
      ];

      final mockCartItems = [CartItem(mockProducts[0], 2)];

      final mockCartProvider = StateProvider<Map<String, CartItem>>((ref) {
        final cart = <String, CartItem>{};
        for (final item in mockCartItems) {
          cart[item.key] = item;
        }
        return cart;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => CartController())],
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

      // Test checkout button tap
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();

      expect(find.text('Checkout Address Screen'), findsOneWidget);
    });
  });
}
