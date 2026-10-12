import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';
import '../widgets/landing_app_bar.dart';
import '../../../shared/widgets/chat_floating_button.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';

/// 网站首页（Landing Page）- 营销型欢迎页
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  PageController? _bannerPageController;

  // 静态Banner数据
  final List<Map<String, dynamic>> _banners = [
    {'id': 1, 'title': 'Banner 1', 'image': 'assets/pic/banner1.png'},
    {'id': 2, 'title': 'Banner 2', 'image': 'assets/pic/banner2.png'},
    {'id': 3, 'title': 'Banner 3', 'image': 'assets/pic/banner3.png'},
  ];

  // 静态数据展示
  List<Map<String, dynamic>> _getDataStats(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      {'id': 1, 'title': '10+', 'subtitle': l10n.translate('market_champions'), 'image': 'assets/pic/map1.jpg'},
      {'id': 2, 'title': '2', 'subtitle': l10n.translate('market_shopping_app'), 'image': 'assets/pic/map2.jpg'},
      {'id': 3, 'title': '76亿', 'subtitle': l10n.translate('total_orders_2025'), 'image': 'assets/pic/map3.jpg'},
      {'id': 4, 'title': '3', 'subtitle': l10n.translate('marketing_matrix'), 'image': 'assets/pic/map4.png'},
    ];
  }

  // 三大权益
  List<Map<String, dynamic>> _getBenefits(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      {
        'icon': Icons.support_agent,
        'title': l10n.translate('incubation_manager'),
        'description': l10n.translate('incubation_manager_desc'),
      },
      {
        'icon': Icons.campaign,
        'title': l10n.translate('activity_exposure'),
        'description': l10n.translate('activity_exposure_desc'),
      },
      {
        'icon': Icons.monetization_on,
        'title': l10n.translate('commission_subsidy'),
        'description': l10n.translate('commission_subsidy_desc'),
      },
    ];
  }

  // 六大收益
  final List<Map<String, dynamic>> _advantages = [
    {
      'image': 'assets/pic/bene1.png',
      'title': 'Efficient logistics',
      'description': 'Lay an efficient logistics network to solve cross-border logistics problems.AS1688 Logistics Service SLS & Localized Fulfillment.',
    },
    {
      'image': 'assets/pic/bene2.png',
      'title': 'Safe and fast payment',
      'description': 'Sellers can withdraw funds through TiKi INT official wallet, or third-party payment service providers LianLian, Payoneer, PingPong The transaction is safe and fast, and the platform payment cycle is once a week.',
    },
    {
      'image': 'assets/pic/bene3.png',
      'title': 'Powerful management platform',
      'description': 'The backend provides functions such as batch new products, order tracking, sales reports, etc. One-stop shop to meet store management needs',
    },
    {
      'image': 'assets/pic/bene4.jpg',
      'title': 'Local customer service',
      'description': 'The customer service team is highly localized, covering areas with small languages. Currently providing free customer service to solve language problems.',
    },
    {
      'image': 'assets/pic/bene5.png',
      'title': 'Recommended products',
      'description': 'Provide product selection suggestions and operation information every week. Help you gain a deeper understanding of the market, accurately select products, and easily create hot items.',
    },
    {
      'image': 'assets/pic/bene6.png',
      'title': 'API Integration',
      'description': 'Connect with domestic mainstream ERP to efficiently manage products and orders. Flexibly customize the backend system that best suits you.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initBanner();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController?.dispose();
    super.dispose();
  }

  /// 初始化Banner轮播
  void _initBanner() {
    _bannerPageController = PageController(initialPage: 0);
    _startAutoBanner();
  }

  /// 启动自动轮播
  void _startAutoBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_banners.isNotEmpty && mounted && _bannerPageController != null && _bannerPageController!.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _banners.length;
        _bannerPageController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const LandingAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBannerSection(isMobile: isMobile),
            SizedBox(height: isMobile ? 48 : 80),
            _buildDataStatsSection(isMobile: isMobile),
            SizedBox(height: isMobile ? 56 : 96),
            _buildBenefitsSection(isMobile: isMobile),
            SizedBox(height: isMobile ? 56 : 96),
            _buildAdvantagesSection(isMobile: isMobile),
            SizedBox(height: isMobile ? 64 : 100),
            _buildJoinNowSection(isMobile: isMobile),
            SizedBox(height: isMobile ? 48 : 80),
            _buildFooter(context),
          ],
        ),
      ),
      bottomNavigationBar: isMobile ? const MobileBottomNavV2() : null,
      floatingActionButton: !isMobile ? const ChatFloatingButton() : null,
    );
  }

  /// 构建Banner区域
  Widget _buildBannerSection({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 24),
      child: Center(
        child: Container(
          height: isMobile ? 300 : 600,
          constraints: const BoxConstraints(maxWidth: 1200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
            boxShadow: isMobile ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                spreadRadius: 0,
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
            child: Stack(
              children: [
                // Banner轮播
                PageView.builder(
                  controller: _bannerPageController,
                  itemCount: _banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBannerIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final banner = _banners[index];
                    return Container(
                      color: Colors.grey[200],
                      child: Image.asset(
                        banner['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: isMobile ? 48 : 80, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  banner['title'],
                                  style: TextStyle(fontSize: isMobile ? 14 : 18, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // 指示器
                Positioned(
                  bottom: isMobile ? 16 : 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_banners.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          if (_bannerPageController != null && _bannerPageController!.hasClients) {
                            _bannerPageController!.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6),
                          width: _currentBannerIndex == index ? (isMobile ? 24 : 32) : (isMobile ? 8 : 10),
                          height: isMobile ? 8 : 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: _currentBannerIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            boxShadow: _currentBannerIndex == index ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建数据展示区域
  Widget _buildDataStatsSection({required bool isMobile}) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Column(
        children: [
          Text(
            l10n.translate('platform_data'),
            style: TextStyle(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Container(
            width: isMobile ? 60 : 80,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[700]!],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          isMobile
              ? Column(
                  children: _getDataStats(context).map((stat) => _buildDataStatCard(stat, isMobile: true)).toList(),
                )
              : Wrap(
                  spacing: 48,
                  runSpacing: 48,
                  alignment: WrapAlignment.center,
                  children: _getDataStats(context).map((stat) => _buildDataStatCard(stat, isMobile: false)).toList(),
                ),
        ],
      ),
    );
  }

  /// 构建单个数据卡片
  Widget _buildDataStatCard(Map<String, dynamic> stat, {required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 552,
      margin: EdgeInsets.only(bottom: isMobile ? 20 : 0),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isMobile ? double.infinity : 552,
            height: isMobile ? 280 : 552,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                stat['image'],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.bar_chart, size: isMobile ? 140 : 276, color: Colors.blue[700]);
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            child: Column(
              children: [
                Text(
                  stat['title'],
                  style: TextStyle(
                    fontSize: isMobile ? 36 : 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  stat['subtitle'],
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建三大权益区域
  Widget _buildBenefitsSection({required bool isMobile}) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Column(
        children: [
          Text(
            l10n.translate('three_benefits'),
            style: TextStyle(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Container(
            width: isMobile ? 60 : 80,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[700]!],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          isMobile
              ? Column(
                  children: _getBenefits(context).map((benefit) => _buildBenefitCard(benefit, isMobile: true)).toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getBenefits(context).map((benefit) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _buildBenefitCard(benefit, isMobile: false),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  /// 构建单个权益卡片
  Widget _buildBenefitCard(Map<String, dynamic> benefit, {required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : null,
      margin: EdgeInsets.only(bottom: isMobile ? 20 : 0),
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isMobile ? 70 : 80,
            height: isMobile ? 70 : 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[400]!, Colors.blue[600]!],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              benefit['icon'],
              size: isMobile ? 36 : 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),
          Text(
            benefit['title'],
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 14 : 16),
          Text(
            benefit['description'],
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: Colors.grey[600],
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建六大收益区域
  Widget _buildAdvantagesSection({required bool isMobile}) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Column(
        children: [
          Text(
            l10n.translate('six_advantages'),
            style: TextStyle(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Container(
            width: isMobile ? 60 : 80,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[700]!],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          isMobile
              ? Column(
                  children: _advantages.map((advantage) => _buildAdvantageCard(advantage, isMobile: true)).toList(),
                )
              : Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: _advantages.map((advantage) => _buildAdvantageCard(advantage, isMobile: false)).toList(),
                ),
        ],
      ),
    );
  }

  /// 构建单个收益卡片
  Widget _buildAdvantageCard(Map<String, dynamic> advantage, {required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 560,
      margin: EdgeInsets.only(bottom: isMobile ? 20 : 0),
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 120 : 180,
            height: isMobile ? 120 : 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                advantage['image'],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image,
                    size: isMobile ? 60 : 90,
                    color: Colors.grey[400],
                  );
                },
              ),
            ),
          ),
          SizedBox(width: isMobile ? 16 : 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advantage['title'],
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 12),
                Text(
                  advantage['description'],
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: Colors.grey[600],
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建"立即入驻"按钮区域
  Widget _buildJoinNowSection({required bool isMobile}) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 40 : 56),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[600]!, Colors.blue[800]!],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              l10n.translate('start_your_journey'),
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              l10n.translate('join_now_desc'),
              style: TextStyle(
                fontSize: isMobile ? 15 : 18,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 28 : 36),
            ElevatedButton(
              onPressed: () {
                // 跳转到商城首页
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 48 : 64,
                  vertical: isMobile ? 18 : 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store, size: isMobile ? 22 : 26),
                  SizedBox(width: isMobile ? 10 : 14),
                  Text(
                    l10n.joinNow,
                    style: TextStyle(
                      fontSize: isMobile ? 17 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建页脚
  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      color: Colors.grey[100],
      child: Text(
        l10n.copyright,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }
}
