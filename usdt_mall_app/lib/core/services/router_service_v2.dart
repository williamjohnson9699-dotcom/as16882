import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../../features/home/screens/landing_page.dart';
import '../../features/home/screens/mall_home_page.dart';
import '../../features/search/screens/search_result_page.dart';
import '../../features/search/screens/mobile_search_page.dart';
import '../../features/category/screens/category_page.dart';
import '../../features/product/screens/product_detail_page.dart';
import '../../features/shop/screens/shop_page.dart';
import '../../features/cart/screens/cart_page.dart';
import '../../features/chat/screens/chat_page.dart';
import '../../features/account/screens/account_page.dart';

/// 路由路径常量
class AppRoutes {
  // 认证相关
  static const String login = '/login';
  static const String register = '/register';

  // 主页
  static const String landing = '/';
  static const String home = '/home';

  // 商品相关
  static const String products = '/products';
  static const String productDetail = '/product/:id';
  static const String search = '/search';
  static const String mobileSearch = '/mobile-search';
  static const String category = '/category/:name';

  // 购物车
  static const String cart = '/cart';

  // 订单相关
  static const String orders = '/orders';
  static const String orderDetail = '/order/:id';

  // 账户相关
  static const String account = '/account';
  static const String profile = '/profile';
  static const String recharge = '/recharge';
  static const String withdraw = '/withdraw';

  // 店铺相关
  static const String shop = '/shop/:id';
  static const String shopProducts = '/shop/products';
  static const String shopOrders = '/shop/orders';

  // 聊天相关
  static const String chat = '/chat';
  static const String chatSession = '/chat/:sessionId';

  // 管理员相关
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminAnnouncements = '/admin/announcements';

  /// 生成商品详情路径
  static String productDetailPath(String id) => '/product/$id';

  /// 生成分类路径
  static String categoryPath(String name) => '/category/$name';

  /// 生成店铺路径
  static String shopPath(String id) => '/shop/$id';

  /// 生成搜索路径
  static String searchPath({required String keyword, int type = 0}) =>
      '/search?keyword=$keyword&type=$type';
}

/// 路由元数据
class RouteMetadata {
  /// 是否需要认证
  final bool requiresAuth;

  /// 是否为主菜单页面（显示底部导航）
  final bool isMainMenu;

  /// 是否显示返回按钮
  final bool showBackButton;

  /// 页面标题
  final String? title;

  const RouteMetadata({
    this.requiresAuth = false,
    this.isMainMenu = false,
    this.showBackButton = true,
    this.title,
  });
}

/// 路由配置项
class AppRouteConfig {
  final String path;
  final Widget Function(BuildContext, GoRouterState) builder;
  final RouteMetadata metadata;

  const AppRouteConfig({
    required this.path,
    required this.builder,
    this.metadata = const RouteMetadata(),
  });
}

/// 路由配置服务 V2
class RouterServiceV2 {
  /// 创建路由器
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.landing,
      redirect: (context, state) => _handleRedirect(context, state, authProvider),
      routes: _buildRoutes(),
      errorBuilder: (context, state) => _ErrorPage(error: state.error),
    );
  }

  /// 处理路由重定向
  static String? _handleRedirect(
    BuildContext context,
    GoRouterState state,
    AuthProvider authProvider,
  ) {
    final isAuthenticated = authProvider.isAuthenticated;
    final location = state.matchedLocation;

    // 获取路由元数据
    final metadata = _getRouteMetadata(location);

    // 已登录用户访问登录/注册页，跳转到商城首页
    if (isAuthenticated && (location == AppRoutes.login || location == AppRoutes.register)) {
      return AppRoutes.home;
    }

    // 需要认证的页面，未登录则跳转到首页
    if (metadata.requiresAuth && !isAuthenticated) {
      return AppRoutes.landing;
    }

    return null;
  }

  /// 获取路由元数据
  static RouteMetadata _getRouteMetadata(String location) {
    final uri = Uri.parse(location);
    final path = uri.path;

    // 主菜单页面
    if (path == '/' || path == '/home' || path == '/cart' || path == '/chat') {
      return const RouteMetadata(isMainMenu: true, showBackButton: false);
    }

    // 账户页面（根据查询参数判断）
    if (path == '/account') {
      final hasMenu = uri.queryParameters.containsKey('menu');
      return RouteMetadata(
        requiresAuth: true,
        isMainMenu: !hasMenu,
        showBackButton: hasMenu,
      );
    }

    // 需要认证的页面
    if (path.startsWith('/order') ||
        path.startsWith('/profile') ||
        path.startsWith('/recharge') ||
        path.startsWith('/withdraw') ||
        path.startsWith('/shop/products') ||
        path.startsWith('/shop/orders')) {
      return const RouteMetadata(requiresAuth: true);
    }

    // 默认配置
    return const RouteMetadata();
  }

  /// 构建路由列表
  static List<RouteBase> _buildRoutes() {
    return [
      // 网站首页
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const LandingPage(),
      ),

      // 登录页
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => _PlaceholderPage(titleKey: 'login_page'),
      ),

      // 注册页
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => _PlaceholderPage(titleKey: 'register_page'),
      ),

      // 商城首页
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MallHomePage(),
      ),

      // 商品列表
      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => _PlaceholderPage(titleKey: 'product_list'),
      ),

      // 商品详情页
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) {
          final productId = state.pathParameters['id'] ?? '';
          return ProductDetailPage(productId: productId);
        },
      ),

      // 搜索结果页
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) {
          final keyword = state.uri.queryParameters['keyword'] ?? '';
          final typeStr = state.uri.queryParameters['type'] ?? '0';
          final searchType = int.tryParse(typeStr) ?? 0;
          return SearchResultPage(
            keyword: keyword,
            searchType: searchType,
          );
        },
      ),

      // 移动端搜索页
      GoRoute(
        path: AppRoutes.mobileSearch,
        builder: (context, state) => const MobileSearchPage(),
      ),

      // 分类商品页
      GoRoute(
        path: AppRoutes.category,
        builder: (context, state) {
          final categoryKey = state.pathParameters['name'] ?? '';
          return CategoryPage(categoryKey: categoryKey);
        },
      ),

      // 购物车
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartPage(),
      ),

      // 订单列表
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => _PlaceholderPage(titleKey: 'my_orders'),
      ),

      // 账户中心
      GoRoute(
        path: AppRoutes.account,
        builder: (context, state) {
          final menu = state.uri.queryParameters['menu'];
          return AccountPage(initialMenu: menu);
        },
      ),

      // 店铺详情页
      GoRoute(
        path: AppRoutes.shop,
        builder: (context, state) {
          final shopId = state.pathParameters['id'] ?? '';
          return ShopPage(shopId: shopId);
        },
      ),

      // 即时沟通
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final sessionIdStr = state.uri.queryParameters['sessionId'];
          final sessionId = sessionIdStr != null ? int.tryParse(sessionIdStr) : null;
          final targetUserIdStr = state.uri.queryParameters['targetUserId'];
          final targetUserId = targetUserIdStr != null ? int.tryParse(targetUserIdStr) : null;
          return ChatPage(
            initialSessionId: sessionId,
            targetUserId: targetUserId,
          );
        },
      ),
    ];
  }
}

/// 路由工具类
class RouteUtils {
  /// 主菜单路由列表（精确匹配）
  static const List<String> _mainMenuRoutes = [
    '/',
    '/home',
    '/cart',
    '/chat',
    '/account',
  ];

  /// 判断是否为主菜单页面（只有这些页面显示底部导航，不显示返回按钮）
  static bool isMainMenuPage(String location) {
    final uri = Uri.parse(location);
    final path = uri.path;

    // /account 带 menu 参数的是子菜单，不是主菜单
    if (path == '/account' && uri.queryParameters.containsKey('menu')) {
      return false;
    }

    // 精确匹配主菜单路由
    return _mainMenuRoutes.contains(path);
  }

  /// 判断是否为分类页面
  static bool isCategoryPage(String location) {
    return location.startsWith('/category/');
  }

  /// 判断是否需要显示返回按钮
  /// 规则：非主菜单页面都显示返回按钮
  static bool shouldShowBackButton(String location) {
    return !isMainMenuPage(location);
  }

  /// 判断是否需要显示分类菜单
  static bool shouldShowCategoryMenu(String location) {
    return (location == '/' || location == '/home') || isCategoryPage(location);
  }

  /// 从路径获取底部导航索引
  /// 返回 -1 表示不在底部导航中
  static int getBottomNavIndex(String location) {
    final uri = Uri.parse(location);
    final path = uri.path;

    // 精确匹配底部导航路由
    if (path == '/' || path == '/home') return 0;
    if (path == '/cart') return 1;
    if (path == '/chat') return 2;
    if (path == '/account' && !uri.queryParameters.containsKey('menu')) return 3;

    return -1; // 不在底部导航中
  }

  /// 判断路由是否需要显示底部导航
  /// 只有主菜单页面才显示底部导航
  static bool shouldShowBottomNav(String location) {
    return isMainMenuPage(location);
  }
}

/// 错误页面
class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.landing),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 占位页面
class _PlaceholderPage extends StatelessWidget {
  final String titleKey;

  const _PlaceholderPage({required this.titleKey});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _getTitle(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n(${l10n.pendingImplementation})',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  String _getTitle(AppLocalizations l10n) {
    switch (titleKey) {
      case 'login_page':
        return l10n.loginPage;
      case 'register_page':
        return l10n.registerPage;
      case 'product_list':
        return l10n.productList;
      case 'my_orders':
        return l10n.myOrders;
      default:
        return titleKey;
    }
  }
}
