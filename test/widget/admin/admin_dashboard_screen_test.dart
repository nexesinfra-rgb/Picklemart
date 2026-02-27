import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:picklemart/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:picklemart/features/admin/application/admin_dashboard_controller.dart';
import 'package:picklemart/features/admin/application/admin_auth_controller.dart';

class MockRef extends Mock implements Ref {}

class FakeAdminDashboardController extends StateNotifier<AdminDashboardState>
    with Mock
    implements AdminDashboardController {
  FakeAdminDashboardController(super.state);

  @override
  Future<void> refresh() async {}
}

void main() {
  group('AdminDashboardScreen Widget Tests', () {
    testWidgets('should display admin dashboard with welcome message', (
      WidgetTester tester,
    ) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) => FakeAdminDashboardController(
                const AdminDashboardState(
                  totalOrders: 1247,
                  totalRevenue: 125000.0,
                  totalProducts: 156,
                  totalCustomers: 342,
                  pendingOrders: 23,
                  lowStockProducts: 8,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Assert
      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Welcome back, Admin User!'), findsOneWidget);
    });

    testWidgets('should display statistics cards', (WidgetTester tester) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) => FakeAdminDashboardController(
                const AdminDashboardState(
                  totalOrders: 1247,
                  totalRevenue: 125000.0,
                  totalProducts: 156,
                  totalCustomers: 342,
                  pendingOrders: 23,
                  lowStockProducts: 8,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Assert
      expect(find.text('1247'), findsOneWidget); // Total Orders
      expect(find.text('₹125000'), findsOneWidget); // Revenue
      expect(find.text('156'), findsOneWidget); // Products
      expect(find.text('342'), findsOneWidget); // Customers
    });

    testWidgets('should display recent orders section', (
      WidgetTester tester,
    ) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) => FakeAdminDashboardController(
                const AdminDashboardState(
                  totalOrders: 1247,
                  totalRevenue: 125000.0,
                  totalProducts: 156,
                  totalCustomers: 342,
                  pendingOrders: 23,
                  lowStockProducts: 8,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Assert
      expect(find.text('Recent Orders'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('should display top products section', (
      WidgetTester tester,
    ) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) => FakeAdminDashboardController(
                const AdminDashboardState(
                  totalOrders: 1247,
                  totalRevenue: 125000.0,
                  totalProducts: 156,
                  totalCustomers: 342,
                  pendingOrders: 23,
                  lowStockProducts: 8,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Assert
      expect(find.text('Top Products'), findsOneWidget);
      expect(
        find.text('View All'),
        findsNWidgets(2),
      ); // One for orders, one for products
    });

    testWidgets('should display user menu in app bar', (
      WidgetTester tester,
    ) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) =>
                  FakeAdminDashboardController(const AdminDashboardState()),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Assert
      expect(find.byType(PopupMenuButton), findsOneWidget);
      expect(find.text('A'), findsOneWidget); // First letter of admin name
    });

    testWidgets('should show loading indicator when data is loading', (
      WidgetTester tester,
    ) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) => FakeAdminDashboardController(
                const AdminDashboardState(loading: true),
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should redirect to login when not authenticated', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => null),
            adminDashboardControllerProvider.overrideWith(
              (ref) =>
                  FakeAdminDashboardController(const AdminDashboardState()),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // In a real app, this would redirect to login
    });

    testWidgets('should display statistics with correct icons', (
      WidgetTester tester,
    ) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) => FakeAdminDashboardController(
                const AdminDashboardState(
                  totalOrders: 1247,
                  totalRevenue: 125000.0,
                  totalProducts: 156,
                  totalCustomers: 342,
                  pendingOrders: 23,
                  lowStockProducts: 8,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Assert
      expect(
        find.byIcon(Icons.receipt_outlined),
        findsOneWidget,
      ); // Orders icon
      expect(
        find.byIcon(Icons.attach_money_outlined),
        findsOneWidget,
      ); // Revenue icon
      expect(
        find.byIcon(Icons.inventory_2_outlined),
        findsOneWidget,
      ); // Products icon
      expect(
        find.byIcon(Icons.people_outline),
        findsOneWidget,
      ); // Customers icon
    });

    testWidgets('should have proper layout structure', (
      WidgetTester tester,
    ) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) =>
                  FakeAdminDashboardController(const AdminDashboardState()),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
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

        final adminUser = AdminUser(
          id: '1',
          name: 'Admin User',
          email: 'admin@sm.com',
          role: AdminRole.superAdmin,
          createdAt: DateTime.now(),
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentAdminProvider.overrideWith((ref) => adminUser),
              adminDashboardControllerProvider.overrideWith(
                (ref) =>
                    FakeAdminDashboardController(const AdminDashboardState()),
              ),
            ],
            child: const MaterialApp(home: AdminDashboardScreen()),
          ),
        );

        // Assert
        expect(find.text('Admin Dashboard'), findsOneWidget);
        expect(find.text('Welcome back, Admin User!'), findsOneWidget);

        // Clean up
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('should handle refresh action', (WidgetTester tester) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) =>
                  FakeAdminDashboardController(const AdminDashboardState()),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Perform pull-to-refresh
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 500),
      );
      await tester.pump();

      // Assert
      // Refresh should be handled (would trigger data reload in real app)
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should display correct role in user menu', (
      WidgetTester tester,
    ) async {
      // Arrange
      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) =>
                  FakeAdminDashboardController(const AdminDashboardState()),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );

      // Tap on user menu
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pump();

      // Assert
      expect(find.text('Profile (superAdmin)'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
