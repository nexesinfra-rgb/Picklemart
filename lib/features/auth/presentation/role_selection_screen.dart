import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/auth_controller.dart';
import '../../../core/ui/responsive_buttons.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Choose your role',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ResponsiveFilledButton(
              onPressed: () {
                ref
                    .read(authControllerProvider.notifier)
                    .selectRole(AppRole.user);
                context.goNamed('login');
              },
              child: const Text('Login with User'),
            ),
            const SizedBox(height: 12),
            ResponsiveOutlinedButton(
              onPressed: () {
                ref
                    .read(authControllerProvider.notifier)
                    .selectRole(AppRole.admin);
                context.goNamed('admin-login');
              },
              child: const Text('Login with Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
