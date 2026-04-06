import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../models/product.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_store_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../product/product_detail_screen.dart';



class _CampaignCardData {
  final String title;
  final String subtitle;
  final String imageUrl;

  const _CampaignCardData({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

const _campaignCards = [
  _CampaignCardData(
    title: 'Spring Glow Edit',
    subtitle: 'Up to 35% off selected skincare bundles',
    imageUrl:
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=1200&q=80',
  ),
  _CampaignCardData(
    title: 'New Arrival Drop',
    subtitle: 'Just landed: clean makeup essentials',
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=1200&q=80',
  ),
  _CampaignCardData(
    title: 'Fragrance Week',
    subtitle: 'Exclusive gift wrap on premium perfumes',
    imageUrl:
        'https://images.unsplash.com/photo-1541643600914-78b084683702?w=1200&q=80',
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bannerController = PageController(viewportFraction: 0.92);
  final _campaignController = PageController(viewportFraction: 0.92);
  ProductCategory? _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _heroTimer;
  int _heroIndex = 0;
  int _campaignIndex = 0;
  bool _heroInteracting = false;
  List<Product> _catalog = const [];
  bool _isLoadingCatalog = true;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startHeroAutoPlay();
    });
  }

  Future<void> _loadCatalog() async {
    if (!SupabaseStoreService.isConfigured) {
      if (!mounted) return;
      setState(() {
        _isLoadingCatalog = false;
        _catalogError = 'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define-from-file=.env.';
      });
      return;
    }

    try {
      final products = await SupabaseStoreService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _catalog = products;
        _isLoadingCatalog = false;
        _catalogError = products.isEmpty
            ? 'No active products found in Supabase. Add rows to the products table or mark products as is_active=true.'
            : null;
      });
    } catch (error) {
      final message = error.toString();
      final hasHostLookupError =
          message.toLowerCase().contains('failed host lookup');
      if (!mounted) return;
      setState(() {
        _catalog = const [];
        _isLoadingCatalog = false;
        _catalogError = hasHostLookupError
            ? 'Could not reach Supabase host. Check SUPABASE_URL and ensure it uses https:// (example: https://your-project.supabase.co).'
            : 'Could not load products from Supabase: $error';
      });
    }
  }

  void _startHeroAutoPlay() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _heroInteracting) return;
      final trending = _topTrendingProducts;
      if (trending.isEmpty || !_bannerController.hasClients) return;
      final next = (_heroIndex + 1) % trending.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _setHeroInteracting(bool value) {
    if (_heroInteracting == value) return;
    setState(() => _heroInteracting = value);
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _bannerController.dispose();
    _campaignController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    return _catalog.where((p) {
      final matchesCategory =
          _selectedCategory == null || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.label.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Product> get _topTrendingProducts {
    final ranked = [..._catalog]
      ..sort((a, b) {
        final byReviews = b.reviews.compareTo(a.reviews);
        if (byReviews != 0) return byReviews;
        return b.rating.compareTo(a.rating);
      });
    return ranked.take(10).toList();
  }

  List<Product> get _newArrivals {
    final newTagged = _catalog.where((p) => p.badge == 'NEW').toList();
    final latest = [..._catalog]
      ..sort((a, b) => b.id.compareTo(a.id));
    final merged = <Product>[...newTagged];
    for (final product in latest) {
      if (merged.any((p) => p.id == product.id)) continue;
      merged.add(product);
      if (merged.length >= 6) break;
    }
    return merged.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCatalog) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.crimson),
        ),
      );
    }

    if (_catalogError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: AppColors.crimson),
                  const SizedBox(height: 12),
                  const Text(
                    'Unable to load products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _catalogError!,
                    style: const TextStyle(color: AppColors.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoadingCatalog = true;
                        _catalogError = null;
                      });
                      _loadCatalog();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildBanner()),
            SliverToBoxAdapter(child: _buildSectionHeader('Top 10 Trending Now')),
            SliverToBoxAdapter(child: _buildTopTrendingStrip()),
            SliverToBoxAdapter(child: _buildCategories()),
            SliverToBoxAdapter(child: _buildSectionHeader('New Arrivals')),
            SliverToBoxAdapter(child: _buildNewArrivalsStrip()),
            SliverToBoxAdapter(child: _buildSectionHeader('Ad Campaigns')),
            SliverToBoxAdapter(child: _buildCampaignCarousel()),
            SliverToBoxAdapter(child: _buildDealsStrip()),
            SliverToBoxAdapter(
                child: _buildSectionHeader('All Products', showItemCount: true)),
            _buildProductGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Beauty! 👋',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Delix Cosmetics',
                style: Theme.of(context).textTheme.displaySmall!.copyWith(
                      color: AppColors.crimson,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await NotificationService.showPromoNotification(
                title: 'Delix Campaign Alert',
                body: 'New arrivals are live. Tap in and discover fresh picks.',
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Promotion notification sent.')),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.crimson, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search skincare, makeup…',
          prefixIcon:
              const Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.close,
                      color: AppColors.mutedForeground, size: 18),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final settings = context.watch<AppSettingsProvider>();
    final trending = _topTrendingProducts;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.idle) {
                _setHeroInteracting(false);
              } else {
                _setHeroInteracting(true);
              }
              return false;
            },
            child: GestureDetector(
              onPanDown: (_) => _setHeroInteracting(true),
              onPanCancel: () => _setHeroInteracting(false),
              onPanEnd: (_) => _setHeroInteracting(false),
              child: SizedBox(
                height: 420,
                child: PageView.builder(
                  controller: _bannerController,
                  itemCount: trending.length,
                  onPageChanged: (index) {
                    if (!mounted) return;
                    setState(() => _heroIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final product = trending[index];
                    return AnimatedBuilder(
                      animation: _bannerController,
                      builder: (context, child) {
                        double page = _heroIndex.toDouble();
                        if (_bannerController.hasClients &&
                            _bannerController.position.hasContentDimensions) {
                          page = _bannerController.page ?? _heroIndex.toDouble();
                        }
                        final distance = (index - page).abs().clamp(0.0, 1.0);
                        final scale = 1 - (distance * 0.06);
                        final parallax = (index - page) * 36;
                        return Transform.scale(
                          scale: scale,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(product: product),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(parallax, 0),
                                      child: product.imageUrl.isEmpty
                                          ? Container(
                                              color: AppColors.crimsonDark,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported_outlined,
                                                  size: 60,
                                                  color: Colors.white30,
                                                ),
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: product.imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: AppColors.crimsonDark,
                                                child: const Center(
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white30,
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, error, stackTrace) => Container(
                                                color: AppColors.crimsonDark,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                    size: 60,
                                                    color: Colors.white30,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x66000000),
                                            Color(0x99000000),
                                            Color(0xE6000000),
                                          ],
                                          stops: [0.0, 0.45, 1.0],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 16,
                                      left: 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.black.withValues(alpha: 0.55),
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.18),
                                          ),
                                        ),
                                        child: Text(
                                          'TOP 10 IN TRENDING',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: Text(
                                        '#${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 38,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 18,
                                      right: 18,
                                      bottom: 20,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.category.label.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              letterSpacing: 2,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            product.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              height: 1.1,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '${product.rating} • ${product.reviews} reviews • ${settings.formatMoney(product.price, context)}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              _buildHeroActionButton(
                                                icon:
                                                    Icons.play_arrow_rounded,
                                                label: 'Buy Now',
                                                filled: true,
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ProductDetailScreen(
                                                            product: product),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              _buildHeroActionButton(
                                                icon: Icons.info_outline,
                                                label: 'Details',
                                                filled: false,
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ProductDetailScreen(
                                                            product: product),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SmoothPageIndicator(
            controller: _bannerController,
            count: trending.length,
            effect: const ExpandingDotsEffect(
              dotColor: Color(0xFF9E9E9E),
              activeDotColor: Color(0xFF1A1A1A),
              dotHeight: 6,
              dotWidth: 6,
              expansionFactor: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTrendingStrip() {
    final trending = _topTrendingProducts;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.42).clamp(148.0, 188.0).toDouble();
    final imageLeftInset = (cardWidth * 0.26).clamp(36.0, 50.0).toDouble();
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: trending.length,
        itemBuilder: (context, index) {
          final product = trending[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            ),
            child: SizedBox(
              width: cardWidth,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    bottom: 2,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 104,
                        height: 0.9,
                        fontWeight: FontWeight.w900,
                        color: Color(0x22000000),
                      ),
                    ),
                  ),
                  Positioned(
                    left: imageLeftInset,
                    right: 8,
                    top: 14,
                    bottom: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, error, stackTrace) => Container(
                              color: AppColors.crimsonDark,
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x22000000),
                                  Color(0xBB000000),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroActionButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: filled ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: filled ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ProductCategory.values;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Categories'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _categoryCircle(
                  null,
                  label: 'All',
                  icon: Icons.auto_awesome,
                  color: AppColors.crimson,
                ),
                ...categories.map(
                  (c) => _categoryCircle(
                    c,
                    label: c.label,
                    icon: _categoryIcon(c),
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCircle(
    ProductCategory? category, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final selected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : Colors.white,
                  border: Border.all(
                    color: selected ? color : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.foreground,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.crimson : AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.skincare:
        return Icons.spa_outlined;
      case ProductCategory.hairStyling:
        return Icons.content_cut;
      case ProductCategory.makeup:
        return Icons.brush_outlined;
      case ProductCategory.fragrance:
        return Icons.local_florist_outlined;
      case ProductCategory.bodycare:
        return Icons.self_improvement_outlined;
    }
  }

  Widget _buildNewArrivalsStrip() {
    final settings = context.watch<AppSettingsProvider>();
    final arrivals = _newArrivals;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.44).clamp(152.0, 196.0).toDouble();
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: arrivals.length,
        itemBuilder: (context, index) {
          final product = arrivals[index];
          return Container(
            width: cardWidth,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              ),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: product.imageUrl.isEmpty
                          ? Container(
                              height: 130,
                              width: double.infinity,
                              color: AppColors.muted,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 32,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              height: 130,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 130,
                                color: AppColors.muted,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.crimson,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, error, stackTrace) => Container(
                                height: 130,
                                color: AppColors.muted,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 32,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                      child: Text(
                        settings.formatMoney(product.price, context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.crimson,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaignCarousel() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _campaignController,
              itemCount: _campaignCards.length,
              onPageChanged: (index) => setState(() => _campaignIndex = index),
              itemBuilder: (context, index) {
                final campaign = _campaignCards[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: campaign.imageUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xC0000000), Color(0x55000000)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                campaign.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                campaign.subtitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSmoothIndicator(
            activeIndex: _campaignIndex,
            count: _campaignCards.length,
            effect: const WormEffect(
              dotWidth: 7,
              dotHeight: 7,
              activeDotColor: AppColors.crimson,
              dotColor: Color(0xFFCBCBCB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gold, Color(0xFFE8B86D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎁 Buy One Get One Free',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'All lipsticks & palettes — limited stock!',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = ProductCategory.makeup),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'Claim Offer',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text('💄', style: TextStyle(fontSize: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showItemCount = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sectionTitle(title),
          if (showItemCount)
            Text(
              '${_filteredProducts.length} items',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.mutedForeground),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredProducts;
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 48, color: AppColors.mutedForeground),
              const SizedBox(height: 12),
              Text('No products found',
                  style: TextStyle(color: AppColors.mutedForeground)),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            ),
          );
        },
      ),
    );
  }
}
