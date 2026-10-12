import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/api/file_api.dart';
import '../../../core/api/shop_management_api.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/user_info_service.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/date_util.dart';

/// 店铺管理视图
class ShopManagementView extends StatefulWidget {
  const ShopManagementView({super.key});

  @override
  State<ShopManagementView> createState() => _ShopManagementViewState();
}

class _ShopManagementViewState extends State<ShopManagementView> {
  final _searchController = TextEditingController();
  int _currentPage = 1; // 当前页码
  int _totalPages = 1; // 总页数
  int _itemsPerPage = 10; // 每页显示数量
  final List<int> _pageSizeOptions = [10, 20, 30, 50]; // 分页大小选项
  final TextEditingController _pageInputController = TextEditingController();

  // 店铺数据列表
  List<Map<String, dynamic>> _shops = [];
  bool _isLoading = false;
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  /// 加载店铺数据
  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ShopManagementApi.getShopList(
        keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        page: _currentPage,
        pageSize: _itemsPerPage,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        setState(() {
          _shops = List<Map<String, dynamic>>.from(data['list'] ?? []);
          _totalRecords = data['total'] ?? 0;
          _totalPages = data['totalPages'] ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.loadFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.loadFailed}: $e')),
        );
      }
    }
  }

  /// 店铺是否因超时未支付而关闭了商家页面。
  ///
  /// [shop] 店铺列表中的一项。
  /// 返回 true 时管理员可以解封。
  bool _isPaymentOverdue(Map<String, dynamic> shop) {
    final value = shop['paymentOverdue'];
    return value == true || value == 1;
  }

  /// 管理员确认后解除该店铺的支付超时限制。
  ///
  /// [shop] 要解封的店铺，使用其中的 id 和 shopName。
  /// 无返回值。
  Future<void> _handleUnlockPaymentLock(Map<String, dynamic> shop) async {
    final l10n = AppLocalizations.of(context);
    final shopId = shop['id'];
    if (shopId is! num) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unlockPaymentLock),
        content: Text(
          '${shop['shopName'] ?? ''}\n${l10n.unlockPaymentLockConfirm}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      final response = await ShopManagementApi.unlockPaymentLock(shopId.toInt());
      if (!mounted) {
        return;
      }
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.unlockPaymentLockSuccess)),
        );
        _loadShops();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.operationFailed}: ${response.errorMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.operationFailed}: $e')),
        );
      }
    }
  }

  /// 处理搜索
  void _handleSearch() {
    setState(() {
      _currentPage = 1;
    });
    _loadShops();
  }

  /// 将类别值转换为国际化文本
  String _getCategoryText(String category, AppLocalizations l10n) {
    switch (category) {
      case '全部':
        return l10n.all;
      case '生活':
        return l10n.life;
      case '男鞋':
        return l10n.menShoes;
      case '女鞋':
        return l10n.womenShoes;
      case '配饰':
        return l10n.accessories;
      case '男装':
        return l10n.menClothing;
      case '女装':
        return l10n.womenClothing;
      case '男包':
        return l10n.menBags;
      case '女包':
        return l10n.womenBags;
      case '男童':
        return l10n.boyClothing;
      case '女童':
        return l10n.girlClothing;
      case '全球购':
        return l10n.globalShopping;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            _buildHeader(),
            const SizedBox(height: 24),
          ],
          _buildSearchBar(),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildShopTable()),
                if (!_isLoading && _shops.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPagination(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.shopManagement,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchShopContact,
              hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
              prefixIcon: Icon(Icons.search, size: isMobile ? 20 : 24),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: isMobile ? 20 : 24),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 10 : 12,
              ),
            ),
            style: TextStyle(fontSize: isMobile ? 13 : 14),
            onChanged: (value) => setState(() {}),
            onSubmitted: (value) => _handleSearch(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _handleSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 14 : 16,
            ),
          ),
          child: Text(l10n.search, style: TextStyle(fontSize: isMobile ? 13 : 14)),
        ),
      ],
    );
  }

  /// 构建店铺表格
  Widget _buildShopTable() {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 32 : 40),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shops.isEmpty) {
      return _buildEmptyState();
    }

    if (isMobile) {
      // 移动端：卡片列表
      return ListView.builder(
        itemCount: _shops.length,
        itemBuilder: (context, index) => _buildShopCard(_shops[index]),
      );
    }

    // 桌面端：表格
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _shops.length,
              itemBuilder: (context, index) => _buildTableRow(_shops[index]),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取筛选后的店铺
  List<Map<String, dynamic>> _getFilteredShops() {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) return _shops;

    return _shops.where((shop) {
      return (shop['shopName'] ?? '').toLowerCase().contains(searchText) ||
          (shop['ownerNickname'] ?? '').toLowerCase().contains(searchText);
    }).toList();
  }

  /// 构建表格头部
  Widget _buildTableHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _buildHeaderCell(l10n.shopName, flex: 2),
          _buildHeaderCell(l10n.contact, flex: 2),
          _buildHeaderCell(l10n.productManagement, flex: 1),
          _buildHeaderCell(l10n.status, flex: 1),
          const SizedBox(width: 16),
          _buildHeaderCell(l10n.createTime, flex: 2),
          _buildHeaderCell(l10n.actions),
        ],
      ),
    );
  }

  /// 构建表头单元格
  Widget _buildHeaderCell(String text, {int flex = 3}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.store_outlined, size: isMobile ? 40 : 48, color: Colors.grey[400]),
            SizedBox(height: isMobile ? 10 : 12),
            Text(
              l10n.noApplications,
              style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建店铺卡片（移动端）
  Widget _buildShopCard(Map<String, dynamic> shop) {
    final l10n = AppLocalizations.of(context);
    final isActive = shop['status'] == 'active';
    final overdue = _isPaymentOverdue(shop);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 店铺名称和状态
          Row(
            children: [
              Expanded(
                child: Text(
                  shop['shopName'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: overdue
                      ? Colors.orange[800]
                      : (isActive ? Colors.green[600] : Colors.grey[600]),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _shopStatusText(shop, l10n),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 联系人和商品数
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.contact}: ${shop['ownerNickname'] ?? ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              Text(
                '${l10n.productManagement}: ${shop['productCount'] ?? 0}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 创建时间
          Text(
            '${l10n.createTime}: ${DateUtil.formatDateTime(DateUtil.parseAsLocalDateTime(shop['createTime']))}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showShopDetails(shop),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    side: BorderSide(color: Colors.blue[600]!),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(l10n.viewDetail, style: const TextStyle(fontSize: 13)),
                ),
              ),
              if (context.watch<AuthProvider>().isAdmin && _isPaymentOverdue(shop)) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleUnlockPaymentLock(shop),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(l10n.unlockPaymentLock, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 构建表格行
  Widget _buildTableRow(Map<String, dynamic> shop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          _buildCell(shop['shopName'] ?? '', flex: 2),
          _buildCell(shop['ownerNickname'] ?? '', flex: 2),
          _buildCell(shop['productCount']?.toString() ?? '0', flex: 1),
          _buildStatusCell(shop, flex: 1),
          const SizedBox(width: 16),
          _buildCell(DateUtil.formatDateTime(DateUtil.parseAsLocalDateTime(shop['createTime'])), flex: 2),
          _buildActionCell(shop),
        ],
      ),
    );
  }

  /// 构建单元格
  Widget _buildCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  /// 店铺列表状态文案。超时未支付时显示已限制，否则按营业状态显示。
  ///
  /// [shop] 店铺列表中的一项。
  /// [l10n] 当前语言文案。
  /// 返回状态文字。
  String _shopStatusText(Map<String, dynamic> shop, AppLocalizations l10n) {
    if (_isPaymentOverdue(shop)) {
      return l10n.paymentLockedStatus;
    }
    return shop['status'] == 'active' ? l10n.shopOpen : l10n.shopClosed;
  }

  /// 构建状态单元格。超时未支付时用橙色「已限制」，营业中为绿色，已关闭为灰色。
  ///
  /// [shop] 店铺列表中的一项。
  /// [flex] 在表格行中占据的宽度比例。
  /// 返回状态标签。
  Widget _buildStatusCell(Map<String, dynamic> shop, {int flex = 1}) {
    final l10n = AppLocalizations.of(context);
    final overdue = _isPaymentOverdue(shop);
    final isActive = shop['status'] == 'active';
    final Color color = overdue
        ? Colors.orange[800]!
        : (isActive ? Colors.green[600]! : Colors.grey[600]!);
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _shopStatusText(shop, l10n),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// 构建操作单元格
  Widget _buildActionCell(Map<String, dynamic> shop) {
    final l10n = AppLocalizations.of(context);
    final canUnlock = context.watch<AuthProvider>().isAdmin && _isPaymentOverdue(shop);
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          TextButton(
            onPressed: () => _showShopDetails(shop),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.viewDetail, style: const TextStyle(fontSize: 13)),
          ),
          if (canUnlock)
            TextButton(
              onPressed: () => _handleUnlockPaymentLock(shop),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[800],
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.unlockPaymentLock, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }

  /// 显示店铺详情
  void _showShopDetails(Map<String, dynamic> shop) async {
    final l10n = AppLocalizations.of(context);
    final userInfo = await UserInfoService.getUserInfo();
    final isAdmin = userInfo?.role == UserRole.admin;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.shopInfo),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditShopDialog(shop);
                },
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基本信息
                Text(l10n.translate('basic_info'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.shopName, shop['shopName'] ?? ''),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.mainBusiness, _getCategoryText(shop['category'] ?? '', l10n)),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.status, _shopStatusText(shop, l10n)),

                const Divider(height: 32),

                // 联系信息
                Text(l10n.translate('contact_info'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.contact, shop['contactName'] ?? ''),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.contactPhone, shop['contactPhone'] ?? ''),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.inviteCode, shop['inviteCode'] ?? ''),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.detailedAddress, shop['address'] ?? ''),

                const Divider(height: 32),

                // 经营数据
                Text(l10n.translate('business_data'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.translate('product_count'), '${shop['productCount'] ?? 0}'),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.translate('order_count'), '${shop['orderCount'] ?? 0}'),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.translate('sales_amount'), '${shop['salesAmount'] ?? 0.0}'),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.translate('follow_count'), '${shop['followCount'] ?? 0}'),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.translate('view_count'), '${shop['views'] ?? 0}'),

                const Divider(height: 32),

                // 店铺评级
                Text(l10n.translate('shop_rating'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.translate('shop_level'), '${shop['level'] ?? 0}'),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.translate('shop_score'), '${shop['rating'] ?? 0.0}'),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.translate('credit_score'), '${shop['creditScore'] ?? 0}'),

                const Divider(height: 32),

                // 其他信息
                Text(l10n.translate('other_info'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow(l10n.createTime, DateUtil.formatDateTime(DateUtil.parseAsLocalDateTime(shop['createTime']))),
                if (shop['logo'] != null && shop['logo'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l10n.shopLogo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Image.network(
                    ImageUtil.getImageUrl(shop['logo']),
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _showEditShopDialog(Map<String, dynamic> shop) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: shop['shopName']);
    final contactNameController = TextEditingController(text: shop['contactName']);
    final contactPhoneController = TextEditingController(text: shop['contactPhone']);
    final addressController = TextEditingController(text: shop['address']);
    final orderCountController = TextEditingController(text: '${shop['orderCount'] ?? 0}');
    final salesAmountController = TextEditingController(text: '${shop['salesAmount'] ?? 0.0}');
    final followCountController = TextEditingController(text: '${shop['followCount'] ?? 0}');
    final viewsController = TextEditingController(text: '${shop['views'] ?? 0}');
    final levelController = TextEditingController(text: '${shop['level'] ?? 0}');
    final ratingController = TextEditingController(text: '${shop['rating'] ?? 0.0}');
    final creditScoreController = TextEditingController(text: '${shop['creditScore'] ?? 0}');

    String? selectedCategory = shop['category'];
    String? uploadedLogoPath = shop['logo'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.edit),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: l10n.shopName),
                  ),
                  const SizedBox(height: 16),
                  // Logo上传
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.shopLogo, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      if (uploadedLogoPath != null && uploadedLogoPath!.isNotEmpty)
                        Image.network(
                          ImageUtil.getImageUrl(uploadedLogoPath!),
                          height: 100,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            final response = await FileApi.uploadFile(
                              filePath: pickedFile.path,
                              fileName: pickedFile.name,
                              fileBytes: bytes,
                            );
                            if (response.isSuccess && response.data != null) {
                              setState(() => uploadedLogoPath = response.data!);
                            }
                          }
                        },
                        icon: const Icon(Icons.upload),
                        label: Text(l10n.selectImage),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contactNameController,
                    decoration: InputDecoration(labelText: l10n.contact),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contactPhoneController,
                    decoration: InputDecoration(labelText: l10n.contactPhone),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(labelText: l10n.mainBusiness),
                    items: [
                      DropdownMenuItem(value: '全部', child: Text(l10n.all)),
                      DropdownMenuItem(value: '生活', child: Text(l10n.life)),
                      DropdownMenuItem(value: '男鞋', child: Text(l10n.menShoes)),
                      DropdownMenuItem(value: '女鞋', child: Text(l10n.womenShoes)),
                      DropdownMenuItem(value: '配饰', child: Text(l10n.accessories)),
                      DropdownMenuItem(value: '男装', child: Text(l10n.menClothing)),
                      DropdownMenuItem(value: '女装', child: Text(l10n.womenClothing)),
                      DropdownMenuItem(value: '男包', child: Text(l10n.menBags)),
                      DropdownMenuItem(value: '女包', child: Text(l10n.womenBags)),
                      DropdownMenuItem(value: '男童', child: Text(l10n.boyClothing)),
                      DropdownMenuItem(value: '女童', child: Text(l10n.girlClothing)),
                      DropdownMenuItem(value: '全球购', child: Text(l10n.globalShopping)),
                    ],
                    onChanged: (value) => setState(() => selectedCategory = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: l10n.detailedAddress),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: orderCountController,
                    decoration: InputDecoration(labelText: l10n.translate('order_count')),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: salesAmountController,
                    decoration: InputDecoration(labelText: l10n.translate('sales_amount')),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: followCountController,
                    decoration: InputDecoration(labelText: l10n.translate('follow_count')),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: viewsController,
                    decoration: InputDecoration(labelText: l10n.translate('view_count')),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: levelController,
                    decoration: InputDecoration(labelText: l10n.translate('shop_level')),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ratingController,
                    decoration: InputDecoration(labelText: l10n.translate('shop_score')),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: creditScoreController,
                    decoration: InputDecoration(labelText: l10n.translate('credit_score')),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final response = await ShopManagementApi.updateShop(
                  shopId: shop['id'],
                  data: {
                    'shopName': nameController.text,
                    'logo': uploadedLogoPath,
                    'contactName': contactNameController.text,
                    'contactPhone': contactPhoneController.text,
                    'category': selectedCategory,
                    'address': addressController.text,
                    'orderCount': int.tryParse(orderCountController.text),
                    'salesAmount': double.tryParse(salesAmountController.text),
                    'followCount': int.tryParse(followCountController.text),
                    'views': int.tryParse(viewsController.text),
                    'level': int.tryParse(levelController.text),
                    'rating': double.tryParse(ratingController.text),
                    'creditScore': int.tryParse(creditScoreController.text),
                  },
                );
                if (mounted) {
                  Navigator.pop(context);
                  if (response.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.saveSuccess)),
                    );
                    _loadShops();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response.errorMessage)),
                    );
                  }
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理切换店铺状态
  void _handleToggleShopStatus(Map<String, dynamic> shop) {
    final l10n = AppLocalizations.of(context);
    final isActive = shop['status'] == 'active';
    final action = isActive ? l10n.close : l10n.shopOpen;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.confirm}$action'),
        content: Text('${l10n.confirm}${action}${l10n.shopName} "${shop['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final newStatus = isActive ? 'inactive' : 'active';
                final response = await ShopManagementApi.updateShopStatus(
                  shopId: shop['id'].toString(),
                  status: newStatus,
                );

                if (mounted) {
                  final l10n = AppLocalizations.of(context);
                  if (response.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.shopName}${action}')),
                    );
                    _loadShops();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.operationFailed}: ${response.errorMessage}')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  final l10n = AppLocalizations.of(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.operationFailed}: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.orange[700] : Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// 处理删除店铺
  void _handleDeleteShop(Map<String, dynamic> shop) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteItem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final response = await ShopManagementApi.deleteShop(
                  shop['id'].toString(),
                );

                if (mounted) {
                  final l10n = AppLocalizations.of(context);
                  if (response.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.deleteSuccess)),
                    );
                    _loadShops();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.deleteFailed}: ${response.errorMessage}')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  final l10n = AppLocalizations.of(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.deleteFailed}: $e')),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
  }

  /// 构建分页栏
  Widget _buildPagination() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      // 移动端：单行紧凑布局
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 总条数
          Text(
            '${l10n.total} $_totalRecords ${l10n.items}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          // 翻页按钮
          Row(
            children: [
              _buildPageButton(
                icon: Icons.chevron_left,
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                        _loadShops();
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              _buildPageButton(
                icon: Icons.chevron_right,
                onPressed: _currentPage < _totalPages
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                        _loadShops();
                      }
                    : null,
              ),
            ],
          ),
        ],
      );
    }

    // 桌面端：原有布局
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 分页大小选择器
        _buildPageSizeSelector(),
        const SizedBox(width: 24),

        // 上一页按钮
        _buildPageButton(
          icon: Icons.chevron_left,
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                  _loadShops();
                }
              : null,
        ),
        const SizedBox(width: 8),

        // 页码按钮
        ..._buildPageNumbers(),

        const SizedBox(width: 8),
        // 下一页按钮
        _buildPageButton(
          icon: Icons.chevron_right,
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                  _loadShops();
                }
              : null,
        ),

        const SizedBox(width: 16),
        // 页码输入区域
        _buildPageInput(),
      ],
    );
  }

  Widget _buildPageSizeSelector() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(l10n.itemsPerPage, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(width: 8),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<int>(
            value: _itemsPerPage,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            onChanged: (int? newValue) {
              if (newValue != null) {
                setState(() {
                  _itemsPerPage = newValue;
                  _currentPage = 1;
                });
                _loadShops();
              }
            },
            items: _pageSizeOptions.map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(value: value, child: Text('$value'));
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Text(l10n.items, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.grey[200] : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 20, color: onPressed == null ? Colors.grey[400] : Colors.grey[700]),
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];
    if (_totalPages < 1) return pageNumbers;

    int startPage = (_currentPage - 2).clamp(1, _totalPages);
    int endPage = (_currentPage + 2).clamp(1, _totalPages);

    if (startPage > 1) {
      pageNumbers.add(_buildPageNumberButton(1));
      if (startPage > 2) {
        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(_buildEllipsis());
      }
      pageNumbers.add(const SizedBox(width: 8));
    }

    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(_buildPageNumberButton(i));
      if (i < endPage) pageNumbers.add(const SizedBox(width: 8));
    }

    if (endPage < _totalPages) {
      pageNumbers.add(const SizedBox(width: 8));
      if (endPage < _totalPages - 1) {
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 8));
      }
      pageNumbers.add(_buildPageNumberButton(_totalPages));
    }

    return pageNumbers;
  }

  Widget _buildPageNumberButton(int pageNumber) {
    final isActive = pageNumber == _currentPage;
    return InkWell(
      onTap: () {
        setState(() {
          _currentPage = pageNumber;
        });
        _loadShops();
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[700] : Colors.white,
          border: Border.all(color: isActive ? Colors.blue[700]! : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '$pageNumber',
            style: TextStyle(
              fontSize: 14,
              color: isActive ? Colors.white : Colors.grey[800],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: Text('...', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
    );
  }

  Widget _buildPageInput() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(l10n.jumpTo, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(width: 8),
        Container(
          width: 60,
          height: 36,
          child: TextField(
            controller: _pageInputController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.blue[700]!),
              ),
            ),
            onSubmitted: (value) => _jumpToPage(),
          ),
        ),
        const SizedBox(width: 8),
        Text(l10n.page, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _jumpToPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(60, 36),
          ),
          child: Text(l10n.jump, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  void _jumpToPage() {
    final l10n = AppLocalizations.of(context);
    final inputText = _pageInputController.text.trim();
    if (inputText.isEmpty) return;

    final pageNumber = int.tryParse(inputText);
    if (pageNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterValidPage)),
      );
      return;
    }

    if (pageNumber < 1 || pageNumber > _totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pageRange(_totalPages))),
      );
      return;
    }

    setState(() {
      _currentPage = pageNumber;
    });
    _loadShops();
    _pageInputController.clear();
  }
}
