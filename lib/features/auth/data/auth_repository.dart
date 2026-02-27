import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/config/environment.dart';
import '../../../core/services/network_diagnostics.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  /// Sign up with mobile number (converted to email format)
  /// Returns AuthResponse which may contain a session if email confirmation is disabled
  Future<AuthResponse> signUpWithMobile({
    required String name,
    required String mobile,
    required String password,
  }) async {
    if (!PhoneUtils.isValidMobile(mobile)) {
      throw Exception('Invalid mobile number format');
    }

    final email = PhoneUtils.mobileToEmail(mobile);
    final displayMobile = PhoneUtils.formatMobileForDisplay(mobile);

    debugPrint('🔐 Signup attempt: email=$email, mobile=$mobile');

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'mobile': mobile, 'display_mobile': displayMobile},
      );

      // Log response details for debugging
      debugPrint(
        '🔐 Signup response: user=${response.user?.id}, session=${response.session != null}, email=${response.user?.email}',
      );

      if (response.user == null) {
        debugPrint('❌ Signup failed: No user in response');
        throw Exception(
          'Failed to create user account. User is null in response.',
        );
      }

      // Treat missing session as an error so the UI surfaces the real issue
      if (response.session == null) {
        debugPrint(
          '⚠️ Signup: User created but no session (email confirmation likely enabled). User ID: ${response.user!.id}',
        );
        throw Exception(
          'Account created but no session returned.\n\n'
          'Root cause: Email confirmations are still enabled in Supabase for ${Environment.supabaseUrl}.\n\n'
          'Fix:\n'
          '1) Supabase Dashboard → Authentication → Settings\n'
          '2) Turn OFF "Enable email confirmations"\n'
          '3) Rebuild the app and try signing up again.\n\n'
          'Note: The user record exists but remains unconfirmed until email confirmations are disabled.',
        );
      }

      debugPrint(
        '✅ Signup: User created with session. User ID: ${response.user!.id}',
      );

      return response;
    } on AuthException catch (e) {
      debugPrint(
        '❌ Signup AuthException: status=${e.statusCode}, message=${e.message}',
      );
      throw _parseAuthError(e);
    } catch (e) {
      debugPrint('❌ Signup Exception: ${e.toString()}');
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign in with mobile number and password
  Future<AuthResponse> signInWithMobile({
    required String mobile,
    required String password,
  }) async {
    if (!PhoneUtils.isValidMobile(mobile)) {
      throw Exception('Invalid mobile number format');
    }

    final email = PhoneUtils.mobileToEmail(mobile);

    debugPrint('🔐 Login attempt: email=$email, mobile=$mobile');

    try {
      // PERFORMANCE OPTIMIZATION: Single fast attempt - no retries, no delays
      // Fail fast (8 seconds) if network is down
      final response = await _supabase.auth
          .signInWithPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 8), // Shorter timeout - fail fast
            onTimeout: () {
              debugPrint(
                '❌ Login: signInWithPassword timed out after 8 seconds',
              );
              throw TimeoutException(
                'Login request timed out. Please check your internet connection and try again.',
                const Duration(seconds: 8),
              );
            },
          );

      // Log response details for debugging
      debugPrint(
        '🔐 Login response: user=${response.user?.id}, session=${response.session != null}, email=${response.user?.email}',
      );

      if (response.user == null) {
        debugPrint('❌ Login failed: No user in response');
        throw Exception('Login failed: No user data returned');
      }

      if (response.session == null) {
        debugPrint('⚠️ Login: User exists but no session returned');
        throw Exception(
          'Login failed: No session returned. User may need email confirmation.',
        );
      }

      debugPrint(
        '✅ Login: User authenticated successfully. User ID: ${response.user!.id}',
      );

      // Check if user is active
      try {
        final profile =
            await _supabase
                .from('profiles')
                .select('is_active')
                .eq('id', response.user!.id)
                .maybeSingle();

        if (profile != null) {
          final isActive = profile['is_active'] as bool? ?? true;
          if (!isActive) {
            debugPrint('❌ Login blocked: User account is deactivated');
            await _supabase.auth.signOut();
            throw Exception(
              'Your account has been deactivated. Please contact support.',
            );
          }
        }
      } catch (e) {
        // If the error is the account deactivated exception, rethrow it
        if (e.toString().contains('deactivated')) {
          rethrow;
        }
        // Otherwise ignore profile fetch errors (e.g. if column doesn't exist yet)
        debugPrint('⚠️ Login: Could not check active status: $e');
      }

      return response;
    } on ConnectivityException catch (e) {
      debugPrint('❌ Login ConnectivityException: ${e.message}');
      throw Exception(
        'Cannot reach Supabase. Please check internet/VPN/firewall and try again.\n${e.message}',
      );
    } on SocketException catch (e) {
      debugPrint('❌ Login SocketException: ${e.message}');
      throw Exception(
        'Network error while reaching Supabase. Check connectivity or VPN and retry.',
      );
    } on http.ClientException catch (e) {
      debugPrint('❌ Login ClientException: ${e.message}');
      throw Exception(
        'Client error while contacting Supabase (possible TLS/DNS issue). Please retry after checking network.',
      );
    } on AuthException catch (e) {
      debugPrint(
        '❌ Login AuthException: status=${e.statusCode}, message=${e.message}',
      );
      throw _parseAuthError(e);
    } catch (e) {
      debugPrint('❌ Login Exception: ${e.toString()}');
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Legacy email-based sign up (for backward compatibility)
  /// Returns AuthResponse which may contain a session if email confirmation is disabled
  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        throw Exception('Failed to create user account');
      }

      return response;
    } on AuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  /// Legacy email-based sign in (for backward compatibility)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 Login attempt: email=$email');

    try {
      // PERFORMANCE OPTIMIZATION: Single fast attempt - no retries, no delays
      // Fail fast (8 seconds) if network is down
      final response = await _supabase.auth
          .signInWithPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 8), // Shorter timeout - fail fast
            onTimeout: () {
              debugPrint(
                '❌ Login: signInWithPassword timed out after 8 seconds',
              );
              throw TimeoutException(
                'Login request timed out. Please check your internet connection and try again.',
                const Duration(seconds: 8),
              );
            },
          );

      // Log response details for debugging
      debugPrint(
        '🔐 Login response: user=${response.user?.id}, session=${response.session != null}',
      );

      if (response.user == null) {
        debugPrint('❌ Login failed: No user in response');
        throw Exception('Login failed: No user data returned');
      }

      if (response.session == null) {
        debugPrint('⚠️ Login: User exists but no session returned');
        throw Exception(
          'Login failed: No session returned. User may need email confirmation.',
        );
      }

      debugPrint(
        '✅ Login: User authenticated successfully. User ID: ${response.user!.id}',
      );

      // Check if user is active
      try {
        final profile =
            await _supabase
                .from('profiles')
                .select('is_active')
                .eq('id', response.user!.id)
                .maybeSingle();

        if (profile != null) {
          final isActive = profile['is_active'] as bool? ?? true;
          if (!isActive) {
            debugPrint('❌ Login blocked: User account is deactivated');
            await _supabase.auth.signOut();
            throw Exception(
              'Your account has been deactivated. Please contact support.',
            );
          }
        }
      } catch (e) {
        if (e.toString().contains('deactivated')) {
          rethrow;
        }
        debugPrint('⚠️ Login: Could not check active status: $e');
      }

      return response;
    } on TimeoutException catch (e) {
      debugPrint('❌ Login TimeoutException: ${e.message}');
      throw Exception(
        'Login request timed out. Your internet connection may be slow or unstable.\n\n'
        'Please try:\n'
        '• Check your internet connection\n'
        '• Move to an area with better signal\n'
        '• Disable VPN if active\n'
        '• Try again in a few moments',
      );
    } on ConnectivityException catch (e) {
      debugPrint('❌ Login ConnectivityException: ${e.message}');
      throw Exception(
        'Cannot reach Supabase. Please check internet/VPN/firewall and try again.\n${e.message}',
      );
    } on SocketException catch (e) {
      debugPrint('❌ Login SocketException: ${e.message}');
      throw Exception(
        'Network error while reaching Supabase. Check connectivity or VPN and retry.',
      );
    } on http.ClientException catch (e) {
      debugPrint('❌ Login ClientException: ${e.message}');
      throw Exception(
        'Client error while contacting Supabase (possible TLS/DNS issue). Please retry after checking network.',
      );
    } on AuthException catch (e) {
      debugPrint(
        '❌ Login AuthException: status=${e.statusCode}, message=${e.message}',
      );
      throw _parseAuthError(e);
    } catch (e) {
      debugPrint('❌ Login Exception: ${e.toString()}');
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Reset password using mobile number
  Future<void> resetPasswordWithMobile({
    required String mobile,
    required String url,
  }) async {
    if (!PhoneUtils.isValidMobile(mobile)) {
      throw Exception('Invalid mobile number format');
    }

    final email = PhoneUtils.mobileToEmail(mobile);

    try {
      await _supabase.auth.resetPasswordForEmail(email, redirectTo: url);
    } on AuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Reset password using email
  Future<void> resetPassword({
    required String email,
    required String url,
  }) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email, redirectTo: url);
    } on AuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Confirm password recovery (update password with recovery token)
  /// For Supabase: The secret parameter should be the token from the reset link
  /// The token is verified via verifyOTP, which creates a recovery session
  /// Then we can update the password
  Future<void> confirmRecovery({
    required String userId,
    required String secret,
    required String newPassword,
  }) async {
    try {
      // Check if we already have a recovery session
      final currentSession = _supabase.auth.currentSession;

      // If no session, we need to verify the OTP token first
      if (currentSession == null) {
        // The secret is the token from the reset link
        // We need the email to verify OTP, but we can try to get it from the token
        // For now, we'll use verifyOTP which will create a session if valid
        // Note: verifyOTP requires email, but for recovery we might not have it
        // Alternative: Use exchangeCodeForSession if we have the full URL

        // Try to verify OTP - this will create a session if the token is valid
        // The email should be extracted from the reset link or we need to pass it
        // For now, we'll attempt verification which Supabase handles internally
        throw Exception(
          'Please use the password reset link from your email to set a new password.',
        );
      }

      // If we have a session (from verifyOTP or from the reset link), update password
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw Exception('Password recovery failed: ${e.toString()}');
    }
  }

  /// Verify recovery token and create session (called when user clicks reset link)
  /// This should be called when the app receives the password reset deep link
  Future<void> verifyRecoveryToken({
    required String token,
    String? email,
  }) async {
    try {
      if (email != null) {
        await _supabase.auth.verifyOTP(
          type: OtpType.recovery,
          token: token,
          email: email,
        );
      } else {
        // If email is not provided, Supabase might still work with just the token
        // depending on how the reset link is structured
        throw Exception('Email is required for password recovery');
      }
    } on AuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      throw Exception('Token verification failed: ${e.toString()}');
    }
  }

  /// Update password for current user
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First verify current password by attempting to sign in
      final currentUser = _supabase.auth.currentUser;
      if (currentUser?.email == null) {
        throw Exception('No user logged in');
      }

      // Verify current password
      await _supabase.auth.signInWithPassword(
        email: currentUser!.email!,
        password: currentPassword,
      );

      // Update to new password
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('Current password is incorrect');
      }
      throw _parseAuthError(e);
    } catch (e) {
      throw Exception('Password update failed: ${e.toString()}');
    }
  }

  /// Get current session
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Even if signOut fails, we should clear local state
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Delete the current user's account permanently
  /// This will delete the profile and all related data via cascade constraints
  /// After deletion, the user will be signed out automatically
  Future<void> deleteAccount() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Call database function to delete user data (profile and all related data)
      await _supabase.rpc('delete_user_account');

      // Sign out after deletion
      await _supabase.auth.signOut();
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete account: ${e.message}');
    } catch (e) {
      throw Exception('Account deletion failed: ${e.toString()}');
    }
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Refresh current user data to get latest metadata
  Future<User?> refreshUser() async {
    try {
      final response = await _supabase.auth.getUser();
      return response.user;
    } catch (e) {
      return null;
    }
  }

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Parse Supabase auth errors to user-friendly messages
  String _parseAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    final status = e.statusCode?.toString() ?? '';
    final errorCode = e.statusCode;

    // Log detailed error for debugging
    debugPrint(
      '🔐 Auth Error: status=$status, message=${e.message}, code=$errorCode',
    );

    // Handle 401 Unauthorized errors with specific checks
    if (status == '401' || errorCode == 401) {
      // Check for Invalid API key error (critical issue)
      if (message.contains('invalid api key') ||
          message.contains('invalid_api_key') ||
          message.contains('api key') ||
          message.contains('apikey')) {
        return 'Invalid API Key (401).\n\n'
            'The Supabase anon key in your app configuration is incorrect or expired.\n\n'
            'To fix:\n'
            '1. Go to Supabase Dashboard → Settings → API\n'
            '2. Copy the "anon/public" key\n'
            '3. Update lib/core/config/environment.dart\n'
            '4. Replace the supabaseAnonKey value\n'
            '5. Restart your app\n\n'
            'Current project: ${Environment.supabaseUrl}';
      }

      // Check for email confirmation required (common for signup)
      if (message.contains('email not confirmed') ||
          message.contains('email_not_confirmed') ||
          message.contains('email_not_verified') ||
          message.contains('unconfirmed') ||
          message.contains('signup') ||
          message.contains('sign up')) {
        return 'Signup failed (401). Email confirmation is enabled in Supabase.\n\n'
            'To fix this:\n'
            '1. Go to Supabase Dashboard → Authentication → Settings\n'
            '2. Disable "Enable email confirmations"\n'
            '3. Save and try signing up again\n\n'
            'Note: Phone-based emails cannot receive confirmation emails, so email confirmation must be disabled.';
      }

      // Check for invalid credentials (most common 401 case for login)
      if (message.contains('invalid login credentials') ||
          message.contains('invalid credentials') ||
          message.contains('invalid_grant') ||
          message.contains('incorrect email or password')) {
        return 'Invalid email or password. Please check your credentials and try again.';
      }

      // Check for user already exists (signup)
      if (message.contains('already registered') ||
          message.contains('already exists') ||
          message.contains('user_already_exists')) {
        return 'An account with this phone number already exists. Please sign in instead.';
      }

      // Generic 401 error with helpful message
      return 'Authentication failed (401). This may be due to:\n'
          '• Invalid API key (check environment.dart)\n'
          '• Email confirmation enabled (disable in Supabase settings)\n'
          '• Account already exists (try signing in)\n'
          '• Incorrect credentials\n'
          '• Supabase configuration issue\n\n'
          'Check the error message above for specific guidance.';
    }

    // Handle 404 Not Found (user doesn't exist)
    if (status == '404' || errorCode == 404) {
      if (message.contains('user not found') ||
          message.contains('user_not_found') ||
          message.contains('no user found')) {
        return 'No account found with this email. Please sign up first.';
      }
    }

    // Handle email already registered
    if (message.contains('email already registered') ||
        message.contains('user already registered') ||
        message.contains('user_already_exists') ||
        message.contains('email_address_already_registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    // Handle password-related errors
    if (message.contains('password')) {
      if (message.contains('weak') || message.contains('too short')) {
        return 'Password is too weak. Please use at least 6 characters';
      }
      if (message.contains('incorrect') || message.contains('wrong')) {
        return 'Incorrect password. Please try again.';
      }
      return 'Password error: ${e.message}';
    }

    // Handle email format errors
    if (message.contains('email')) {
      if (message.contains('invalid') ||
          message.contains('format') ||
          message.contains('malformed')) {
        return 'Invalid email format. Please enter a valid email address.';
      }
      return 'Email error: ${e.message}';
    }

    // Handle network/connection errors
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('failed host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // Handle rate limiting
    if (message.contains('rate limit') ||
        message.contains('too many requests') ||
        status == '429') {
      return 'Too many login attempts. Please wait a few minutes and try again.';
    }

    // Handle server errors
    if (status == '500' ||
        errorCode == 500 ||
        message.contains('server error')) {
      return 'Server error. Please try again later. If the problem persists, contact support.';
    }

    // Return original message if we can't parse it, but add helpful context
    return 'Authentication error: ${e.message}\n\n'
        'If this persists, check:\n'
        '• Your internet connection\n'
        '• Supabase Auth settings (email confirmation)\n'
        '• Your credentials are correct';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});
