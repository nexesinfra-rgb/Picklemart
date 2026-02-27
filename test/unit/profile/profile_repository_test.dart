import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picklemart/features/profile/data/profile_repository.dart';
import 'package:picklemart/features/profile/domain/profile.dart';
import 'profile_repository_test.mocks.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
// ignore: must_be_immutable
class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final Future<T> _future;

  FakePostgrestTransformBuilder(this._future);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    return FakePostgrestTransformBuilder(
      _future.then((value) {
        if (value is List) {
          if (value.isEmpty) {
            throw const PostgrestException(
              message: 'No rows found',
              code: 'PGRST116',
            );
          }
          return value.first as Map<String, dynamic>;
        }
        return value as Map<String, dynamic>;
      }),
    );
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder(
      _future.then((value) {
        if (value is List) {
          if (value.isEmpty) {
            return null;
          }
          return value.first as Map<String, dynamic>;
        }
        return value as Map<String, dynamic>?;
      }),
    );
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return _future.catchError(onError, test: test);
  }
}

class FakePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final Future<T> _future;

  FakePostgrestFilterBuilder(this._future);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return _future.catchError(onError, test: test);
  }
}

void main() {
  group('ProfileRepository Tests', () {
    late ProfileRepository profileRepository;
    late MockSupabaseClient mockSupabaseClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late dynamic mockFilterBuilder;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      profileRepository = ProfileRepository(mockSupabaseClient);
    });

    group('getProfile', () {
      test('should return profile when found', () async {
        // Arrange
        const profileId = 'test-profile-id';
        final profileData = {
          'id': profileId,
          'user_id': 'test-user-id',
          'name': 'John Doe',
          'mobile': '9876543210',
          'display_mobile': '+91 98765 43210',
          'role': 'customer',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.maybeSingle(),
        ).thenReturn(FakePostgrestTransformBuilder(Future.value(profileData)));
        // Note: getProfile implementation uses maybeSingle() in the file I read?
        // Let me check line 86 of profile_repository.dart.
        // It says .maybeSingle().
        // But the previous test setup used .single().
        // I will use maybeSingle() in test setup to match implementation.
      });

      // Wait, let's double check getProfile implementation I read earlier.
      // Line 86: .maybeSingle();
      // Line 136 (createProfile): .single();
      // Line 188 (updateProfile): .single();
      // Line 215 (profileExists): .maybeSingle();
      // Line 231 (getProfileByMobile): .maybeSingle();

      // So getProfile uses maybeSingle.
      test('should return profile when found', () async {
        // Arrange
        const profileId = 'test-profile-id';
        final profileData = {
          'id': profileId,
          'user_id': 'test-user-id',
          'name': 'John Doe',
          'mobile': '9876543210',
          'display_mobile': '+91 98765 43210',
          'role': 'customer',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        // getProfile uses maybeSingle
        when(
          mockFilterBuilder.maybeSingle(),
        ).thenReturn(FakePostgrestTransformBuilder(Future.value(profileData)));

        // Act
        final result = await profileRepository.getProfile(profileId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(profileId));
        expect(result.name, equals('John Doe'));
        expect(result.mobile, equals('9876543210'));
        expect(result.role, equals('customer'));
      });

      test('should return null when profile not found', () async {
        // Arrange
        const profileId = 'non-existent-id';

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        // maybeSingle returns null if not found
        when(
          mockFilterBuilder.maybeSingle(),
        ).thenReturn(FakePostgrestTransformBuilder(Future.value(null)));

        // Act
        final result = await profileRepository.getProfile(profileId);

        // Assert
        expect(result, isNull);
      });

      test('should throw exception for other database errors', () async {
        // Arrange
        const profileId = 'test-profile-id';

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.maybeSingle()).thenReturn(
          FakePostgrestTransformBuilder(
            Future.error(
              const PostgrestException(
                message: 'Database connection failed',
                code: 'CONNECTION_ERROR',
              ),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => profileRepository.getProfile(profileId),
          throwsA(
            isA<Exception>(),
          ), // The repo wraps it in Exception('Failed to get profile: ...')
        );
      });
    });

    // getProfileByUserId is redundant as it is same as getProfile(userId)

    group('getProfileByMobile', () {
      test('should return profile when found by mobile', () async {
        // Arrange
        const mobile = '9876543210';
        final profileData = {
          'id': 'test-profile-id',
          'user_id': 'test-user-id',
          'name': 'John Doe',
          'mobile': mobile,
          'display_mobile': '+91 98765 43210',
          'role': 'customer',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('mobile', mobile),
        ).thenReturn(mockFilterBuilder);
        // getProfileByMobile uses maybeSingle
        when(
          mockFilterBuilder.maybeSingle(),
        ).thenReturn(FakePostgrestTransformBuilder(Future.value(profileData)));

        // Act
        final result = await profileRepository.getProfileByMobile(mobile);

        // Assert
        expect(result, isNotNull);
        expect(result!.mobile, equals(mobile));
        expect(result.name, equals('John Doe'));
      });

      test('should return null when profile not found by mobile', () async {
        // Arrange
        const mobile = '0000000000';

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('mobile', mobile),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.maybeSingle(),
        ).thenReturn(FakePostgrestTransformBuilder(Future.value(null)));

        // Act
        final result = await profileRepository.getProfileByMobile(mobile);

        // Assert
        expect(result, isNull);
      });
    });

    group('createProfile', () {
      test('should create profile successfully', () async {
        // Arrange
        final profile = Profile(
          id: 'test-profile-id',
          name: 'John Doe',
          mobile: '9876543210',
          displayMobile: '+91 98765 43210',
          role: 'customer',
          createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
          updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
        );

        // createProfile constructs data map internally.
        // We verify the insert call arguments.

        final returnedProfileData = profile.toJson();

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(
          mockQueryBuilder.insert(
            any,
          ), // Use any to avoid strict map matching issues
        ).thenReturn(mockFilterBuilder);
        // createProfile uses select().single()
        when(mockFilterBuilder.select()).thenReturn(
          FakePostgrestTransformBuilder(Future.value([returnedProfileData])),
        );

        // Act
        final result = await profileRepository.createProfile(
          userId: profile.id,
          name: profile.name,
          mobile: profile.mobile,
          role: profile.role,
        );

        // Assert
        expect(result.id, equals(profile.id));
        expect(result.name, equals(profile.name));
        verify(mockQueryBuilder.insert(any)).called(1);
      });

      test('should throw exception when create fails', () async {
        // Arrange
        final profile = Profile(
          id: 'test-profile-id',
          name: 'John Doe',
          role: 'customer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);

        when(mockFilterBuilder.select()).thenReturn(
          FakePostgrestTransformBuilder(
            Future.error(
              const PostgrestException(
                message: 'Duplicate key violation',
                code: '23505',
              ),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => profileRepository.createProfile(
            userId: profile.id,
            name: profile.name,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateProfile', () {
      test('should update profile successfully', () async {
        // Arrange
        const profileId = 'test-profile-id';

        final updatedProfileData = {
          'id': profileId,
          'user_id': 'test-user-id',
          'name': 'Jane Doe',
          'mobile': '9876543210',
          'display_mobile': '+91 98765 43210',
          'role': 'admin',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-02T00:00:00Z',
        };

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        // updateProfile uses select().single()
        when(mockFilterBuilder.select()).thenReturn(
          FakePostgrestTransformBuilder(Future.value([updatedProfileData])),
        );

        // Act
        final result = await profileRepository.updateProfile(
          userId: profileId,
          name: 'Jane Doe',
        );

        // Assert
        expect(result.id, equals(profileId));
        expect(result.name, equals('Jane Doe'));
        verify(mockQueryBuilder.update(any)).called(1);
      });

      test('should throw exception when update fails', () async {
        // Arrange
        const profileId = 'non-existent-id';

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        // Return empty list to simulate not found via single() -> exception
        when(
          mockFilterBuilder.select(),
        ).thenReturn(FakePostgrestTransformBuilder(Future.value([])));

        // Act & Assert
        expect(
          () => profileRepository.updateProfile(
            userId: profileId,
            name: 'Jane Doe',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteProfile', () {
      test('should delete profile successfully', () async {
        // Arrange
        const profileId = 'test-profile-id';

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(FakePostgrestFilterBuilder(Future.value(null)));

        // Act
        await profileRepository.deleteProfile(profileId);

        // Assert
        verify(mockQueryBuilder.delete()).called(1);
        verify(mockFilterBuilder.eq('id', profileId)).called(1);
      });

      test('should throw exception when delete fails', () async {
        // Arrange
        const profileId = 'test-profile-id';

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', profileId)).thenReturn(
          FakePostgrestFilterBuilder(Future.error(Exception('Delete failed'))),
        );

        // Act & Assert
        expect(
          () => profileRepository.deleteProfile(profileId),
          throwsA(isA<Exception>()),
        );
      });
    });
    group('profileExists', () {
      test('should return true when profile exists', () async {
        // Arrange
        const profileId = 'test-profile-id';

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('id')).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        // profileExists uses maybeSingle()
        when(mockFilterBuilder.maybeSingle()).thenReturn(
          FakePostgrestTransformBuilder(Future.value({'id': profileId})),
        );

        // Act
        final result = await profileRepository.profileExists(profileId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when profile does not exist', () async {
        // Arrange
        const profileId = 'non-existent-id';

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('id')).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.maybeSingle(),
        ).thenReturn(FakePostgrestTransformBuilder(Future.value(null)));

        // Act
        final result = await profileRepository.profileExists(profileId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle null values in profile data', () async {
        // Arrange
        const profileId = 'test-profile-id';
        final profileData = {
          'id': profileId,
          'user_id': 'test-user-id',
          'name': null,
          'mobile': '9876543210',
          'display_mobile': '+91 98765 43210',
          'role': 'customer',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.maybeSingle(),
        ).thenReturn(FakePostgrestTransformBuilder(Future.value(profileData)));

        // Act
        final result = await profileRepository.getProfile(profileId);

        // Assert
        expect(result, isNotNull);
        expect(result!.name, isEmpty); // Should handle null as empty string
      });

      test('should handle invalid role values', () async {
        // Arrange
        const profileId = 'test-profile-id';
        final profileData = {
          'id': profileId,
          'user_id': 'test-user-id',
          'name': 'John Doe',
          'mobile': '9876543210',
          'display_mobile': '+91 98765 43210',
          'role': 'invalid_role',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        when(mockSupabaseClient.from('profiles')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', profileId),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.maybeSingle(),
        ).thenReturn(FakePostgrestTransformBuilder(Future.value(profileData)));

        // Act
        final result = await profileRepository.getProfile(profileId);

        // Assert
        expect(result, isNotNull);
        expect(result!.role, equals('customer')); // Should default to customer
      });
    });
  });
}
