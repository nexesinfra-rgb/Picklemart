import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/marketing_models.dart';

class AdminMarketingState {
  final bool loading;
  final String? error;
  final List<MarketingCampaign> campaigns;
  final List<MarketingCampaign> filteredCampaigns;
  final List<MarketingTemplate> templates;
  final List<CampaignMetrics> metrics;
  final String searchQuery;
  final CampaignType? selectedType;
  final CampaignStatus? selectedStatus;
  final MarketingCampaign? selectedCampaign;
  final MarketingTemplate? selectedTemplate;

  const AdminMarketingState({
    this.loading = false,
    this.error,
    this.campaigns = const [],
    List<MarketingCampaign>? filteredCampaigns,
    this.templates = const [],
    this.metrics = const [],
    this.searchQuery = '',
    this.selectedType,
    this.selectedStatus,
    this.selectedCampaign,
    this.selectedTemplate,
  }) : filteredCampaigns = filteredCampaigns ?? campaigns;

  AdminMarketingState copyWith({
    bool? loading,
    String? error,
    List<MarketingCampaign>? campaigns,
    List<MarketingCampaign>? filteredCampaigns,
    List<MarketingTemplate>? templates,
    List<CampaignMetrics>? metrics,
    String? searchQuery,
    CampaignType? selectedType,
    CampaignStatus? selectedStatus,
    MarketingCampaign? selectedCampaign,
    MarketingTemplate? selectedTemplate,
  }) {
    return AdminMarketingState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      campaigns: campaigns ?? this.campaigns,
      filteredCampaigns: filteredCampaigns ?? this.filteredCampaigns,
      templates: templates ?? this.templates,
      metrics: metrics ?? this.metrics,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedCampaign: selectedCampaign ?? this.selectedCampaign,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    );
  }
}

class AdminMarketingController extends StateNotifier<AdminMarketingState> {
  AdminMarketingController(this._ref) : super(const AdminMarketingState()) {
    loadCampaigns();
    loadTemplates();
    loadMetrics();
  }

  final Ref _ref;

  Future<void> loadCampaigns() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));

      final mockCampaigns = [
        EmailCampaign(
          id: 'campaign_1',
          name: 'Welcome Email Series',
          description: 'Welcome new customers with our email series',
          status: CampaignStatus.running,
          priority: CampaignPriority.high,
          targetAudience: 'new_customers',
          subject: 'Welcome to SM Store!',
          content:
              'Thank you for joining us. Here are some exclusive offers...',
          templateId: 'template_1',
          recipients: ['customer1@example.com', 'customer2@example.com'],
          createdBy: 'admin',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          startedAt: DateTime.now().subtract(const Duration(days: 10)),
          budget: 500.0,
          spent: 150.0,
        ),
        SMSCampaign(
          id: 'campaign_2',
          name: 'Flash Sale Alert',
          description: 'Alert customers about flash sales via SMS',
          status: CampaignStatus.scheduled,
          priority: CampaignPriority.urgent,
          targetAudience: 'all_customers',
          message:
              'Flash Sale! 50% off on all electronics. Limited time offer!',
          templateId: 'template_2',
          recipients: ['+1234567890', '+0987654321'],
          scheduledAt: DateTime.now().add(const Duration(hours: 2)),
          createdBy: 'admin',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          budget: 200.0,
          spent: 0.0,
        ),
        PushCampaign(
          id: 'campaign_3',
          name: 'New Product Launch',
          description: 'Notify users about new product launches',
          status: CampaignStatus.completed,
          priority: CampaignPriority.normal,
          targetAudience: 'mobile_users',
          title: 'New Product Available!',
          message: 'Check out our latest smartphone with amazing features',
          actionUrl: 'https://sm.com/products/smartphone',
          targetDevices: ['ios', 'android'],
          createdBy: 'admin',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          startedAt: DateTime.now().subtract(const Duration(days: 15)),
          endedAt: DateTime.now().subtract(const Duration(days: 5)),
          budget: 300.0,
          spent: 280.0,
        ),
      ];

      state = state.copyWith(
        campaigns: mockCampaigns,
        filteredCampaigns: _filterCampaigns(
          mockCampaigns,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadTemplates() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final mockTemplates = [
        MarketingTemplate(
          id: 'template_1',
          name: 'Welcome Email Template',
          type: 'email',
          content: 'Welcome to {{store_name}}! Thank you for joining us.',
          variables: {
            'store_name': 'Store Name',
            'customer_name': 'Customer Name',
            'discount_code': 'Discount Code',
          },
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
          createdBy: 'admin',
        ),
        MarketingTemplate(
          id: 'template_2',
          name: 'SMS Flash Sale Template',
          type: 'sms',
          content:
              'Flash Sale! {{discount_percent}}% off on {{category}}. Code: {{discount_code}}',
          variables: {
            'discount_percent': 'Discount Percent',
            'category': 'Category',
            'discount_code': 'Discount Code',
          },
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
          createdBy: 'admin',
        ),
        MarketingTemplate(
          id: 'template_3',
          name: 'Push Notification Template',
          type: 'push',
          content:
              'New {{product_type}} available! {{product_name}} - {{price}}',
          variables: {
            'product_type': 'Product Type',
            'product_name': 'Product Name',
            'price': 'Price',
          },
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          createdBy: 'admin',
        ),
      ];

      state = state.copyWith(templates: mockTemplates, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMetrics() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final mockMetrics = [
        CampaignMetrics(
          campaignId: 'campaign_1',
          totalSent: 1000,
          totalDelivered: 950,
          totalOpened: 380,
          totalClicked: 95,
          totalUnsubscribed: 5,
          totalBounced: 50,
          openRate: 40.0,
          clickRate: 10.0,
          conversionRate: 5.0,
          revenue: 2500.0,
          lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        CampaignMetrics(
          campaignId: 'campaign_3',
          totalSent: 5000,
          totalDelivered: 4800,
          totalOpened: 1920,
          totalClicked: 480,
          totalUnsubscribed: 20,
          totalBounced: 200,
          openRate: 40.0,
          clickRate: 10.0,
          conversionRate: 8.0,
          revenue: 12000.0,
          lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      state = state.copyWith(metrics: mockMetrics, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  List<MarketingCampaign> _filterCampaigns(
    List<MarketingCampaign> campaigns,
    String query,
    CampaignType? type,
    CampaignStatus? status,
  ) {
    return campaigns.where((campaign) {
      final matchesSearch =
          query.isEmpty ||
          campaign.name.toLowerCase().contains(query.toLowerCase()) ||
          campaign.description.toLowerCase().contains(query.toLowerCase());

      final matchesType = type == null || campaign.type == type;
      final matchesStatus = status == null || campaign.status == status;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  void searchCampaigns(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredCampaigns: _filterCampaigns(
        state.campaigns,
        query,
        state.selectedType,
        state.selectedStatus,
      ),
    );
  }

  void filterByType(CampaignType? type) {
    state = state.copyWith(
      selectedType: type,
      filteredCampaigns: _filterCampaigns(
        state.campaigns,
        state.searchQuery,
        type,
        state.selectedStatus,
      ),
    );
  }

  void filterByStatus(CampaignStatus? status) {
    state = state.copyWith(
      selectedStatus: status,
      filteredCampaigns: _filterCampaigns(
        state.campaigns,
        state.searchQuery,
        state.selectedType,
        status,
      ),
    );
  }

  Future<bool> createCampaign(MarketingCampaign campaign) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedCampaigns = [...state.campaigns, campaign];
      state = state.copyWith(
        campaigns: updatedCampaigns,
        filteredCampaigns: _filterCampaigns(
          updatedCampaigns,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateCampaign(MarketingCampaign updatedCampaign) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedCampaigns =
          state.campaigns.map((campaign) {
            if (campaign.id == updatedCampaign.id) {
              return updatedCampaign;
            }
            return campaign;
          }).toList();

      state = state.copyWith(
        campaigns: updatedCampaigns,
        filteredCampaigns: _filterCampaigns(
          updatedCampaigns,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCampaign(String campaignId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedCampaigns =
          state.campaigns
              .where((campaign) => campaign.id != campaignId)
              .toList();
      state = state.copyWith(
        campaigns: updatedCampaigns,
        filteredCampaigns: _filterCampaigns(
          updatedCampaigns,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> startCampaign(String campaignId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedCampaigns =
          state.campaigns.map((campaign) {
            if (campaign.id == campaignId) {
              return campaign.copyWith(
                status: CampaignStatus.running,
                startedAt: DateTime.now(),
              );
            }
            return campaign;
          }).toList();

      state = state.copyWith(
        campaigns: updatedCampaigns,
        filteredCampaigns: _filterCampaigns(
          updatedCampaigns,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> pauseCampaign(String campaignId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedCampaigns =
          state.campaigns.map((campaign) {
            if (campaign.id == campaignId) {
              return campaign.copyWith(status: CampaignStatus.paused);
            }
            return campaign;
          }).toList();

      state = state.copyWith(
        campaigns: updatedCampaigns,
        filteredCampaigns: _filterCampaigns(
          updatedCampaigns,
          state.searchQuery,
          state.selectedType,
          state.selectedStatus,
        ),
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> createTemplate(MarketingTemplate template) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        templates: [...state.templates, template],
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  CampaignMetrics? getCampaignMetrics(String campaignId) {
    try {
      return state.metrics.firstWhere(
        (metric) => metric.campaignId == campaignId,
      );
    } catch (e) {
      return null;
    }
  }

  void selectCampaign(MarketingCampaign? campaign) {
    state = state.copyWith(selectedCampaign: campaign);
  }

  void selectTemplate(MarketingTemplate? template) {
    state = state.copyWith(selectedTemplate: template);
  }

  void refresh() {
    loadCampaigns();
    loadTemplates();
    loadMetrics();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final adminMarketingControllerProvider =
    StateNotifierProvider<AdminMarketingController, AdminMarketingState>(
      (ref) => AdminMarketingController(ref),
    );
