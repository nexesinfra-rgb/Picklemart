import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:picklemart/features/admin/application/admin_dashboard_controller.dart';
import 'package:picklemart/features/admin/application/admin_auth_controller.dart';

class FakeAdminDashboardController extends StateNotifier<AdminDashboardState> {
  FakeAdminDashboardController(super.state);

  @override
  Future<void> refresh() async {}
}

void main() {
  group('AdminDashboardScreen Golden Tests', () {
    testWidgets('admin dashboard mobile portrait', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
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
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(AdminDashboardScreen),
        matchesGoldenFile('admin_dashboard_screen_mobile_portrait.png'),
      );
    });

    testWidgets('admin dashboard mobile landscape', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(667, 375);
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
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(AdminDashboardScreen),
        matchesGoldenFile('admin_dashboard_screen_mobile_landscape.png'),
      );
    });

    testWidgets('admin dashboard tablet portrait', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(768, 1024);
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
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(AdminDashboardScreen),
        matchesGoldenFile('admin_dashboard_screen_tablet_portrait.png'),
      );
    });

    testWidgets('admin dashboard tablet landscape', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(1024, 768);
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
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(AdminDashboardScreen),
        matchesGoldenFile('admin_dashboard_screen_tablet_landscape.png'),
      );
    });

    testWidgets('admin dashboard desktop', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
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
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(AdminDashboardScreen),
        matchesGoldenFile('admin_dashboard_screen_desktop.png'),
      );
    });

    testWidgets('admin dashboard loading state', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
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
              (ref) => FakeAdminDashboardController(
                const AdminDashboardState(loading: true),
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(AdminDashboardScreen),
        matchesGoldenFile('admin_dashboard_screen_loading.png'),
      );
    });

    testWidgets('admin dashboard with manager role', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final adminUser = AdminUser(
        id: '2',
        name: 'Manager User',
        email: 'manager@sm.com',
        role: AdminRole.manager,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) => const AdminDashboardState(
                totalOrders: 1247,
                totalRevenue: 125000.0,
                totalProducts: 156,
                totalCustomers: 342,
                pendingOrders: 23,
                lowStockProducts: 8,
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(AdminDashboardScreen),
        matchesGoldenFile('admin_dashboard_screen_manager.png'),
      );
    });

    testWidgets('admin dashboard with support role', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final adminUser = AdminUser(
        id: '3',
        name: 'Support User',
        email: 'support@sm.com',
        role: AdminRole.support,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) => const AdminDashboardState(
                totalOrders: 1247,
                totalRevenue: 125000.0,
                totalProducts: 156,
                totalCustomers: 342,
                pendingOrders: 23,
                lowStockProducts: 8,
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(AdminDashboardScreen),
        matchesGoldenFile('admin_dashboard_screen_support.png'),
      );
    });

    testWidgets('admin dashboard with user menu open', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final adminUser = AdminUser(
        id: '1',
        name: 'Admin User',
        email: 'admin@sm.com',
        role: AdminRole.superAdmin,
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProvider.overrideWith((ref) => adminUser),
            adminDashboardControllerProvider.overrideWith(
              (ref) => const AdminDashboardState(
                totalOrders: 1247,
                totalRevenue: 125000.0,
                totalProducts: 156,
                totalCustomers: 342,
                pendingOrders: 23,
                lowStockProducts: 8,
              ),
            ),
          ],
          child: const MaterialApp(home: AdminDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on user menu
      await tester.tap(find.byType(PopupMenuButton));
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(AdminDashboardScreen),
        matchesGoldenFile('admin_dashboard_screen_user_menu.png'),
      );
    });
  });
}
