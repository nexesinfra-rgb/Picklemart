import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/layout/responsive.dart';
import '../../data/analytics_models.dart';

class AnalyticsFilterBar extends ConsumerStatefulWidget {
  final Function(AnalyticsFilter) onFilterChanged;

  const AnalyticsFilterBar({super.key, required this.onFilterChanged});

  @override
  ConsumerState<AnalyticsFilterBar> createState() => _AnalyticsFilterBarState();
}

class _AnalyticsFilterBarState extends ConsumerState<AnalyticsFilterBar> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.today;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  String? _selectedProduct;
  String? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bp = Responsive.breakpointForWidth(width);
    final isCompact = bp == AppBreakpoint.compact;
    final isMobile = width < 600;

    return Container(
      padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          if (isMobile) ...[
            _buildMobileFilters(context, isCompact),
          ] else ...[
            _buildDesktopFilters(context, isCompact),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileFilters(BuildContext context, bool isCompact) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPeriodDropdown(context, isCompact)),
            const SizedBox(width: 8),
            _buildFilterButton(context, isCompact),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildCategoryDropdown(context, isCompact)),
            const SizedBox(width: 8),
            Expanded(child: _buildProductDropdown(context, isCompact)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFilters(BuildContext context, bool isCompact) {
    return Row(
      children: [
        _buildPeriodDropdown(context, isCompact),
        const SizedBox(width: 16),
        _buildCategoryDropdown(context, isCompact),
        const SizedBox(width: 16),
        _buildProductDropdown(context, isCompact),
        const SizedBox(width: 16),
        _buildCustomerDropdown(context, isCompact),
        const Spacer(),
        _buildFilterButton(context, isCompact),
        const SizedBox(width: 8),
        _buildClearButton(context, isCompact),
      ],
    );
  }

  Widget _buildPeriodDropdown(BuildContext context, bool isCompact) {
    return DropdownButtonFormField<AnalyticsPeriod>(
      initialValue: _selectedPeriod,
      decoration: InputDecoration(
        labelText: 'Period',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 8 : 12,
        ),
        border: const OutlineInputBorder(),
      ),
      style: TextStyle(fontSize: isCompact ? 12 : 14),
      items:
          AnalyticsPeriod.values.map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(_getPeriodLabel(period)),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPeriod = value;
          });
          _applyFilter();
        }
      },
    );
  }

  Widget _buildCategoryDropdown(BuildContext context, bool isCompact) {
    final categories = [
      'All Categories',
      'Safety Equipment',
      'Power Tools',
      'Hand Tools',
      'Hardware',
      'Protective Gear',
      'Workwear',
      'Accessories',
    ];

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory ?? 'All Categories',
      decoration: InputDecoration(
        labelText: 'Category',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 8 : 12,
        ),
        border: const OutlineInputBorder(),
      ),
      style: TextStyle(fontSize: isCompact ? 12 : 14),
      items:
          categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value == 'All Categories' ? null : value;
        });
        _applyFilter();
      },
    );
  }

  Widget _buildProductDropdown(BuildContext context, bool isCompact) {
    final products = [
      'All Products',
      'Heavy Duty Work Gloves',
      'Professional Drill Set',
      'Industrial Hammer',
      'Precision Cutter',
      'Adjustable Wrench',
      'Safety Helmet',
      'Work Boots',
    ];

    return DropdownButtonFormField<String>(
      initialValue: _selectedProduct ?? 'All Products',
      decoration: InputDecoration(
        labelText: 'Product',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 8 : 12,
        ),
        border: const OutlineInputBorder(),
      ),
      style: TextStyle(fontSize: isCompact ? 12 : 14),
      items:
          products.map((product) {
            return DropdownMenuItem(value: product, child: Text(product));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedProduct = value == 'All Products' ? null : value;
        });
        _applyFilter();
      },
    );
  }

  Widget _buildCustomerDropdown(BuildContext context, bool isCompact) {
    final customers = [
      'All Customers',
      'John Smith',
      'Sarah Johnson',
      'Mike Wilson',
      'Emily Davis',
      'David Brown',
    ];

    return DropdownButtonFormField<String>(
      initialValue: _selectedCustomer ?? 'All Customers',
      decoration: InputDecoration(
        labelText: 'Customer',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 8 : 12,
        ),
        border: const OutlineInputBorder(),
      ),
      style: TextStyle(fontSize: isCompact ? 12 : 14),
      items:
          customers.map((customer) {
            return DropdownMenuItem(value: customer, child: Text(customer));
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCustomer = value == 'All Customers' ? null : value;
        });
        _applyFilter();
      },
    );
  }

  Widget _buildFilterButton(BuildContext context, bool isCompact) {
    return IconButton(
      onPressed: _applyFilter,
      icon: const Icon(Ionicons.filter_outline),
      tooltip: 'Apply Filters',
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildClearButton(BuildContext context, bool isCompact) {
    return IconButton(
      onPressed: _clearFilters,
      icon: const Icon(Ionicons.refresh_outline),
      tooltip: 'Clear Filters',
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }

  void _applyFilter() {
    final filter = AnalyticsFilter(
      period: _selectedPeriod,
      startDate: _startDate,
      endDate: _endDate,
      category: _selectedCategory,
      product: _selectedProduct,
      customer: _selectedCustomer,
    );

    widget.onFilterChanged(filter);
  }

  void _clearFilters() {
    setState(() {
      _selectedPeriod = AnalyticsPeriod.today;
      _startDate = null;
      _endDate = null;
      _selectedCategory = null;
      _selectedProduct = null;
      _selectedCustomer = null;
    });

    _applyFilter();
  }

  String _getPeriodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.today:
        return 'Today';
      case AnalyticsPeriod.week:
        return 'This Week';
      case AnalyticsPeriod.month:
        return 'This Month';
      case AnalyticsPeriod.quarter:
        return 'This Quarter';
      case AnalyticsPeriod.year:
        return 'This Year';
      case AnalyticsPeriod.allTime:
        return 'All Time';
    }
  }
}
