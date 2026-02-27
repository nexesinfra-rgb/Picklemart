import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/home/presentation/home_screen.dart';
import 'package:picklemart/core/ui/app_scaffold.dart';

void main() {
  group('Home Screen Golden Tests', () {
    testWidgets('Home Screen - Mobile Portrait (375x812)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/search',
                name: 'search',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Search Screen')),
                    ),
              ),
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Catalog Screen')),
                    ),
              ),
              GoRoute(
                path: '/cart',
                name: 'cart',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Cart Screen')),
                    ),
              ),
            ],
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
      expect(
        find.text('Home'),
        findsNWidgets(2),
      ); // AppBar title and NavigationBar
      expect(find.text('Search for products'), findsOneWidget);
      expect(find.text('Featured Categories'), findsOneWidget);
      expect(find.text('Featured Products'), findsOneWidget);
      expect(find.text('See all'), findsNWidgets(2));

      // Take a golden test screenshot
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_mobile_portrait.png'),
      );
    });

    testWidgets('Home Screen - Mobile Landscape (812x375)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(812, 375));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/search',
                name: 'search',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Search Screen')),
                    ),
              ),
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Catalog Screen')),
                    ),
              ),
              GoRoute(
                path: '/cart',
                name: 'cart',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Cart Screen')),
                    ),
              ),
            ],
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
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_mobile_landscape.png'),
      );
    });

    testWidgets('Home Screen - Tablet Portrait (768x1024)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/search',
                name: 'search',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Search Screen')),
                    ),
              ),
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Catalog Screen')),
                    ),
              ),
              GoRoute(
                path: '/cart',
                name: 'cart',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Cart Screen')),
                    ),
              ),
            ],
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
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_tablet_portrait.png'),
      );
    });

    testWidgets('Home Screen - Tablet Landscape (1024x768)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/search',
                name: 'search',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Search Screen')),
                    ),
              ),
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Catalog Screen')),
                    ),
              ),
              GoRoute(
                path: '/cart',
                name: 'cart',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Cart Screen')),
                    ),
              ),
            ],
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
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_tablet_landscape.png'),
      );
    });

    testWidgets('Home Screen - Desktop (1920x1080)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/search',
                name: 'search',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Search Screen')),
                    ),
              ),
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Catalog Screen')),
                    ),
              ),
              GoRoute(
                path: '/cart',
                name: 'cart',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Cart Screen')),
                    ),
              ),
            ],
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
        find.byType(HomeScreen),
        matchesGoldenFile('home_screen_desktop.png'),
      );
    });

    testWidgets('Home Screen - Basic Elements Present', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
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

      // Verify basic elements are present
      expect(
        find.text('Home'),
        findsNWidgets(2),
      ); // AppBar title and NavigationBar
      expect(find.text('Search for products'), findsOneWidget);
      expect(find.text('Featured Categories'), findsOneWidget);
      expect(find.text('Featured Products'), findsOneWidget);
      expect(find.text('Spring Sale'), findsOneWidget);
      expect(find.text('Up to 50% off'), findsOneWidget);
      expect(find.text('Shop Now'), findsOneWidget);
    });
  });
}
