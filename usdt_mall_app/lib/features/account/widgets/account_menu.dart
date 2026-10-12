import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/image_util.dart';

/// 账号页面左侧菜单
class AccountMenu extends StatelessWidget {
  final String selectedMenu;
  final Function(String, {String? orderStatus}) onMenuSelected;

  const AccountMenu({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final isAdmin = authProvider.isAdmin || authProvider.isService;
    final isShop = authProvider.isShop;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 头像和昵称
          _buildUserHeader(context),
          const Divider(height: 1),
          // 菜单列表
          _buildMenuItem(
            context: context,
            icon: Icons.account_circle_outlined,
            title: l10n.accountInfo,
            menuKey: 'account',
          ),
          if (!isShop)
            _buildMenuItem(
              context: context,
              icon: Icons.shopping_bag_outlined,
              title: l10n.myOrders,
              menuKey: 'orders',
              badgeCount: appProvider.pendingOrderCount,
            ),
          _buildMenuItem(
            context: context,
            icon: Icons.history_outlined,
            title: l10n.accountRecords,
            menuKey: 'records',
            badgeCount: appProvider.pendingRecordCount,
          ),
          if (!isShop)
            _buildMenuItem(
              context: context,
              icon: Icons.location_on_outlined,
              title: l10n.addressManagement,
              menuKey: 'address',
            ),
          if (!isShop)
            _buildMenuItem(
              context: context,
              icon: Icons.favorite_outlined,
              title: l10n.myFollows,
              menuKey: 'my_follows',
            ),
          // 仅管理员/客服可见
          if (isAdmin)
            _buildMenuItem(
              context: context,
              icon: Icons.notifications_outlined,
              title: l10n.systemAnnouncement,
              menuKey: 'announcement',
            ),
          // 仅普通用户可见（非管理员且非店铺用户）
          if (!isAdmin && !isShop)
            _buildMenuItem(
              context: context,
              icon: Icons.store_outlined,
              title: l10n.applyShop,
              menuKey: 'apply_shop',
            ),
          // 仅店铺用户可见
          if (isShop)
            _buildMenuItem(
              context: context,
              icon: Icons.storefront_outlined,
              title: l10n.myShop,
              menuKey: 'my_shop',
            ),
          // 仅管理员/客服可见
          if (isAdmin)
            _buildMenuItem(
              context: context,
              icon: Icons.assignment_outlined,
              title: l10n.shopApplications,
              menuKey: 'shop_applications',
              badgeCount: appProvider.pendingShopApplicationCount,
            ),
          // 仅店铺用户可见
          if (isShop) ...[
            _buildMenuItem(
              context: context,
              icon: Icons.inventory_outlined,
              title: l10n.shopProducts,
              menuKey: 'shop_products',
            ),
          ],
          // 店铺用户、管理员、客服可见
          if (isShop || isAdmin) ...[
            _buildMenuItem(
              context: context,
              icon: Icons.receipt_long_outlined,
              title: l10n.shopOrders,
              menuKey: 'shop_orders',
              badgeCount: appProvider.pendingShopOrderCount,
            ),
          ],
          if (authProvider.isAdmin && !authProvider.isService)
            _buildMenuItem(
              context: context,
              icon: Icons.dataset_outlined,
              title: '虚拟数据',
              menuKey: 'virtual_data',
            ),
          // 仅管理员/客服可见
          if (isAdmin) ...[
            _buildMenuItem(
              context: context,
              icon: Icons.system_update_outlined,
              title: l10n.appUpdate,
              menuKey: 'app_update',
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.shopping_cart_outlined,
              title: l10n.proxyOrder,
              menuKey: 'proxy_order',
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.admin_panel_settings_outlined,
              title: l10n.userManagement,
              menuKey: 'permission_management',
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.store_mall_directory_outlined,
              title: l10n.shopManagement,
              menuKey: 'shop_management',
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.category_outlined,
              title: l10n.productManagement,
              menuKey: 'product_management',
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.view_carousel_outlined,
              title: l10n.translate('carousel_products'),
              menuKey: 'carousel_products',
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.settings_outlined,
              title: l10n.translate('system_config'),
              menuKey: 'system_config',
            ),
          ],
        ],
      ),
    );
  }

  /// 构建用户头部
  Widget _buildUserHeader(BuildContext context) {
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
          // 头像
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
          // 昵称
          Text(
            nickname,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // 统计数据
          _buildStatistics(context, balance, isShop),
          if (!isShop) ...[
            const SizedBox(height: 12),
            _buildOrderCounts(context, appProvider),
          ],
          // 店铺订单数量（店铺用户、管理员、客服可见）
          if (isShop || isAdmin || isService) ...[
            const SizedBox(height: 12),
            _buildShopOrderCounts(context, appProvider),
          ],
        ],
      ),
    );
  }

  /// 构建统计数据
  Widget _buildStatistics(BuildContext context, double balance, bool isShop) {
    final l10n = AppLocalizations.of(context);
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
      child: Column(
        children: [
          Row(
            children: [
              if (isShop)
                _buildStatColumnNoClick(l10n.translate('my_follows'),
                    '${appProvider.myFollowCount}')
              else
                _buildStatColumnClickable(
                  label: l10n.translate('my_follows'),
                  value: '${appProvider.myFollowCount}',
                  onTap: () => onMenuSelected('my_follows'),
                ),
              if (isShop)
                _buildStatColumnNoClick(l10n.translate('shop_follows'),
                    '${appProvider.shopFollowCount}'),
              if (!isShop)
                _buildStatColumnClickable(
                  label: l10n.translate('account_balance'),
                  value: '\$ ${balance.toStringAsFixed(2)}',
                  onTap: () => onMenuSelected('account'),
                ),
            ],
          ),
          if (isShop) const SizedBox(height: 12),
          if (isShop)
            Row(
              children: [
                _buildStatColumnClickable(
                  label: l10n.translate('account_balance'),
                  value: '\$ ${balance.toStringAsFixed(2)}',
                  onTap: () => onMenuSelected('account'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建可点击的统计列
  Widget _buildStatColumnClickable({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            children: [
              Text(
                value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

  /// 构建订单统计列（带图标和角标）
  Widget _buildOrderStatColumn({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
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
          ),
        ),
      ),
    );
  }

  /// 构建订单数量
  Widget _buildOrderCounts(BuildContext context, AppProvider appProvider) {
    final l10n = AppLocalizations.of(context);
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
              _buildOrderStatColumn(
                icon: Icons.local_shipping_outlined,
                label: l10n.translate('pending_shipment'),
                count: appProvider.pendingShipmentCount,
                onTap: () =>
                    onMenuSelected('orders', orderStatus: 'pending_shipment'),
              ),
              _buildOrderStatColumn(
                icon: Icons.inventory_2_outlined,
                label: l10n.translate('pending_receipt'),
                count: appProvider.pendingReceiptCount,
                onTap: () =>
                    onMenuSelected('orders', orderStatus: 'pending_receipt'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildOrderStatColumn(
                icon: Icons.check_circle_outline,
                label: l10n.translate('completed_orders'),
                count: appProvider.completedOrderCount,
                onTap: () => onMenuSelected('orders', orderStatus: 'completed'),
              ),
              _buildOrderStatColumn(
                icon: Icons.cancel_outlined,
                label: l10n.translate('cancelled_orders'),
                count: appProvider.cancelledOrderCount,
                onTap: () => onMenuSelected('orders', orderStatus: 'cancelled'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建店铺订单数量
  Widget _buildShopOrderCounts(BuildContext context, AppProvider appProvider) {
    final l10n = AppLocalizations.of(context);
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
              _buildOrderStatColumn(
                icon: Icons.local_shipping_outlined,
                label: l10n.translate('pending_shipment'),
                count: appProvider.shopPendingShipmentCount,
                onTap: () => onMenuSelected('shop_orders',
                    orderStatus: 'pending_shipment'),
              ),
              _buildOrderStatColumn(
                icon: Icons.inventory_2_outlined,
                label: l10n.translate('pending_receipt'),
                count: appProvider.shopPendingReceiptCount,
                onTap: () => onMenuSelected('shop_orders',
                    orderStatus: 'pending_receipt'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildOrderStatColumn(
                icon: Icons.check_circle_outline,
                label: l10n.translate('completed_orders'),
                count: appProvider.shopCompletedOrderCount,
                onTap: () =>
                    onMenuSelected('shop_orders', orderStatus: 'completed'),
              ),
              _buildOrderStatColumn(
                icon: Icons.cancel_outlined,
                label: l10n.translate('cancelled_orders'),
                count: appProvider.shopCancelledOrderCount,
                onTap: () =>
                    onMenuSelected('shop_orders', orderStatus: 'cancelled'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String menuKey,
    int? badgeCount,
  }) {
    final isSelected = selectedMenu == menuKey;

    return InkWell(
      onTap: () => onMenuSelected(menuKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? Colors.blue[700]! : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.blue[700] : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.blue[700] : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.visible,
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
      ),
    );
  }
}
