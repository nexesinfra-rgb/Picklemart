import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../data/auth_repository.dart';
import '../../../core/config/environment.dart';
import '../../../core/services/session_tracking_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/domain/profile.dart';

enum AppRole { none, user, admin }

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final AppRole role;
  final String? name;
  final String? email;
  final String? mobile;
  final String? displayMobile;
  final bool loading;
  final bool isInitialized;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.role = AppRole.none,
    this.name,
    this.email,
    this.mobile,
    this.displayMobile,
    this.loading = false,
    this.isInitialized = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    AppRole? role,
    String? name,
    String? email,
    String? mobile,
    String? displayMobile,
    bool? loading,
    bool? isInitialized,
    String? error,
  }) => AuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    name: name ?? this.name,
    email: email ?? this.email,
    mobile: mobile ?? this.mobile,
    displayMobile: displayMobile ?? this.displayMobile,
    loading: loading ?? this.loading,
    isInitialized: isInitialized ?? this.isInitialized,
    error: error,
  );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _initialize();
  }
  final Ref _ref;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  /// Initialize auth state by checking for existing session
  Future<void> _initialize() async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      final session = repo.getCurrentSession();
      final user = repo.currentUser;

      if (session != null && user != null) {
        await _updateStateFromUser(user);

        if (!mounted) return;

        // Ensure profile exists for authenticated user
        try {
          await _ref
              .read(profileControllerProvider.notifier)
              .ensureProfileExists();
        } catch (_) {
          // Ignore profile sync errors
        }
      }

      // Listen to auth state changes
      _authStateSubscription = repo.authStateChanges.listen((
        supabaseAuthState,
      ) {
        _handleAuthStateChange(supabaseAuthState);
      });
    } catch (e) {
      // Silently handle initialization errors
      // Error is logged but doesn't block app startup
    } finally {
      // Mark initialization as complete
      if (mounted) {
        state = state.copyWith(isInitialized: true);
      }
    }
  }

  /// Handle auth state changes from Supabase
  void _handleAuthStateChange(supabase.AuthState supabaseAuthState) {
    if (supabaseAuthState.event == supabase.AuthChangeEvent.signedIn) {
      final user = supabaseAuthState.session?.user;
      if (user != null) {
        _updateStateFromUser(user);
      }
    } else if (supabaseAuthState.event == supabase.AuthChangeEvent.signedOut) {
      // End session when user logs out
      try {
        // Cleanup FCM tokens for the user who just logged out
        // We do this before clearing state so we have the userId
        final userId = state.userId;
        if (userId != null) {
          final fcmService = FcmService();
          if (fcmService.isInitialized) {
            // Best effort cleanup - don't await if you don't want to block
            // But here we're in an event handler so it's fine
            fcmService
                .deleteAllUserTokens(userId)
                .then((_) {
                  if (kDebugMode) {
                    print('✅ AuthController: User FCM tokens cleaned up');
                  }
                })
                .catchError((e) {
                  if (kDebugMode) {
                    print(
                      '⚠️ AuthController: Failed to cleanup FCM tokens: $e',
                    );
                  }
                });
          }
        }

        final sessionService = _ref.read(sessionTrackingServiceProvider);
        sessionService.endSession();
      } catch (e) {
        // Silently fail - session end is not critical for logout
        if (kDebugMode) {
          print('Failed to end session on logout: $e');
        }
      }
      state = const AuthState();
    } else if (supabaseAuthState.event ==
        supabase.AuthChangeEvent.tokenRefreshed) {
      final user = supabaseAuthState.session?.user;
      if (user != null) {
        _updateStateFromUser(user);
      }
    }
  }

  /// Update auth state from Supabase user
  /// Returns the fetched profile to avoid duplicate queries
  Future<Profile?> _updateStateFromUser(supabase.User user) async {
    // Get user metadata - Supabase stores custom data passed during signup here
    final userMetadata = user.userMetadata ?? <String, dynamic>{};

    // Fetch profile from database to get accurate role
    AppRole appRole = AppRole.user;
    String? profileName = userMetadata['name'] as String?;
    Profile? fetchedProfile;

    try {
      final profileRepo = _ref.read(profileRepositoryProvider);
      fetchedProfile = await profileRepo.getProfile(user.id);

      if (!mounted) return null;

      if (fetchedProfile != null) {
        // Use profile data for role and name
        profileName = fetchedProfile.name;
        appRole = _determineRoleFromProfile(fetchedProfile.role);
      } else {
        // Fallback to metadata if profile doesn't exist yet
        appRole = _determineRole(userMetadata);
      }
    } catch (e) {
      // If profile fetch fails, fallback to metadata
      appRole = _determineRole(userMetadata);
    }

    if (!mounted) return null;

    // Register FCM token for regular users
    // Admin users are handled by AdminAuthController
    if (appRole == AppRole.user) {
      try {
        final fcmService = FcmService();
        // Request notification permission and register token
        // We do this in the background to not block the UI
        if (fcmService.isInitialized) {
          Future.microtask(() async {
            try {
              // Request permission first (this handles checking if already granted)
              final granted = await fcmService.requestNotificationPermission();

              if (granted) {
                // Register token if permission granted
                await fcmService.registerUserToken(user.id);
                if (kDebugMode) {
                  print('✅ AuthController: FCM token registered for user');
                }
              } else {
                if (kDebugMode) {
                  print(
                    '⚠️ AuthController: Notification permission denied by user',
                  );
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ AuthController: Failed to register FCM token: $e');
              }
            }
          });
        }
      } catch (e) {
        // Ignore initialization errors
      }
    }

    state = state.copyWith(
      isAuthenticated: true,
      userId: user.id,
      name: profileName,
      email: user.email,
      mobile: userMetadata['mobile'] as String?,
      displayMobile: userMetadata['display_mobile'] as String?,
      role: appRole,
      error: null,
    );

    return fetchedProfile;
  }

  /// Determine app role from profile role field
  AppRole _determineRoleFromProfile(String? profileRole) {
    if (profileRole == 'admin' ||
        profileRole == 'manager' ||
        profileRole == 'support') {
      return AppRole.admin;
    }
    return AppRole.user;
  }

  /// Determine app role from user metadata or email (fallback)
  AppRole _determineRole(Map<String, dynamic> userMetadata) {
    final role = userMetadata['role'] as String?;
    if (role == 'admin' || role == 'manager' || role == 'support') {
      return AppRole.admin;
    }
    return AppRole.user;
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void selectRole(AppRole role) {
    state = state.copyWith(role: role);
  }

  /// Sign in with mobile number and password
  Future<void> signInWithMobile(String mobile, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final response = await repo.signInWithMobile(
        mobile: mobile,
        password: password,
      );

      if (!mounted) return;

      // Check if we have both user and session
      final user = response.user;
      final session = response.session;

      if (user == null) {
        state = state.copyWith(
          error:
              'Login failed: No user data returned. Please check your credentials and try again.',
        );
        return;
      }

      if (session == null) {
        state = state.copyWith(
          error:
              'Login failed: No session returned.\n\n'
              'This may happen if:\n'
              '• Email confirmation is still enabled in Supabase\n'
              '• User account is not confirmed\n\n'
              'Please check Supabase settings and ensure email confirmation is disabled.',
        );
        return;
      }

      // PERFORMANCE OPTIMIZATION: Set authenticated state immediately
      // This allows navigation to happen instantly without waiting for profile
      final userMetadata = user.userMetadata ?? <String, dynamic>{};
      state = state.copyWith(
        isAuthenticated: true,
        userId: user.id,
        name: userMetadata['name'] as String?,
        email: user.email,
        mobile: userMetadata['mobile'] as String?,
        displayMobile: userMetadata['display_mobile'] as String?,
        role: _determineRole(userMetadata), // Use metadata role initially
        error: null,
        loading: false, // Set loading to false immediately
      );

      // Move profile operations to background (fire-and-forget)
      // Profile will load in background and update state when ready
      _updateStateFromUser(user)
          .then((profile) {
            if (!mounted) return;
            // Profile loaded - update state with accurate role/name
            // Ensure profile exists in background
            try {
              if (profile != null) {
                _ref
                    .read(profileControllerProvider.notifier)
                    .ensureProfileExists(profile: profile)
                    .catchError((_) {
                      // Ignore profile sync errors
                    });
              } else {
                _ref
                    .read(profileControllerProvider.notifier)
                    .ensureProfileExists()
                    .catchError((_) {
                      // Ignore profile sync errors
                    });
              }
            } catch (_) {
              // Ignore profile sync errors
            }
          })
          .catchError((_) {
            // Ignore profile fetch errors - user is already authenticated
          });

      // Request notification permission and register FCM token (fire-and-forget)
      // Request permission contextually after login to comply with Google Play Store policies
      try {
        final fcmService = FcmService();
        if (fcmService.isInitialized) {
          // Request permission first, then register token
          fcmService
              .requestNotificationPermission()
              .then((granted) async {
                if (granted) {
                  // Register token only if permission was granted
                  await fcmService.registerUserToken(user.id);
                } else {
                  if (kDebugMode) {
                    print(
                      '⚠️ FCM: Permission not granted, token not registered',
                    );
                  }
                }
              })
              .catchError((e) {
                if (kDebugMode) {
                  print(
                    '⚠️ FCM: Failed to request permission or register token: $e',
                  );
                }
              });
        }
      } catch (e) {
        // Silently fail - FCM registration is not critical for login
        if (kDebugMode) {
          print(
            '⚠️ FCM: Error during permission request or token registration: $e',
          );
        }
      }
    } catch (e) {
      // Extract error message, handling both Exception and String
      final errorMessage =
          e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : e.toString();
      if (mounted) {
        state = state.copyWith(error: errorMessage, loading: false);
      }
    }
  }

  /// Sign up with mobile number, name, and password
  Future<void> signUpWithMobile(
    String name,
    String mobile,
    String password,
  ) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final response = await repo.signUpWithMobile(
        name: name,
        mobile: mobile,
        password: password,
      );

      if (!mounted) return;

      // Check if user was created
      if (response.user == null) {
        state = state.copyWith(
          error:
              'Signup failed: User account was not created. Please try again.',
        );
        return;
      }

      // If signup returned a session (email confirmation disabled), update auth state
      if (response.session == null) {
        state = state.copyWith(
          error:
              'Signup failed: Supabase did not return a session.\n\n'
              'Most likely email confirmations are still enabled. Disable "Enable email confirmations" in Supabase → Authentication → Settings, rebuild, and try again.',
        );
        return;
      }

      // Update state with user from response (no need to refresh)
      await _updateStateFromUser(response.user!);

      if (!mounted) return;

      // After sign-up, pre-create the profile with name/mobile/createdAt
      try {
        await _ref
            .read(profileControllerProvider.notifier)
            .ensureProfileExists(overrideName: name);
      } catch (_) {
        // Ignore profile sync errors to keep sign-up flow resilient
      }
    } catch (e) {
      // Extract error message, handling both Exception and String
      final errorMessage =
          e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : e.toString();
      if (mounted) {
        state = state.copyWith(error: errorMessage);
      }
    } finally {
      if (mounted) {
        state = state.copyWith(loading: false);
      }
    }
  }

  /// Reset password using mobile number
  Future<void> resetPasswordWithMobile(String mobile) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.resetPasswordWithMobile(
        mobile: mobile,
        url: Environment.passwordResetRedirectUrl,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    } finally {
      if (mounted) {
        state = state.copyWith(loading: false);
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final response = await repo.signIn(email: email, password: password);

      if (!mounted) return;

      // Check if we have both user and session
      final user = response.user;
      final session = response.session;

      if (user == null) {
        state = state.copyWith(
          error:
              'Login failed: No user data returned. Please check your credentials and try again.',
        );
        return;
      }

      if (session == null) {
        state = state.copyWith(
          error:
              'Login failed: No session returned.\n\n'
              'This may happen if:\n'
              '• Email confirmation is still enabled in Supabase\n'
              '• User account is not confirmed\n\n'
              'Please check Supabase settings and ensure email confirmation is disabled.',
          loading: false,
        );
        return;
      }

      // PERFORMANCE OPTIMIZATION: Set authenticated state immediately
      // This allows navigation to happen instantly without waiting for profile
      final userMetadata = user.userMetadata ?? <String, dynamic>{};
      state = state.copyWith(
        isAuthenticated: true,
        userId: user.id,
        name: userMetadata['name'] as String?,
        email: user.email,
        mobile: userMetadata['mobile'] as String?,
        displayMobile: userMetadata['display_mobile'] as String?,
        role: _determineRole(userMetadata), // Use metadata role initially
        error: null,
        loading: false, // Set loading to false immediately
      );

      // Move profile operations to background (fire-and-forget)
      // Profile will load in background and update state when ready
      _updateStateFromUser(user)
          .then((profile) {
            if (!mounted) return;
            // Profile loaded - update state with accurate role/name
            // Ensure profile exists in background
            try {
              if (profile != null) {
                _ref
                    .read(profileControllerProvider.notifier)
                    .ensureProfileExists(profile: profile)
                    .catchError((_) {
                      // Ignore profile sync errors
                    });
              } else {
                _ref
                    .read(profileControllerProvider.notifier)
                    .ensureProfileExists()
                    .catchError((_) {
                      // Ignore profile sync errors
                    });
              }
            } catch (_) {
              // Ignore profile sync errors
            }
          })
          .catchError((_) {
            // Ignore profile fetch errors - user is already authenticated
          });

      // Request notification permission and register FCM token (fire-and-forget)
      // Request permission contextually after login to comply with Google Play Store policies
      try {
        final fcmService = FcmService();
        if (fcmService.isInitialized) {
          // Request permission first, then register token
          fcmService
              .requestNotificationPermission()
              .then((granted) async {
                if (granted) {
                  // Register token only if permission was granted
                  await fcmService.registerUserToken(user.id);
                } else {
                  if (kDebugMode) {
                    print(
                      '⚠️ FCM: Permission not granted, token not registered',
                    );
                  }
                }
              })
              .catchError((e) {
                if (kDebugMode) {
                  print(
                    '⚠️ FCM: Failed to request permission or register token: $e',
                  );
                }
              });
        }
      } catch (e) {
        // Silently fail - FCM registration is not critical for login
        if (kDebugMode) {
          print(
            '⚠️ FCM: Error during permission request or token registration: $e',
          );
        }
      }
    } catch (e) {
      // Extract error message, handling both Exception and String
      final errorMessage =
          e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : e.toString();
      if (mounted) {
        state = state.copyWith(error: errorMessage, loading: false);
      }
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final response = await repo.signUp(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      // If signup returned a session (email confirmation disabled), update auth state
      if (response.session != null && response.user != null) {
        // Update state with user from response (no need to refresh)
        await _updateStateFromUser(response.user!);
      }

      if (!mounted) return;

      // After sign-up, pre-create the profile with name/phone/createdAt
      try {
        await _ref
            .read(profileControllerProvider.notifier)
            .ensureProfileExists(overrideName: name);
      } catch (_) {
        // Ignore profile sync errors to keep sign-up flow resilient
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    } finally {
      if (mounted) {
        state = state.copyWith(loading: false);
      }
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.resetPassword(
        email: email,
        url: Environment.passwordResetRedirectUrl,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    } finally {
      if (mounted) {
        state = state.copyWith(loading: false);
      }
    }
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    } finally {
      if (mounted) {
        state = state.copyWith(loading: false);
      }
    }
  }

  Future<void> confirmRecovery(
    String userId,
    String secret,
    String newPassword,
    String confirmPassword,
  ) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.confirmRecovery(
        userId: userId,
        secret: secret,
        newPassword: newPassword,
      );
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    } finally {
      if (mounted) {
        state = state.copyWith(loading: false);
      }
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final userId = state.userId;

      // Unregister FCM token before signing out (fire-and-forget)
      if (userId != null) {
        try {
          final fcmService = FcmService();
          if (fcmService.isInitialized) {
            fcmService.deleteAllUserTokens(userId).catchError((e) {
              if (kDebugMode) {
                print('⚠️ FCM: Failed to unregister user token: $e');
              }
            });
          }
        } catch (e) {
          // Silently fail - FCM unregistration is not critical for logout
          if (kDebugMode) {
            print('⚠️ FCM: Error during token unregistration: $e');
          }
        }
      }

      // End session before signing out
      try {
        final sessionService = _ref.read(sessionTrackingServiceProvider);
        await sessionService.endSession();
      } catch (e) {
        // Silently fail - session end is not critical for logout
        if (kDebugMode) {
          print('Failed to end session on signOut: $e');
        }
      }

      final repo = _ref.read(authRepositoryProvider);
      await repo.signOut();
      if (mounted) {
        state = const AuthState();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    } finally {
      if (mounted) {
        state = state.copyWith(loading: false);
      }
    }
  }

  /// Delete the current user's account permanently
  /// This will delete the profile and all related data, then sign out
  Future<void> deleteAccount() async {
    state = state.copyWith(loading: true, error: null);
    try {
      // End session before deleting account
      try {
        final sessionService = _ref.read(sessionTrackingServiceProvider);
        await sessionService.endSession();
      } catch (e) {
        // Silently fail - session end is not critical for account deletion
        if (kDebugMode) {
          print('Failed to end session on deleteAccount: $e');
        }
      }

      final repo = _ref.read(authRepositoryProvider);
      await repo.deleteAccount();

      // Reset state after successful deletion
      if (mounted) {
        state = const AuthState();
      }
    } catch (e) {
      // Extract error message, handling both Exception and String
      final errorMessage =
          e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : e.toString();
      if (mounted) {
        state = state.copyWith(error: errorMessage, loading: false);
      }
      rethrow; // Re-throw so caller can handle navigation/UI updates
    } finally {
      if (mounted && !state.isAuthenticated) {
        // If deletion was successful, state is already reset
        // Only set loading to false if still authenticated (error case)
        state = state.copyWith(loading: false);
      }
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);
