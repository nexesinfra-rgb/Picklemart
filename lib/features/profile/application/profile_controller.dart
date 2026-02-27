import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/config/environment.dart';

// Profile repository provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProfileRepository(supabase);
});

// Profile state
class ProfileState {
  final Profile? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({this.profile, this.isLoading = false, this.error});

  ProfileState copyWith({Profile? profile, bool? isLoading, String? error}) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Profile controller
class ProfileController extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final Ref _ref;
  StreamSubscription<Profile?>? _profileSubscription;
  String? _currentUserId;

  ProfileController(this._repository, this._ref) : super(const ProfileState()) {
    _initialize();
  }

  /// Initialize profile controller
  Future<void> _initialize() async {
    // Listen to auth state changes
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        if (next.isAuthenticated && next.userId != null) {
          // User logged in: load profile and subscribe to real-time changes
          _currentUserId = next.userId;
          loadCurrentProfile();
          _subscribeToProfileChanges(next.userId!);
        } else {
          // User logged out: clear profile and cancel subscription
          _currentUserId = null;
          _profileSubscription?.cancel();
          _profileSubscription = null;
          state = const ProfileState();
        }
      } else if (next.isAuthenticated && 
                 next.userId != null && 
                 next.userId != _currentUserId) {
        // User ID changed: reload profile
        _currentUserId = next.userId;
        loadCurrentProfile();
        _subscribeToProfileChanges(next.userId!);
      }
    });

    // Load profile if user is already authenticated
    final authState = _ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.userId != null) {
      _currentUserId = authState.userId;
      await loadCurrentProfile();
      _subscribeToProfileChanges(authState.userId!);
    }
  }

  /// Subscribe to real-time profile changes
  void _subscribeToProfileChanges(String userId) {
    // Cancel existing subscription
    _profileSubscription?.cancel();

    // Subscribe to real-time changes
    _profileSubscription = _repository.subscribeToProfileChanges(userId).listen(
      (profile) {
        if (kDebugMode) {
          print('DEBUG: Profile changed via realtime: ${profile?.name ?? 'null'}');
        }
        state = state.copyWith(profile: profile, error: null);
      },
      onError: (error) {
        if (kDebugMode) {
          print('DEBUG: Error in profile subscription: $error');
        }
        // Don't update state on subscription error, just log it
      },
    );
  }

  /// Load current user's profile
  Future<void> loadCurrentProfile() async {
    print('DEBUG: loadCurrentProfile called');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current authenticated user from auth repository
      final authRepo = _ref.read(authRepositoryProvider);
      final user = authRepo.currentUser;

      if (user == null) {
        print('DEBUG: No authenticated user found');
        state = state.copyWith(profile: null, isLoading: false);
        return;
      }

      print('DEBUG: Calling repository.getProfile() for user: ${user.id}');
      final profile = await _repository.getProfile(user.id);
      print('DEBUG: Repository returned profile: ${profile?.name ?? 'null'}');

      state = state.copyWith(profile: profile, isLoading: false);
      print(
        'DEBUG: Profile state updated, isLoading: ${state.isLoading}, profile: ${state.profile?.name ?? 'null'}',
      );
    } catch (e) {
      print('DEBUG: Error in loadCurrentProfile: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Load profile by user ID
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _repository.getProfile(userId);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new profile
  Future<Profile?> createProfile({
    required String userId,
    required String name,
    String? mobile,
    String? avatarUrl,
    String role = 'user',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _repository.createProfile(
        userId: userId,
        name: name,
        mobile: mobile,
        avatarUrl: avatarUrl,
        role: role,
      );

      state = state.copyWith(profile: profile, isLoading: false);

      return profile;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Get GST number
  Future<String?> getGstNumber() async {
    if (state.profile == null) return null;
    return _repository.getProfileGst(state.profile!.id);
  }

  /// Update profile
  Future<Profile?> updateProfile({
    String? name,
    String? mobile,
    String? avatarUrl,
    bool removeAvatar = false,
    String? gender,
    DateTime? dateOfBirth,
    String? email,
    String? gstNumber,
  }) async {
    if (state.profile == null) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedProfile = await _repository.updateProfile(
        userId: state.profile!.id,
        name: name,
        mobile: mobile,
        avatarUrl: avatarUrl,
        removeAvatar: removeAvatar,
        gender: gender,
        dateOfBirth: dateOfBirth,
        email: email,
        gstNumber: gstNumber,
      );

      state = state.copyWith(profile: updatedProfile, isLoading: false);

      return updatedProfile;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Delete profile
  Future<bool> deleteProfile() async {
    if (state.profile == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.deleteProfile(state.profile!.id);
      state = state.copyWith(profile: null, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Check if profile exists
  Future<bool> profileExists(String userId) async {
    try {
      return await _repository.profileExists(userId);
    } catch (e) {
      return false;
    }
  }

  /// Ensure profile exists for authenticated user, create if not exists
  Future<Profile?> ensureProfileExists({
    String? overrideName,
    String? mobile,
    Profile? profile, // Accept cached profile to avoid duplicate query
  }) async {
    try {
      // If profile provided, use it instead of querying
      if (profile != null) {
        state = state.copyWith(profile: profile);
        return profile;
      }

      // Get current authenticated user from auth repository
      final authRepo = _ref.read(authRepositoryProvider);
      final user = authRepo.currentUser;

      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Check if profile already exists
      final existingProfile = await _repository.getProfile(user.id);
      if (existingProfile != null) {
        // Update state with existing profile
        state = state.copyWith(profile: existingProfile);
        return existingProfile;
      }

      // Create new profile
      final name =
          overrideName ?? (user.userMetadata?['name'] as String?) ?? 'User';
      final userMobile = mobile ?? (user.userMetadata?['mobile'] as String?);

      // Determine role - check metadata for role (not hardcoded email)
      String profileRole = 'user';
      // Check metadata for role
      final metadataRole = user.userMetadata?['role'] as String?;
      if (metadataRole == 'admin' ||
          metadataRole == 'manager' ||
          metadataRole == 'support') {
        profileRole = metadataRole!;
      }
      // Also check if email matches configured admin email (from environment)
      if (user.email == Environment.adminEmail) {
        profileRole = 'admin';
      }

      final newProfile = await createProfile(
        userId: user.id,
        name: name,
        mobile: userMobile,
        role: profileRole,
      );

      return newProfile;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get profile by mobile number
  Future<Profile?> getProfileByMobile(String mobile) async {
    try {
      return await _repository.getProfileByMobile(mobile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update user role (admin only)
  Future<Profile?> updateUserRole({
    required String userId,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedProfile = await _repository.updateUserRole(
        userId: userId,
        role: role,
      );

      // Update state if it's the current user's profile
      if (state.profile?.id == userId) {
        state = state.copyWith(profile: updatedProfile, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }

      return updatedProfile;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Clear profile state
  void clearProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _currentUserId = null;
    state = const ProfileState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
    super.dispose();
  }
}

// Profile controller provider
final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return ProfileController(repository, ref);
    });

// Current profile provider (convenience)
final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(profileControllerProvider).profile;
});

// Profile loading state provider
final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileControllerProvider).isLoading;
});

// Profile error provider
final profileErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileControllerProvider).error;
});
