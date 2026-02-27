import 'package:flutter_test/flutter_test.dart';
import 'package:picklemart/core/utils/phone_utils.dart';

void main() {
  group('PhoneUtils Tests', () {
    group('mobileToEmail', () {
      test('should convert 10-digit mobile to email format', () {
        expect(
          PhoneUtils.mobileToEmail('9876543210'),
          equals('919876543210@phone.local'),
        );
        expect(
          PhoneUtils.mobileToEmail('8765432109'),
          equals('918765432109@phone.local'),
        );
        expect(
          PhoneUtils.mobileToEmail('7654321098'),
          equals('917654321098@phone.local'),
        );
      });

      test('should handle mobile numbers with spaces', () {
        expect(
          PhoneUtils.mobileToEmail('98765 43210'),
          equals('919876543210@phone.local'),
        );
        expect(
          PhoneUtils.mobileToEmail('9876 543 210'),
          equals('919876543210@phone.local'),
        );
      });

      test('should handle mobile numbers with dashes', () {
        expect(
          PhoneUtils.mobileToEmail('98765-43210'),
          equals('919876543210@phone.local'),
        );
        expect(
          PhoneUtils.mobileToEmail('9876-543-210'),
          equals('919876543210@phone.local'),
        );
      });

      test('should handle mobile numbers with mixed separators', () {
        expect(
          PhoneUtils.mobileToEmail('9876 543-210'),
          equals('919876543210@phone.local'),
        );
        expect(
          PhoneUtils.mobileToEmail('98765-432 10'),
          equals('919876543210@phone.local'),
        );
      });

      test('should handle mobile numbers already with country code', () {
        expect(
          PhoneUtils.mobileToEmail('919876543210'),
          equals('919876543210@phone.local'),
        );
        expect(
          PhoneUtils.mobileToEmail('+91 9876543210'),
          equals('919876543210@phone.local'),
        );
      });

      test('should handle 10-digit numbers starting with 91 correctly', () {
        expect(
          PhoneUtils.mobileToEmail('9123456789'),
          equals('919123456789@phone.local'),
        );
      });

      test('should handle empty input', () {
        expect(PhoneUtils.mobileToEmail(''), equals('91@phone.local'));
      });
    });

    group('emailToMobile', () {
      test('should extract mobile from email format', () {
        expect(
          PhoneUtils.emailToMobile('919876543210@phone.local'),
          equals('9876543210'),
        );
        expect(
          PhoneUtils.emailToMobile('919123456789@phone.local'),
          equals('9123456789'),
        );
        expect(
          PhoneUtils.emailToMobile('918765432109@phone.local'),
          equals('8765432109'),
        );
      });

      test('should handle mobile without country code in email', () {
        expect(
          PhoneUtils.emailToMobile('9876543210@phone.local'),
          equals('9876543210'),
        );
      });

      test('should throw error for invalid email format', () {
        expect(
          () => PhoneUtils.emailToMobile('invalid@gmail.com'),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => PhoneUtils.emailToMobile('9876543210@wrong.domain'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('isValidMobile', () {
      test('should validate correct 10-digit mobile numbers', () {
        expect(PhoneUtils.isValidMobile('9876543210'), isTrue);
        expect(PhoneUtils.isValidMobile('8765432109'), isTrue);
        expect(PhoneUtils.isValidMobile('7654321098'), isTrue);
        expect(PhoneUtils.isValidMobile('6123456789'), isTrue);
      });

      test('should validate mobile numbers with country code', () {
        expect(PhoneUtils.isValidMobile('919876543210'), isTrue);
        expect(PhoneUtils.isValidMobile('918765432109'), isTrue);
      });

      test('should reject mobile numbers with invalid starting digits', () {
        expect(PhoneUtils.isValidMobile('0123456789'), isFalse);
        expect(PhoneUtils.isValidMobile('1123456789'), isFalse);
        expect(PhoneUtils.isValidMobile('2123456789'), isFalse);
        expect(PhoneUtils.isValidMobile('3123456789'), isFalse);
        expect(PhoneUtils.isValidMobile('4123456789'), isFalse);
        expect(PhoneUtils.isValidMobile('5123456789'), isFalse);
      });

      test('should reject invalid lengths', () {
        expect(PhoneUtils.isValidMobile('123456789'), isFalse); // 9 digits
        expect(PhoneUtils.isValidMobile('12345678901'), isFalse); // 11 digits
        expect(PhoneUtils.isValidMobile(''), isFalse);
      });

      test('should handle mobile numbers with separators', () {
        expect(PhoneUtils.isValidMobile('98765 43210'), isTrue);
        expect(PhoneUtils.isValidMobile('9876-543-210'), isTrue);
        expect(PhoneUtils.isValidMobile('(9876) 543-210'), isTrue);
      });
    });

    group('formatMobileForDisplay', () {
      test('should format 10-digit mobile number correctly', () {
        expect(
          PhoneUtils.formatMobileForDisplay('9876543210'),
          equals('+91 98765 43210'),
        );
        expect(
          PhoneUtils.formatMobileForDisplay('8765432109'),
          equals('+91 87654 32109'),
        );
        expect(
          PhoneUtils.formatMobileForDisplay('7654321098'),
          equals('+91 76543 21098'),
        );
      });

      test('should format mobile numbers with country code', () {
        expect(
          PhoneUtils.formatMobileForDisplay('919876543210'),
          equals('+91 98765 43210'),
        );
        expect(
          PhoneUtils.formatMobileForDisplay('918765432109'),
          equals('+91 87654 32109'),
        );
      });

      test('should handle mobile numbers with separators', () {
        expect(
          PhoneUtils.formatMobileForDisplay('98765 43210'),
          equals('+91 98765 43210'),
        );
        expect(
          PhoneUtils.formatMobileForDisplay('9876-543-210'),
          equals('+91 98765 43210'),
        );
      });

      test('should return original string for invalid lengths', () {
        expect(PhoneUtils.formatMobileForDisplay('123'), equals('123'));
        expect(
          PhoneUtils.formatMobileForDisplay('12345678901'),
          equals('12345678901'),
        );
        expect(PhoneUtils.formatMobileForDisplay(''), equals(''));
      });
    });

    group('isPhoneEmail', () {
      test('should identify phone-based emails correctly', () {
        expect(PhoneUtils.isPhoneEmail('919876543210@phone.local'), isTrue);
        expect(PhoneUtils.isPhoneEmail('9876543210@phone.local'), isTrue);
      });

      test('should reject non-phone emails', () {
        expect(PhoneUtils.isPhoneEmail('user@gmail.com'), isFalse);
        expect(PhoneUtils.isPhoneEmail('test@example.com'), isFalse);
        expect(PhoneUtils.isPhoneEmail('919876543210@wrong.domain'), isFalse);
      });

      test('should handle empty and invalid inputs', () {
        expect(PhoneUtils.isPhoneEmail(''), isFalse);
        expect(PhoneUtils.isPhoneEmail('invalid'), isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle very long mobile numbers', () {
        final longMobile = '9876543210${'1' * 100}';
        final result = PhoneUtils.mobileToEmail(longMobile);
        expect(result.startsWith('91987654321'), isTrue);
        expect(result.endsWith('@phone.local'), isTrue);
      });

      test('should handle special characters in mobile numbers', () {
        expect(
          PhoneUtils.mobileToEmail('+91-98765-43210'),
          equals('919876543210@phone.local'),
        );
        expect(
          PhoneUtils.mobileToEmail('(91) 98765 43210'),
          equals('919876543210@phone.local'),
        );
        expect(
          PhoneUtils.mobileToEmail('91.9876.543210'),
          equals('919876543210@phone.local'),
        );
      });

      test('should handle mobile numbers with letters', () {
        expect(
          PhoneUtils.mobileToEmail('abc9876def543ghi210'),
          equals('919876543210@phone.local'),
        );
      });
    });
  });
}
