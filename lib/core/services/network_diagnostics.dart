import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/environment.dart';

/// Lightweight connectivity checks to surface DNS/TLS issues before auth calls.
class NetworkDiagnostics {
  static Uri get _healthUri =>
      Uri.parse('${Environment.supabaseUrl}/auth/v1/health');

  /// Throws [ConnectivityException] when Supabase cannot be reached.
  static Future<void> ensureSupabaseReachable({
    Duration timeout = const Duration(seconds: 12),
    int maxRetries = 2,
  }) async {
    final supabaseUri = Uri.parse(Environment.supabaseUrl);
    final host = supabaseUri.host;

    // 1) DNS resolution with retry logic (skip on web - browsers handle DNS automatically)
    bool dnsResolved = false;
    if (!kIsWeb) {
      dnsResolved = await _resolveDnsWithRetry(host, timeout, maxRetries);
      // If DNS fails, log warning but continue to health check
      // The actual HTTP request might still work if DNS resolves later
      if (!dnsResolved && kDebugMode) {
        debugPrint('⚠️ NetworkDiagnostics: DNS resolution failed, but continuing to health check');
      }
    } else {
      dnsResolved = true; // Web handles DNS automatically
    }

    // 2) Health endpoint over HTTPS with retry logic
    await _checkHealthEndpointWithRetry(timeout, maxRetries, dnsResolved);
  }

  /// Resolve DNS with retry logic and exponential backoff
  static Future<bool> _resolveDnsWithRetry(
    String host,
    Duration timeout,
    int maxRetries,
  ) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode && attempt > 0) {
          debugPrint('🔄 NetworkDiagnostics: DNS retry attempt ${attempt + 1}/${maxRetries + 1}');
        }
        
        final addresses = await InternetAddress.lookup(host).timeout(timeout);
        if (addresses.isNotEmpty) {
          if (kDebugMode && attempt > 0) {
            debugPrint('✅ NetworkDiagnostics: DNS resolved on retry attempt ${attempt + 1}');
          }
          return true;
        }
      } on TimeoutException {
        if (attempt < maxRetries) {
          // Exponential backoff: 1s, 2s, 4s
          final delay = Duration(seconds: 1 << attempt);
          if (kDebugMode) {
            debugPrint('⏳ NetworkDiagnostics: DNS timeout, retrying in ${delay.inSeconds}s...');
          }
          await Future.delayed(delay);
          continue;
        }
        // Last attempt failed
        if (kDebugMode) {
          debugPrint('❌ NetworkDiagnostics: DNS resolution timed out after ${maxRetries + 1} attempts');
        }
        return false;
      } on SocketException catch (e) {
        if (attempt < maxRetries) {
          final delay = Duration(seconds: 1 << attempt);
          if (kDebugMode) {
            debugPrint('⏳ NetworkDiagnostics: DNS error (${e.message}), retrying in ${delay.inSeconds}s...');
          }
          await Future.delayed(delay);
          continue;
        }
        if (kDebugMode) {
          debugPrint('❌ NetworkDiagnostics: DNS resolution failed after ${maxRetries + 1} attempts: ${e.message}');
        }
        return false;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ NetworkDiagnostics: Unexpected DNS error: $e');
        }
        return false;
      }
    }
    return false;
  }

  /// Check health endpoint with retry logic
  static Future<void> _checkHealthEndpointWithRetry(
    Duration timeout,
    int maxRetries,
    bool dnsResolved,
  ) async {
    String? lastError;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode && attempt > 0) {
          debugPrint('🔄 NetworkDiagnostics: Health check retry attempt ${attempt + 1}/${maxRetries + 1}');
        }

        final response = await http.get(_healthUri).timeout(timeout);

        if (response.statusCode >= 500) {
          throw ConnectivityException(
            'Supabase service unavailable (HTTP ${response.statusCode}). Please try again later.',
          );
        }

        // Success
        if (kDebugMode && attempt > 0) {
          debugPrint('✅ NetworkDiagnostics: Health check succeeded on retry attempt ${attempt + 1}');
        }
        return;
      } on TimeoutException {
        lastError = 'Timeout reaching Supabase. Check network stability or VPN.';
        if (attempt < maxRetries) {
          final delay = Duration(seconds: 1 << attempt);
          if (kDebugMode) {
            debugPrint('⏳ NetworkDiagnostics: Health check timeout, retrying in ${delay.inSeconds}s...');
          }
          await Future.delayed(delay);
          continue;
        }
      } on SocketException catch (e) {
        lastError = 'Cannot reach Supabase over the network. Verify internet/VPN/firewall.';
        if (attempt < maxRetries) {
          final delay = Duration(seconds: 1 << attempt);
          if (kDebugMode) {
            debugPrint('⏳ NetworkDiagnostics: Network error (${e.message}), retrying in ${delay.inSeconds}s...');
          }
          await Future.delayed(delay);
          continue;
        }
      } on http.ClientException {
        lastError = 'Client error while reaching Supabase (possible TLS/DNS issue). Please check your network connection.';
        if (attempt < maxRetries) {
          final delay = Duration(seconds: 1 << attempt);
          if (kDebugMode) {
            debugPrint('⏳ NetworkDiagnostics: Client error, retrying in ${delay.inSeconds}s...');
          }
          await Future.delayed(delay);
          continue;
        }
      } on ConnectivityException {
        // Re-throw connectivity exceptions immediately
        rethrow;
      } catch (e) {
        lastError = 'Unexpected error while checking connectivity: ${e.toString()}';
        if (attempt < maxRetries) {
          final delay = Duration(seconds: 1 << attempt);
          await Future.delayed(delay);
          continue;
        }
      }
    }

    // All retries failed
    String errorMessage = lastError ?? 'Unable to reach Supabase. Please check your internet connection.';
    
    // Add helpful suggestions if DNS didn't resolve
    if (!dnsResolved) {
      errorMessage += '\n\nTip: DNS resolution failed. Try:\n• Checking your internet connection\n• Disabling VPN if active\n• Restarting the app';
    }
    
    throw ConnectivityException(errorMessage);
  }
}

class ConnectivityException implements Exception {
  final String message;
  final Object? cause;

  ConnectivityException(this.message, [this.cause]);

  @override
  String toString() => message;
}

