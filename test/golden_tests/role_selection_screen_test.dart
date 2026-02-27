import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/auth/presentation/role_selection_screen.dart';

void main() {
  group('Role Selection Screen Golden Tests', () {
    testWidgets('Role Selection Screen - Mobile Portrait (375x812)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 'role',
            builder: (context, state) => const RoleSelectionScreen(),
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

      // Build the widget with ProviderScope and a simple theme to avoid Google Fonts issues
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
      expect(find.text('Pickle Mart'), findsOneWidget);
      expect(find.text('Choose your role'), findsOneWidget);
      expect(find.text('Continue as User'), findsOneWidget);
      expect(find.text('Admin (coming soon)'), findsOneWidget);

      // Take a golden test screenshot
      await expectLater(
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_mobile_portrait.png'),
      );
    });

    testWidgets('Role Selection Screen - Mobile Landscape (812x375)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(812, 375));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 'role',
            builder: (context, state) => const RoleSelectionScreen(),
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

      // Build the widget with ProviderScope and a simple theme to avoid Google Fonts issues
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
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_mobile_landscape.png'),
      );
    });

    testWidgets('Role Selection Screen - Tablet Portrait (768x1024)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 'role',
            builder: (context, state) => const RoleSelectionScreen(),
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

      // Build the widget with ProviderScope and a simple theme to avoid Google Fonts issues
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
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_tablet_portrait.png'),
      );
    });

    testWidgets('Role Selection Screen - Tablet Landscape (1024x768)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 'role',
            builder: (context, state) => const RoleSelectionScreen(),
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

      // Build the widget with ProviderScope and a simple theme to avoid Google Fonts issues
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
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_tablet_landscape.png'),
      );
    });

    testWidgets('Role Selection Screen - Desktop (1920x1080)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 'role',
            builder: (context, state) => const RoleSelectionScreen(),
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

      // Build the widget with ProviderScope and a simple theme to avoid Google Fonts issues
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
        find.byType(RoleSelectionScreen),
        matchesGoldenFile('role_selection_screen_desktop.png'),
      );
    });

    testWidgets('Role Selection Screen - User Button Interaction', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 'role',
            builder: (context, state) => const RoleSelectionScreen(),
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

      // Build the widget with ProviderScope and a simple theme to avoid Google Fonts issues
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

      // Find and tap the "Continue as User" button
      final userButton = find.text('Continue as User');
      expect(userButton, findsOneWidget);

      await tester.tap(userButton);
      await tester.pumpAndSettle();

      // Verify navigation to login screen
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('Role Selection Screen - Admin Button Interaction', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            name: 'role',
            builder: (context, state) => const RoleSelectionScreen(),
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

      // Build the widget with ProviderScope and a simple theme to avoid Google Fonts issues
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

      // Find and tap the "Admin (coming soon)" button
      final adminButton = find.text('Admin (coming soon)');
      expect(adminButton, findsOneWidget);

      await tester.tap(adminButton);
      await tester.pumpAndSettle();

      // Verify navigation to login screen
      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
