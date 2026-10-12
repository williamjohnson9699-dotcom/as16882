import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/router_service_v2.dart';

/// 响应式布局包装器 - 自动处理底部导航显示
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool showBottomNav;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    final isMainMenu = RouteUtils.isMainMenuPage(location);

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      bottomNavigationBar: showBottomNav && isMainMenu
          ? _buildBottomNav(context)
          : null,
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    // 这里可以根据屏幕尺寸返回不同的导航组件
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      // 移动端 - 使用底部导航
      return const SizedBox.shrink(); // 实际使用时替换为 MobileBottomNavV2()
    } else {
      // 平板/桌面 - 可以使用侧边导航或其他布局
      return const SizedBox.shrink();
    }
  }
}

/// 页面包装器 - 提供统一的页面结构
class PageWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? floatingActionButton;
  final bool showBottomNav;

  const PageWrapper({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.floatingActionButton,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      showBottomNav: showBottomNav,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackPressed ?? () => context.pop(),
              )
            : null,
      ),
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// 加载页面包装器
class LoadingPageWrapper extends StatelessWidget {
  final String title;
  final Future<Widget> Function() builder;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorBuilder;

  const LoadingPageWrapper({
    super.key,
    required this.title,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: title,
      child: FutureBuilder<Widget>(
        future: builder(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return loadingWidget ??
                const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return errorBuilder?.call(snapshot.error!) ??
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                );
          }

          return snapshot.data ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

/// 空状态页面
class EmptyStatePage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStatePage({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: title,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 错误页面
class ErrorPage extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorPage({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: title,
      showBackButton: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction ?? () => context.pop(),
                child: Text(actionLabel ?? 'Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
