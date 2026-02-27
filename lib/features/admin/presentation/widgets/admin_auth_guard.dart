import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/admin_auth_controller.dart';

class AdminAuthGuard extends ConsumerWidget {
  final Widget child;

  const AdminAuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthControllerProvider);
    final adminUser = authState.adminUser;
    final isLoading = authState.loading;

    // Show loading indicator while initialization is in progress
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Only allow access if authenticated
    if (adminUser != null) {
      return child;
    }

    // Redirect to admin login if not authenticated (only after loading completes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.goNamed('admin-login');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
