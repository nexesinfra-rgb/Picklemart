import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';
import '../providers/supabase_provider.dart';

/// Diagnostic service for troubleshooting Supabase authentication issues
class SupabaseAuthDiagnostic {
  final SupabaseClient _supabase;

  SupabaseAuthDiagnostic(this._supabase);

  /// Run comprehensive diagnostic checks
  Future<DiagnosticResult> runDiagnostics() async {
    final results = <DiagnosticCheck>[];

    // Check 1: Supabase initialization
    results.add(await _checkInitialization());

    // Check 2: Configuration
    results.add(await _checkConfiguration());

    // Check 3: Current session
    results.add(await _checkCurrentSession());

    // Check 4: Network connectivity
    results.add(await _checkNetworkConnectivity());

    final allPassed = results.every((r) => r.status == DiagnosticStatus.pass);
    final hasWarnings = results.any((r) => r.status == DiagnosticStatus.warning);

    return DiagnosticResult(
      allChecksPassed: allPassed,
      hasWarnings: hasWarnings,
      checks: results,
    );
  }

  /// Check if Supabase is properly initialized
  Future<DiagnosticCheck> _checkInitialization() async {
    try {
      final instance = Supabase.instance;

      return DiagnosticCheck(
        name: 'Supabase Initialization',
        status: DiagnosticStatus.pass,
        message: 'Supabase is properly initialized',
      );
    } catch (e) {
      return DiagnosticCheck(
        name: 'Supabase Initialization',
        status: DiagnosticStatus.fail,
        message: 'Error checking initialization: $e',
        suggestion: 'Check Supabase initialization in main.dart',
      );
    }
  }

  /// Check configuration values
  Future<DiagnosticCheck> _checkConfiguration() async {
    try {
      final url = Environment.supabaseUrl;
      final anonKey = Environment.supabaseAnonKey;

      if (url.isEmpty || anonKey.isEmpty) {
        return DiagnosticCheck(
          name: 'Configuration',
          status: DiagnosticStatus.fail,
          message: 'Supabase URL or Anon Key is empty',
          suggestion: 'Check environment.dart configuration',
        );
      }

      if (!url.startsWith('https://')) {
        return DiagnosticCheck(
          name: 'Configuration',
          status: DiagnosticStatus.warning,
          message: 'Supabase URL should use HTTPS',
          suggestion: 'Verify URL format in environment.dart',
        );
      }

      return DiagnosticCheck(
        name: 'Configuration',
        status: DiagnosticStatus.pass,
        message: 'Configuration looks valid',
      );
    } catch (e) {
      return DiagnosticCheck(
        name: 'Configuration',
        status: DiagnosticStatus.fail,
        message: 'Error checking configuration: $e',
      );
    }
  }

  /// Check current authentication session
  Future<DiagnosticCheck> _checkCurrentSession() async {
    try {
      final session = _supabase.auth.currentSession;
      final user = _supabase.auth.currentUser;

      if (session == null && user == null) {
        return DiagnosticCheck(
          name: 'Current Session',
          status: DiagnosticStatus.pass,
          message: 'No active session (user not logged in)',
        );
      }

      if (session != null && user != null) {
        final isExpired = session.expiresAt != null &&
            DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
                .isBefore(DateTime.now());

        if (isExpired) {
          return DiagnosticCheck(
            name: 'Current Session',
            status: DiagnosticStatus.warning,
            message: 'Session expired',
            suggestion: 'User needs to sign in again',
          );
        }

        return DiagnosticCheck(
          name: 'Current Session',
          status: DiagnosticStatus.pass,
          message: 'Valid session exists for user: ${user.email ?? 'N/A'}',
        );
      }

      return DiagnosticCheck(
        name: 'Current Session',
        status: DiagnosticStatus.warning,
        message: 'Session state inconsistent',
        suggestion: 'Try signing out and signing in again',
      );
    } catch (e) {
      return DiagnosticCheck(
        name: 'Current Session',
        status: DiagnosticStatus.fail,
        message: 'Error checking session: $e',
      );
    }
  }

  /// Check network connectivity to Supabase
  Future<DiagnosticCheck> _checkNetworkConnectivity() async {
    try {
      // Try a simple query to check connectivity
      // Using a lightweight query that should work even without auth
      await _supabase.from('profiles').select('id').limit(1).maybeSingle();

      return DiagnosticCheck(
        name: 'Network Connectivity',
        status: DiagnosticStatus.pass,
        message: 'Successfully connected to Supabase',
      );
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('network') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout')) {
        return DiagnosticCheck(
          name: 'Network Connectivity',
          status: DiagnosticStatus.fail,
          message: 'Network error: $e',
          suggestion: 'Check your internet connection and Supabase project status',
        );
      }

      // Other errors (like RLS policies) are OK - means we can connect
      return DiagnosticCheck(
        name: 'Network Connectivity',
        status: DiagnosticStatus.pass,
        message: 'Network connection successful (query may require auth)',
      );
    }
  }

  /// Check if a user exists (for debugging)
  /// Note: This may fail due to RLS policies, which is expected
  Future<bool> checkUserExists(String email) async {
    try {
      // Try to query auth.users indirectly through profiles
      final response = await _supabase
          .from('profiles')
          .select('id, email')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Could not check user existence (may be due to RLS): $e');
      return false;
    }
  }

  /// Get diagnostic information as a formatted string
  Future<String> getDiagnosticReport() async {
    final result = await runDiagnostics();
    final buffer = StringBuffer();

    buffer.writeln('=== Supabase Auth Diagnostic Report ===\n');
    buffer.writeln('Overall Status: ${result.allChecksPassed ? "✅ PASS" : "❌ FAIL"}');
    if (result.hasWarnings) {
      buffer.writeln('⚠️  Warnings present\n');
    }
    buffer.writeln('--- Individual Checks ---\n');

    for (final check in result.checks) {
      final icon = check.status == DiagnosticStatus.pass
          ? '✅'
          : check.status == DiagnosticStatus.warning
              ? '⚠️'
              : '❌';
      buffer.writeln('$icon ${check.name}: ${check.message}');
      if (check.suggestion != null) {
        buffer.writeln('   💡 ${check.suggestion}');
      }
      buffer.writeln();
    }

    buffer.writeln('--- Configuration ---');
    buffer.writeln('URL: ${Environment.supabaseUrl}');
    buffer.writeln('Anon Key: ${Environment.supabaseAnonKey.substring(0, 20)}...');
    buffer.writeln();

    return buffer.toString();
  }
}

/// Result of diagnostic checks
class DiagnosticResult {
  final bool allChecksPassed;
  final bool hasWarnings;
  final List<DiagnosticCheck> checks;

  DiagnosticResult({
    required this.allChecksPassed,
    required this.hasWarnings,
    required this.checks,
  });
}

/// Individual diagnostic check result
class DiagnosticCheck {
  final String name;
  final DiagnosticStatus status;
  final String message;
  final String? suggestion;

  DiagnosticCheck({
    required this.name,
    required this.status,
    required this.message,
    this.suggestion,
  });
}

/// Status of a diagnostic check
enum DiagnosticStatus {
  pass,
  warning,
  fail,
}

/// Provider for diagnostic service
final supabaseAuthDiagnosticProvider = Provider<SupabaseAuthDiagnostic>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseAuthDiagnostic(supabase);
});

