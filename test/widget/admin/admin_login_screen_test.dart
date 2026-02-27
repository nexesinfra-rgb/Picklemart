import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/admin/presentation/admin_login_screen.dart';

void main() {
  group('AdminLoginScreen', () {
    testWidgets('should display login form with all required fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      // Check if all form elements are present
      expect(find.text('Admin Panel'), findsOneWidget);
      expect(
        find.text('Sign in to access the admin dashboard'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('should show demo credentials', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      // Check if demo credentials are displayed
      expect(find.text('Demo Credentials:'), findsOneWidget);
      expect(find.text('Super Admin: admin@sm.com / admin123'), findsOneWidget);
      expect(find.text('Manager: manager@sm.com / admin123'), findsOneWidget);
      expect(find.text('Support: support@sm.com / admin123'), findsOneWidget);
    });

    testWidgets('should validate email field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      // Try to submit with empty email
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should validate password field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      // Enter valid email but empty password
      await tester.enterText(find.byType(TextFormField).first, 'admin@sm.com');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);

      // Enter short password
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('should toggle password visibility', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      final passwordField = find.byType(TextFormField).at(1);
      final toggleButton = find.byIcon(Icons.visibility_outlined);

      // Password should be obscured initially
      final textFieldFinder = find.descendant(of: passwordField, matching: find.byType(TextField));
      TextField field = tester.widget(textFieldFinder);
      expect(field.obscureText, true);

      // Tap toggle button
      await tester.tap(toggleButton);
      await tester.pump();

      // Password should be visible
      field = tester.widget(textFieldFinder);
      expect(field.obscureText, false);
    });

    testWidgets('should show loading state during login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).first, 'admin@sm.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'admin123');

      // Tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message on failed login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      // Enter invalid credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'invalid@sm.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');

      // Tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should be responsive on different screen sizes', (
      WidgetTester tester,
    ) async {
      // Test mobile size
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      expect(find.byType(AdminLoginScreen), findsOneWidget);

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      expect(find.byType(AdminLoginScreen), findsOneWidget);

      // Test desktop size
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: const AdminLoginScreen())),
      );

      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });
  });
}
