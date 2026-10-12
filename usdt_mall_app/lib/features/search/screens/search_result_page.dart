import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../home/widgets/mall_app_bar.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/chat_floating_button.dart';
import '../../../shared/widgets/responsive_app_bar.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';
import '../../../core/api/search_api.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/image_util.dart';
import '../../../shared/widgets/product_card_image.dart';
import '../../../core/l10n/app_localizations.dart';

/// 搜索结果页面
class SearchResultPage extends StatefulWidget {
  final String keyword;
  final int searchType; // 0: 商品, 1: 店铺

  const SearchResultPage({
    super.key,
    required this.keyword,
    required this.searchType,
  });

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  int _currentPage = 1; // 当前页码
  int _totalPages = 1; // 总页数
  int _itemsPerPage = 12; // 每页显示数量
  final List<int> _pageSizeOptions = [12, 24, 36, 48]; // 分页大小选项
  final TextEditingController _pageInputController = TextEditingController();

  // 搜索结果数据
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  int _totalRecords = 0;

  // 当前搜索的关键词和类型（用于判断是否需要重新搜索）
  String _currentKeyword = '';
  int _currentSearchType = 0;

  @override
  void initState() {
    super.initState();
    _currentKeyword = widget.keyword;
    _currentSearchType = widget.searchType;
    _loadSearchResults();
  }

  @override
  void didUpdateWidget(SearchResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当搜索关键词或搜索类型变化时，重新加载数据
    if (oldWidget.keyword != widget.keyword ||
        oldWidget.searchType != widget.searchType) {
      setState(() {
        _currentKeyword = widget.keyword;
        _currentSearchType = widget.searchType;
        _currentPage = 1;
      });
      _loadSearchResults();
    }
  }

  @override
  void dispose() {
    _pageInputController.dispose();
    super.dispose();
  }

  /// 处理搜索回调
  void _handleSearch(String keyword, int searchType) {
    // 更新 URL 以触发页面重建和状态同步
    context.go('/search?keyword=$keyword&type=$searchType');
  }

  /// 加载搜索结果
  Future<void> _loadSearchResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = _currentSearchType == 0
          ? await SearchApi.searchProducts(
              keyword: _currentKeyword,
              page: _currentPage,
              pageSize: _itemsPerPage,
            )
          : await SearchApi.searchShops(
              keyword: _currentKeyword,
              page: _currentPage,
              pageSize: _itemsPerPage,
            );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        setState(() {
          _results = List<Map<String, dynamic>>.from(data['list'] ?? []);
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
            SnackBar(
                content: Text(
                    '${l10n.translate('search_failed')}: ${response.errorMessage}')),
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
          SnackBar(content: Text('${l10n.translate('search_failed')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: isMobile
          ? ResponsiveAppBar(
              title: widget.searchType == 0
                  ? l10n.searchProducts
                  : l10n.searchShops,
            )
          : MallAppBar(
              initialKeyword: widget.keyword,
              initialSearchType: widget.searchType,
              onSearch: _handleSearch,
            ),
      body: SafeArea(
        child: AppBackground(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: ResponsiveUtil.getContentConstraints(context),
              height: double.infinity,
              color: Colors.white,
              child: _buildSearchResults(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? const MobileBottomNavV2() : null,
      floatingActionButton: !isMobile ? const ChatFloatingButton() : null,
    );
  }

  /// 构建标题
  Widget _buildTitle() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: Text(
        widget.searchType == 0
            ? l10n.translate('search_product_results')
            : l10n.translate('search_shop_results'),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 8),
                  widget.searchType == 0
                      ? _buildProductResults()
                      : _buildShopResults(),
                  const SizedBox(height: 24),
                  if (_results.isNotEmpty) _buildPagination(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建商品搜索结果
  Widget _buildProductResults() {
    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _results.map((product) {
        return _buildProductCard(product);
      }).toList(),
    );
  }

  /// 构建商品卡片
  Widget _buildProductCard(Map<String, dynamic> product) {
    return ProductSummaryCard(
      product: product,
      width: 200,
      nameSize: 13,
      priceSize: 14,
      onTap: () {
        context.push('/product/${product['id']}');
      },
    );
  }

  /// 构建店铺搜索结果
  Widget _buildShopResults() {
    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.start,
        children: _results.map((shop) {
          return _buildShopCard(shop);
        }).toList(),
      ),
    );
  }

  /// 构建店铺卡片
  Widget _buildShopCard(Map<String, dynamic> shop) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 店铺图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: shop['logo'] != null && shop['logo'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      ImageUtil.getImageUrl(shop['logo']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.store,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  )
                : Icon(
                    Icons.store,
                    size: 48,
                    color: Colors.grey[400],
                  ),
          ),
          const SizedBox(height: 12),
          // 店铺名称
          Text(
            shop['name'] ?? '',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // 进店按钮
          SizedBox(
            width: 80,
            child: ElevatedButton(
              onPressed: () {
                context.go('/shop/${shop['id']}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                l10n.translate('enter_shop'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分页组件
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
                        _loadSearchResults();
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
                        _loadSearchResults();
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
                  _loadSearchResults();
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
                  _loadSearchResults();
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
          l10n.perPage,
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
                _loadSearchResults();
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
    _loadSearchResults();
  }

  /// 构建页码按钮列表
  List<Widget> _buildPageNumbers() {
    List<Widget> pageButtons = [];

    int startPage = 1;
    int endPage = _totalPages;

    if (_totalPages > 7) {
      if (_currentPage <= 4) {
        startPage = 1;
        endPage = 5;
      } else if (_currentPage >= _totalPages - 3) {
        startPage = _totalPages - 4;
        endPage = _totalPages;
      } else {
        startPage = _currentPage - 2;
        endPage = _currentPage + 2;
      }
    }

    if (startPage > 1) {
      pageButtons.add(_buildPageNumberButton(1));
      if (startPage > 2) {
        pageButtons.add(_buildEllipsis());
      }
      pageButtons.add(const SizedBox(width: 4));
    }

    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(_buildPageNumberButton(i));
      if (i < endPage) {
        pageButtons.add(const SizedBox(width: 4));
      }
    }

    if (endPage < _totalPages) {
      pageButtons.add(const SizedBox(width: 4));
      if (endPage < _totalPages - 1) {
        pageButtons.add(_buildEllipsis());
      }
      pageButtons.add(_buildPageNumberButton(_totalPages));
    }

    return pageButtons;
  }

  /// 构建单个页码按钮
  Widget _buildPageNumberButton(int pageNumber) {
    final isActive = pageNumber == _currentPage;

    return InkWell(
      onTap: () {
        setState(() {
          _currentPage = pageNumber;
        });
        _loadSearchResults();
      },
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
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : Colors.black87,
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
      child: Center(
        child: Text(
          '...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 构建翻页按钮
  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onPressed != null ? Colors.white : Colors.grey[100],
          border: Border.all(
            color: onPressed != null ? Colors.grey[300]! : Colors.grey[200]!,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null ? Colors.black87 : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  /// 构建空数据状态
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('no_data_found'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
