import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/admin/application/admin_auth_controller.dart';

void main() {
  group('AdminAuthController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be unauthenticated', () {
      final controller = container.read(adminAuthControllerProvider.notifier);
      final state = container.read(adminAuthControllerProvider);

      expect(state.isAuthenticated, false);
      expect(state.adminUser, null);
      expect(state.loading, false);
      expect(state.error, null);
    });

    test('signIn with valid credentials should succeed', () async {
      final controller = container.read(adminAuthControllerProvider.notifier);

      final result = await controller.signIn('admin@sm.com', 'admin123');

      expect(result, true);

      final state = container.read(adminAuthControllerProvider);
      expect(state.isAuthenticated, true);
      expect(state.adminUser, isNotNull);
      expect(state.adminUser!.email, 'admin@sm.com');
      expect(state.adminUser!.role, AdminRole.superAdmin);
      expect(state.loading, false);
      expect(state.error, null);
    });

    test('signIn with invalid credentials should fail', () async {
      final controller = container.read(adminAuthControllerProvider.notifier);

      final result = await controller.signIn('invalid@sm.com', 'wrongpassword');

      expect(result, false);

      final state = container.read(adminAuthControllerProvider);
      expect(state.isAuthenticated, false);
      expect(state.adminUser, null);
      expect(state.loading, false);
      expect(state.error, isNotNull);
    });

    test('signIn with wrong password should fail', () async {
      final controller = container.read(adminAuthControllerProvider.notifier);

      final result = await controller.signIn('admin@sm.com', 'wrongpassword');

      expect(result, false);

      final state = container.read(adminAuthControllerProvider);
      expect(state.isAuthenticated, false);
      expect(state.adminUser, null);
      expect(state.loading, false);
      expect(state.error, isNotNull);
    });

    test('signOut should reset state', () async {
      final controller = container.read(adminAuthControllerProvider.notifier);

      // First sign in
      await controller.signIn('admin@sm.com', 'admin123');
      expect(container.read(adminAuthControllerProvider).isAuthenticated, true);

      // Then sign out
      controller.signOut();

      final state = container.read(adminAuthControllerProvider);
      expect(state.isAuthenticated, false);
      expect(state.adminUser, null);
      expect(state.loading, false);
      expect(state.error, null);
    });

    test(
      'hasPermission should return correct permissions for superAdmin',
      () async {
        final controller = container.read(adminAuthControllerProvider.notifier);

        await controller.signIn('admin@sm.com', 'admin123');

        expect(controller.hasPermission('manage_products'), true);
        expect(controller.hasPermission('manage_orders'), true);
        expect(controller.hasPermission('manage_customers'), true);
        expect(controller.hasPermission('view_analytics'), true);
        expect(controller.hasPermission('manage_admins'), true);
        expect(controller.hasPermission('system_settings'), true);
        expect(controller.hasPermission('manage_content'), true);
      },
    );

    test(
      'hasPermission should return correct permissions for manager',
      () async {
        final controller = container.read(adminAuthControllerProvider.notifier);

        await controller.signIn('manager@sm.com', 'admin123');

        expect(controller.hasPermission('manage_products'), true);
        expect(controller.hasPermission('manage_orders'), true);
        expect(controller.hasPermission('manage_customers'), true);
        expect(controller.hasPermission('view_analytics'), true);
        expect(controller.hasPermission('manage_admins'), false);
        expect(controller.hasPermission('system_settings'), false);
        expect(controller.hasPermission('manage_content'), true);
      },
    );

    test(
      'hasPermission should return correct permissions for support',
      () async {
        final controller = container.read(adminAuthControllerProvider.notifier);

        await controller.signIn('support@sm.com', 'admin123');

        expect(controller.hasPermission('manage_products'), true);
        expect(controller.hasPermission('manage_orders'), true);
        expect(controller.hasPermission('manage_customers'), true);
        expect(controller.hasPermission('view_analytics'), true);
        expect(controller.hasPermission('manage_admins'), false);
        expect(controller.hasPermission('system_settings'), false);
        expect(controller.hasPermission('manage_content'), false);
      },
    );

    test('hasPermission should return false when not authenticated', () {
      final controller = container.read(adminAuthControllerProvider.notifier);

      expect(controller.hasPermission('manage_products'), false);
      expect(controller.hasPermission('any_permission'), false);
    });

    test('clearError should clear error state', () async {
      final controller = container.read(adminAuthControllerProvider.notifier);

      // Trigger an error
      await controller.signIn('invalid@sm.com', 'wrongpassword');
      expect(container.read(adminAuthControllerProvider).error, isNotNull);

      // Clear error
      controller.clearError();
      expect(container.read(adminAuthControllerProvider).error, null);
    });
  });
}


