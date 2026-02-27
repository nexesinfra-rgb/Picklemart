# Profile Table Setup Guide

## Overview

This guide explains how to set up the profiles table in Supabase and use the CRUD operations from the profile screen.

## Step 1: Create the Profiles Table

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `okjuhvgavbcbbnzvvyxc`
3. Navigate to **SQL Editor**
4. Copy and paste the contents of `supabase_migrations/001_create_profiles_table.sql`
5. Click **Run** to execute the migration

This will create:

- The `profiles` table with all required fields
- Indexes for better query performance
- Row Level Security (RLS) policies
- Automatic `updated_at` trigger

## Step 2: Verify Table Creation

1. Go to **Table Editor** in Supabase Dashboard
2. You should see the `profiles` table listed
3. Verify the columns match the schema:
   - `id` (UUID, Primary Key)
   - `name` (TEXT, NOT NULL)
   - `email` (TEXT)
   - `mobile` (TEXT)
   - `display_mobile` (TEXT)
   - `avatar_url` (TEXT)
   - `role` (TEXT, DEFAULT 'user')
   - `gender` (TEXT)
   - `date_of_birth` (DATE)
   - `created_at` (TIMESTAMPTZ)
   - `updated_at` (TIMESTAMPTZ)

## Step 3: RLS Policies

The migration creates the following RLS policies:

1. **profiles_select_own**: Users can SELECT their own profile
2. **profiles_insert_own**: Users can INSERT their own profile
3. **profiles_update_own**: Users can UPDATE their own profile
4. **profiles_select_admin**: Admins can SELECT all profiles
5. **profiles_update_admin**: Admins can UPDATE all profiles

## Step 4: Using CRUD Operations

### From Profile Screen

The profile screen automatically:

- **Creates** a profile when a user signs up (via `ensureProfileExists`)
- **Reads** the current user's profile when the screen loads
- **Updates** the profile when the user edits their information
- **Deletes** the profile (if needed, via admin or user deletion)

### Available Methods

#### Create Profile

```dart
final profile = await ref.read(profileControllerProvider.notifier)
    .createProfile(
      userId: userId,
      name: 'John Doe',
      mobile: '919876543210',
      email: 'john@example.com',
    );
```

#### Read Profile

```dart
// Load current user's profile
await ref.read(profileControllerProvider.notifier).loadCurrentProfile();

// Get profile from state
final profile = ref.read(profileControllerProvider).profile;
```

#### Update Profile

```dart
await ref.read(profileControllerProvider.notifier).updateProfile(
  name: 'John Updated',
  mobile: '919876543211',
  gender: 'male',
  dateOfBirth: DateTime(1990, 1, 1),
);
```

#### Delete Profile

```dart
final success = await ref.read(profileControllerProvider.notifier).deleteProfile();
```

## Step 5: Testing

1. **Sign up a new user** - Profile should be automatically created
2. **View profile screen** - Should display user's name and mobile
3. **Edit profile** - Update name, mobile, gender, date of birth
4. **Verify in Supabase** - Check the `profiles` table in Table Editor to see the data

## Troubleshooting

### Profile not created on signup

- Check if `ensureProfileExists` is called after signup
- Verify RLS policies allow INSERT for authenticated users
- Check Supabase logs for errors

### Cannot read profile

- Verify user is authenticated
- Check RLS policies allow SELECT for the user
- Ensure profile exists in the database

### Cannot update profile

- Verify RLS policies allow UPDATE for the user
- Check that the profile ID matches the authenticated user ID
- Verify all required fields are provided

### Date format issues

- The `date_of_birth` field is stored as DATE in Supabase
- The repository automatically converts between DATE and DateTime
- Ensure dates are in YYYY-MM-DD format when stored

## Next Steps

After setting up the profiles table:

1. Test all CRUD operations
2. Set up profile edit screen to use update operations
3. Add profile image upload functionality (for `avatar_url`)
4. Implement admin features for managing all profiles













