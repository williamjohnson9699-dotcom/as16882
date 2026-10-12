import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/api/order_api.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/providers/auth_provider.dart';

/// 我的订单视图
class MyOrdersView extends StatefulWidget {
  final String? initialStatus;

  const MyOrdersView({super.key, this.initialStatus});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  String _selectedStatus = 'all'; // 当前选中的状态
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  // 状态数量统计。已完成、已取消是未读数，入口红点用 menuBadge。
  int _pendingShipmentCount = 0;
  int _pendingReceiptCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  int _menuBadge = 0;
  int _loadSerial = 0;

  // 分页相关
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 10;
  final List<int> _pageSizeOptions = [10, 20, 30, 50];
  final TextEditingController _pageInputController = TextEditingController();
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      _selectedStatus = widget.initialStatus!;
    }
    _loadOrders();
  }

  @override
  void didUpdateWidget(MyOrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus &&
        widget.initialStatus != null) {
      setState(() {
        _selectedStatus = widget.initialStatus!;
      });
      _loadOrders();
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

  void _copyBuyerStats(Map<String, dynamic> stats) {
    _pendingShipmentCount = _asCount(stats['pendingShipment']);
    _pendingReceiptCount = _asCount(stats['pendingReceipt']);
    _completedCount = _asCount(stats['completed']);
    _cancelledCount = _asCount(stats['cancelled']);
    _menuBadge = _asCount(stats['menuBadge']);
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

      final response = await OrderApi.getUserOrders(
        status: status,
        page: _currentPage,
        pageSize: _itemsPerPage,
      );
      final statsResponse = await OrderApi.getUserOrderStats();
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
            _copyBuyerStats(statsResponse.data!);
          }
          _isLoading = false;
        });
        if (statsResponse.isSuccess && statsResponse.data != null) {
          context.read<AppProvider>().updateUserOrderStats(statsResponse.data!);
        }

        await _markViewedFinalOrders(viewedStatus, orders, serial);
      } else {
        setState(() {
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
      final markReadResponse = await OrderApi.markFinalOrdersAsRead(
        statusValue,
        orderIds,
        'buyer',
      );
      if (!markReadResponse.isSuccess || !mounted || serial != _loadSerial) {
        return;
      }
      final newStatsResponse = await OrderApi.getUserOrderStats();
      if (!mounted || serial != _loadSerial) {
        return;
      }
      if (newStatsResponse.isSuccess && newStatsResponse.data != null) {
        setState(() {
          _copyBuyerStats(newStatsResponse.data!);
        });
        context
            .read<AppProvider>()
            .updateUserOrderStats(newStatsResponse.data!);
      }
    } catch (e) {
      // 标记已读失败不影响订单列表显示
    }
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
          // 标题
          if (!isMobile) ...[
            Text(
              l10n.myOrders,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          // 状态选项卡
          _buildStatusTabs(),
          const SizedBox(height: 16),
          // 订单列表
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }

  /// 构建状态选项卡
  Widget _buildStatusTabs() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _buildStatusTab(l10n.allRecords, 'all'),
        const SizedBox(width: 12),
        _buildStatusTab(l10n.pendingShipment, 'pending_shipment'),
        const SizedBox(width: 12),
        _buildStatusTab(l10n.pendingReceipt, 'pending_receipt'),
        const SizedBox(width: 12),
        _buildStatusTab(l10n.orderCompleted, 'completed'),
        const SizedBox(width: 12),
        _buildStatusTab(l10n.orderCancelled, 'cancelled'),
      ],
    );
  }

  /// 构建单个状态选项卡
  Widget _buildStatusTab(String label, String status) {
    final isSelected = _selectedStatus == status;

    // 全部用接口的 menuBadge。待发货、待收货、已完成、已取消用各自的统计字段。
    int? badgeCount;
    if (status == 'all') {
      badgeCount = _menuBadge > 0 ? _menuBadge : null;
    } else if (status == 'pending_shipment') {
      badgeCount = _pendingShipmentCount > 0 ? _pendingShipmentCount : null;
    } else if (status == 'pending_receipt') {
      badgeCount = _pendingReceiptCount > 0 ? _pendingReceiptCount : null;
    } else if (status == 'completed') {
      badgeCount = _completedCount > 0 ? _completedCount : null;
    } else if (status == 'cancelled') {
      badgeCount = _cancelledCount > 0 ? _cancelledCount : null;
    }

    final badgeText =
        badgeCount == null ? null : (badgeCount > 99 ? '99+' : '$badgeCount');

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: isSelected ? Colors.blue[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
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
                constraints: const BoxConstraints(minHeight: 44),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF424242),
                        ),
                      ),
                    ),
                    if (badgeText != null)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建订单列表
  Widget _buildOrderList() {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return Center(
        child: Text(
          l10n.noOrders,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _orders.length,
            itemBuilder: (context, index) => _buildOrderItem(_orders[index]),
          ),
        ),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  /// 构建订单项
  Widget _buildOrderItem(Map<String, dynamic> order) {
    final l10n = AppLocalizations.of(context);
    final items = order['items'] as List<dynamic>? ?? [];
    final firstItem = items.isNotEmpty ? items[0] : null;
    final orderStatus = order['status'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：订单号、状态、商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 订单号
                Text(
                  '${l10n.orderNo}: ${order['orderNo'] ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                // 状态标签
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColorByValue(orderStatus),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getStatusTextByValue(orderStatus,
                          isArrived: order['isArrived'] as bool?),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 商品信息
                if (firstItem != null)
                  InkWell(
                    onTap: () {
                      final productId = firstItem['productId'];
                      if (productId != null) {
                        context.push('/product/$productId');
                      }
                    },
                    child: Row(
                      children: [
                        // 商品图片
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
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.image,
                                          color: Colors.grey[400], size: 35);
                                    },
                                  ),
                                )
                              : Icon(Icons.image,
                                  color: Colors.grey[400], size: 35),
                        ),
                        const SizedBox(width: 12),
                        // 商品详情
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
          // 右侧：订单总额、日期、按钮
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 订单总额
              Text(
                '\$ ${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              // 订单日期
              Text(
                DateUtil.formatDateTime(
                    DateUtil.parseAsLocalDateTime(order['createTime'])),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              // 操作按钮
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      if ((orderStatus == 0 ||
                          (orderStatus == 1 &&
                              order['isArrived'] != true))) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _showCancelOrderDialog(order['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[700]!),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          child: Text(l10n.cancelOrder,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                  if (orderStatus == 1 && order['isArrived'] == true) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showConfirmReceiptDialog(order['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: Text(l10n.confirmReceipt,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _showCancelOrderDialog(order['id']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[700]!),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: Text(l10n.cancelOrder,
                          style: const TextStyle(fontSize: 13)),
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

  /// 获取状态文本
  String _getStatusText(String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 'all':
        return l10n.allRecords;
      case 'pending_shipment':
        return l10n.pendingShipment;
      case 'pending_receipt':
        return l10n.pendingReceipt;
      case 'completed':
        return l10n.orderCompleted;
      case 'cancelled':
        return l10n.orderCancelled;
      default:
        return l10n.statusUnknown;
    }
  }

  /// 根据状态值获取状态文本
  String _getStatusTextByValue(int status, {bool? isArrived}) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 0:
        return l10n.pendingShipment;
      case 1:
        // 如果已发货但未到货，显示"运输中"；如果已到货，显示"待收货"
        if (isArrived == false) {
          return l10n.translate('in_transit');
        }
        return l10n.pendingReceipt;
      case 2:
        return l10n.orderCompleted;
      case 3:
        return l10n.orderCancelled;
      default:
        return l10n.statusUnknown;
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case 'all':
        return Colors.grey;
      case 'pending_shipment':
        return Colors.orange;
      case 'pending_receipt':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
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
    final isMobile = ResponsiveUtil.isMobile(context);
    final l10n = AppLocalizations.of(context);

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

  /// 构建分页大小选择器
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

  /// 构建页码按钮
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

  /// 构建页码数字列表
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

  /// 构建页码数字按钮
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

  /// 构建省略号
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

  /// 构建页码输入区域
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

  /// 跳转到指定页码
  void _jumpToPage() {
    final l10n = AppLocalizations.of(context);
    final inputText = _pageInputController.text.trim();
    if (inputText.isEmpty) return;

    final pageNumber = int.tryParse(inputText);
    if (pageNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterValidPage)),
      );
      return;
    }

    if (pageNumber < 1 || pageNumber > _totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.pageRange}: 1-$_totalPages')),
      );
      return;
    }

    setState(() {
      _currentPage = pageNumber;
    });
    _pageInputController.clear();
    _loadOrders();
  }

  /// 确认发货
  Future<void> _handleConfirmShipment(dynamic orderId) async {
    final l10n = AppLocalizations.of(context);
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

  /// 确认收货
  Future<void> _handleConfirmReceipt(dynamic orderId) async {
    final l10n = AppLocalizations.of(context);
    try {
      final response = await OrderApi.confirmReceipt(orderId as int);
      if (response.isSuccess) {
        if (mounted) {
          SnackBarUtil.showSuccess(context, l10n.receiptSuccess);
          _loadOrders();
          // 刷新统计数据
          final statsResponse = await OrderApi.getUserOrderStats();
          if (statsResponse.isSuccess &&
              statsResponse.data != null &&
              mounted) {
            context
                .read<AppProvider>()
                .updateUserOrderStats(statsResponse.data!);
          }
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

  /// 显示确认收货对话框
  void _showConfirmReceiptDialog(dynamic orderId) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmReceipt),
        content: Text(l10n.confirmReceiptMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleConfirmReceipt(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// 显示取消订单对话框
  void _showCancelOrderDialog(dynamic orderId) {
    final l10n = AppLocalizations.of(context);
    final cancelReasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelOrderDialogTitle),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: TextFormField(
              controller: cancelReasonController,
              decoration: InputDecoration(
                labelText: l10n.cancelReasonLabel,
                hintText: l10n.cancelReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterCancelReason;
                }
                return null;
              },
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
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _handleCancelOrder(orderId, cancelReasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirmCancel),
          ),
        ],
      ),
    );
  }

  /// 取消订单
  Future<void> _handleCancelOrder(dynamic orderId, String cancelReason) async {
    final l10n = AppLocalizations.of(context);
    try {
      final response = await OrderApi.cancelOrder(orderId as int, cancelReason);
      if (response.isSuccess) {
        if (mounted) {
          SnackBarUtil.showSuccess(context, l10n.orderCancelledSuccess);
          _loadOrders();
          // 刷新用户余额
          context.read<AuthProvider>().refreshUserInfo();
          // 刷新统计数据
          final statsResponse = await OrderApi.getUserOrderStats();
          if (statsResponse.isSuccess &&
              statsResponse.data != null &&
              mounted) {
            context
                .read<AppProvider>()
                .updateUserOrderStats(statsResponse.data!);
          }
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
                // 订单信息
                _buildDetailSection(l10n.orderInfo, [
                  _buildDetailRow(l10n.orderNo, order['orderNo'] ?? ''),
                  _buildDetailRow(
                      l10n.orderStatus,
                      _getStatusTextByValue(orderStatus,
                          isArrived: order['isArrived'] as bool?)),
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
                // 收货信息
                _buildDetailSection(l10n.shippingInfo, [
                  _buildDetailRow(
                      l10n.receiverName, order['receiverName'] ?? ''),
                  _buildDetailRow(
                      l10n.receiverPhone, order['receiverPhone'] ?? ''),
                  _buildDetailRow(
                      l10n.receiverAddress, order['receiverAddress'] ?? ''),
                ]),
                const SizedBox(height: 16),
                // 商品信息
                _buildDetailSection(l10n.productInfo, [
                  ...items.map((item) => _buildProductItem(item)).toList(),
                ]),
                const SizedBox(height: 16),
                // 物流状态
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

  /// 构建详情区块
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

  /// 构建详情行
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

  /// 构建商品项
  Widget _buildProductItem(Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        final productId = item['productId'];
        if (productId != null) {
          Navigator.pop(context);
          context.push('/product/$productId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // 商品图片
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
            // 商品信息
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
      ),
    );
  }

  /// 构建物流状态部分
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

  /// 构建物流信息项
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
