import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_controller.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/ui/branding_header.dart';
import 'widgets/mobile_number_input.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _mobileDigits = '';
  bool _passwordObscured = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Call signup
      await ref
          .read(authControllerProvider.notifier)
          .signUpWithMobile(
            _nameController.text.trim(),
            _mobileDigits,
            _passwordController.text,
          );

      // Wait a bit for state to update (async state update)
      await Future.delayed(const Duration(milliseconds: 100));

      // Check the state after signup completes
      final state = ref.read(authControllerProvider);
      
      if (mounted) {
        if (state.error != null) {
          // Show error - don't navigate away
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              duration: const Duration(seconds: 5),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }

        // Only show success if user is authenticated (has session)
        if (state.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to home
          context.goNamed('home');
        }
      }
    } catch (e) {
      // Catch any unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Branding Header
                        const BrandingHeader(),
                        const SizedBox(height: 32),

                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator:
                              (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'Enter name'
                                      : null,
                        ),
                        const SizedBox(height: 12),
                        MobileNumberInput(
                          labelText: 'Mobile Number',
                          hintText: 'Enter 10-digit mobile number',
                          onChanged: (v) => _mobileDigits = v,
                          validator: (v) {
                            final val = v ?? '';
                            if (val.isEmpty) return 'Enter mobile number';
                            if (val.length != 10) {
                              return 'Enter 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
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
                          validator:
                              (v) =>
                                  (v == null || v.length < 6)
                                      ? 'Min 6 characters'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        ResponsiveFilledButton(
                          onPressed: state.loading ? null : _submit,
                          isLoading: state.loading,
                          child: const Text('Create account'),
                        ),
                        const SizedBox(height: 12),
                        ResponsiveOutlinedButton(
                          onPressed: () => context.goNamed('login'),
                          child: const Text("Already have an account? Login"),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        state.error!,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.error,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (state.error!.contains('401') ||
                                    state.error!.contains('email confirmation') ||
                                    state.error!.contains('Supabase')) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Quick Fix: Go to Supabase Dashboard → Authentication → Settings → Disable "Enable email confirmations"',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
