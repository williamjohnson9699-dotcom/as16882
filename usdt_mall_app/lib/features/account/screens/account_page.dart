import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../home/widgets/mall_app_bar.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/responsive_app_bar.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/services/router_service_v2.dart';
import '../widgets/account_menu.dart';
import '../widgets/account_info_view.dart';
import '../widgets/my_orders_view.dart';
import '../widgets/account_records_view.dart';
import '../widgets/address_management_view.dart';
import '../widgets/my_follows_view.dart';
import '../widgets/system_announcement_view.dart';
import '../widgets/apply_shop_view.dart';
import '../widgets/my_shop_view.dart';
import '../widgets/shop_applications_management_view.dart';
import '../widgets/shop_products_view.dart';
import '../widgets/shop_orders_view.dart';
import '../widgets/shop_payment_lock_view.dart';
import '../widgets/virtual_data_view.dart';
import '../widgets/app_update_view.dart';
import '../widgets/proxy_order_view.dart';
import '../widgets/permission_management_view.dart';
import '../widgets/shop_management_view.dart';
import '../widgets/product_management_view.dart';
import '../widgets/carousel_products_view.dart';
import '../widgets/system_config_view.dart';
import '../widgets/download_app_view.dart';
import '../../chat/screens/chat_page.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/providers/unread_message_provider.dart';
import '../../../core/l10n/app_localizations.dart';

/// 账号页面
class AccountPage extends StatefulWidget {
  final String? initialMenu;

  const AccountPage({super.key, this.initialMenu});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? _selectedMenu; // 当前选中的菜单
  String? _orderStatus; // 订单状态参数

  @override
  void initState() {
    super.initState();
    // 使用传入的初始菜单，移动端默认为null显示菜单列表，桌面端默认为'account'
    _selectedMenu = widget.initialMenu;
    // 加载待处理订单数量和账户记录数量
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      final authProvider = context.read<AuthProvider>();
      appProvider.loadUserOrderStats();
      appProvider.loadPendingRecordCount();
      appProvider.loadPendingShopApplicationCount();
      appProvider.loadFollowStats();
      if (authProvider.isShop ||
          authProvider.isAdmin ||
          authProvider.isService) {
        appProvider.loadShopOrderStats(null);
      }
    });
  }

  @override
  void didUpdateWidget(AccountPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当路由参数变化时，更新选中的菜单
    if (widget.initialMenu != oldWidget.initialMenu) {
      setState(() {
        _selectedMenu = widget.initialMenu;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    final shouldShowBottomNav = RouteUtils.shouldShowBottomNav(location);

    // 读取URL参数中的menu
    final uri = router.routerDelegate.currentConfiguration.uri;
    final menuParam = uri.queryParameters['menu'];
    if (menuParam != null && _selectedMenu != menuParam) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedMenu = menuParam;
        });
      });
    }

    // 桌面端：如果没有选中菜单，默认选中'account'
    if (!isMobile && _selectedMenu == null) {
      _selectedMenu = 'account';
    }

    return Scaffold(
      appBar: isMobile
          ? ResponsiveAppBar(
              title: _selectedMenu == null
                  ? l10n.myAccount
                  : _getMenuTitle(context, _selectedMenu!),
              onBackPressed: _selectedMenu != null
                  ? () {
                      // 返回到菜单列表
                      context.go('/account');
                    }
                  : null,
            )
          : const MallAppBar(),
      body: SafeArea(
        child: AppBackground(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: ResponsiveUtil.getContentConstraints(context),
              color: Colors.white,
              child: isMobile
                  ? (_selectedMenu == null
                      ? _buildMobileMenuList() // 移动端：未选择菜单时显示列表
                      : _buildContentViewWithBack(
                          context)) // 移动端：选择菜单后显示内容（带返回按钮）
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左侧菜单（仅桌面端）
                        AccountMenu(
                          selectedMenu: _selectedMenu ?? 'account',
                          onMenuSelected: (menu, {String? orderStatus}) {
                            setState(() {
                              _selectedMenu = menu;
                              _orderStatus = orderStatus;
                            });
                          },
                        ),
                        // 右侧内容区
                        Expanded(
                          child: _buildContentView(context),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          isMobile && shouldShowBottomNav ? const MobileBottomNavV2() : null,
      // 浮动按钮（仅桌面端）
      floatingActionButton: !isMobile
          ? Consumer<UnreadMessageProvider>(
              builder: (context, unreadProvider, _) {
                final unreadCount = unreadProvider.unreadCount;

                return unreadCount > 0
                    ? Badge(
                        label: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        child: FloatingActionButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ChatPage()),
                            );
                            // 返回后刷新未读数量
                            unreadProvider.refresh();
                          },
                          backgroundColor: Colors.blue[700],
                          child: const Icon(Icons.chat, color: Colors.white),
                          tooltip: l10n.instantChat,
                        ),
                      )
                    : FloatingActionButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ChatPage()),
                          );
                          // 返回后刷新未读数量
                          unreadProvider.refresh();
                        },
                        backgroundColor: Colors.blue[700],
                        child: const Icon(Icons.chat, color: Colors.white),
                        tooltip: l10n.instantChat,
                      );
              },
            )
          : null,
    );
  }

  /// 店铺用户是否因超时未支付而不能打开商家页面。
  ///
  /// [context] 用于读取登录角色和订单统计。
  /// 返回 true 时，我的店铺、店铺商品、店铺订单都改为联系客服页。
  bool _isShopConsoleLocked(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    return authProvider.isShop && appProvider.shopPaymentOverdue;
  }

  /// 判断菜单是否属于商家页面。
  ///
  /// [menu] 账号页当前菜单键。
  /// 返回 true 表示我的店铺、店铺商品或店铺订单。
  bool _isMerchantMenu(String? menu) {
    return menu == 'my_shop' ||
        menu == 'shop_products' ||
        menu == 'shop_orders';
  }

  /// 构建右侧内容视图
  Widget _buildContentView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final uri = router.routerDelegate.currentConfiguration.uri;
    final statusParam = uri.queryParameters['status'];

    if (_isShopConsoleLocked(context) && _isMerchantMenu(_selectedMenu)) {
      return const ShopPaymentLockView();
    }

    switch (_selectedMenu) {
      case 'account':
        return const AccountInfoView();
      case 'orders':
        return MyOrdersView(initialStatus: _orderStatus ?? statusParam);
      case 'records':
        return const AccountRecordsView();
      case 'address':
        return const AddressManagementView();
      case 'my_follows':
        return const MyFollowsView();
      case 'announcement':
        return const SystemAnnouncementView();
      case 'apply_shop':
        return const ApplyShopView();
      case 'my_shop':
        return const MyShopView();
      case 'shop_applications':
        return const ShopApplicationsManagementView();
      case 'shop_products':
        return const ShopProductsView();
      case 'shop_orders':
        return ShopOrdersView(initialStatus: _orderStatus ?? statusParam);
      case 'virtual_data':
        final authProvider = context.watch<AuthProvider>();
        if (authProvider.isAdmin && !authProvider.isService) {
          return const VirtualDataView();
        }
        return Center(child: Text(l10n.unknownPage));
      case 'app_update':
        return const AppUpdateView();
      case 'proxy_order':
        return const ProxyOrderView();
      case 'permission_management':
        return const PermissionManagementView();
      case 'shop_management':
        return const ShopManagementView();
      case 'product_management':
        return const ProductManagementView();
      case 'carousel_products':
        return const CarouselProductsView();
      case 'system_config':
        return const SystemConfigView();
      case 'download_app':
        return const DownloadAppView();
      default:
        return Center(child: Text(l10n.unknownPage));
    }
  }

  /// 构建移动端菜单列表
  Widget _buildMobileMenuList() {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final isAdmin = authProvider.isAdmin || authProvider.isService;
    final isShop = authProvider.isShop;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 用户头部
        _buildUserHeader(),
        const Divider(height: 1),
        // 菜单列表
        _buildMobileMenuItem(
          icon: Icons.account_circle_outlined,
          title: l10n.accountInfo,
          menuKey: 'account',
        ),
        if (!isShop)
          _buildMobileMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: l10n.myOrders,
            menuKey: 'orders',
            badgeCount: appProvider.pendingOrderCount,
          ),
        _buildMobileMenuItem(
          icon: Icons.history_outlined,
          title: l10n.accountRecords,
          menuKey: 'records',
          badgeCount: appProvider.pendingRecordCount,
        ),
        if (!isShop)
          _buildMobileMenuItem(
            icon: Icons.location_on_outlined,
            title: l10n.addressManagement,
            menuKey: 'address',
          ),
        if (!isShop)
          _buildMobileMenuItem(
            icon: Icons.favorite_outlined,
            title: l10n.myFollows,
            menuKey: 'my_follows',
          ),
        if (!isShop)
          _buildMobileMenuItem(
            icon: Icons.download_outlined,
            title: l10n.downloadApp,
            menuKey: 'download_app',
          ),
        // 仅管理员/客服可见
        if (isAdmin)
          _buildMobileMenuItem(
            icon: Icons.notifications_outlined,
            title: l10n.systemAnnouncement,
            menuKey: 'announcement',
          ),
        // 仅普通用户可见（非管理员且非店铺用户）
        if (!isAdmin && !isShop)
          _buildMobileMenuItem(
            icon: Icons.store_outlined,
            title: l10n.applyShop,
            menuKey: 'apply_shop',
          ),
        // 仅店铺用户可见
        if (isShop)
          _buildMobileMenuItem(
            icon: Icons.storefront_outlined,
            title: l10n.myShop,
            menuKey: 'my_shop',
          ),
        // 仅管理员/客服可见
        if (isAdmin)
          _buildMobileMenuItem(
            icon: Icons.assignment_outlined,
            title: l10n.shopApplications,
            menuKey: 'shop_applications',
            badgeCount: appProvider.pendingShopApplicationCount,
          ),
        // 仅店铺用户可见
        if (isShop) ...[
          _buildMobileMenuItem(
            icon: Icons.inventory_outlined,
            title: l10n.shopProducts,
            menuKey: 'shop_products',
          ),
        ],
        // 店铺用户、管理员、客服可见
        if (isShop || isAdmin) ...[
          _buildMobileMenuItem(
            icon: Icons.receipt_long_outlined,
            title: l10n.shopOrders,
            menuKey: 'shop_orders',
            badgeCount: appProvider.pendingShopOrderCount,
          ),
        ],
        if (authProvider.isAdmin && !authProvider.isService)
          _buildMobileMenuItem(
            icon: Icons.dataset_outlined,
            title: '虚拟数据',
            menuKey: 'virtual_data',
          ),
        // 仅管理员/客服可见
        if (isAdmin) ...[
          _buildMobileMenuItem(
            icon: Icons.system_update_outlined,
            title: l10n.appUpdate,
            menuKey: 'app_update',
          ),
          _buildMobileMenuItem(
            icon: Icons.shopping_cart_outlined,
            title: l10n.proxyOrder,
            menuKey: 'proxy_order',
          ),
          _buildMobileMenuItem(
            icon: Icons.admin_panel_settings_outlined,
            title: l10n.userManagement,
            menuKey: 'permission_management',
          ),
          _buildMobileMenuItem(
            icon: Icons.store_mall_directory_outlined,
            title: l10n.shopManagement,
            menuKey: 'shop_management',
          ),
          _buildMobileMenuItem(
            icon: Icons.category_outlined,
            title: l10n.productManagement,
            menuKey: 'product_management',
          ),
          _buildMobileMenuItem(
            icon: Icons.view_carousel_outlined,
            title: l10n.translate('carousel_products'),
            menuKey: 'carousel_products',
          ),
          _buildMobileMenuItem(
            icon: Icons.settings_outlined,
            title: l10n.translate('system_config'),
            menuKey: 'system_config',
          ),
        ],
      ],
    );
  }

  /// 构建用户头部
  Widget _buildUserHeader() {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final isShop = authProvider.isShop;
    final isAdmin = authProvider.isAdmin;
    final isService = authProvider.isService;

    final userInfo = authProvider.userInfo;
    final avatarUrl = userInfo?.avatar ?? '';
    final nickname = userInfo?.nickname ?? l10n.userNickname;
    final balance = userInfo?.balance ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[300],
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(ImageUtil.getImageUrl(avatarUrl))
                : null,
            child: avatarUrl.isEmpty
                ? Icon(Icons.person, size: 40, color: Colors.grey[700])
                : null,
          ),
          const SizedBox(height: 12),
          Text(nickname,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          _buildMobileStatistics(l10n, balance, isShop),
          if (!isShop) ...[
            const SizedBox(height: 12),
            _buildMobileOrderCounts(l10n, appProvider),
          ],
          // 店铺订单统计（店铺用户、管理员、客服可见）
          if (isShop || isAdmin || isService) ...[
            const SizedBox(height: 12),
            _buildMobileShopOrderCounts(l10n, appProvider),
          ],
        ],
      ),
    );
  }

  /// 构建移动端统计数据
  Widget _buildMobileStatistics(
      AppLocalizations l10n, double balance, bool isShop) {
    final appProvider = context.watch<AppProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: isShop
                ? _buildStatColumnContent(l10n.translate('my_follows'),
                    '${appProvider.myFollowCount}')
                : GestureDetector(
                    onTap: () {
                      context.go('/account?menu=my_follows');
                    },
                    child: _buildStatColumnContent(l10n.translate('my_follows'),
                        '${appProvider.myFollowCount}'),
                  ),
          ),
          if (isShop)
            Expanded(
              child: _buildStatColumnContent(l10n.translate('shop_follows'),
                  '${appProvider.shopFollowCount}'),
            ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.go('/account?menu=account');
              },
              child: _buildStatColumnContent(l10n.translate('account_balance'),
                  '\$ ${balance.toStringAsFixed(2)}'),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建移动端订单数量
  Widget _buildMobileOrderCounts(
      AppLocalizations l10n, AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.orange[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 标题
          Text(
            l10n.myOrders,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.go('/account?menu=orders&status=pending_shipment');
                  },
                  child: _buildOrderStatColumn(
                      Icons.local_shipping_outlined,
                      l10n.translate('pending_shipment'),
                      appProvider.pendingShipmentCount),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.go('/account?menu=orders&status=pending_receipt');
                  },
                  child: _buildOrderStatColumn(
                      Icons.inventory_2_outlined,
                      l10n.translate('pending_receipt'),
                      appProvider.pendingReceiptCount),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.go('/account?menu=orders&status=completed');
                  },
                  child: _buildOrderStatColumn(
                      Icons.check_circle_outline,
                      l10n.translate('completed_orders'),
                      appProvider.completedOrderCount),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.go('/account?menu=orders&status=cancelled');
                  },
                  child: _buildOrderStatColumn(
                      Icons.cancel_outlined,
                      l10n.translate('cancelled_orders'),
                      appProvider.cancelledOrderCount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建移动端店铺订单统计
  Widget _buildMobileShopOrderCounts(
      AppLocalizations l10n, AppProvider appProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 标题
          Text(
            l10n.shopOrders,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.go(
                        '/account?menu=shop_orders&status=pending_shipment');
                  },
                  child: _buildOrderStatColumn(
                      Icons.local_shipping_outlined,
                      l10n.translate('pending_shipment'),
                      appProvider.shopPendingShipmentCount),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context
                        .go('/account?menu=shop_orders&status=pending_receipt');
                  },
                  child: _buildOrderStatColumn(
                      Icons.inventory_2_outlined,
                      l10n.translate('pending_receipt'),
                      appProvider.shopPendingReceiptCount),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.go('/account?menu=shop_orders&status=completed');
                  },
                  child: _buildOrderStatColumn(
                      Icons.check_circle_outline,
                      l10n.translate('completed_orders'),
                      appProvider.shopCompletedOrderCount),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.go('/account?menu=shop_orders&status=cancelled');
                  },
                  child: _buildOrderStatColumn(
                      Icons.cancel_outlined,
                      l10n.translate('cancelled_orders'),
                      appProvider.shopCancelledOrderCount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建订单统计列（带图标和角标）
  Widget _buildOrderStatColumn(IconData icon, String label, int count) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 28, color: Colors.grey[700]),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 构建统计列内容
  Widget _buildStatColumnContent(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 构建统计列
  Widget _buildStatColumn(String label, String value) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计列（不可点击）
  Widget _buildStatColumnNoClick(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  /// 构建移动端菜单项
  Widget _buildMobileMenuItem({
    required IconData icon,
    required String title,
    required String menuKey,
    int? badgeCount,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badgeCount != null && badgeCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828),
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              alignment: Alignment.center,
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // 移动端：使用路由导航而不是内部状态
        context.go('/account?menu=$menuKey');
      },
    );
  }

  /// 构建带返回按钮的内容视图（移动端）
  Widget _buildContentViewWithBack(BuildContext context) {
    return _buildContentView(context);
  }

  /// 获取菜单标题
  String _getMenuTitle(BuildContext context, String menuKey) {
    final l10n = AppLocalizations.of(context);
    if (_isShopConsoleLocked(context) && _isMerchantMenu(menuKey)) {
      return l10n.contactCustomerService;
    }
    switch (menuKey) {
      case 'account':
        return l10n.accountInfo;
      case 'orders':
        return l10n.myOrders;
      case 'records':
        return l10n.accountRecords;
      case 'address':
        return l10n.addressManagement;
      case 'my_follows':
        return l10n.myFollows;
      case 'announcement':
        return l10n.systemAnnouncement;
      case 'apply_shop':
        return l10n.applyShop;
      case 'my_shop':
        return l10n.myShop;
      case 'shop_applications':
        return l10n.shopApplications;
      case 'shop_products':
        return l10n.shopProducts;
      case 'shop_orders':
        return l10n.shopOrders;
      case 'virtual_data':
        return '虚拟数据';
      case 'app_update':
        return l10n.appUpdate;
      case 'proxy_order':
        return l10n.proxyOrder;
      case 'permission_management':
        return l10n.userManagement;
      case 'shop_management':
        return l10n.shopManagement;
      case 'product_management':
        return l10n.productManagement;
      case 'carousel_products':
        return l10n.translate('carousel_products');
      case 'system_config':
        return l10n.translate('system_config');
      case 'download_app':
        return l10n.downloadApp;
      default:
        return '';
    }
  }
}
