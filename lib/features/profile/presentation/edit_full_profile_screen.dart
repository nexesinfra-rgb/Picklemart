import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../application/profile_controller.dart';
import '../application/address_controller.dart';
import '../data/gst_repository.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';

class EditFullProfileScreen extends ConsumerStatefulWidget {
  const EditFullProfileScreen({super.key});

  @override
  ConsumerState<EditFullProfileScreen> createState() =>
      _EditFullProfileScreenState();
}

class _EditFullProfileScreenState extends ConsumerState<EditFullProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();

  bool _isLoading = false;

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
    final profileState = ref.read(profileControllerProvider);
    final profile = profileState.profile;

    // Load GST Number
    final gst =
        await ref.read(profileControllerProvider.notifier).getGstNumber();
    if (gst != null && mounted) {
      _gstController.text = gst;
    }

    if (profile != null) {
      setState(() {
        _nameController.text = profile.name;
        _mobileController.text = profile.mobile ?? '';
        _emailController.text = profile.email ?? '';
      });
    } else {
      await ref.read(profileControllerProvider.notifier).loadCurrentProfile();
      final updatedProfile = ref.read(profileControllerProvider).profile;
      if (updatedProfile != null) {
        setState(() {
          _nameController.text = updatedProfile.name;
          _mobileController.text = updatedProfile.mobile ?? '';
          _emailController.text = updatedProfile.email ?? '';
        });
      }
    }
  }

  Future<void> _saveBasicDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(
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
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Basic details updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    final sectionSpacing = Responsive.getSectionSpacing(width);

    // Watch address and GST state
    final addressState = ref.watch(addressControllerProvider);
    final gstDetails = ref.watch(savedGstDetailsProvider);

    return SafeScaffold(
      appBar: AppBar(title: const Text('Edit Full Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Details
            _buildSectionHeader(
              context,
              'Basic Details',
              Ionicons.person_outline,
            ),
            SizedBox(height: cardPadding * 0.75),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Ionicons.person_outline),
                        ),
                        validator:
                            (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: Icon(Ionicons.call_outline),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Ionicons.mail_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gstController,
                        decoration: const InputDecoration(
                          labelText: 'GST Number',
                          prefixIcon: Icon(Ionicons.receipt_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ResponsiveFilledButton(
                        onPressed: _isLoading ? null : _saveBasicDetails,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Save Basic Details'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: sectionSpacing),

            // Addresses
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  context,
                  'Addresses',
                  Ionicons.location_outline,
                ),
                IconButton(
                  onPressed: () => context.pushNamed('profile-address-add'),
                  icon: const Icon(Ionicons.add_circle_outline, size: 28),
                  tooltip: 'Add Address',
                ),
              ],
            ),
            SizedBox(height: cardPadding * 0.75),
            if (addressState.addresses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No addresses found.'),
                ),
              )
            else
              ...addressState.addresses.map(
                (addr) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(addr.name),
                    subtitle: Text(
                      '${addr.address}, ${addr.city}, ${addr.state} - ${addr.pincode}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Ionicons.create_outline),
                      onPressed:
                          () => context.pushNamed(
                            'profile-address-edit',
                            pathParameters: {'id': addr.id},
                          ),
                    ),
                  ),
                ),
              ),
          ],
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
