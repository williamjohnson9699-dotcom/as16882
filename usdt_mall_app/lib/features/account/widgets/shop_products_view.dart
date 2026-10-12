import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/shop_product_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';
import 'product_image_upload_dialog.dart';

/// 店铺商品视图
class ShopProductsView extends StatefulWidget {
  const ShopProductsView({super.key});

  @override
  State<ShopProductsView> createState() => _ShopProductsViewState();
}

class _ShopProductsViewState extends State<ShopProductsView> {
  String _selectedCategory = 'all';
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemsPerPage = 12;
  final List<int> _pageSizeOptions = [12, 24, 36, 48];
  final TextEditingController _pageInputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  int _totalRecords = 0;
  bool _isAddMode = false; // 添加视图模式

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _pageInputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 加载商品数据
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final keyword = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
      final category = _selectedCategory == 'all' ? null : _selectedCategory;

      final response = _isAddMode
          ? await ShopProductApi.getAllProductList(
              keyword: keyword,
              category: category,
              page: _currentPage,
              pageSize: _itemsPerPage,
            )
          : await ShopProductApi.getProductList(
              keyword: keyword,
              category: category,
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

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildCategoryTabs(),
          const SizedBox(height: 24),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final l10n = AppLocalizations.of(context);

    if (isMobile) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.shopProducts,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            // 添加商品按钮
            if (false)
              ElevatedButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add),
                label: Text(l10n.translate('add_product')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            if (false) const SizedBox(width: 12),
            Text(
              _isAddMode ? l10n.translate('add_view') : l10n.translate('product_management'),
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _isAddMode,
              onChanged: (value) {
                setState(() {
                  _isAddMode = value;
                  _currentPage = 1;
                  if (_isAddMode) {
                    _selectedCategory = 'all';
                  }
                });
                _loadProducts();
              },
              activeColor: Colors.blue[700],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.translate('search_product_name'),
              hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
              prefixIcon: Icon(Icons.search, size: isMobile ? 20 : 24),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: isMobile ? 18 : 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                        _loadProducts();
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
            onSubmitted: (value) => _loadProducts(),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 16),
        ElevatedButton.icon(
          onPressed: _loadProducts,
          icon: Icon(Icons.search, size: isMobile ? 18 : 20),
          label: Text(l10n.search, style: TextStyle(fontSize: isMobile ? 13 : 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isMobile ? 10 : 16,
            ),
          ),
        ),
        if (isMobile) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isAddMode ? l10n.translate('add_view') : l10n.translate('product_management'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                Switch(
                  value: _isAddMode,
                  onChanged: (value) {
                    setState(() {
                      _isAddMode = value;
                      _currentPage = 1;
                      if (_isAddMode) {
                        _selectedCategory = 'all';
                      }
                    });
                    _loadProducts();
                  },
                  activeColor: Colors.blue[700],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryTabs() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    final categories = [l10n.all, l10n.life, l10n.menShoes, l10n.womenShoes, l10n.accessories, l10n.menClothing, l10n.womenClothing, l10n.menBags, l10n.womenBags, l10n.boyClothing, l10n.girlClothing, l10n.globalShopping];
    final categoryKeys = ['all', '生活', '男鞋', '女鞋', '配饰', '男装', '女装', '男包', '女包', '男童', '女童', '全球购'];

    return Wrap(
      spacing: isMobile ? 8 : 12,
      runSpacing: isMobile ? 8 : 12,
      children: List.generate(categories.length, (index) {
        final isSelected = _selectedCategory == categoryKeys[index];
        return InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = categoryKeys[index];
              _currentPage = 1;
            });
            _loadProducts();
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: isMobile ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[700] : Colors.grey[100],
              borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            ),
            child: Text(
              categories[index],
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProductGrid() {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 4,
                        crossAxisSpacing: isMobile ? 12 : 16,
                        mainAxisSpacing: isMobile ? 12 : 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) => _buildProductCard(_products[index]),
                    ),
        ),
        if (!_isLoading && _products.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildPagination(),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            l10n.translate('no_product_data'),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final mainImage = product['mainImage'] as String?;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: mainImage != null && mainImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.network(
                            ImageUtil.getImageUrl(mainImage),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
                        ),
                ),
                if (_isAddMode && product['inShop'] == true)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context).translate('added'),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isAddMode && product['inShop'] != true)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.green, size: 20),
                      onPressed: () => _handleAddProduct(product),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${double.parse(product['price'].toString()).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700]),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalizations.of(context).translate('sales_label')}: ${product['sales'] ?? 0}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    InkWell(
                      onTap: () => _showProductDetail(product),
                      child: Text(
                        AppLocalizations.of(context).viewDetails,
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
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

  /// 处理删除商品
  void _handleDeleteProduct(Map<String, dynamic> product) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.translate('confirm_delete_product').replaceAll('{name}', product['name'] ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final response = await ShopProductApi.deleteProduct(
                  product['id'].toString(),
                );

                if (mounted) {
                  if (response.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.translate('product_delete_success'))),
                    );
                    _loadProducts();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.deleteFailed}: ${response.errorMessage}')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.deleteFailed}: $e')),
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

  /// 显示商品详情
  void _showProductDetail(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailHeader(product),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildDetailContent(product),
                ),
              ),
              _buildDetailFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeader(Map<String, dynamic> product) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.productDetail,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(Map<String, dynamic> product) {
    final l10n = AppLocalizations.of(context);
    final images = product['images'] as List?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailSection(l10n.basicInfo, [
          _buildDetailRow(l10n.productName, product['name'] ?? ''),
          _buildDetailRow(l10n.translate('category'), product['category'] ?? ''),
          _buildDetailRow(l10n.price, '\$${double.parse(product['price'].toString()).toStringAsFixed(2)}'),
          _buildDetailRow(l10n.stock, '${product['stock'] ?? 0}'),
          _buildDetailRow(l10n.sales, '${product['sales'] ?? 0}'),
          _buildDetailRow(l10n.translate('status'), product['status'] == 'active' ? l10n.translate('active') : l10n.translate('inactive')),
        ]),
        const SizedBox(height: 24),
        _buildDetailSection(l10n.productDescription, [
          Text(
            product['description'] ?? l10n.noDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ]),
        if (images != null && images.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildDetailSection(l10n.translate('product_images'), [
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: images.map((imageUrl) => _buildImageThumbnail(imageUrl.toString())).toList(),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
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
            width: 100,
            child: Text(
              '$label：',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String imageUrl) {
    return GestureDetector(
      onTap: () => _showImagePreview(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          ImageUtil.getImageUrl(imageUrl),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 120,
            height: 120,
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  void _showImagePreview(String imageUrl) {
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
                      l10n.translate('image_preview'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildDetailFooter() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// 处理添加商品到店铺
  void _handleAddProduct(Map<String, dynamic> product) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_add')),
        content: Text(l10n.translate('confirm_add_product').replaceAll('{name}', product['name'] ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final response = await ShopProductApi.addProductToShop(
                  product['id'].toString(),
                );

                if (mounted) {
                  if (response.isSuccess) {
                    setState(() {
                      product['inShop'] = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.translate('product_add_success'))),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.translate('add')}: ${response.errorMessage}')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.translate('add')}: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('add')),
          ),
        ],
      ),
    );
  }

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
        _buildPageSizeSelector(),
        const SizedBox(width: 24),
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
        ..._buildPageNumbers(),
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
        const SizedBox(width: 16),
        _buildPageInput(),
      ],
    );
  }

  Widget _buildPageSizeSelector() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(l10n.translate('per_page'), style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
              return DropdownMenuItem<int>(value: value, child: Text('$value'));
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        Text(l10n.translate('items'), style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
        _loadProducts();
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
        SnackBar(content: Text(l10n.pleaseEnterValidPage)),
      );
      return;
    }

    if (pageNumber < 1 || pageNumber > _totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.translate('page_range_label')}: 1-$_totalPages')),
      );
      return;
    }

    setState(() {
      _currentPage = pageNumber;
    });
    _loadProducts();
    _pageInputController.clear();
  }

  /// 显示添加商品对话框
  void _showAddProductDialog() {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    String name = '';
    String category = '生活';
    String price = '';
    String stock = '';
    String description = '';
    List<String> imageUrls = [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addProduct),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
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
                  final response = await ShopProductApi.createAndAddProduct(
                    name: name,
                    category: category,
                    price: price,
                    stock: int.parse(stock),
                    description: description.isEmpty ? null : description,
                    images: imageUrls.isEmpty ? null : imageUrls,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    final l10nInner = AppLocalizations.of(context);
                    if (response.isSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10nInner.productAddedSuccess)),
                      );
                      _loadProducts();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${l10nInner.addFailed}: ${response.errorMessage}')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    final l10nInner = AppLocalizations.of(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10nInner.addFailed}: $e')),
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
}
