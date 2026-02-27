import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:picklemart/features/profile/presentation/profile_screen.dart';
import 'package:picklemart/features/profile/domain/profile.dart';
import 'package:picklemart/features/profile/application/profile_controller.dart';

void main() {
  group('Profile Screen Golden Tests', () {
    testWidgets('Profile Screen - Mobile Portrait (375x812)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(375, 812));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/settings',
            name: 'profile-settings',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Settings Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/edit',
            name: 'profile-edit',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Edit Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/addresses',
            name: 'profile-addresses',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Addresses Screen')),
                ),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Orders Screen'))),
          ),
        ],
      );

      // Create mock profile
      final mockProfile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith((ref) => ProfileController(ref)..state = ProfileState(profile: mockProfile)),
          ],
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
      await tester.pumpAndSettle();

      // Verify the screen elements are present
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Addresses'), findsOneWidget);

      // Take golden screenshot
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('profile_screen_mobile_portrait.png'),
      );
    });

    testWidgets('Profile Screen - Mobile Landscape (812x375)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(812, 375));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/settings',
            name: 'profile-settings',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Settings Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/edit',
            name: 'profile-edit',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Edit Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/addresses',
            name: 'profile-addresses',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Addresses Screen')),
                ),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Orders Screen'))),
          ),
        ],
      );

      // Create mock profile
      final mockProfile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith((ref) => ProfileController(ref)..state = ProfileState(profile: mockProfile)),
          ],
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
      await tester.pumpAndSettle();

      // Verify the screen elements are present
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);

      // Take golden screenshot
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('profile_screen_mobile_landscape.png'),
      );
    });

    testWidgets('Profile Screen - Tablet Portrait (768x1024)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(768, 1024));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/settings',
            name: 'profile-settings',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Settings Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/edit',
            name: 'profile-edit',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Edit Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/addresses',
            name: 'profile-addresses',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Addresses Screen')),
                ),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Orders Screen'))),
          ),
        ],
      );

      // Create mock profile
      final mockProfile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith((ref) => ProfileController(ref)..state = ProfileState(profile: mockProfile)),
          ],
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
      await tester.pumpAndSettle();

      // Verify the screen elements are present
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);

      // Take golden screenshot
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('profile_screen_tablet_portrait.png'),
      );
    });

    testWidgets('Profile Screen - Tablet Landscape (1024x768)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/settings',
            name: 'profile-settings',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Settings Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/edit',
            name: 'profile-edit',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Edit Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/addresses',
            name: 'profile-addresses',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Addresses Screen')),
                ),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Orders Screen'))),
          ),
        ],
      );

      // Create mock profile
      final mockProfile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith((ref) => ProfileController(ref)..state = ProfileState(profile: mockProfile)),
          ],
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
      await tester.pumpAndSettle();

      // Verify the screen elements are present
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);

      // Take golden screenshot
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('profile_screen_tablet_landscape.png'),
      );
    });

    testWidgets('Profile Screen - Desktop (1920x1080)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(1920, 1080));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/settings',
            name: 'profile-settings',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Settings Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/edit',
            name: 'profile-edit',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Edit Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/addresses',
            name: 'profile-addresses',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Addresses Screen')),
                ),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Orders Screen'))),
          ),
        ],
      );

      // Create mock profile
      final mockProfile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith((ref) => ProfileController(ref)..state = ProfileState(profile: mockProfile)),
          ],
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
      await tester.pumpAndSettle();

      // Verify the screen elements are present
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);

      // Take golden screenshot
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('profile_screen_desktop.png'),
      );
    });

    testWidgets('Profile Screen - Large Desktop (2560x1440)', (
      WidgetTester tester,
    ) async {
      // Set up the test environment
      await tester.binding.setSurfaceSize(const Size(2560, 1440));

      // Create a test router with proper route names
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/settings',
            name: 'profile-settings',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Settings Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/edit',
            name: 'profile-edit',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Profile Edit Screen')),
                ),
          ),
          GoRoute(
            path: '/profile/addresses',
            name: 'profile-addresses',
            builder:
                (context, state) => const Scaffold(
                  body: Center(child: Text('Addresses Screen')),
                ),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder:
                (context, state) =>
                    const Scaffold(body: Center(child: Text('Orders Screen'))),
          ),
        ],
      );

      // Create mock profile
      final mockProfile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith((ref) => ProfileController(ref)..state = ProfileState(profile: mockProfile)),
          ],
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
      await tester.pumpAndSettle();

      // Verify the screen elements are present
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);

      // Take golden screenshot
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('profile_screen_large_desktop.png'),
      );
    });
  });
}
