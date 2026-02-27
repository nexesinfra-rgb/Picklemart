import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/admin/presentation/admin_products_screen.dart';
import 'package:picklemart/features/admin/application/admin_product_controller.dart';
import 'package:picklemart/features/catalog/data/product.dart';

void main() {
  group('AdminProductsScreen Golden Tests', () {
    testWidgets('mobile layout with products', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      // Set up mock products
      final container = ProviderContainer();
      final mockProducts = [
        Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'test1.jpg',
          price: 100.0,
          stock: 10,
          tags: ['tag1', 'tag2'],
          categories: ['Electronics'],
          variants: [],
          images: [],
        ),
        Product(
          id: '2',
          name: 'Another Product',
          imageUrl: 'test2.jpg',
          price: 200.0,
          stock: 5,
          tags: ['tag3'],
          categories: ['Clothing'],
          variants: [],
          images: [],
        ),
      ];

      container.read(adminProductControllerProvider.notifier).state = container
          .read(adminProductControllerProvider)
          .copyWith(
            products: mockProducts,
            filteredProducts: mockProducts,
            loading: false,
          );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: const AdminProductsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdminProductsScreen),
        matchesGoldenFile('admin_products_mobile.png'),
      );
    });

    testWidgets('tablet layout with products', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      // Set up mock products
      final container = ProviderContainer();
      final mockProducts = [
        Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'test1.jpg',
          price: 100.0,
          stock: 10,
          tags: ['tag1', 'tag2'],
          categories: ['Electronics'],
          variants: [],
          images: [],
        ),
        Product(
          id: '2',
          name: 'Another Product',
          imageUrl: 'test2.jpg',
          price: 200.0,
          stock: 5,
          tags: ['tag3'],
          categories: ['Clothing'],
          variants: [],
          images: [],
        ),
      ];

      container.read(adminProductControllerProvider.notifier).state = container
          .read(adminProductControllerProvider)
          .copyWith(
            products: mockProducts,
            filteredProducts: mockProducts,
            loading: false,
          );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: const AdminProductsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdminProductsScreen),
        matchesGoldenFile('admin_products_tablet.png'),
      );
    });

    testWidgets('desktop layout with products', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      // Set up mock products
      final container = ProviderContainer();
      final mockProducts = [
        Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'test1.jpg',
          price: 100.0,
          stock: 10,
          tags: ['tag1', 'tag2'],
          categories: ['Electronics'],
          variants: [],
          images: [],
        ),
        Product(
          id: '2',
          name: 'Another Product',
          imageUrl: 'test2.jpg',
          price: 200.0,
          stock: 5,
          tags: ['tag3'],
          categories: ['Clothing'],
          variants: [],
          images: [],
        ),
      ];

      container.read(adminProductControllerProvider.notifier).state = container
          .read(adminProductControllerProvider)
          .copyWith(
            products: mockProducts,
            filteredProducts: mockProducts,
            loading: false,
          );

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: const AdminProductsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdminProductsScreen),
        matchesGoldenFile('admin_products_desktop.png'),
      );
    });

    testWidgets('empty state', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminProductsScreen())),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdminProductsScreen),
        matchesGoldenFile('admin_products_empty.png'),
      );
    });

    testWidgets('loading state', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminProductsScreen())),
      );

      // Should show loading state initially
      await expectLater(
        find.byType(AdminProductsScreen),
        matchesGoldenFile('admin_products_loading.png'),
      );
    });

    testWidgets('error state', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      // Set up error state
      final container = ProviderContainer();
      container.read(adminProductControllerProvider.notifier).state = container
          .read(adminProductControllerProvider)
          .copyWith(error: 'Failed to load products', loading: false);

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(home: const AdminProductsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdminProductsScreen),
        matchesGoldenFile('admin_products_error.png'),
      );
    });
  });
}
