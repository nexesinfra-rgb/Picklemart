import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/phone_utils.dart';
import '../domain/profile.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  /// Helper function to convert DateTime fields to ISO strings for JSON parsing
  /// Profile.fromJson expects strings, not DateTime objects
  Map<String, dynamic> _convertDateTimeFieldsToStrings(
    Map<String, dynamic> data,
  ) {
    final converted = Map<String, dynamic>.from(data);

    // Convert date_of_birth (DATE format - just date part)
    if (converted['date_of_birth'] != null) {
      if (converted['date_of_birth'] is DateTime) {
        converted['date_of_birth'] =
            (converted['date_of_birth'] as DateTime).toIso8601String().split(
              'T',
            )[0];
      } else if (converted['date_of_birth'] is! String) {
        try {
          final dt = DateTime.parse(converted['date_of_birth'].toString());
          converted['date_of_birth'] = dt.toIso8601String().split('T')[0];
        } catch (e) {
          converted['date_of_birth'] = null;
        }
      }
    }

    // Convert created_at
    if (converted['created_at'] != null) {
      if (converted['created_at'] is DateTime) {
        converted['created_at'] =
            (converted['created_at'] as DateTime).toIso8601String();
      } else if (converted['created_at'] is! String) {
        try {
          final dt = DateTime.parse(converted['created_at'].toString());
          converted['created_at'] = dt.toIso8601String();
        } catch (e) {
          converted['created_at'] = null;
        }
      }
    }

    // Convert updated_at
    if (converted['updated_at'] != null) {
      if (converted['updated_at'] is DateTime) {
        converted['updated_at'] =
            (converted['updated_at'] as DateTime).toIso8601String();
      } else if (converted['updated_at'] is! String) {
        try {
          final dt = DateTime.parse(converted['updated_at'].toString());
          converted['updated_at'] = dt.toIso8601String();
        } catch (e) {
          converted['updated_at'] = null;
        }
      }
    }

    return converted;
  }

  /// Get current user's profile
  Future<Profile?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }

  /// Get profile by user ID
  Future<Profile?> getProfile(String userId) async {
    try {
      final response =
          await _supabase
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

      if (response == null) return null;

      final data = Map<String, dynamic>.from(response);
      final convertedData = _convertDateTimeFieldsToStrings(data);
      return Profile.fromJson(convertedData);
    } catch (e) {
      throw Exception('Failed to get profile: ${e.toString()}');
    }
  }

  /// Create a new profile
  Future<Profile> createProfile({
    required String userId,
    required String name,
    String? mobile,
    String? avatarUrl,
    String role = 'user',
    String? gender,
    DateTime? dateOfBirth,
    String? email,
  }) async {
    String? displayMobile;
    if (mobile != null) {
      displayMobile = PhoneUtils.formatMobileForDisplay(mobile);
    }

    final profileData = <String, dynamic>{
      'id': userId,
      'name': name,
      'role': role,
    };

    if (mobile != null) profileData['mobile'] = mobile;
    if (displayMobile != null) profileData['display_mobile'] = displayMobile;
    if (avatarUrl != null) profileData['avatar_url'] = avatarUrl;
    if (gender != null) profileData['gender'] = gender;
    if (dateOfBirth != null) {
      profileData['date_of_birth'] =
          dateOfBirth.toIso8601String().split('T')[0]; // DATE format
    }
    if (email != null) profileData['email'] = email;

    try {
      final response =
          await _supabase
              .from('profiles')
              .insert(profileData)
              .select()
              .single();

      final data = Map<String, dynamic>.from(response);
      // Convert DateTime objects to ISO strings (fromJson expects strings)
      final convertedData = _convertDateTimeFieldsToStrings(data);

      return Profile.fromJson(convertedData);
    } catch (e) {
      throw Exception('Failed to create profile: ${e.toString()}');
    }
  }

  /// Update profile
  Future<Profile> updateProfile({
    required String userId,
    String? name,
    String? mobile,
    String? avatarUrl,
    bool removeAvatar = false,
    String? gender,
    DateTime? dateOfBirth,
    String? email,
    String? gstNumber,
  }) async {
    final updateData = <String, dynamic>{};

    if (name != null) updateData['name'] = name;
    if (mobile != null) {
      updateData['mobile'] = mobile;
      updateData['display_mobile'] = PhoneUtils.formatMobileForDisplay(mobile);
    }
    if (removeAvatar) {
      // Explicitly set avatar_url to null to remove it
      updateData['avatar_url'] = null;
    } else if (avatarUrl != null) {
      updateData['avatar_url'] = avatarUrl;
    }
    if (gender != null) updateData['gender'] = gender;
    if (dateOfBirth != null) {
      updateData['date_of_birth'] =
          dateOfBirth.toIso8601String().split('T')[0]; // DATE format
    }
    if (email != null) updateData['email'] = email;
    if (gstNumber != null) updateData['gst_number'] = gstNumber;

    // updated_at is automatically updated by trigger

    try {
      final response =
          await _supabase
              .from('profiles')
              .update(updateData)
              .eq('id', userId)
              .select()
              .single();

      final data = Map<String, dynamic>.from(response);
      final convertedData = _convertDateTimeFieldsToStrings(data);
      return Profile.fromJson(convertedData);
    } on PostgrestException catch (e) {
      // Fallback: If gst_number column is missing, retry without it
      if (e.message.contains('gst_number') &&
          updateData.containsKey('gst_number')) {
        updateData.remove('gst_number');
        // Retry
        final response =
            await _supabase
                .from('profiles')
                .update(updateData)
                .eq('id', userId)
                .select()
                .single();

        final data = Map<String, dynamic>.from(response);
        final convertedData = _convertDateTimeFieldsToStrings(data);
        return Profile.fromJson(convertedData);
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Delete profile
  Future<void> deleteProfile(String userId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete profile: ${e.toString()}');
    }
  }

  /// Get profile GST number
  Future<String?> getProfileGst(String userId) async {
    try {
      final response =
          await _supabase
              .from('profiles')
              .select('gst_number')
              .eq('id', userId)
              .maybeSingle();

      if (response == null) return null;
      return response['gst_number'] as String?;
    } catch (e) {
      // Return null if column doesn't exist yet or other error
      return null;
    }
  }

  /// Check if profile exists
  Future<bool> profileExists(String userId) async {
    try {
      final response =
          await _supabase
              .from('profiles')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get profile by mobile number
  Future<Profile?> getProfileByMobile(String mobile) async {
    try {
      final response =
          await _supabase
              .from('profiles')
              .select()
              .eq('mobile', mobile)
              .maybeSingle();

      if (response == null) return null;

      final data = Map<String, dynamic>.from(response);
      final convertedData = _convertDateTimeFieldsToStrings(data);
      return Profile.fromJson(convertedData);
    } catch (e) {
      throw Exception('Failed to get profile by mobile: ${e.toString()}');
    }
  }

  /// Subscribe to real-time profile changes for a user
  Stream<Profile?> subscribeToProfileChanges(String userId) {
    final controller = StreamController<Profile?>();

    // Initial fetch
    getProfile(userId)
        .then((profile) {
          if (!controller.isClosed) {
            controller.add(profile);
          }
        })
        .catchError((error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        });

    // Subscribe to real-time changes
    final subscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen(
          (data) async {
            try {
              if (data.isEmpty) {
                if (!controller.isClosed) {
                  controller.add(null);
                }
                return;
              }

              final profileData = data.first;
              final convertedData = _convertDateTimeFieldsToStrings(
                profileData,
              );
              final profile = Profile.fromJson(convertedData);

              if (!controller.isClosed) {
                controller.add(profile);
              }
            } catch (e) {
              if (kDebugMode) {
                print('Error processing profile change: $e');
              }
              // Don't add error to stream, just log it
              // The initial fetch error was already handled
            }
          },
          onError: (error) {
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );

    // Cancel subscription when stream is closed
    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Update user role (admin only)
  Future<Profile> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      final response =
          await _supabase
              .from('profiles')
              .update({'role': role})
              .eq('id', userId)
              .select()
              .single();

      final data = Map<String, dynamic>.from(response);
      final convertedData = _convertDateTimeFieldsToStrings(data);
      return Profile.fromJson(convertedData);
    } catch (e) {
      throw Exception('Failed to update user role: ${e.toString()}');
    }
  }

  /// Get all profiles (admin only)
  Future<List<Profile>> getAllProfiles({
    int? limit,
    int? offset,
    String? search,
  }) async {
    try {
      dynamic query = _supabase.from('profiles').select();

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        query = query.or('name.ilike.%$search%,mobile.ilike.%$search%');
      }

      // Sort by created_at descending
      query = query.order('created_at', ascending: false);

      // Apply pagination
      if (limit != null && offset != null) {
        query = query.range(offset, offset + limit - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      } else if (offset != null) {
        query = query.range(offset, offset + 999);
      }

      final response = await query;
      final profilesList = response as List;

      return profilesList.map((json) {
        final data = json as Map<String, dynamic>;
        final convertedData = _convertDateTimeFieldsToStrings(data);
        return Profile.fromJson(convertedData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get all profiles: ${e.toString()}');
    }
  }

  /// Get profiles count (admin only)
  Future<int> getProfilesCount({String? search}) async {
    try {
      // For count, we'll get all profiles and count them
      // This is simpler than dealing with count() API complexity
      final profiles = await getAllProfiles(search: search);
      return profiles.length;
    } catch (e) {
      throw Exception('Failed to get profiles count: ${e.toString()}');
    }
  }

  /// Upload profile avatar image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String> uploadProfileAvatar(XFile imageFile, String userId) async {
    // Validate authentication before attempting upload
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception(
        'User not authenticated. Please log in to upload a profile avatar.',
      );
    }

    if (currentUser.id != userId) {
      throw Exception(
        'User ID mismatch. Cannot upload avatar for another user.',
      );
    }

    try {
      final bucket = _supabase.storage.from('profile-avatars');

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String extension = 'jpg';
      if (imageFile.name.contains('.')) {
        extension = imageFile.name.split('.').last.toLowerCase();
      }
      // Ensure extension is valid
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        extension = 'jpg';
      }
      final fileName = 'avatars/$userId/${timestamp}_avatar.$extension';

      // Read file bytes
      Uint8List bytes;
      if (kIsWeb) {
        // On web, read bytes from XFile
        bytes = await imageFile.readAsBytes();
      } else {
        // On mobile, read from File path
        final file = File(imageFile.path);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        } else {
          throw Exception('File not found: ${imageFile.path}');
        }
      }

      if (bytes.isEmpty) {
        throw Exception(
          'Image bytes are empty. The selected image file appears to be corrupted.',
        );
      }

      // Check file size (5MB limit)
      const maxFileSize = 5242880; // 5MB
      if (bytes.length > maxFileSize) {
        throw Exception(
          'Image file is too large. Maximum size is 5MB. Current size: ${(bytes.length / 1048576).toStringAsFixed(2)}MB',
        );
      }

      // Determine content type
      final contentType =
          extension == 'png'
              ? 'image/png'
              : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      if (kDebugMode) {
        print('Uploading profile avatar:');
        print('  User ID: $userId');
        print('  File name: $fileName');
        print(
          '  File size: ${bytes.length} bytes (${(bytes.length / 1048576).toStringAsFixed(2)}MB)',
        );
        print('  Content type: $contentType');
        print('  Current auth user: ${currentUser.id}');
      }

      // Upload using Supabase storage API (works on both web and mobile)
      try {
        if (kIsWeb) {
          // On web, upload bytes directly
          await bucket.uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
              cacheControl: '3600',
            ),
          );
        } else {
          // On mobile, upload file
          final file = File(imageFile.path);
          await bucket.upload(
            fileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
              cacheControl: '3600',
            ),
          );
        }
      } catch (storageError) {
        // Provide more specific error messages for common storage errors
        final errorString = storageError.toString().toLowerCase();
        if (errorString.contains('bucket') ||
            errorString.contains('not found')) {
          throw Exception(
            'Storage bucket not found. Please ensure the profile-avatars bucket exists in Supabase Storage. '
            'Contact support if this issue persists.',
          );
        } else if (errorString.contains('policy') ||
            errorString.contains('permission') ||
            errorString.contains('forbidden')) {
          throw Exception(
            'Permission denied. You may not have permission to upload profile avatars. '
            'Please ensure you are logged in and try again.',
          );
        } else if (errorString.contains('size') ||
            errorString.contains('too large')) {
          throw Exception(
            'File size exceeds the limit. Maximum file size is 5MB. '
            'Please select a smaller image.',
          );
        } else if (errorString.contains('mime') ||
            errorString.contains('content type')) {
          throw Exception(
            'Invalid file type. Only JPEG, PNG, and WebP images are supported.',
          );
        } else {
          // Re-throw with additional context
          throw Exception(
            'Storage upload failed: ${storageError.toString()}. '
            'Please check your internet connection and try again.',
          );
        }
      }

      // Get public URL
      final publicUrl = bucket.getPublicUrl(fileName);

      if (kDebugMode) {
        print('Profile avatar uploaded successfully');
        print('File name: $fileName');
        print('Public URL: $publicUrl');
      }

      if (publicUrl.isEmpty) {
        throw Exception('Failed to generate public URL for uploaded avatar.');
      }

      return publicUrl;
    } catch (e) {
      // If it's already a formatted Exception with user-friendly message, re-throw it
      if (e is Exception &&
          !e.toString().contains('Failed to upload profile avatar')) {
        rethrow;
      }

      if (kDebugMode) {
        print('Error uploading profile avatar: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      throw Exception('Failed to upload profile avatar: ${e.toString()}');
    }
  }
}
