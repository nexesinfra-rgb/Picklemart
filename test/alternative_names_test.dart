import 'package:flutter_test/flutter_test.dart';
import 'package:picklemart/features/catalog/data/product.dart';

void main() {
  group('Product Alternative Names Tests', () {
    test('Product should include alternative names in search', () {
      final product = Product(
        id: 'test_1',
        name: 'Work Gloves',
        imageUrl: 'test_image.jpg',
        images: ['test_image.jpg'],
        price: 15.99,
        alternativeNames: [
          'Safety Gloves',
          'Hand Protection',
          'Work Hand Gear',
        ],
        categories: ['Safety Equipment'],
      );

      // Test search functionality
      final searchQuery = 'safety';
      final matches = product.alternativeNames.any(
        (name) => name.toLowerCase().contains(searchQuery.toLowerCase()),
      );

      expect(matches, isTrue);
    });

    test('Product should match multiple alternative names', () {
      final product = Product(
        id: 'test_2',
        name: 'Power Drill',
        imageUrl: 'test_image.jpg',
        images: ['test_image.jpg'],
        price: 99.99,
        alternativeNames: ['Electric Drill', 'Cordless Drill', 'Drill Machine'],
        categories: ['Tools'],
      );

      // Test different search terms
      final searchTerms = ['electric', 'cordless', 'machine'];

      for (final term in searchTerms) {
        final matches = product.alternativeNames.any(
          (name) => name.toLowerCase().contains(term.toLowerCase()),
        );
        expect(matches, isTrue, reason: 'Should match search term: $term');
      }
    });

    test('Product should handle empty alternative names', () {
      final product = Product(
        id: 'test_3',
        name: 'Basic Tool',
        imageUrl: 'test_image.jpg',
        images: ['test_image.jpg'],
        price: 25.99,
        alternativeNames: [], // Empty alternative names
        categories: ['Tools'],
      );

      // Should not match any alternative names
      final matches = product.alternativeNames.any(
        (name) => name.toLowerCase().contains('anything'),
      );

      expect(matches, isFalse);
    });
  });
}

