import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/router_service_v2.dart';
import '../core/services/navigation_middleware.dart';

/// 路由导航系统使用示例

// ============================================
// 1. 基本导航示例
// ============================================

class BasicNavigationExample extends StatelessWidget {
  const BasicNavigationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 简单导航
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Go to Home'),
        ),

        // 带路径参数的导航
        ElevatedButton(
          onPressed: () {
            final productId = '12345';
            context.go(AppRoutes.productDetailPath(productId));
          },
          child: const Text('Go to Product Detail'),
        ),

        // 带查询参数的导航
        ElevatedButton(
          onPressed: () {
            context.go(AppRoutes.searchPath(keyword: 'phone', type: 1));
          },
          child: const Text('Search Products'),
        ),

        // 使用 push 导航（保留历史）
        ElevatedButton(
          onPressed: () => context.push(AppRoutes.cart),
          child: const Text('Push to Cart'),
        ),

        // 返回上一页
        ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('Go Back'),
        ),
      ],
    );
  }
}

// ============================================
// 2. 使用导航助手
// ============================================

class NavigationHelperExample extends StatelessWidget {
  const NavigationHelperExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 安全导航（自动处理错误）
        ElevatedButton(
          onPressed: () {
            NavigationHelper.safeGo(context, '/some/route');
          },
          child: const Text('Safe Navigation'),
        ),

        // 带参数导航
        ElevatedButton(
          onPressed: () {
            NavigationHelper.goWithParams(
              context,
              AppRoutes.productDetail,
              pathParams: {'id': '123'},
              queryParams: {'ref': 'home'},
            );
          },
          child: const Text('Navigate with Params'),
        ),

        // 智能返回（没有历史则回首页）
        ElevatedButton(
          onPressed: () {
            NavigationHelper.goBackOrHome(context);
          },
          child: const Text('Back or Home'),
        ),
      ],
    );
  }
}

// ============================================
// 3. 底部导航集成示例
// ============================================

class BottomNavIntegrationExample extends StatelessWidget {
  const BottomNavIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    final currentIndex = RouteUtils.getBottomNavIndex(location);

    return Scaffold(
      body: Center(
        child: Text('Current Tab Index: $currentIndex'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex >= 0 ? currentIndex : 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
              break;
            case 1:
              context.go(AppRoutes.cart);
              break;
            case 2:
              context.go(AppRoutes.chat);
              break;
            case 3:
              context.go(AppRoutes.account);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

// ============================================
// 4. 路由守卫使用示例
// ============================================

class RouteGuardExample {
  // 在 router_service_v2.dart 中集成守卫
  static void integrateGuard() {
    // 示例代码（实际使用时在 RouterServiceV2 中配置）
    /*
    GoRouter(
      redirect: (context, state) {
        // 使用认证守卫
        final authGuard = AuthGuard(authProvider);
        final authRedirect = authGuard.checkAuth(context, state);
        if (authRedirect != null) return authRedirect;

        // 记录路由日志
        RouteLogger.log(context, state);

        // 追踪页面访问
        RouteAnalytics.track(context, state);

        return null;
      },
    );
    */
  }
}

// ============================================
// 5. 深度链接处理示例
// ============================================

class DeepLinkExample extends StatelessWidget {
  const DeepLinkExample({super.key});

  void handleDeepLink(BuildContext context, String url) async {
    // 处理外部链接
    await DeepLinkHandler.handleExternalLink(context, url);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // 模拟接收深度链接
        handleDeepLink(context, 'myapp://product/123');
      },
      child: const Text('Handle Deep Link'),
    );
  }
}

// ============================================
// 6. 页面包装器使用示例
// ============================================

class PageWrapperExample extends StatelessWidget {
  const PageWrapperExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用方式在 page_wrappers.dart 中定义
    // 这里展示如何在实际页面中使用

    return const SizedBox.shrink();

    // 实际使用示例：
    /*
    return PageWrapper(
      title: 'My Page',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
      ],
      child: ListView(
        children: [
          // 页面内容
        ],
      ),
    );
    */
  }
}

// ============================================
// 7. 路由状态监听示例
// ============================================

class RouteListenerExample extends StatefulWidget {
  const RouteListenerExample({super.key});

  @override
  State<RouteListenerExample> createState() => _RouteListenerExampleState();
}

class _RouteListenerExampleState extends State<RouteListenerExample> {
  String _currentRoute = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    _currentRoute = router.routerDelegate.currentConfiguration.uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Current Route: $_currentRoute'),
    );
  }
}

// ============================================
// 8. 条件导航示例
// ============================================

class ConditionalNavigationExample extends StatelessWidget {
  const ConditionalNavigationExample({super.key});

  void navigateBasedOnCondition(BuildContext context, bool isLoggedIn) {
    if (isLoggedIn) {
      context.go(AppRoutes.account);
    } else {
      // 显示登录对话框或跳转登录页
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final isLoggedIn = false; // 从 AuthProvider 获取
        navigateBasedOnCondition(context, isLoggedIn);
      },
      child: const Text('Navigate to Account'),
    );
  }
}

// ============================================
// 9. 嵌套路由示例
// ============================================

class NestedRouteExample {
  // 在 router_service_v2.dart 中配置嵌套路由
  static void configureNestedRoutes() {
    /*
    GoRoute(
      path: '/shop/:id',
      builder: (context, state) => ShopPage(shopId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'products',
          builder: (context, state) => ShopProductsPage(),
        ),
        GoRoute(
          path: 'orders',
          builder: (context, state) => ShopOrdersPage(),
        ),
      ],
    );
    */
  }
}

// ============================================
// 10. 路由参数提取示例
// ============================================

class RouteParamsExample extends StatelessWidget {
  const RouteParamsExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 在实际页面中提取参数
    final router = GoRouter.of(context);
    final state = router.routerDelegate.currentConfiguration;

    // 提取路径参数
    // final productId = state.pathParameters['id'];

    // 提取查询参数
    // final keyword = state.uri.queryParameters['keyword'];

    return const Center(
      child: Text('Check console for route params'),
    );
  }
}
