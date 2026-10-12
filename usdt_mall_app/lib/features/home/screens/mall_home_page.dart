import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/home_api.dart';
import '../../../core/api/carousel_api.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/image_util.dart';
import '../widgets/mall_app_bar.dart';
import '../widgets/side_menu.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/chat_floating_button.dart';
import '../../../shared/widgets/responsive_app_bar.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';
import '../../../shared/widgets/product_card_image.dart';
import '../../../core/l10n/app_localizations.dart';

/// 商城首页
class MallHomePage extends StatefulWidget {
  const MallHomePage({super.key});

  @override
  State<MallHomePage> createState() => _MallHomePageState();
}

class _MallHomePageState extends State<MallHomePage> {
  List<Map<String, dynamic>> _hotProducts = [];
  List<Map<String, dynamic>> _dailyProducts = [];
  List<Map<String, dynamic>> _carouselProducts = [];
  bool _isLoadingHot = false;
  bool _isLoadingDaily = false;
  bool _isLoadingCarousel = false;
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;
  PageController? _carouselPageController;

  @override
  void initState() {
    super.initState();
    _loadCarouselProducts();
    _loadHotProducts();
    _loadDailyProducts();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselPageController?.dispose();
    super.dispose();
  }

  /// 加载轮播商品
  Future<void> _loadCarouselProducts() async {
    setState(() {
      _isLoadingCarousel = true;
    });

    try {
      final response = await CarouselApi.getCarouselProducts();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _carouselProducts = List<Map<String, dynamic>>.from(response.data!);
          _isLoadingCarousel = false;
        });
        if (_carouselProducts.isNotEmpty) {
          _carouselPageController = PageController(initialPage: 0);
          _startAutoCarousel();
        }
      } else {
        setState(() {
          _isLoadingCarousel = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCarousel = false;
      });
    }
  }

  /// 启动自动轮播
  void _startAutoCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_carouselProducts.isNotEmpty &&
          mounted &&
          _carouselPageController != null &&
          _carouselPageController!.hasClients) {
        final nextPage = (_currentCarouselIndex + 1) % _carouselProducts.length;
        _carouselPageController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// 加载热卖商品
  Future<void> _loadHotProducts() async {
    setState(() {
      _isLoadingHot = true;
    });

    try {
      final response = await HomeApi.getHotProducts(limit: 30);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _hotProducts =
              List<Map<String, dynamic>>.from(response.data!['list'] ?? []);
          _isLoadingHot = false;
        });
      } else {
        setState(() {
          _isLoadingHot = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingHot = false;
      });
    }
  }

  /// 加载每日新发现商品
  Future<void> _loadDailyProducts() async {
    setState(() {
      _isLoadingDaily = true;
    });

    try {
      final response = await HomeApi.getDailyDiscover(limit: 8);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _dailyProducts =
              List<Map<String, dynamic>>.from(response.data!['list'] ?? []);
          _isLoadingDaily = false;
        });
      } else {
        setState(() {
          _isLoadingDaily = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingDaily = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Scaffold(
      appBar: isMobile
          ? ResponsiveAppBar(
              title: AppLocalizations.of(context).appName,
              showBackButton: false,
            )
          : const MallAppBar(),
      body: SafeArea(
        child: AppBackground(
          child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
      bottomNavigationBar: isMobile ? const MobileBottomNavV2() : null,
      floatingActionButton: !isMobile ? const ChatFloatingButton() : null,
    );
  }

  /// 构建移动端布局
  Widget _buildMobileLayout() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildBannerSection(),
        const SizedBox(height: 16),
        _buildHotSaleSectionMobile(),
        const SizedBox(height: 16),
        _buildProductSectionMobile(),
      ],
    );
  }

  /// 构建桌面端布局
  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SideMenu(),
            Expanded(
              child: _buildContentArea(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContentArea(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerSection(),
            const SizedBox(height: 24),
            _buildHotSaleSection(),
            const SizedBox(height: 24),
            _buildProductSection(),
          ],
        ),
      ),
    );
  }

  /// 构建轮播图区域
  Widget _buildBannerSection() {
    final l10n = AppLocalizations.of(context);

    if (_isLoadingCarousel) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_carouselProducts.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            l10n.bannerArea,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          PageView.builder(
            controller: _carouselPageController,
            itemCount: _carouselProducts.length,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final product = _carouselProducts[index];
              return InkWell(
                onTap: () {
                  context.go('/product/${product['productId']}');
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: product['productImage'] != null &&
                            product['productImage'].isNotEmpty
                        ? Image.network(
                            ImageUtil.getImageUrl(product['productImage']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image,
                                        size: 64, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      product['productName'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  product['productName'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_carouselProducts.length, (index) {
                return GestureDetector(
                  onTap: () {
                    if (_carouselPageController != null &&
                        _carouselPageController!.hasClients) {
                      _carouselPageController!.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentCarouselIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建热卖商品滚动区域
  Widget _buildHotSaleSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.hotProducts,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            TextButton(
              onPressed: () {
                context.go('/category/hot-sale');
              },
              child: Text(
                l10n.viewAll,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoadingHot
            ? const Center(child: CircularProgressIndicator())
            : _AutoScrollHotSale(products: _hotProducts),
      ],
    );
  }

  /// 构建商品列表区域
  Widget _buildProductSection() {
    final l10n = AppLocalizations.of(context);
    if (_isLoadingDaily) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dailyProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dailyDiscover,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 4;
            const spacing = 16.0;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: ProductCardMetrics.gridAspectRatio(
                  maxWidth: constraints.maxWidth,
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                ),
              ),
              itemCount: _dailyProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_dailyProducts[index]);
              },
            );
          },
        ),
      ],
    );
  }

  /// 构建商品卡片
  Widget _buildProductCard(Map<String, dynamic> product) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return ProductSummaryCard(
      product: product,
      nameSize: isMobile ? 13 : 14,
      priceSize: isMobile ? 15 : 16,
      onTap: () {
        context.go('/product/${product['id']}');
      },
    );
  }

  /// 构建移动端热卖商品区域
  Widget _buildHotSaleSectionMobile() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.hotProducts,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                context.go('/category/hot-sale');
              },
              child: Text(
                l10n.viewAll,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isLoadingHot
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  const crossAxisCount = 2;
                  const spacing = 8.0;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: ProductCardMetrics.gridAspectRatio(
                        maxWidth: constraints.maxWidth,
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                      ),
                    ),
                    itemCount:
                        _hotProducts.length > 10 ? 10 : _hotProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(_hotProducts[index]);
                    },
                  );
                },
              ),
      ],
    );
  }

  /// 构建移动端商品列表区域
  Widget _buildProductSectionMobile() {
    final l10n = AppLocalizations.of(context);

    if (_isLoadingDaily) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dailyProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dailyDiscover,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 2;
            const spacing = 8.0;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: ProductCardMetrics.gridAspectRatio(
                  maxWidth: constraints.maxWidth,
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                ),
              ),
              itemCount: _dailyProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_dailyProducts[index]);
              },
            );
          },
        ),
      ],
    );
  }
}

/// 自动滚动的热卖商品组件
class _AutoScrollHotSale extends StatefulWidget {
  final List<Map<String, dynamic>> products;

  const _AutoScrollHotSale({required this.products});

  @override
  State<_AutoScrollHotSale> createState() => _AutoScrollHotSaleState();
}

class _AutoScrollHotSaleState extends State<_AutoScrollHotSale> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _totalPages = (widget.products.length / 6).ceil();
    _pageController = PageController();

    if (_totalPages > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_pageController.hasClients) {
          _currentPage = (_currentPage + 1) % _totalPages;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 60) / 6;
        final pageHeight = cardWidth + ProductCardMetrics.textBlockHeight;
        return Column(
          children: [
            SizedBox(
              height: pageHeight,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _totalPages,
                itemBuilder: (context, pageIndex) {
                  return _buildPage(pageIndex);
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_totalPages > 1) _buildPageIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildPage(int pageIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 60) / 6;
        final startIndex = pageIndex * 6;
        final endIndex = (startIndex + 6).clamp(0, widget.products.length);
        final pageProducts = widget.products.sublist(startIndex, endIndex);

        return Row(
          children: List.generate(pageProducts.length, (index) {
            return _buildHotSaleCard(pageProducts[index], cardWidth, index);
          }),
        );
      },
    );
  }

  Widget _buildHotSaleCard(
      Map<String, dynamic> product, double width, int indexInPage) {
    return ProductSummaryCard(
      product: product,
      width: width,
      margin: EdgeInsets.only(right: indexInPage < 5 ? 12 : 0),
      nameSize: 13,
      priceSize: 14,
      onTap: () {
        context.go('/product/${product['id']}');
      },
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _currentPage == index ? Colors.blue[700] : Colors.grey[300],
              ),
            ),
          ),
        );
      }),
    );
  }
}
