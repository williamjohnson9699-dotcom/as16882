import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:usdt_mall_app/core/api/shop_application_api.dart';
import 'package:usdt_mall_app/core/l10n/app_localizations.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';

/// 店铺申请管理视图
class ShopApplicationsManagementView extends StatefulWidget {
  const ShopApplicationsManagementView({super.key});

  @override
  State<ShopApplicationsManagementView> createState() => _ShopApplicationsManagementViewState();
}

class _ShopApplicationsManagementViewState extends State<ShopApplicationsManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 10;
  final List<int> _pageSizeOptions = [10, 20, 30, 50];
  final TextEditingController _pageInputController = TextEditingController();

  List<Map<String, dynamic>> _applications = [];
  int _totalRecords = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApplications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadPendingShopApplicationCount();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ShopApplicationApi.getApplicationsByPage(
        status: _selectedStatus,
        keyword: _searchController.text.trim(),
        page: _currentPage,
        pageSize: _itemsPerPage,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final records = (data['records'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        setState(() {
          _applications = records;
          _totalRecords = (data['total'] as num?)?.toInt() ?? 0;
          _totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? AppLocalizations.of(context).loadFailed)),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).loadFailed}: $e')),
        );
      }
    }
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
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            Text(
              l10n.shopApplicationsManagement,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
          ],
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildStatusTabs(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildApplicationList(),
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
              hintText: l10n.searchShopContact,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                        _loadApplications();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => setState(() {}),
            onSubmitted: (value) => _loadApplications(),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _loadApplications,
          icon: const Icon(Icons.search),
          label: Text(l10n.search),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: _buildStatusTab(l10n.all, 'all')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatusTab(l10n.pending, 'pending')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatusTab(l10n.approved, 'approved')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatusTab(l10n.rejected, 'rejected')),
      ],
    );
  }

  Widget _buildStatusTab(String label, String status) {
    final isSelected = _selectedStatus == status;
    final appProvider = context.watch<AppProvider>();

    int? badgeCount;
    if (status == 'all' || status == 'pending') {
      badgeCount = appProvider.pendingShopApplicationCount > 0 ? appProvider.pendingShopApplicationCount : null;
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
          _currentPage = 1;
        });
        _loadApplications();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
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
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationList() {
    final l10n = AppLocalizations.of(context);
    if (_applications.isEmpty) {
      return Center(
        child: Text(l10n.noApplications, style: const TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _applications.length,
            itemBuilder: (context, index) => _buildApplicationItem(_applications[index]),
          ),
        ),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  Widget _buildApplicationItem(Map<String, dynamic> application) {
    final l10n = AppLocalizations.of(context);
    final status = application['status'] as String;
    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'approved'
            ? Colors.green
            : Colors.red;
    final statusText = status == 'pending'
        ? l10n.pending
        : status == 'approved'
            ? l10n.approved
            : l10n.rejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  ImageUtil.getImageUrl(application['shopLogo'] ?? ''),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(Icons.store, color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application['shopName'] ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.user}：${application['nickname'] ?? ''} (${application['username'] ?? ''})',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.contact}：${application['contactName']} | ${application['contactPhone']}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.mainBusiness}：${_getCategoryText(application['category'], l10n)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _showDetailDialog(application),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[700]!),
                ),
                child: Text(l10n.viewDetail),
              ),
              if (status == 'pending') ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _showRejectDialog(application),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: Text(l10n.reject),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _approveApplication(application),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.approve),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _approveApplication(Map<String, dynamic> application) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmApprove),
        content: Text(l10n.confirmApproveApplication(application['shopName'])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await ShopApplicationApi.approveApplication(application['id']);
                if (response.isSuccess) {
                  // 先刷新列表
                  await _loadApplications();
                  // 再刷新统计数据
                  if (mounted) {
                    await context.read<AppProvider>().loadPendingShopApplicationCount();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).reviewApproved)),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response.message ?? AppLocalizations.of(context).operationFailed)),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppLocalizations.of(context).operationFailed}: $e')),
                  );
                }
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> application) {
    final l10n = AppLocalizations.of(context);
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rejectApplication),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.shopName}：${application['shopName']}'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.rejectReason,
                hintText: l10n.pleaseEnterRejectReason,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).pleaseEnterRejectReason)),
                );
                return;
              }
              Navigator.pop(context);
              try {
                final response = await ShopApplicationApi.rejectApplication(
                  application['id'],
                  noteController.text.trim(),
                );
                if (response.isSuccess) {
                  // 先刷新列表
                  await _loadApplications();
                  // 再刷新统计数据
                  if (mounted) {
                    await context.read<AppProvider>().loadPendingShopApplicationCount();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).applicationRejected)),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response.message ?? AppLocalizations.of(context).operationFailed)),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppLocalizations.of(context).operationFailed}: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> application) {
    final l10n = AppLocalizations.of(context);
    final status = application['status'] as String;
    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'approved'
            ? Colors.green
            : Colors.red;
    final statusText = status == 'pending'
        ? l10n.pending
        : status == 'approved'
            ? l10n.approved
            : l10n.rejected;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shopApplicationDetail),
        content: SingleChildScrollView(
          child: Container(
            width: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailSection(l10n.basicInfo, [
                  _buildDetailRow(l10n.shopName, application['shopName'] ?? ''),
                  _buildDetailRow(l10n.mainBusiness, _getCategoryText(application['category'] ?? '', l10n)),
                  _buildDetailRow(l10n.applicationStatus, statusText, valueColor: statusColor),
                ]),
                const Divider(height: 32),
                _buildDetailSection(l10n.contactInfo, [
                  _buildDetailRow(l10n.username, application['username'] ?? ''),
                  _buildDetailRow(l10n.nickname, application['nickname'] ?? ''),
                  _buildDetailRow(l10n.contact, application['contactName'] ?? ''),
                  _buildDetailRow(l10n.contactPhone, application['contactPhone'] ?? ''),
                  _buildDetailRow(l10n.idNumber, application['idNumber'] ?? ''),
                  _buildDetailRow(l10n.inviteCode, application['inviteCode'] ?? ''),
                  _buildDetailRow(l10n.detailedAddress, application['address'] ?? ''),
                ]),
                const Divider(height: 32),
                _buildDetailSection(l10n.shopLogo, [
                  const SizedBox(height: 8),
                  _buildImagePreview(application['shopLogo']),
                ]),
                const Divider(height: 32),
                _buildDetailSection(l10n.idCredentials, [
                  const SizedBox(height: 8),
                  _buildIdCardImages(application),
                ]),
                if (application['reviewNote'] != null && application['reviewNote'].toString().isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildDetailSection(l10n.reviewNote, [
                    Text(
                      application['reviewNote'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                  ]),
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
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label：',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.grey[800],
                fontWeight: valueColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.store, size: 48, color: Colors.grey[400]),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        ImageUtil.getImageUrl(imageUrl),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.store, size: 48, color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildIdCardImages(Map<String, dynamic> application) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildIdCardImage(
            l10n.idFront,
            application['idFrontImage'],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildIdCardImage(
            l10n.idBack,
            application['idBackImage'],
          ),
        ),
      ],
    );
  }

  Widget _buildIdCardImage(String label, String? imageUrl) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (imageUrl != null && imageUrl.isNotEmpty) {
              _showImagePreviewDialog(imageUrl, label);
            }
          },
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: imageUrl == null || imageUrl.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noImage,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ImageUtil.getImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            l10n.imageLoadFailed,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showImagePreviewDialog(String imageUrl, String title) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    ImageUtil.getImageUrl(imageUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            l10n.imageLoadFailed,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
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
                        _loadApplications();
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
                        _loadApplications();
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
                  _loadApplications();
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
                  _loadApplications();
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
                _loadApplications();
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
        _loadApplications();
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
      _loadApplications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.pleaseEnterValidPage} (1-$_totalPages)')),
      );
    }
  }
}
