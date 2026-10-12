import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/unread_message_provider.dart';
import '../../core/services/router_service_v2.dart';
import '../../core/l10n/app_localizations.dart';
import '../../features/auth/widgets/auth_dialog.dart';

/// 底部导航项配置
class BottomNavItem {
  final String route;
  final IconData icon;
  final String Function(AppLocalizations) label;
  final bool requiresAuth;
  final Widget Function(BuildContext)? badgeBuilder;

  const BottomNavItem({
    required this.route,
    required this.icon,
    required this.label,
    this.requiresAuth = false,
    this.badgeBuilder,
  });
}

/// 移动端底部导航栏 V2
class MobileBottomNavV2 extends StatelessWidget {
  const MobileBottomNavV2({super.key});

  /// 底部导航配置
  static final List<BottomNavItem> _navItems = [
    BottomNavItem(
      route: '/home',  // 直接使用字符串
      icon: Icons.home,
      label: (l10n) => l10n.home,
    ),
    BottomNavItem(
      route: '/cart',  // 直接使用字符串
      icon: Icons.shopping_cart,
      label: (l10n) => l10n.cart,
      requiresAuth: true,
      badgeBuilder: (context) {
        final cartCount = context.watch<AppProvider>().cartCount;
        return cartCount > 0
            ? Badge(
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart),
              )
            : const Icon(Icons.shopping_cart);
      },
    ),
    BottomNavItem(
      route: '/chat',  // 直接使用字符串
      icon: Icons.chat,
      label: (l10n) => l10n.instantChat,
      requiresAuth: true,
      badgeBuilder: (context) {
        final unreadCount = context.watch<UnreadMessageProvider>().unreadCount;
        return unreadCount > 0
            ? Badge(
                label: Text('$unreadCount'),
                child: const Icon(Icons.chat),
              )
            : const Icon(Icons.chat);
      },
    ),
    BottomNavItem(
      route: '/account',  // 直接使用字符串
      icon: Icons.person,
      label: (l10n) => l10n.myAccount,
      requiresAuth: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    final currentIndex = RouteUtils.getBottomNavIndex(location);

    return BottomNavigationBar(
      currentIndex: currentIndex >= 0 ? currentIndex : 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue[700],
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) => _handleNavigation(context, index, currentIndex),
      items: _buildNavItems(context, l10n),
    );
  }

  /// 构建导航项
  List<BottomNavigationBarItem> _buildNavItems(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return _navItems.map((item) {
      final icon = item.badgeBuilder?.call(context) ?? Icon(item.icon);
      return BottomNavigationBarItem(
        icon: icon,
        label: item.label(l10n),
      );
    }).toList();
  }

  /// 处理导航
  void _handleNavigation(BuildContext context, int index, int currentIndex) {
    // 只有在主菜单页面且点击当前标签时，才不做任何操作
    // currentIndex == -1 表示在子页面，此时应该允许导航
    if (currentIndex >= 0 && index == currentIndex) {
      return;
    }

    final navItem = _navItems[index];

    final authProvider = context.read<AuthProvider>();

    // 检查是否需要认证
    if (navItem.requiresAuth && !authProvider.isAuthenticated) {
      _showLoginDialog(context);
      return;
    }

    // 导航到目标页面
    context.go(navItem.route);
  }

  /// 显示登录对话框
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AuthDialog(isLogin: true),
    );
  }
}
