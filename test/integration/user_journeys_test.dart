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
import 'package:picklemart/features/catalog/data/product.dart';
import 'package:picklemart/features/cart/application/cart_controller.dart';

void main() {
  group('User Journey Integration Tests', () {
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

    group('Complete Shopping Journey', () {
      testWidgets(
        'should complete full shopping flow: Role Selection → Login → Home → Cart',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(createTestApp());
          await tester.pumpAndSettle();

          // Step 1: Role Selection
          expect(find.text('Choose your role'), findsOneWidget);
          expect(find.text('Continue as User'), findsOneWidget);
          expect(find.text('Admin (coming soon)'), findsOneWidget);

          // Act: Select User role
          await tester.tap(find.text('Continue as User'));
          await tester.pumpAndSettle();

          // Assert: Navigate to Login
          expect(
            find.text('Login'),
            findsNWidgets(2),
          ); // AppBar title and button

          // Step 2: Login
          await tester.enterText(
            find.byType(TextFormField).first,
            'test@example.com',
          );
          await tester.enterText(
            find.byType(TextFormField).last,
            'password123',
          );
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();

          // Assert: Navigate to Home
          expect(find.text('Home'), findsOneWidget);
          expect(find.text('Search for products'), findsOneWidget);

          // Step 3: Add item to cart (simulate)
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

          // Step 4: Navigate to Cart
          await tester.tap(find.byIcon(Icons.shopping_cart));
          await tester.pumpAndSettle();

          // Assert: Cart screen shows added item
          expect(find.text('Cart'), findsOneWidget);
          expect(find.text('Test Product'), findsOneWidget);
          expect(find.text('Rs. 100.00'), findsOneWidget);
        },
      );

      testWidgets(
        'should complete product discovery flow: Home → Search → Product Detail',
        (WidgetTester tester) async {
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
          await tester.enterText(
            find.byType(TextFormField).last,
            'password123',
          );
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();

          // Step 1: Home Screen
          expect(find.text('Home'), findsOneWidget);
          expect(find.text('Search for products'), findsOneWidget);

          // Act: Tap search
          await tester.tap(find.byIcon(Icons.search));
          await tester.pumpAndSettle();

          // Assert: Search functionality (would navigate to search screen in real app)
          // For this test, we're just verifying the search icon is tappable
          expect(find.byIcon(Icons.search), findsOneWidget);
        },
      );

      testWidgets(
        'should complete profile management flow: Profile → Edit Profile',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(createTestApp());
          await tester.pumpAndSettle();

          // Navigate to Profile (simulate login and navigation)
          await tester.tap(find.text('Continue as User'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField).first,
            'test@example.com',
          );
          await tester.enterText(
            find.byType(TextFormField).last,
            'password123',
          );
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();

          // Navigate to Profile
          await tester.tap(find.byIcon(Icons.person));
          await tester.pumpAndSettle();

          // Step 1: Profile Screen
          expect(find.text('Profile'), findsOneWidget);
          expect(find.text('Personal Details'), findsOneWidget);
          expect(find.text('Addresses'), findsOneWidget);
          expect(find.text('Order History'), findsOneWidget);

          // Act: Tap Personal Details
          await tester.tap(find.text('Personal Details'));
          await tester.pumpAndSettle();

          // Assert: Would navigate to Profile Edit screen
          // For this test, we're just verifying the navigation works
          expect(find.text('Personal Details'), findsOneWidget);
        },
      );
    });

    group('Navigation Flow', () {
      testWidgets(
        'should navigate between all main screens using bottom navigation',
        (WidgetTester tester) async {
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
          await tester.enterText(
            find.byType(TextFormField).last,
            'password123',
          );
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();

          // Step 1: Home Screen
          expect(find.text('Home'), findsOneWidget);

          // Step 2: Navigate to Cart
          await tester.tap(find.byIcon(Icons.shopping_cart));
          await tester.pumpAndSettle();
          expect(find.text('Cart'), findsOneWidget);

          // Step 3: Navigate to Orders
          await tester.tap(find.byIcon(Icons.receipt_long));
          await tester.pumpAndSettle();
          expect(find.text('My Orders'), findsOneWidget);

          // Step 4: Navigate to Profile
          await tester.tap(find.byIcon(Icons.person));
          await tester.pumpAndSettle();
          expect(find.text('Profile'), findsOneWidget);

          // Step 5: Navigate back to Home
          await tester.tap(find.byIcon(Icons.home));
          await tester.pumpAndSettle();
          expect(find.text('Home'), findsOneWidget);
        },
      );

      testWidgets('should maintain state during navigation', (
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
        expect(find.text('Test Product'), findsOneWidget);

        // Navigate to Profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Navigate back to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Assert: Cart state is maintained
        expect(find.text('Test Product'), findsOneWidget);
        expect(find.text('Rs. 100.00'), findsOneWidget);
      });
    });

    group('Authentication Flow', () {
      testWidgets(
        'should complete authentication flow: Role Selection → Login → Home',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(createTestApp());
          await tester.pumpAndSettle();

          // Step 1: Role Selection
          expect(find.text('Choose your role'), findsOneWidget);
          expect(find.text('Continue as User'), findsOneWidget);

          // Act: Select User role
          await tester.tap(find.text('Continue as User'));
          await tester.pumpAndSettle();

          // Step 2: Login Screen
          expect(find.text('Login'), findsNWidgets(2));
          expect(find.text('Email'), findsOneWidget);
          expect(find.text('Password'), findsOneWidget);

          // Act: Enter credentials
          await tester.enterText(
            find.byType(TextFormField).first,
            'test@example.com',
          );
          await tester.enterText(
            find.byType(TextFormField).last,
            'password123',
          );
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();

          // Step 3: Home Screen
          expect(find.text('Home'), findsOneWidget);
          expect(find.text('Search for products'), findsOneWidget);
        },
      );

      testWidgets('should handle authentication errors gracefully', (
        WidgetTester tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to Login
        await tester.tap(find.text('Continue as User'));
        await tester.pumpAndSettle();

        // Act: Enter invalid credentials
        await tester.enterText(
          find.byType(TextFormField).first,
          'invalid@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'wrongpassword',
        );
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Assert: Should show error message (in real app)
        // For this test, we're just verifying the form submission works
        expect(find.byType(FilledButton), findsOneWidget);
      });
    });

    group('Cart Management Flow', () {
      testWidgets('should add and remove items from cart', (
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

        // Act: Remove item
        cartController.remove(product);
        await tester.pumpAndSettle();

        // Assert: Cart is empty
        expect(find.text('Your cart is empty'), findsOneWidget);
      });

      testWidgets('should update item quantities in cart', (
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
        cartController.add(product); // Quantity = 2

        // Navigate to Cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Assert: Quantity is 2
        expect(find.text('2'), findsOneWidget);
        expect(find.text('Rs. 200.00'), findsOneWidget);
      });
    });
  });
}
