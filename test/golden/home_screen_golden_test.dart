import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/home/presentation/home_screen.dart';
import 'package:picklemart/features/catalog/data/shared_product_provider.dart';
import 'package:picklemart/features/cart/application/cart_controller.dart';
import 'package:picklemart/features/catalog/data/product.dart';

void main() {
  group('HomeScreen Golden Tests', () {
    testWidgets('home screen mobile portrait', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final mockProducts = [
        Product(
          id: '1',
          name: 'Cordless Drill',
          imageUrl: 'https://picsum.photos/seed/drill/300/300',
          images: ['https://picsum.photos/seed/drill/300/300'],
          price: 79.99,
          categories: ['Power Tools'],
          brand: 'DeWalt',
        ),
        Product(
          id: '2',
          name: 'Claw Hammer',
          imageUrl: 'https://picsum.photos/seed/hammer/300/300',
          images: ['https://picsum.photos/seed/hammer/300/300'],
          price: 14.99,
          categories: ['Hand Tools'],
          brand: 'Stanley',
        ),
      ];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => AsyncValue.data(mockProducts),
            ),
            cartProvider.overrideWith((ref) => {}),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_mobile_portrait.png'),
      );
    });

    testWidgets('home screen mobile landscape', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(667, 375);
      tester.view.devicePixelRatio = 1.0;

      final mockProducts = [
        Product(
          id: '1',
          name: 'Cordless Drill',
          imageUrl: 'https://picsum.photos/seed/drill/300/300',
          images: ['https://picsum.photos/seed/drill/300/300'],
          price: 79.99,
          categories: ['Power Tools'],
          brand: 'DeWalt',
        ),
      ];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => AsyncValue.data(mockProducts),
            ),
            cartProvider.overrideWith((ref) => {}),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_mobile_landscape.png'),
      );
    });

    testWidgets('home screen tablet portrait', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

      final mockProducts = [
        Product(
          id: '1',
          name: 'Cordless Drill',
          imageUrl: 'https://picsum.photos/seed/drill/300/300',
          images: ['https://picsum.photos/seed/drill/300/300'],
          price: 79.99,
          categories: ['Power Tools'],
          brand: 'DeWalt',
        ),
        Product(
          id: '2',
          name: 'Claw Hammer',
          imageUrl: 'https://picsum.photos/seed/hammer/300/300',
          images: ['https://picsum.photos/seed/hammer/300/300'],
          price: 14.99,
          categories: ['Hand Tools'],
          brand: 'Stanley',
        ),
        Product(
          id: '3',
          name: 'Paint Roller Kit',
          imageUrl: 'https://picsum.photos/seed/paint/300/300',
          images: ['https://picsum.photos/seed/paint/300/300'],
          price: 19.99,
          categories: ['Painting Tools'],
          brand: 'Purdy',
        ),
      ];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => AsyncValue.data(mockProducts),
            ),
            cartProvider.overrideWith((ref) => {}),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_tablet_portrait.png'),
      );
    });

    testWidgets('home screen tablet landscape', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      final mockProducts = [
        Product(
          id: '1',
          name: 'Cordless Drill',
          imageUrl: 'https://picsum.photos/seed/drill/300/300',
          images: ['https://picsum.photos/seed/drill/300/300'],
          price: 79.99,
          categories: ['Power Tools'],
          brand: 'DeWalt',
        ),
        Product(
          id: '2',
          name: 'Claw Hammer',
          imageUrl: 'https://picsum.photos/seed/hammer/300/300',
          images: ['https://picsum.photos/seed/hammer/300/300'],
          price: 14.99,
          categories: ['Hand Tools'],
          brand: 'Stanley',
        ),
      ];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => AsyncValue.data(mockProducts),
            ),
            cartProvider.overrideWith((ref) => {}),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_tablet_landscape.png'),
      );
    });

    testWidgets('home screen desktop', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      final mockProducts = [
        Product(
          id: '1',
          name: 'Cordless Drill',
          imageUrl: 'https://picsum.photos/seed/drill/300/300',
          images: ['https://picsum.photos/seed/drill/300/300'],
          price: 79.99,
          categories: ['Power Tools'],
          brand: 'DeWalt',
        ),
        Product(
          id: '2',
          name: 'Claw Hammer',
          imageUrl: 'https://picsum.photos/seed/hammer/300/300',
          images: ['https://picsum.photos/seed/hammer/300/300'],
          price: 14.99,
          categories: ['Hand Tools'],
          brand: 'Stanley',
        ),
        Product(
          id: '3',
          name: 'Paint Roller Kit',
          imageUrl: 'https://picsum.photos/seed/paint/300/300',
          images: ['https://picsum.photos/seed/paint/300/300'],
          price: 19.99,
          categories: ['Painting Tools'],
          brand: 'Purdy',
        ),
        Product(
          id: '4',
          name: 'Safety Gloves',
          imageUrl: 'https://picsum.photos/seed/gloves/300/300',
          images: ['https://picsum.photos/seed/gloves/300/300'],
          price: 8.99,
          categories: ['Safety Equipment'],
          brand: '3M',
        ),
      ];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => AsyncValue.data(mockProducts),
            ),
            cartProvider.overrideWith((ref) => {}),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_desktop.png'),
      );
    });

    testWidgets('home screen with cart items', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final mockProducts = [
        Product(
          id: '1',
          name: 'Cordless Drill',
          imageUrl: 'https://picsum.photos/seed/drill/300/300',
          images: ['https://picsum.photos/seed/drill/300/300'],
          price: 79.99,
          categories: ['Power Tools'],
          brand: 'DeWalt',
        ),
      ];

      final cartItems = {
        'item1': CartItem(product: mockProducts[0], quantity: 2),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => AsyncValue.data(mockProducts),
            ),
            cartProvider.overrideWith((ref) => cartItems),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_with_cart.png'),
      );
    });

    testWidgets('home screen loading state', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => const AsyncValue.loading(),
            ),
            cartProvider.overrideWith((ref) => {}),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_loading.png'),
      );
    });

    testWidgets('home screen error state', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            featuredProductsProvider.overrideWith(
              (ref) => const AsyncValue.error('Failed to load products'),
            ),
            cartProvider.overrideWith((ref) => {}),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_error.png'),
      );
    });
  });
}
