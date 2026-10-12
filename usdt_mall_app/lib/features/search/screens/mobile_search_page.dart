import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/search_api.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/product_card_image.dart';
import '../../../shared/widgets/responsive_app_bar.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';

/// 移动端搜索页面
class MobileSearchPage extends StatefulWidget {
  const MobileSearchPage({super.key});

  @override
  State<MobileSearchPage> createState() => _MobileSearchPageState();
}

class _MobileSearchPageState extends State<MobileSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _searchType = 0; // 0: 搜商品, 1: 搜店铺
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 执行搜索
  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = _searchType == 0
          ? await SearchApi.searchProducts(
              keyword: keyword,
              page: 1,
              pageSize: 20,
            )
          : await SearchApi.searchShops(
              keyword: keyword,
              page: 1,
              pageSize: 20,
            );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        setState(() {
          _results = List<Map<String, dynamic>>.from(data['list'] ?? []);
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
                content:
                    Text('${l10n.operationFailed}: ${response.errorMessage}')),
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
          SnackBar(content: Text('${l10n.operationFailed}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: ResponsiveAppBar(
        title: l10n.search,
        showMenu: false,
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),
          // 搜索结果
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
      bottomNavigationBar: const MobileBottomNavV2(),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // 搜索输入框
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _searchType == 0
                          ? l10n.searchProducts
                          : l10n.searchShops,
                      hintStyle:
                          TextStyle(fontSize: 14, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _results = [];
                        _hasSearched = false;
                      });
                    },
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 搜索类型和搜索按钮
          Row(
            children: [
              // 搜索类型按钮
              _buildSearchTypeButton(l10n.searchProducts, 0),
              const SizedBox(width: 8),
              _buildSearchTypeButton(l10n.searchShops, 1),
              const Spacer(),
              // 搜索按钮
              ElevatedButton(
                onPressed: _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(l10n.search),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建搜索类型按钮
  Widget _buildSearchTypeButton(String label, int type) {
    final isSelected = _searchType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _searchType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.blue[700] : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 构建搜索结果
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_results.isEmpty) {
      return _buildNoResultsState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _searchType == 0 ? _buildProductResults() : _buildShopResults(),
    );
  }

  /// 构建商品搜索结果
  Widget _buildProductResults() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const spacing = 12.0;
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
          itemCount: _results.length,
          itemBuilder: (context, index) {
            return _buildProductCard(_results[index]);
          },
        );
      },
    );
  }

  /// 构建商品卡片
  Widget _buildProductCard(Map<String, dynamic> product) {
    return ProductSummaryCard(
      product: product,
      nameSize: 13,
      priceSize: 14,
      onTap: () {
        context.push('/product/${product['id']}');
      },
    );
  }

  /// 构建店铺搜索结果
  Widget _buildShopResults() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return _buildShopCard(_results[index]);
      },
    );
  }

  /// 构建店铺卡片
  Widget _buildShopCard(Map<String, dynamic> shop) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // 店铺图标
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: shop['logo'] != null && shop['logo'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ImageUtil.getImageUrl(shop['logo']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.store, size: 32, color: Colors.grey[400]),
                    ),
                  )
                : Icon(Icons.store, size: 32, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          // 店铺信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.shopLevel(shop['level'] ?? 0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 进店按钮
          ElevatedButton(
            onPressed: () {
              context.push('/shop/${shop['id']}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(l10n.visitShop),
          ),
        ],
      ),
    );
  }

  /// 构建空状态（未搜索）
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('please_enter_search_keyword'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建无结果状态
  Widget _buildNoResultsState() {
    return Center(
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
            '未找到数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
