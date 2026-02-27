import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/cart/presentation/cart_screen.dart';
import 'package:picklemart/features/cart/application/cart_controller.dart';
import 'package:picklemart/features/catalog/data/product.dart';

void main() {
  group('CartScreen Golden Tests', () {
    testWidgets('cart screen empty state', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => {})],
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_empty.png'),
      );
    });

    testWidgets('cart screen with single item', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final product = Product(
        id: '1',
        name: 'Cordless Drill',
        imageUrl: 'https://picsum.photos/seed/drill/300/300',
        images: ['https://picsum.photos/seed/drill/300/300'],
        price: 79.99,
        categories: ['Power Tools'],
        brand: 'DeWalt',
      );

      final cartItems = {'item1': CartItem(product: product, quantity: 1)};

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => cartItems)],
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_single_item.png'),
      );
    });

    testWidgets('cart screen with multiple items', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final products = [
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

      final cartItems = {
        'item1': CartItem(product: products[0], quantity: 2),
        'item2': CartItem(product: products[1], quantity: 1),
        'item3': CartItem(product: products[2], quantity: 3),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => cartItems)],
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_multiple_items.png'),
      );
    });

    testWidgets('cart screen mobile landscape', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(667, 375);
      tester.view.devicePixelRatio = 1.0;

      final product = Product(
        id: '1',
        name: 'Cordless Drill',
        imageUrl: 'https://picsum.photos/seed/drill/300/300',
        images: ['https://picsum.photos/seed/drill/300/300'],
        price: 79.99,
        categories: ['Power Tools'],
        brand: 'DeWalt',
      );

      final cartItems = {'item1': CartItem(product: product, quantity: 1)};

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => cartItems)],
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_mobile_landscape.png'),
      );
    });

    testWidgets('cart screen tablet portrait', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

      final products = [
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

      final cartItems = {
        'item1': CartItem(product: products[0], quantity: 2),
        'item2': CartItem(product: products[1], quantity: 1),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => cartItems)],
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_tablet_portrait.png'),
      );
    });

    testWidgets('cart screen tablet landscape', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      final products = [
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

      final cartItems = {
        'item1': CartItem(product: products[0], quantity: 2),
        'item2': CartItem(product: products[1], quantity: 1),
        'item3': CartItem(product: products[2], quantity: 3),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => cartItems)],
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_tablet_landscape.png'),
      );
    });

    testWidgets('cart screen desktop', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      final products = [
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

      final cartItems = {
        'item1': CartItem(product: products[0], quantity: 2),
        'item2': CartItem(product: products[1], quantity: 1),
        'item3': CartItem(product: products[2], quantity: 3),
        'item4': CartItem(product: products[3], quantity: 1),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => cartItems)],
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_desktop.png'),
      );
    });

    testWidgets('cart screen with variants', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final product = Product(
        id: '1',
        name: 'Cordless Drill',
        imageUrl: 'https://picsum.photos/seed/drill/300/300',
        images: ['https://picsum.photos/seed/drill/300/300'],
        price: 79.99,
        categories: ['Power Tools'],
        brand: 'DeWalt',
        variants: [
          Variant(
            sku: 'DRILL-001',
            attributes: {'Size': 'Medium', 'Color': 'Black'},
            price: 79.99,
            stock: 10,
          ),
        ],
      );

      final cartItems = {
        'item1': CartItem(
          product: product,
          variant: product.variants[0],
          quantity: 1,
        ),
      };

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartProvider.overrideWith((ref) => cartItems)],
          child: const MaterialApp(home: CartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(CartScreen),
        matchesGoldenFile('cart_screen_with_variants.png'),
      );
    });
  });
}
