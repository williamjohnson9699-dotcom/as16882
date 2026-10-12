import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../home/widgets/mall_app_bar.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/chat_floating_button.dart';
import '../../../shared/widgets/responsive_app_bar.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';
import '../../../core/api/category_api.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../shared/widgets/product_card_image.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/providers/auth_provider.dart';

/// 分类商品页面
class CategoryPage extends StatefulWidget {
  final String categoryKey;

  const CategoryPage({
    super.key,
    required this.categoryKey,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  int _currentPage = 1; // 当前页码
  int _totalPages = 1; // 总页数
  int _totalRecords = 0; // 总记录数
  int _itemsPerPage = 20; // 每页显示数量
  final List<int> _pageSizeOptions = [20, 40, 60, 80]; // 分页大小选项
  final TextEditingController _pageInputController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  int? _categoryId;

  /// 根据分类 key 获取翻译后的名称
  String _getCategoryName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoryNameMap = {
      'hot-sale': l10n.hotSale,
      'life': l10n.life,
      'man-shoes': l10n.menShoes,
      'woman-shoes': l10n.womenShoes,
      'accessories': l10n.accessories,
      'man-clothing': l10n.menClothing,
      'woman-clothing': l10n.womenClothing,
      'man-bags': l10n.menBags,
      'woman-bags': l10n.womenBags,
      'boy-clothing': l10n.boyClothing,
      'girl-clothing': l10n.girlClothing,
      'global-shopping': l10n.globalShopping,
    };
    return categoryNameMap[widget.categoryKey] ?? widget.categoryKey;
  }

  /// 根据分类 key 获取对应的中文名称（用于 API 调用）
  String _getCategoryNameForApi() {
    final categoryApiNameMap = {
      'hot-sale': '热销',
      'life': '生活',
      'man-shoes': '男鞋',
      'woman-shoes': '女鞋',
      'accessories': '配饰',
      'man-clothing': '男装',
      'woman-clothing': '女装',
      'man-bags': '男包',
      'woman-bags': '女包',
      'boy-clothing': '男童',
      'girl-clothing': '女童',
      'global-shopping': '全球购',
    };
    return categoryApiNameMap[widget.categoryKey] ?? widget.categoryKey;
  }

  @override
  void initState() {
    super.initState();
    _loadCategoryId();
  }

  @override
  void dispose() {
    _pageInputController.dispose();
    super.dispose();
  }

  /// 加载分类ID
  Future<void> _loadCategoryId() async {
    // 热销商品不需要分类ID，直接加载商品
    if (widget.categoryKey == 'hot-sale') {
      _loadProducts();
      return;
    }

    try {
      final response = await CategoryApi.getAllCategories();
      if (response.isSuccess && response.data != null) {
        final categories = response.data as List;
        final apiCategoryName = _getCategoryNameForApi();
        final category = categories.firstWhere(
          (c) => c['name'] == apiCategoryName,
          orElse: () => null,
        );
        if (category != null) {
          setState(() {
            _categoryId = category['id'];
          });
          _loadProducts();
        }
      }
    } catch (e) {
      // 加载失败
    }
  }

  /// 加载商品列表
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 热销商品使用专门的API
      if (widget.categoryKey == 'hot-sale') {
        final response = await CategoryApi.getHotProducts(
          page: _currentPage,
          pageSize: _itemsPerPage,
        );
        if (response.isSuccess && response.data != null) {
          final records = response.data?['records'] as List?;
          final total = response.data?['total'] ?? 0;
          setState(() {
            _products = records?.cast<Map<String, dynamic>>() ?? [];
            _totalRecords = total;
            _totalPages = (total / _itemsPerPage).ceil();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // 其他分类使用分类ID查询
      if (_categoryId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await CategoryApi.getProductsByCategory(
        _categoryId!,
        page: _currentPage,
        pageSize: _itemsPerPage,
      );
      if (response.isSuccess && response.data != null) {
        final records = response.data?['records'] as List?;
        final total = response.data?['total'] ?? 0;
        setState(() {
          _products = records?.cast<Map<String, dynamic>>() ?? [];
          _totalRecords = total;
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

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    final categoryName = _getCategoryName(context);

    // 临时调试：打印路由信息
    if (isMobile) {
      final router = GoRouter.of(context);
      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      debugPrint('========== 分类页面 ==========');
      debugPrint('当前路由: $location');
      debugPrint('分类名称: $categoryName');
      debugPrint('============================');
    }

    return Scaffold(
      appBar:
          isMobile ? ResponsiveAppBar(title: categoryName) : const MallAppBar(),
      body: SafeArea(
        child: AppBackground(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: ResponsiveUtil.getContentConstraints(context),
              color: Colors.white,
              child: isMobile
                  ? Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitle(),
                                const SizedBox(height: 8),
                                _buildProductGrid(),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: _buildPagination(),
                        ),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final padding = 24.0;
                        return Padding(
                          padding: EdgeInsets.all(padding),
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    constraints.maxHeight - (padding * 2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTitle(),
                                  const SizedBox(height: 8),
                                  _buildProductGrid(),
                                  const SizedBox(height: 24),
                                  _buildPagination(),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
    final categoryName = _getCategoryName(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 前置图片
          Image.asset(
            'assets/pic/pre_title.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          // 标题文字
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 8),
          // 后置图片
          Image.asset(
            'assets/pic/post_title.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  /// 构建商品网格
  Widget _buildProductGrid() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_products.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            l10n.noProducts,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final isMobile = ResponsiveUtil.isMobile(context);
    final crossAxisCount = isMobile ? 2 : 5;
    final spacing = isMobile ? 12.0 : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: ProductCardMetrics.gridAspectRatio(
              maxWidth: constraints.maxWidth,
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
            ),
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(_products[index]);
          },
        );
      },
    );
  }

  /// 构建商品卡片
  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['id']?.toString() ?? '';

    return ProductSummaryCard(
      product: product,
      onTap: () {
        context.push('/product/$productId');
      },
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
                        _loadProducts();
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
                        _loadProducts();
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
                  _loadProducts();
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
                  _loadProducts();
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
                _loadProducts();
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
    _loadProducts();
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
        _loadProducts();
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
    return SizedBox(
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
}
