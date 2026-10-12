import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/policy_dialog.dart';
import '../../../shared/widgets/download_app_dialog.dart';
import '../../../shared/constants/policy_contents.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/widgets/auth_dialog.dart';

/// 商城左侧菜单组件
class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  int _selectedIndex = 0;
  final Set<int> _expandedItems = {}; // 记录展开的菜单项索引

  List<MenuItem> _getMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      MenuItem(iconAsset: 'assets/pic/life.png', label: l10n.life, route: '/category/life'),
      MenuItem(iconAsset: 'assets/pic/man-shoe.png', label: l10n.menShoes, route: '/category/man-shoes'),
      MenuItem(iconAsset: 'assets/pic/woman-shoe.png', label: l10n.womenShoes, route: '/category/woman-shoes'),
      MenuItem(iconAsset: 'assets/pic/peishi.png', label: l10n.accessories, route: '/category/accessories'),
      MenuItem(iconAsset: 'assets/pic/man-cloth.png', label: l10n.menClothing, route: '/category/man-clothing'),
      MenuItem(iconAsset: 'assets/pic/woman-cloth.png', label: l10n.womenClothing, route: '/category/woman-clothing'),
      MenuItem(iconAsset: 'assets/pic/man-bag.png', label: l10n.menBags, route: '/category/man-bags'),
      MenuItem(iconAsset: 'assets/pic/woman-bag.png', label: l10n.womenBags, route: '/category/woman-bags'),
      MenuItem(iconAsset: 'assets/pic/man-child.png', label: l10n.boyClothing, route: '/category/boy-clothing'),
      MenuItem(iconAsset: 'assets/pic/woman-child.png', label: l10n.girlClothing, route: '/category/girl-clothing'),
      MenuItem(iconAsset: 'assets/pic/global.png', label: l10n.globalShopping, route: '/category/global-shopping'),
      MenuItem(
        icon: Icons.info_outline,
        label: l10n.about1688,
        subItems: [
          MenuItem(icon: Icons.circle, label: l10n.aboutUs, route: '/about-us', key: 'about_us'),
          MenuItem(icon: Icons.circle, label: l10n.joinUs, route: '/join-us', key: 'join_us'),
          MenuItem(icon: Icons.circle, label: l10n.contactUs, route: '/contact-us', key: 'contact_us'),
        ],
      ),
      MenuItem(
        icon: Icons.handshake_outlined,
        label: l10n.cooperation,
        subItems: [
          MenuItem(icon: Icons.circle, label: l10n.merchantAgreement, route: '/merchant-agreement', key: 'merchant_agreement'),
          MenuItem(icon: Icons.circle, label: l10n.supplierCooperation, route: '/supplier-cooperation', key: 'supplier_cooperation'),
        ],
      ),
      MenuItem(
        icon: Icons.analytics_outlined,
        label: l10n.precisionOperation,
        subItems: [
          MenuItem(icon: Icons.circle, label: l10n.strategyManagement, route: '/strategy-management', key: 'strategy_management'),
          MenuItem(icon: Icons.circle, label: l10n.precisionOperation, route: '/precision-operation', key: 'precision_operation'),
        ],
      ),
      MenuItem(icon: Icons.help_outline, label: l10n.faq, route: '/faq', key: 'faq'),
      MenuItem(icon: Icons.download, label: l10n.downloadApp, route: '/download-app', key: 'download_app'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems(context);
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return _buildMenuItem(index, menuItems);
        },
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem(int index, List<MenuItem> menuItems) {
    final item = menuItems[index];
    final isSelected = _selectedIndex == index;
    final hasSubItems = item.subItems != null && item.subItems!.isNotEmpty;
    final isExpanded = _expandedItems.contains(index);

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (hasSubItems) {
                // 如果有子菜单，切换展开/收起状态
                if (isExpanded) {
                  _expandedItems.remove(index);
                } else {
                  _expandedItems.add(index);
                }
              } else {
                // 如果没有子菜单，选中该项并跳转
                _selectedIndex = index;
                _handleMainMenuTap(context, item);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[50] : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? Colors.blue[700]! : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                // 根据图标类型渲染不同的组件
                if (item.iconAsset != null)
                  RepaintBoundary(
                    child: Image.asset(
                      item.iconAsset!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      cacheWidth: 180, // 5倍分辨率缓存
                    ),
                  )
                else
                  Icon(
                    item.icon,
                    size: 24,
                    color: isSelected ? Colors.blue[700] : Colors.grey[700],
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.blue[700] : Colors.grey[800],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
                // 如果有子菜单，显示展开/收起图标
                if (hasSubItems)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey[600],
                  ),
              ],
            ),
          ),
        ),
        // 显示子菜单项
        if (hasSubItems && isExpanded)
          ...item.subItems!.asMap().entries.map((entry) {
            return _buildSubMenuItem(entry.value, index, entry.key);
          }).toList(),
      ],
    );
  }

  /// 处理主菜单点击
  void _handleMainMenuTap(BuildContext context, MenuItem item) {
    if (item.key == 'faq') {
      _showPolicyDialog(context, item.label, faqContentPart1 + '\n\n' + faqContentPart2);
    } else if (item.key == 'download_app') {
      showDialog(
        context: context,
        builder: (context) => const DownloadAppDialog(),
      );
    } else if (item.route != null) {
      context.go(item.route!);
    }
  }

  /// 构建子菜单项
  Widget _buildSubMenuItem(MenuItem subItem, int parentIndex, int subIndex) {
    final subItemKey = '$parentIndex-$subIndex';
    final isSelected = _selectedIndex == parentIndex && _expandedItems.contains(parentIndex);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = parentIndex;
        });
        _handleSubMenuTap(context, subItem);
      },
      child: Container(
        padding: const EdgeInsets.only(left: 48, right: 16, top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(
              subItem.icon ?? Icons.circle,
              size: 8,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subItem.label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理子菜单点击
  void _handleSubMenuTap(BuildContext context, MenuItem item) {
    switch (item.key) {
      case 'about_us':
        _showPolicyDialog(context, item.label, aboutUsContent);
        break;
      case 'merchant_agreement':
        _showPolicyDialog(context, item.label, merchantAgreementContent);
        break;
      case 'strategy_management':
        _showPolicyDialog(context, item.label, strategicManagementContent);
        break;
      case 'precision_operation':
        _showPolicyDialog(context, item.label, precisionOperationsContent);
        break;
      case 'join_us':
      case 'contact_us':
      case 'supplier_cooperation':
        // 检查是否已登录
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isAuthenticated) {
          context.go('/chat');
        } else {
          _showLoginDialog(context);
        }
        break;
      default:
        if (item.route != null) {
          context.go(item.route!);
        }
    }
  }

  /// 显示登录对话框
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AuthDialog(isLogin: true),
    );
  }

  /// 显示政策对话框
  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => PolicyDialog(
        title: title,
        content: content,
      ),
    );
  }
}

/// 菜单项数据模型
class MenuItem {
  final IconData? icon;
  final String? iconAsset;
  final String label;
  final String? route;
  final List<MenuItem>? subItems;
  final String? key; // 用于标识菜单项的唯一键

  MenuItem({
    this.icon,
    this.iconAsset,
    required this.label,
    this.route,
    this.subItems,
    this.key,
  }) : assert(icon != null || iconAsset != null || subItems != null,
             'Either icon, iconAsset, or subItems must be provided');
}
