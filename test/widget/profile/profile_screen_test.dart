import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:picklemart/features/profile/application/profile_controller.dart';
import 'package:picklemart/features/profile/data/profile_repository.dart';
import 'package:picklemart/features/profile/domain/profile.dart';
import 'package:picklemart/features/profile/presentation/profile_screen.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockRef extends Mock implements Ref {}

class FakeProfileController extends StateNotifier<ProfileState>
    with Mock
    implements ProfileController {
  FakeProfileController(ProfileState state) : super(state);
}

void main() {
  group('ProfileScreen Widget Tests', () {
    testWidgets('should display user profile information', (
      WidgetTester tester,
    ) async {
      // Arrange
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
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);
    });

    testWidgets('should display user profile without phone', (
      WidgetTester tester,
    ) async {
      // Arrange
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
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets(
      'should navigate to edit profile screen when edit button is tapped',
      (WidgetTester tester) async {
        // Arrange
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
                (ref) => FakeProfileController(ProfileState(profile: profile)),
              ),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      },
    );

    testWidgets('should show loading indicator when profile is loading', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) =>
                  FakeProfileController(const ProfileState(isLoading: true)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display profile with avatar', (
      WidgetTester tester,
    ) async {
      // Arrange
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
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should display profile with role', (
      WidgetTester tester,
    ) async {
      // Arrange
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
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.text('Admin User'), findsOneWidget);
    });

    testWidgets('should show error message when profile loading fails', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => FakeProfileController(
                const ProfileState(error: 'Error loading profile'),
              ),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(
        find.text('Error loading profile: Error loading profile'),
        findsOneWidget,
      );
    });

    testWidgets('should display profile settings options', (
      WidgetTester tester,
    ) async {
      // Arrange
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
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should display logout option', (WidgetTester tester) async {
      // Arrange
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
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('should display privacy policy option', (
      WidgetTester tester,
    ) async {
      // Arrange
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
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('should display terms and conditions option', (
      WidgetTester tester,
    ) async {
      // Arrange
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
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.text('Terms & Conditions'), findsOneWidget);
    });

    testWidgets('should display help and support with coming soon message', (
      WidgetTester tester,
    ) async {
      // Arrange
      final profile = Profile(
        id: '1',
        name: 'Test User',
        mobile: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Tap on Help & Support
      await tester.tap(find.text('Help & Support'));
      await tester.pump();

      // Assert
      expect(find.text('Help & Support coming soon'), findsOneWidget);
    });

    testWidgets('should display user without phone number', (
      WidgetTester tester,
    ) async {
      // Arrange
      final profile = Profile(
        id: '1',
        name: 'Test User',
        mobile: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              (ref) => FakeProfileController(ProfileState(profile: profile)),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      // Assert
      expect(find.text('Test User'), findsOneWidget);
    });
  });
}
