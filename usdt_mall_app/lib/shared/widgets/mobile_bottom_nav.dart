import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/unread_message_provider.dart';
import '../../core/services/router_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../features/auth/widgets/auth_dialog.dart';

/// 移动端底部导航栏
class MobileBottomNav extends StatelessWidget {
  final int currentIndex;

  const MobileBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appProvider = context.watch<AppProvider>();
    final unreadProvider = context.watch<UnreadMessageProvider>();

    // 获取当前路由，动态计算 currentIndex
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();

    int actualIndex = currentIndex;
    if (location == '/' || location == '/home') {
      actualIndex = 0;
    } else if (location == '/cart') {
      actualIndex = 1;
    } else if (location == '/chat') {
      actualIndex = 2;
    } else if (location.startsWith('/account')) {
      actualIndex = 3;
    }

    return BottomNavigationBar(
      currentIndex: actualIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue[700],
      unselectedItemColor: Colors.grey[600],
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) => _onTabTapped(context, index, location),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: l10n.home,
        ),
        BottomNavigationBarItem(
          icon: appProvider.cartCount > 0
              ? Badge(
                  label: Text('${appProvider.cartCount}'),
                  child: const Icon(Icons.shopping_cart),
                )
              : const Icon(Icons.shopping_cart),
          label: l10n.cart,
        ),
        BottomNavigationBarItem(
          icon: unreadProvider.unreadCount > 0
              ? Badge(
                  label: Text('${unreadProvider.unreadCount}'),
                  child: const Icon(Icons.chat),
                )
              : const Icon(Icons.chat),
          label: l10n.instantChat,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: l10n.myAccount,
        ),
      ],
    );
  }

  void _onTabTapped(BuildContext context, int index, String currentLocation) {
    final authProvider = context.read<AuthProvider>();

    // 如果点击的是当前已选中的标签，不做任何操作
    int currentTabIndex = -1;
    if (currentLocation == '/' || currentLocation == '/home') {
      currentTabIndex = 0;
    } else if (currentLocation == '/cart') {
      currentTabIndex = 1;
    } else if (currentLocation == '/chat') {
      currentTabIndex = 2;
    } else if (currentLocation.startsWith('/account')) {
      currentTabIndex = 3;
    }

    if (index == currentTabIndex) {
      return; // 已经在当前页面，不需要导航
    }

    switch (index) {
      case 0:
        // 商城首页
        context.go(RoutePaths.home);
        break;
      case 1:
        // 购物车
        if (!authProvider.isAuthenticated) {
          _showLoginDialog(context);
        } else {
          context.go(RoutePaths.cart);
        }
        break;
      case 2:
        // 聊天
        if (!authProvider.isAuthenticated) {
          _showLoginDialog(context);
        } else {
          context.go(RoutePaths.chat);
        }
        break;
      case 3:
        // 我的账户
        if (!authProvider.isAuthenticated) {
          _showLoginDialog(context);
        } else {
          context.go(RoutePaths.account);
        }
        break;
    }
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AuthDialog(isLogin: true),
    );
  }
}
