import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/product_management_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/date_util.dart';
import 'product_image_upload_dialog.dart';

/// 商品管理视图
class ProductManagementView extends StatefulWidget {
  const ProductManagementView({super.key});

  @override
  State<ProductManagementView> createState() => _ProductManagementViewState();
}

class _ProductManagementViewState extends State<ProductManagementView> {
  final _searchController = TextEditingController();
  final _pageInputController = TextEditingController();
  String _selectedCategory = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 10;
  final List<int> _pageSizeOptions = [10, 20, 30, 50];

  // 商品数据列表
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  int _totalRecords = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  /// 加载商品数据
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProductManagementApi.getProductList(
        keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        page: _currentPage,
        pageSize: _itemsPerPage,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        setState(() {
          _products = List<Map<String, dynamic>>.from(data['list'] ?? []);
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
            SnackBar(content: Text('${l10n.translate('load_failed')}: ${response.errorMessage}')),
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

  /// 处理搜索
  void _handleSearch() {
    setState(() {
      _currentPage = 1;
    });
    _loadProducts();
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
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) _buildHeader(l10n, isMobile),
              if (!isMobile) const SizedBox(height: 24),
              _buildSearchAndFilter(l10n),
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildProductTable(l10n)),
                    if (!_isLoading && _products.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPagination(l10n),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // 移动端浮动按钮
        if (isMobile)
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton(
              onPressed: _showAddProductDialog,
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  /// 构建头部
  Widget _buildHeader(AppLocalizations l10n, bool isMobile) {
    if (isMobile) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showAddProductDialog,
          icon: const Icon(Icons.add),
          label: Text(l10n.translate('add_product')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.productManagement,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddProductDialog,
          icon: const Icon(Icons.add),
          label: Text(l10n.translate('add_product')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// 构建搜索和筛选
  Widget _buildSearchAndFilter(AppLocalizations l10n) {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          // 分类筛选
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: l10n.categoryFilter,
              labelStyle: TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            items: [
              DropdownMenuItem(value: 'all', child: Text(l10n.allCategories, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '生活', child: Text(l10n.life, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '男鞋', child: Text(l10n.menShoes, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '女鞋', child: Text(l10n.womenShoes, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '配饰', child: Text(l10n.accessories, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '男装', child: Text(l10n.menClothing, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '女装', child: Text(l10n.womenClothing, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '男包', child: Text(l10n.menBags, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '女包', child: Text(l10n.womenBags, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '男童', child: Text(l10n.boyClothing, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '女童', child: Text(l10n.girlClothing, style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '全球购', child: Text(l10n.globalShopping, style: TextStyle(fontSize: 13))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
                _currentPage = 1;
              });
              _loadProducts();
            },
          ),
          const SizedBox(height: 12),
          // 搜索框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchProductHint,
                    hintStyle: TextStyle(fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 20),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: TextStyle(fontSize: 13),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: Text(l10n.search, style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: l10n.categoryFilter,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: [
              DropdownMenuItem(value: 'all', child: Text(l10n.allCategories)),
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
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
                _currentPage = 1;
              });
              _loadProducts();
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchProductHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: Text(l10n.search),
        ),
      ],
    );
  }

  /// 构建商品表格
  Widget _buildProductTable(AppLocalizations l10n) {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 32 : 40),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_products.isEmpty) {
      return _buildEmptyState(l10n);
    }

    if (isMobile) {
      // 移动端：卡片列表
      return ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) => _buildProductCard(_products[index], l10n),
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
          _buildTableHeader(l10n),
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) => _buildTableRow(_products[index], l10n),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建表格头部
  Widget _buildTableHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _buildHeaderCell(l10n.image, flex: 1),
          const SizedBox(width: 16),
          _buildHeaderCell(l10n.productName, flex: 2),
          _buildHeaderCell(l10n.category, flex: 1),
          _buildHeaderCell(l10n.price, flex: 1),
          _buildHeaderCell(l10n.stock, flex: 1),
          _buildHeaderCell(l10n.sales, flex: 1),
          _buildHeaderCell(l10n.status, flex: 1),
          const SizedBox(width: 16),
          _buildHeaderCell(l10n.listingDate, flex: 1),
          _buildHeaderCell(l10n.actions, flex: 2),
        ],
      ),
    );
  }

  /// 构建表头单元格
  Widget _buildHeaderCell(String text, {int flex = 1}) {
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
  Widget _buildEmptyState(AppLocalizations l10n) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: isMobile ? 40 : 48, color: Colors.grey[400]),
            SizedBox(height: isMobile ? 10 : 12),
            Text(
              l10n.noProductData,
              style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建商品卡片（移动端）
  Widget _buildProductCard(Map<String, dynamic> product, AppLocalizations l10n) {
    final mainImage = product['mainImage'] as String?;
    final isActive = product['status'] == 'active';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品图片
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: mainImage != null && mainImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          ImageUtil.getImageUrl(mainImage),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.broken_image, color: Colors.grey[400], size: 24);
                          },
                        ),
                      )
                    : Icon(Icons.image, color: Colors.grey[400], size: 24),
              ),
              const SizedBox(width: 12),
              // 商品信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCategoryText(product['category'], l10n),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // 状态标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[600] : Colors.grey[600],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? l10n.active : l10n.inactive,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 价格、库存、销量
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${double.parse(product['price'].toString()).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.stock}: ${product['stock']} | ${l10n.sales}: ${product['sales']}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                DateUtil.formatDate(DateUtil.parseAsLocalDateTime(product['createTime'])),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showProductDetails(product),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    side: BorderSide(color: Colors.blue[600]!),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(l10n.more, style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showEditProductDialog(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(l10n.edit, style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _handleDeleteProduct(product),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red[600],
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建表格行
  Widget _buildTableRow(Map<String, dynamic> product, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          _buildImageCell(product, flex: 1),
          const SizedBox(width: 16),
          _buildCell(product['name'], flex: 2),
          _buildCell(_getCategoryText(product['category'], l10n), flex: 1),
          _buildCell('\$${double.parse(product['price'].toString()).toStringAsFixed(2)}', flex: 1),
          _buildCell(product['stock'].toString(), flex: 1),
          _buildCell(product['sales'].toString(), flex: 1),
          _buildStatusCell(product['status'], l10n, flex: 1),
          const SizedBox(width: 16),
          _buildCell(DateUtil.formatDate(DateUtil.parseAsLocalDateTime(product['createTime'])), flex: 1),
          _buildActionCell(product, l10n),
        ],
      ),
    );
  }

  /// 构建图片单元格
  Widget _buildImageCell(Map<String, dynamic> product, {int flex = 1}) {
    final mainImage = product['mainImage'] as String?;
    return Expanded(
      flex: flex,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: mainImage != null && mainImage.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  ImageUtil.getImageUrl(mainImage),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.broken_image, color: Colors.grey[400]);
                  },
                ),
              )
            : Icon(Icons.image, color: Colors.grey[400]),
      ),
    );
  }

  /// 构建单元格
  Widget _buildCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[800])),
    );
  }

  /// 构建状态单元格
  Widget _buildStatusCell(String status, AppLocalizations l10n, {int flex = 1}) {
    final isActive = status == 'active';
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.green[600] : Colors.grey[600],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isActive ? l10n.active : l10n.inactive,
          style: const TextStyle(fontSize: 12, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 构建操作单元格
  Widget _buildActionCell(Map<String, dynamic> product, AppLocalizations l10n) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          TextButton(
            onPressed: () => _showProductDetails(product),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.more, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => _showEditProductDialog(product),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.edit, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => _handleDeleteProduct(product),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.delete, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  /// 显示添加商品对话框
  void _showAddProductDialog() {
    final l10n = AppLocalizations.of(context);
    List<Map<String, dynamic>> products = [
      {'name': '', 'category': 'life', 'price': '', 'stock': '', 'description': '', 'images': <String>[]}
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.addProduct),
              TextButton.icon(
                onPressed: () {
                  if (products.length >= 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.translate('max_100_products'))),
                    );
                    return;
                  }
                  setDialogState(() {
                    products.add({'name': '', 'category': 'life', 'price': '', 'stock': '', 'description': '', 'images': <String>[]});
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.translate('add_more_product')),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            height: 600,
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) => _buildProductForm(context, products, index, setDialogState, l10n),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => _submitBatchProducts(products),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示商品详情
  void _showProductDetails(Map<String, dynamic> product) {
    final l10n = AppLocalizations.of(context);
    final mainImage = product['mainImage'] as String?;
    final images = product['images'] as List?;
    final description = product['description'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.productDetail),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 主图
                if (mainImage != null && mainImage.isNotEmpty) ...[
                  Text('${l10n.mainImage}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ImageUtil.getImageUrl(mainImage),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // 所有图片
                if (images != null && images.isNotEmpty) ...[
                  Text('${l10n.allImages}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: images.map((imageUrl) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ImageUtil.getImageUrl(imageUrl.toString()),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.broken_image, size: 24, color: Colors.grey[400]),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('${l10n.productName}: ${product['name']}'),
                const SizedBox(height: 8),
                Text('${l10n.category}: ${_getCategoryText(product['category'], l10n)}'),
                const SizedBox(height: 8),
                Text('${l10n.price}: \$${double.parse(product['price'].toString()).toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text('${l10n.stock}: ${product['stock']}'),
                const SizedBox(height: 8),
                Text('${l10n.sales}: ${product['sales']}'),
                const SizedBox(height: 8),
                Text('${l10n.views}: ${product['views'] ?? 0}'),
                const SizedBox(height: 8),
                Text('${l10n.status}: ${product['status'] == 'active' ? l10n.active : l10n.inactive}'),
                const SizedBox(height: 8),
                Text('${l10n.listingDate}: ${DateUtil.formatDate(DateUtil.parseAsLocalDateTime(product['createTime']))}'),
                // 商品说明
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('${l10n.productDescriptionLabel}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
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

  /// 显示编辑商品对话框
  void _showEditProductDialog(Map<String, dynamic> product) {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    String name = product['name'];
    String category = product['category'];
    String price = product['price'];
    String stock = product['stock'].toString();
    String sales = product['sales']?.toString() ?? '0';
    String views = product['views']?.toString() ?? '0';
    String status = product['status'];
    String description = product['description'] ?? '';
    List<String> imageUrls = List<String>.from(product['images'] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        String selectedStatus = status;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('${l10n.edit} ${l10n.translate('product')}'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: name,
                        decoration: InputDecoration(
                          labelText: l10n.productName,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? l10n.pleaseEnterProductName : null,
                        onSaved: (value) => name = value!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: InputDecoration(
                          labelText: l10n.productCategory,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
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
                        onChanged: (value) => category = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: price,
                        decoration: InputDecoration(
                          labelText: l10n.productPrice,
                          border: const OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return l10n.pleaseEnterProductPrice;
                          if (double.tryParse(value!) == null) return l10n.pleaseEnterValidPrice;
                          return null;
                        },
                        onSaved: (value) => price = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: stock,
                        decoration: InputDecoration(
                          labelText: l10n.stockQuantity,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return l10n.pleaseEnterStockQuantity;
                          final intValue = int.tryParse(value!);
                          if (intValue == null) return l10n.pleaseEnterValidInteger;
                          if (intValue < 0) return l10n.quantityCannotBeNegative;
                          return null;
                        },
                        onSaved: (value) => stock = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: sales,
                        decoration: InputDecoration(
                          labelText: l10n.sales,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return '请输入销量';
                          final intValue = int.tryParse(value!);
                          if (intValue == null) return l10n.pleaseEnterValidInteger;
                          if (intValue < 0) return l10n.quantityCannotBeNegative;
                          return null;
                        },
                        onSaved: (value) => sales = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: views,
                        decoration: InputDecoration(
                          labelText: l10n.views,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return '请输入浏览量';
                          final intValue = int.tryParse(value!);
                          if (intValue == null) return l10n.pleaseEnterValidInteger;
                          if (intValue < 0) return l10n.quantityCannotBeNegative;
                          return null;
                        },
                        onSaved: (value) => views = value!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: l10n.productStatus,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 'active', child: Text(l10n.active)),
                          DropdownMenuItem(value: 'inactive', child: Text(l10n.inactive)),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedStatus = value!);
                          status = value!;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: description,
                        decoration: InputDecoration(
                          labelText: l10n.productDescriptionLabel,
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        minLines: 5,
                        validator: (value) => value?.isEmpty ?? true ? l10n.pleaseEnterProductDescription : null,
                        onSaved: (value) => description = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setImageState) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(l10n.productImagesMax5),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    if (imageUrls.length >= 5) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.max5Images)),
                                      );
                                      return;
                                    }
                                    _showAddImageUrlDialog(context, (urls) {
                                      setImageState(() {
                                        imageUrls.addAll(urls);
                                        // 确保不超过5张
                                        if (imageUrls.length > 5) {
                                          imageUrls = imageUrls.sublist(0, 5);
                                        }
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                                  label: Text(l10n.addImage),
                                ),
                              ],
                            ),
                            if (imageUrls.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: imageUrls.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final url = entry.value;
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            ImageUtil.getImageUrl(url),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(Icons.broken_image, color: Colors.grey),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -8,
                                        right: -8,
                                        child: IconButton(
                                          icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                          onPressed: () {
                                            setImageState(() {
                                              imageUrls.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();

                    try {
                      final response = await ProductManagementApi.updateProduct(
                        productId: product['id'].toString(),
                        name: name,
                        category: category,
                        price: price,
                        stock: int.parse(stock),
                        sales: int.parse(sales),
                        views: int.parse(views),
                        status: status,
                        description: description.isEmpty ? null : description,
                        images: imageUrls.isEmpty ? null : imageUrls,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        final l10nInner = AppLocalizations.of(context);
                        if (response.isSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10nInner.productUpdatedSuccess)),
                          );
                          _loadProducts();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${l10nInner.updateFailed}: ${response.errorMessage}')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.pop(context);
                        final l10nInner = AppLocalizations.of(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${l10nInner.updateFailed}: $e')),
                        );
                      }
                    }
                  }
                },
                child: Text(l10n.confirm),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 处理删除商品
  void _handleDeleteProduct(Map<String, dynamic> product) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text('${l10n.confirmDeleteProduct}"${product['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final response = await ProductManagementApi.deleteProduct(
                  product['id'].toString(),
                );

                if (mounted) {
                  final l10nInner = AppLocalizations.of(context);
                  if (response.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10nInner.productDeleteSuccess)),
                    );
                    _loadProducts();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10nInner.deleteFailed}: ${response.errorMessage}')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  final l10nInner = AppLocalizations.of(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10nInner.deleteFailed}: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  /// 显示添加图片对话框
  void _showAddImageUrlDialog(BuildContext context, Function(List<String>) onAdd) {
    showDialog(
      context: context,
      builder: (context) => ProductImageUploadDialog(
        onImagesSelected: (List<String> imageUrls) => onAdd(imageUrls),
      ),
    );
  }

  /// 构建分页栏
  Widget _buildPagination(AppLocalizations l10n) {
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
        _buildPageSizeSelector(l10n),
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
        _buildPageInput(l10n),
      ],
    );
  }

  /// 构建分页大小选择器
  Widget _buildPageSizeSelector(AppLocalizations l10n) {
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
        _loadProducts();
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
  Widget _buildPageInput(AppLocalizations l10n) {
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

  Widget _buildProductForm(BuildContext context, List<Map<String, dynamic>> products, int index, StateSetter setState, AppLocalizations l10n) {
    final product = products[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.translate('product')} ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (products.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => setState(() => products.removeAt(index)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: l10n.productName, border: const OutlineInputBorder()),
              onChanged: (v) => product['name'] = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: product['category'],
              decoration: InputDecoration(labelText: l10n.productCategory, border: const OutlineInputBorder()),
              items: [
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
              onChanged: (v) => product['category'] = v!,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: l10n.productPrice, border: const OutlineInputBorder(), prefixText: '\$'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              onChanged: (v) => product['price'] = v,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: l10n.stockQuantity, border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => product['stock'] = v,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: l10n.productDescriptionLabel, border: const OutlineInputBorder()),
              maxLines: 3,
              onChanged: (v) => product['description'] = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(l10n.productImagesMax5),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    if ((product['images'] as List).length >= 5) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.max5Images)));
                      return;
                    }
                    _showAddImageUrlDialog(context, (urls) {
                      setState(() {
                        (product['images'] as List).addAll(urls);
                        if ((product['images'] as List).length > 5) {
                          product['images'] = (product['images'] as List).sublist(0, 5);
                        }
                      });
                    });
                  },
                  icon: const Icon(Icons.add_photo_alternate, size: 18),
                  label: Text(l10n.addImage),
                ),
              ],
            ),
            if ((product['images'] as List).isNotEmpty)
              Wrap(
                spacing: 8,
                children: (product['images'] as List).asMap().entries.map((e) {
                  return Stack(
                    children: [
                      Image.network(ImageUtil.getImageUrl(e.value), width: 60, height: 60, fit: BoxFit.cover),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.red),
                          onPressed: () => setState(() => (product['images'] as List).removeAt(e.key)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBatchProducts(List<Map<String, dynamic>> products) async {
    final l10n = AppLocalizations.of(context);

    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      if (p['name'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('product')} ${i + 1}: ${l10n.pleaseEnterProductName}')),
        );
        return;
      }
      if (p['price'].toString().trim().isEmpty || double.tryParse(p['price']) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('product')} ${i + 1}: ${l10n.pleaseEnterValidPrice}')),
        );
        return;
      }
      if (p['stock'].toString().trim().isEmpty || int.tryParse(p['stock']) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('product')} ${i + 1}: ${l10n.pleaseEnterStockQuantity}')),
        );
        return;
      }
    }

    try {
      final productList = products.map((p) => {
        'name': p['name'],
        'category': p['category'],
        'price': p['price'],
        'stock': int.parse(p['stock']),
        'description': p['description'].toString().isEmpty ? null : p['description'],
        'images': (p['images'] as List).isEmpty ? null : p['images'],
      }).toList();

      final response = await ProductManagementApi.batchAddProduct(products: productList);

      if (mounted) {
        Navigator.pop(context);
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.translate('batch_add_success')}: ${products.length}')),
          );
          _loadProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.addFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.addFailed}: $e')),
        );
      }
    }
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
        SnackBar(content: Text('${l10n.pageRangeLabel}: 1-$_totalPages')),
      );
      return;
    }

    setState(() {
      _currentPage = pageNumber;
    });
    _loadProducts();
    _pageInputController.clear();
  }
}
