import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_controller.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/ui/branding_header.dart';
import 'widgets/mobile_number_input.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _mobileDigits = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .resetPasswordWithMobile(_mobileDigits);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your mobile number')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Branding Header
              const BrandingHeader(),
              const SizedBox(height: 32),

              MobileNumberInput(
                labelText: 'Mobile Number',
                hintText: 'Enter 10-digit mobile number',
                onChanged: (v) => _mobileDigits = v,
                validator: (v) {
                  final val = v ?? '';
                  if (val.isEmpty) return 'Please enter your mobile number';
                  if (val.length != 10) return 'Enter a valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ResponsiveFilledButton(
                onPressed: state.loading ? null : _submit,
                child:
                    state.loading
                        ? const CircularProgressIndicator()
                        : const Text('Send reset link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
