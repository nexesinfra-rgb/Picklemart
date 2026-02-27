import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/auth/presentation/signup_screen.dart';

void main() {
  group('Signup Screen Golden Tests', () {
    testWidgets('Signup Screen - Mobile Portrait (375x812)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/signup',
        routes: [
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder: (context, state) => const SignupScreen(),
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
      expect(find.text('Sign up'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);

      // Take a golden test screenshot
      await expectLater(
        find.byType(SignupScreen),
        matchesGoldenFile('signup_screen_mobile_portrait.png'),
      );
    });

    testWidgets('Signup Screen - Mobile Landscape (812x375)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(812, 375));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/signup',
        routes: [
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder: (context, state) => const SignupScreen(),
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
        find.byType(SignupScreen),
        matchesGoldenFile('signup_screen_mobile_landscape.png'),
      );
    });

    testWidgets('Signup Screen - Tablet Portrait (768x1024)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/signup',
        routes: [
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder: (context, state) => const SignupScreen(),
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
        find.byType(SignupScreen),
        matchesGoldenFile('signup_screen_tablet_portrait.png'),
      );
    });

    testWidgets('Signup Screen - Tablet Landscape (1024x768)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/signup',
        routes: [
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder: (context, state) => const SignupScreen(),
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
        find.byType(SignupScreen),
        matchesGoldenFile('signup_screen_tablet_landscape.png'),
      );
    });

    testWidgets('Signup Screen - Desktop (1920x1080)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/signup',
        routes: [
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder: (context, state) => const SignupScreen(),
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
        find.byType(SignupScreen),
        matchesGoldenFile('signup_screen_desktop.png'),
      );
    });

    testWidgets('Signup Screen - Form Validation', (WidgetTester tester) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/signup',
        routes: [
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder: (context, state) => const SignupScreen(),
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

      // Test form validation with empty fields
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Verify validation messages appear
      expect(find.text('Enter name'), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Min 6 characters'), findsOneWidget);
    });

    testWidgets('Signup Screen - Form Fields Present', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/signup',
        routes: [
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder: (context, state) => const SignupScreen(),
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

      // Verify all form fields are present
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });
  });
}
