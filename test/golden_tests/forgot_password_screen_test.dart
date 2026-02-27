import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/auth/presentation/forgot_password_screen.dart';

void main() {
  group('Forgot Password Screen Golden Tests', () {
    testWidgets('Forgot Password Screen - Mobile Portrait (375x812)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/forgot',
        routes: [
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Login Screen'))),
          ),
        ],
      );

      // Build the widget with ProviderScope and a simple theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify the screen elements are present
      expect(find.text('Reset password'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);

      // Take a golden test screenshot
      await expectLater(
        find.byType(ForgotPasswordScreen),
        matchesGoldenFile('forgot_password_screen_mobile_portrait.png'),
      );
    });

    testWidgets('Forgot Password Screen - Mobile Landscape (812x375)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(812, 375));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/forgot',
        routes: [
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Login Screen'))),
          ),
        ],
      );

      // Build the widget with ProviderScope and a simple theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Take a golden test screenshot
      await expectLater(
        find.byType(ForgotPasswordScreen),
        matchesGoldenFile('forgot_password_screen_mobile_landscape.png'),
      );
    });

    testWidgets('Forgot Password Screen - Tablet Portrait (768x1024)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/forgot',
        routes: [
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Login Screen'))),
          ),
        ],
      );

      // Build the widget with ProviderScope and a simple theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Take a golden test screenshot
      await expectLater(
        find.byType(ForgotPasswordScreen),
        matchesGoldenFile('forgot_password_screen_tablet_portrait.png'),
      );
    });

    testWidgets('Forgot Password Screen - Tablet Landscape (1024x768)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/forgot',
        routes: [
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Login Screen'))),
          ),
        ],
      );

      // Build the widget with ProviderScope and a simple theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Take a golden test screenshot
      await expectLater(
        find.byType(ForgotPasswordScreen),
        matchesGoldenFile('forgot_password_screen_tablet_landscape.png'),
      );
    });

    testWidgets('Forgot Password Screen - Desktop (1920x1080)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/forgot',
        routes: [
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Login Screen'))),
          ),
        ],
      );

      // Build the widget with ProviderScope and a simple theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Take a golden test screenshot
      await expectLater(
        find.byType(ForgotPasswordScreen),
        matchesGoldenFile('forgot_password_screen_desktop.png'),
      );
    });

    testWidgets('Forgot Password Screen - Form Validation', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/forgot',
        routes: [
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Login Screen'))),
          ),
        ],
      );

      // Build the widget with ProviderScope and a simple theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Test invalid email validation
      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Verify validation message appears
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('Forgot Password Screen - Form Fields Present', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/forgot',
        routes: [
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Login Screen'))),
          ),
        ],
      );

      // Build the widget with ProviderScope and a simple theme
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            title: 'Pickle Mart',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify all form elements are present
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
