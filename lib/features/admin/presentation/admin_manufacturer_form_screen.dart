import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../application/manufacturer_controller.dart';
import '../application/admin_customer_controller.dart';
import '../application/admin_dashboard_controller.dart';
import '../domain/manufacturer.dart';
import '../data/manufacturer_repository.dart';
import '../../../core/providers/supabase_provider.dart';

class AdminManufacturerFormScreen extends ConsumerStatefulWidget {
  final String? manufacturerId;

  const AdminManufacturerFormScreen({super.key, this.manufacturerId});

  @override
  ConsumerState<AdminManufacturerFormScreen> createState() =>
      _AdminManufacturerFormScreenState();
}

class _AdminManufacturerFormScreenState
    extends ConsumerState<AdminManufacturerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.manufacturerId != null) {
      _loadManufacturerData();
    }
  }

  Future<void> _loadManufacturerData() async {
    if (!_isInitialized && widget.manufacturerId != null) {
      setState(() => _isLoading = true);
      try {
        // First try to load from controller state
        final manufacturers =
            ref.read(manufacturerControllerProvider).manufacturers;
        Manufacturer? manufacturer;

        if (manufacturers.isNotEmpty) {
          try {
            manufacturer = manufacturers.firstWhere(
              (m) => m.id == widget.manufacturerId,
            );
          } catch (e) {
            // Not in state, need to load from repository
            manufacturer = null;
          }
        }

        // If not in state, load from repository
        if (manufacturer == null) {
          final repository = ManufacturerRepository(
            ref.read(supabaseClientProvider),
          );
          manufacturer = await repository.getManufacturerById(
            widget.manufacturerId!,
          );
        }

        if (manufacturer != null) {
          _nameController.text = manufacturer.name;
          _gstNumberController.text = manufacturer.gstNumber;
          _businessNameController.text = manufacturer.businessName;
          _businessAddressController.text = manufacturer.businessAddress;
          _cityController.text = manufacturer.city;
          _stateController.text = manufacturer.state;
          _pincodeController.text = manufacturer.pincode;
          _emailController.text = manufacturer.email ?? '';
          _phoneController.text = manufacturer.phone ?? '';
          _isActive = manufacturer.isActive;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Manufacturer not found')),
            );
            context.pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load manufacturer: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isInitialized = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gstNumberController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveManufacturer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Auto-generate values for hidden fields to satisfy DB constraints
      String gstNumber = _gstNumberController.text.trim();
      if (gstNumber.isEmpty) {
        // Generate a unique dummy GST: NA-TIMESTAMP-RANDOM
        gstNumber = 'NA-${DateTime.now().millisecondsSinceEpoch}';
      }

      final manufacturer = Manufacturer(
        id: widget.manufacturerId ?? '',
        name: _businessNameController.text.trim(), // Use Business Name as Name
        gstNumber: gstNumber,
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        city: 'Not Provided',
        state: 'Not Provided',
        pincode: '000000',
        email: null,
        phone: _phoneController.text.trim(),
        isActive: _isActive,
      );

      final controller = ref.read(manufacturerControllerProvider.notifier);
      final success =
          widget.manufacturerId != null
              ? await controller.updateManufacturer(manufacturer)
              : await controller.createManufacturer(manufacturer);

      if (success && mounted) {
        // Refresh customer list to include new manufacturer in dashboard
        ref.read(adminCustomerControllerProvider.notifier).refresh();

        // Also refresh dashboard data if possible
        try {
          ref.read(adminDashboardControllerProvider.notifier).refresh();
        } catch (e) {
          // Ignore if dashboard controller doesn't have refresh or isn't initialized
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Success'),
                content: const Text(
                  'i created this manufacturer and reload here',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/admin/dashboard');
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else if (mounted) {
        final state = ref.read(manufacturerControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error ?? 'Failed to save manufacturer')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateGstNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter GST number';
    }

    // Remove any spaces or dashes
    final cleanGst = value.replaceAll(RegExp(r'[\s-]'), '');

    // GST format: 15 characters
    // Format: 22AAAAA0000A1Z5
    // First 2: State code
    // Next 10: PAN
    // Next 1: Entity number
    // Next 1: Z (default)
    // Last 1: Checksum
    if (cleanGst.length != 15) {
      return 'GST number must be 15 characters';
    }

    // First 2 characters should be digits
    if (!RegExp(r'^[0-9]{2}').hasMatch(cleanGst)) {
      return 'Invalid GST format - first 2 characters must be digits';
    }

    // Next 10 characters: 5 letters + 4 digits + 1 letter
    if (!RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}',
    ).hasMatch(cleanGst.substring(0, 12))) {
      return 'Invalid GST format';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);
    final isEditing = widget.manufacturerId != null;

    if (_isLoading && !_isInitialized) {
      return AdminAuthGuard(
        child: AdminScaffold(
          title: isEditing ? 'Edit Party' : 'Add Party',
          showBackButton: true,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AdminAuthGuard(
      child: AdminScaffold(
        title: isEditing ? 'Edit Party' : 'Add Party',
        showBackButton: true,
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Name
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Ionicons.briefcase_outline),
                    hintText: 'Enter registered business name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter business name';
                    }
                    if (value.trim().length < 2) {
                      return 'Business name must be at least 2 characters';
                    }
                    if (value.trim().length > 200) {
                      return 'Business name must be less than 200 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: spacing),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Ionicons.call_outline),
                    hintText: 'Enter 10-digit phone number',
                    helperText: 'Format: 10 digits (e.g., 9876543210)',
                    counterText: '',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digitsOnly.length != 10) {
                      return 'Phone number must be exactly 10 digits';
                    }
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digitsOnly)) {
                      return 'Invalid phone number. Must start with 6, 7, 8, or 9';
                    }
                    return null;
                  },
                ),
                SizedBox(height: spacing),

                // Business Address
                TextFormField(
                  controller: _businessAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Business Address *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Ionicons.location_outline),
                    hintText: 'Enter complete business address',
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter business address';
                    }
                    if (value.trim().length < 10) {
                      return 'Business address must be at least 10 characters';
                    }
                    if (value.trim().length > 500) {
                      return 'Business address must be less than 500 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: spacing * 2),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ResponsiveFilledButton(
                    onPressed: _isLoading ? null : _saveManufacturer,
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(
                              isEditing
                                  ? 'Update Party'
                                  : 'Create Party',
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
