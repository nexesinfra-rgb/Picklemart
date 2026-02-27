import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/admin/application/admin_dashboard_controller.dart';
import 'package:picklemart/features/orders/data/shared_orders_provider.dart';
import 'package:picklemart/features/catalog/data/shared_product_provider.dart';
import 'package:picklemart/features/catalog/data/product.dart';
import 'package:picklemart/features/orders/data/order_model.dart';
import 'package:picklemart/features/admin/data/shared_customers_provider.dart';
import 'package:picklemart/features/admin/data/shared_manufacturers_provider.dart';
import 'package:picklemart/features/admin/domain/customer.dart';
import 'package:picklemart/features/admin/domain/manufacturer.dart';
import 'package:picklemart/features/admin/application/admin_customer_controller.dart';

// Mocks
class MockAdminCustomerController extends StateNotifier<AdminCustomerState>
    implements AdminCustomerController {
  MockAdminCustomerController() : super(const AdminCustomerState());

  @override
  Future<void> refresh() async {}
}

class MockSharedProductNotifier extends StateNotifier<SharedProductState>
    implements SharedProductNotifier {
  MockSharedProductNotifier() : super(const SharedProductState());

  @override
  Future<void> loadProducts() async {}

  @override
  Future<void> addProduct(Product product) async {}

  @override
  Future<void> updateProduct(Product product) async {}

  @override
  Future<void> deleteProduct(String productId) async {}

  @override
  void refresh() {}

  void setState(SharedProductState newState) {
    state = newState;
  }
}

void main() {
  group('AdminDashboardController Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          sharedOrdersProvider.overrideWith((ref) => Stream.value([])),
          sharedProductProvider.overrideWith(
            (ref) => MockSharedProductNotifier(),
          ),
          sharedCustomersProvider.overrideWith((ref) => Stream.value([])),
          sharedManufacturersProvider.overrideWith((ref) => Stream.value([])),
          adminCustomerControllerProvider.overrideWith(
            (ref) => MockAdminCustomerController(),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state should be correct', () {
      final state = container.read(adminDashboardControllerProvider);
      expect(state.totalOrders, 0);
      expect(state.totalRevenue, 0.0);
      expect(state.totalProducts, 0);
      expect(state.totalCustomers, 0);
      expect(state.pendingOrders, 0);
      expect(state.lowStockProducts, 0);
      expect(state.loading, false);
      expect(state.error, isNull);
    });

    test('Should update metrics when orders stream emits', () async {
      final order = Order(
        id: '1',
        orderTag: 'TAG-1',
        orderNumber: 'ORD-1',
        orderDate: DateTime.now(),
        status: OrderStatus.confirmed,
        items: [],
        deliveryAddress: const OrderAddress(
          name: 'Test',
          phone: '123',
          address: 'Addr',
          city: 'City',
          state: 'State',
          pincode: '123456',
        ),
        subtotal: 100,
        shipping: 10,
        tax: 5,
        total: 115,
        userId: 'user1',
      );

      container = ProviderContainer(
        overrides: [
          sharedOrdersProvider.overrideWith((ref) => Stream.value([order])),
          sharedProductProvider.overrideWith(
            (ref) => MockSharedProductNotifier(),
          ),
          sharedCustomersProvider.overrideWith((ref) => Stream.value([])),
          sharedManufacturersProvider.overrideWith((ref) => Stream.value([])),
          adminCustomerControllerProvider.overrideWith(
            (ref) => MockAdminCustomerController(),
          ),
        ],
      );

      // Initialize controller
      final controller = container.read(
        adminDashboardControllerProvider.notifier,
      );
      controller.initialize();

      // Wait for stream to emit and processing
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(adminDashboardControllerProvider);
      expect(state.totalOrders, 1);
      expect(state.totalRevenue, 115.0);
    });

    test('Should update metrics when products change', () async {
      final mockProductNotifier = MockSharedProductNotifier();
      container = ProviderContainer(
        overrides: [
          sharedOrdersProvider.overrideWith((ref) => Stream.value([])),
          sharedProductProvider.overrideWith((ref) => mockProductNotifier),
          sharedCustomersProvider.overrideWith((ref) => Stream.value([])),
          sharedManufacturersProvider.overrideWith((ref) => Stream.value([])),
          adminCustomerControllerProvider.overrideWith(
            (ref) => MockAdminCustomerController(),
          ),
        ],
      );

      // Initialize controller
      final controller = container.read(
        adminDashboardControllerProvider.notifier,
      );
      controller.initialize();

      // Update products
      final product = Product(
        id: 'p1',
        name: 'Product 1',
        price: 100,
        description: 'Desc',
        category: 'Cat',
        imageUrl: 'url',
        inStock: true,
        isPopular: false,
        stockQuantity: 5, // Low stock
      );

      mockProductNotifier.setState(
        SharedProductState(products: [product, product]),
      );

      // Wait for processing
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(adminDashboardControllerProvider);
      expect(state.totalProducts, 2);
      expect(state.lowStockProducts, 2);
    });
  });
}
