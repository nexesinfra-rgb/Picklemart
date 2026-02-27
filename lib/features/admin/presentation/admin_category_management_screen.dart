import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'dart:typed_data';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import '../domain/category.dart';
import '../data/category_service.dart';
import '../../../core/router/router_helpers.dart';
import '../../../core/utils/debouncer.dart';

class AdminCategoryManagementScreen extends ConsumerStatefulWidget {
  const AdminCategoryManagementScreen({super.key});

  @override
  ConsumerState<AdminCategoryManagementScreen> createState() =>
      _AdminCategoryManagementScreenState();
}

class _AdminCategoryManagementScreenState
    extends ConsumerState<AdminCategoryManagementScreen> {
  final _searchController = TextEditingController();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  bool _isInitialized = false;
  bool _isUpdatingUrl = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadFromUrl();
      _isInitialized = true;
    } else if (!_isUpdatingUrl) {
      // Listen for URL changes (browser back/forward, deep links)
      _syncFromUrl();
    }
  }

  void _loadFromUrl() {
    final state = GoRouterState.of(context);
    final qp = state.uri.queryParameters;
    final urlQuery = qp['q'] ?? '';
    
    if (urlQuery.isNotEmpty) {
      _searchController.text = urlQuery;
    }
  }

  void _syncFromUrl() {
    final state = GoRouterState.of(context);
    final qp = state.uri.queryParameters;
    final urlQuery = qp['q'] ?? '';
    
    if (urlQuery != _searchController.text) {
      _searchController.text = urlQuery;
    }
  }

  void _updateUrl(String query) {
    if (_isUpdatingUrl) return;
    _isUpdatingUrl = true;
    
    final url = RouterHelpers.buildAdminCategoriesUrl(
      query: query.isEmpty ? null : query,
    );
    context.go(url);
    // Reset flag after navigation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isUpdatingUrl = false;
      }
    });
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    return AdminAuthGuard(
      child: AdminScaffold(
        title: 'Category Management',
        showBackButton: true,
        actions: [
          ResponsiveIconButton(
            icon: const Icon(Ionicons.add_outline),
            onPressed: () => _showAddCategoryDialog(context),
            tooltip: 'Add Category',
          ),
        ],
        body: _buildBody(context, screenSize, foldableBreakpoint),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(context),
          const SizedBox(height: 16),
          _buildCategoryStats(context),
          const SizedBox(height: 24),
          Expanded(child: _buildCategoryList(context, screenSize)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search categories...',
        prefixIcon: const Icon(Ionicons.search_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onChanged: (value) {
        // Debounce URL update to avoid excessive navigation
        _searchDebouncer.debounce(() {
          if (mounted) {
            _updateUrl(value);
          }
        });
      },
    );
  }

  Widget _buildCategoryStats(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (List<Category> categories) {
        // Show stats for all categories
        final activeCategories = categories.where((c) => c.isActive).length;
        final totalProducts = categories.fold<int>(
          0,
          (sum, c) => sum + c.productCount,
        );

        return Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Categories',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeCategories',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Products',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalProducts',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildCategoryList(BuildContext context, ScreenSize screenSize) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (List<Category> categories) {
        // Show all categories, not just those with products
        var filteredCategories = List<Category>.from(categories);
        
        // Apply search filter if search query exists
        final searchQuery = _searchController.text.toLowerCase().trim();
        if (searchQuery.isNotEmpty) {
          filteredCategories = filteredCategories.where((c) {
            return c.name.toLowerCase().contains(searchQuery) ||
                c.description.toLowerCase().contains(searchQuery);
          }).toList();
        }
        
        // Sort categories: active first, then by name
        filteredCategories.sort((a, b) {
          if (a.isActive != b.isActive) {
            return a.isActive ? -1 : 1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        
        if (filteredCategories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Ionicons.folder_outline,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No categories found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  searchQuery.isNotEmpty
                      ? 'Try a different search term'
                      : 'Create a new category to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredCategories.length,
          itemBuilder: (context, index) {
            final category = filteredCategories[index];
            return _buildCategoryCard(context, category);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Ionicons.warning_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load categories',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: category.isActive ? Colors.green : Colors.grey,
          radius: 24,
          child:
              category.imageUrl != null && category.imageUrl!.isNotEmpty
                  ? ClipOval(
                    child: Image.network(
                      category.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Ionicons.folder_outline,
                            color: Colors.white,
                          ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      },
                    ),
                  )
                  : Icon(Ionicons.folder_outline, color: Colors.white),
        ),
        title: Text(
          category.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(category.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        category.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: category.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${category.productCount} products',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected:
              (value) => _handleCategoryAction(context, category, value),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Ionicons.create_outline),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: category.isActive ? 'deactivate' : 'activate',
                  child: Row(
                    children: [
                      Icon(
                        category.isActive
                            ? Ionicons.pause_outline
                            : Ionicons.play_outline,
                      ),
                      const SizedBox(width: 8),
                      Text(category.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Ionicons.trash_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
        ),
      ),
    );
  }

  void _handleCategoryAction(
    BuildContext context,
    Category category,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(context, category);
        break;
      case 'activate':
      case 'deactivate':
        _toggleCategoryStatus(category);
        break;
      case 'delete':
        _showDeleteConfirmation(context, category);
        break;
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    _showCategoryDialog(context, 'Add Category');
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    _showCategoryDialog(context, 'Edit Category', category: category);
  }

  void _showCategoryDialog(
    BuildContext context,
    String title, {
    Category? category,
  }) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    bool isActive = category?.isActive ?? true;
    Uint8List? selectedImageBytes;
    String? selectedImageName;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(title),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Category Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          // Image Upload Section
                          const Text(
                            'Category Image',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap:
                                      () => _pickImage(setState, (bytes, name) {
                                        selectedImageBytes = bytes;
                                        selectedImageName = name;
                                      }),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Ionicons.cloud_upload_outline,
                                          size: 48,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          selectedImageName ??
                                              'Click to select image',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Supported formats: JPG, PNG, GIF',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Image Preview
                                if (selectedImageBytes != null)
                                  Container(
                                    margin: const EdgeInsets.all(16),
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        selectedImageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Active'),
                            subtitle: const Text(
                              'Enable this category for customers',
                            ),
                            value: isActive,
                            onChanged: (value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Validate form fields
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a category name'),
                            ),
                          );
                          return;
                        }

                        if (descriptionController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter a category description',
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final categoryService = ref.read(
                            categoryServiceProvider,
                          );

                          if (category == null) {
                            // Create new category
                            print(
                              '🔍 Creating new category: ${nameController.text.trim()}',
                            );

                            final newCategory = Category(
                              id: '',
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              isActive: isActive,
                              productCount: 0,
                              imageBytes: selectedImageBytes,
                              imageName: selectedImageName,
                            );

                            print(
                              '📝 Category object created: ${newCategory.name}',
                            );

                            final createdCategory = await categoryService
                                .createCategory(newCategory);
                            print(
                              '✅ Category created successfully: ${createdCategory.name} (ID: ${createdCategory.id})',
                            );

                            // Close dialog first
                            Navigator.of(context).pop();

                            // Refresh categories list
                            print('🔄 Invalidating categories provider');
                            ref.invalidate(categoriesProvider);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Category created successfully'),
                              ),
                            );
                          } else {
                            // Update existing category
                            print(
                              '🔍 Updating existing category: ${category.name}',
                            );

                            final updatedCategory = category.copyWith(
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              isActive: isActive,
                              imageBytes: selectedImageBytes,
                              imageName: selectedImageName,
                            );

                            await categoryService.updateCategory(
                              updatedCategory,
                            );

                            // Close dialog first
                            Navigator.of(context).pop();

                            // Refresh categories list
                            ref.invalidate(categoriesProvider);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Category updated successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          print('❌ Error in category save action: $e');
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _pickImage(
    StateSetter setState,
    Function(Uint8List, String) onImageSelected,
  ) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      onImageSelected(Uint8List.fromList(bytes), file.name);
    });
  }

  void _toggleCategoryStatus(Category category) async {
    try {
      final categoryService = ref.read(categoryServiceProvider);
      final updatedCategory = category.copyWith(isActive: !category.isActive);

      await categoryService.updateCategory(updatedCategory);

      // Refresh categories list
      ref.invalidate(categoriesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Category ${updatedCategory.isActive ? 'activated' : 'deactivated'}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDeleteConfirmation(BuildContext context, Category category) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteCategoryDialog(
        category: category,
        onDeleted: () {
          // Refresh categories list after successful deletion
          ref.invalidate(categoriesProvider);
        },
      ),
    );
  }
}

class _DeleteCategoryDialog extends ConsumerStatefulWidget {
  final Category category;
  final VoidCallback onDeleted;

  const _DeleteCategoryDialog({
    required this.category,
    required this.onDeleted,
  });

  @override
  ConsumerState<_DeleteCategoryDialog> createState() =>
      _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends ConsumerState<_DeleteCategoryDialog> {
  bool _isDeleting = false;
  String? _errorMessage;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final categoryService = ref.read(categoryServiceProvider);
      final success = await categoryService.deleteCategory(widget.category.id);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        widget.onDeleted();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'Failed to delete category. It may be in use by products.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${widget.category.name}"? This action cannot be undone.',
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Ionicons.alert_circle_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isDeleting) ...[
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
