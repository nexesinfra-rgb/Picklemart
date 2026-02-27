import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/admin/presentation/admin_login_screen.dart';

void main() {
  group('AdminLoginScreen Golden Tests', () {
    testWidgets('mobile layout', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdminLoginScreen),
        matchesGoldenFile('admin_login_mobile.png'),
      );
    });

    testWidgets('tablet layout', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdminLoginScreen),
        matchesGoldenFile('admin_login_tablet.png'),
      );
    });

    testWidgets('desktop layout', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdminLoginScreen),
        matchesGoldenFile('admin_login_desktop.png'),
      );
    });

    testWidgets('with error state', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      // Enter invalid credentials and submit
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid@sm.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AdminLoginScreen),
        matchesGoldenFile('admin_login_error.png'),
      );
    });

    testWidgets('with loading state', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      // Enter valid credentials and submit
      await tester.enterText(find.byType(TextFormField).first, 'admin@sm.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      await expectLater(
        find.byType(AdminLoginScreen),
        matchesGoldenFile('admin_login_loading.png'),
      );
    });
  });
}


