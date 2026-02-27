import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import 'package:openstreetmap_location_picker/openstreetmap_location_picker.dart';
import '../application/address_controller.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final String? editAddressId;

  const AddressFormScreen({super.key, this.editAddressId});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _notesController = TextEditingController();

  LatLng? _selectedLocation;
  String? _selectedLocationAddress;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.editAddressId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAddressData();
      });
    }
  }

  void _loadAddressData() {
    final addressState = ref.read(addressControllerProvider);
    final address = addressState.addresses.firstWhere(
      (a) => a.id == widget.editAddressId,
      orElse: () => throw Exception('Address not found'),
    );
    
    _nameController.text = address.name;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _pincodeController.text = address.pincode;
    _notesController.text = address.notes ?? '';
    _selectedLocation = address.coordinates;
    _selectedLocationAddress = address.fullAddress;
    _isDefault = address.isDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final addressController = ref.read(addressControllerProvider.notifier);
    final addressState = ref.read(addressControllerProvider);
    final isEditing = widget.editAddressId != null;

    // Check if user already has an address when trying to create a new one
    if (!isEditing && addressState.addresses.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only have one address. Please edit your existing address.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      if (isEditing) {
        // Update existing address
        final addressState = ref.read(addressControllerProvider);
        final existingAddress = addressState.addresses.firstWhere(
          (a) => a.id == widget.editAddressId,
        );

        final updatedAddress = existingAddress.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          coordinates: _selectedLocation,
          isDefault: _isDefault,
          updatedAt: DateTime.now(),
        );

        final result = await addressController.updateAddress(updatedAddress);
        if (mounted) {
          if (result != null) {
            // Refresh addresses to ensure UI updates immediately
            await addressController.refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address updated'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else {
            final error = ref.read(addressControllerProvider).error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error ?? 'Failed to update address'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Create new address
        final result = await addressController.createAddress(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          stateValue: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          coordinates: _selectedLocation,
          isDefault: _isDefault,
        );
        if (mounted) {
          if (result != null) {
            // Refresh addresses to ensure UI updates immediately
            await addressController.refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address added'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else {
            final error = ref.read(addressControllerProvider).error;
            // Show user-friendly error message
            String errorMessage = error ?? 'Failed to add address';
            if (errorMessage.contains('only have one address') || 
                errorMessage.contains('unique') || 
                errorMessage.contains('duplicate')) {
              errorMessage = 'You can only have one address. Please edit your existing address.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onLocationSelected(LatLng location, String address) {
    setState(() {
      _selectedLocation = location;
      _selectedLocationAddress = address;
    });
  }

  void _onLocationCleared() {
    setState(() {
      _selectedLocation = null;
      _selectedLocationAddress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressControllerProvider);
    final isEditing = widget.editAddressId != null;
    final width = MediaQuery.of(context).size.width;
    final cardPadding = Responsive.getCardPadding(width);
    final sectionSpacing = Responsive.getSectionSpacing(width);

    return SafeScaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Address'),
        actions: [
          TextButton.icon(
            onPressed: _saveAddress,
            icon: const Icon(Ionicons.checkmark_outline),
            label: const Text('Save'),
          ),
        ],
      ),
      body: addressState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(cardPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Contact Information Section
                    _buildSectionHeader(context, 'Contact Information', Ionicons.person_outline),
                    SizedBox(height: cardPadding * 0.75),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Ionicons.person_outline),
                                hintText: 'Enter full name',
                                filled: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: cardPadding * 0.75),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Ionicons.call_outline),
                                hintText: 'Enter 10-digit phone number',
                                filled: true,
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
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing),

                    // Address Details Section
                    _buildSectionHeader(context, 'Address Details', Ionicons.location_outline),
                    SizedBox(height: cardPadding * 0.75),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                prefixIcon: Icon(Ionicons.location_outline),
                                hintText: 'Enter street address',
                                filled: true,
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter the address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: cardPadding * 0.75),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                      prefixIcon: Icon(Ionicons.business_outline),
                                      hintText: 'Enter city',
                                      filled: true,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Enter city';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: cardPadding * 0.75),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stateController,
                                    decoration: const InputDecoration(
                                      labelText: 'State',
                                      prefixIcon: Icon(Ionicons.flag_outline),
                                      hintText: 'Enter state',
                                      filled: true,
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
                            SizedBox(height: cardPadding * 0.75),
                            TextFormField(
                              controller: _pincodeController,
                              decoration: const InputDecoration(
                                labelText: 'Pincode',
                                prefixIcon: Icon(Ionicons.mail_outline),
                                hintText: 'Enter 6-digit pincode',
                                filled: true,
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
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
                            SizedBox(height: cardPadding * 0.75),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes (Optional)',
                                prefixIcon: Icon(Ionicons.document_text_outline),
                                hintText: 'Any additional notes for delivery',
                                filled: true,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing),

                    // Additional Options Section
                    _buildSectionHeader(context, 'Additional Options', Ionicons.options_outline),
                    SizedBox(height: cardPadding * 0.75),
                    Card(
                      elevation: 2,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.all(cardPadding),
                        title: Text(
                          'Set as default address',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'This will be used as the primary delivery address',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        value: _isDefault,
                        onChanged: (value) {
                          setState(() {
                            _isDefault = value;
                          });
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Ionicons.star_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing),

                    // Location Picker Section
                    _buildSectionHeader(context, 'Location on Map', Ionicons.map_outline),
                    SizedBox(height: cardPadding * 0.75),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final location = await showLocationPicker(
                                  context: context,
                                  initialLocation: _selectedLocation != null
                                      ? LocationData(
                                          latitude: _selectedLocation!.latitude,
                                          longitude: _selectedLocation!.longitude,
                                        )
                                      : null,
                                  restrictToIndia: true,
                                );

                                if (location != null) {
                                  _onLocationSelected(
                                    LatLng(location.latitude, location.longitude),
                                    location.displayAddress,
                                  );
                                  // Optionally auto-populate address fields if available
                                  if (location.address != null &&
                                      _addressController.text.isEmpty) {
                                    _addressController.text = location.address!;
                                  }
                                  if (location.city != null && _cityController.text.isEmpty) {
                                    _cityController.text = location.city!;
                                  }
                                }
                              },
                              icon: const Icon(Ionicons.map_outline),
                              label: Text(
                                _selectedLocation != null
                                    ? 'Change Location'
                                    : 'Select Location on Map',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: cardPadding * 0.75),
                              ),
                            ),
                            if (_selectedLocation != null) ...[
                              SizedBox(height: cardPadding * 0.75),
                              Container(
                                padding: EdgeInsets.all(cardPadding * 0.75),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Ionicons.location,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                    SizedBox(width: cardPadding * 0.5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Selected Location',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: cardPadding * 0.25),
                                          Text(
                                            _selectedLocationAddress ?? 'Location selected',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Ionicons.close_outline, size: 20),
                                      onPressed: _onLocationCleared,
                                      tooltip: 'Clear location',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing * 1.5),

                    // Save Button
                    FilledButton.icon(
                      onPressed: _saveAddress,
                      icon: const Icon(Ionicons.checkmark_outline),
                      label: Text(isEditing ? 'Update Address' : 'Save Address'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: cardPadding * 0.75),
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
