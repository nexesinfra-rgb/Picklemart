import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mockito/mockito.dart';
import 'package:picklemart/core/router/app_router.dart';
import 'package:picklemart/features/admin/application/admin_auth_controller.dart';
import 'package:picklemart/features/admin/application/admin_product_controller.dart';
import 'package:picklemart/features/admin/domain/admin_user.dart';
import 'package:picklemart/features/admin/presentation/admin_products_screen.dart';
import 'package:picklemart/features/catalog/data/product.dart';
import 'package:picklemart/features/catalog/data/shared_product_provider.dart';
import 'package:picklemart/media_upload_widget.dart';

// Create a Fake implementation since we can't easily mock StateNotifier with Mockito
class FakeAdminProductController extends StateNotifier<AdminProductState>
    implements AdminProductController {
  FakeAdminProductController(super.state);

  @override
  Future<bool> deleteProduct(String id) async {
    final updatedProducts = state.products.where((p) => p.id != id).toList();
    state = state.copyWith(
      products: updatedProducts,
      filteredProducts: updatedProducts,
    );
    return true;
  }

  @override
  void searchProducts(String query) {}

  @override
  void filterByCategory(String category) {}

  @override
  void filterByOutOfStock(bool filter) {}

  @override
  Future<void> loadProducts() async {}

  @override
  Future<void> loadMoreProducts() async {}

  @override
  Future<bool> addProduct(
    Product product, {
    List<MediaUploadResult>? selectedImages,
  }) async {
    return true;
  }

  @override
  Future<bool> updateProduct(
    Product product, {
    List<MediaUploadResult>? selectedImages,
  }) async {
    return true;
  }

  @override
  Future<void> toggleFeatured(Product product, bool isFeatured) async {}

  @override
  Future<bool> toggleOutOfStock(String productId, bool isOutOfStock) async {
    return true;
  }
}

// Fake SharedProductNotifier
class FakeSharedProductNotifier extends StateNotifier<SharedProductState>
    implements SharedProductNotifier {
  FakeSharedProductNotifier() : super(const SharedProductState());

  @override
  Future<void> loadProducts() async {}

  @override
  void initialize() {}

  @override
  Future<void> addProduct(Product product) async {}

  @override
  Future<void> updateProduct(Product product) async {}

  @override
  Future<void> deleteProduct(String productId) async {}

  @override
  void refresh() {}
}

// Helper to create test app with overrides
Widget createTestAppWithOverrides({
  required Widget child,
  required AdminProductController adminProductController,
}) {
  return ProviderScope(
    overrides: [
      // Mock admin auth
      currentAdminProvider.overrideWith(
        (ref) => const AdminUser(
          id: 'test-admin-id',
          email: 'admin@test.com',
          name: 'Test Admin',
          role: AdminRole.superAdmin,
        ),
      ),
      // Mock admin product controller
      adminProductControllerProvider.overrideWith(
        (ref) => adminProductController,
      ),
      // Mock shared product provider correctly
      sharedProductProvider.overrideWith((ref) => FakeSharedProductNotifier()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  final testProduct = Product(
    id: 'p1',
    name: 'Test Product',
    imageUrl: 'http://test.com/image.jpg',
    images: ['http://test.com/image.jpg'],
    price: 100.0,
    categories: ['Pickles'],
  );

  group('AdminProductsScreen', () {
    testWidgets(
      'should display Edit and Delete buttons and NOT Add to Cart button',
      (WidgetTester tester) async {
        final controller = FakeAdminProductController(
          AdminProductState(
            products: [testProduct],
            filteredProducts: [testProduct],
          ),
        );

        await tester.pumpWidget(
          createTestAppWithOverrides(
            child: const AdminProductsScreen(),
            adminProductController: controller,
          ),
        );

        await tester.pumpAndSettle();

        // Check if product is displayed
        expect(find.text('Test Product'), findsOneWidget);

        // Check for DELETE button (icon)
        expect(find.byIcon(Ionicons.trash_outline), findsOneWidget);

        // Check for EDIT button (icon)
        // Note: The popup menu also has an edit icon, but it's not in the tree until opened.
        // So this should find the visible button we just added.
        expect(find.byIcon(Ionicons.create_outline), findsOneWidget);

        // Verify "Add to Cart" is NOT present
        expect(find.text('Add to Cart'), findsNothing);
        expect(find.byIcon(Ionicons.cart_outline), findsNothing);
      },
    );

    testWidgets('should show delete dialog when DELETE button is clicked', (
      WidgetTester tester,
    ) async {
      final controller = FakeAdminProductController(
        AdminProductState(
          products: [testProduct],
          filteredProducts: [testProduct],
        ),
      );

      await tester.pumpWidget(
        createTestAppWithOverrides(
          child: const AdminProductsScreen(),
          adminProductController: controller,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the delete button
      final deleteButton = find.byIcon(Ionicons.trash_outline);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Check if dialog appears
      expect(find.text('Delete Product'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete "Test Product"?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('should delete product when confirmed in dialog', (
      WidgetTester tester,
    ) async {
      final controller = FakeAdminProductController(
        AdminProductState(
          products: [testProduct],
          filteredProducts: [testProduct],
        ),
      );

      await tester.pumpWidget(
        createTestAppWithOverrides(
          child: const AdminProductsScreen(),
          adminProductController: controller,
        ),
      );

      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Ionicons.trash_outline));
      await tester.pumpAndSettle();

      // Tap confirm Delete in dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify product is removed from screen
      expect(find.text('Test Product'), findsNothing);
    });
  });
}
