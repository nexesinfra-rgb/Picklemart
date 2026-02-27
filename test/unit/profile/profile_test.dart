import 'package:flutter_test/flutter_test.dart';
import 'package:picklemart/features/profile/domain/profile.dart';

void main() {
  group('Profile Domain Model Tests', () {
    late Profile testProfile;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
      testProfile = Profile(
        id: 'test-user-id',
        name: 'John Doe',
        mobile: '9876543210',
        displayMobile: '+91 98765 43210',
        avatarUrl: 'https://example.com/avatar.jpg',
        role: 'user',
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    group('Profile Creation', () {
      test('should create profile with all fields', () {
        expect(testProfile.id, equals('test-user-id'));
        expect(testProfile.name, equals('John Doe'));
        expect(testProfile.mobile, equals('9876543210'));
        expect(testProfile.displayMobile, equals('+91 98765 43210'));
        expect(testProfile.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(testProfile.role, equals('user'));
        expect(testProfile.createdAt, equals(testDate));
        expect(testProfile.updatedAt, equals(testDate));
      });

      test('should create profile with minimal fields', () {
        final minimalProfile = Profile(
          id: 'minimal-id',
          name: 'Jane Doe',
          mobile: '9123456789',
          displayMobile: '+91 91234 56789',
          role: 'user',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(minimalProfile.id, equals('minimal-id'));
        expect(minimalProfile.name, equals('Jane Doe'));
        expect(minimalProfile.mobile, equals('9123456789'));
        expect(minimalProfile.displayMobile, equals('+91 91234 56789'));
        expect(minimalProfile.avatarUrl, isNull);
        expect(minimalProfile.role, equals('user'));
      });
    });

    group('Profile Extensions', () {
      test('isAdmin should return true for admin role', () {
        final adminProfile = testProfile.copyWith(role: 'admin');
        expect(adminProfile.isAdmin, isTrue);
        expect(testProfile.isAdmin, isFalse);
      });

      test('isUser should return true for user role', () {
        expect(testProfile.isUser, isTrue);

        final adminProfile = testProfile.copyWith(role: 'admin');
        expect(adminProfile.isUser, isFalse);
      });

      test('displayName should return name', () {
        expect(testProfile.displayName, equals('John Doe'));
      });

      test('formattedMobile should return displayMobile', () {
        expect(testProfile.formattedMobile, equals('+91 98765 43210'));
      });

      test(
        'formattedMobile should fallback to mobile if displayMobile is null',
        () {
          final profileWithoutDisplay = testProfile.copyWith(
            displayMobile: null,
          );
          expect(profileWithoutDisplay.formattedMobile, equals('9876543210'));
        },
      );
    });

    group('Profile Equality and Copying', () {
      test('should support equality comparison', () {
        final sameProfile = Profile(
          id: 'test-user-id',
          name: 'John Doe',
          mobile: '9876543210',
          displayMobile: '+91 98765 43210',
          avatarUrl: 'https://example.com/avatar.jpg',
          role: 'user',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(testProfile, equals(sameProfile));
      });

      test('should support copyWith for updates', () {
        final updatedProfile = testProfile.copyWith(
          name: 'John Smith',
          role: 'admin',
        );

        expect(updatedProfile.id, equals(testProfile.id));
        expect(updatedProfile.name, equals('John Smith'));
        expect(updatedProfile.mobile, equals(testProfile.mobile));
        expect(updatedProfile.role, equals('admin'));
        expect(updatedProfile.createdAt, equals(testProfile.createdAt));
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON', () {
        final json = testProfile.toJson();

        expect(json['id'], equals('test-user-id'));
        expect(json['name'], equals('John Doe'));
        expect(json['mobile'], equals('9876543210'));
        expect(json['display_mobile'], equals('+91 98765 43210'));
        expect(json['avatar_url'], equals('https://example.com/avatar.jpg'));
        expect(json['role'], equals('user'));
        expect(json['created_at'], equals(testDate.toIso8601String()));
        expect(json['updated_at'], equals(testDate.toIso8601String()));
      });

      test('should create from JSON', () {
        final json = {
          'id': 'json-user-id',
          'name': 'Jane Smith',
          'mobile': '9123456789',
          'display_mobile': '+91 91234 56789',
          'avatar_url': null,
          'role': 'admin',
          'created_at': testDate.toIso8601String(),
          'updated_at': testDate.toIso8601String(),
        };

        final profile = Profile.fromJson(json);

        expect(profile.id, equals('json-user-id'));
        expect(profile.name, equals('Jane Smith'));
        expect(profile.mobile, equals('9123456789'));
        expect(profile.displayMobile, equals('+91 91234 56789'));
        expect(profile.avatarUrl, isNull);
        expect(profile.role, equals('admin'));
        expect(profile.createdAt, equals(testDate));
        expect(profile.updatedAt, equals(testDate));
      });

      test('should handle JSON roundtrip', () {
        final json = testProfile.toJson();
        final recreatedProfile = Profile.fromJson(json);

        expect(recreatedProfile, equals(testProfile));
      });
    });
  });
}
