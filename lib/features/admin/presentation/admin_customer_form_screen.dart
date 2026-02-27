import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/layout/responsive.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../application/admin_customer_controller.dart';

class AdminCustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const AdminCustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<AdminCustomerFormScreen> createState() =>
      _AdminCustomerFormScreenState();
}

class _AdminCustomerFormScreenState
    extends ConsumerState<AdminCustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loadCustomerData();
    }
  }

  Future<void> _loadCustomerData() async {
    if (!_isInitialized && widget.customerId != null) {
      setState(() => _isLoading = true);
      try {
        final customers = ref.read(adminCustomerControllerProvider).customers;
        final customer = customers.firstWhere(
          (c) => c.id == widget.customerId,
          orElse: () => throw Exception('Customer not found'),
        );

        _nameController.text = customer.name;
        _emailController.text =
            customer.email.endsWith('@phone.local') ? '' : customer.email;
        _phoneController.text = customer.phone;
        _addressController.text = customer.address ?? '';
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load customer: $e')),
          );
          context.pop();
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
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(adminCustomerControllerProvider.notifier);

      // Check if we should update email
      final customers = ref.read(adminCustomerControllerProvider).customers;
      final originalCustomer = customers
          .cast<Customer?>()
          .firstWhere((c) => c?.id == widget.customerId, orElse: () => null);

      String? emailToUpdate = _emailController.text.trim();
      if (emailToUpdate.isEmpty &&
          originalCustomer != null &&
          originalCustomer.email.endsWith('@phone.local')) {
        emailToUpdate = null;
      }

      final success = await controller.updateCustomer(
        id: widget.customerId!,
        name: _nameController.text.trim(),
        email: emailToUpdate,
        phone: _phoneController.text.trim(),
        password:
            _passwordController.text.isNotEmpty
                ? _passwordController.text
                : null,
        address: _addressController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer updated successfully')),
        );
        context.pop();
      } else if (mounted) {
        final state = ref.read(adminCustomerControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error ?? 'Failed to update customer')),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);

    if (_isLoading && !_isInitialized) {
      return AdminAuthGuard(
        child: AdminScaffold(
          title: 'Edit Customer',
          showBackButton: true,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Edit Customer',
        showBackButton: true,
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Ionicons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: spacing),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Ionicons.mail_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: spacing),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Ionicons.call_outline),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.length < 10) {
                      return 'Phone number must be at least 10 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: spacing),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'New Password (Optional)',
                    hintText: 'Leave empty to keep current password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Ionicons.lock_closed_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Ionicons.eye_off_outline : Ionicons.eye_outline,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: spacing),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Ionicons.location_outline),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveCustomer,
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Save Changes'),
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
