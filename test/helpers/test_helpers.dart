import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/core/router/app_router.dart';
import 'package:picklemart/features/admin/application/admin_auth_controller.dart';
import 'package:picklemart/features/admin/domain/admin_user.dart';

/// Test helper to create a MaterialApp with GoRouter for widget tests
Widget createTestApp({required Widget child}) {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

/// Test helper to create a MaterialApp with GoRouter for admin widget tests
Widget createAdminTestApp({required Widget child}) {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

/// Test helper to create a simple MaterialApp without router for basic widget tests
Widget createSimpleTestApp({required Widget child}) {
  return ProviderScope(child: MaterialApp(home: child));
}

/// Test helper to create a MaterialApp with mocked admin auth for admin widget tests
Widget createAdminTestAppWithMockAuth({required Widget child}) {
  return ProviderScope(
    overrides: [
      // Mock admin auth to always return authenticated admin user
      currentAdminProvider.overrideWith(
        (ref) => const AdminUser(
          id: 'test-admin-id',
          email: 'admin@test.com',
          name: 'Test Admin',
          role: AdminRole.superAdmin,
        ),
      ),
    ],
    child: MaterialApp(home: child),
  );
}
