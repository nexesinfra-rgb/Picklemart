import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../application/gst_controller.dart';
import '../data/gst_repository.dart';

class GstFormScreen extends ConsumerStatefulWidget {
  final int? editIndex;

  const GstFormScreen({super.key, this.editIndex});

  @override
  ConsumerState<GstFormScreen> createState() => _GstFormScreenState();
}

class _GstFormScreenState extends ConsumerState<GstFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gstNumberController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isDefault = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    if (widget.editIndex != null) {
      // Delay loading data until after build to access ref safely
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGstData();
      });
    }
  }

  void _loadGstData() {
    final gstState = ref.read(gstControllerProvider);
    gstState.whenData((gstDetails) {
      if (widget.editIndex != null && widget.editIndex! < gstDetails.length) {
        final gst = gstDetails[widget.editIndex!];
        _editingId = gst.id;
        _gstNumberController.text = gst.gstNumber;
        _businessNameController.text = gst.businessName;
        _businessAddressController.text = gst.businessAddress;
        _cityController.text = gst.city;
        _stateController.text = gst.state;
        _pincodeController.text = gst.pincode;
        _emailController.text = gst.email ?? '';
        _phoneController.text = gst.phone ?? '';
        setState(() {
          _isDefault = gst.isDefault;
        });
      }
    });
  }

  @override
  void dispose() {
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

  Future<void> _saveGstDetails() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final gst = GstDetails(
        id: _editingId ?? '', // ID will be ignored for create, used for update
        userId: '', // Will be set by repository
        gstNumber: _gstNumberController.text,
        businessName: _businessNameController.text,
        businessAddress: _businessAddressController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        isDefault: _isDefault,
        createdAt: DateTime.now(), // Will be ignored/set by DB
        updatedAt: DateTime.now(), // Will be ignored/set by DB
      );

      if (widget.editIndex != null && _editingId != null) {
        await ref.read(gstControllerProvider.notifier).updateGstDetails(gst);
      } else {
        await ref.read(gstControllerProvider.notifier).addGstDetails(gst);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editIndex != null
                  ? 'GST details updated'
                  : 'GST details added',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving GST details: $e')),
        );
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
    final isEditing = widget.editIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit GST Details' : 'Add GST Details'),
        actions: [
          TextButton(onPressed: _saveGstDetails, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Ionicons.information_circle_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'GST details are used for generating tax invoices',
                          style: TextStyle(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // GST Number Field
              TextFormField(
                controller: _gstNumberController,
                decoration: const InputDecoration(
                  labelText: 'GST Number',
                  prefixIcon: Icon(Ionicons.document_text_outline),
                  hintText: 'Enter 15-digit GST number',
                  helperText: 'Format: 22AAAAA0000A1Z5',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 15,
                validator: _validateGstNumber,
                onChanged: (value) {
                  // Auto-format to uppercase
                  final cursorPosition =
                      _gstNumberController.selection.baseOffset;
                  _gstNumberController
                      .value = _gstNumberController.value.copyWith(
                    text: value.toUpperCase(),
                    selection: TextSelection.collapsed(offset: cursorPosition),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Business Name Field
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  prefixIcon: Icon(Ionicons.business_outline),
                  hintText: 'Enter registered business name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Business Address Field
              TextFormField(
                controller: _businessAddressController,
                decoration: const InputDecoration(
                  labelText: 'Business Address',
                  prefixIcon: Icon(Ionicons.location_outline),
                  hintText: 'Enter registered business address',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter business address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // City and State Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Ionicons.business_outline),
                        hintText: 'Enter city',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter city';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Ionicons.flag_outline),
                        hintText: 'Enter state',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter state';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pincode Field
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(
                  labelText: 'Pincode',
                  prefixIcon: Icon(Ionicons.mail_outline),
                  hintText: 'Enter pincode',
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter pincode';
                  }
                  if (value.length != 6) {
                    return 'Please enter a valid 6-digit pincode';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field (Optional)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Business Email (Optional)',
                  prefixIcon: Icon(Ionicons.mail_outline),
                  hintText: 'Enter business email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field (Optional)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Business Phone (Optional)',
                  prefixIcon: Icon(Ionicons.call_outline),
                  hintText: 'Enter business phone number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Default GST Toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Set as default GST'),
                  subtitle: const Text(
                    'This will be used for generating invoices',
                  ),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value;
                    });
                  },
                  secondary: const Icon(Ionicons.star_outline),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ResponsiveFilledButton(
                onPressed: _saveGstDetails,
                child: Text(
                  isEditing ? 'Update GST Details' : 'Save GST Details',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
