import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/seo_models.dart';

class AdminSEOState {
  final bool loading;
  final String? error;
  final List<SEOAnalysis> analyses;
  final List<SEOMetaTag> metaTags;
  final List<SEOSitemap> sitemaps;
  final SEORobotsTxt? robotsTxt;
  final String searchQuery;
  final SEOAnalysis? selectedAnalysis;

  const AdminSEOState({
    this.loading = false,
    this.error,
    this.analyses = const [],
    this.metaTags = const [],
    this.sitemaps = const [],
    this.robotsTxt,
    this.searchQuery = '',
    this.selectedAnalysis,
  });

  AdminSEOState copyWith({
    bool? loading,
    String? error,
    List<SEOAnalysis>? analyses,
    List<SEOMetaTag>? metaTags,
    List<SEOSitemap>? sitemaps,
    SEORobotsTxt? robotsTxt,
    String? searchQuery,
    SEOAnalysis? selectedAnalysis,
  }) {
    return AdminSEOState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      analyses: analyses ?? this.analyses,
      metaTags: metaTags ?? this.metaTags,
      sitemaps: sitemaps ?? this.sitemaps,
      robotsTxt: robotsTxt ?? this.robotsTxt,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedAnalysis: selectedAnalysis ?? this.selectedAnalysis,
    );
  }
}

class AdminSEOController extends StateNotifier<AdminSEOState> {
  AdminSEOController(this._ref) : super(const AdminSEOState()) {
    loadAnalyses();
    loadMetaTags();
    loadSitemaps();
    loadRobotsTxt();
  }

  final Ref _ref;

  Future<void> loadAnalyses() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));

      final mockAnalyses = [
        SEOAnalysis(
          id: 'seo_1',
          url: 'https://sm.com/products',
          title: 'Products - SM Store',
          description: 'Browse our amazing collection of products',
          score: 85,
          issues: [
            SEOIssue(
              id: 'issue_1',
              type: 'title_length',
              title: 'Title too long',
              description: 'Page title exceeds 60 characters',
              priority: SEOPriority.normal,
              solution: 'Shorten the title to under 60 characters',
              createdAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
            SEOIssue(
              id: 'issue_2',
              type: 'meta_description',
              title: 'Missing meta description',
              description: 'Page is missing meta description',
              priority: SEOPriority.high,
              solution: 'Add a compelling meta description',
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ],
          suggestions: [
            SEOSuggestion(
              id: 'suggestion_1',
              type: 'header_structure',
              title: 'Improve header structure',
              description: 'Use proper H1, H2, H3 hierarchy',
              priority: SEOPriority.normal,
              implementation:
                  'Add H1 tag and organize content with proper headers',
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ],
          metrics: {
            'page_speed': 78,
            'mobile_friendly': 92,
            'accessibility': 85,
          },
          analyzedAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        SEOAnalysis(
          id: 'seo_2',
          url: 'https://sm.com/blog',
          title: 'Blog - SM Store',
          description: 'Read our latest blog posts and articles',
          score: 92,
          issues: [],
          suggestions: [
            SEOSuggestion(
              id: 'suggestion_2',
              type: 'internal_linking',
              title: 'Add more internal links',
              description: 'Include more internal links to related content',
              priority: SEOPriority.low,
              implementation:
                  'Add links to related blog posts and product pages',
              createdAt: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ],
          metrics: {
            'page_speed': 88,
            'mobile_friendly': 95,
            'accessibility': 90,
          },
          analyzedAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];

      state = state.copyWith(analyses: mockAnalyses, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadMetaTags() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final mockMetaTags = [
        SEOMetaTag(
          id: 'meta_1',
          name: 'description',
          content: 'SM Store - Your one-stop shop for electronics and gadgets',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        SEOMetaTag(
          id: 'meta_2',
          name: 'keywords',
          content: 'electronics, gadgets, store, online shopping, technology',
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        SEOMetaTag(
          id: 'meta_3',
          name: 'og:title',
          content: 'SM Store - Electronics & Gadgets',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        SEOMetaTag(
          id: 'meta_4',
          name: 'og:description',
          content: 'Discover amazing electronics and gadgets at SM Store',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];

      state = state.copyWith(metaTags: mockMetaTags, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadSitemaps() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final mockSitemaps = [
        SEOSitemap(
          id: 'sitemap_1',
          url: 'https://sm.com/',
          priority: 1.0,
          changeFrequency: 'daily',
          lastModified: DateTime.now().subtract(const Duration(hours: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        SEOSitemap(
          id: 'sitemap_2',
          url: 'https://sm.com/products',
          priority: 0.9,
          changeFrequency: 'weekly',
          lastModified: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        SEOSitemap(
          id: 'sitemap_3',
          url: 'https://sm.com/blog',
          priority: 0.8,
          changeFrequency: 'daily',
          lastModified: DateTime.now().subtract(const Duration(hours: 6)),
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ];

      state = state.copyWith(sitemaps: mockSitemaps, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadRobotsTxt() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final mockRobotsTxt = SEORobotsTxt(
        id: 'robots_1',
        content: '''User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/
Disallow: /private/

Sitemap: https://sm.com/sitemap.xml''',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      state = state.copyWith(robotsTxt: mockRobotsTxt, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void searchAnalyses(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> analyzeUrl(String url) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 2));

      // Simulate analysis
      final newAnalysis = SEOAnalysis(
        id: 'seo_${DateTime.now().millisecondsSinceEpoch}',
        url: url,
        title: 'Analyzed Page',
        description: 'This page has been analyzed for SEO',
        score: 75,
        issues: [
          SEOIssue(
            id: 'issue_${DateTime.now().millisecondsSinceEpoch}',
            type: 'general',
            title: 'New analysis completed',
            description: 'This is a newly analyzed page',
            priority: SEOPriority.normal,
            createdAt: DateTime.now(),
          ),
        ],
        suggestions: [],
        metrics: {'page_speed': 80, 'mobile_friendly': 85, 'accessibility': 75},
        analyzedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        analyses: [...state.analyses, newAnalysis],
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> createMetaTag(SEOMetaTag metaTag) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        metaTags: [...state.metaTags, metaTag],
        loading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateMetaTag(SEOMetaTag updatedMetaTag) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedTags =
          state.metaTags.map((tag) {
            if (tag.id == updatedMetaTag.id) {
              return updatedMetaTag;
            }
            return tag;
          }).toList();

      state = state.copyWith(metaTags: updatedTags, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteMetaTag(String metaTagId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedTags =
          state.metaTags.where((tag) => tag.id != metaTagId).toList();
      state = state.copyWith(metaTags: updatedTags, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateRobotsTxt(SEORobotsTxt robotsTxt) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(robotsTxt: robotsTxt, loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }

  void selectAnalysis(SEOAnalysis? analysis) {
    state = state.copyWith(selectedAnalysis: analysis);
  }

  void refresh() {
    loadAnalyses();
    loadMetaTags();
    loadSitemaps();
    loadRobotsTxt();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final adminSEOControllerProvider =
    StateNotifierProvider<AdminSEOController, AdminSEOState>(
      (ref) => AdminSEOController(ref),
    );
