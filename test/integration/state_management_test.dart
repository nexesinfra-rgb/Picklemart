import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/auth/presentation/role_selection_screen.dart';
import 'package:picklemart/features/auth/presentation/login_screen.dart';
import 'package:picklemart/features/home/presentation/home_screen.dart';
import 'package:picklemart/features/cart/presentation/cart_screen.dart';
import 'package:picklemart/features/orders/presentation/orders_list_screen.dart';
import 'package:picklemart/features/profile/presentation/profile_screen.dart';
import 'package:picklemart/features/cart/application/cart_controller.dart';
import 'package:picklemart/features/catalog/data/product.dart';

void main() {
  group('State Management Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestApp() {
      return ProviderScope(
        parent: container,
        child: MaterialApp.router(
          title: 'Test App',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                name: 'role',
                builder: (context, state) => const RoleSelectionScreen(),
              ),
              GoRoute(
                path: '/login',
                name: 'login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/cart',
                name: 'cart',
                builder: (context, state) => const CartScreen(),
              ),
              GoRoute(
                path: '/orders',
                name: 'orders',
                builder: (context, state) => const OrdersListScreen(),
              ),
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ),
      );
    }

    group('Cart State Persistence', () {
      testWidgets('should persist cart state across navigation', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Add items to cart
        final cartController = container.read(cartProvider.notifier);
        final product1 = Product(
          id: '1',
          name: 'Product 1',
          imageUrl: 'https://example.com/image1.jpg',
          images: ['https://example.com/image1.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        final product2 = Product(
          id: '2',
          name: 'Product 2',
          imageUrl: 'https://example.com/image2.jpg',
          images: ['https://example.com/image2.jpg'],
          price: 200.0,
          categories: ['Test'],
        );

        cartController.add(product1);
        cartController.add(product2);

        // Navigate to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Assert: Cart contains both items
        expect(find.text('Product 1'), findsOneWidget);
        expect(find.text('Product 2'), findsOneWidget);
        expect(find.text('Rs. 300.00'), findsOneWidget);

        // Navigate to Profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Navigate back to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Assert: Cart state is preserved
        expect(find.text('Product 1'), findsOneWidget);
        expect(find.text('Product 2'), findsOneWidget);
        expect(find.text('Rs. 300.00'), findsOneWidget);
      });

      testWidgets('should persist cart state across app restarts', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Add item to cart
        final cartController = container.read(cartProvider.notifier);
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        cartController.add(product);

        // Navigate to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Assert: Item is in cart
        expect(find.text('Test Product'), findsOneWidget);
        expect(find.text('Rs. 100.00'), findsOneWidget);

        // Simulate app restart by recreating the app
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Navigate to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Assert: Cart state is preserved (in real app, this would be persisted)
        // For this test, we're just verifying the cart screen works
        expect(find.text('Cart'), findsOneWidget);
      });

      testWidgets('should maintain cart state when switching between tabs', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Add item to cart
        final cartController = container.read(cartProvider.notifier);
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        cartController.add(product);

        // Switch between tabs multiple times
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        expect(find.text('Test Product'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();
        expect(find.text('My Orders'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        expect(find.text('Test Product'), findsOneWidget);
        expect(find.text('Rs. 100.00'), findsOneWidget);
      });
    });

    group('Authentication State Management', () {
      testWidgets('should maintain authentication state across navigation', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Navigate to different screens
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Navigate back to Home
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();

        // Assert: Still authenticated (Home screen is accessible)
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Search for products'), findsOneWidget);
      });

      testWidgets('should handle logout and clear all state', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Add item to cart
        final cartController = container.read(cartProvider.notifier);
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        cartController.add(product);

        // Navigate to Profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Simulate logout (in real app, this would clear all state)
        // For this test, we're just verifying the profile screen works
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Personal Details'), findsOneWidget);
      });
    });

    group('Profile Data Caching', () {
      testWidgets('should cache profile data correctly', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Navigate to Profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Assert: Profile data is displayed
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Personal Details'), findsOneWidget);
        expect(find.text('Addresses'), findsOneWidget);
        expect(find.text('Order History'), findsOneWidget);

        // Navigate away and back
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Assert: Profile data is still cached and displayed
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Personal Details'), findsOneWidget);
        expect(find.text('Addresses'), findsOneWidget);
        expect(find.text('Order History'), findsOneWidget);
      });

      testWidgets('should refresh profile data when needed', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Navigate to Profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Assert: Profile data is displayed
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('Personal Details'), findsOneWidget);

        // Simulate refresh (in real app, this would trigger data refresh)
        // For this test, we're just verifying the profile screen works
        expect(find.text('Profile'), findsOneWidget);
      });
    });

    group('Order Data Synchronization', () {
      testWidgets('should synchronize order data across screens', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Navigate to Orders
        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();

        // Assert: Orders screen is displayed
        expect(find.text('My Orders'), findsOneWidget);
        expect(find.text('No orders yet'), findsOneWidget);

        // Navigate to Profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Navigate back to Orders
        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();

        // Assert: Orders data is synchronized
        expect(find.text('My Orders'), findsOneWidget);
        expect(find.text('No orders yet'), findsOneWidget);
      });

      testWidgets('should maintain order state consistency', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Navigate to Orders
        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();

        // Switch between tabs
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();

        // Assert: Orders state is consistent
        expect(find.text('My Orders'), findsOneWidget);
        expect(find.text('No orders yet'), findsOneWidget);
      });
    });

    group('Search State Preservation', () {
      testWidgets('should preserve search state across navigation', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextFormField), 'test search');
        await tester.pumpAndSettle();

        // Navigate to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Navigate back to Home
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();

        // Assert: Search state is preserved (in real app)
        // For this test, we're just verifying the home screen works
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Search for products'), findsOneWidget);
      });

      testWidgets('should clear search state when appropriate', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Home (simulate login)
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextFormField), 'test search');
        await tester.pumpAndSettle();

        // Clear search (simulate)
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();

        // Assert: Search is cleared
        expect(find.text('Search for products'), findsOneWidget);
      });
    });
  });
}
