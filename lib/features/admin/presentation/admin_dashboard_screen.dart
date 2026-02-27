import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../application/admin_auth_controller.dart';
import '../../../core/layout/responsive.dart';
import '../application/admin_dashboard_controller.dart';
import 'widgets/admin_auth_guard.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/transaction_type_sheet.dart';
import '../application/admin_customer_controller.dart';
import '../application/manufacturer_controller.dart';
import '../../catalog/data/shared_product_provider.dart';
import '../data/customer_balance_pdf_service.dart';
import '../application/credit_system_controller.dart';
import '../domain/credit_transaction.dart';
import '../data/payment_receipt_repository.dart';
import '../data/credit_transaction_repository.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isInitialized = false;
  bool _showBackButton = false;
  final TextEditingController _partySearchController = TextEditingController();
  int _bottomTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(adminDashboardControllerProvider.notifier).initialize();
        ref.read(manufacturerControllerProvider.notifier).loadManufacturers();
      }
    });
  }

  @override
  void dispose() {
    _partySearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _checkPreviousRoute();
      _isInitialized = true;
    }
  }

  Widget _buildRevenueSummary(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState state,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final spacing = isMobile ? 12.0 : 16.0;
    final borderRadius = isMobile ? 12.0 : 16.0;
    final monthRevenue = state.totalRevenue;

    Widget chip(String title, String value, Color color, IconData icon) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: isMobile ? 16 : 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 18.0 : 20.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: isMobile ? 12.0 : 13.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: chip(
            "You'll Get",
            '₹${state.totalBalance.toStringAsFixed(0)}',
            const Color(0xFF00C853),
            Ionicons.arrow_down_circle_outline,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: chip(
            'Revenue',
            '₹${monthRevenue.toStringAsFixed(0)}',
            Colors.blue,
            Ionicons.trending_up_outline,
          ),
        ),
      ],
    );
  }

  void _checkPreviousRoute() {
    try {
      final state = GoRouterState.of(context);
      final qp = state.uri.queryParameters;
      final previousRoute = qp['previousRoute'];

      setState(() {
        _showBackButton = previousRoute == '/admin/more';
      });
    } catch (e) {
      // Router state not available yet, ignore
      setState(() {
        _showBackButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardControllerProvider);
    final adminUser = ref.watch(currentAdminProvider);
    final screenSize = Responsive.getScreenSize(context);
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    return AdminAuthGuard(
      child: _buildMainContent(
        context,
        ref,
        dashboardState,
        adminUser,
        screenSize,
        width,
        foldableBreakpoint,
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState dashboardState,
    adminUser,
    ScreenSize screenSize,
    double width,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    // final isSoundEnabled = ref.watch(adminNotificationSettingsProvider);

    return AdminScaffold(
      title: 'Admin Dashboard',
      titleWidget: Image.asset('assets/admin_navbar_logo.png', height: 90),
      toolbarHeight: 100.0,
      showBackButton: _showBackButton,
      showFloatingActionButton: false,
      actions: [
        /*
        Row(
          children: [
            Icon(
              isSoundEnabled ? Ionicons.volume_high : Ionicons.volume_mute,
              size: 20,
              color: isSoundEnabled ? Colors.green : Colors.grey,
            ),
            Switch(
              value: isSoundEnabled,
              onChanged: (value) {
                ref
                    .read(adminNotificationSettingsProvider.notifier)
                    .toggleSound();
              },
              activeThumbColor: Colors.green,
            ),
            const SizedBox(width: 8),
          ],
        ),
        */
      ],
      onBackPressed:
          _showBackButton
              ? () {
                context.go('/admin/more');
              }
              : null,
      // bottomNavigationBar: _buildCustomBottomBar(context), // Removed to restore default nav
      body: _buildDashboardBody(
        context,
        ref,
        dashboardState,
        adminUser,
        screenSize,
        width,
        foldableBreakpoint,
      ),
    );
  }

  Widget _buildDashboardBody(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState dashboardState,
    adminUser,
    ScreenSize screenSize,
    double width,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    // Show loading state until initialized.
    // We don't block on loading=true to allow background refreshes without hiding content.
    if (!dashboardState.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle devices that need bottom navigation
    // - Mobile devices (< 600px) use mobile layout
    // - Tablet-sized devices (600-882px) like Samsung Galaxy S8+ (740px) use foldable layout
    // - Desktop devices (>= 882px) use desktop layout without bottom nav
    if (width < 600) {
      // Standard mobile devices
      return _buildMobileContent(context, ref, dashboardState, adminUser);
    } else if (width < 882) {
      // Tablet-sized devices (600-882px) that need bottom nav
      // This includes Samsung Galaxy S8+ (740px) and similar devices
      return _buildFoldableContent(
        context,
        ref,
        dashboardState,
        adminUser,
        foldableBreakpoint,
      );
    } else {
      // Desktop devices (>= 882px) - no bottom nav
      return _buildDesktopContent(context, ref, dashboardState, adminUser);
    }
  }

  Widget _buildFoldableContent(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState dashboardState,
    adminUser,
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
        bottomNavHeight +
        systemBottomPadding +
        100; // Increased buffer for floating action bar

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(adminDashboardControllerProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(spacing),
              child: _buildRevenueSummary(context, ref, dashboardState),
            ),
            _buildCustomersList(context, ref, foldableBreakpoint),
            SizedBox(
              height: totalBottomSpacing,
            ), // Padding at end to prevent overlap
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState dashboardState,
    adminUser,
  ) {
    final width = MediaQuery.of(context).size.width;
    final mediaQuery = MediaQuery.of(context);
    final systemBottomPadding = mediaQuery.viewPadding.bottom;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    // Calculate responsive navigation bar height
    final isUltraCompact = width <= 288;
    final isCompact = width <= 400;
    final bottomNavHeight = isUltraCompact ? 56.0 : (isCompact ? 60.0 : 64.0);
    final totalBottomSpacing =
        bottomNavHeight +
        systemBottomPadding +
        100; // Increased buffer for floating action bar

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(adminDashboardControllerProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildRevenueSummary(context, ref, dashboardState),
            ),
            _buildCustomersList(context, ref, foldableBreakpoint),
            SizedBox(
              height: totalBottomSpacing,
            ), // Padding at end to prevent overlap
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    WidgetRef ref,
    AdminDashboardState dashboardState,
    adminUser,
  ) {
    final width = MediaQuery.of(context).size.width;
    final foldableBreakpoint = Responsive.getFoldableBreakpoint(width);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(adminDashboardControllerProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRevenueSummary(context, ref, dashboardState),
            const SizedBox(height: 20),
            _buildCustomersList(context, ref, foldableBreakpoint),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Customer customer) {
    final isManufacturer = customer.isManufacturer;
    final entityType = isManufacturer ? 'Manufacturer' : 'Store';

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Delete $entityType'),
            content: Text(
              'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final success = await ref
                      .read(adminCustomerControllerProvider.notifier)
                      .deleteCustomer(customer.id);

                  if (mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$entityType deleted successfully'),
                        ),
                      );
                    } else {
                      final error =
                          ref.read(adminCustomerControllerProvider).error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to delete $entityType: ${error ?? "Unknown error"}',
                          ),
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Widget _buildCustomersList(
    BuildContext context,
    WidgetRef ref,
    FoldableBreakpoint foldableBreakpoint,
  ) {
    final customerState = ref.watch(adminCustomerControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final spacing = Responsive.getSpacingForFoldable(width);
    final isUltraCompact = Responsive.isUltraCompactDevice(width);
    final isFoldable = Responsive.isFoldableMobile(width);

    final headerPadding =
        isUltraCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
            : isFoldable
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 16);

    final borderRadius = isUltraCompact ? 12.0 : 16.0;

    String title;
    if (_bottomTabIndex == 0) {
      title = 'Parties';
    } else if (_bottomTabIndex == 1) {
      title = 'Transactions';
    } else {
      title = 'Items';
    }

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: headerPadding,
            child: Row(
              children: [
                if (_bottomTabIndex != 0) ...[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize:
                          isUltraCompact ? 15.0 : (isFoldable ? 16.0 : 17.0),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (_bottomTabIndex == 0) ...[
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _partySearchController,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Search stores...',
                          hintStyle: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          prefixIcon: const Icon(
                            Ionicons.search_outline,
                            size: 18,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.5),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                        onChanged: (value) {
                          ref
                              .read(adminCustomerControllerProvider.notifier)
                              .searchCustomers(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else
                  const Spacer(),
                if (_bottomTabIndex == 0)
                  PopupMenuButton<String>(
                    tooltip: 'Add Party',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Ionicons.add_outline,
                            color: Colors.black,
                            size:
                                isUltraCompact
                                    ? 18.0
                                    : (isFoldable ? 20.0 : 22.0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Party',
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'store') {
                        context.push('/admin/customers/create');
                      } else if (value == 'manufacturer') {
                        context.push('/admin/manufacturers/add');
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'store',
                          child: Text('Create Store'),
                        ),
                        PopupMenuItem(
                          value: 'manufacturer',
                          child: Text('Create Manufacturer'),
                        ),
                      ];
                    },
                  )
                else if (_bottomTabIndex == 1)
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const TransactionTypeSheet(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Ionicons.add_outline,
                            color: Colors.black,
                            size:
                                isUltraCompact
                                    ? 18.0
                                    : (isFoldable ? 20.0 : 22.0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_bottomTabIndex == 2)
                  PopupMenuButton<String>(
                    tooltip: 'Add Item',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Ionicons.add_outline,
                            color: Colors.black,
                            size:
                                isUltraCompact
                                    ? 18.0
                                    : (isFoldable ? 20.0 : 22.0),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Item',
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'product') {
                        context.pushNamed('admin-product-form');
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'product',
                          child: Text('Add Product'),
                        ),
                      ];
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: isUltraCompact ? 12.0 : (isFoldable ? 16.0 : 20.0),
              right: 4.0,
              top: isUltraCompact ? 8.0 : (isFoldable ? 10.0 : 12.0),
              bottom: isUltraCompact ? 8.0 : (isFoldable ? 10.0 : 12.0),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Parties'),
                    selected: _bottomTabIndex == 0,
                    onSelected: (_) => setState(() => _bottomTabIndex = 0),
                    selectedColor: const Color(0xFFFFC107),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color:
                          _bottomTabIndex == 0 ? Colors.black : Colors.black87,
                      fontWeight:
                          _bottomTabIndex == 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            _bottomTabIndex == 0
                                ? Colors.transparent
                                : Colors.black,
                        width: 1.5,
                      ),
                    ),
                    showCheckmark: _bottomTabIndex == 0,
                    checkmarkColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Transactions'),
                    selected: _bottomTabIndex == 1,
                    onSelected: (_) {
                      setState(() => _bottomTabIndex = 1);
                      ref
                          .read(creditSystemControllerProvider.notifier)
                          .loadTransactions();
                    },
                    selectedColor: const Color(0xFFFFC107),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color:
                          _bottomTabIndex == 1 ? Colors.black : Colors.black87,
                      fontWeight:
                          _bottomTabIndex == 1
                              ? FontWeight.bold
                              : FontWeight.w500,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            _bottomTabIndex == 1
                                ? Colors.transparent
                                : Colors.black,
                        width: 1.5,
                      ),
                    ),
                    showCheckmark: _bottomTabIndex == 1,
                    checkmarkColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Items'),
                    selected: _bottomTabIndex == 2,
                    onSelected: (_) => setState(() => _bottomTabIndex = 2),
                    selectedColor: const Color(0xFFFFC107),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color:
                          _bottomTabIndex == 2 ? Colors.black : Colors.black87,
                      fontWeight:
                          _bottomTabIndex == 2
                              ? FontWeight.bold
                              : FontWeight.w500,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color:
                            _bottomTabIndex == 2
                                ? Colors.transparent
                                : Colors.black,
                        width: 1.5,
                      ),
                    ),
                    showCheckmark: _bottomTabIndex == 2,
                    checkmarkColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_bottomTabIndex == 0) ...[
            if (customerState.loading)
              Padding(
                padding: EdgeInsets.all(
                  isUltraCompact ? 12.0 : (isFoldable ? 16.0 : 20.0),
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (customerState.filteredCustomers.isEmpty)
              Padding(
                padding: EdgeInsets.all(
                  isUltraCompact ? 12.0 : (isFoldable ? 16.0 : 20.0),
                ),
                child: Center(
                  child: Text(
                    'No parties found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontSize:
                          isUltraCompact ? 12.0 : (isFoldable ? 13.0 : null),
                    ),
                  ),
                ),
              )
            else ...[
              ...customerState.filteredCustomers.map((customer) {
                // Determine display date (most recent activity)
                DateTime displayDate = customer.createdAt;
                final dates =
                    [
                      customer.lastOrderDate,
                      customer.lastPaymentDate,
                      customer.createdAt,
                    ].where((d) => d != null).map((d) => d!).toList();

                if (dates.isNotEmpty) {
                  displayDate = dates.reduce(
                    (curr, next) => curr.isAfter(next) ? curr : next,
                  );
                }

                // Determine balance text and color
                final balance = customer.totalBalance;
                final formattedAmount = NumberFormat.currency(
                  locale: 'en_IN',
                  symbol: 'Rs ',
                  decimalDigits: 0,
                ).format(balance.abs());

                // Determine status text and color
                String statusText;
                Color statusColor;

                if (balance > 0) {
                  statusText = "You'll Get";
                  statusColor = const Color(0xFF00C853); // Material Green A700
                } else if (balance < 0) {
                  statusText = "You'll Give";
                  statusColor = Colors.red;
                } else {
                  statusText = "";
                  statusColor = Colors.black;
                }

                return InkWell(
                  onTap: () {
                    context.push('/admin/customers/${customer.id}/orders');
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                      left: isUltraCompact ? 12 : (isFoldable ? 14 : 16),
                      right: 0,
                      top: isUltraCompact ? 8 : (isFoldable ? 10 : 12),
                      bottom: isUltraCompact ? 8 : (isFoldable ? 10 : 12),
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Avatar removed as per request
                        const SizedBox(width: 2),

                        // Left Side: Name and Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (customer.alias != null &&
                                        customer.alias!.isNotEmpty)
                                    ? customer.alias!
                                    : customer.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize:
                                      isUltraCompact
                                          ? 18.0
                                          : (isFoldable ? 19.0 : 20.0),
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy').format(displayDate),
                                style: TextStyle(
                                  fontSize:
                                      isUltraCompact
                                          ? 12.0
                                          : (isFoldable ? 13.0 : 14.0),
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right Side: Amount, Label, and Menu
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formattedAmount,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize:
                                        isUltraCompact
                                            ? 15.0
                                            : (isFoldable ? 16.0 : 17.0),
                                    color:
                                        balance == 0
                                            ? Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color
                                            : statusColor,
                                  ),
                                ),
                                if (statusText.isNotEmpty) ...[
                                  const SizedBox(height: 0),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize:
                                          isUltraCompact
                                              ? 10.0
                                              : (isFoldable ? 11.0 : 12.0),
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Removed SizedBox to move price closer to menu (right corner)
                            GestureDetector(
                              onTapDown:
                                  (
                                    _,
                                  ) {}, // Stop tap propagation to parent InkWell
                              child: PopupMenuButton<String>(
                                icon: Icon(
                                  Ionicons.ellipsis_vertical_outline,
                                  size:
                                      isUltraCompact
                                          ? 16
                                          : (isFoldable ? 18 : 20),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 16,
                                onSelected: (value) {
                                  if (value == 'generate_pdf') {
                                    _generateBalancePdf(context, ref, customer);
                                  } else if (value == 'edit') {
                                    if (customer.isManufacturer) {
                                      context.push(
                                        '/admin/manufacturers/${customer.id}/edit',
                                      );
                                    } else {
                                      context.push(
                                        '/admin/customers/${customer.id}/edit',
                                      );
                                    }
                                  } else if (value == 'delete') {
                                    _confirmDelete(context, ref, customer);
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Ionicons.create_outline,
                                              size: 16,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Ionicons.trash_outline,
                                              size: 16,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Delete'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'generate_pdf',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Ionicons.document_text_outline,
                                              size: 16,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Generate Balance PDF'),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (customerState.hasMore)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child:
                      customerState.isLoadingMore
                          ? const Center(child: CircularProgressIndicator())
                          : OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(
                                    adminCustomerControllerProvider.notifier,
                                  )
                                  .loadMoreCustomers();
                            },
                            icon: const Icon(Ionicons.refresh_outline),
                            label: const Text('Load More Parties'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                ),
            ],
          ] else if (_bottomTabIndex == 1) ...[
            // Transactions Filter
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isUltraCompact ? 12.0 : (isFoldable ? 16.0 : 20.0),
                vertical: 8.0,
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final manufacturerState = ref.watch(
                    manufacturerControllerProvider,
                  );
                  final creditState = ref.watch(creditSystemControllerProvider);

                  return DropdownButtonFormField<String>(
                    initialValue: creditState.selectedManufacturerId,
                    decoration: InputDecoration(
                      labelText: 'Filter by Manufacturer',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: spacing,
                        vertical: spacing * 0.75,
                      ),
                      prefixIcon: const Icon(Ionicons.funnel_outline, size: 18),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Manufacturers'),
                      ),
                      ...manufacturerState.manufacturers.map((m) {
                        return DropdownMenuItem(
                          value: m.id,
                          child: Text(m.businessName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      ref
                          .read(creditSystemControllerProvider.notifier)
                          .selectManufacturer(value);
                    },
                  );
                },
              ),
            ),
            // Transactions List
            Builder(
              builder: (context) {
                final creditState = ref.watch(creditSystemControllerProvider);
                if (creditState.isLoading) {
                  return Padding(
                    padding: EdgeInsets.all(
                      isUltraCompact ? 12.0 : (isFoldable ? 16.0 : 20.0),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (creditState.transactions.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(
                      isUltraCompact ? 12.0 : (isFoldable ? 16.0 : 20.0),
                    ),
                    child: Center(
                      child: Text(
                        'No transactions found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontSize:
                              isUltraCompact
                                  ? 12.0
                                  : (isFoldable ? 13.0 : null),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...creditState.transactions.map((transaction) {
                      Color color;
                      IconData icon;

                      switch (transaction.transactionType) {
                        case CreditTransactionType.payin:
                          color = const Color(0xFF00C853);
                          icon = Ionicons.arrow_down_circle_outline;
                          break;
                        case CreditTransactionType.payout:
                          color = Colors.blue;
                          icon = Ionicons.arrow_up_circle_outline;
                          break;
                        case CreditTransactionType.purchase:
                          color = Colors.orange;
                          icon = Ionicons.cart_outline;
                          break;
                      }

                      final formattedAmount = NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹ ',
                        decimalDigits: 0,
                      ).format(transaction.amount);

                      return InkWell(
                        onTap: () {
                          // Show transaction details if needed
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                            left: isUltraCompact ? 12 : (isFoldable ? 14 : 16),
                            right: isUltraCompact ? 12 : (isFoldable ? 14 : 16),
                            top: isUltraCompact ? 12 : (isFoldable ? 14 : 16),
                            bottom:
                                isUltraCompact ? 12 : (isFoldable ? 14 : 16),
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Icon
                              Container(
                                padding: EdgeInsets.all(isUltraCompact ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: color,
                                  size: isUltraCompact ? 16 : 20,
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Left Side: Name and Type
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            transaction.displayName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  isUltraCompact
                                                      ? 14.0
                                                      : (isFoldable
                                                          ? 15.0
                                                          : 16.0),
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge?.color,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Reference number hidden as per request
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(transaction.transactionDate),
                                      style: TextStyle(
                                        fontSize:
                                            isUltraCompact
                                                ? 12.0
                                                : (isFoldable ? 13.0 : 14.0),
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right Side: Amount
                              Text(
                                formattedAmount,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      isUltraCompact
                                          ? 14.0
                                          : (isFoldable ? 15.0 : 16.0),
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ] else ...[
            const SizedBox.shrink(),
            Builder(
              builder: (context) {
                final sharedState = ref.watch(sharedProductProvider);
                final products = ref.watch(allProductsProvider);
                if (sharedState.isLoading) {
                  return Padding(
                    padding: EdgeInsets.all(
                      isUltraCompact ? 12.0 : (isFoldable ? 16.0 : 20.0),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (products.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(
                      isUltraCompact ? 12.0 : (isFoldable ? 16.0 : 20.0),
                    ),
                    child: Center(
                      child: Text(
                        'No items yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontSize:
                              isUltraCompact
                                  ? 12.0
                                  : (isFoldable ? 13.0 : null),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...products.map((product) {
                      final formattedAmount = NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹ ',
                        decimalDigits: 0,
                      ).format(product.finalPrice);
                      return InkWell(
                        onTap: () {
                          context.pushNamed(
                            'admin-product-detail',
                            pathParameters: {'id': product.id},
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.only(
                            left: isUltraCompact ? 12 : (isFoldable ? 14 : 16),
                            right: 0,
                            top: isUltraCompact ? 12 : (isFoldable ? 14 : 16),
                            bottom:
                                isUltraCompact ? 12 : (isFoldable ? 14 : 16),
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        isUltraCompact
                                            ? 14.0
                                            : (isFoldable ? 15.0 : 16.0),
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                formattedAmount,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      isUltraCompact
                                          ? 14.0
                                          : (isFoldable ? 15.0 : 16.0),
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: Icon(
                                  Ionicons.create_outline,
                                  size: isUltraCompact ? 18 : 20,
                                ),
                                tooltip: 'Edit Product',
                                onPressed: () {
                                  context.pushNamed(
                                    'admin-product-form',
                                    extra: product,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (products.length > 10)
                      _buildViewAllButton(
                        context,
                        'View All Items',
                        () => context.push('/admin/products'),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewAllButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Ionicons.chevron_forward_outline, size: 16),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// Generate balance PDF for a customer
  Future<void> _generateBalancePdf(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generating PDF...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final pdfService = ref.read(customerBalancePdfServiceProvider);
      final pdfBytes = await pdfService.generateBalancePdf(customer);

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show PDF
        await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showPartySelectionDialog(
    BuildContext context,
    bool isPaymentIn,
  ) async {
    final customers = ref.read(adminCustomerControllerProvider).customers;
    final filteredParties =
        customers.where((c) {
          if (isPaymentIn) {
            return !c.isManufacturer; // Payment In -> Customers
          } else {
            return c.isManufacturer; // Payment Out -> Manufacturers
          }
        }).toList();

    Customer? selectedParty = await showDialog<Customer>(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPaymentIn ? 'Select Customer' : 'Select Manufacturer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Ionicons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Implement local filtering if needed
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredParties.length,
                      itemBuilder: (context, index) {
                        final party = filteredParties[index];
                        return ListTile(
                          title: Text(party.name),
                          subtitle: Text(party.phone),
                          onTap: () => Navigator.pop(context, party),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (selectedParty != null) {
      if (mounted) {
        _showPaymentDialog(context, selectedParty, isPaymentIn);
      }
    }
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    Customer party,
    bool isPaymentIn,
  ) async {
    final amountController = TextEditingController(
      text: party.totalBalance > 0 ? party.totalBalance.toStringAsFixed(2) : '',
    );
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedMode = 'Cash'; // Default
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isPaymentIn ? 'Receive Payment' : 'Make Payment'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(party.name),
                      subtitle: Text(isPaymentIn ? 'Customer' : 'Manufacturer'),
                      leading: const Icon(Ionicons.person),
                    ),
                    const Divider(),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          ['Cash', 'Bank Transfer', 'UPI', 'Cheque', 'Other']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) => selectedMode = v!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final amount = double.parse(amountController.text);

                    try {
                      Navigator.pop(context); // Close dialog first

                      if (isPaymentIn) {
                        // Receive Payment (Customer)
                        await ref
                            .read(paymentReceiptRepositoryProvider)
                            .createPaymentReceipt(
                              orderId: null, // General payment
                              customerId: party.id,
                              receiptNumber:
                                  'REC-${DateTime.now().millisecondsSinceEpoch}',
                              paymentDate: selectedDate,
                              amount: amount,
                              paymentType: selectedMode,
                              description: descriptionController.text,
                              createdBy:
                                  ref
                                      .read(adminAuthControllerProvider)
                                      .adminUser
                                      ?.id ??
                                  '',
                            );
                      } else {
                        // Make Payment (Vendor)
                        PaymentMethod method;
                        switch (selectedMode) {
                          case 'Cash':
                            method = PaymentMethod.cash;
                            break;
                          case 'Bank Transfer':
                            method = PaymentMethod.bankTransfer;
                            break;
                          case 'UPI':
                            method = PaymentMethod.upi;
                            break;
                          case 'Cheque':
                            method = PaymentMethod.cheque;
                            break;
                          default:
                            method = PaymentMethod.other;
                        }

                        await ref
                            .read(creditTransactionRepositoryProvider)
                            .createCreditTransaction(
                              manufacturerId: party.id,
                              transactionType:
                                  CreditTransactionType
                                      .payin, // Admin pays entity
                              amount: amount,
                              createdBy:
                                  ref
                                      .read(adminAuthControllerProvider)
                                      .adminUser
                                      ?.id ??
                                  '',
                              paymentMethod: method,
                              description: descriptionController.text,
                              transactionDate: selectedDate,
                            );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction recorded successfully'),
                          ),
                        );
                        // Refresh data
                        ref.invalidate(adminCustomerControllerProvider);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}
