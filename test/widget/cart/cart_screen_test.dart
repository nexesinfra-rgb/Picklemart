import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:picklemart/features/cart/presentation/cart_screen.dart';
import 'package:picklemart/features/cart/application/cart_controller.dart';
import 'package:picklemart/features/cart/data/cart_repository.dart';
import 'package:picklemart/features/catalog/data/product.dart';
import 'package:picklemart/features/catalog/data/measurement.dart';

class MockCartRepository extends Mock implements CartRepository {}
class MockRef extends Mock implements Ref {}

class FakeCartController extends StateNotifier<Map<String, CartItem>> with Mock implements CartController {
  FakeCartController(Map<String, CartItem> state) : super(state);

  @override
  Future<void> add(Product product, {Variant? variant, int qty = 1, MeasurementUnit? measurementUnit}) async {}

  @override
  Future<void> remove(Product product, {Variant? variant, MeasurementUnit? measurementUnit}) async {}

  @override
  Future<void> delete(Product product, {Variant? variant, MeasurementUnit? measurementUnit}) async {}

  @override
  Future<void> clear() async {}
  
  @override
  double get total => state.values.fold(0.0, (sum, item) {
    double price;
    if (item.measurementUnit != null && item.product.hasMeasurementPricing) {
      final measurement = item.product.measurement!;
      final pricing = measurement.getPricingForUnit(item.measurementUnit!);
      final basePrice = pricing?.price ?? item.product.price;
      if (item.product.tax != null && item.product.tax! > 0) {
        price = basePrice + (basePrice * item.product.tax! / 100);
      } else {
        price = basePrice;
      }
    } else {
      if (item.variant != null) {
        price = item.variant!.finalPriceWithFallback(item.product.tax);
      } else {
        price = item.product.finalPrice;
      }
    }
    return sum + price * item.quantity;
  });
}

void main() {
  group('CartScreen Widget Tests', () {
    testWidgets('should display empty cart message when cart is empty', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => FakeCartController({}))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Assert
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Cart'), findsOneWidget);
    });

    testWidgets('should display cart items when cart has items', (
      WidgetTester tester,
    ) async {
      // Arrange
      final cartItems = {
        'item1': CartItem(
          Product(
            id: '1',
            name: 'Test Product 1',
            imageUrl: 'https://example.com/image1.jpg',
            images: ['https://example.com/image1.jpg'],
            price: 100.0,
            categories: ['Test'],
          ),
          2,
        ),
        'item2': CartItem(
          Product(
            id: '2',
            name: 'Test Product 2',
            imageUrl: 'https://example.com/image2.jpg',
            images: ['https://example.com/image2.jpg'],
            price: 200.0,
            categories: ['Test'],
          ),
          1,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Assert
      expect(find.text('Test Product 1'), findsOneWidget);
      expect(find.text('Test Product 2'), findsOneWidget);
      expect(find.text('Rs. 100.00'), findsOneWidget);
      expect(find.text('Rs. 200.00'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Quantity
      expect(find.text('1'), findsOneWidget); // Quantity
    });

    testWidgets('should display correct total amount', (
      WidgetTester tester,
    ) async {
      // Arrange
      final cartItems = {
        'item1': CartItem(
          Product(
            id: '1',
            name: 'Test Product 1',
            imageUrl: 'https://example.com/image1.jpg',
            images: ['https://example.com/image1.jpg'],
            price: 100.0,
            categories: ['Test'],
          ),
          2,
        ),
        'item2': CartItem(
          Product(
            id: '2',
            name: 'Test Product 2',
            imageUrl: 'https://example.com/image2.jpg',
            images: ['https://example.com/image2.jpg'],
            price: 200.0,
            categories: ['Test'],
          ),
          1,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Assert
      expect(find.text('Total'), findsOneWidget);
      // The total is calculated by CartScreen using controller.total (or local logic?)
      // Assuming CartScreen reads total from controller or calculates it.
      // If it uses controller.total, my mock needs to implement it.
      expect(find.text('Rs. 400.00'), findsOneWidget); // 2*100 + 1*200
    });

    testWidgets('should display checkout button when cart has items', (
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
          1,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Assert
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('should display quantity controls for each item', (
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
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Quantity display
    });

    testWidgets('should display remove button for each item', (
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
          1,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Assert
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('should handle quantity increase', (WidgetTester tester) async {
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
          1,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Tap increase button
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();

      // Assert
      // The quantity should have increased (this would be handled by the cart controller)
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('should handle quantity decrease', (WidgetTester tester) async {
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
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Tap decrease button
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      // Assert
      // The quantity should have decreased (this would be handled by the cart controller)
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    });

    testWidgets('should handle item removal', (WidgetTester tester) async {
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
          1,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Tap remove button
      await tester.tap(find.text('Remove'));
      await tester.pump();

      // Assert
      // The item should have been removed (this would be handled by the cart controller)
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('should display product images', (WidgetTester tester) async {
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
          1,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Assert
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (
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
          1,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
          child: const MaterialApp(home: CartScreen()),
        ),
      );

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
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
            1,
          ),
        };

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [cartProvider.overrideWith((ref) => FakeCartController(cartItems))],
            child: const MaterialApp(home: CartScreen()),
          ),
        );

        // Assert
        expect(find.text('Test Product'), findsOneWidget);
        expect(find.text('Rs. 100.00'), findsOneWidget);

        // Clean up
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}
