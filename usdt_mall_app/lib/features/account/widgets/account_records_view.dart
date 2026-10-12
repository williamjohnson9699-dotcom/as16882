import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:usdt_mall_app/core/api/account_records_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/date_util.dart';

/// 账户记录视图
class AccountRecordsView extends StatefulWidget {
  const AccountRecordsView({super.key});

  @override
  State<AccountRecordsView> createState() => _AccountRecordsViewState();
}

class _AccountRecordsViewState extends State<AccountRecordsView> {
  String _selectedType = 'all'; // 当前选中的类型：all-全部, recharge-充值, withdraw-提现, seller_pay-卖家支付, platform_rebate-平台回馈, buyer_settlement-买家结算
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 10;
  final List<int> _pageSizeOptions = [10, 20, 30, 50];
  final TextEditingController _pageInputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  List<Map<String, dynamic>> _displayRecords = [];
  List<Map<String, dynamic>> _allRecords = [];
  int _totalRecords = 0;
  bool _isLoading = false;

  int _pendingRechargeCount = 0;
  int _pendingWithdrawCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final appProvider = context.read<AppProvider>();
    await appProvider.loadPendingRecordCount();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAdminOrService = authProvider.isAdmin || authProvider.isService;

      // 根据选中的类型确定API参数
      int? typeParam;
      if (_selectedType == 'recharge') {
        typeParam = 1;
      } else if (_selectedType == 'withdraw') {
        typeParam = 2;
      } else if (_selectedType == 'seller_pay') {
        typeParam = 3;
      } else if (_selectedType == 'platform_rebate') {
        typeParam = 4;
      } else if (_selectedType == 'buyer_settlement') {
        typeParam = 5;
      }

      // 根据用户角色调用不同的API
      final response = isAdminOrService
          ? await AccountRecordsApi.getAllRecordsByPage(
              keyword: _searchKeyword.isEmpty ? null : _searchKeyword,
              type: typeParam,
              page: _currentPage,
              pageSize: _itemsPerPage,
            )
          : await AccountRecordsApi.getRecordsByPage(
              type: typeParam,
              page: _currentPage,
              pageSize: _itemsPerPage,
            );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final records = (data['records'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        setState(() {
          _displayRecords = records;
          _totalRecords = (data['total'] as num?)?.toInt() ?? 0;
          _totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
          _isLoading = false;
        });

        // 自动标记已读：全部、卖家支付、平台回馈、买家结算
        if (_selectedType == 'all' || _selectedType == 'seller_pay' ||
            _selectedType == 'platform_rebate' || _selectedType == 'buyer_settlement') {
          _batchMarkAsRead(records);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? l10n.loadFailed)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdminOrService = authProvider.isAdmin || authProvider.isService;
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            Text(
              l10n.accountRecords,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
          ],
          if (isAdminOrService) ...[
            _buildSearchBar(),
            const SizedBox(height: 16),
          ],
          _buildTypeTabs(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildRecordList(),
          ),
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
              hintText: l10n.translate('search_user_hint'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (value) => _performSearch(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _performSearch,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
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
    _loadRecords();
  }

  void _clearSearch() {
    setState(() {
      _searchKeyword = '';
      _searchController.clear();
      _currentPage = 1;
    });
    _loadRecords();
  }

  /// 类型筛选标签。充值、提现不单独成页，只在「全部」里展示。
  Widget _buildTypeTabs() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _buildTypeTab(l10n.allRecords, 'all'),
        const SizedBox(width: 12),
        _buildTypeTab(l10n.translate('seller_payment'), 'seller_pay'),
        const SizedBox(width: 12),
        _buildTypeTab(l10n.translate('platform_rebate'), 'platform_rebate'),
        const SizedBox(width: 12),
        _buildTypeTab(l10n.translate('buyer_settlement'), 'buyer_settlement'),
      ],
    );
  }

  Widget _buildTypeTab(String label, String type) {
    final isSelected = _selectedType == type;
    final appProvider = context.watch<AppProvider>();

    int? badgeCount;
    if (type == 'all') {
      badgeCount = appProvider.pendingRecordCount > 0 ? appProvider.pendingRecordCount : null;
    } else if (type == 'recharge') {
      badgeCount = appProvider.pendingRechargeCount > 0 ? appProvider.pendingRechargeCount : null;
    } else if (type == 'withdraw') {
      badgeCount = appProvider.pendingWithdrawCount > 0 ? appProvider.pendingWithdrawCount : null;
    } else if (type == 'seller_pay') {
      badgeCount = appProvider.pendingSellerPayCount > 0 ? appProvider.pendingSellerPayCount : null;
    } else if (type == 'platform_rebate') {
      badgeCount = appProvider.pendingPlatformRebateCount > 0 ? appProvider.pendingPlatformRebateCount : null;
    } else if (type == 'buyer_settlement') {
      badgeCount = appProvider.pendingBuyerSettlementCount > 0 ? appProvider.pendingBuyerSettlementCount : null;
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
            _currentPage = 1;
          });
          _loadRecords();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[700] : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
              if (badgeCount != null)
                Positioned(
                  right: 4,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _displayRecords.length,
            itemBuilder: (context, index) => _buildRecordItem(_displayRecords[index]),
          ),
        ),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdminOrService = authProvider.isAdmin || authProvider.isService;
    final recordType = record['type'] as int;
    final isRecharge = recordType == 1;
    final status = record['status'] as int?;
    final isPending = status == 0;
    final isMobile = ResponsiveUtil.isMobile(context);
    final typeText = _getTypeText(recordType);
    final typeColor = _getTypeColor(recordType);
    final isRead = record['isRead'] as int? ?? 1;
    final needsRead = (recordType == 3 || recordType == 4 || recordType == 5) && isRead == 0;

    return InkWell(
      onTap: needsRead ? () => _markAsRead(record['id'] as int) : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (!isMobile) ...[
                Icon(
                  isRecharge ? Icons.add_circle : Icons.remove_circle,
                  color: isRecharge ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 16),
              ],
              if (isRecharge && record['proofImage'] != null && record['proofImage'].toString().isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _showImageDialog(record['proofImage']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      ImageUtil.getImageUrl(record['proofImage']),
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 60,
                        width: 60,
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.grey[600], size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(record['orderNo'] ?? '', style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeText,
                            style: TextStyle(
                              fontSize: 11,
                              color: typeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isAdminOrService && record['username'] != null) ...[
                      Text(
                        '${l10n.translate('user')}: ${record['nickname'] ?? record['username']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                    ],
                    // 充值和提现显示收款地址
                    if ((recordType == 1 || recordType == 2) && record['receivingAddress'] != null && record['receivingAddress'].toString().isNotEmpty) ...[
                      _buildCopyableField(
                        label: l10n.translate('receiving_address'),
                        value: record['receivingAddress'],
                      ),
                      const SizedBox(height: 2),
                    ],
                    // 卖家支付、平台回馈、买家结算显示订单号
                    if ((recordType == 3 || recordType == 4 || recordType == 5) && record['relatedOrderNo'] != null && record['relatedOrderNo'].toString().isNotEmpty) ...[
                      _buildCopyableField(
                        label: l10n.translate('order_number'),
                        value: record['relatedOrderNo'],
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      DateUtil.formatDateTime(DateUtil.parseAsLocalDateTime(record['createTime'])),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$ ${record['amount'] ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isRecharge ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusText(status),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (isAdminOrService && isPending) ...[
                const SizedBox(width: 12),
                Column(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _approveRecord(record['id'] as int),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(l10n.translate('approve'), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 70,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () => _rejectRecord(record['id'] as int),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(l10n.translate('reject'), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _markAsRead(int recordId) async {
    try {
      await AccountRecordsApi.markAsRead(recordId);
      _loadRecords();
      context.read<AppProvider>().loadPendingRecordCount();
    } catch (e) {
      // 静默失败
    }
  }

  Future<void> _batchMarkAsRead(List<Map<String, dynamic>> records) async {
    final unreadIds = records
        .where((r) {
          final type = r['type'] as int;
          final isRead = r['isRead'] as int? ?? 1;
          return (type == 3 || type == 4 || type == 5) && isRead == 0;
        })
        .map((r) => r['id'] as int)
        .toList();

    print('批量标记已读: 找到 ${unreadIds.length} 条未读记录, IDs: $unreadIds');

    if (unreadIds.isEmpty) return;

    try {
      final response = await AccountRecordsApi.batchMarkAsRead(unreadIds);
      print('批量标记已读响应: ${response.isSuccess}');
      if (response.isSuccess && mounted) {
        context.read<AppProvider>().loadPendingRecordCount();
      }
    } catch (e) {
      print('批量标记已读失败: $e');
    }
  }

  Future<void> _approveRecord(int recordId) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('approve')),
        content: Text(l10n.translate('confirm_approve_message')),
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
      final response = await AccountRecordsApi.approveRecord(recordId);

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('approve_success'))),
          );
          _loadRecords();
          context.read<AuthProvider>().refreshUserInfo();
          context.read<AppProvider>().loadPendingRecordCount();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? l10n.translate('approve_failed'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('approve_failed')}: $e')),
        );
      }
    }
  }

  Future<void> _rejectRecord(int recordId) async {
    final l10n = AppLocalizations.of(context);

    try {
      final response = await AccountRecordsApi.rejectRecord(recordId);

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('reject_success'))),
          );
          _loadRecords();
          context.read<AppProvider>().loadPendingRecordCount();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? l10n.translate('reject_failed'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('reject_failed')}: $e')),
        );
      }
    }
  }

  String _getStatusText(int? status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 0:
        return l10n.statusPending;
      case 1:
        return l10n.statusApproved;
      case 2:
        return l10n.statusRejected;
      default:
        return l10n.statusUnknown;
    }
  }

  String _getTypeText(int type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case 1:
        return l10n.recharge;
      case 2:
        return l10n.withdraw;
      case 3:
        return l10n.sellerPayment;
      case 4:
        return l10n.platformRebate;
      case 5:
        return l10n.buyerSettlement;
      default:
        return l10n.statusUnknown;
    }
  }

  Color _getTypeColor(int type) {
    switch (type) {
      case 1:
        return Colors.green[700]!;
      case 2:
        return Colors.orange[700]!;
      case 3:
        return Colors.blue[700]!;
      case 4:
        return Colors.purple[700]!;
      case 5:
        return Colors.teal[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

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
                        _loadRecords();
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
                        _loadRecords();
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
        _buildPageSizeSelector(),
        const SizedBox(width: 24),
        _buildPageButton(
          icon: Icons.chevron_left,
          onPressed: _currentPage > 1
              ? () {
                  setState(() {
                    _currentPage--;
                  });
                  _loadRecords();
                }
              : null,
        ),
        const SizedBox(width: 8),
        ..._buildPageNumbers(),
        const SizedBox(width: 8),
        _buildPageButton(
          icon: Icons.chevron_right,
          onPressed: _currentPage < _totalPages
              ? () {
                  setState(() {
                    _currentPage++;
                  });
                  _loadRecords();
                }
              : null,
        ),
        const SizedBox(width: 16),
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
                _loadRecords();
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
        _loadRecords();
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
        Container(
          width: 60,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _pageInputController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        InkWell(
          onTap: _jumpToPage,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                l10n.confirm,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _jumpToPage() {
    final l10n = AppLocalizations.of(context);
    final pageNumber = int.tryParse(_pageInputController.text);
    if (pageNumber != null && pageNumber >= 1 && pageNumber <= _totalPages) {
      setState(() {
        _currentPage = pageNumber;
      });
      _pageInputController.clear();
      _loadRecords();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.enterValidPage} (1-$_totalPages)')),
      );
    }
  }

  /// 构建可复制的字段
  Widget _buildCopyableField({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).translate('copied')),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Icon(Icons.copy, size: 16, color: Colors.blue[700]),
        ),
      ],
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.network(
            ImageUtil.getImageUrl(imageUrl),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}
