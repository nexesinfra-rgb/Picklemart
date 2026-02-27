import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import '../../../core/utils/phone_utils.dart';

class PasswordResetConfirmScreen extends ConsumerStatefulWidget {
  const PasswordResetConfirmScreen({
    super.key,
    required this.userId,
    required this.secret,
  });

  final String userId;
  final String secret;

  @override
  ConsumerState<PasswordResetConfirmScreen> createState() =>
      _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState
    extends ConsumerState<PasswordResetConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isVerifyingToken = false;
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    _verifyTokenIfNeeded();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Verify the recovery token if we have one and no active session
  Future<void> _verifyTokenIfNeeded() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    // If we already have a session, we're good
    if (session != null) return;

    // Try to verify the token if we have it
    // For Supabase, the secret might be a token that needs verification
    if (widget.secret.isNotEmpty) {
      setState(() {
        _isVerifyingToken = true;
      });

      try {
        final repo = ref.read(authRepositoryProvider);
        // Try to extract email from userId (could be email or phone-based email)
        String? email;
        if (PhoneUtils.isPhoneEmail(widget.userId)) {
          email = widget.userId;
        } else if (widget.userId.contains('@')) {
          email = widget.userId;
        }

        if (email != null) {
          await repo.verifyRecoveryToken(token: widget.secret, email: email);
        }
      } catch (e) {
        setState(() {
          _verificationError = 'Token verification failed: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isVerifyingToken = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // Check if we have a session (from token verification)
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please use the password reset link from your email'),
        ),
      );
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .confirmRecovery(
          widget.userId,
          widget.secret,
          _newPasswordController.text,
          _confirmPasswordController.text,
        );

    final state = ref.read(authControllerProvider);
    if (!mounted) return;

    if (state.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successful. Please log in.'),
        ),
      );
      if (mounted) {
        context.goNamed('login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    if (_isVerifyingToken) {
      return Scaffold(
        appBar: AppBar(title: const Text('Set new password')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_verificationError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Set new password')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _verificationError!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.goNamed('login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Set new password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'New password'),
                obscureText: true,
                validator:
                    (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                obscureText: true,
                validator:
                    (v) =>
                        (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.loading ? null : _submit,
                child:
                    state.loading
                        ? const CircularProgressIndicator()
                        : const Text('Update password'),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(state.error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
