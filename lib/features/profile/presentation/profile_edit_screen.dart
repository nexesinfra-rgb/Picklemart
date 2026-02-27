import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:picklemart/features/auth/data/auth_repository.dart';
import 'package:picklemart/features/profile/application/profile_controller.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    print('DEBUG: _loadUserData called');

    // Check authentication state
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    final currentSession = authRepo.getCurrentSession();

    print('DEBUG: Current user: ${currentUser?.id} - ${currentUser?.email}');
    print('DEBUG: Current session: ${currentSession?.user.id}');

    if (currentUser == null) {
      print('DEBUG: No authenticated user found');
      return;
    }

    try {
      // Use ProfileRepository to get current user profile
      final profileController = ref.read(profileControllerProvider.notifier);
      await profileController.loadCurrentProfile();

      final profile = ref.read(currentProfileProvider);
      print('DEBUG: Profile loaded: ${profile?.name} - ${profile?.mobile}');

      if (profile != null) {
        setState(() {
          _nameController.text = profile.name;
          _mobileController.text = profile.mobile ?? '';
          _emailController.text = profile.email ?? '';
          _selectedGender = profile.gender;
          _selectedDateOfBirth = profile.dateOfBirth;
        });
        print('DEBUG: Form fields populated with profile data');
      } else {
        print('DEBUG: No profile data available');
      }
    } catch (e) {
      print('DEBUG: Error loading profile: $e');
    }
  }

  bool _isLoading = false;

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }

    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profileController = ref.read(profileControllerProvider.notifier);

      // Update the profile using ProfileController
      await profileController.updateProfile(
        name: _nameController.text.trim(),
        mobile:
            _mobileController.text.trim().isEmpty
                ? null
                : _mobileController.text.trim(),
        email:
            _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
        gstNumber:
            _gstController.text.trim().isEmpty
                ? null
                : _gstController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: _selectedDateOfBirth,
      );

      // Reload profile to ensure we have the latest data from database
      await profileController.loadCurrentProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    final sectionSpacing = Responsive.getSectionSpacing(width);

    return SafeScaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(cardPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      _buildSectionHeader(
                        context,
                        'Personal Information',
                        Ionicons.person_outline,
                      ),
                      SizedBox(height: cardPadding * 0.75),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: const Icon(
                                    Ionicons.person_outline,
                                  ),
                                  filled: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: cardPadding * 0.75),
                              TextFormField(
                                controller: _mobileController,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile Number',
                                  prefixIcon: Icon(Ionicons.call_outline),
                                  filled: true,
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: cardPadding * 0.75),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Ionicons.mail_outline),
                                  hintText: 'Enter your email address',
                                  filled: true,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                              SizedBox(height: cardPadding * 0.75),
                              TextFormField(
                                controller: _gstController,
                                decoration: const InputDecoration(
                                  labelText: 'GST Number',
                                  prefixIcon: Icon(Ionicons.receipt_outline),
                                  hintText: 'Enter your GST number',
                                  filled: true,
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: sectionSpacing),

                      // Additional Information Section
                      _buildSectionHeader(
                        context,
                        'Additional Information',
                        Ionicons.information_circle_outline,
                      ),
                      SizedBox(height: cardPadding * 0.75),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: _selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  prefixIcon: Icon(Ionicons.people_outline),
                                  filled: true,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text('Female'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'others',
                                    child: Text('Others'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'prefer_not_to_say',
                                    child: Text('Prefer not to say'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                              ),
                              SizedBox(height: cardPadding * 0.75),
                              InkWell(
                                onTap: _selectDateOfBirth,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date of Birth',
                                    prefixIcon: Icon(Ionicons.calendar_outline),
                                    filled: true,
                                    suffixIcon: Icon(Ionicons.chevron_down),
                                  ),
                                  child: Text(
                                    _selectedDateOfBirth != null
                                        ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                                        : 'Select date of birth',
                                    style:
                                        _selectedDateOfBirth != null
                                            ? null
                                            : TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: sectionSpacing * 1.5),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _saveProfile,
                          icon:
                              _isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(Ionicons.checkmark_outline),
                          label: Text(
                            _isLoading ? 'Saving...' : 'Save Profile',
                          ),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: cardPadding * 0.75,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
