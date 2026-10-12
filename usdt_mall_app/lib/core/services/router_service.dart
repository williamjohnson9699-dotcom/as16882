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
class RoutePaths {
  // 认证相关
  static const String login = '/login';
  static const String register = '/register';

  // 主页
  static const String landing = '/';  // 网站首页（未登录）
  static const String home = '/home';  // 商城首页（已登录）

  // 商品相关
  static const String products = '/products';
  static const String productDetail = '/product/:id';
  static const String search = '/search';
  static const String mobileSearch = '/mobile-search';
  static const String category = '/category/:name'; // 分类商品页

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
  static const String shop = '/shop/:id'; // 店铺详情页
  static const String shopProducts = '/shop/products';
  static const String shopOrders = '/shop/orders';

  // 聊天相关
  static const String chat = '/chat';
  static const String chatSession = '/chat/:sessionId';

  // 管理员相关
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminAnnouncements = '/admin/announcements';
}

/// 路由配置类型
enum RouteType {
  /// 主菜单页面（不显示返回按钮）
  mainMenu,
  /// 分类页面（显示返回按钮和分类菜单）
  category,
  /// 普通页面（只显示返回按钮）
  normal,
}

/// 路由配置
class RouteConfig {
  /// 判断路由是否为主菜单页面
  static bool isMainMenuPage(String location) {
    // 解析 URI 以检查查询参数
    final uri = Uri.parse(location);

    // 如果是 /account 但带有 menu 参数，则不是主菜单页面（是子菜单）
    if (uri.path == '/account' && uri.queryParameters.containsKey('menu')) {
      return false;
    }

    return location == '/' ||
           location == '/home' ||
           location == '/cart' ||
           location == '/chat' ||
           uri.path == '/account';
  }

  /// 判断路由是否为分类页面
  static bool isCategoryPage(String location) {
    return location.startsWith('/category/');
  }

  /// 判断路由是否需要显示返回按钮
  static bool shouldShowBackButton(String location) {
    return !isMainMenuPage(location);
  }

  /// 判断路由是否需要显示分类菜单
  static bool shouldShowCategoryMenu(String location) {
    return (location == '/' || location == '/home') || isCategoryPage(location);
  }

  /// 获取路由类型
  static RouteType getRouteType(String location) {
    if (isMainMenuPage(location)) {
      return RouteType.mainMenu;
    } else if (isCategoryPage(location)) {
      return RouteType.category;
    } else {
      return RouteType.normal;
    }
  }
}

/// 路由配置服务
class RouterService {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: RoutePaths.landing,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == RoutePaths.login ||
            state.matchedLocation == RoutePaths.register;

        // 已登录用户访问登录/注册页，跳转到商城首页
        if (isAuthenticated && isAuthRoute) {
          return RoutePaths.home;
        }

        return null;
      },
      routes: _buildRoutes(),
    );
  }

  /// 构建路由列表
  static List<RouteBase> _buildRoutes() {
    return [
      // 网站首页（Landing Page）
      GoRoute(
        path: RoutePaths.landing,
        builder: (context, state) => const LandingPage(),
      ),

      // 登录页
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => _PlaceholderPage(titleKey: 'login_page'),
      ),

      // 注册页
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => _PlaceholderPage(titleKey: 'register_page'),
      ),

      // 商城首页
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const MallHomePage(),
      ),

      // 商品列表
      GoRoute(
        path: RoutePaths.products,
        builder: (context, state) => _PlaceholderPage(titleKey: 'product_list'),
      ),

      // 商品详情页
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = state.pathParameters['id'] ?? '';
          return ProductDetailPage(productId: productId);
        },
      ),

      // 搜索结果页
      GoRoute(
        path: RoutePaths.search,
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
        path: '/mobile-search',
        builder: (context, state) => const MobileSearchPage(),
      ),

      // 分类商品页
      GoRoute(
        path: '/category/:name',
        builder: (context, state) {
          final categoryKey = state.pathParameters['name'] ?? '';
          return CategoryPage(
            categoryKey: categoryKey,
          );
        },
      ),

      // 购物车
      GoRoute(
        path: RoutePaths.cart,
        builder: (context, state) => const CartPage(),
      ),

      // 订单列表
      GoRoute(
        path: RoutePaths.orders,
        builder: (context, state) => _PlaceholderPage(titleKey: 'my_orders'),
      ),

      // 账户中心
      GoRoute(
        path: RoutePaths.account,
        builder: (context, state) {
          final menu = state.uri.queryParameters['menu'];
          return AccountPage(initialMenu: menu);
        },
      ),

      // 店铺详情页
      GoRoute(
        path: '/shop/:id',
        builder: (context, state) {
          final shopId = state.pathParameters['id'] ?? '';
          return ShopPage(shopId: shopId);
        },
      ),

      // 即时沟通
      GoRoute(
        path: RoutePaths.chat,
        builder: (context, state) => const ChatPage(),
      ),
    ];
  }
}

/// 占位页面（用于路由测试）
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
