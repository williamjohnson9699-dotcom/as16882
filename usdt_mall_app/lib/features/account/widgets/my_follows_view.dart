import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/shop_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';

/// 我的关注视图
class MyFollowsView extends StatefulWidget {
  const MyFollowsView({super.key});

  @override
  State<MyFollowsView> createState() => _MyFollowsViewState();
}

class _MyFollowsViewState extends State<MyFollowsView> {
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 20;
  final List<int> _pageSizeOptions = [20, 40, 60, 80];
  final TextEditingController _pageInputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _shops = [];
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _loadFollows();
  }

  @override
  void dispose() {
    _pageInputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 加载关注列表
  Future<void> _loadFollows() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ShopApi.getMyFollows(
        keyword: _keyword,
        page: _currentPage,
        pageSize: _itemsPerPage,
      );
      if (response.isSuccess && response.data != null) {
        final records = response.data?['records'] as List?;
        final total = response.data?['total'] ?? 0;
        setState(() {
          _shops = records?.cast<Map<String, dynamic>>() ?? [];
          _totalPages = (total / _itemsPerPage).ceil();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 搜索
  void _handleSearch() {
    setState(() {
      _keyword = _searchController.text.trim();
      _currentPage = 1;
    });
    _loadFollows();
  }

  /// 取消关注
  Future<void> _handleUnfollow(String shopId, String shopName) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmUnfollow),
        content: Text(l10n.confirmUnfollowShop(shopName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ShopApi.unfollowShop(shopId);
      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.unfollowedSuccess)),
          );
        }
        _loadFollows();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.operationFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.operationFailed}: $e')),
        );
      }
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
              l10n.myFollows,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
          ],
          _buildSearchBar(),
          const SizedBox(height: 24),
          Expanded(child: _buildShopList()),
        ],
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchShopName,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _handleSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: Text(l10n.search),
        ),
      ],
    );
  }

  /// 构建店铺列表
  Widget _buildShopList() {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_shops.isEmpty) {
      return Center(
        child: Text(l10n.noFollowedShops, style: const TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _shops.length,
            itemBuilder: (context, index) => _buildShopItem(_shops[index]),
          ),
        ),
        const SizedBox(height: 16),
        _buildPagination(),
      ],
    );
  }

  /// 构建店铺项
  Widget _buildShopItem(Map<String, dynamic> shop) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    final shopId = shop['id']?.toString() ?? '';
    final shopName = shop['name'] ?? '';
    final shopLogo = shop['logo'];
    final shopLevel = shop['level'] ?? 0;
    final shopRating = shop['rating'] ?? 0.0;
    final followCount = shop['followCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上部分：店铺图标和信息
                Row(
                  children: [
                    // 店铺图标
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: shopLogo != null && shopLogo.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                ImageUtil.getImageUrl(shopLogo),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.store, size: 30, color: Colors.grey[400]),
                              ),
                            )
                          : Icon(Icons.store, size: 30, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 12),
                    // 店铺信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  shopName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.star, size: 14, color: Colors.amber[700]),
                              const SizedBox(width: 2),
                              Text(
                                l10n.shopLevel(shopLevel),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${l10n.rating}: ${shopRating.toStringAsFixed(1)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${l10n.follow}: $followCount',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 下部分：操作按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.go('/shop/$shopId');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(l10n.visitShop, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleUnfollow(shopId, shopName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(l10n.unfollow, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                // 店铺图标
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: shopLogo != null && shopLogo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ImageUtil.getImageUrl(shopLogo),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.store, size: 30, color: Colors.grey[400]),
                          ),
                        )
                      : Icon(Icons.store, size: 30, color: Colors.grey[400]),
                ),
                const SizedBox(width: 16),
                // 店铺信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            shopName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star, size: 16, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            l10n.shopLevel(shopLevel),
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${l10n.rating}: ${shopRating.toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${l10n.follow}: $followCount',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 操作按钮
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        context.go('/shop/$shopId');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(l10n.visitShop),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleUnfollow(shopId, shopName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(l10n.unfollow),
                    ),
                  ],
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
            '${l10n.total} ${_shops.length} ${l10n.items}',
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
                        _loadFollows();
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
                        _loadFollows();
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
                  _loadFollows();
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
                  _loadFollows();
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
                _loadFollows();
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
        _loadFollows();
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
    _loadFollows();
  }
}
