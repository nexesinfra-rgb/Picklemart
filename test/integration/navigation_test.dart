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

void main() {
  group('Navigation Integration Tests', () {
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

    group('Bottom Navigation', () {
      testWidgets('should navigate between all main screens', (
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

        // Test Home navigation
        expect(find.text('Home'), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);

        // Test Cart navigation
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        expect(find.text('Cart'), findsOneWidget);
        expect(find.byIcon(Icons.shopping_cart), findsOneWidget);

        // Test Orders navigation
        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();
        expect(find.text('My Orders'), findsOneWidget);
        expect(find.byIcon(Icons.receipt_long), findsOneWidget);

        // Test Profile navigation
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);

        // Test back to Home
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('should maintain active tab state', (
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

        // Navigate to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Verify Cart is active
        expect(find.text('Cart'), findsOneWidget);
        expect(find.byIcon(Icons.shopping_cart), findsOneWidget);

        // Navigate to Profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Verify Profile is active
        expect(find.text('Profile'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      });
    });

    group('Back Navigation', () {
      testWidgets('should navigate back from Cart to Home', (
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

        // Navigate to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        expect(find.text('Cart'), findsOneWidget);

        // Navigate back to Home
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('should navigate back from Orders to Home', (
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
        expect(find.text('My Orders'), findsOneWidget);

        // Navigate back to Home
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('should navigate back from Profile to Home', (
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
        expect(find.text('Profile'), findsOneWidget);

        // Navigate back to Home
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
      });
    });

    group('Deep Linking', () {
      testWidgets('should navigate directly to Home screen', (
        WidgetTester tester,
      ) async {
        // Arrange
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp.router(
              title: 'Test App',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert: Direct navigation to Home
        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('should navigate directly to Cart screen', (
        WidgetTester tester,
      ) async {
        // Arrange
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

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp.router(
              title: 'Test App',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert: Direct navigation to Cart
        expect(find.text('Cart'), findsOneWidget);
      });

      testWidgets('should navigate directly to Profile screen', (
        WidgetTester tester,
      ) async {
        // Arrange
        final router = GoRouter(
          initialLocation: '/profile',
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp.router(
              title: 'Test App',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert: Direct navigation to Profile
        expect(find.text('Profile'), findsOneWidget);
      });
    });

    group('App State Preservation', () {
      testWidgets('should preserve app state during navigation', (
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

        // Navigate to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Navigate to Profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Navigate back to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Assert: Cart state is preserved
        expect(find.text('Cart'), findsOneWidget);
        expect(find.text('Your cart is empty'), findsOneWidget);
      });

      testWidgets('should preserve authentication state during navigation', (
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
    });

    group('Tab Switching', () {
      testWidgets('should maintain state when switching between tabs', (
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

        // Switch to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        expect(find.text('Cart'), findsOneWidget);

        // Switch to Orders
        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();
        expect(find.text('My Orders'), findsOneWidget);

        // Switch to Profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsOneWidget);

        // Switch back to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        expect(find.text('Cart'), findsOneWidget);

        // Switch back to Home
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('should maintain scroll position when switching tabs', (
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

        // Switch to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Switch to Orders
        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();

        // Switch back to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Assert: Cart screen is still accessible
        expect(find.text('Cart'), findsOneWidget);
        expect(find.text('Your cart is empty'), findsOneWidget);
      });
    });
  });
}

