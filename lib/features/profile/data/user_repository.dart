import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? alias;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.alias,
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? alias,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      alias: alias ?? this.alias,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'alias': alias,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      alias: json['alias'] as String?,
      dateOfBirth:
          json['date_of_birth'] != null
              ? DateTime.parse(json['date_of_birth'] as String)
              : null,
      gender: json['gender'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class UserRepository {
  UserRepository();

  // In-memory storage for user profiles
  static final Map<String, UserProfile> _profiles = {};
  String? _currentUserId;

  // Mock data for offline/tests
  static final _mockUser = UserProfile(
    id: 'mock-user',
    name: 'John Doe',
    email: 'john.doe@example.com',
    phone: '+1 234 567 8900',
    alias: 'JD',
    dateOfBirth: null,
    gender: null,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );

  Future<UserProfile> getCurrentUser() async {
    if (_currentUserId == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockUser;
    }

    final profile = _profiles[_currentUserId];
    if (profile == null) {
      return await ensureProfileExists();
    }

    return profile;
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _profiles[profile.id] = profile.copyWith(updatedAt: DateTime.now());
    return _profiles[profile.id]!;
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // In-memory implementation - password is stored in auth repository
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  Future<UserProfile> ensureProfileExists({
    String? phoneDigits,
    String? overrideName,
  }) async {
    _currentUserId ??= 'user_${DateTime.now().millisecondsSinceEpoch}';

    final existing = _profiles[_currentUserId!];
    if (existing != null) {
      return existing;
    }

    final created = DateTime.now();
    final name = overrideName ?? 'User';
    final phone = phoneDigits;

    final profile = UserProfile(
      id: _currentUserId!,
      name: name,
      email: 'user@example.com',
      phone: phone,
      alias: null,
      gender: null,
      dateOfBirth: null,
      createdAt: created,
      updatedAt: created,
    );

    _profiles[_currentUserId!] = profile;
    return profile;
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final currentUserProvider = FutureProvider<UserProfile>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCurrentUser();
});
