import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../application/admin_customer_controller.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../../core/router/router_helpers.dart';
import '../../auth/presentation/widgets/mobile_number_input.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/admin_action_bottom_bar.dart';
import 'customer_browsing_analytics_screen.dart';
import '../../chat/data/chat_repository.dart';

class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() =>
      _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  final _searchController = TextEditingController();
  bool _isInitialized = false;
  String? _entryRoute; // Track the route we came from

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      // Capture entry route before any URL updates break the stack
      final state = GoRouterState.of(context);
      final previousRoute = state.uri.queryParameters['previousRoute'];

      if (previousRoute != null && previousRoute.isNotEmpty) {
        // Previous route was passed via query parameter (from More page or bottom nav navigation)
        _entryRoute = previousRoute;
      } else if (context.canPop()) {
        // Try to get previous route from navigation history
        // Since we can't directly access it, we'll use a smart fallback
        _entryRoute = '/admin/dashboard'; // Default assumption
      } else {
        // No navigation stack - likely accessed from bottom nav or direct link
        _entryRoute = null; // Will use dashboard as fallback
      }
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    var customerState = ref.watch(adminCustomerControllerProvider);

    // Filter out manufacturers from filteredCustomers as this screen is for managing Stores/Customers only
    customerState = customerState.copyWith(
      filteredCustomers:
          customerState.filteredCustomers
              .where((c) => !c.isManufacturer)
              .toList(),
    );

    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;

    return AdminAuthGuard(
      child: _buildMainContent(context, customerState, screenSize, width),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    customerState,
    screenSize,
    width,
  ) {
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    return AdminScaffold(
      title: 'Manage Stores',
      showBackButton: true,
      onBackPressed: () {
        // Try to pop first
        if (context.canPop()) {
          context.pop();
        } else {
          // Navigation stack broken - use entry route or default to dashboard
          context.go(_entryRoute ?? '/admin/dashboard');
        }
      },
      actions: [
        IconButton(
          icon: const Icon(Ionicons.add_outline),
          onPressed: () => _showCreateCustomerDialog(context),
          tooltip: 'Create Store',
        ),
      ],
      body: Stack(
        children: [
          customerState.error != null
              ? _buildErrorState(context, customerState.error!)
              : customerState.filteredCustomers.isEmpty
              ? _buildEmptyState(context)
              : _buildResponsiveContent(
                context,
                customerState,
                screenSize,
                foldableBreakpoint,
              ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AdminActionBottomBar(
              onRefresh: () {
                ref.read(adminCustomerControllerProvider.notifier).refresh();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent(
    BuildContext context,
    AdminCustomerState customerState,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);
    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.viewPadding.bottom;

    // Calculate responsive navigation bar height
    final isUltraCompact = width <= 288;
    final isCompact = width <= 400;
    final bottomNavHeight = isUltraCompact ? 56.0 : (isCompact ? 60.0 : 64.0);
    final totalBottomSpacing =
        bottomNavHeight + systemBottomPadding + 40; // 40px buffer

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: totalBottomSpacing),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(spacing),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(Ionicons.search_outline),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Ionicons.close_outline),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(adminCustomerControllerProvider.notifier)
                                .searchCustomers('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref
                    .read(adminCustomerControllerProvider.notifier)
                    .searchCustomers(value);
              },
            ),
          ),

          // Customers List
          _buildResponsiveCustomersList(
            context,
            customerState,
            screenSize,
            foldableBreakpoint,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
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
            'Error loading stores',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref
                  .read(adminCustomerControllerProvider.notifier)
                  .loadCustomers();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No stores found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveCustomersList(
    BuildContext context,
    AdminCustomerState state,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);

    return Padding(
      padding: EdgeInsets.only(
        left: spacing,
        right: spacing,
        bottom: spacing, // Extra bottom spacing for last item
      ),
      child: Column(
        children: [
          ...state.filteredCustomers.map((customer) {
            return Padding(
              padding: EdgeInsets.only(bottom: spacing * 0.5),
              child: _buildResponsiveCustomerCard(
                context,
                customer,
                screenSize,
                foldableBreakpoint,
              ),
            );
          }),
          if (state.hasMore)
            Padding(
              padding: EdgeInsets.only(top: spacing),
              child:
                  state.isLoadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(adminCustomerControllerProvider.notifier)
                              .loadMoreCustomers();
                        },
                        icon: const Icon(Ionicons.refresh_outline),
                        label: const Text('Load More'),
                      ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsiveCustomerCard(
    BuildContext context,
    customer,
    ScreenSize screenSize,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isUltraCompact = Responsive.isUltraCompactDevice(width);
    final isFoldable = Responsive.isFoldableMobile(width);

    final padding =
        isUltraCompact
            ? const EdgeInsets.all(12)
            : isFoldable
            ? const EdgeInsets.all(14)
            : const EdgeInsets.all(16);

    final borderRadius = isUltraCompact ? 8.0 : 12.0;
    final avatarRadius = isUltraCompact ? 20.0 : 24.0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _showCustomerDetails(context, customer),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (customer.alias != null && customer.alias!.isNotEmpty)
                      ? customer.alias![0].toUpperCase()
                      : (customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : 'C'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isUltraCompact ? 14 : 16,
                  ),
                ),
              ),
              SizedBox(width: isUltraCompact ? 12 : 16),

              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (customer.alias != null && customer.alias!.isNotEmpty)
                          ? customer.alias!
                          : customer.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isUltraCompact ? 14 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isUltraCompact ? 2 : 4),
                    Text(
                      customer.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: isUltraCompact ? 11 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (customer.phone != null) ...[
                      SizedBox(height: isUltraCompact ? 2 : 4),
                      Text(
                        customer.phone!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: isUltraCompact ? 10 : null,
                        ),
                      ),
                    ],
                    if (customer.gstNumber != null &&
                        customer.gstNumber!.isNotEmpty) ...[
                      SizedBox(height: isUltraCompact ? 2 : 4),
                      Row(
                        children: [
                          Icon(
                            Ionicons.document_text_outline,
                            size: isUltraCompact ? 10 : 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            customer.gstNumber!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.7),
                              fontSize: isUltraCompact ? 12 : 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status and Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isUltraCompact ? 6 : 8,
                      vertical: isUltraCompact ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          customer.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        isUltraCompact ? 8 : 12,
                      ),
                    ),
                    child: Text(
                      customer.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: customer.isActive ? Colors.green : Colors.red,
                        fontSize: isUltraCompact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: isUltraCompact ? 4 : 8),
                  PopupMenuButton<String>(
                    onSelected:
                        (value) => _handleCustomerAction(value, customer),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 120),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Ionicons.eye_outline, size: 18),
                                SizedBox(width: 8),
                                Text('View'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Ionicons.create_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value:
                                customer.isActive ? 'deactivate' : 'activate',
                            child: Row(
                              children: [
                                Icon(
                                  customer.isActive
                                      ? Ionicons.pause_outline
                                      : Ionicons.play_outline,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  customer.isActive ? 'Deactivate' : 'Activate',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Ionicons.trash_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    customer,
    ScreenSize screenSize,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCustomerDetails(context, customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    customer.isActive
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                child: Text(
                  ((customer.alias != null && customer.alias!.isNotEmpty)
                          ? customer.alias!
                          : customer.name)
                      .substring(0, 1)
                      .toUpperCase(),
                  style: TextStyle(
                    color:
                        customer.isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (customer.alias != null &&
                                    customer.alias!.isNotEmpty)
                                ? customer.alias!
                                : customer.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (!customer.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Inactive',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Stats
                    if (screenSize == ScreenSize.mobile)
                      _buildMobileStats(context, customer)
                    else
                      _buildDesktopStats(context, customer),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (value) => _handleCustomerAction(value, customer),
                itemBuilder:
                    (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Ionicons.eye_outline, size: 16),
                            const SizedBox(width: 8),
                            const Text('View Details'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'orders',
                        child: Row(
                          children: [
                            const Icon(Ionicons.receipt_outline, size: 16),
                            const SizedBox(width: 8),
                            const Text('View Orders'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: customer.isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              customer.isActive
                                  ? Ionicons.pause_outline
                                  : Ionicons.play_outline,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(customer.isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                    ],
                child: const Icon(Ionicons.ellipsis_vertical_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStats(BuildContext context, customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatChip(
              context,
              '${customer.totalOrders} orders',
              Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              context,
              '₹${customer.totalSpent.toStringAsFixed(0)} spent',
              Colors.green,
            ),
          ],
        ),
        if (customer.lastOrderDate != null) ...[
          const SizedBox(height: 4),
          Text(
            'Last order: ${_formatDate(customer.lastOrderDate!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopStats(BuildContext context, customer) {
    return Row(
      children: [
        _buildStatChip(context, '${customer.totalOrders} orders', Colors.blue),
        const SizedBox(width: 8),
        _buildStatChip(
          context,
          '₹${customer.totalSpent.toStringAsFixed(0)} spent',
          Colors.green,
        ),
        if (customer.lastOrderDate != null) ...[
          const SizedBox(width: 8),
          _buildStatChip(
            context,
            'Last: ${_formatDate(customer.lastOrderDate!)}',
            Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder:
                (context, scrollController) => Consumer(
                  builder: (context, ref, child) {
                    // Get the latest customer data from the controller
                    final customerState = ref.watch(
                      adminCustomerControllerProvider,
                    );
                    final updatedCustomer = customerState.customers.firstWhere(
                      (c) => c.id == customer.id,
                      orElse: () => customer,
                    );

                    return SafeArea(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            controller: scrollController,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 900,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      _buildCustomerDetailsContent(
                                        context,
                                        updatedCustomer,
                                        ref,
                                      ),
                                      const SizedBox(
                                        height: 80,
                                      ), // Space for bottom bar
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: AdminActionBottomBar(
                              customerId: customer.id,
                              onRefresh: () {
                                ref
                                    .read(
                                      adminCustomerControllerProvider.notifier,
                                    )
                                    .refresh();
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Widget _buildCustomerDetailsContent(
    BuildContext context,
    Customer customer,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Customer Header
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor:
                  customer.isActive
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              child: Text(
                customer.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color:
                      customer.isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (customer.alias != null && customer.alias!.isNotEmpty)
                        ? customer.alias!
                        : customer.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    customer.phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (customer.gstNumber != null &&
                      customer.gstNumber!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Ionicons.document_text_outline,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'GST: ${customer.gstNumber}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!customer.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Inactive',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Customer Stats
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                context,
                'Total Orders',
                customer.totalOrders.toString(),
                Ionicons.receipt_outline,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailCard(
                context,
                'Total Spent',
                '₹${customer.totalSpent.toStringAsFixed(0)}',
                Ionicons.cash_outline,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                context,
                'Member Since',
                _formatDate(customer.createdAt),
                Ionicons.calendar_outline,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailCard(
                context,
                'Last Order',
                customer.lastOrderDate != null
                    ? _formatDate(customer.lastOrderDate!)
                    : 'Never',
                Ionicons.time_outline,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Address Section
        if (customer.address != null && customer.address!.isNotEmpty) ...[
          Text(
            'Address',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Ionicons.location_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer.address!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Actions
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ResponsiveOutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      final url = RouterHelpers.buildAdminOrdersUrl(
                        customerId: customer.id,
                      );
                      context.go(url);
                    },
                    child: const Text('View Orders'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ResponsiveFilledButton(
                    onPressed: () async {
                      final success = await ref
                          .read(adminCustomerControllerProvider.notifier)
                          .updateCustomerStatus(
                            customer.id,
                            !customer.isActive,
                          );

                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              customer.isActive
                                  ? 'Customer deactivated successfully'
                                  : 'Customer activated successfully',
                            ),
                          ),
                        );
                        // Bottom sheet will automatically update via Consumer
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to update customer status'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(customer.isActive ? 'Deactivate' : 'Activate'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Chat Button
            SizedBox(
              width: double.infinity,
              child: ResponsiveFilledButton(
                onPressed: () async {
                  try {
                    // Get or create conversation for this customer
                    final chatRepository = ref.read(chatRepositoryProvider);
                    final conversation = await chatRepository
                        .createOrGetConversation(customer.id);

                    // Close the bottom sheet
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }

                    // Navigate to admin chat detail screen
                    if (context.mounted) {
                      context.push('/admin/chat/${conversation.id}');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to open chat: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.chatbubble_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Chat with Customer'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Price Visibility Toggle
            Card(
              child: ListTile(
                leading: const Icon(Ionicons.cash_outline),
                title: const Text('Price Visibility'),
                subtitle: const Text(
                  'Allow this customer to see product prices',
                ),
                trailing: Switch(
                  value: customer.priceVisibilityEnabled,
                  onChanged: (value) async {
                    final success = await ref
                        .read(adminCustomerControllerProvider.notifier)
                        .updateCustomerPriceVisibility(customer.id, value);

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Price visibility enabled for customer'
                                : 'Price visibility disabled for customer',
                          ),
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update price visibility'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ResponsiveOutlinedButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => CustomerBrowsingAnalyticsScreen(
                            customerId: customer.id,
                            customerName: customer.name,
                            customerEmail: customer.email,
                          ),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.analytics_outline, size: 18),
                    SizedBox(width: 8),
                    Text('View Browsing Analytics'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ResponsiveOutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pushNamed(
                    'admin-user-location',
                    queryParameters: {
                      'userId': customer.id,
                      'userName': customer.name,
                    },
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.location_outline, size: 18),
                    SizedBox(width: 8),
                    Text('View Location History'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleCustomerAction(String action, customer) {
    switch (action) {
      case 'view':
        _showCustomerDetails(context, customer);
        break;
      case 'edit':
        _editCustomer(customer);
        break;
      case 'delete':
        _deleteCustomer(customer);
        break;
      case 'orders':
        // TODO: Navigate to customer orders
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer orders view coming soon')),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleCustomerStatus(customer);
        break;
    }
  }

  Future<void> _editCustomer(customer) async {
    context.pushNamed(
      'admin-customer-edit',
      pathParameters: {'customerId': customer.id},
    );
  }

  Future<void> _deleteCustomer(customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Customer'),
            content: Text(
              'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(adminCustomerControllerProvider.notifier)
          .deleteCustomer(customer.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
      }
    }
  }

  Future<void> _toggleCustomerStatus(customer) async {
    final success = await ref
        .read(adminCustomerControllerProvider.notifier)
        .updateCustomerStatus(customer.id, !customer.isActive);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            customer.isActive
                ? 'Customer deactivated successfully'
                : 'Customer activated successfully',
          ),
        ),
      );
    }
  }

  void _showCreateCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String mobileDigits = '';
    bool passwordObscured = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Create Store Account'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            enabled: !isSubmitting,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          MobileNumberInput(
                            labelText: 'Mobile Number',
                            hintText: 'Enter 10-digit mobile number',
                            onChanged: (v) {
                              setDialogState(() {
                                mobileDigits = v;
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
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  passwordObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    passwordObscured = !passwordObscured;
                                  });
                                },
                              ),
                            ),
                            obscureText: passwordObscured,
                            enabled: !isSubmitting,
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
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isSubmitting
                              ? null
                              : () {
                                Navigator.of(context).pop();
                              },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed:
                          isSubmitting
                              ? null
                              : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                setDialogState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  final result = await ref
                                      .read(
                                        adminCustomerControllerProvider
                                            .notifier,
                                      )
                                      .createCustomerAccount(
                                        name: nameController.text.trim(),
                                        mobile: mobileDigits,
                                        password: passwordController.text,
                                      );

                                  if (!context.mounted) return;

                                  if (result != null) {
                                    final userData =
                                        result['user'] as Map<String, dynamic>;
                                    final mobile = userData['mobile'] as String;
                                    final password =
                                        userData['password'] as String;

                                    Navigator.of(context).pop();

                                    // Show success dialog with credentials
                                    showDialog(
                                      context: context,
                                      builder:
                                          (successContext) => AlertDialog(
                                            title: const Text(
                                              'Account Created Successfully',
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Store account has been created. Share these credentials with the store owner:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                _buildCredentialRow(
                                                  'Mobile:',
                                                  mobile,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildCredentialRow(
                                                  'Password:',
                                                  password,
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  'Note: These credentials should be shared securely with the store owner.',
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
                                                  Navigator.of(
                                                    successContext,
                                                  ).pop();
                                                },
                                                child: const Text('Done'),
                                              ),
                                            ],
                                          ),
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Store account created successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ref
                                                  .read(
                                                    adminCustomerControllerProvider,
                                                  )
                                                  .error ??
                                              'Failed to create store account',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                      child:
                          isSubmitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Create'),
                    ),
                  ],
                ),
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
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
