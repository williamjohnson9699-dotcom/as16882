import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/api/shop_api.dart';
import '../../../core/api/cart_api.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../auth/widgets/auth_dialog.dart';
import '../../home/widgets/mall_app_bar.dart';
import '../../../shared/widgets/chat_floating_button.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/responsive_app_bar.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';
import '../widgets/edit_shop_dialog.dart';

/// 店铺页面
class ShopPage extends StatefulWidget {
  final String shopId;

  const ShopPage({
    super.key,
    required this.shopId,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _currentPage = 1; // 当前页码
  int _totalPages = 1; // 总页数
  int _totalRecords = 0; // 总记录数
  int _itemsPerPage = 20; // 每页显示数量
  final List<int> _pageSizeOptions = [20, 40, 60, 80]; // 分页大小选项
  final TextEditingController _pageInputController = TextEditingController();
  bool _isFollowing = false; // 是否已关注

  Map<String, dynamic>? _shopData; // 店铺数据
  List<Map<String, dynamic>> _products = []; // 商品列表
  bool _isLoadingShop = false;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _loadShopDetail();
    _loadProducts();
  }

  @override
  void dispose() {
    _pageInputController.dispose();
    super.dispose();
  }

  /// 加载店铺详情
  Future<void> _loadShopDetail() async {
    setState(() {
      _isLoadingShop = true;
    });

    try {
      final response = await ShopApi.getShopDetail(widget.shopId);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _shopData = response.data;
          _isFollowing = response.data?['isFollowed'] ?? false;
          _isLoadingShop = false;
        });
      } else {
        setState(() {
          _isLoadingShop = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingShop = false;
      });
    }
  }

  /// 加载商品列表
  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final response = await ShopApi.getShopProducts(
        widget.shopId,
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
          _isLoadingProducts = false;
        });
      } else {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  /// 验证登录状态
  Future<bool> _checkLogin() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      // 显示登录对话框
      await showDialog(
        context: context,
        builder: (context) => const AuthDialog(isLogin: true),
      );
      // 对话框关闭后重新检查登录状态
      return authProvider.isAuthenticated;
    }
    return true;
  }

  /// 处理关注/取消关注
  Future<void> _handleFollow() async {
    if (!await _checkLogin()) return;

    try {
      final response = _isFollowing
          ? await ShopApi.unfollowShop(widget.shopId)
          : await ShopApi.followShop(widget.shopId);

      if (response.isSuccess) {
        setState(() {
          _isFollowing = !_isFollowing;
          // 更新关注数
          if (_shopData != null) {
            final currentCount = _shopData!['followCount'] ?? 0;
            _shopData!['followCount'] = _isFollowing ? currentCount + 1 : currentCount - 1;
          }
        });

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isFollowing ? l10n.shopFollowed : l10n.shopUnfollowed),
            ),
          );
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.operationFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.operationFailed}: $e')),
        );
      }
    }
  }

  /// 处理发送消息
  Future<void> _handleMessage() async {
    if (!await _checkLogin()) return;

    final userId = _shopData?['userId'];
    if (userId == null) return;

    if (mounted) {
      context.go('/chat?targetUserId=$userId');
    }
  }

  /// 处理编辑店铺
  Future<void> _handleEditShop() async {
    if (_shopData == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditShopDialog(shopData: _shopData!),
    );

    if (result == true) {
      // 重新加载店铺信息
      _loadShopDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: isMobile
          ? ResponsiveAppBar(title: _shopData?['name'] ?? '')
          : const MallAppBar(),
      body: SafeArea(
        child: AppBackground(
          child: Center(
            child: Container(
              constraints: ResponsiveUtil.getContentConstraints(context),
              color: Colors.white,
              child: isMobile
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final padding = ResponsiveUtil.getResponsivePadding(context);
                        final paddingValue = padding.horizontal / 2;
                        return Padding(
                          padding: padding,
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - (paddingValue * 2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 移动端：店铺信息在顶部
                                  _buildShopInfo(),
                                  const SizedBox(height: 16),
                                  // 商品列表
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
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 桌面端：左侧店铺信息
                        Container(
                          width: 250,
                          padding: const EdgeInsets.all(16),
                          child: _buildShopInfo(),
                        ),
                        // 右侧商品列表
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProductGrid(),
                                const SizedBox(height: 24),
                                _buildPagination(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? const MobileBottomNavV2() : null,
      floatingActionButton: !isMobile ? const ChatFloatingButton() : null,
    );
  }

  /// 构建店铺信息
  Widget _buildShopInfo() {
    if (_isLoadingShop) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final shopName = _shopData?['name'] ?? l10n.shopInfo;
    final shopLogo = _shopData?['logo'];
    final shopLevel = _shopData?['level'] ?? 5;
    final shopRating = _shopData?['rating'] ?? 4.8;
    final followCount = _shopData?['followCount'] ?? 0;
    final views = _shopData?['views'] ?? 0;
    final creditScore = _shopData?['creditScore'] ?? 98;
    final orderCount = _shopData?['orderCount'] ?? 0;
    final salesAmount = _shopData?['salesAmount'] ?? 0;

    // 检查是否是店铺所有者
    final isOwner = authProvider.isAuthenticated &&
                    _shopData != null &&
                    authProvider.userInfo?.id == _shopData!['userId'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 店铺图标
        Container(
          width: 100,
          height: 100,
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
                        Icon(Icons.store, size: 48, color: Colors.grey[400]),
                  ),
                )
              : Icon(Icons.store, size: 48, color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        // 店铺名称和编辑按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                shopName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (isOwner) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.edit, size: 20, color: Colors.blue[700]),
                onPressed: _handleEditShop,
                tooltip: l10n.editShop,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // 店铺等级
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, size: 18, color: Colors.amber[700]),
            const SizedBox(width: 4),
            Text(
              l10n.shopLevel(shopLevel),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 店铺统计信息
        _buildInfoRow(l10n.views, '$views'),
        const SizedBox(height: 12),
        _buildInfoRow(l10n.shopRating, '${shopRating.toStringAsFixed(1)}'),
        const SizedBox(height: 12),
        _buildInfoRow(l10n.followCount, '$followCount'),
        const SizedBox(height: 12),
        _buildInfoRow(l10n.creditScore, '$creditScore%'),
        const SizedBox(height: 24),
        // 关注和消息按钮
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _handleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey[400] : Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(_isFollowing ? l10n.followed : l10n.follow),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _handleMessage,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[700],
                side: BorderSide(color: Colors.blue[700]!),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: const Icon(Icons.message_outlined, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  /// 构建商品网格
  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4, // 移动端每行2个，桌面端每行4个
        crossAxisSpacing: isMobile ? 8 : 16,
        mainAxisSpacing: isMobile ? 8 : 16,
        childAspectRatio: isMobile ? 0.7 : 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_products[index]);
      },
    );
  }

  /// 构建商品卡片
  Widget _buildProductCard(Map<String, dynamic> product) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    final productId = product['id']?.toString() ?? '';
    final name = product['name'] ?? '';
    final price = product['price'] ?? 0;
    final mainImage = product['mainImage'];

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品图片
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: mainImage != null && mainImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        ImageUtil.getImageUrl(mainImage),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
            ),
          ),
          // 商品信息
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    context.push('/product/$productId');
                  },
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$$price',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAddToCart(productId),
                    icon: Icon(Icons.shopping_cart, size: isMobile ? 14 : 16),
                    label: Text(
                      l10n.addToCart,
                      style: TextStyle(fontSize: isMobile ? 12 : 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: isMobile ? 6 : 8,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 处理加入购物车
  Future<void> _handleAddToCart(String productId) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 检查是否登录
    if (!authProvider.isAuthenticated) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => const AuthDialog(isLogin: true),
      );
      if (shouldLogin != true) return;
    }

    try {
      // 使用当前店铺ID添加到购物车
      final response = await CartApi.addToCart(
        productId: int.parse(productId),
        quantity: 1,
        shopId: int.parse(widget.shopId),
      );

      if (response.isSuccess) {
        if (mounted) {
          // 更新购物车数量角标
          context.read<AppProvider>().loadCartCount();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.addToCartSuccess),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.addToCartFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.addToCartFailed}: $e')),
        );
      }
    }
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
