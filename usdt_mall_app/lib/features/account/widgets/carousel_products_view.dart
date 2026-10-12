import 'package:flutter/material.dart';
import '../../../core/api/carousel_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';

/// 轮播商品管理视图
class CarouselProductsView extends StatefulWidget {
  const CarouselProductsView({super.key});

  @override
  State<CarouselProductsView> createState() => _CarouselProductsViewState();
}

class _CarouselProductsViewState extends State<CarouselProductsView> {
  List<Map<String, dynamic>> _carouselProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCarouselProducts();
  }

  /// 加载轮播商品列表
  Future<void> _loadCarouselProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await CarouselApi.getCarouselProducts();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _carouselProducts = List<Map<String, dynamic>>.from(response.data!);
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
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) _buildHeader(isMobile),
              if (!isMobile) const SizedBox(height: 24),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_carouselProducts.isEmpty)
                Expanded(child: _buildEmptyState())
              else
                Expanded(child: _buildCarouselList()),
            ],
          ),
        ),
        // 移动端浮动按钮
        if (isMobile && _carouselProducts.length < 5)
          Positioned(
            right: 16,
            bottom: 16,
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
  Widget _buildHeader(bool isMobile) {
    final l10n = AppLocalizations.of(context);

    if (isMobile) {
      // 移动端不显示头部，使用浮动按钮
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('carousel_products'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.translate('carousel_products_desc'),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _carouselProducts.length >= 5 ? null : _showAddProductDialog,
          icon: const Icon(Icons.add),
          label: Text(l10n.translate('add_carousel_product')),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_carousel_outlined, size: isMobile ? 48 : 64, color: Colors.grey[400]),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            l10n.translate('no_carousel_products'),
            style: TextStyle(fontSize: isMobile ? 14 : 16, color: Colors.grey[600]),
          ),
          if (!isMobile) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add),
              label: Text(l10n.translate('add_carousel_product')),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建轮播商品列表
  Widget _buildCarouselList() {
    return ReorderableListView.builder(
      itemCount: _carouselProducts.length,
      onReorder: _handleReorder,
      itemBuilder: (context, index) {
        final product = _carouselProducts[index];
        return _buildCarouselItem(product, index, key: ValueKey(product['id']));
      },
    );
  }

  /// 构建单个轮播商品项
  Widget _buildCarouselItem(Map<String, dynamic> product, int index, {required Key key}) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      // 移动端：紧凑卡片布局
      return Card(
        key: key,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 拖动手柄
              Icon(Icons.drag_handle, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              // 商品图片
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: product['productImage'] != null && product['productImage'].isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          ImageUtil.getImageUrl(product['productImage']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image, color: Colors.grey[400], size: 24);
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['productName'] ?? l10n.productName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product['productPrice']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red[700],
                onPressed: () => _handleDelete(product['id']),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      );
    }

    // 桌面端：原有布局
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_handle, color: Colors.grey[400]),
            const SizedBox(width: 16),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: product['productImage'] != null && product['productImage'].isNotEmpty
                  ? Image.network(
                      ImageUtil.getImageUrl(product['productImage']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, color: Colors.grey);
                      },
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product['productName'] ?? l10n.productName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${index + 1}',
                style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '\$${product['productPrice']?.toStringAsFixed(2) ?? '0.00'}',
          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red[700],
              onPressed: () => _handleDelete(product['id']),
              tooltip: l10n.delete,
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  /// 处理重新排序
  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _carouselProducts.removeAt(oldIndex);
      _carouselProducts.insert(newIndex, item);
    });

    // 更新排序到后端
    try {
      final productIds = _carouselProducts.map((p) => p['productId'] as int).toList();
      final response = await CarouselApi.updateCarouselOrder(productIds);

      if (!response.isSuccess && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('update_order_failed')}: ${response.errorMessage}')),
        );
        // 失败时重新加载
        _loadCarouselProducts();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('update_order_failed')}: $e')),
        );
        // 失败时重新加载
        _loadCarouselProducts();
      }
    }
  }

  /// 处理删除
  Future<void> _handleDelete(int carouselId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.translate('confirm_delete_carousel_product')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await CarouselApi.deleteCarouselProduct(carouselId);

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteSuccess)),
          );
        }
        _loadCarouselProducts();
      } else {
        if (mounted) {
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
  }

  /// 显示添加商品对话框
  Future<void> _showAddProductDialog() async {
    if (!mounted) return;

    final selectedProduct = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddProductDialog(),
    );

    if (selectedProduct != null) {
      _handleAddProduct(selectedProduct['id']);
    }
  }

  /// 处理添加商品
  Future<void> _handleAddProduct(int productId) async {
    final l10n = AppLocalizations.of(context);

    try {
      final response = await CarouselApi.addCarouselProduct(productId);

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('add_carousel_success'))),
          );
        }
        _loadCarouselProducts();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.addFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.addFailed}: $e')),
        );
      }
    }
  }
}

/// 添加商品对话框（支持分页搜索）
class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog();

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  String _searchKeyword = '';
  Map<String, dynamic>? _selectedProduct;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _pageSize = 10;
  int _total = 0;
  int _totalPages = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载商品列表
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await CarouselApi.searchProducts(
        keyword: _searchKeyword.isEmpty ? null : _searchKeyword,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response.data!['list'] ?? []);
          _total = response.data!['total'] ?? 0;
          _totalPages = response.data!['totalPages'] ?? 0;
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

  /// 处理搜索
  void _handleSearch(String keyword) {
    setState(() {
      _searchKeyword = keyword;
      _currentPage = 1;
    });
    _loadProducts();
  }

  /// 处理翻页
  void _handlePageChange(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.translate('select_carousel_product')),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.translate('search_product'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _handleSearch('');
                  },
                ),
              ),
              onSubmitted: _handleSearch,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_products.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.noProductData,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final isSelected = _selectedProduct?['id'] == product['id'];

                    return Card(
                      color: isSelected ? Colors.blue[50] : null,
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: product['mainImage'] != null && product['mainImage'].isNotEmpty
                              ? Image.network(
                                  ImageUtil.getImageUrl(product['mainImage']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.image, color: Colors.grey);
                                  },
                                )
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                        title: Text(product['name'] ?? ''),
                        subtitle: Text('\$${product['price']?.toString() ?? '0.00'}'),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.blue[700])
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedProduct = product;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            _buildPagination(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _selectedProduct == null
              ? null
              : () => Navigator.of(context).pop(_selectedProduct),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  /// 构建分页组件
  Widget _buildPagination() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      // 移动端：紧凑布局
      return Column(
        children: [
          // 第一行：页码导航
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? () => _handlePageChange(_currentPage - 1) : null,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages ? () => _handlePageChange(_currentPage + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 第二行：总数显示
          Text(
            '${l10n.total}: $_total',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      );
    }

    // 桌面端：原有布局
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${l10n.total}: $_total',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 1 ? () => _handlePageChange(_currentPage - 1) : null,
            ),
            Text(
              '$_currentPage / $_totalPages',
              style: const TextStyle(fontSize: 14),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < _totalPages ? () => _handlePageChange(_currentPage + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
