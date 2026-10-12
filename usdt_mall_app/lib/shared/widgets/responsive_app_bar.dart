import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive_util.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/app_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/image_util.dart';
import '../../core/services/router_service_v2.dart';
import '../../features/home/widgets/mall_app_bar.dart';
import '../../features/auth/widgets/auth_dialog.dart';

/// 响应式 AppBar
/// 移动端：简洁的 AppBar 带返回按钮和菜单按钮
/// Web端：使用完整的 MallAppBar
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool? showBackButton; // 改为可空类型，null 表示自动判断
  final List<Widget>? actions;
  final bool showMenu;
  final VoidCallback? onBackPressed; // 自定义返回按钮回调

  const ResponsiveAppBar({
    super.key,
    this.title,
    this.showBackButton, // 不再有默认值
    this.actions,
    this.showMenu = true,
    this.onBackPressed,
  });

  @override
  Size get preferredSize {
    // 移动端使用标准高度，Web端使用 MallAppBar 的高度
    return const Size.fromHeight(kToolbarHeight);
  }

  /// 构建菜单项列表
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final userInfo = authProvider.userInfo;

    List<PopupMenuEntry<String>> items = [];

    // 用户信息或登录/注册
    if (isAuthenticated && userInfo != null) {
      items.add(
        PopupMenuItem<String>(
          value: 'account',
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                backgroundImage: userInfo.avatar != null && userInfo.avatar!.isNotEmpty
                    ? NetworkImage(ImageUtil.getImageUrl(userInfo.avatar!))
                    : null,
                child: userInfo.avatar == null || userInfo.avatar!.isEmpty
                    ? Icon(Icons.person, size: 16, color: Colors.grey[700])
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userInfo.nickname,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      userInfo.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      items.add(
        PopupMenuItem<String>(
          value: 'login',
          child: Row(
            children: [
              Icon(Icons.login, color: Colors.grey[800]),
              const SizedBox(width: 12),
              Text(l10n.loginOrRegister),
            ],
          ),
        ),
      );
    }

    items.add(const PopupMenuDivider());

    // 搜索
    items.add(
      PopupMenuItem<String>(
        value: 'search',
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[800]),
            const SizedBox(width: 12),
            Text(l10n.search),
          ],
        ),
      ),
    );

    // 首页
    items.add(
      PopupMenuItem<String>(
        value: 'home',
        child: Row(
          children: [
            Icon(Icons.home, color: Colors.grey[800]),
            const SizedBox(width: 12),
            Text(l10n.home),
          ],
        ),
      ),
    );

    // 如果已登录，添加退出选项
    if (isAuthenticated) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[700]),
              const SizedBox(width: 12),
              Text(
                l10n.logout,
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  /// 处理菜单选择
  void _handleMenuSelection(BuildContext context, String value) async {
    switch (value) {
      case 'account':
        context.go(AppRoutes.account);
        break;
      case 'login':
        // 显示登录对话框
        await showDialog(
          context: context,
          builder: (context) => const AuthDialog(isLogin: true),
        );
        break;
      case 'search':
        context.push(AppRoutes.mobileSearch);
        break;
      case 'home':
        context.go(AppRoutes.landing);
        break;
      case 'logout':
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        if (context.mounted) {
          context.go(AppRoutes.landing);
        }
        break;
    }
  }

  /// 构建分类菜单项列表
  List<PopupMenuEntry<String>> _buildCategoryMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      PopupMenuItem<String>(
        value: '/category/life',
        child: Row(
          children: [
            Image.asset('assets/pic/life.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.life),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/man-shoes',
        child: Row(
          children: [
            Image.asset('assets/pic/man-shoe.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.menShoes),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/woman-shoes',
        child: Row(
          children: [
            Image.asset('assets/pic/woman-shoe.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.womenShoes),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/accessories',
        child: Row(
          children: [
            Image.asset('assets/pic/peishi.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.accessories),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/man-clothing',
        child: Row(
          children: [
            Image.asset('assets/pic/man-cloth.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.menClothing),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/woman-clothing',
        child: Row(
          children: [
            Image.asset('assets/pic/woman-cloth.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.womenClothing),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/man-bags',
        child: Row(
          children: [
            Image.asset('assets/pic/man-bag.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.menBags),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/woman-bags',
        child: Row(
          children: [
            Image.asset('assets/pic/woman-bag.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.womenBags),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/boy-clothing',
        child: Row(
          children: [
            Image.asset('assets/pic/man-child.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.boyClothing),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/girl-clothing',
        child: Row(
          children: [
            Image.asset('assets/pic/woman-child.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.girlClothing),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: '/category/global-shopping',
        child: Row(
          children: [
            Image.asset('assets/pic/global.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(l10n.globalShopping),
          ],
        ),
      ),
    ];
  }

  /// 处理分类菜单选择
  void _handleCategorySelection(BuildContext context, String route) {
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      // 移动端：简洁的 AppBar
      final router = GoRouter.of(context);
      final location = router.routerDelegate.currentConfiguration.uri.toString();

      // 判断是否显示返回按钮：
      // 1. 如果明确传入了 showBackButton 参数，使用传入的值
      // 2. 否则根据路由自动判断
      final shouldShowBackButton = showBackButton ?? RouteUtils.shouldShowBackButton(location);
      final shouldShowCategoryMenu = RouteUtils.shouldShowCategoryMenu(location);

      return AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        // Leading 部分：返回按钮或分类菜单
        leading: shouldShowBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else if (router.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              )
            : shouldShowCategoryMenu
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.category, color: Colors.white),
                    offset: const Offset(0, 50),
                    tooltip: AppLocalizations.of(context).translate('categories'),
                    itemBuilder: (context) => _buildCategoryMenuItems(context),
                    onSelected: (value) => _handleCategorySelection(context, value),
                  )
                : null,
        title: Text(
          title ?? AppLocalizations.of(context).appName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (actions != null) ...actions!,
          // 分类页面：在右侧也显示分类菜单
          if (shouldShowBackButton && shouldShowCategoryMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.category, color: Colors.white),
              offset: const Offset(0, 50),
              tooltip: AppLocalizations.of(context).translate('categories'),
              itemBuilder: (context) => _buildCategoryMenuItems(context),
              onSelected: (value) => _handleCategorySelection(context, value),
            ),
          // 语言切换按钮
          Consumer<AppProvider>(
            builder: (context, appProvider, _) {
              return PopupMenuButton<SupportedLocale>(
                icon: const Icon(Icons.language, color: Colors.white),
                offset: const Offset(0, 50),
                itemBuilder: (context) {
                  final currentLocale = appProvider.locale;
                  return SupportedLocale.values.map((locale) {
                    final isSelected = currentLocale.languageCode == locale.languageCode;
                    return PopupMenuItem<SupportedLocale>(
                      value: locale,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[700] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              locale.languageCode.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              locale.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.blue[700] : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                        ],
                      ),
                    );
                  }).toList();
                },
                onSelected: (locale) {
                  appProvider.changeLocale(locale.locale);
                },
              );
            },
          ),
          // 菜单按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            offset: const Offset(0, 50),
            itemBuilder: (context) => _buildMenuItems(context),
            onSelected: (value) => _handleMenuSelection(context, value),
          ),
        ],
      );
    } else {
      // Web端：使用原有的 MallAppBar
      return const MallAppBar();
    }
  }
}
