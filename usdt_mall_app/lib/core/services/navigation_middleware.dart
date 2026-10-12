import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

/// 路由守卫 - 认证检查
class AuthGuard {
  final AuthProvider authProvider;

  AuthGuard(this.authProvider);

  /// 检查是否需要认证
  String? checkAuth(BuildContext context, GoRouterState state) {
    final isAuthenticated = authProvider.isAuthenticated;
    final location = state.matchedLocation;

    // 需要认证的路由列表
    final protectedRoutes = [
      '/cart',
      '/chat',
      '/account',
      '/orders',
      '/profile',
      '/recharge',
      '/withdraw',
      '/shop/products',
      '/shop/orders',
    ];

    // 检查是否为受保护的路由
    final isProtected = protectedRoutes.any((route) => location.startsWith(route));

    if (isProtected && !isAuthenticated) {
      // 未登录，重定向到首页
      return '/';
    }

    return null;
  }
}

/// 路由中间件 - 日志记录
class RouteLogger {
  static void log(BuildContext context, GoRouterState state) {
    debugPrint('🔀 Route: ${state.matchedLocation}');
    if (state.pathParameters.isNotEmpty) {
      debugPrint('   Params: ${state.pathParameters}');
    }
    if (state.uri.queryParameters.isNotEmpty) {
      debugPrint('   Query: ${state.uri.queryParameters}');
    }
  }
}

/// 路由中间件 - 页面分析
class RouteAnalytics {
  static void track(BuildContext context, GoRouterState state) {
    // 这里可以集成第三方分析工具
    // 例如: Firebase Analytics, Google Analytics 等
    debugPrint('📊 Analytics: Page view - ${state.matchedLocation}');
  }
}

/// 路由观察者 - 监听路由变化
class AppRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRouteChange('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logRouteChange('POP', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logRouteChange('REPLACE', newRoute, oldRoute);
  }

  void _logRouteChange(String action, Route<dynamic>? route, Route<dynamic>? previousRoute) {
    debugPrint('🔄 Route $action: ${route?.settings.name ?? 'unknown'}');
    if (previousRoute != null) {
      debugPrint('   From: ${previousRoute.settings.name ?? 'unknown'}');
    }
  }
}

/// 导航助手类
class NavigationHelper {
  /// 安全导航 - 检查路由是否存在
  static void safeGo(BuildContext context, String location) {
    try {
      context.go(location);
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      // 导航失败，返回首页
      context.go('/');
    }
  }

  /// 带参数导航
  static void goWithParams(
    BuildContext context,
    String path, {
    Map<String, String>? pathParams,
    Map<String, String>? queryParams,
  }) {
    var finalPath = path;

    // 替换路径参数
    if (pathParams != null) {
      pathParams.forEach((key, value) {
        finalPath = finalPath.replaceAll(':$key', value);
      });
    }

    // 添加查询参数
    if (queryParams != null && queryParams.isNotEmpty) {
      final query = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      finalPath = '$finalPath?$query';
    }

    context.go(finalPath);
  }

  /// 返回上一页，如果没有上一页则跳转到首页
  static void goBackOrHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// 清空导航栈并跳转
  static void goAndRemoveUntil(BuildContext context, String location) {
    context.go(location);
  }
}

/// 深度链接处理器
class DeepLinkHandler {
  /// 解析深度链接
  static String? parseDeepLink(Uri uri) {
    // 示例: myapp://product/123 -> /product/123
    if (uri.scheme == 'myapp') {
      return '/${uri.host}${uri.path}';
    }
    return null;
  }

  /// 处理外部链接
  static Future<void> handleExternalLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final route = parseDeepLink(uri);

    if (route != null) {
      NavigationHelper.safeGo(context, route);
    } else {
      debugPrint('⚠️ Unsupported deep link: $url');
    }
  }
}
