import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/providers/supabase_provider.dart';
import '../../../core/services/network_diagnostics.dart';
import '../../../core/services/fcm_service.dart';

enum AdminRole { superAdmin, manager, support }

class AdminUser {
  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final DateTime createdAt;
  final bool isActive;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  AdminUser copyWith({
    String? id,
    String? name,
    String? email,
    AdminRole? role,
    DateTime? createdAt,
    bool? isActive,
  }) => AdminUser(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
  );
}

class AdminAuthState {
  final bool isAuthenticated;
  final AdminUser? adminUser;
  final bool loading;
  final bool isInitialized;
  final String? error;

  const AdminAuthState({
    this.isAuthenticated = false,
    this.adminUser,
    this.loading = false,
    this.isInitialized = false,
    this.error,
  });

  AdminAuthState copyWith({
    bool? isAuthenticated,
    AdminUser? adminUser,
    bool? loading,
    bool? isInitialized,
    String? error,
  }) => AdminAuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    adminUser: adminUser ?? this.adminUser,
    loading: loading ?? this.loading,
    isInitialized: isInitialized ?? this.isInitialized,
    error: error,
  );
}

class AdminAuthController extends StateNotifier<AdminAuthState> {
  AdminAuthController(this._ref) : super(const AdminAuthState()) {
    _initialize();
  }
  final Ref _ref;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  /// Initialize auth state by checking for existing session
  Future<void> _initialize() async {
    // Set loading state at start of initialization
    state = state.copyWith(loading: true);

    try {
      final supabaseClient = _ref.read(supabaseClientProvider);
      final session = supabaseClient.auth.currentSession;
      final user = supabaseClient.auth.currentUser;

      if (session != null && user != null) {
        // Pass manageLoading: false so _initialize() controls loading state
        await _restoreAdminStateFromUser(user, manageLoading: false);
      }

      // Listen to auth state changes
      _authStateSubscription = supabaseClient.auth.onAuthStateChange.listen((
        supabaseAuthState,
      ) {
        _handleAuthStateChange(supabaseAuthState);
      });

      // Set loading to false and mark as initialized after initialization completes
      state = state.copyWith(loading: false, isInitialized: true);
    } catch (e) {
      // Silently handle initialization errors
      if (kDebugMode) {
        print('⚠️ AdminAuthController: Initialization error: $e');
      }
      // Set loading to false and mark as initialized even on error
      state = state.copyWith(loading: false, isInitialized: true);
    }
  }

  /// Restore admin state from Supabase user
  /// [manageLoading] controls whether this method should set loading: false.
  /// Set to false when called from _initialize() to let the caller manage loading state.
  Future<void> _restoreAdminStateFromUser(
    supabase.User user, {
    bool manageLoading = true,
  }) async {
    try {
      final supabaseClient = _ref.read(supabaseClientProvider);

      // Check if user has admin role in profiles table
      final profileResponse =
          await supabaseClient
              .from('profiles')
              .select('id, name, email, role, created_at')
              .eq('id', user.id)
              .single();

      final role = profileResponse['role'] as String?;
      if (role == null ||
          (role != 'admin' && role != 'manager' && role != 'support')) {
        // User doesn't have admin role, don't restore state
        return;
      }

      // Map Supabase role to AdminRole enum
      AdminRole adminRole;
      switch (role) {
        case 'admin':
          adminRole = AdminRole.superAdmin;
          break;
        case 'manager':
          adminRole = AdminRole.manager;
          break;
        case 'support':
          adminRole = AdminRole.support;
          break;
        default:
          adminRole = AdminRole.support;
      }

      // Register FCM token for admin user
      try {
        final fcmService = FcmService();
        if (fcmService.isInitialized) {
          await fcmService.registerToken(user.id);
          if (kDebugMode) {
            print('✅ AdminAuthController: FCM token registered for admin');
          }
        }
      } catch (e) {
        // Don't fail restoration if FCM registration fails
        if (kDebugMode) {
          print(
            '⚠️ AdminAuthController: Failed to register FCM token (non-critical): $e',
          );
        }
      }

      // Create AdminUser from Supabase profile
      // Get created_at from profile if available, otherwise use current time
      DateTime createdAt = DateTime.now();
      if (profileResponse['created_at'] != null) {
        try {
          createdAt = DateTime.parse(profileResponse['created_at'] as String);
        } catch (e) {
          // If parsing fails, use current time
          createdAt = DateTime.now();
        }
      }

      final adminUser = AdminUser(
        id: profileResponse['id'] as String,
        name: profileResponse['name'] as String? ?? 'Admin',
        email: profileResponse['email'] as String? ?? user.email ?? '',
        role: adminRole,
        createdAt: createdAt,
      );

      // Only set loading: false if manageLoading is true (allows caller to control loading state)
      state = state.copyWith(
        isAuthenticated: true,
        adminUser: adminUser,
        loading: manageLoading ? false : state.loading,
      );
    } catch (e) {
      // Silently fail restoration - user might not be admin or profile might not exist
      if (kDebugMode) {
        print('⚠️ AdminAuthController: Failed to restore admin state: $e');
      }
    }
  }

  /// Handle auth state changes from Supabase
  void _handleAuthStateChange(supabase.AuthState supabaseAuthState) {
    if (supabaseAuthState.event == supabase.AuthChangeEvent.signedIn) {
      final user = supabaseAuthState.session?.user;
      if (user != null) {
        _restoreAdminStateFromUser(user);
      }
    } else if (supabaseAuthState.event == supabase.AuthChangeEvent.signedOut) {
      // Clear admin state when user signs out
      state = const AdminAuthState();
    } else if (supabaseAuthState.event ==
        supabase.AuthChangeEvent.tokenRefreshed) {
      final user = supabaseAuthState.session?.user;
      if (user != null) {
        _restoreAdminStateFromUser(user);
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final supabaseClient = _ref.read(supabaseClientProvider);

      // Surface DNS/TLS connectivity issues early
      await NetworkDiagnostics.ensureSupabaseReachable();

      // Authenticate with Supabase
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return false;

      if (response.user == null) {
        throw Exception(
          'Authentication failed: No user data returned. Please check your credentials.',
        );
      }

      // Use the extracted method to restore admin state
      await _restoreAdminStateFromUser(response.user!);

      if (!mounted) return false;

      // Check if state was successfully updated (user has admin role)
      if (!state.isAuthenticated) {
        // User doesn't have admin role, sign them out
        await supabaseClient.auth.signOut();
        throw Exception(
          'Access denied. Admin privileges required. '
          'Your account does not have admin, manager, or support role.',
        );
      }

      return true;
    } on ConnectivityException catch (e) {
      final message =
          'Cannot reach Supabase. Check internet/VPN/firewall and try again.\n${e.message}';
      state = state.copyWith(loading: false, error: message);
      return false;
    } on SocketException {
      state = state.copyWith(
        loading: false,
        error:
            'Network error while reaching Supabase. Verify connectivity or VPN and retry.',
      );
      return false;
    } on http.ClientException {
      state = state.copyWith(
        loading: false,
        error:
            'Client error while contacting Supabase (possible TLS/DNS issue). Please retry after checking network.',
      );
      return false;
    } on supabase.AuthException catch (e) {
      // Handle Supabase auth errors with better messages
      String errorMessage;
      final message = e.message.toLowerCase();
      // final status = e.statusCode?.toString() ?? ''; // Removed unused variable

      if (e.statusCode == '401') {
        if (message.contains('email not confirmed') ||
            message.contains('email_not_confirmed') ||
            message.contains('unconfirmed')) {
          errorMessage =
              'Email confirmation required. Please check your email for a confirmation link. '
              'If you\'re the admin, ensure email confirmation is disabled in Supabase settings.';
        } else if (message.contains('invalid login credentials') ||
            message.contains('invalid credentials')) {
          errorMessage =
              'Invalid email or password. Please check your credentials.';
        } else {
          errorMessage =
              'Authentication failed (401). Please check:\n'
              '• Your email and password are correct\n'
              '• Email confirmation is disabled in Supabase\n'
              '• Your account exists and is active';
        }
      } else if (e.statusCode == '404') {
        errorMessage = 'Account not found. Please verify your email address.';
      } else {
        errorMessage = 'Authentication error: ${e.message}';
      }

      state = state.copyWith(loading: false, error: errorMessage);
      return false;
    } catch (e) {
      // Extract error message, handling both Exception and String
      final errorMessage =
          e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : e.toString();
      state = state.copyWith(loading: false, error: errorMessage);
      return false;
    }
  }

  Future<void> signOut() async {
    // Unregister FCM token before signing out
    try {
      final currentAdmin = state.adminUser;
      if (currentAdmin != null) {
        final fcmService = FcmService();
        if (fcmService.isInitialized) {
          await fcmService.deleteAllTokens(currentAdmin.id);
          if (kDebugMode) {
            print('✅ AdminAuthController: FCM tokens deleted on logout');
          }
        }
      }
    } catch (e) {
      // Don't fail logout if FCM unregistration fails
      if (kDebugMode) {
        print(
          '⚠️ AdminAuthController: Failed to unregister FCM token (non-critical): $e',
        );
      }
    }

    try {
      final supabaseClient = _ref.read(supabaseClientProvider);
      await supabaseClient.auth.signOut();
    } catch (e) {
      // Ignore errors during signout
    } finally {
      if (mounted) {
        state = const AdminAuthState();
      }
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  bool hasPermission(String permission) {
    if (!state.isAuthenticated || state.adminUser == null) return false;

    final role = state.adminUser!.role;

    switch (permission) {
      case 'manage_products':
      case 'manage_orders':
      case 'manage_customers':
      case 'view_analytics':
        return true; // All admin roles can access these
      case 'manage_admins':
      case 'system_settings':
        return role == AdminRole.superAdmin;
      case 'manage_content':
        return role == AdminRole.superAdmin || role == AdminRole.manager;
      default:
        return false;
    }
  }
}

final adminAuthControllerProvider =
    StateNotifierProvider<AdminAuthController, AdminAuthState>(
      (ref) => AdminAuthController(ref),
    );

// Convenience providers
final isAdminAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(adminAuthControllerProvider).isAuthenticated;
});

final currentAdminProvider = Provider<AdminUser?>((ref) {
  return ref.watch(adminAuthControllerProvider).adminUser;
});

final adminPermissionsProvider = Provider<Set<String>>((ref) {
  final controller = ref.watch(adminAuthControllerProvider);
  if (!controller.isAuthenticated || controller.adminUser == null) {
    return <String>{};
  }

  final permissions = <String>{
    'manage_products',
    'manage_orders',
    'manage_customers',
    'view_analytics',
  };

  if (controller.adminUser!.role == AdminRole.superAdmin) {
    permissions.addAll({'manage_admins', 'system_settings', 'manage_content'});
  } else if (controller.adminUser!.role == AdminRole.manager) {
    permissions.add('manage_content');
  }

  return permissions;
});
