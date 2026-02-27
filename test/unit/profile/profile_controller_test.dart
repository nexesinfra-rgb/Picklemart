import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:picklemart/features/profile/application/profile_controller.dart';
import 'package:picklemart/features/profile/domain/profile.dart';
import 'package:picklemart/features/profile/data/profile_repository.dart';

import 'profile_controller_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  group('ProfileController Unit Tests', () {
    late MockProfileRepository mockProfileRepository;
    late ProviderContainer container;
    late ProfileController profileController;

    setUp(() {
      mockProfileRepository = MockProfileRepository();
      container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        ],
      );
      profileController = container.read(profileControllerProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        final state = container.read(profileControllerProvider);

        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.profile, isNull);
      });
    });

    group('loadCurrentProfile()', () {
      test('should load profile successfully', () async {
        // Arrange
        final profile = Profile(
          id: 'user1',
          name: 'John Doe',
          mobile: '+1234567890',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );

        when(
          mockProfileRepository.getCurrentProfile(),
        ).thenAnswer((_) async => profile);

        // Act
        await profileController.loadCurrentProfile();

        // Assert
        final state = container.read(profileControllerProvider);
        expect(state.profile, equals(profile));
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);

        verify(mockProfileRepository.getCurrentProfile()).called(1);
      });

      test('should handle error when loading profile fails', () async {
        // Arrange
        const errorMessage = 'Failed to load profile';
        when(
          mockProfileRepository.getCurrentProfile(),
        ).thenThrow(Exception(errorMessage));

        // Act
        await profileController.loadCurrentProfile();

        // Assert
        final state = container.read(profileControllerProvider);
        expect(state.profile, isNull);
        expect(state.isLoading, isFalse);
        expect(state.error, contains(errorMessage));

        verify(mockProfileRepository.getCurrentProfile()).called(1);
      });

      test('should set loading state during profile loading', () async {
        // Arrange
        final profile = Profile(
          id: 'user1',
          name: 'John Doe',
          mobile: '+1234567890',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockProfileRepository.getCurrentProfile()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return profile;
        });

        // Act
        final future = profileController.loadCurrentProfile();

        // Assert loading state
        await Future.delayed(const Duration(milliseconds: 50));
        final loadingState = container.read(profileControllerProvider);
        expect(loadingState.isLoading, isTrue);

        // Wait for completion
        await future;
        final finalState = container.read(profileControllerProvider);
        expect(finalState.isLoading, isFalse);
        expect(finalState.profile, equals(profile));
      });
    });

    group('updateProfile()', () {
      test('should update profile successfully', () async {
        // Arrange
        final originalProfile = Profile(
          id: 'user1',
          name: 'John Doe',
          mobile: '+1234567890',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        final updatedProfile = Profile(
          id: 'user1',
          name: 'John Smith',
          mobile: '+0987654321',
          createdAt: originalProfile.createdAt,
          updatedAt: DateTime.now(),
        );

        // Set initial state
        container.read(profileControllerProvider.notifier).state = ProfileState(
          profile: originalProfile,
        );

        when(
          mockProfileRepository.updateProfile(
            userId: anyNamed('userId'),
            name: anyNamed('name'),
            mobile: anyNamed('mobile'),
            avatarUrl: anyNamed('avatarUrl'),
            removeAvatar: anyNamed('removeAvatar'),
            gender: anyNamed('gender'),
            dateOfBirth: anyNamed('dateOfBirth'),
            email: anyNamed('email'),
          ),
        ).thenAnswer((_) async => updatedProfile);

        // Act
        await profileController.updateProfile(
          name: 'John Smith',
          mobile: '+0987654321',
        );

        // Assert
        final state = container.read(profileControllerProvider);
        expect(state.profile, equals(updatedProfile));
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);

        verify(
          mockProfileRepository.updateProfile(
            userId: anyNamed('userId'),
            name: anyNamed('name'),
            mobile: anyNamed('mobile'),
            avatarUrl: anyNamed('avatarUrl'),
            removeAvatar: anyNamed('removeAvatar'),
            gender: anyNamed('gender'),
            dateOfBirth: anyNamed('dateOfBirth'),
            email: anyNamed('email'),
          ),
        ).called(1);
      });

      test('should handle error when updating profile fails', () async {
        // Arrange
        final profile = Profile(
          id: 'user1',
          name: 'John Doe',
          mobile: '+1234567890',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        container.read(profileControllerProvider.notifier).state = ProfileState(
          profile: profile,
        );

        const errorMessage = 'Failed to update profile';
        when(
          mockProfileRepository.updateProfile(
            userId: anyNamed('userId'),
            name: anyNamed('name'),
            mobile: anyNamed('mobile'),
            avatarUrl: anyNamed('avatarUrl'),
            removeAvatar: anyNamed('removeAvatar'),
            gender: anyNamed('gender'),
            dateOfBirth: anyNamed('dateOfBirth'),
            email: anyNamed('email'),
          ),
        ).thenThrow(Exception(errorMessage));

        // Act
        await profileController.updateProfile(
          name: 'John Smith',
          mobile: '+0987654321',
        );

        // Assert
        final state = container.read(profileControllerProvider);
        expect(state.profile, equals(profile)); // Should remain unchanged
        expect(state.isLoading, isFalse);
        expect(state.error, contains(errorMessage));

        verify(
          mockProfileRepository.updateProfile(
            userId: anyNamed('userId'),
            name: anyNamed('name'),
            mobile: anyNamed('mobile'),
            avatarUrl: anyNamed('avatarUrl'),
            removeAvatar: anyNamed('removeAvatar'),
            gender: anyNamed('gender'),
            dateOfBirth: anyNamed('dateOfBirth'),
            email: anyNamed('email'),
          ),
        ).called(1);
      });

      test('should set loading state during profile update', () async {
        // Arrange
        final profile = Profile(
          id: 'user1',
          name: 'John Doe',
          mobile: '+1234567890',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        container.read(profileControllerProvider.notifier).state = ProfileState(
          profile: profile,
        );

        when(
          mockProfileRepository.updateProfile(
            userId: anyNamed('userId'),
            name: anyNamed('name'),
            mobile: anyNamed('mobile'),
            avatarUrl: anyNamed('avatarUrl'),
            removeAvatar: anyNamed('removeAvatar'),
            gender: anyNamed('gender'),
            dateOfBirth: anyNamed('dateOfBirth'),
            email: anyNamed('email'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return profile.copyWith(name: 'John Smith');
        });

        // Act
        final future = profileController.updateProfile(name: 'John Smith');

        // Assert loading state
        await Future.delayed(const Duration(milliseconds: 50));
        final loadingState = container.read(profileControllerProvider);
        expect(loadingState.isLoading, isTrue);

        // Wait for completion
        await future;
        final finalState = container.read(profileControllerProvider);
        expect(finalState.isLoading, isFalse);
      });
    });

    group('clearError()', () {
      test('should clear error state', () {
        // Arrange
        container
            .read(profileControllerProvider.notifier)
            .state = const ProfileState(error: 'Some error');

        // Act
        profileController.clearError();

        // Assert
        final state = container.read(profileControllerProvider);
        expect(state.error, isNull);
      });
    });

    group('clearProfile()', () {
      test('should clear profile state', () {
        // Arrange
        final profile = Profile(
          id: 'user1',
          name: 'John Doe',
          mobile: '+1234567890',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        container.read(profileControllerProvider.notifier).state = ProfileState(
          profile: profile,
          isLoading: true,
          error: 'Some error',
        );

        // Act
        profileController.clearProfile();

        // Assert
        final state = container.read(profileControllerProvider);
        expect(state.profile, isNull);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });
    });
  });
}
