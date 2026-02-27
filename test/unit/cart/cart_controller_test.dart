import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/cart/application/cart_controller.dart';
import 'package:picklemart/features/catalog/data/product.dart';
import 'package:picklemart/features/catalog/data/measurement.dart';

void main() {
  group('CartController Unit Tests', () {
    late ProviderContainer container;
    late CartController cartController;

    setUp(() {
      container = ProviderContainer();
      cartController = container.read(cartProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('addItem()', () {
      test('should add new item to cart', () {
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
        cartController.add(product);

        // Assert
        final state = container.read(cartProvider);
        expect(state.length, equals(1));
        expect(state.values.first.product, equals(product));
        expect(state.values.first.quantity, equals(1));
      });

      test('should increment quantity for existing item', () {
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
        cartController.add(product);
        cartController.add(product);

        // Assert
        final state = container.read(cartProvider);
        expect(state.length, equals(1));
        expect(state.values.first.quantity, equals(2));
      });

      test('should handle measurement units correctly', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
          measurement: ProductMeasurement(
            productId: 'p1',
            defaultUnit: MeasurementUnit.kg,
            pricingOptions: [
              MeasurementPricing(
                unit: MeasurementUnit.kg,
                price: 100.0,
                stock: 10,
              ),
            ],
          ),
        );

        // Act
        cartController.add(product, measurementUnit: MeasurementUnit.kg);

        // Assert
        final state = container.read(cartProvider);
        expect(state.length, equals(1));
        expect(state.values.first.measurementUnit, equals(MeasurementUnit.kg));
      });

      test('should handle variants correctly', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
          variants: [
            Variant(
              sku: 'VARIANT-1',
              attributes: {'Size': 'M', 'Color': 'Blue'},
              price: 120.0,
              stock: 10,
            ),
          ],
        );
        final variant = product.variants.first;

        // Act
        cartController.add(product, variant: variant);

        // Assert
        final state = container.read(cartProvider);
        expect(state.length, equals(1));
        expect(state.values.first.variant, equals(variant));
      });
    });

    group('removeItem()', () {
      test('should remove item completely when quantity is 1', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        cartController.add(product);

        // Act
        cartController.remove(product);

        // Assert
        final state = container.read(cartProvider);
        expect(state.length, equals(0));
      });

      test('should decrement quantity when quantity > 1', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        cartController.add(product);
        cartController.add(product);

        // Act
        cartController.remove(product);

        // Assert
        final state = container.read(cartProvider);
        expect(state.length, equals(1));
        expect(state.values.first.quantity, equals(1));
      });

      test('should handle measurement units in removal', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
          measurement: ProductMeasurement(
            productId: 'p1',
            defaultUnit: MeasurementUnit.kg,
            pricingOptions: [
              MeasurementPricing(
                unit: MeasurementUnit.kg,
                price: 100.0,
                stock: 10,
              ),
            ],
          ),
        );
        cartController.add(product, measurementUnit: MeasurementUnit.kg);

        // Act
        cartController.remove(product, measurementUnit: MeasurementUnit.kg);

        // Assert
        final state = container.read(cartProvider);
        expect(state.length, equals(0));
      });
    });

    group('deleteItem()', () {
      test('should remove item completely regardless of quantity', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        cartController.add(product);
        cartController.add(product);

        // Act
        cartController.delete(product);

        // Assert
        final state = container.read(cartProvider);
        expect(state.length, equals(0));
      });
    });

    group('clearCart()', () {
      test('should remove all items from cart', () {
        // Arrange
        final product1 = Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://example.com/image1.jpg',
          images: ['https://example.com/image1.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        final product2 = Product(
          id: '2',
          name: 'Test Product 2',
          imageUrl: 'https://example.com/image2.jpg',
          images: ['https://example.com/image2.jpg'],
          price: 200.0,
          categories: ['Test'],
        );
        cartController.add(product1);
        cartController.add(product2);

        // Act
        cartController.clear();

        // Assert
        final state = container.read(cartProvider);
        expect(state.length, equals(0));
      });
    });

    group('getTotal()', () {
      test('should calculate total correctly for single item', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        cartController.add(product);

        // Act
        final total = cartController.total;

        // Assert
        expect(total, equals(100.0));
      });

      test('should calculate total correctly for multiple items', () {
        // Arrange
        final product1 = Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://example.com/image1.jpg',
          images: ['https://example.com/image1.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        final product2 = Product(
          id: '2',
          name: 'Test Product 2',
          imageUrl: 'https://example.com/image2.jpg',
          images: ['https://example.com/image2.jpg'],
          price: 200.0,
          categories: ['Test'],
        );
        cartController.add(product1);
        cartController.add(product2);

        // Act
        final total = cartController.total;

        // Assert
        expect(total, equals(300.0));
      });

      test('should calculate total correctly with quantities', () {
        // Arrange
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

        // Act
        final total = cartController.total;

        // Assert
        expect(total, equals(200.0));
      });

      test('should calculate total correctly with variants', () {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          imageUrl: 'https://example.com/image.jpg',
          images: ['https://example.com/image.jpg'],
          price: 100.0,
          categories: ['Test'],
          variants: [
            Variant(
              sku: 'VARIANT-1',
              attributes: {'Size': 'M', 'Color': 'Blue'},
              price: 120.0,
              stock: 10,
            ),
          ],
        );
        final variant = product.variants.first;
        cartController.add(product, variant: variant);

        // Act
        final total = cartController.total;

        // Assert
        expect(total, equals(120.0));
      });
    });

    group('getItemCount()', () {
      test('should return correct item count', () {
        // Arrange
        final product1 = Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://example.com/image1.jpg',
          images: ['https://example.com/image1.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        final product2 = Product(
          id: '2',
          name: 'Test Product 2',
          imageUrl: 'https://example.com/image2.jpg',
          images: ['https://example.com/image2.jpg'],
          price: 200.0,
          categories: ['Test'],
        );
        cartController.add(product1);
        cartController.add(product1); // Quantity = 2
        cartController.add(product2);

        // Act
        final itemCount = container.read(cartProvider).length;

        // Assert
        expect(
          itemCount,
          equals(2),
        ); // Two unique items (product1 and product2)
      });
    });

    group('CartItem key generation', () {
      test('should generate unique keys for different products', () {
        // Arrange
        final product1 = Product(
          id: '1',
          name: 'Test Product 1',
          imageUrl: 'https://example.com/image1.jpg',
          images: ['https://example.com/image1.jpg'],
          price: 100.0,
          categories: ['Test'],
        );
        final product2 = Product(
          id: '2',
          name: 'Test Product 2',
          imageUrl: 'https://example.com/image2.jpg',
          images: ['https://example.com/image2.jpg'],
          price: 200.0,
          categories: ['Test'],
        );

        // Act
        cartController.add(product1);
        cartController.add(product2);

        // Assert
        final state = container.read(cartProvider);
        final keys = state.keys.toList();
        expect(keys.length, equals(2));
        expect(keys[0], isNot(equals(keys[1])));
      });

      test(
        'should generate unique keys for same product with different variants',
        () {
          // Arrange
          final product = Product(
            id: '1',
            name: 'Test Product',
            imageUrl: 'https://example.com/image.jpg',
            images: ['https://example.com/image.jpg'],
            price: 100.0,
            categories: ['Test'],
            variants: [
              Variant(
                sku: 'VARIANT-1',
                attributes: {'Size': 'M', 'Color': 'Blue'},
                price: 120.0,
                stock: 10,
              ),
              Variant(
                sku: 'VARIANT-2',
                attributes: {'Size': 'L', 'Color': 'Red'},
                price: 130.0,
                stock: 10,
              ),
            ],
          );

          // Act
          cartController.add(product, variant: product.variants[0]);
          cartController.add(product, variant: product.variants[1]);

          // Assert
          final state = container.read(cartProvider);
          expect(state.length, equals(2));
        },
      );
    });
  });
}
