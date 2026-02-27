import '../../../core/config/environment.dart';

String mapPhoneToEmail(String rawMobileDigits) {
  // Keep digits only
  final digits = rawMobileDigits.replaceAll(RegExp(r'[^0-9]'), '');
  // Expect 10-digit local number; prefix with default country code
  final localNumber = digits.length == 10 ? digits : digits;
  if (localNumber.length != 10) {
    throw ArgumentError('Invalid mobile number');
  }
  final normalized = '${Environment.phoneDefaultCountryCode}$localNumber';
  return '$normalized@${Environment.phoneEmailDomain}';
}