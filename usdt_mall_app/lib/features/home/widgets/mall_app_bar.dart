import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/router_service.dart';
import '../../../core/utils/image_util.dart';
import '../../auth/widgets/auth_dialog.dart';
import 'announcement_bar.dart';

/// 商城首页AppBar组件
class MallAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? initialKeyword;
  final int? initialSearchType;
  final Function(String keyword, int searchType)? onSearch;

  const MallAppBar({
    super.key,
    this.initialKeyword,
    this.initialSearchType,
    this.onSearch,
  });

  @override
  State<MallAppBar> createState() => _MallAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(96); // 设置为最大高度
}

class _MallAppBarState extends State<MallAppBar> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;
  int _searchType = 0; // 0: 搜商品, 1: 搜店铺
  final GlobalKey _avatarKey = GlobalKey(); // 头像的GlobalKey
  bool _hasAnnouncement = true; // 是否有公告，初始为true，等待公告加载后更新

  @override
  void initState() {
    super.initState();
    // 设置初始关键词和搜索类型
    if (widget.initialKeyword != null) {
      _searchController.text = widget.initialKeyword!;
    }
    if (widget.initialSearchType != null) {
      _searchType = widget.initialSearchType!;
    }
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
    // 加载购物车数量
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      appProvider.loadCartCount();
    });
  }

  @override
  void didUpdateWidget(MallAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当关键词或搜索类型变化时，更新输入框
    if (oldWidget.initialKeyword != widget.initialKeyword) {
      _searchController.text = widget.initialKeyword ?? '';
    }
    if (oldWidget.initialSearchType != widget.initialSearchType) {
      setState(() {
        _searchType = widget.initialSearchType ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarHeight = _hasAnnouncement ? 96.0 : 60.0;

    return SizedBox(
      height: appBarHeight,
      child: AppBar(
        backgroundColor: const Color(0xFFF3F9FF),
        elevation: 2,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          height: appBarHeight,
          alignment: Alignment.center,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFirstRow(context),
                if (_hasAnnouncement) _buildSecondRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建第一行（Logo、搜索栏、按钮组）
  Widget _buildFirstRow(BuildContext context) {
    return Container(
      height: 60, // 减小高度，让整体更紧凑
      padding: const EdgeInsets.symmetric(horizontal: 16), // 去掉上下padding，只保留左右
      child: Row(
        children: [
          _buildLogo(context),
          const SizedBox(width: 16),
          Expanded(child: _buildSearchBar(context)),
          const SizedBox(width: 16),
          _buildActions(context),
        ],
      ),
    );
  }

  /// 构建第二行（系统公告）
  Widget _buildSecondRow(BuildContext context) {
    return AnnouncementBar(
      onAnnouncementStatusChanged: (hasAnnouncement) {
        if (mounted && _hasAnnouncement != hasAnnouncement) {
          setState(() {
            _hasAnnouncement = hasAnnouncement;
          });
        }
      },
    );
  }

  /// 构建Logo
  Widget _buildLogo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () {
        context.go(RoutePaths.home);
      },
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Image.asset(
        'assets/pic/logo1.jpg',
        width: 96,
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSearchFocused ? Colors.blue[700]! : Colors.grey[300]!,
          width: _isSearchFocused ? 2 : 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 14, height: 1.2),
              onSubmitted: (_) => _performSearch(context),
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: _searchType == 0 ? l10n.searchProducts : l10n.searchShops,
                hintStyle: const TextStyle(fontSize: 14, height: 1.2),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.search, size: 20),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
                border: InputBorder.none,
              ),
            ),
          ),
          _buildSearchTypeButtons(context),
          _buildSearchButton(context),
        ],
      ),
    );
  }

  /// 执行搜索
  void _performSearch(BuildContext context) {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    // 如果有搜索回调，优先使用回调（在搜索结果页面）
    if (widget.onSearch != null) {
      widget.onSearch!(keyword, _searchType);
    } else {
      // 否则跳转到搜索结果页
      context.go('/search?keyword=$keyword&type=$_searchType');
    }
  }

  /// 构建搜索类型按钮
  Widget _buildSearchTypeButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Row(
        children: [
          _buildSearchTypeButton(l10n.searchProducts, 0),
          const SizedBox(width: 4),
          _buildSearchTypeButton(l10n.searchShops, 1),
        ],
      ),
    );
  }

  /// 构建搜索按钮
  Widget _buildSearchButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () => _performSearch(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            l10n.search,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建单个搜索类型按钮
  Widget _buildSearchTypeButton(String label, int type) {
    final isSelected = _searchType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _searchType = type;
        });
        // 如果有输入内容，立即执行搜索
        if (_searchController.text.trim().isNotEmpty) {
          _performSearch(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.blue[700] : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 构建右侧按钮组
  Widget _buildActions(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return Row(
      children: [
        _buildHomeButton(context),
        const SizedBox(width: 12),
        if (isAuthenticated) ...[
          _buildUserInfo(context),
          const SizedBox(width: 12),
          _buildCartButton(context),
          const SizedBox(width: 12),
        ] else ...[
          _buildLoginButton(context),
          const SizedBox(width: 12),
        ],
        _buildLanguageSelector(context),
      ],
    );
  }

  /// 构建"家"按钮
  Widget _buildHomeButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.home),
      onPressed: () {
        context.go(RoutePaths.landing);
      },
      tooltip: l10n.returnToHome,
    );
  }

  /// 构建登录/注册按钮
  Widget _buildLoginButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const AuthDialog(isLogin: true),
        );
      },
      child: Text(
        l10n.loginOrRegister,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  /// 构建用户信息
  Widget _buildUserInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final nickname = authProvider.userInfo?.nickname ?? l10n.userNickname;
    final avatar = authProvider.userInfo?.avatar;

    return TextButton(
      onPressed: () {
        context.go(RoutePaths.account);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 圆形头像 - 带下拉菜单
          GestureDetector(
            key: _avatarKey,
            onTap: () {
              _showUserMenu(context);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? NetworkImage(ImageUtil.getImageUrl(avatar))
                    : null,
                child: avatar == null || avatar.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.blue[700],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 昵称
          Text(nickname),
        ],
      ),
    );
  }

  /// 构建购物车按钮
  Widget _buildCartButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appProvider = context.watch<AppProvider>();
    final cartCount = appProvider.cartCount;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () {
            context.go(RoutePaths.cart);
          },
          tooltip: l10n.cart,
        ),
        if (cartCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(
                minWidth: 14,
                minHeight: 14,
              ),
              child: Text(
                cartCount > 99 ? '99+' : '$cartCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建语言选择器
  Widget _buildLanguageSelector(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currentLocale = appProvider.locale;
    final currentLang = SupportedLocale.fromLocale(currentLocale);

    return PopupMenuButton<SupportedLocale>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      position: PopupMenuPosition.under,
      // offset: const Offset(0, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.language, size: 20),
            const SizedBox(width: 4),
            Text(
              currentLang.label,
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
      onSelected: (locale) {
        context.read<AppProvider>().changeLocale(locale.locale);
      },
      itemBuilder: (context) {
        return SupportedLocale.values.map((locale) {
          return PopupMenuItem<SupportedLocale>(
            value: locale,
            child: Text(locale.label),
          );
        }).toList();
      },
    );
  }

  /// 显示用户菜单
  void _showUserMenu(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    // 使用GlobalKey获取头像的位置信息
    final RenderBox? renderBox = _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,                    // 左边距
        offset.dy + size.height + 5,  // 上边距（头像下方，加5像素间距）
        offset.dx + size.width,       // 右边距
        0,                            // 下边距
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'logout',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 16),
              const SizedBox(width: 8),
              Text(l10n.logout, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );

    if (result == 'logout' && context.mounted) {
      await _handleLogout(context);
    }
  }

  /// 处理退出登录
  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();

    try {
      // 调用退出接口（会自动设置离线状态并清除token和用户信息）
      await authProvider.logout();

      if (context.mounted) {
        // 获取当前路由路径
        final currentPath = GoRouterState.of(context).uri.path;

        // 判断是否需要跳转
        // 如果在购物车、即时沟通或账户页面，跳转到商城首页
        if (currentPath.contains('/cart') ||
            currentPath.contains('/chat') ||
            currentPath.contains('/account')) {
          context.go(RoutePaths.home);
        }
        // 其他页面保持不变

        // 显示退出成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.logoutSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.logoutError}: $e')),
        );
      }
    }
  }
}
