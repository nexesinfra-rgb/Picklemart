import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../application/store_controller.dart';
import '../domain/store_details.dart';

class AdminStoreFormScreen extends ConsumerStatefulWidget {
  const AdminStoreFormScreen({super.key});

  @override
  ConsumerState<AdminStoreFormScreen> createState() => _AdminStoreFormScreenState();
}

class _AdminStoreFormScreenState extends ConsumerState<AdminStoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstController;
  String? _storeId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _gstController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _initializeFields(StoreDetails store) {
    _storeId = store.id;
    _nameController.text = store.name;
    _addressController.text = store.address ?? '';
    _phoneController.text = store.phone ?? '';
    _emailController.text = store.email ?? '';
    _gstController.text = store.gstNumber ?? '';
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) return;

    final store = StoreDetails(
      id: _storeId ?? '', // If empty, repo handles insert logic if needed
      name: _nameController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      gstNumber: _gstController.text,
    );

    try {
      await ref.read(storeControllerProvider.notifier).updateStoreDetails(store);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store details updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update store: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeControllerProvider);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Manage Store Details'),
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: storeState.when(
        data: (store) {
          if (store != null && _storeId == null) {
            _initializeFields(store);
          }
          
          // If store is null (e.g. first run before migration or fetch), 
          // we might want to allow creating one or show loading.
          // Assuming migration runs, store shouldn't be null.
          // But if it is, we present empty form.

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Store Name',
                    icon: Ionicons.business_outline,
                    validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Ionicons.location_outline,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Ionicons.call_outline,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Ionicons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _gstController,
                    label: 'GST Number',
                    icon: Ionicons.receipt_outline,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _saveStore,
                    icon: const Icon(Ionicons.save_outline),
                    label: const Text('Save Details'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
