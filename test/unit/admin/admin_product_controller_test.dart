import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:picklemart/features/admin/application/admin_product_controller.dart';
import 'package:picklemart/features/catalog/data/product.dart';
import 'package:picklemart/features/catalog/data/shared_product_provider.dart';

import 'admin_product_controller_test.mocks.dart';

@GenerateMocks([SharedProductNotifier])
void main() {
  group('AdminProductController Unit Tests', () {
    late MockSharedProductNotifier mockSharedProductNotifier;
    late ProviderContainer container;
    late AdminProductController adminProductController;

    setUp(() {
      mockSharedProductNotifier = MockSharedProductNotifier();
      // Stub the state getter
      when(mockSharedProductNotifier.state).thenReturn(
        const SharedProductState(products: [], isLoading: false, error: null),
      );
      // Stub the stream getter for listeners
      when(
        mockSharedProductNotifier.stream,
      ).thenAnswer((_) => Stream.value(const SharedProductState()));

      container = ProviderContainer(
        overrides: [
          sharedProductProvider.overrideWith(
            (ref) => mockSharedProductNotifier,
          ),
        ],
      );
      adminProductController = container.read(
        adminProductControllerProvider.notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        final state = container.read(adminProductControllerProvider);

        expect(state.products, isEmpty);
        expect(state.filteredProducts, isEmpty);
        expect(state.searchQuery, equals(''));
        expect(state.selectedCategory, equals('All'));
        expect(state.loading, isFalse);
        expect(state.error, isNull);
        expect(state.selectedProduct, isNull);
      });
    });

    group('loadProducts()', () {
      test('should load products successfully', () async {
        // Arrange
        final products = [
          Product(
            id: '1',
            name: 'Test Product 1',
            imageUrl: 'https://example.com/image1.jpg',
            images: ['https://example.com/image1.jpg'],
            price: 100.0,
            categories: ['Category1'],
          ),
          Product(
            id: '2',
            name: 'Test Product 2',
            imageUrl: 'https://example.com/image2.jpg',
            images: ['https://example.com/image2.jpg'],
            price: 200.0,
            categories: ['Category2'],
          ),
        ];

        when(mockSharedProductNotifier.state).thenReturn(
          SharedProductState(products: products, isLoading: false, error: null),
        );
        when(mockSharedProductNotifier.stream).thenAnswer(
          (_) => Stream.value(
            SharedProductState(
              products: products,
              isLoading: false,
              error: null,
            ),
          ),
        );

        container = ProviderContainer(
          overrides: [
            sharedProductProvider.overrideWith(
              (ref) => mockSharedProductNotifier,
            ),
            allProductsProvider.overrideWith((ref) => products),
          ],
        );
        adminProductController = container.read(
          adminProductControllerProvider.notifier,
        );

        // Act
        await adminProductController.loadProducts();

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.products, equals(products));
        expect(state.filteredProducts, equals(products));
        expect(state.loading, isFalse);
        expect(state.error, isNull);
      });

      test('should handle error when loading products fails', () async {
        // Arrange
        when(mockSharedProductNotifier.state).thenReturn(
          const SharedProductState(
            products: [],
            isLoading: false,
            error: 'Loading failed',
          ),
        );
        when(mockSharedProductNotifier.stream).thenAnswer(
          (_) => Stream.value(
            const SharedProductState(
              products: [],
              isLoading: false,
              error: 'Loading failed',
            ),
          ),
        );

        container = ProviderContainer(
          overrides: [
            sharedProductProvider.overrideWith(
              (ref) => mockSharedProductNotifier,
            ),
            allProductsProvider.overrideWith(
              (ref) => throw Exception('Provider error'),
            ),
          ],
        );
        adminProductController = container.read(
          adminProductControllerProvider.notifier,
        );

        // Act
        await adminProductController.loadProducts();

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, contains('Provider error'));
      });

      test('should set loading state during load', () async {
        // Arrange
        final products = [
          Product(
            id: '1',
            name: 'Test Product',
            imageUrl: 'https://example.com/image.jpg',
            images: ['https://example.com/image.jpg'],
            price: 100.0,
            categories: ['Test'],
          ),
        ];

        when(mockSharedProductNotifier.state).thenReturn(
          SharedProductState(products: products, isLoading: false, error: null),
        );
        when(mockSharedProductNotifier.stream).thenAnswer(
          (_) => Stream.value(
            SharedProductState(
              products: products,
              isLoading: false,
              error: null,
            ),
          ),
        );

        container = ProviderContainer(
          overrides: [
            sharedProductProvider.overrideWith(
              (ref) => mockSharedProductNotifier,
            ),
            allProductsProvider.overrideWith((ref) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return products;
            }),
          ],
        );
        adminProductController = container.read(
          adminProductControllerProvider.notifier,
        );

        // Act
        final future = adminProductController.loadProducts();

        // Assert - Check loading state
        final loadingState = container.read(adminProductControllerProvider);
        expect(loadingState.loading, isTrue);

        // Wait for completion
        await future;

        // Check final state
        final finalState = container.read(adminProductControllerProvider);
        expect(finalState.loading, isFalse);
      });
    });

    group('searchProducts()', () {
      setUp(() {
        final products = [
          Product(
            id: '1',
            name: 'Blue Hammer',
            imageUrl: 'https://example.com/image1.jpg',
            images: ['https://example.com/image1.jpg'],
            price: 100.0,
            categories: ['Tools'],
            brand: 'BrandA',
            sku: 'HAMMER-001',
            alternativeNames: ['Hammer Tool', 'Blue Tool'],
          ),
          Product(
            id: '2',
            name: 'Red Screwdriver',
            imageUrl: 'https://example.com/image2.jpg',
            images: ['https://example.com/image2.jpg'],
            price: 50.0,
            categories: ['Tools'],
            brand: 'BrandB',
            sku: 'SCREW-001',
            alternativeNames: ['Screw Tool', 'Red Tool'],
          ),
          Product(
            id: '3',
            name: 'Green Wrench',
            imageUrl: 'https://example.com/image3.jpg',
            images: ['https://example.com/image3.jpg'],
            price: 75.0,
            categories: ['Tools'],
            brand: 'BrandC',
            sku: 'WRENCH-001',
            alternativeNames: ['Wrench Tool', 'Green Tool'],
          ),
        ];

        when(mockSharedProductNotifier.state).thenReturn(
          SharedProductState(products: products, isLoading: false, error: null),
        );
        when(mockSharedProductNotifier.stream).thenAnswer(
          (_) => Stream.value(
            SharedProductState(
              products: products,
              isLoading: false,
              error: null,
            ),
          ),
        );

        container = ProviderContainer(
          overrides: [
            sharedProductProvider.overrideWith(
              (ref) => mockSharedProductNotifier,
            ),
            allProductsProvider.overrideWith((ref) => products),
          ],
        );
        adminProductController = container.read(
          adminProductControllerProvider.notifier,
        );
        adminProductController.loadProducts();
      });

      test('should filter products by name', () {
        // Act
        adminProductController.searchProducts('Hammer');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.searchQuery, equals('Hammer'));
        expect(state.filteredProducts.length, equals(1));
        expect(state.filteredProducts.first.name, equals('Blue Hammer'));
      });

      test('should filter products by brand', () {
        // Act
        adminProductController.searchProducts('BrandA');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.filteredProducts.length, equals(1));
        expect(state.filteredProducts.first.brand, equals('BrandA'));
      });

      test('should filter products by SKU', () {
        // Act
        adminProductController.searchProducts('SCREW-001');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.filteredProducts.length, equals(1));
        expect(state.filteredProducts.first.sku, equals('SCREW-001'));
      });

      test('should filter products by alternative names', () {
        // Act
        adminProductController.searchProducts('Green Tool');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.filteredProducts.length, equals(1));
        expect(state.filteredProducts.first.name, equals('Green Wrench'));
      });

      test('should return all products for empty search', () {
        // Act
        adminProductController.searchProducts('');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.filteredProducts.length, equals(3));
      });

      test('should be case insensitive', () {
        // Act
        adminProductController.searchProducts('hammer');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.filteredProducts.length, equals(1));
        expect(state.filteredProducts.first.name, equals('Blue Hammer'));
      });
    });

    group('filterByCategory()', () {
      setUp(() {
        final products = [
          Product(
            id: '1',
            name: 'Hammer',
            imageUrl: 'https://example.com/image1.jpg',
            images: ['https://example.com/image1.jpg'],
            price: 100.0,
            categories: ['Tools'],
          ),
          Product(
            id: '2',
            name: 'Screwdriver',
            imageUrl: 'https://example.com/image2.jpg',
            images: ['https://example.com/image2.jpg'],
            price: 50.0,
            categories: ['Tools'],
          ),
          Product(
            id: '3',
            name: 'Safety Gloves',
            imageUrl: 'https://example.com/image3.jpg',
            images: ['https://example.com/image3.jpg'],
            price: 25.0,
            categories: ['Safety'],
          ),
        ];

        when(mockSharedProductNotifier.state).thenReturn(
          SharedProductState(products: products, isLoading: false, error: null),
        );
        when(mockSharedProductNotifier.stream).thenAnswer(
          (_) => Stream.value(
            SharedProductState(
              products: products,
              isLoading: false,
              error: null,
            ),
          ),
        );

        container = ProviderContainer(
          overrides: [
            sharedProductProvider.overrideWith(
              (ref) => mockSharedProductNotifier,
            ),
            allProductsProvider.overrideWith((ref) => products),
          ],
        );
        adminProductController = container.read(
          adminProductControllerProvider.notifier,
        );
        adminProductController.loadProducts();
      });

      test('should filter products by category', () {
        // Act
        adminProductController.filterByCategory('Tools');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.selectedCategory, equals('Tools'));
        expect(state.filteredProducts.length, equals(2));
        expect(
          state.filteredProducts.every((p) => p.categories.contains('Tools')),
          isTrue,
        );
      });

      test('should show all products for All category', () {
        // Act
        adminProductController.filterByCategory('All');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.selectedCategory, equals('All'));
        expect(state.filteredProducts.length, equals(3));
      });

      test('should return empty list for non-existent category', () {
        // Act
        adminProductController.filterByCategory('NonExistent');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.filteredProducts, isEmpty);
      });
    });

    group('Combined Search and Category Filter', () {
      setUp(() {
        final products = [
          Product(
            id: '1',
            name: 'Blue Hammer',
            imageUrl: 'https://example.com/image1.jpg',
            images: ['https://example.com/image1.jpg'],
            price: 100.0,
            categories: ['Tools'],
            brand: 'BrandA',
          ),
          Product(
            id: '2',
            name: 'Red Hammer',
            imageUrl: 'https://example.com/image2.jpg',
            images: ['https://example.com/image2.jpg'],
            price: 120.0,
            categories: ['Tools'],
            brand: 'BrandB',
          ),
          Product(
            id: '3',
            name: 'Blue Safety Gloves',
            imageUrl: 'https://example.com/image3.jpg',
            images: ['https://example.com/image3.jpg'],
            price: 25.0,
            categories: ['Safety'],
            brand: 'BrandA',
          ),
        ];

        when(mockSharedProductNotifier.state).thenReturn(
          SharedProductState(products: products, isLoading: false, error: null),
        );
        when(mockSharedProductNotifier.stream).thenAnswer(
          (_) => Stream.value(
            SharedProductState(
              products: products,
              isLoading: false,
              error: null,
            ),
          ),
        );

        container = ProviderContainer(
          overrides: [
            sharedProductProvider.overrideWith(
              (ref) => mockSharedProductNotifier,
            ),
            allProductsProvider.overrideWith((ref) => products),
          ],
        );
        adminProductController = container.read(
          adminProductControllerProvider.notifier,
        );
        adminProductController.loadProducts();
      });

      test('should apply both search and category filters', () {
        // Act
        adminProductController.searchProducts('Blue');
        adminProductController.filterByCategory('Tools');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.filteredProducts.length, equals(1));
        expect(state.filteredProducts.first.name, equals('Blue Hammer'));
      });

      test('should return empty when no products match both filters', () {
        // Act
        adminProductController.searchProducts('Red');
        adminProductController.filterByCategory('Safety');

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.filteredProducts, isEmpty);
      });
    });

    group('selectProduct()', () {
      test('should select a product', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );

        // Act
        adminProductController.selectProduct(product);

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.selectedProduct, equals(product));
      });
    });

    group('clearSelection()', () {
      test('should clear selected product', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        adminProductController.selectProduct(product);

        // Act
        adminProductController.clearSelection();

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.selectedProduct, isNull);
      });
    });

    group('addProduct()', () {
      test('should add product successfully', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'New Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );

        when(
          mockSharedProductNotifier.addProduct(product),
        ).thenAnswer((_) async => true);

        // Act
        final result = await adminProductController.addProduct(product);

        // Assert
        expect(result, isTrue);
        verify(mockSharedProductNotifier.addProduct(product)).called(1);
      });

      test('should handle error when adding product fails', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'New Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );

        when(
          mockSharedProductNotifier.addProduct(product),
        ).thenThrow(Exception('Add failed'));

        // Act
        final result = await adminProductController.addProduct(product);

        // Assert
        expect(result, isFalse);
        final state = container.read(adminProductControllerProvider);
        expect(state.error, contains('Add failed'));
      });
    });

    group('updateProduct()', () {
      test('should update product successfully', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Updated Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 150.0,
          categories: ['Test'],
        );

        when(
          mockSharedProductNotifier.updateProduct(product),
        ).thenAnswer((_) async => true);

        // Act
        final result = await adminProductController.updateProduct(product);

        // Assert
        expect(result, isTrue);
        verify(mockSharedProductNotifier.updateProduct(product)).called(1);
      });

      test('should handle error when updating product fails', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Updated Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 150.0,
          categories: ['Test'],
        );

        when(
          mockSharedProductNotifier.updateProduct(product),
        ).thenThrow(Exception('Update failed'));

        // Act
        final result = await adminProductController.updateProduct(product);

        // Assert
        expect(result, isFalse);
        final state = container.read(adminProductControllerProvider);
        expect(state.error, contains('Update failed'));
      });
    });

    group('deleteProduct()', () {
      test('should delete product successfully', () async {
        // Arrange
        const productId = '1';

        when(
          mockSharedProductNotifier.deleteProduct(productId),
        ).thenAnswer((_) async => true);

        // Act
        final result = await adminProductController.deleteProduct(productId);

        // Assert
        expect(result, isTrue);
        verify(mockSharedProductNotifier.deleteProduct(productId)).called(1);
      });

      test('should handle error when deleting product fails', () async {
        // Arrange
        const productId = '1';

        when(
          mockSharedProductNotifier.deleteProduct(productId),
        ).thenThrow(Exception('Delete failed'));

        // Act
        final result = await adminProductController.deleteProduct(productId);

        // Assert
        expect(result, isFalse);
        final state = container.read(adminProductControllerProvider);
        expect(state.error, contains('Delete failed'));
      });
    });

    group('clearError()', () {
      test('should clear error state', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );

        when(
          mockSharedProductNotifier.addProduct(product),
        ).thenThrow(Exception('Test error'));

        await adminProductController.addProduct(product);

        // Verify error is set
        expect(container.read(adminProductControllerProvider).error, isNotNull);

        // Act
        adminProductController.clearError();

        // Assert
        final state = container.read(adminProductControllerProvider);
        expect(state.error, isNull);
      });
    });

    group('categories getter', () {
      test('should return all unique categories', () {
        // Arrange
        final products = [
          Product(
            id: '1',
            name: 'Product 1',
            imageUrl: 'https://example.com/image1.jpg',
            images: ['https://example.com/image1.jpg'],
            price: 100.0,
            categories: ['Tools', 'Hardware'],
          ),
          Product(
            id: '2',
            name: 'Product 2',
            imageUrl: 'https://example.com/image2.jpg',
            images: ['https://example.com/image2.jpg'],
            price: 200.0,
            categories: ['Tools', 'Safety'],
          ),
          Product(
            id: '3',
            name: 'Product 3',
            imageUrl: 'https://example.com/image3.jpg',
            images: ['https://example.com/image3.jpg'],
            price: 300.0,
            categories: ['Hardware'],
          ),
        ];

        when(mockSharedProductNotifier.state).thenReturn(
          SharedProductState(products: products, isLoading: false, error: null),
        );
        when(mockSharedProductNotifier.stream).thenAnswer(
          (_) => Stream.value(
            SharedProductState(
              products: products,
              isLoading: false,
              error: null,
            ),
          ),
        );

        container = ProviderContainer(
          overrides: [
            sharedProductProvider.overrideWith(
              (ref) => mockSharedProductNotifier,
            ),
            allProductsProvider.overrideWith((ref) => products),
          ],
        );
        adminProductController = container.read(
          adminProductControllerProvider.notifier,
        );
        adminProductController.loadProducts();

        // Act
        final categories = adminProductController.categories;

        // Assert
        expect(categories, contains('All'));
        expect(categories, contains('Hardware'));
        expect(categories, contains('Safety'));
        expect(categories, contains('Tools'));
        expect(categories.length, equals(4)); // All + 3 unique categories
        expect(categories, isA<List<String>>());
      });
    });
  });
}
