import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:picklemart/features/auth/application/auth_controller.dart';
import 'package:picklemart/features/auth/data/auth_repository.dart';
import 'package:picklemart/features/profile/application/profile_controller.dart';
import 'package:picklemart/features/profile/data/profile_repository.dart';
import 'package:picklemart/features/profile/domain/profile.dart';
import 'package:picklemart/core/config/environment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_controller_test.mocks.dart';

@GenerateMocks([AuthRepository, ProfileRepository, User, AuthResponse])
void main() {
  group('AuthController Unit Tests', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepository;
    late MockProfileRepository mockProfileRepository;
    late MockUser mockUser;
    late MockAuthResponse mockAuthResponse;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockProfileRepository = MockProfileRepository();
      mockUser = MockUser();
      mockAuthResponse = MockAuthResponse();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          profileRepositoryProvider.overrideWithValue(mockProfileRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        final state = container.read(authControllerProvider);

        expect(state.isAuthenticated, isFalse);
        expect(state.userId, isNull);
        expect(state.role, equals(AppRole.none));
        expect(state.email, isNull);
        expect(state.mobile, isNull);
        expect(state.displayMobile, isNull);
        expect(state.loading, isFalse);
        expect(state.error, isNull);
      });
    });

    group('selectRole()', () {
      test('should select user role', () {
        // Act
        container
            .read(authControllerProvider.notifier)
            .selectRole(AppRole.user);

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.role, equals(AppRole.user));
      });

      test('should select admin role', () {
        // Act
        container
            .read(authControllerProvider.notifier)
            .selectRole(AppRole.admin);

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.role, equals(AppRole.admin));
      });
    });

    group('signInWithMobile()', () {
      test('should sign in successfully with mobile', () async {
        // Arrange
        const mobileDigits = '9876543210';
        const password = 'password123';
        const userId = 'mock-user-id';

        when(mockUser.id).thenReturn(userId);
        when(mockUser.email).thenReturn('9876543210@sm.local');
        when(mockUser.userMetadata).thenReturn({
          'name': 'John Doe',
          'mobile': mobileDigits,
          'display_mobile': '+91 98765 43210',
          'role': 'user',
        });

        // Create a real AuthResponse instead of mock, as it's a data class
        final authResponse = AuthResponse(
          user: mockUser,
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: mockUser,
          ),
        );

        when(
          mockAuthRepository.signInWithMobile(
            mobile: mobileDigits,
            password: password,
          ),
        ).thenAnswer((_) async => authResponse);

        when(
          mockProfileRepository.profileExists(userId),
        ).thenAnswer((_) async => true);

        // Act
        await container
            .read(authControllerProvider.notifier)
            .signInWithMobile(mobileDigits, password);

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isTrue);
        expect(state.userId, equals(userId));
        expect(state.mobile, equals(mobileDigits));
        expect(state.displayMobile, equals('+91 98765 43210'));
        expect(state.loading, isFalse);
        expect(state.error, isNull);

        verify(
          mockAuthRepository.signInWithMobile(
            mobile: mobileDigits,
            password: password,
          ),
        ).called(1);
        verify(mockProfileRepository.profileExists(userId)).called(1);
      });

      test('should handle sign in error', () async {
        // Arrange
        const mobileDigits = '9876543210';
        const password = 'wrongpassword';

        when(
          mockAuthRepository.signInWithMobile(
            mobile: mobileDigits,
            password: password,
          ),
        ).thenThrow(Exception('Invalid credentials'));

        // Act
        await container
            .read(authControllerProvider.notifier)
            .signInWithMobile(mobileDigits, password);

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.loading, isFalse);
        expect(state.error, isNotNull);
        expect(state.error, contains('Invalid credentials'));
      });
    });

    group('signUpWithMobile()', () {
      test('should sign up successfully with mobile', () async {
        // Arrange
        const name = 'John Doe';
        const mobileDigits = '9876543210';
        const password = 'password123';
        const userId = 'mock-user-id';

        when(mockUser.id).thenReturn(userId);
        when(mockUser.email).thenReturn('9876543210@sm.local');
        when(mockUser.userMetadata).thenReturn({
          'name': name,
          'mobile': mobileDigits,
          'display_mobile': '+91 98765 43210',
          'role': 'user',
        });

        final authResponse = AuthResponse(
          user: mockUser,
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: mockUser,
          ),
        );

        when(
          mockAuthRepository.signUpWithMobile(
            name: name,
            mobile: mobileDigits,
            password: password,
          ),
        ).thenAnswer((_) async => authResponse);

        when(
          mockProfileRepository.profileExists(userId),
        ).thenAnswer((_) async => false);

        when(
          mockProfileRepository.createProfile(
            userId: anyNamed('userId'),
            name: anyNamed('name'),
            mobile: anyNamed('mobile'),
            avatarUrl: anyNamed('avatarUrl'),
            role: anyNamed('role'),
            gender: anyNamed('gender'),
            dateOfBirth: anyNamed('dateOfBirth'),
            email: anyNamed('email'),
          ),
        ).thenAnswer(
          (_) async => Profile(
            id: userId,
            name: name,
            mobile: mobileDigits,
            displayMobile: '+91 98765 43210',
            role: 'user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Act
        await container
            .read(authControllerProvider.notifier)
            .signUpWithMobile(name, mobileDigits, password);

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isTrue);
        expect(state.userId, equals(userId));
        expect(state.mobile, equals(mobileDigits));
        expect(state.displayMobile, equals('+91 98765 43210'));
        expect(state.loading, isFalse);
        expect(state.error, isNull);

        verify(
          mockAuthRepository.signUpWithMobile(
            name: name,
            mobile: mobileDigits,
            password: password,
          ),
        ).called(1);
        verify(mockProfileRepository.profileExists(userId)).called(1);
        verify(
          mockProfileRepository.createProfile(
            userId: anyNamed('userId'),
            name: anyNamed('name'),
            mobile: anyNamed('mobile'),
          ),
        ).called(1);
      });

      test('should handle sign up error', () async {
        // Arrange
        const name = 'John Doe';
        const mobileDigits = '9876543210';
        const password = 'password123';

        when(
          mockAuthRepository.signUpWithMobile(
            name: name,
            mobile: mobileDigits,
            password: password,
          ),
        ).thenThrow(Exception('User already exists'));

        // Act
        await container
            .read(authControllerProvider.notifier)
            .signUpWithMobile(name, mobileDigits, password);

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.loading, isFalse);
        expect(state.error, isNotNull);
        expect(state.error, contains('User already exists'));
      });
    });

    group('resetPasswordWithMobile()', () {
      test('should reset password successfully with mobile', () async {
        // Arrange
        const mobileDigits = '9876543210';

        when(
          mockAuthRepository.resetPasswordWithMobile(
            mobile: mobileDigits,
            url: Environment.passwordResetRedirectUrl,
          ),
        ).thenAnswer((_) async => {});

        // Act
        await container
            .read(authControllerProvider.notifier)
            .resetPasswordWithMobile(mobileDigits);

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, isNull);

        verify(
          mockAuthRepository.resetPasswordWithMobile(
            mobile: mobileDigits,
            url: Environment.passwordResetRedirectUrl,
          ),
        ).called(1);
      });

      test('should handle reset password error', () async {
        // Arrange
        const mobileDigits = '9876543210';

        when(
          mockAuthRepository.resetPasswordWithMobile(
            mobile: mobileDigits,
            url: Environment.passwordResetRedirectUrl,
          ),
        ).thenThrow(Exception('User not found'));

        // Act
        await container
            .read(authControllerProvider.notifier)
            .resetPasswordWithMobile(mobileDigits);

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.loading, isFalse);
        expect(state.error, isNotNull);
        expect(state.error, contains('User not found'));
      });
    });

    group('signOut()', () {
      test('should sign out successfully', () async {
        // Arrange - first sign in
        const mobileDigits = '9876543210';
        const password = 'password123';
        const userId = 'mock-user-id';

        when(mockUser.id).thenReturn(userId);
        when(mockUser.email).thenReturn('9876543210@sm.local');
        when(mockUser.userMetadata).thenReturn({
          'name': 'John Doe',
          'mobile': mobileDigits,
          'display_mobile': '+91 98765 43210',
          'role': 'user',
        });

        final authResponse = AuthResponse(
          user: mockUser,
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: mockUser,
          ),
        );

        when(
          mockAuthRepository.signInWithMobile(
            mobile: mobileDigits,
            password: password,
          ),
        ).thenAnswer((_) async => authResponse);

        when(
          mockProfileRepository.profileExists(userId),
        ).thenAnswer((_) async => true);

        when(mockAuthRepository.signOut()).thenAnswer((_) async => {});

        await container
            .read(authControllerProvider.notifier)
            .signInWithMobile(mobileDigits, password);

        expect(container.read(authControllerProvider).isAuthenticated, isTrue);

        // Act
        container.read(authControllerProvider.notifier).signOut();

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.userId, isNull);
        expect(state.role, equals(AppRole.none));
        expect(state.email, isNull);
        expect(state.mobile, isNull);
        expect(state.displayMobile, isNull);
        expect(state.loading, isFalse);
        expect(state.error, isNull);

        verify(mockAuthRepository.signOut()).called(1);
      });
    });

    group('Loading States', () {
      test('should set loading state during sign in', () async {
        // Arrange
        const mobileDigits = '9876543210';
        const password = 'password123';

        when(mockUser.id).thenReturn('mock-user-id');
        when(mockUser.email).thenReturn('9876543210@sm.local');

        when(
          mockAuthRepository.signInWithMobile(
            mobile: mobileDigits,
            password: password,
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return AuthResponse(
            user: mockUser,
            session: Session(
              accessToken: 'token',
              tokenType: 'bearer',
              user: mockUser,
            ),
          );
        });

        when(
          mockProfileRepository.profileExists(any),
        ).thenAnswer((_) async => true);

        // Act
        final future = container
            .read(authControllerProvider.notifier)
            .signInWithMobile(mobileDigits, password);

        // Check loading state immediately
        expect(container.read(authControllerProvider).loading, isTrue);

        // Wait for completion
        await future;

        // Check loading state after completion
        expect(container.read(authControllerProvider).loading, isFalse);
      });
    });
  });
}
