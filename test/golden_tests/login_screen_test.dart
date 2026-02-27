import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/auth/presentation/login_screen.dart';

void main() {
  group('Login Screen Golden Tests', () {
    testWidgets('Login Screen - Mobile Portrait (375x812)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Home Screen'))),
          ),
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Forgot Password Screen')),
                ),
          ),
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Signup Screen'))),
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
      expect(find.text('Login'), findsNWidgets(2)); // AppBar title and button
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text("Don't have an account? Sign up"), findsOneWidget);

      // Take a golden test screenshot
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('login_screen_mobile_portrait.png'),
      );
    });

    testWidgets('Login Screen - Mobile Landscape (812x375)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(812, 375));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Home Screen'))),
          ),
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Forgot Password Screen')),
                ),
          ),
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Signup Screen'))),
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
        find.byType(LoginScreen),
        matchesGoldenFile('login_screen_mobile_landscape.png'),
      );
    });

    testWidgets('Login Screen - Tablet Portrait (768x1024)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Home Screen'))),
          ),
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Forgot Password Screen')),
                ),
          ),
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Signup Screen'))),
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
        find.byType(LoginScreen),
        matchesGoldenFile('login_screen_tablet_portrait.png'),
      );
    });

    testWidgets('Login Screen - Tablet Landscape (1024x768)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Home Screen'))),
          ),
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Forgot Password Screen')),
                ),
          ),
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Signup Screen'))),
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
        find.byType(LoginScreen),
        matchesGoldenFile('login_screen_tablet_landscape.png'),
      );
    });

    testWidgets('Login Screen - Desktop (1920x1080)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Home Screen'))),
          ),
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Forgot Password Screen')),
                ),
          ),
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Signup Screen'))),
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
        find.byType(LoginScreen),
        matchesGoldenFile('login_screen_desktop.png'),
      );
    });

    testWidgets('Login Screen - Form Validation', (WidgetTester tester) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/home',
            name: 'home',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Home Screen'))),
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
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, '123');

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Verify validation messages appear
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Min 6 characters'), findsOneWidget);
    });

    testWidgets('Login Screen - Navigation to Forgot Password', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/forgot',
            name: 'forgot',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Forgot Password Screen')),
                ),
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

      // Tap forgot password button
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      // Verify navigation to forgot password screen
      expect(find.text('Forgot Password Screen'), findsOneWidget);
    });

    testWidgets('Login Screen - Navigation to Signup', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/signup',
            name: 'signup',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Signup Screen'))),
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

      // Tap signup button
      await tester.tap(find.text("Don't have an account? Sign up"));
      await tester.pumpAndSettle();

      // Verify navigation to signup screen
      expect(find.text('Signup Screen'), findsOneWidget);
    });
  });
}
