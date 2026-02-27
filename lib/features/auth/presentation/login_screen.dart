import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_controller.dart';
import '../../../core/ui/responsive_buttons.dart';
import 'widgets/mobile_number_input.dart';
import 'auth_location_helper.dart';
import 'contact_support_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String _mobileDigits = '';
  bool _passwordObscured = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Mobile-based login (for regular users)
      await ref
          .read(authControllerProvider.notifier)
          .signInWithMobile(_mobileDigits, _passwordController.text);

      // PERFORMANCE OPTIMIZATION: No delay needed - state is set immediately
      // Check the state after the signIn completes
      final state = ref.read(authControllerProvider);
      if (mounted) {
        if (state.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged in successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate immediately
          if (state.role == AppRole.admin) {
            context.goNamed('admin-dashboard');
          } else {
            context.goNamed('home');
          }

          // Start location/session in background (non-blocking)
          AuthLocationHelper.handlePostAuth(
            context,
            ref,
            state.role,
          ).catchError((e) => debugPrint('Background auth setup error: $e'));
        } else if (state.error != null) {
          // Show error with longer duration and better styling
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              duration: const Duration(seconds: 5),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          // No error but not authenticated - check if there's a pending error
          // This might happen if error was set but then cleared
          final errorState = ref.read(authControllerProvider).error;
          if (errorState != null && errorState.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorState),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            // Fallback only if truly no error available
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Login failed. Please check your credentials and try again.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage;
      if (e is Exception) {
        final errorString = e.toString();
        // Remove "Exception: " prefix if present
        errorMessage = errorString.replaceFirst(RegExp(r'^Exception:\s*'), '');
        // Handle connectivity errors with better messages
        if (errorMessage.contains('timed out') ||
            errorMessage.contains('Timeout') ||
            errorMessage.contains('Login request timed out')) {
          // Timeout errors already have good messages with retry suggestions
          // Keep the detailed timeout error message
          errorMessage = errorMessage;
        } else if (errorMessage.contains('Cannot reach Supabase') ||
            errorMessage.contains('network') ||
            errorMessage.contains('DNS')) {
          // Keep the detailed connectivity error message
          errorMessage = errorMessage;
        } else if (errorMessage.contains('Invalid mobile number')) {
          errorMessage =
              'Invalid mobile number format. Please check and try again.';
        } else if (errorMessage.isEmpty || errorMessage == 'null') {
          errorMessage = 'An unexpected error occurred. Please try again.';
        }
      } else {
        errorMessage = e.toString();
      }

      // Surface errors to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(
              seconds: 6,
            ), // Longer duration for connectivity errors
          ),
        );
      }
    }
  }

  void _showContactSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ContactSupportScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
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
                          // Logo (Bigger and without text)
                          const SizedBox(height: 60),
                          Image.asset(
                            'assets/picklemart.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          // Mobile Input
                          MobileNumberInput(
                            labelText: 'Mobile Number',
                            hintText: 'Enter 10-digit mobile number',
                            onChanged: (v) => _mobileDigits = v,
                            validator: (v) {
                              final val = v ?? '';
                              if (val.isEmpty) {
                                return 'Please enter your mobile number';
                              }
                              if (val.length != 10) {
                                return 'Enter a valid 10-digit number';
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
                              prefixIcon: const Icon(Icons.lock_outline),
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
                          const SizedBox(height: 24),
                          // Login Button
                          ResponsiveFilledButton(
                            onPressed: state.loading ? null : _submit,
                            isLoading: state.loading,
                            child: const Text('Login'),
                          ),
                          const SizedBox(height: 12),
                          ResponsiveTextButton(
                            onPressed: () => _showContactSupport(context),
                            child: const Text('Forgot password?'),
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.error!,
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (state.error!.contains(
                                        'email confirmation',
                                      ) ||
                                      state.error!.contains('401')) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tip: If using phone-based login, ensure email confirmation is disabled in Supabase Auth settings.',
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
      ),
    );
  }
}
