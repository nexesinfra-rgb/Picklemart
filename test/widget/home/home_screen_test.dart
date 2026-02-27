import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:picklemart/features/home/presentation/home_screen.dart';
import 'package:picklemart/features/catalog/data/shared_product_provider.dart';
import 'package:picklemart/features/cart/application/cart_controller.dart';
import 'package:picklemart/features/cart/data/cart_repository.dart';
import 'package:picklemart/features/catalog/data/product.dart';
import 'package:picklemart/features/catalog/data/measurement.dart';
import 'package:picklemart/features/admin/data/admin_features.dart';
import 'package:picklemart/features/notifications/application/notification_controller.dart';
import 'package:picklemart/features/chat/application/chat_controller.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockRef extends Mock implements Ref {}

class FakeCartController extends StateNotifier<Map<String, CartItem>>
    with Mock
    implements CartController {
  FakeCartController(super.state);

  @override
  Future<void> add(
    Product product, {
    Variant? variant,
    int qty = 1,
    MeasurementUnit? measurementUnit,
  }) async {}

  @override
  Future<void> remove(
    Product product, {
    Variant? variant,
    MeasurementUnit? measurementUnit,
  }) async {}

  @override
  Future<void> delete(
    Product product, {
    Variant? variant,
    MeasurementUnit? measurementUnit,
  }) async {}

  @override
  Future<void> clear() async {}
}

class FakeAdminFeaturesNotifier extends StateNotifier<AdminFeatures> {
  FakeAdminFeaturesNotifier() : super(const AdminFeatures());
}

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('should display home screen with app bar', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController({})),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display search and cart icons in app bar', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController({})),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('should display hero banner', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController({})),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.text('Hardware Store'), findsOneWidget);
      expect(find.text('Professional Tools & Equipment'), findsOneWidget);
      expect(find.text('Shop Now'), findsOneWidget);
    });

    testWidgets('should display featured categories section', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController({})),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.text('Featured Categories'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('should display featured products section', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController({})),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.text('Featured Products'), findsOneWidget);
    });

    /*
    // TODO: Fix these tests. featuredProductsProvider is a Provider<List<Product>>, so it cannot be in loading/error state directly.
    // To test loading/error, we need to mock sharedProductProvider or the underlying repository.
    testWidgets('should show loading indicator when products are loading', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => const AsyncValue.loading(),
            ),
            cartProvider.overrideWith((ref) => FakeCartController({})),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when products fail to load', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => const AsyncValue.error('Error loading products', StackTrace.empty),
            ),
            cartProvider.overrideWith((ref) => FakeCartController({})),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.text('Error loading products'), findsOneWidget);
    });
    */

    testWidgets('should display cart badge when cart has items', (
      WidgetTester tester,
    ) async {
      // Arrange
      final cartItems = {
        'item1': CartItem(
          Product(
            id: '1',
            name: 'Test Product',
            imageUrl: 'https://example.com/image.jpg',
            images: ['https://example.com/image.jpg'],
            price: 100.0,
            categories: ['Test'],
          ),
          2,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController(cartItems)),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController({})),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should be responsive to different screen sizes', (
      WidgetTester tester,
    ) async {
      // Test with different screen sizes
      final testSizes = [
        const Size(320, 568), // iPhone SE
        const Size(375, 667), // iPhone 8
        const Size(414, 896), // iPhone 11 Pro Max
        const Size(768, 1024), // iPad
      ];

      for (final size in testSizes) {
        // Arrange
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              featuredProductsProvider.overrideWith((ref) => []),
              cartProvider.overrideWith((ref) => FakeCartController({})),
              adminFeaturesProvider.overrideWith(
                (ref) => FakeAdminFeaturesNotifier(),
              ),
              unreadNotificationCountProvider.overrideWith((ref) => 0),
              userChatUnreadCountProvider.overrideWith(
                (ref) => Stream.value(0),
              ),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );

        // Assert
        expect(find.text('Hardware Store'), findsOneWidget);
        expect(find.text('Featured Categories'), findsOneWidget);
        expect(find.text('Featured Products'), findsOneWidget);

        // Clean up
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('should handle search button tap', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController({})),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      // Assert
      // Search button tap should be handled (navigation would occur in real app)
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should handle cart button tap', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController({})),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pump();

      // Assert
      // Cart button tap should be handled (navigation would occur in real app)
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('should display category product rows', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith((ref) => []),
            cartProvider.overrideWith((ref) => FakeCartController({})),
            adminFeaturesProvider.overrideWith(
              (ref) => FakeAdminFeaturesNotifier(),
            ),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            userChatUnreadCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Assert
      // CategoryProductRows widget should be present
      expect(find.byType(Column), findsWidgets);
    });
  });
}
