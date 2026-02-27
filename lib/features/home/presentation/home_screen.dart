import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/ui/responsive_buttons.dart';
import '../../catalog/data/product.dart';
import '../../catalog/data/shared_product_provider.dart' as shared;
import '../../admin/data/admin_features.dart';
import '../../notifications/application/notification_controller.dart';
import '../../chat/application/chat_controller.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/home_featured_categories_strip.dart';
import 'widgets/category_section.dart';
import '../../../../core/widgets/lazy_image.dart';
import '../data/hero_image_provider.dart';
import '../../admin/data/hero_image_model.dart';
import '../../catalog/presentation/widgets/universal_product_card.dart';
// import 'widgets/product_carousel.dart'; // Removed for new implementation
// import 'widgets/category_product_rows.dart'; // Replaced with new implementation

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(shared.featuredProductsProvider);
    final features = ref.watch(adminFeaturesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              leading: Consumer(
                builder: (context, ref, _) {
                  final unreadCount = ref.watch(
                    unreadNotificationCountProvider,
                  );
                  final hasUnread = unreadCount > 0;

                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:
                                hasUnread
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                hasUnread
                                    ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.3),
                                      width: 1.5,
                                    )
                                    : null,
                          ),
                          child: ResponsiveIconButton(
                            icon: Icon(
                              hasUnread
                                  ? Ionicons.notifications
                                  : Ionicons.notifications_outline,
                              color:
                                  hasUnread
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                            onPressed: () => context.goNamed('notifications'),
                          ),
                        ),
                        if (hasUnread)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              title: Center(
                child: Image.asset(
                  'assets/admin_navbar_logo.png',
                  height: 58,
                  fit: BoxFit.contain,
                ),
              ),
              actions: [
                // Chat icon (only if enabled)
                if (features.chatEnabled)
                  Consumer(
                    builder: (context, ref, _) {
                      final unreadCountAsync = ref.watch(
                        userChatUnreadCountProvider,
                      );
                      final unreadCount = unreadCountAsync.value ?? 0;
                      final hasUnread = unreadCount > 0;
                      final showBadge = unreadCount >= 9;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    hasUnread
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.1)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    hasUnread
                                        ? Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.3),
                                          width: 1.5,
                                        )
                                        : null,
                              ),
                              child: ResponsiveIconButton(
                                icon: Icon(
                                  hasUnread
                                      ? Ionicons.chatbubbles
                                      : Ionicons.chatbubbles_outline,
                                  color:
                                      hasUnread
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : null,
                                ),
                                onPressed: () {
                                  try {
                                    context.push('/chat');
                                  } catch (e) {
                                    // Fallback to named route
                                    try {
                                      context.pushNamed('chat');
                                    } catch (e2) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Unable to open chat: $e2',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                tooltip: 'Chat with Admin',
                              ),
                            ),
                            if (showBadge)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: const Text(
                                    '9+',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final bp = Responsive.breakpointForWidth(screenWidth);
                      // Calculate hero height based on responsive breakpoints
                      // Mobile: 16:9 aspect ratio, Tablet: 21:9 aspect ratio, Desktop: 21:9 with max 400px
                      double heroHeight;
                      if (screenWidth < 600) {
                        // Mobile - use 16:9 aspect ratio
                        final aspectRatio = 16 / 9;
                        heroHeight = screenWidth / aspectRatio;
                      } else if (screenWidth < 1024) {
                        // Tablet - use 21:9 aspect ratio
                        final aspectRatio = 21 / 9;
                        heroHeight = screenWidth / aspectRatio;
                      } else {
                        // Desktop - use 21:9 aspect ratio with max 400px cap (reduced from 500px)
                        final aspectRatio = 21 / 9;
                        heroHeight = (screenWidth / aspectRatio).clamp(
                          0.0,
                          400.0,
                        );
                      }

                      // Use infinite scroll if enabled, otherwise use regular SingleChildScrollView
                      if (features.infinityScrollEnabled) {
                        return _buildInfiniteScrollContent(
                          context,
                          ref,
                          featured,
                          heroHeight,
                          screenWidth,
                          bp,
                        );
                      } else {
                        return SingleChildScrollView(
                          padding: Responsive.getHomeContentPadding(screenWidth),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    bp == AppBreakpoint.expanded
                                        ? 1200
                                        : double.infinity,
                              ),
                              child: _buildHomeContent(
                                context,
                                ref,
                                featured,
                                heroHeight,
                                bp,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection(
    BuildContext context,
    List<Product> products,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Use unified card widths across all breakpoints
        final cardWidth = Responsive.getUnifiedProductCardWidth(width);

        // Calculate height based on card width and aspect ratio
        final cardAspectRatio = UniversalProductCard.getCardAspectRatio(width, customCardWidth: cardWidth);
        final overflowBuffer = 32.0; // Increased buffer for ListView padding and shadows
        final estimatedCardHeight = (cardWidth / cardAspectRatio) + overflowBuffer;

        // Wrap ListView in SizedBox with calculated height to provide bounded constraint
        // Use responsive horizontal padding matching unified constraints
        final horizontalPadding = Responsive.getProductCardSectionPadding(
          width,
        );
        return SizedBox(
          height: estimatedCardHeight,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, i) {
              final isLast = i == products.length - 1;
              return Padding(
                padding: EdgeInsets.only(right: isLast ? 16 : 8),
                child: SizedBox(
                  width: cardWidth,
                  child: UniversalProductCard(
                    product: products[i],
                    cardWidth: cardWidth,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    WidgetRef ref,
    List<Product> featured,
    double heroHeight,
    AppBreakpoint bp,
  ) {
    return Column(
      children: [
        const HomeSearchBar(),
        const SizedBox(height: 12),
        _ImageCarousel(height: heroHeight),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Featured Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize:
                      bp == AppBreakpoint.expanded
                          ? 24
                          : bp == AppBreakpoint.medium
                          ? 22
                          : 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ResponsiveTextButton(
              onPressed: () => context.goNamed('catalog'),
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: bp == AppBreakpoint.expanded ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
        // Slightly reduce the gap before category sections
        const SizedBox(height: 4),
        const HomeFeaturedCategoriesStrip(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Featured Products',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize:
                      bp == AppBreakpoint.expanded
                          ? 24
                          : bp == AppBreakpoint.medium
                          ? 22
                          : 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ResponsiveTextButton(
              onPressed: () => context.goNamed('featured-products'),
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: bp == AppBreakpoint.expanded ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        featured.isEmpty
            ? const SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'No featured products available',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
            : _buildFeaturedProductsSection(context, featured),
        // Category-based product sections
        Consumer(
          builder: (context, ref, _) {
            final categories = ref.watch(shared.categoriesProvider);
            final allProducts = ref.watch(shared.allProductsProvider);
            final categorySections = <Widget>[];

            // Show top 3-4 categories with products
            for (final category in categories.take(4)) {
              final categoryProducts =
                  allProducts
                      .where(
                        (p) => p.categories.any(
                          (c) => c.toLowerCase() == category.toLowerCase(),
                        ),
                      )
                      .take(10) // Show up to 10 products per category
                      .toList();

              if (categoryProducts.isNotEmpty) {
                categorySections.add(
                  CategorySection(
                    title: category,
                    products: categoryProducts,
                    onViewAll:
                        () => context.pushNamed(
                          'browse',
                          pathParameters: {
                            'kind': 'category',
                            'value': category,
                          },
                        ),
                  ),
                );
              }
            }

            return Column(children: categorySections);
          },
        ),
      ],
    );
  }

  Widget _buildInfiniteScrollContent(
    BuildContext context,
    WidgetRef ref,
    List<Product> featured,
    double heroHeight,
    double screenWidth,
    AppBreakpoint bp,
  ) {
    return _InfiniteScrollHomeContent(
      featured: featured,
      heroHeight: heroHeight,
      screenWidth: screenWidth,
      bp: bp,
    );
  }
}

class _InfiniteScrollHomeContent extends StatefulWidget {
  final List<Product> featured;
  final double heroHeight;
  final double screenWidth;
  final AppBreakpoint bp;

  const _InfiniteScrollHomeContent({
    required this.featured,
    required this.heroHeight,
    required this.screenWidth,
    required this.bp,
  });

  @override
  State<_InfiniteScrollHomeContent> createState() =>
      _InfiniteScrollHomeContentState();
}

class _InfiniteScrollHomeContentState
    extends State<_InfiniteScrollHomeContent> {
  late ScrollController _scrollController;
  int _displayedCategoryCount = 3; // Start with 3 categories
  static const int _loadMoreThreshold = 500; // Load more when 500px from end

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxScrollExtent = position.maxScrollExtent;
    final currentPixels = position.pixels;

    // Load more categories when near the end
    if (currentPixels >= maxScrollExtent - _loadMoreThreshold) {
      _loadMoreCategories();
    }
  }

  void _loadMoreCategories() {
    if (!mounted) return;

    // Increment displayed count - will be clamped in build method
    setState(() {
      _displayedCategoryCount += 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final categories = ref.watch(shared.categoriesProvider);
        final totalCategories = categories.length;

        // Clamp displayed count to total available categories
        final effectiveDisplayCount = _displayedCategoryCount.clamp(
          0,
          totalCategories,
        );

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Static content section
            SliverPadding(
              padding: Responsive.getHomeContentPadding(widget.screenWidth),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          widget.bp == AppBreakpoint.expanded
                              ? 1200
                              : double.infinity,
                    ),
                    child: _buildStaticContent(context),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStaticContent(BuildContext context) {
    return Column(
      children: [
        const HomeSearchBar(),
        const SizedBox(height: 12),
        Consumer(
          builder:
              (context, ref, _) => _ImageCarousel(height: widget.heroHeight),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Featured Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize:
                      widget.bp == AppBreakpoint.expanded
                          ? 24
                          : widget.bp == AppBreakpoint.medium
                          ? 22
                          : 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ResponsiveTextButton(
              onPressed: () => context.goNamed('catalog'),
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: widget.bp == AppBreakpoint.expanded ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const HomeFeaturedCategoriesStrip(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Featured Products',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize:
                      widget.bp == AppBreakpoint.expanded
                          ? 24
                          : widget.bp == AppBreakpoint.medium
                          ? 22
                          : 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ResponsiveTextButton(
              onPressed: () => context.goNamed('featured-products'),
              child: Text(
                'See all',
                style: TextStyle(
                  fontSize: widget.bp == AppBreakpoint.expanded ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        widget.featured.isEmpty
            ? const SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'No featured products available',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
            : _buildFeaturedProductsSection(context, widget.featured),
        // Category-based product sections
        Consumer(
          builder: (context, ref, _) {
            final categories = ref.watch(shared.categoriesProvider);
            final allProducts = ref.watch(shared.allProductsProvider);
            final categorySections = <Widget>[];

            // Show top 3-4 categories with products
            for (final category in categories.take(4)) {
              final categoryProducts =
                  allProducts
                      .where(
                        (p) => p.categories.any(
                          (c) => c.toLowerCase() == category.toLowerCase(),
                        ),
                      )
                      .take(10) // Show up to 10 products per category
                      .toList();

              if (categoryProducts.isNotEmpty) {
                categorySections.add(
                  CategorySection(
                    title: category,
                    products: categoryProducts,
                    onViewAll:
                        () => context.pushNamed(
                          'browse',
                          pathParameters: {
                            'kind': 'category',
                            'value': category,
                          },
                        ),
                  ),
                );
              }
            }

            return Column(children: categorySections);
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedProductsSection(
    BuildContext context,
    List<Product> products,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Use unified card widths across all breakpoints
        final cardWidth = Responsive.getUnifiedProductCardWidth(width);

        // Calculate height based on card width and aspect ratio
        final cardAspectRatio = UniversalProductCard.getCardAspectRatio(
          width,
          customCardWidth: cardWidth,
        );
        final overflowBuffer =
            32.0; // Increased buffer for ListView padding and shadows
        final estimatedCardHeight =
            (cardWidth / cardAspectRatio) + overflowBuffer;

        // Wrap ListView in SizedBox with calculated height to provide bounded constraint
        // Use responsive horizontal padding matching unified constraints
        final horizontalPadding = Responsive.getProductCardSectionPadding(
          width,
        );
        return SizedBox(
          height: estimatedCardHeight,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, i) {
              final isLast = i == products.length - 1;
              return Padding(
                padding: EdgeInsets.only(right: isLast ? 16 : 8),
                child: SizedBox(
                  width: cardWidth,
                  child: UniversalProductCard(
                    product: products[i],
                    cardWidth: cardWidth,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ImageCarousel extends ConsumerStatefulWidget {
  final double height;
  const _ImageCarousel({required this.height});

  @override
  ConsumerState<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends ConsumerState<_ImageCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  static const Duration _autoPlayInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay(int imageCount) {
    _timer?.cancel();
    if (imageCount <= 1) return; // Don't auto-play if only one image

    _timer = Timer.periodic(_autoPlayInterval, (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentPage < imageCount - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index, int imageCount) {
    setState(() {
      _currentPage = index;
    });
    // Reset auto-play timer when user manually swipes
    _timer?.cancel();
    _startAutoPlay(imageCount);
  }

  @override
  Widget build(BuildContext context) {
    final heroImagesAsync = ref.watch(heroImagesProvider);

    return heroImagesAsync.when(
      data: (heroImages) {
        final imageCount = heroImages.length;

        // Start auto-play when images are loaded
        if (imageCount > 0 && _timer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAutoPlay(imageCount);
          });
        }

        if (imageCount == 0) {
          // Empty state - show placeholder
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: widget.height,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hero images available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final currentHero = heroImages[_currentPage];
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  SizedBox(
                    height: widget.height,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged:
                          (index) => _onPageChanged(index, imageCount),
                      itemCount: imageCount,
                      itemBuilder: (context, index) {
                        return LazyImage(
                          imageUrl: heroImages[index].imageUrl,
                          fit: BoxFit.cover,
                          height: widget.height,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                  // Enhanced gradient overlay with dark vignette for better text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        // Linear gradient for bottom darkening
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          stops: const [0.0, 0.5, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Radial gradient vignette at the bottom for stronger effect
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.bottomCenter,
                          radius: 1.2,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          stops: const [0.0, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Hero content overlay (title, subtitle, CTA)
                  if ((currentHero.title != null &&
                          currentHero.title!.trim().isNotEmpty) ||
                      (currentHero.subtitle != null &&
                          currentHero.subtitle!.trim().isNotEmpty) ||
                      (currentHero.ctaText != null &&
                          currentHero.ctaText!.trim().isNotEmpty &&
                          (currentHero.ctaLink != null ||
                              currentHero.slackUrl != null)))
                    Positioned(
                      bottom: 70,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildHeroContentOverlay(
                          context,
                          currentHero,
                          constraints.maxWidth,
                        ),
                      ),
                    ),
                  // Page indicators
                  if (imageCount > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imageCount,
                          (index) => _buildPageIndicator(index == _currentPage),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () {
        // Loading state
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: widget.height,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, stack) {
        // Error state - show placeholder with fallback
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: widget.height,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load images',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildHeroContentOverlay(
    BuildContext context,
    HeroImage heroImage,
    double screenWidth,
  ) {
    // Determine sizes based on screen width
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final titleFontSize = isMobile ? 20.0 : (isTablet ? 24.0 : 28.0);
    final subtitleFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          if (heroImage.title != null && heroImage.title!.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                heroImage.title!,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // Subtitle
          if (heroImage.subtitle != null &&
              heroImage.subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                heroImage.subtitle!,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          // CTA Button
          if (heroImage.ctaText != null &&
              heroImage.ctaText!.trim().isNotEmpty &&
              (heroImage.ctaLink != null || heroImage.slackUrl != null)) ...[
            const SizedBox(height: 12),
            _buildHeroCTAButton(context, heroImage, screenWidth),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroCTAButton(
    BuildContext context,
    HeroImage heroImage,
    double screenWidth,
  ) {
    // Determine button size based on screen width
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final buttonHeight = isMobile ? 40.0 : (isTablet ? 44.0 : 48.0);
    final horizontalPadding = isMobile ? 24.0 : (isTablet ? 32.0 : 40.0);
    final fontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _handleHeroCTAClick(context, heroImage),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 12,
          ),
          minimumSize: Size(0, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          heroImage.ctaText!,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _handleCTAClick(BuildContext context, String ctaLink) {
    // Check if it's a URL (starts with http:// or https://)
    if (ctaLink.startsWith('http://') || ctaLink.startsWith('https://')) {
      // Handle external URL - you might want to use url_launcher here
      // For now, just show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: $ctaLink'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Assume it's a route name and navigate
      try {
        context.goNamed(ctaLink);
      } catch (e) {
        // If route doesn't exist, try pushNamed as fallback
        try {
          context.pushNamed(ctaLink);
        } catch (e2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route not found: $ctaLink'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _handleHeroCTAClick(BuildContext context, HeroImage heroImage) async {
    // Prioritize Slack URL if available, otherwise use regular CTA link
    String? targetUrl = heroImage.slackUrl ?? heroImage.ctaLink;

    if (targetUrl == null) {
      return;
    }

    // Check if it's a Slack URL (slack:// or https://*.slack.com/*)
    final isSlackUrl =
        targetUrl.startsWith('slack://') ||
        (targetUrl.startsWith('https://') && targetUrl.contains('.slack.com'));

    if (isSlackUrl) {
      // Handle Slack URL using url_launcher
      try {
        final uri = Uri.parse(targetUrl);
        final canLaunch = await canLaunchUrl(uri);

        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to open Slack URL'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening Slack URL: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Handle regular URL or route
      _handleCTAClick(context, targetUrl);
    }
  }

  Widget _buildShopButton(BuildContext context, double screenWidth) {
    // Determine button size based on screen width - make it smaller
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final buttonHeight = isMobile ? 36.0 : (isTablet ? 38.0 : 40.0);
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    final fontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final iconSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => context.goNamed('catalog'),
        icon: Icon(Icons.shopping_bag, size: iconSize, color: Colors.black),
        label: Text(
          'Shop Now',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 10,
          ),
          minimumSize: Size(0, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ProductGrid moved to a shared widget: features/catalog/presentation/widgets/product_grid.dart
// Local _ProductCard removed - now using UniversalProductCard from catalog/presentation/widgets/universal_product_card.dart
