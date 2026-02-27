import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picklemart/features/auth/data/auth_repository.dart';
import 'package:picklemart/core/utils/phone_utils.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, GoTrueClient, AuthResponse, User, Session])
import 'auth_repository_test.mocks.dart';

void main() {
  group('AuthRepository Tests', () {
    late AuthRepository authRepository;
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockGoTrueClient;
    late MockAuthResponse mockAuthResponse;
    late MockUser mockUser;
    late MockSession mockSession;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockGoTrueClient = MockGoTrueClient();
      mockAuthResponse = MockAuthResponse();
      mockUser = MockUser();
      mockSession = MockSession();

      when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
      authRepository = AuthRepository(mockSupabaseClient);
    });

    group('signInWithMobile', () {
      test('should sign in successfully with valid mobile number', () async {
        // Arrange
        const mobile = '9876543210';
        const password = 'password123';
        final email = PhoneUtils.mobileToEmail(mobile);

        when(mockGoTrueClient.signInWithPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockAuthResponse);

        when(mockAuthResponse.user).thenReturn(mockUser);
        when(mockAuthResponse.session).thenReturn(mockSession);

        // Act
        final result = await authRepository.signInWithMobile(
          mobile: mobile,
          password: password,
        );

        // Assert
        expect(result.user, equals(mockUser));
        expect(result.session, equals(mockSession));
        verify(mockGoTrueClient.signInWithPassword(
          email: email,
          password: password,
        )).called(1);
      });

      test('should throw exception when sign in fails', () async {
        // Arrange
        const mobile = '9876543210';
        const password = 'wrongpassword';
        final email = PhoneUtils.mobileToEmail(mobile);

        when(mockGoTrueClient.signInWithPassword(
          email: email,
          password: password,
        )).thenThrow(const AuthException('Invalid credentials'));

        // Act & Assert
        expect(
          () => authRepository.signInWithMobile(
            mobile: mobile,
            password: password,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signUpWithMobile', () {
      test('should sign up successfully with valid mobile number', () async {
        // Arrange
        const mobile = '9876543210';
        const password = 'password123';
        const name = 'John Doe';
        final email = PhoneUtils.mobileToEmail(mobile);
        final displayMobile = PhoneUtils.formatMobileForDisplay(mobile);

        when(mockGoTrueClient.signUp(
          email: email,
          password: password,
          data: {'name': name, 'mobile': mobile, 'display_mobile': displayMobile},
        )).thenAnswer((_) async => mockAuthResponse);

        when(mockAuthResponse.user).thenReturn(mockUser);
        when(mockAuthResponse.session).thenReturn(mockSession);

        // Act
        final result = await authRepository.signUpWithMobile(
          mobile: mobile,
          password: password,
          name: name,
        );

        // Assert
        expect(result.user, equals(mockUser));
        expect(result.session, equals(mockSession));
        verify(mockGoTrueClient.signUp(
          email: email,
          password: password,
          data: {'name': name, 'mobile': mobile, 'display_mobile': displayMobile},
        )).called(1);
      });

      test('should throw exception when sign up fails', () async {
        // Arrange
        const mobile = '9876543210';
        const password = 'weak';
        const name = 'John Doe';
        final email = PhoneUtils.mobileToEmail(mobile);
        final displayMobile = PhoneUtils.formatMobileForDisplay(mobile);

        when(mockGoTrueClient.signUp(
          email: email,
          password: password,
          data: {'name': name, 'mobile': mobile, 'display_mobile': displayMobile},
        )).thenThrow(const AuthException('Password too weak'));

        // Act & Assert
        expect(
          () => authRepository.signUpWithMobile(
            mobile: mobile,
            password: password,
            name: name,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('resetPasswordWithMobile', () {
      test('should send reset password email successfully', () async {
        // Arrange
        const mobile = '9876543210';
        const url = 'http://example.com';
        final email = PhoneUtils.mobileToEmail(mobile);

        when(mockGoTrueClient.resetPasswordForEmail(
          email,
          redirectTo: url,
        )).thenAnswer((_) async => {});

        // Act
        await authRepository.resetPasswordWithMobile(
          mobile: mobile,
          url: url,
        );

        // Assert
        verify(mockGoTrueClient.resetPasswordForEmail(
          email,
          redirectTo: url,
        )).called(1);
      });

      test('should throw exception when reset password fails', () async {
        // Arrange
        const mobile = '9876543210';
        const url = 'http://example.com';
        final email = PhoneUtils.mobileToEmail(mobile);

        when(mockGoTrueClient.resetPasswordForEmail(
          email,
          redirectTo: url,
        )).thenThrow(const AuthException('User not found'));

        // Act & Assert
        expect(
          () => authRepository.resetPasswordWithMobile(
            mobile: mobile,
            url: url,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        // Arrange
        when(mockGoTrueClient.signOut()).thenAnswer((_) async => {});

        // Act
        await authRepository.signOut();

        // Assert
        verify(mockGoTrueClient.signOut()).called(1);
      });

      test('should throw exception when sign out fails', () async {
        // Arrange
        when(mockGoTrueClient.signOut())
            .thenThrow(const AuthException('Sign out failed'));

        // Act & Assert
        expect(
          () => authRepository.signOut(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return current user when authenticated', () {
        // Arrange
        when(mockGoTrueClient.currentUser).thenReturn(mockUser);

        // Act
        final result = authRepository.currentUser;

        // Assert
        expect(result, equals(mockUser));
      });

      test('should return null when not authenticated', () {
        // Arrange
        when(mockGoTrueClient.currentUser).thenReturn(null);

        // Act
        final result = authRepository.currentUser;

        // Assert
        expect(result, isNull);
      });
    });

    group('getCurrentSession', () {
      test('should return current session when authenticated', () async {
        // Arrange
        when(mockGoTrueClient.currentSession).thenReturn(mockSession);

        // Act
        final result = authRepository.getCurrentSession();

        // Assert
        expect(result, equals(mockSession));
      });

      test('should return null when not authenticated', () async {
        // Arrange
        when(mockGoTrueClient.currentSession).thenReturn(null);

        // Act
        final result = authRepository.getCurrentSession();

        // Assert
        expect(result, isNull);
      });
    });

    group('authStateChanges', () {
      test('should return auth state changes stream', () {
        // Arrange
        final authStateStream = Stream<AuthState>.empty();
        when(mockGoTrueClient.onAuthStateChange).thenReturn(authStateStream);

        // Act
        final result = authRepository.authStateChanges;

        // Assert
        expect(result, equals(authStateStream));
      });
    });

    group('Edge Cases', () {
      test('should handle empty mobile number', () async {
        // Arrange
        const mobile = '';
        const password = 'password123';
        final email = PhoneUtils.mobileToEmail(mobile);

        when(mockGoTrueClient.signInWithPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockAuthResponse);

        // Act
        final result = await authRepository.signInWithMobile(
          mobile: mobile, 
          password: password,
        );

        // Assert
        expect(result, equals(mockAuthResponse));
        verify(mockGoTrueClient.signInWithPassword(
          email: '@phone.local', // Empty mobile converts to @phone.local
          password: password,
        )).called(1);
      });

      test('should handle mobile number with special characters', () async {
        // Arrange
        const mobile = '+91-98765-43210';
        const password = 'password123';
        final email = PhoneUtils.mobileToEmail(mobile);

        when(mockGoTrueClient.signInWithPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockAuthResponse);

        // Act
        final result = await authRepository.signInWithMobile(
          mobile: mobile, 
          password: password,
        );

        // Assert
        expect(result, equals(mockAuthResponse));
        verify(mockGoTrueClient.signInWithPassword(
          email: '919876543210@phone.local', // Digits extracted and converted
          password: password,
        )).called(1);
      });
    });
  });
}