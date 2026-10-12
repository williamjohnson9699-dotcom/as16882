import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/order_api.dart';
import '../../../core/api/shop_api.dart';
import '../../../core/api/file_api.dart';
import '../../../core/api/system_config_api.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/date_util.dart';

/// 店铺订单视图
class ShopOrdersView extends StatefulWidget {
  final String? initialStatus;

  const ShopOrdersView({super.key, this.initialStatus});

  @override
  State<ShopOrdersView> createState() => _ShopOrdersViewState();
}

class _ShopOrdersViewState extends State<ShopOrdersView> {
  String _selectedStatus = 'all';
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = false;
  int? _shopId;

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  // 分页相关
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 10;
  final List<int> _pageSizeOptions = [10, 20, 30, 50];
  final TextEditingController _pageInputController = TextEditingController();
  int _totalRecords = 0;

  // 状态统计。已完成、已取消是未读数，入口红点用 menuBadge。
  int _pendingShipmentCount = 0;
  int _pendingReceiptCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  int _menuBadge = 0;
  int _loadSerial = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      _selectedStatus = widget.initialStatus!;
    }
    _loadShopInfo();
  }

  @override
  void didUpdateWidget(ShopOrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus &&
        widget.initialStatus != null) {
      setState(() {
        _selectedStatus = widget.initialStatus!;
      });
      _loadOrders();
    }
  }

  /// 加载店铺信息
  Future<void> _loadShopInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdminOrService = authProvider.isAdmin || authProvider.isService;

    // 管理员/客服直接加载所有订单，不需要店铺ID
    if (isAdminOrService) {
      setState(() {
        _shopId = null;
      });
      _loadOrders();
      return;
    }

    // 店铺用户加载自己的店铺信息
    try {
      final response = await ShopApi.getMyShop();
      if (response.isSuccess && response.data != null) {
        final shopData = response.data as Map<String, dynamic>;
        setState(() {
          _shopId = shopData['id'];
        });
        _loadOrders();
      } else {
        // 店铺用户但没有店铺记录，显示错误信息
        setState(() {
          _isLoading = false;
          _shopId = null;
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? l10n.noShopYet)),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _shopId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${AppLocalizations.of(context).loadFailed}: $e')),
        );
      }
    }
  }

  int _asCount(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  void _copyShopStats(Map<String, dynamic> stats) {
    _pendingShipmentCount = _asCount(stats['pendingShipment']);
    _pendingReceiptCount = _asCount(stats['pendingReceipt']);
    _completedCount = _asCount(stats['completed']);
    _cancelledCount = _asCount(stats['cancelled']);
    _menuBadge = _asCount(stats['menuBadge']);
  }

  void _publishShopStats(Map<String, dynamic> stats) {
    context.read<AppProvider>().updateShopOrderCounts(
          pendingShipment: _asCount(stats['pendingShipment']),
          pendingReceipt: _asCount(stats['pendingReceipt']),
          completed: _asCount(stats['completed']),
          cancelled: _asCount(stats['cancelled']),
          menuBadge: _asCount(stats['menuBadge']),
          paymentOverdue: stats.containsKey('paymentOverdue')
              ? _asCount(stats['paymentOverdue']) == 1
              : null,
        );
  }

  /// 加载订单列表
  Future<void> _loadOrders() async {
    final serial = ++_loadSerial;
    final viewedStatus = _selectedStatus;
    setState(() {
      _isLoading = true;
    });

    try {
      final status =
          viewedStatus == 'all' ? null : _getStatusValue(viewedStatus);

      final response = await OrderApi.getShopOrders(
        _shopId,
        status: status,
        keyword: _searchKeyword.isNotEmpty ? _searchKeyword : null,
        page: _currentPage,
        pageSize: _itemsPerPage,
      );
      final statsResponse = await OrderApi.getMyShopOrderStats();
      if (!mounted || serial != _loadSerial) {
        return;
      }

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final orders = List<Map<String, dynamic>>.from(data['records'] ?? []);
        setState(() {
          _orders = orders;
          _totalRecords = (data['total'] as num?)?.toInt() ?? 0;
          _totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
          if (statsResponse.isSuccess && statsResponse.data != null) {
            _copyShopStats(statsResponse.data!);
          }
          _isLoading = false;
        });
        if (statsResponse.isSuccess && statsResponse.data != null) {
          _publishShopStats(statsResponse.data!);
        }

        await _markViewedFinalOrders(viewedStatus, orders, serial);
      } else {
        setState(() {
          _allOrders = [];
          _orders = [];
          _totalRecords = 0;
          _totalPages = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || serial != _loadSerial) {
        return;
      }
      setState(() {
        _allOrders = [];
        _orders = [];
        _totalRecords = 0;
        _totalPages = 1;
        _isLoading = false;
      });
    }
  }

  /// 全部、已完成、已取消才标已读。orderIds 只带本页终态订单。
  Future<void> _markViewedFinalOrders(
    String viewedStatus,
    List<Map<String, dynamic>> orders,
    int serial,
  ) async {
    if (viewedStatus != 'all' &&
        viewedStatus != 'completed' &&
        viewedStatus != 'cancelled') {
      return;
    }

    final orderIds = <int>[];
    for (final order in orders) {
      final status = _asCount(order['status']);
      if (status != 2 && status != 3) {
        continue;
      }
      final id = order['id'];
      if (id is num) {
        orderIds.add(id.toInt());
      }
    }
    if (orderIds.isEmpty) {
      return;
    }

    int? statusValue;
    if (viewedStatus == 'completed') {
      statusValue = 2;
    } else if (viewedStatus == 'cancelled') {
      statusValue = 3;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAdminOrService = authProvider.isAdmin || authProvider.isService;
      final viewType = isAdminOrService ? 'service' : 'seller';
      final markReadResponse = await OrderApi.markFinalOrdersAsRead(
        statusValue,
        orderIds,
        viewType,
      );
      if (!markReadResponse.isSuccess || !mounted || serial != _loadSerial) {
        return;
      }
      final newStatsResponse = await OrderApi.getMyShopOrderStats();
      if (!mounted || serial != _loadSerial) {
        return;
      }
      if (newStatsResponse.isSuccess && newStatsResponse.data != null) {
        setState(() {
          _copyShopStats(newStatsResponse.data!);
        });
        _publishShopStats(newStatsResponse.data!);
      }
    } catch (e) {
      // 标记已读失败不影响订单列表显示
    }
  }

  /// 更新当前页数据
  void _updatePageData() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _allOrders.length);
    _orders = _allOrders.sublist(startIndex, endIndex);
  }

  /// 将前端状态转换为后端状态值
  int _getStatusValue(String status) {
    switch (status) {
      case 'pending_shipment':
        return 0;
      case 'pending_receipt':
        return 1;
      case 'completed':
        return 2;
      case 'cancelled':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            Text(
              l10n.shopOrdersTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
          ],
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildStatusTabs(),
          const SizedBox(height: 16),
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.translate('search_order_hint'),
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (value) => _performSearch(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _performSearch,
          style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          child: Text(l10n.translate('search')),
        ),
        const SizedBox(width: 8),
        if (_searchKeyword.isNotEmpty)
          TextButton(
            onPressed: _clearSearch,
            child: Text(l10n.translate('clear')),
          ),
      ],
    );
  }

  void _performSearch() {
    setState(() {
      _searchKeyword = _searchController.text.trim();
      _currentPage = 1;
    });
    _loadOrders();
  }

  void _clearSearch() {
    setState(() {
      _searchKeyword = '';
      _searchController.clear();
      _currentPage = 1;
    });
    _loadOrders();
  }

  Widget _buildStatusTabs() {
    final l10n = AppLocalizations.of(context);
    final tabs = <(String, String, int)>[
      (l10n.all, 'all', _menuBadge),
      (l10n.pendingShipment, 'pending_shipment', _pendingShipmentCount),
      (l10n.pendingReceipt, 'pending_receipt', _pendingReceiptCount),
      (l10n.orderCompleted, 'completed', _completedCount),
      (l10n.orderCancelled, 'cancelled', _cancelledCount),
    ];

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(right: 8),
          itemCount: tabs.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final tab = tabs[index];
            return _buildStatusTab(tab.$1, tab.$2, tab.$3);
          },
        ),
      ),
    );
  }

  Widget _buildStatusTab(String label, String status, int count) {
    final isSelected = _selectedStatus == status;
    final badgeText = count > 0 ? (count > 99 ? '99+' : '$count') : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: isSelected ? Colors.blue[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              setState(() {
                _selectedStatus = status;
                _currentPage = 1;
              });
              _loadOrders();
            },
            splashColor: isSelected ? Colors.white24 : Colors.black12,
            highlightColor: isSelected ? Colors.white10 : Colors.black12,
            child: Semantics(
              selected: isSelected,
              label: badgeText == null ? label : '$label $badgeText',
              excludeSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF424242),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (badgeText != null)
          Positioned(
            top: -6,
            right: -6,
            child: _countBadge(badgeText),
          ),
      ],
    );
  }

  /// 右上角小角标。不设 alignment，避免被父级高度撑满。
  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdminOrService = authProvider.isAdmin || authProvider.isService;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_shopId == null && !isAdminOrService) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            l10n.noShopYet,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            l10n.noOrders,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView(
      children: [
        ..._orders.map((order) => _buildOrderItem(order)).toList(),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdminOrService = authProvider.isAdmin || authProvider.isService;
    final isShop = authProvider.isShop;
    final items = order['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty ? items[0] : null;
    final orderStatus = order['status'] as int? ?? 0;
    final isArrived = order['isArrived'] as bool?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 订单号和状态
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${l10n.orderNo}: ${order['orderNo'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColorByValue(orderStatus),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getStatusTextByValue(orderStatus,
                            isArrived: isArrived),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 商品信息
                if (firstItem != null)
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: firstItem['productImage'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  ImageUtil.getImageUrl(
                                      firstItem['productImage']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.image,
                                        color: Colors.grey[400], size: 30);
                                  },
                                ),
                              )
                            : Icon(Icons.image,
                                color: Colors.grey[400], size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstItem['productName'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (order['shopName'] != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.store,
                                      size: 11, color: Colors.grey[600]),
                                  const SizedBox(width: 3),
                                  Text(
                                    order['shopName'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.quantity}: ${firstItem['quantity'] ?? 0}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (items.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.itemsCount(items.length),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // 订单金额和时间
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$ ${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${l10n.cost}: \$ ${(order['cost'] ?? 0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${l10n.profit}: \$ ${(order['profit'] ?? 0).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateUtil.formatDateTime(
                          DateUtil.parseAsLocalDateTime(order['createTime'])),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _showOrderDetailDialog(order),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(l10n.viewDetails,
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                    // 支付按钮：只有店铺用户可见
                    if (isShop && orderStatus == 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (order['sellerPaid'] == true) ? null : () => _handlePayment(order['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            (order['sellerPaid'] == true) ? l10n.sellerPaid : l10n.pay,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    // 发货按钮：只有管理员/客服可见
                    if (isAdminOrService && orderStatus == 0 && order['sellerPaid'] == true) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleConfirmShipment(order['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            l10n.confirmShipment,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    if (isAdminOrService &&
                        orderStatus == 1 &&
                        order['isArrived'] != true) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleUpdateLogistics(order['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            l10n.translate('update_logistics'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleMarkAsArrived(order['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            l10n.translate('mark_as_arrived'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${l10n.orderNo}: ${order['orderNo'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColorByValue(orderStatus),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getStatusTextByValue(orderStatus,
                                  isArrived: isArrived),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (firstItem != null)
                        Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: firstItem['productImage'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        ImageUtil.getImageUrl(
                                            firstItem['productImage']),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.image,
                                              color: Colors.grey[400],
                                              size: 35);
                                        },
                                      ),
                                    )
                                  : Icon(Icons.image,
                                      color: Colors.grey[400], size: 35),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstItem['productName'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (order['shopName'] != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.store,
                                            size: 12, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          order['shopName'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    '${l10n.quantity}: ${firstItem['quantity'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      if (items.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l10n.itemsCount(items.length),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$ ${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${l10n.cost}: \$ ${(order['cost'] ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${l10n.profit}: \$ ${(order['profit'] ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateUtil.formatDateTime(
                          DateUtil.parseAsLocalDateTime(order['createTime'])),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _showOrderDetailDialog(order),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          child: Text(l10n.viewDetails,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        // 支付按钮：只有店铺用户可见
                        if (isShop && orderStatus == 0) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (order['sellerPaid'] == true) ? null : () => _handlePayment(order['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              (order['sellerPaid'] == true) ? l10n.sellerPaid : l10n.pay,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        // 发货按钮：只有管理员/客服可见
                        if (isAdminOrService && orderStatus == 0 && order['sellerPaid'] == true) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _handleConfirmShipment(order['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              l10n.confirmShipment,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                        if (isAdminOrService &&
                            orderStatus == 1 &&
                            order['isArrived'] != true) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _handleUpdateLogistics(order['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              l10n.translate('update_logistics'),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _handleMarkAsArrived(order['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              l10n.translate('mark_as_arrived'),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  /// 根据状态值获取状态文本
  String _getStatusTextByValue(int status, {bool? isArrived}) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 0:
        return l10n.pendingShipment;
      case 1:
        // 已发货但未到货显示"运输中"，已到货显示"待收货"
        if (isArrived == false) {
          return l10n.translate('in_transit');
        }
        return l10n.pendingReceipt;
      case 2:
        return l10n.orderCompleted;
      case 3:
        return l10n.orderCancelled;
      default:
        return l10n.unknown;
    }
  }

  /// 根据状态值获取状态颜色
  Color _getStatusColorByValue(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
                        _loadOrders();
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
                        _loadOrders();
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
                  _loadOrders();
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
                  _loadOrders();
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
        Text(
          l10n.itemsPerPage,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
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
                _loadOrders();
              }
            },
            items: _pageSizeOptions.map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value'),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.items,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
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
        child: Icon(
          icon,
          size: 20,
          color: onPressed == null ? Colors.grey[400] : Colors.grey[700],
        ),
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
      if (i < endPage) {
        pageNumbers.add(const SizedBox(width: 8));
      }
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
        _loadOrders();
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[700] : Colors.white,
          border: Border.all(
            color: isActive ? Colors.blue[700]! : Colors.grey[300]!,
          ),
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
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildPageInput() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          l10n.jumpTo,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          height: 36,
          child: TextField(
            controller: _pageInputController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        Text(
          l10n.page,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _jumpToPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(60, 36),
          ),
          child: Text(
            l10n.jump,
            style: const TextStyle(fontSize: 14),
          ),
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
    _pageInputController.clear();
    _loadOrders();
  }

  /// 支付
  Future<void> _handlePayment(dynamic orderId) async {
    final order = _orders.firstWhere((o) => o['id'] == orderId);

    // 保存当前的 BuildContext，避免对话框关闭后 context 失效
    final parentContext = context;

    showDialog(
      context: context,
      builder: (context) => _PaymentDialog(
        order: order,
        onSubmit: (paymentPassword) async {
          try {
            final response = await OrderApi.sellerPay(
              orderId,
              paymentPassword: paymentPassword,
            );

            if (mounted) {
              // 使用保存的父级 context 显示支付结果弹框
              await showDialog(
                context: parentContext,
                barrierDismissible: false,
                builder: (dialogContext) {
                  final l10n = AppLocalizations.of(dialogContext);
                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(
                          response.isSuccess ? Icons.check_circle : Icons.error,
                          color: response.isSuccess ? Colors.green[700] : Colors.red[700],
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          response.isSuccess ? l10n.paymentSuccess : l10n.paymentFailed,
                          style: TextStyle(
                            color: response.isSuccess ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    content: Text(response.isSuccess
                        ? l10n.paymentSuccess
                        : response.errorMessage),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: response.isSuccess ? Colors.green[700] : Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.confirm),
                      ),
                    ],
                  );
                },
              );

              // 只有支付成功才刷新列表和余额
              if (response.isSuccess) {
                _loadOrders();
                parentContext.read<AuthProvider>().refreshUserInfo();
              }
            }
          } catch (e) {
            if (mounted) {
              // 使用保存的父级 context 显示支付失败弹框
              await showDialog(
                context: parentContext,
                barrierDismissible: false,
                builder: (dialogContext) {
                  final l10n = AppLocalizations.of(dialogContext);
                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700], size: 28),
                        const SizedBox(width: 12),
                        Text(
                          l10n.paymentFailed,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                    content: Text('${l10n.operationFailed}: $e'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.confirm),
                      ),
                    ],
                  );
                },
              );
            }
          }
        },
      ),
    );
  }

  /// 显示支付结果弹框
  Future<void> _showPaymentResultDialog({
    required bool success,
    required String message,
  }) async {
    print('🟢 [支付结果对话框] 开始显示 - success: $success, message: $message');
    final l10n = AppLocalizations.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        print('🟢 [支付结果对话框] 构建对话框UI');
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green[700] : Colors.red[700],
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                success ? l10n.paymentSuccess : l10n.paymentFailed,
                style: TextStyle(
                  color: success ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                print('🟢 [支付结果对话框] 用户点击确定按钮');
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: success ? Colors.green[700] : Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
    print('🟢 [支付结果对话框] 对话框已关闭');
  }

  /// 确认发货
  Future<void> _handleConfirmShipment(dynamic orderId) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmShipment),
        content: Text(l10n.translate('confirm_shipment_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await OrderApi.confirmShipment(orderId as int);
      if (response.isSuccess) {
        if (mounted) {
          SnackBarUtil.showSuccess(context, l10n.shipmentSuccess);
          _loadOrders();
        }
      } else {
        if (mounted) {
          SnackBarUtil.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '${l10n.operationFailed}: $e');
      }
    }
  }

  /// 更新物流
  Future<void> _handleUpdateLogistics(dynamic orderId) async {
    final l10n = AppLocalizations.of(context);
    final TextEditingController logisticsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('update_logistics')),
        content: TextField(
          controller: logisticsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.translate('enter_logistics_info'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await OrderApi.updateLogistics(
        orderId as int,
        logisticsController.text,
      );
      if (response.isSuccess) {
        if (mounted) {
          SnackBarUtil.showSuccess(
              context, l10n.translate('update_logistics_success'));
          _loadOrders();
        }
      } else {
        if (mounted) {
          SnackBarUtil.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '${l10n.operationFailed}: $e');
      }
    }
  }

  /// 标记为已到货
  Future<void> _handleMarkAsArrived(dynamic orderId) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('mark_as_arrived')),
        content: Text(l10n.translate('confirm_mark_as_arrived_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await OrderApi.markAsArrived(orderId as int);
      if (response.isSuccess) {
        if (mounted) {
          SnackBarUtil.showSuccess(
              context, l10n.translate('mark_as_arrived_success'));
          _loadOrders();
        }
      } else {
        if (mounted) {
          SnackBarUtil.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(context, '${l10n.operationFailed}: $e');
      }
    }
  }

  /// 显示订单详情对话框
  void _showOrderDetailDialog(Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context);
    final items = order['items'] as List<dynamic>? ?? [];
    final orderStatus = order['status'] as int? ?? 0;
    final isArrived = order['isArrived'] as bool?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.orderDetail),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailSection(l10n.orderInfo, [
                  _buildDetailRow(l10n.orderNo, order['orderNo'] ?? ''),
                  _buildDetailRow(l10n.orderStatus,
                      _getStatusTextByValue(orderStatus, isArrived: isArrived)),
                  _buildDetailRow(
                      l10n.placeOrderTime,
                      DateUtil.formatDateTime(
                          DateUtil.parseAsLocalDateTime(order['createTime']))),
                  _buildDetailRow(l10n.orderTotal,
                      '\$ ${(order['totalAmount'] ?? 0).toStringAsFixed(2)}'),
                  if (order['remark'] != null &&
                      order['remark'].toString().isNotEmpty)
                    _buildDetailRow(l10n.orderRemark, order['remark']),
                  if (orderStatus == 3 && order['cancelReason'] != null)
                    _buildDetailRow(l10n.cancelReason, order['cancelReason']),
                ]),
                const SizedBox(height: 16),
                _buildDetailSection(l10n.shippingInfo, [
                  _buildDetailRow(
                      l10n.receiverName, order['receiverName'] ?? ''),
                  _buildDetailRow(
                      l10n.receiverPhone, order['receiverPhone'] ?? ''),
                  _buildDetailRow(
                      l10n.receiverAddress, order['receiverAddress'] ?? ''),
                ]),
                const SizedBox(height: 16),
                _buildDetailSection(l10n.productInfo, [
                  ...items.map((item) => _buildProductItem(item)).toList(),
                ]),
                const SizedBox(height: 16),
                _buildLogisticsSection(order),
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: item['productImage'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      ImageUtil.getImageUrl(item['productImage']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image,
                            color: Colors.grey[400], size: 30);
                      },
                    ),
                  )
                : Icon(Icons.image, color: Colors.grey[400], size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$ ${(item['price'] ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[700],
                      ),
                    ),
                    Text(
                      'x ${item['quantity'] ?? 0}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$ ${(item['subtotal'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsSection(Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context);
    final orderInfos = order['orderInfos'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('logistics_status'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: orderInfos.isEmpty
              ? Text(
                  l10n.translate('no_logistics_info'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: orderInfos.map((info) {
                    return _buildLogisticsItem(info);
                  }).toList(),
                ),
        ),
      ],
    );
  }

  /// 翻译物流状态内容
  String _translateLogisticsContent(String content) {
    final l10n = AppLocalizations.of(context);

    // 订单已创建
    if (content == '订单已创建') {
      return l10n.orderCreated;
    }
    // 卖家已支付
    if (content == '卖家已支付') {
      return l10n.sellerPaid;
    }
    // 订单已发货
    if (content == '订单已发货') {
      return l10n.orderShipped;
    }
    // 物流信息已更新：xxxx（只翻译前缀，保留后面的内容）
    if (content.startsWith('物流信息已更新：')) {
      final customContent = content.substring('物流信息已更新：'.length);
      return '${l10n.logisticsUpdated}：$customContent';
    }
    // 订单已到货
    if (content == '订单已到货') {
      return l10n.orderArrived;
    }
    // 订单已完成
    if (content == '订单已完成') {
      return l10n.orderCompletedStatus;
    }
    // 订单已取消
    if (content == '订单已取消') {
      return l10n.orderCancelledStatus;
    }
    // 订单已取消，原因：xxxx
    if (content.startsWith('订单已取消，原因：')) {
      final reason = content.substring('订单已取消，原因：'.length);
      return '${l10n.orderCancelledReason}：$reason';
    }

    // 如果没有匹配到，返回原内容
    return content;
  }

  Widget _buildLogisticsItem(Map<String, dynamic> info) {
    final content = info['content'] ?? '';
    final translatedContent = _translateLogisticsContent(content);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                info['infoType'] == 'LOGISTICS_UPDATE'
                    ? Icons.local_shipping
                    : Icons.info_outline,
                size: 16,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  translatedContent,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateUtil.formatDateTime(
                DateUtil.parseAsLocalDateTime(info['createTime'])),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// 支付对话框
class _PaymentDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(String paymentPassword) onSubmit;

  const _PaymentDialog({
    required this.order,
    required this.onSubmit,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cost = widget.order['cost'] ?? 0.0;

    return AlertDialog(
      title: Text(l10n.pay),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 显示订单成本金额（只读）
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.paymentAmount,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '\$ ${cost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.translate('payment_password'),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return l10n.translate('please_enter_payment_password');
                  }
                  return null;
                },
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final password = _passwordController.text;
              Navigator.pop(context);
              widget.onSubmit(password);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
