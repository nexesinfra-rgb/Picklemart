/// Password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Password requirements validation result
class PasswordRequirements {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;

  const PasswordRequirements({
    this.hasMinLength = false,
    this.hasUppercase = false,
    this.hasLowercase = false,
    this.hasNumber = false,
    this.hasSpecialChar = false,
  });

  bool get allMet =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasNumber &&
      hasSpecialChar;

  int get metCount =>
      [hasMinLength, hasUppercase, hasLowercase, hasNumber, hasSpecialChar]
          .where((met) => met)
          .length;
}

/// Password utility functions
class PasswordUtils {
  /// Calculate password strength based on requirements
  static PasswordStrength calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    final requirements = checkRequirements(password);
    final metCount = requirements.metCount;

    if (metCount < 3) {
      return PasswordStrength.weak;
    } else if (metCount < 5) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.strong;
    }
  }

  /// Check password requirements
  static PasswordRequirements checkRequirements(String password) {
    return PasswordRequirements(
      hasMinLength: password.length >= 8,
      hasUppercase: password.contains(RegExp(r'[A-Z]')),
      hasLowercase: password.contains(RegExp(r'[a-z]')),
      hasNumber: password.contains(RegExp(r'[0-9]')),
      hasSpecialChar: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    );
  }

  /// Get strength color
  static int getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0xFFFF5252; // Red
      case PasswordStrength.medium:
        return 0xFFFFB74D; // Orange
      case PasswordStrength.strong:
        return 0xFF4CAF50; // Green
    }
  }

  /// Get strength label
  static String getStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}






