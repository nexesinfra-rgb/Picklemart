import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picklemart/features/profile/presentation/profile_screen.dart';
import 'package:picklemart/features/profile/application/profile_controller.dart';
import 'package:picklemart/features/profile/domain/profile.dart';

void main() {
  group('ProfileScreen Golden Tests', () {
    testWidgets('profile screen mobile portrait', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final profile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => ProfileState(profile: profile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_mobile_portrait.png'),
      );
    });

    testWidgets('profile screen mobile landscape', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(667, 375);
      tester.view.devicePixelRatio = 1.0;

      final profile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => ProfileState(profile: profile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_mobile_landscape.png'),
      );
    });

    testWidgets('profile screen tablet portrait', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

      final profile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => ProfileState(profile: profile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_tablet_portrait.png'),
      );
    });

    testWidgets('profile screen tablet landscape', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;

      final profile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => ProfileState(profile: profile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_tablet_landscape.png'),
      );
    });

    testWidgets('profile screen desktop', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      final profile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => ProfileState(profile: profile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_desktop.png'),
      );
    });

    testWidgets('profile screen loading state', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => const ProfileState(isLoading: true),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_loading.png'),
      );
    });

    testWidgets('profile screen error state', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => const ProfileState(error: 'Failed to load profile'),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_error.png'),
      );
    });

    testWidgets('profile screen with avatar', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final profile = Profile(
        id: '1',
        name: 'John Doe',
        mobile: '+1234567890',
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => ProfileState(profile: profile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_with_avatar.png'),
      );
    });

    testWidgets('profile screen without phone', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final profile = Profile(
        id: '1',
        name: 'Jane Smith',
        mobile: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => ProfileState(profile: profile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_without_phone.png'),
      );
    });

    testWidgets('profile screen admin role', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;

      final profile = Profile(
        id: '1',
        name: 'Admin User',
        mobile: '+1234567890',
        role: 'admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => ProfileState(profile: profile),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      await expectLater(
        find.byType(ProfileScreen),
        matchesGoldenFile('profile_screen_admin_role.png'),
      );
    });
  });
}
