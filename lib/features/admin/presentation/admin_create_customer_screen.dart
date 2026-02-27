import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../application/admin_customer_controller.dart';
import '../../auth/presentation/widgets/mobile_number_input.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_auth_guard.dart';

class AdminCreateCustomerScreen extends ConsumerStatefulWidget {
  const AdminCreateCustomerScreen({super.key});

  @override
  ConsumerState<AdminCreateCustomerScreen> createState() =>
      _AdminCreateCustomerScreenState();
}

class _AdminCreateCustomerScreenState
    extends ConsumerState<AdminCreateCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _gstNumberController = TextEditingController();
  String _mobileDigits = '';
  bool _passwordObscured = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _gstNumberController.dispose();
    super.dispose();
  }

  String? _validateGstNumber(String? value) {
    // GST number is optional, so if empty, return null (valid)
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    // Remove any spaces or dashes
    final cleanGst = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

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
    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}').hasMatch(cleanGst.substring(0, 12))) {
      return 'Invalid GST format';
    }

    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final gstNumber = _gstNumberController.text.trim();
      final result = await ref
          .read(adminCustomerControllerProvider.notifier)
          .createCustomerAccount(
            name: _nameController.text.trim(),
            mobile: _mobileDigits,
            password: _passwordController.text,
            gstNumber: gstNumber.isEmpty ? null : gstNumber,
          );

      if (!mounted) return;

      if (result != null) {
        final userData = result['user'] as Map<String, dynamic>;
        final mobile = userData['mobile'] as String;
        final password = userData['password'] as String;

        // Show success dialog with credentials
        _showSuccessDialog(mobile, password);

        // Refresh customer list
        ref.read(adminCustomerControllerProvider.notifier).refresh();
      } else {
        _showErrorDialog(
          ref.read(adminCustomerControllerProvider).error ??
              'Failed to create customer account',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(String mobile, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (successContext) => AlertDialog(
        title: const Text('Account Created Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer account has been created. Share these credentials with the customer:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCredentialRow('Mobile:', mobile),
            const SizedBox(height: 8),
            _buildCredentialRow('Password:', password),
            const SizedBox(height: 16),
            const Text(
              'Note: These credentials should be shared securely with the customer.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(successContext).pop();
              // Navigate back to customers screen
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/admin/customers');
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer account created successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (errorContext) => AlertDialog(
        title: const Text('Error'),
        content: Text(errorMessage),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(errorContext).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Create Customer Account',
        showBackButton: true,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/admin/customers');
          }
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter customer name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Ionicons.person_outline),
                  ),
                  enabled: !_isSubmitting,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mobile Number Field
                MobileNumberInput(
                  labelText: 'Mobile Number',
                  hintText: 'Enter 10-digit mobile number',
                  onChanged: (v) {
                    setState(() {
                      _mobileDigits = v;
                    });
                  },
                  validator: (v) {
                    final val = v ?? '';
                    if (val.isEmpty) return 'Enter mobile number';
                    if (val.length != 10) {
                      return 'Enter 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter password (min 6 characters)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Ionicons.lock_closed_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordObscured = !_passwordObscured;
                        });
                      },
                    ),
                  ),
                  obscureText: _passwordObscured,
                  enabled: !_isSubmitting,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter password';
                    }
                    if (value.length < 6) {
                      return 'Min 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // GST Number Field (Optional)
                TextFormField(
                  controller: _gstNumberController,
                  decoration: const InputDecoration(
                    labelText: 'GST Number (Optional)',
                    hintText: 'Enter 15-digit GST number',
                    helperText: 'Format: 22AAAAA0000A1Z5',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Ionicons.document_text_outline),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 15,
                  enabled: !_isSubmitting,
                  validator: _validateGstNumber,
                  onChanged: (value) {
                    // Auto-format to uppercase
                    final cursorPosition = _gstNumberController.selection.baseOffset;
                    _gstNumberController.value = _gstNumberController.value.copyWith(
                      text: value.toUpperCase().replaceAll(RegExp(r'[\s-]'), ''),
                      selection: TextSelection.collapsed(offset: cursorPosition),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                FilledButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/admin/customers');
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
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

