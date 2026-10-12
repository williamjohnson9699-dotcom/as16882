import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/api/product_api.dart';
import '../../../core/api/shop_api.dart';
import '../../../core/api/cart_api.dart';
import '../../../core/api/chat_api.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../home/widgets/mall_app_bar.dart';
import '../../auth/widgets/auth_dialog.dart';
import '../../../shared/widgets/chat_floating_button.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/responsive_app_bar.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';

/// 商品详情页面
class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1; // 商品数量
  int _currentImageIndex = 0; // 当前图片索引
  Map<String, dynamic>? _productData; // 商品数据
  Map<String, dynamic>? _shopData; // 店铺数据
  List<Map<String, dynamic>> _recommendProducts = []; // 推荐商品列表
  bool _isLoading = false;
  bool _isLoadingRecommend = false;
  Timer? _autoPlayTimer; // 自动播放定时器

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  /// 加载商品详情
  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ProductApi.getProductDetail(widget.productId);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _productData = response.data;
          _isLoading = false;
        });
        // 启动自动播放
        _startAutoPlay();

        // 加载店铺信息
        final shopId = response.data?['shopId'];
        if (shopId != null) {
          _loadShopDetail(shopId.toString());
        }

        // 加载推荐商品
        _loadRecommendProducts();
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${l10n.loadFailed}: ${response.errorMessage}')),
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

  /// 加载店铺详情
  Future<void> _loadShopDetail(String shopId) async {
    try {
      final response = await ShopApi.getShopDetail(shopId);
      if (response.isSuccess && response.data != null && mounted) {
        setState(() {
          _shopData = response.data;
        });
      }
    } catch (e) {
      // 店铺信息不再展示，加载失败不影响商品详情
    }
  }

  /// 加载推荐商品
  Future<void> _loadRecommendProducts() async {
    setState(() {
      _isLoadingRecommend = true;
    });

    try {
      final response = await ProductApi.getRecommendProducts(
        widget.productId,
        page: 1,
        pageSize: 10,
      );
      if (response.isSuccess && response.data != null) {
        final records = response.data?['records'] as List?;
        setState(() {
          _recommendProducts = records?.cast<Map<String, dynamic>>() ?? [];
          _isLoadingRecommend = false;
        });
      } else {
        setState(() {
          _isLoadingRecommend = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingRecommend = false;
      });
    }
  }

  /// 启动自动播放
  void _startAutoPlay() {
    _stopAutoPlay();

    final images = _getImageList();
    if (images.length > 1) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            _currentImageIndex = (_currentImageIndex + 1) % images.length;
          });
        }
      });
    }
  }

  /// 停止自动播放
  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  /// 获取图片列表。主图在前，空地址和字符串 "null" 不算图片。
  List<String> _getImageList() {
    if (_productData == null) return [];

    final List<String> images = [];
    void addImage(dynamic raw) {
      if (raw == null) {
        return;
      }
      final text = raw.toString().trim();
      if (text.isEmpty || text == 'null' || images.contains(text)) {
        return;
      }
      images.add(text);
    }

    addImage(_productData!['mainImage']);
    if (_productData!['images'] is List) {
      for (final img in _productData!['images']) {
        addImage(img);
      }
    }
    return images;
  }

  @override
  void dispose() {
    _stopAutoPlay();
    super.dispose();
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

  /// 选择店铺
  Future<int?> _selectShop(int productId) async {
    final l10n = AppLocalizations.of(context);

    try {
      print('🔍 开始查询商品关联店铺，商品ID: $productId');

      // 获取商品关联的店铺列表
      final response = await ProductApi.getProductShops(productId);

      print(
          '📦 API响应: isSuccess=${response.isSuccess}, data=${response.data}, errorMessage=${response.errorMessage}');

      if (!response.isSuccess ||
          response.data == null ||
          response.data!.isEmpty) {
        print('❌ 查询失败或无店铺数据');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.operationFailedMsg}: 商品未关联店铺')),
          );
        }
        return null;
      }

      final shops = response.data!;
      print('✅ 查询到 ${shops.length} 个店铺');

      // 如果只有一个店铺，直接返回
      if (shops.length == 1) {
        print('📍 只有一个店铺，直接返回: ${shops[0]['id']}');
        return shops[0]['id'] as int?;
      }

      // 多个店铺，显示选择对话框
      print('📋 显示店铺选择对话框');
      return await showDialog<int>(
        context: context,
        builder: (context) => _ShopSelectDialog(shops: shops),
      );
    } catch (e, stackTrace) {
      print('💥 选择店铺异常: $e');
      print('📚 堆栈信息: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.operationFailedMsg}: $e')),
        );
      }
      return null;
    }
  }

  /// 选择店铺（用于联系卖家，过滤掉自己的店铺）
  Future<int?> _selectShopForChat(int productId) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();

    try {
      print('🔍 开始查询商品关联店铺（联系卖家），商品ID: $productId');

      // 获取商品关联的店铺列表
      final response = await ProductApi.getProductShops(productId);

      print(
          '📦 API响应: isSuccess=${response.isSuccess}, data=${response.data}, errorMessage=${response.errorMessage}');

      if (!response.isSuccess ||
          response.data == null ||
          response.data!.isEmpty) {
        print('❌ 查询失败或无店铺数据');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.operationFailedMsg}: 商品未关联店铺')),
          );
        }
        return null;
      }

      final allShops = response.data!;
      print('✅ 查询到 ${allShops.length} 个店铺');

      // 为每个店铺查询详情以获取userId
      final currentUserId = authProvider.userInfo?.id;
      print('🔍 当前用户ID: $currentUserId (类型: ${currentUserId.runtimeType})');

      final List<Map<String, dynamic>> shopsWithUserId = [];
      for (final shop in allShops) {
        final shopId = shop['id'];
        if (shopId == null) continue;

        // 查询店铺详情
        final detailResponse = await ShopApi.getShopDetail(shopId.toString());
        if (detailResponse.isSuccess && detailResponse.data != null) {
          final shopDetail = Map<String, dynamic>.from(detailResponse.data!);
          // 合并店铺基本信息和详情
          shopDetail.addAll(shop);
          shopsWithUserId.add(shopDetail);
        }
      }

      print('✅ 获取到 ${shopsWithUserId.length} 个店铺的详细信息');

      // 过滤掉当前用户自己的店铺
      final shops = shopsWithUserId.where((shop) {
        final shopUserId = shop['userId'];
        print(
            '🏪 店铺 ${shop['name']} 的userId: $shopUserId (类型: ${shopUserId.runtimeType})');

        // 转换为字符串进行比较，避免类型不匹配
        final currentUserIdStr = currentUserId?.toString();
        final shopUserIdStr = shopUserId?.toString();
        final isNotOwner = shopUserIdStr != currentUserIdStr;

        print('   比较结果: $shopUserIdStr != $currentUserIdStr = $isNotOwner');
        return isNotOwner;
      }).toList();

      print('🔍 过滤后剩余 ${shops.length} 个店铺（排除了自己的店铺）');

      if (shops.isEmpty) {
        print('❌ 过滤后没有可选择的店铺');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.operationFailedMsg}: 没有可联系的店铺')),
          );
        }
        return null;
      }

      // 如果只有一个店铺，直接返回
      if (shops.length == 1) {
        print('📍 只有一个店铺，直接返回: ${shops[0]['id']}');
        return shops[0]['id'] as int?;
      }

      // 多个店铺，显示选择对话框
      print('📋 显示店铺选择对话框');
      return await showDialog<int>(
        context: context,
        builder: (context) => _ShopSelectDialog(shops: shops),
      );
    } catch (e, stackTrace) {
      print('💥 选择店铺异常: $e');
      print('📚 堆栈信息: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.operationFailedMsg}: $e')),
        );
      }
      return null;
    }
  }

  /// 加入购物车
  Future<void> _addToCart() async {
    if (!await _checkLogin()) return;

    if (_productData == null) return;

    final productId = _productData!['id'];
    if (productId == null) return;

    // 获取商品关联的店铺列表
    final shopId = await _selectShop(productId);
    if (shopId == null) return;

    try {
      final response = await CartApi.addToCart(
        productId: productId,
        shopId: shopId,
        quantity: _quantity,
      );

      if (response.isSuccess) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          final appProvider = context.read<AppProvider>();
          appProvider.loadCartCount();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.addedToCart)),
          );
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${l10n.addToCartFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.addToCartFailed}: $e')),
        );
      }
    }
  }

  /// 立即购买
  Future<void> _buyNow() async {
    if (!await _checkLogin()) return;

    if (_productData == null) return;

    final productId = _productData!['id'];
    if (productId == null) return;

    // 获取商品关联的店铺列表
    final shopId = await _selectShop(productId);
    if (shopId == null) return;

    final l10n = AppLocalizations.of(context);
    // 先加入购物车
    try {
      final response = await CartApi.addToCart(
        productId: productId,
        shopId: shopId,
        quantity: _quantity,
      );

      if (response.isSuccess) {
        // 更新购物车数量角标
        if (mounted) {
          context.read<AppProvider>().loadCartCount();
        }
        // 跳转到购物车页面
        if (mounted) {
          context.go('/cart');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${l10n.operationFailedMsg}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.operationFailedMsg}: $e')),
        );
      }
    }
  }

  /// 联系卖家
  Future<void> _contactSeller() async {
    if (!await _checkLogin()) return;

    if (_productData == null) return;

    final productId = _productData!['id'];
    if (productId == null) return;

    // 获取商品关联的店铺列表（过滤掉自己的店铺）
    final shopId = await _selectShopForChat(productId);
    if (shopId == null) return;

    // 根据店铺ID获取店铺的userId
    try {
      final response = await ShopApi.getShopDetail(shopId.toString());
      if (!response.isSuccess || response.data == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.operationFailedMsg}: 无法获取店铺信息')),
          );
        }
        return;
      }

      final shopUserId = response.data?['userId'];
      if (shopUserId == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.operationFailedMsg}: 无法获取店铺用户信息')),
          );
        }
        return;
      }

      if (mounted) {
        context.go('/chat?targetUserId=$shopUserId');
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.operationFailedMsg}: $e')),
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
          ? ResponsiveAppBar(title: l10n.productDetail)
          : const MallAppBar(),
      body: SafeArea(
        child: AppBackground(
          child: Center(
            child: Container(
              constraints: ResponsiveUtil.getContentConstraints(context),
              color: Colors.white,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _productData == null
                      ? Center(child: Text(l10n.productNotFound))
                      : SingleChildScrollView(
                          padding: ResponsiveUtil.getResponsivePadding(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 商品信息区域
                              _buildProductInfo(),
                              const SizedBox(height: 24),
                              // 猜你喜欢区域
                              _buildRecommendSection(),
                            ],
                          ),
                        ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? const MobileBottomNavV2() : null,
      floatingActionButton: !isMobile ? const ChatFloatingButton() : null,
    );
  }

  /// 构建商品信息区域
  Widget _buildProductInfo() {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 上部分：图片轮播、商品详细信息
        if (isMobile)
          // 移动端：垂直布局
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片轮播
              _buildImageCarousel(),
              const SizedBox(height: 16),
              // 商品详细信息
              _buildProductDetails(),
            ],
          )
        else
          // Web端：水平布局
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片轮播
              Expanded(
                child: _buildImageCarousel(),
              ),
              const SizedBox(width: 16),
              // 商品详细信息
              Expanded(
                child: _buildProductDetails(),
              ),
            ],
          ),
      ],
    );
  }

  /// 构建图片轮播
  Widget _buildImageCarousel() {
    final images = _getImageList();
    final imageIndex =
        images.isEmpty ? 0 : _currentImageIndex.clamp(0, images.length - 1);

    return Column(
      children: [
        // 主图按原始像素显示，不放大、不裁切
        GestureDetector(
          onTap: images.isEmpty
              ? null
              : () {
                  _showImagePreview(context, images, imageIndex);
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildOriginalProductImage(
              images.isEmpty ? null : images[imageIndex],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          // 缩略图列表
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: EdgeInsets.only(
                        right: index < images.length - 1 ? 8 : 0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentImageIndex == index
                            ? Colors.blue[700]!
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.network(
                        ImageUtil.getImageUrl(images[index]),
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child:
                              Icon(Icons.image, size: 24, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// 按图片原始像素显示主图，不放大、不裁切。
  ///
  /// 参数:
  /// - [imagePath]: 图片相对路径或完整地址，为空时显示占位
  ///
  /// 返回: 原始尺寸的图片；地址为空或加载失败时返回占位
  Widget _buildOriginalProductImage(String? imagePath) {
    final imageUrl = ImageUtil.getImageUrl(imagePath);
    if (imageUrl.isEmpty) {
      return const SizedBox(
        height: 160,
        child: ColoredBox(
          color: Color(0xFFEEEEEE),
          child: _DetailImagePlaceholder(),
        ),
      );
    }
    return ColoredBox(
      color: Colors.grey.shade200,
      child: Image.network(
        imageUrl,
        alignment: Alignment.center,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return const SizedBox(
            height: 160,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          height: 160,
          child: _DetailImagePlaceholder(),
        ),
      ),
    );
  }

  /// 显示图片预览
  void _showImagePreview(
      BuildContext context, List<String> images, int initialIndex) {
    // 停止自动播放
    _stopAutoPlay();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _ImagePreviewDialog(
        images: images,
        initialIndex: initialIndex,
      ),
    ).then((_) {
      // 关闭预览后重新启动自动播放
      _startAutoPlay();
    });
  }

  /// 构建商品详细信息
  Widget _buildProductDetails() {
    final product = _productData!;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product['name'] ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${l10n.price}：',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '\$${product['price'] ?? 0}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuantitySelector(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 构建数量选择器
  Widget _buildQuantitySelector() {
    final l10n = AppLocalizations.of(context);
    final stock = _productData?['stock'] ?? 0;
    final canDecrease = _quantity > 1;
    final canIncrease = _quantity < stock;

    return Row(
      children: [
        Text(
          '${l10n.quantity}：',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        _buildQuantityButton(
          icon: Icons.remove,
          enabled: canDecrease,
          label: '${l10n.quantity}-',
          onTap: () {
            setState(() {
              _quantity--;
            });
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 48,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$_quantity',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        _buildQuantityButton(
          icon: Icons.add,
          enabled: canIncrease,
          label: '${l10n.quantity}+',
          onTap: () {
            setState(() {
              _quantity++;
            });
          },
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            '${l10n.stock}：$stock',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required bool enabled,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 18,
              color: enabled ? Colors.grey.shade800 : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final shopId = _productData?['shopId'];
    final isDisabled = shopId == null;

    // 检查是否是店铺所有者
    final shopUserId = _shopData?['userId'];
    final isOwner = authProvider.isAuthenticated &&
        shopUserId != null &&
        authProvider.userInfo?.id == shopUserId;

    return Row(
      children: [
        // 只有非店铺所有者才显示聊天按钮
        if (!isDisabled && !isOwner) ...[
          IconButton(
            onPressed: _contactSeller,
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: l10n.contactSeller,
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              side: BorderSide(color: Colors.grey[400]!),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: isDisabled ? null : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled ? Colors.grey : Colors.orange[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(l10n.addToCart),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isDisabled ? null : _buyNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled ? Colors.grey : Colors.red[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(l10n.buyNow),
          ),
        ),
      ],
    );
  }

  /// 构建猜你喜欢区域
  Widget _buildRecommendSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.youMayLike,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 16),
        _buildRecommendGrid(),
      ],
    );
  }

  /// 构建猜你喜欢商品网格
  Widget _buildRecommendGrid() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    if (_isLoadingRecommend) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recommendProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            l10n.noRecommendProducts,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 5,
        crossAxisSpacing: isMobile ? 12 : 16,
        mainAxisSpacing: isMobile ? 12 : 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _recommendProducts.length,
      itemBuilder: (context, index) {
        return _buildRecommendCard(_recommendProducts[index]);
      },
    );
  }

  /// 构建推荐商品卡片
  Widget _buildRecommendCard(Map<String, dynamic> product) {
    final productId = product['id']?.toString() ?? '';
    final name = product['name'] ?? '';
    final price = product['price'] ?? 0;
    final mainImage = product['mainImage'];

    return InkWell(
      onTap: () {
        context.push('/product/$productId');
      },
      child: Container(
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: mainImage != null && mainImage.isNotEmpty
                    ? Center(
                        child: Image.network(
                          ImageUtil.getImageUrl(mainImage),
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child:
                                Icon(Icons.image, size: 48, color: Colors.grey),
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
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: ExcludeSemantics(
        child: Icon(Icons.image_outlined, size: 40, color: Color(0xFF9E9E9E)),
      ),
    );
  }
}

/// 图片预览对话框
class _ImagePreviewDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImagePreviewDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<_ImagePreviewDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // 图片预览区域
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: Image.network(
                      ImageUtil.getImageUrl(widget.images[index]),
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 关闭按钮
          Positioned(
            top: 40,
            right: 40,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // 页码指示器
          if (widget.images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          // 左右切换按钮
          if (widget.images.length > 1) ...[
            // 左箭头
            Positioned(
              left: 40,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 48),
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ),
            ),
            // 右箭头
            Positioned(
              right: 40,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 48),
                  onPressed: _currentIndex < widget.images.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 店铺选择对话框
class _ShopSelectDialog extends StatelessWidget {
  final List<Map<String, dynamic>> shops;

  const _ShopSelectDialog({required this.shops});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.translate('select_shop')),
      content: SizedBox(
        width: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: shops.length,
          itemBuilder: (context, index) {
            final shop = shops[index];
            return _buildShopItem(context, shop);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _buildShopItem(BuildContext context, Map<String, dynamic> shop) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(shop['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 店铺图标
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: shop['logo'] != null && shop['logo'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ImageUtil.getImageUrl(shop['logo']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.store,
                            size: 24,
                            color: Colors.grey[400]),
                      ),
                    )
                  : Icon(Icons.store, size: 24, color: Colors.grey[400]),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${shop['rating'] ?? 0.0}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
