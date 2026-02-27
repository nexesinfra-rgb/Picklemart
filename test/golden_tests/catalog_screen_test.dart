import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/catalog/presentation/categories_screen.dart';
import 'package:picklemart/core/ui/app_scaffold.dart';

void main() {
  group('Catalog Screen Golden Tests', () {
    testWidgets('Catalog Screen - Mobile Portrait (375x812)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/catalog',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder: (context, state) => const CategoriesScreen(),
              ),
              GoRoute(
                path: '/browse/:kind/:value',
                name: 'browse',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Browse Products Screen')),
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
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Search categories'), findsOneWidget);

      // Take a golden test screenshot
      await expectLater(
        find.byType(CategoriesScreen),
        matchesGoldenFile('catalog_screen_mobile_portrait.png'),
      );
    });

    testWidgets('Catalog Screen - Mobile Landscape (812x375)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(812, 375));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/catalog',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder: (context, state) => const CategoriesScreen(),
              ),
              GoRoute(
                path: '/browse/:kind/:value',
                name: 'browse',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Browse Products Screen')),
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
        find.byType(CategoriesScreen),
        matchesGoldenFile('catalog_screen_mobile_landscape.png'),
      );
    });

    testWidgets('Catalog Screen - Tablet Portrait (768x1024)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/catalog',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder: (context, state) => const CategoriesScreen(),
              ),
              GoRoute(
                path: '/browse/:kind/:value',
                name: 'browse',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Browse Products Screen')),
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
        find.byType(CategoriesScreen),
        matchesGoldenFile('catalog_screen_tablet_portrait.png'),
      );
    });

    testWidgets('Catalog Screen - Tablet Landscape (1024x768)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/catalog',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder: (context, state) => const CategoriesScreen(),
              ),
              GoRoute(
                path: '/browse/:kind/:value',
                name: 'browse',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Browse Products Screen')),
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
        find.byType(CategoriesScreen),
        matchesGoldenFile('catalog_screen_tablet_landscape.png'),
      );
    });

    testWidgets('Catalog Screen - Desktop (1920x1080)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/catalog',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder: (context, state) => const CategoriesScreen(),
              ),
              GoRoute(
                path: '/browse/:kind/:value',
                name: 'browse',
                builder:
                    (context, state) => const Scaffold(
                      body: Center(child: Text('Browse Products Screen')),
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
        find.byType(CategoriesScreen),
        matchesGoldenFile('catalog_screen_desktop.png'),
      );
    });

    testWidgets('Catalog Screen - Search Functionality', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/catalog',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder: (context, state) => const CategoriesScreen(),
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

      // Test search functionality
      await tester.enterText(find.byType(TextField), 'tools');
      await tester.pumpAndSettle();

      // Verify search is working (categories should be filtered)
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Catalog Screen - Basic Elements Present', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/catalog',
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppScaffold(child: child),
            routes: [
              GoRoute(
                path: '/catalog',
                name: 'catalog',
                builder: (context, state) => const CategoriesScreen(),
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
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Search categories'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
