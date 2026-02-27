import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/address_controller.dart';
import '../../profile/data/address_repository.dart';
import '../../orders/application/order_controller.dart';
import '../../orders/data/order_model.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/data/orders_infinite_scroll_provider.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/providers/supabase_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:openstreetmap_location_picker/openstreetmap_location_picker.dart';
import 'package:picklemart/openstreetmap_location_picker/lib/src/services/geocoding_service.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/ui/address_map_view.dart';

class CheckoutAddressScreen extends ConsumerStatefulWidget {
  const CheckoutAddressScreen({super.key});

  @override
  ConsumerState<CheckoutAddressScreen> createState() =>
      _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends ConsumerState<CheckoutAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _notesController = TextEditingController();
  LatLng? _selectedLatLng;
  Uint8List? _shopPhoto;
  XFile? _shopPhotoFile;
  final _picker = ImagePicker();
  String? _selectedAddressId;
  final ScrollController _scrollController = ScrollController();
  String? _reverseGeocodedAddress;
  bool _isLoadingAddress = false;
  final Debouncer _reverseGeocodeDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  bool _hasAutoSelected = false;

  @override
  void initState() {
    super.initState();
    // Auto-select address after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectAddress();
    });
  }

  void _autoSelectAddress() {
    if (_hasAutoSelected) return; // Only auto-select once
    
    final addressState = ref.read(addressControllerProvider);
    final saved = addressState.addresses;
    
    // Only auto-select if no address is currently selected and addresses are available
    if (_selectedAddressId == null && saved.isNotEmpty) {
      // Find default address first, otherwise use first address
      int index = 0;
      final defaultIndex = saved.indexWhere((a) => a.isDefault);
      if (defaultIndex != -1) {
        index = defaultIndex;
      }
      
      _hasAutoSelected = true;
      _selectSavedAddress(index, saved);
    }
  }

  Address? _getSelectedAddress() {
    if (_selectedAddressId == null) return null;
    
    final addressState = ref.read(addressControllerProvider);
    try {
      return addressState.addresses.firstWhere(
        (a) => a.id == _selectedAddressId,
      );
    } catch (e) {
      return null;
    }
  }

  void _selectSavedAddress(int index, List<Address> saved) {
    final a = saved[index];
    
    // Clear form validation errors
    _formKey.currentState?.reset();
    
    // Set selected address ID
    _selectedAddressId = a.id;
    
    // Populate all form fields
    _nameController.text = a.name;
    _phoneController.text = a.phone;
    _addressController.text = a.address;
    _cityController.text = a.city;
    _stateController.text = a.state;
    _pincodeController.text = a.pincode;
    _notesController.text = a.notes ?? '';
    _selectedLatLng = a.coordinates;
    
    // Fetch address from coordinates
    if (_selectedLatLng != null) {
      _fetchAddressFromCoordinates();
    }
    
    // Update UI
    setState(() {});
    
    // Scroll to show the form fields after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildAddressCard(Address address) {
    final width = MediaQuery.of(context).size.width;
    final cardPadding = 16.0; // Using fixed padding for consistency
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Ionicons.location,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Default',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Ionicons.call_outline,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            address.phone,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                address.fullAddress,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            if (address.coordinates != null) ...[
              const SizedBox(height: 16),
              Text(
                'Location on Map',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              AddressMapView(
                location: address.coordinates!,
                addressText: address.fullAddress,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAddressFromCoordinates() async {
    if (!mounted) return;
    
    if (_selectedLatLng == null) {
      _reverseGeocodedAddress = null;
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
      return;
    }

    // Store current coordinates to ensure we use the latest values when debounced execution happens
    final currentLat = _selectedLatLng!.latitude;
    final currentLng = _selectedLatLng!.longitude;

    // Show loading state immediately
    if (mounted) {
      setState(() {
        _isLoadingAddress = true;
        _reverseGeocodedAddress = null;
      });
    }

    // Debounce the API call to prevent excessive requests
    if (mounted) {
      _reverseGeocodeDebouncer.debounce(() async {
        // Check if widget is still mounted before proceeding
        if (!mounted) return;
        
        // Double-check coordinates are still valid and haven't changed
        if (_selectedLatLng == null || 
            _selectedLatLng!.latitude != currentLat || 
            _selectedLatLng!.longitude != currentLng) {
          if (mounted) {
            setState(() {
              _isLoadingAddress = false;
            });
          }
          return;
        }

        try {
          final result = await GeocodingService.reverseGeocode(
            currentLat,
            currentLng,
          );

          if (mounted && 
              _selectedLatLng != null && 
              _selectedLatLng!.latitude == currentLat && 
              _selectedLatLng!.longitude == currentLng) {
            setState(() {
              _isLoadingAddress = false;
              _reverseGeocodedAddress = result?.displayName;
            });
          }
        } catch (e) {
          // If reverse geocoding fails, fallback to coordinates
          if (mounted && 
              _selectedLatLng != null && 
              _selectedLatLng!.latitude == currentLat && 
              _selectedLatLng!.longitude == currentLng) {
            setState(() {
              _isLoadingAddress = false;
              _reverseGeocodedAddress = null;
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _reverseGeocodeDebouncer.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Validate if a URL string is a valid HTTP/HTTPS URL
  /// Returns the trimmed URL if valid, null otherwise
  static String? _validateShopPhotoUrl(String? url) {
    if (url == null) return null;
    
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return null;
    
    // Must start with http:// or https://
    if (!trimmedUrl.startsWith('http://') &&
        !trimmedUrl.startsWith('https://')) {
      return null;
    }
    
    // Basic URL format validation - must have at least http://domain
    try {
      final uri = Uri.parse(trimmedUrl);
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return trimmedUrl;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Invalid URL format: $trimmedUrl - $e');
      }
      return null;
    }
    
    return null;
  }

  /// Upload shop photo to Supabase Storage
  Future<String?> _uploadShopPhoto() async {
    if (_shopPhoto == null || _shopPhotoFile == null) {
      if (kDebugMode) {
        print('⚠️ Shop photo upload skipped: No photo selected');
      }
      return null;
    }

    try {
      if (kDebugMode) {
        print('📸 Starting shop photo upload...');
        print('   File name: ${_shopPhotoFile!.name}');
        print('   File size: ${(_shopPhoto!.length / 1024).toStringAsFixed(2)} KB');
      }

      // Get user ID
      final authState = ref.read(authControllerProvider);
      if (!authState.isAuthenticated || authState.userId == null) {
        final error = 'User not authenticated';
        if (kDebugMode) {
          print('❌ Shop photo upload failed: $error');
        }
        throw Exception(error);
      }
      final userId = authState.userId!;

      if (kDebugMode) {
        print('   User ID: $userId');
      }

      final supabase = ref.read(supabaseClientProvider);
      final bucket = supabase.storage.from('delivery-photos');

      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String extension = 'jpg';
      final fileName = _shopPhotoFile!.name;
      if (fileName.contains('.')) {
        extension = fileName.split('.').last.toLowerCase();
      }
      // Ensure extension is valid
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        extension = 'jpg';
      }
      // Use userId + timestamp for path (will be organized later if needed)
      final storagePath = 'orders/$userId/${timestamp}_shop.$extension';

      if (kDebugMode) {
        print('   Storage path: $storagePath');
      }

      // Determine content type
      final contentType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      // Check file size (5MB limit)
      const maxFileSize = 5242880; // 5MB
      if (_shopPhoto!.length > maxFileSize) {
        final errorMessage = 'Shop photo is too large. Maximum size is 5MB. Current size: ${(_shopPhoto!.length / 1048576).toStringAsFixed(2)}MB';
        if (kDebugMode) {
          print('❌ Shop photo upload failed: $errorMessage');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      // Upload to Supabase Storage
      if (kDebugMode) {
        print('   Uploading to Supabase Storage (${kIsWeb ? 'Web' : 'Mobile'})...');
      }

      if (kIsWeb) {
        // On web, use uploadBinary with bytes directly
        await bucket.uploadBinary(
          storagePath,
          _shopPhoto!,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
            cacheControl: '3600',
          ),
        );
      } else {
        // On mobile, write bytes to temp file and upload
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/${timestamp}_shop.$extension');
        await tempFile.writeAsBytes(_shopPhoto!);
        
        try {
          await bucket.upload(
            storagePath,
            tempFile,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
              cacheControl: '3600',
            ),
          );
        } finally {
          // Clean up temp file
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }

      if (kDebugMode) {
        print('✅ Shop photo uploaded successfully');
      }

      // Get public URL
      final publicUrl = bucket.getPublicUrl(storagePath);
      
      if (kDebugMode) {
        print('   Public URL: $publicUrl');
        print('✅ Shop photo upload completed successfully');
      }

      return publicUrl;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error uploading shop photo: $e');
        print('   Stack trace: $stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload shop photo: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _confirmOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Upload shop photo first if present
    String? shopPhotoUrl;
    if (_shopPhoto != null && _shopPhotoFile != null) {
      if (mounted) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      try {
        final uploadedUrl = await _uploadShopPhoto();
        
        // Validate the uploaded URL using helper function
        shopPhotoUrl = _validateShopPhotoUrl(uploadedUrl);
        
        if (shopPhotoUrl != null) {
          if (kDebugMode) {
            print('✅ Shop photo URL obtained and validated: $shopPhotoUrl');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Shop photo URL invalid or empty: ${uploadedUrl ?? 'null'}');
          }
          if (uploadedUrl != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Shop photo uploaded but URL format is invalid. Photo will not be saved.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error during shop photo upload: $e');
        }
        shopPhotoUrl = null; // Don't save if upload failed
      } finally {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }
      }
    } else {
      if (kDebugMode) {
        print('ℹ️ No shop photo to upload');
      }
    }

    // Validate shopPhotoUrl one more time before creating OrderAddress
    final validShopPhotoUrl = _validateShopPhotoUrl(shopPhotoUrl);

    // Create delivery address from selected address or form data
    final selectedAddress = _getSelectedAddress();
    final deliveryAddress = selectedAddress != null
        ? OrderAddress(
            name: selectedAddress.name,
            phone: selectedAddress.phone,
            address: selectedAddress.address,
            city: selectedAddress.city,
            state: selectedAddress.state,
            pincode: selectedAddress.pincode,
            shopPhotoUrl: validShopPhotoUrl,
          )
        : OrderAddress(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            pincode: _pincodeController.text.trim(),
            shopPhotoUrl: validShopPhotoUrl,
          );

    if (kDebugMode) {
      print('📦 Creating order with delivery address:');
      print('   Name: ${deliveryAddress.name}');
      print('   Shop Photo URL: ${deliveryAddress.shopPhotoUrl ?? 'None'}');
      if (deliveryAddress.shopPhotoUrl != null) {
        print('   Shop Photo URL length: ${deliveryAddress.shopPhotoUrl!.length}');
        print('   Shop Photo URL valid: ${deliveryAddress.shopPhotoUrl!.startsWith('http')}');
      }
    }

    // Optionally save address if not selected from saved addresses
    if (_selectedAddressId == null) {
      final addressController = ref.read(addressControllerProvider.notifier);
      try {
        await addressController.createAddress(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          stateValue: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          coordinates: _selectedLatLng,
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          isDefault: false,
        );
      } catch (e) {
        // Continue with order creation even if address save fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Address saved, but order may fail: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }

    // Create order (shopPhotoUrl is already in deliveryAddress)
    // Use coordinates from selected address or manually selected location
    final coordinatesForNotes = selectedAddress?.coordinates ?? _selectedLatLng;
    final order = await ref
        .read(orderControllerProvider.notifier)
        .createOrderFromCart(
          deliveryAddress: deliveryAddress,
          notes:
              coordinatesForNotes != null
                  ? 'Location: Lat ${coordinatesForNotes.latitude.toStringAsFixed(6)}, Lng ${coordinatesForNotes.longitude.toStringAsFixed(6)}'
                  : null,
        );

    if (order != null) {
      ref.invalidate(userOrdersProvider);
      ref.read(ordersInfiniteScrollProvider.notifier).refresh();

      // Show success SnackBar for payment confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! Order #${order.orderNumber} placed.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to confirmation page after a brief delay so user sees the success message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.goNamed('order-confirmation', pathParameters: {'orderId': order.id});
        }
      }
    } else {
      // Show error if order creation failed
      final orderState = ref.read(orderControllerProvider);
      if (mounted && orderState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order creation failed: ${orderState.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressControllerProvider);
    final saved = addressState.addresses;
    final selectedAddress = _getSelectedAddress();
    
    // Listen for address state changes to auto-select when addresses load asynchronously
    ref.listen<AddressState>(addressControllerProvider, (previous, next) {
      // Auto-select address when addresses become available
      if (!_hasAutoSelected && 
          next.addresses.isNotEmpty && 
          _selectedAddressId == null &&
          !next.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoSelectAddress();
        });
      }
    });
    
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Address')),
      body: addressState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (saved.isNotEmpty) ...[
                      const Text(
                        'Saved addresses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: saved.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final isSelected = _selectedAddressId == saved[i].id;
                            return ActionChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          saved[i].name,
                                          style: TextStyle(
                                            color: isSelected 
                                                ? Colors.white 
                                                : null,
                                          ),
                                        ),
                                        if (saved[i].isDefault)
                                          Text(
                                            'Default',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected 
                                                  ? Colors.white70 
                                                  : null,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: isSelected
                                  ? Theme.of(context).primaryColor
                                  : null,
                              side: isSelected
                                  ? BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    )
                                  : null,
                              onPressed: () => _selectSavedAddress(i, saved),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Show address card if address is selected, otherwise show form
                    if (selectedAddress != null) ...[
                      _buildAddressCard(selectedAddress),
                    ] else ...[
                      if (saved.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Or enter new address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name *'),
                      validator:
                          (v) => (v == null || v.isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone number *',
                        hintText: 'Enter 10-digit phone number',
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        final digitsOnly = v.replaceAll(RegExp(r'[^0-9]'), '');
                        if (digitsOnly.length != 10) {
                          return 'Phone number must be exactly 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Street address *'),
                      maxLines: 3,
                      validator:
                          (v) => (v == null || v.isEmpty) ? 'Enter address' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City *'),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Enter city' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pincodeController,
                            decoration: const InputDecoration(
                              labelText: 'Pincode *',
                              hintText: 'Enter 6-digit pincode',
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter pincode';
                              }
                              if (v.length != 6) {
                                return 'Please enter a valid 6-digit pincode';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State *'),
                      validator:
                          (v) => (v == null || v.isEmpty) ? 'Enter state' : null,
                    ),
                    const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery notes (optional)',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Delivery location (OpenStreetMap)',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ResponsiveOutlinedButton(
                        onPressed: () async {
                          final location = await showLocationPicker(
                            context: context,
                            initialLocation: _selectedLatLng != null
                                ? LocationData(
                                    latitude: _selectedLatLng!.latitude,
                                    longitude: _selectedLatLng!.longitude,
                                  )
                                : null,
                            restrictToIndia: true,
                          );

                          if (location != null) {
                            setState(() {
                              _selectedLatLng = LatLng(
                                location.latitude,
                                location.longitude,
                              );
                              // Optionally auto-populate address fields if available
                              if (location.address != null &&
                                  _addressController.text.isEmpty) {
                                _addressController.text = location.address!;
                              }
                              if (location.city != null && _cityController.text.isEmpty) {
                                _cityController.text = location.city!;
                              }
                              if (location.country != null &&
                                  _stateController.text.isEmpty) {
                                // Some addresses might have state in country field
                                // This is a fallback, better to parse if needed
                              }
                            });
                            // Fetch address from coordinates
                            _fetchAddressFromCoordinates();
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_outlined),
                            const SizedBox(width: 8),
                            Text(
                              _selectedLatLng != null
                                  ? 'Change Location'
                                  : 'Select Location',
                            ),
                          ],
                        ),
                      ),
                      if (_selectedLatLng != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _isLoadingAddress
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Loading address...',
                                            style: TextStyle(
                                              color: Colors.blue.shade900,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _reverseGeocodedAddress ??
                                            'Lat: ${_selectedLatLng!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLatLng!.longitude.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          color: Colors.blue.shade900,
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Optional: Upload shop photo',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ResponsiveOutlinedButton(
                              onPressed: () async {
                                final x = await _picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1600,
                                  imageQuality: 85,
                                );
                                if (x != null) {
                                  final bytes = await x.readAsBytes();
                                  setState(() {
                                    _shopPhoto = bytes;
                                    _shopPhotoFile = x;
                                  });
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.photo_library_outlined),
                                  const SizedBox(width: 8),
                                  const Text('Choose photo'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ResponsiveOutlinedButton(
                              onPressed: () async {
                                final x = await _picker.pickImage(
                                  source: ImageSource.camera,
                                  imageQuality: 85,
                                );
                                if (x != null) {
                                  final bytes = await x.readAsBytes();
                                  setState(() {
                                    _shopPhoto = bytes;
                                    _shopPhotoFile = x;
                                  });
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.photo_camera_outlined),
                                  const SizedBox(width: 8),
                                  const Text('Camera'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_shopPhoto != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _shopPhoto!,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    ResponsiveFilledButton(
                      onPressed: _confirmOrder,
                      child: const Text('Confirm Order'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
