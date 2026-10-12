import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/api/order_api.dart';
import '../../../core/api/user_api.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../home/widgets/mall_app_bar.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/chat_floating_button.dart';
import '../../../shared/widgets/responsive_app_bar.dart';
import '../../../shared/widgets/mobile_bottom_nav_v2.dart';
import '../../../shared/widgets/address_select_dialog.dart';
import '../../../shared/widgets/order_success_dialog.dart';

/// 购物车页面
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  List<CartItem> _cartItems = [];
  Set<int> _selectedIds = {}; // 选中的购物车项ID
  bool _isLoading = true;
  bool _isSelectAll = false;
  Map<String, dynamic>? _selectedAddress; // 选中的地址

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  /// 加载购物车列表
  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _cartService.getCartList();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _cartItems = response.data!;
          // 默认全部选中
          _selectedIds = _cartItems.map((item) => item.id).toSet();
          _isSelectAll = _cartItems.isNotEmpty;
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

    return Scaffold(
      appBar: isMobile
          ? ResponsiveAppBar(title: AppLocalizations.of(context).cart)
          : const MallAppBar(),
      body: SafeArea(
        child: AppBackground(
          child: Center(
            child: Container(
              constraints: ResponsiveUtil.getContentConstraints(context),
              color: Colors.white,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cartItems.isEmpty
                      ? _buildEmptyCart()
                      : _buildCartContent(),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isMobile ? const MobileBottomNavV2() : null,
      floatingActionButton: !isMobile ? const ChatFloatingButton() : null,
    );
  }

  /// 构建空购物车
  Widget _buildEmptyCart() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            l10n.cartEmpty,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(l10n.goShopping),
          ),
        ],
      ),
    );
  }

  /// 构建购物车内容
  Widget _buildCartContent() {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Column(
      children: [
        if (!isMobile) _buildTitle(),
        Expanded(
          child: _buildCartList(),
        ),
        _buildActionArea(),
      ],
    );
  }

  /// 构建标题
  Widget _buildTitle() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.cart,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          if (!isMobile)
            TextButton.icon(
              onPressed: _selectedIds.isEmpty ? null : _handleDeleteSelected,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(l10n.deleteSelected),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[700],
              ),
            )
          else
            IconButton(
              onPressed: _selectedIds.isEmpty ? null : _handleDeleteSelected,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[700],
              tooltip: l10n.deleteSelected,
            ),
        ],
      ),
    );
  }

  /// 构建购物车列表
  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        final isSelected = _selectedIds.contains(item.id);
        return _buildCartItem(item, isSelected);
      },
    );
  }

  /// 构建单个购物车项
  Widget _buildCartItem(CartItem item, bool isSelected) {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isMobile ? _buildMobileCartItem(item, isSelected) : _buildDesktopCartItem(item, isSelected),
    );
  }

  /// 构建桌面端购物车项
  Widget _buildDesktopCartItem(CartItem item, bool isSelected) {
    return Row(
      children: [
        // 复选框
        Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedIds.add(item.id);
              } else {
                _selectedIds.remove(item.id);
              }
              _updateSelectAllState();
            });
          },
        ),
        const SizedBox(width: 12),
        // 商品图片
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: item.productImage != null && item.productImage!.isNotEmpty
              ? Image.network(
                  ImageUtil.getImageUrl(item.productImage!),
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.image, size: 40, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        // 商品信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? AppLocalizations.of(context).productName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.shopName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.store, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      item.shopName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '\$${item.productPrice?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // 数量控制
        _buildQuantityControl(item),
        const SizedBox(width: 12),
        // 删除按钮
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: Colors.red[700],
          onPressed: () => _handleDeleteItem(item.id),
        ),
      ],
    );
  }

  /// 构建移动端购物车项
  Widget _buildMobileCartItem(CartItem item, bool isSelected) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 复选框
        Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedIds.add(item.id);
              } else {
                _selectedIds.remove(item.id);
              }
              _updateSelectAllState();
            });
          },
        ),
        const SizedBox(width: 8),
        // 商品图片
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: item.productImage != null && item.productImage!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ImageUtil.getImageUrl(item.productImage!),
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.image, size: 35, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        // 商品信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? AppLocalizations.of(context).productName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.shopName != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.store, size: 11, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text(
                      item.shopName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              // 价格和数量控制在同一行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${item.productPrice?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  _buildQuantityControl(item, isMobile: true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 删除按钮
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          color: Colors.red[700],
          onPressed: () => _handleDeleteItem(item.id),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  /// 构建数量控制
  Widget _buildQuantityControl(CartItem item, {bool isMobile = false}) {
    final buttonSize = isMobile ? 26.0 : 28.0;
    final iconSize = isMobile ? 14.0 : 16.0;
    final inputWidth = isMobile ? 45.0 : 50.0;
    final inputHeight = isMobile ? 26.0 : 28.0;

    return Row(
      children: [
        // 减少按钮
        InkWell(
          onTap: () {
            if (item.quantity > 1) {
              _handleUpdateQuantity(item, item.quantity - 1);
            }
          },
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.remove, size: iconSize),
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8),
        // 数量显示
        Container(
          width: inputWidth,
          height: inputHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${item.quantity}',
            style: TextStyle(fontSize: isMobile ? 13 : 14),
          ),
        ),
        SizedBox(width: isMobile ? 6 : 8),
        // 增加按钮
        InkWell(
          onTap: () {
            _handleUpdateQuantity(item, item.quantity + 1);
          },
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.add, size: iconSize),
          ),
        ),
      ],
    );
  }

  /// 构建操作区域
  Widget _buildActionArea() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    // 计算总价
    double totalPrice = 0;
    for (var item in _cartItems) {
      if (_selectedIds.contains(item.id)) {
        totalPrice += (item.productPrice ?? 0) * item.quantity;
      }
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: isMobile ? _buildMobileActionArea(l10n, totalPrice) : _buildDesktopActionArea(l10n, totalPrice),
    );
  }

  /// 构建桌面端操作区域
  Widget _buildDesktopActionArea(AppLocalizations l10n, double totalPrice) {
    return Row(
      children: [
        // 全选复选框
        Checkbox(
          value: _isSelectAll,
          onChanged: (value) {
            setState(() {
              _isSelectAll = value ?? false;
              if (_isSelectAll) {
                _selectedIds = _cartItems.map((item) => item.id).toSet();
              } else {
                _selectedIds.clear();
              }
            });
          },
        ),
        Text(l10n.selectAll, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 24),
        // 总价
        Text(l10n.total, style: const TextStyle(fontSize: 14)),
        Text(
          '\$${totalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(width: 24),
        // 已选择的地址信息
        if (_selectedAddress != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Text(
                  '${_selectedAddress!['name']} ${_selectedAddress!['phone']}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    _selectedAddress!['address'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _handleSelectAddress,
                  child: Icon(Icons.edit, size: 14, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ] else ...[
          // 选择地址按钮
          ElevatedButton(
            onPressed: _selectedIds.isEmpty ? null : _handleSelectAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(l10n.selectAddress, style: const TextStyle(fontSize: 14)),
          ),
        ],
        const Spacer(),
        // 结算按钮
        ElevatedButton(
          onPressed: _selectedIds.isEmpty ? null : _handleCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(l10n.checkout),
        ),
      ],
    );
  }

  /// 构建移动端操作区域
  Widget _buildMobileActionArea(AppLocalizations l10n, double totalPrice) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 地址选择行
        if (_selectedAddress != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedAddress!['name']} ${_selectedAddress!['phone']}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedAddress!['address'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _handleSelectAddress,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit, size: 16, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _selectedIds.isEmpty ? null : _handleSelectAddress,
              icon: const Icon(Icons.location_on, size: 18),
              label: Text(l10n.selectAddress),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[700],
                side: BorderSide(color: Colors.blue[300]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        // 全选、删除、总价、结算行
        Row(
          children: [
            // 全选复选框
            Checkbox(
              value: _isSelectAll,
              onChanged: (value) {
                setState(() {
                  _isSelectAll = value ?? false;
                  if (_isSelectAll) {
                    _selectedIds = _cartItems.map((item) => item.id).toSet();
                  } else {
                    _selectedIds.clear();
                  }
                });
              },
            ),
            Text(l10n.selectAll, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            // 删除按钮
            IconButton(
              onPressed: _selectedIds.isEmpty ? null : _handleDeleteSelected,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[700],
              tooltip: l10n.deleteSelected,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const Spacer(),
            // 总价
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.total,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // 结算按钮
            ElevatedButton(
              onPressed: _selectedIds.isEmpty ? null : _handleCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(l10n.checkout, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ],
    );
  }

  /// 更新全选状态
  void _updateSelectAllState() {
    setState(() {
      _isSelectAll = _cartItems.isNotEmpty && _selectedIds.length == _cartItems.length;
    });
  }

  /// 处理删除选中项
  Future<void> _handleDeleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteSelected(_selectedIds.length)),
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
      // 批量删除：循环调用单个删除接口
      final idsToDelete = _selectedIds.toList();
      int successCount = 0;
      int failCount = 0;

      for (var cartId in idsToDelete) {
        try {
          final response = await _cartService.deleteCartItem(cartId);
          if (response.isSuccess) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }

      // 重新加载购物车列表
      await _loadCartItems();

      // 更新购物车数量角标
      if (mounted) {
        context.read<AppProvider>().loadCartCount();
      }

      if (mounted) {
        if (failCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteSuccess)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteCompleted(successCount, failCount))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.deleteFailed}: $e')),
        );
      }
    }
  }

  /// 处理删除单个商品
  Future<void> _handleDeleteItem(int cartId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteItem),
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
      final response = await _cartService.deleteCartItem(cartId);

      if (response.isSuccess) {
        // 重新加载购物车列表
        await _loadCartItems();

        // 更新购物车数量角标
        if (mounted) {
          context.read<AppProvider>().loadCartCount();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteSuccess)),
          );
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.deleteFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.deleteFailed}: $e')),
        );
      }
    }
  }

  /// 处理更新数量
  Future<void> _handleUpdateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      final response = await _cartService.updateCartQuantity(
        cartId: item.id,
        quantity: newQuantity,
      );

      if (response.isSuccess) {
        setState(() {
          final index = _cartItems.indexWhere((i) => i.id == item.id);
          if (index != -1) {
            _cartItems[index] = CartItem(
              id: item.id,
              userId: item.userId,
              productId: item.productId,
              quantity: newQuantity,
              productName: item.productName,
              productPrice: item.productPrice,
              productImage: item.productImage,
            );
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.updateFailedText}: $e')),
        );
      }
    }
  }

  /// 处理选择地址
  Future<void> _handleSelectAddress() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddressSelectDialog(),
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addressSelected(result['name']))),
        );
      }
    }
  }

  /// 处理结算
  Future<void> _handleCheckout() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectProducts)),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectAddressFirst)),
      );
      return;
    }

    // 检查用户是否已设置支付密码
    try {
      final userInfoResponse = await UserApi.getUserInfo();
      if (!userInfoResponse.isSuccess || userInfoResponse.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToGetUserInfo)),
          );
        }
        return;
      }

      final hasPaymentPassword = userInfoResponse.data!['hasPaymentPassword'] as bool?;
      if (hasPaymentPassword != true) {
        // 用户未设置支付密码，显示提示对话框
        if (mounted) {
          final shouldSetPassword = await _showSetPaymentPasswordPrompt();
          if (shouldSetPassword != true) {
            return;
          }
          // 用户选择去设置支付密码，跳转到账户设置页面
          context.go('/account');
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToGetUserInfo}: $e')),
        );
      }
      return;
    }

    // 显示支付密码输入对话框
    final paymentPassword = await _showPaymentPasswordDialog();
    if (paymentPassword == null || paymentPassword.isEmpty) {
      // 用户取消或未输入密码
      return;
    }

    try {
      // 创建订单（包含支付密码）
      final response = await OrderApi.createOrder(
        cartIds: _selectedIds.toList(),
        addressId: _selectedAddress!['id'],
        paymentPassword: paymentPassword,
      );

      if (response.isSuccess) {
        if (mounted) {
          // 刷新用户信息（更新余额）
          final authProvider = context.read<AuthProvider>();
          await authProvider.refreshUserInfo();

          // 更新购物车数量角标
          context.read<AppProvider>().loadCartCount();

          // 显示订单成功对话框
          await _showOrderSuccessDialog();
          // 重新加载购物车
          await _loadCartItems();
          // 清空选中的地址
          setState(() {
            _selectedAddress = null;
          });
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.orderCreateFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.orderCreateFailed}: $e')),
        );
      }
    }
  }

  /// 显示支付密码输入对话框
  Future<String?> _showPaymentPasswordDialog() async {
    final l10n = AppLocalizations.of(context);
    final passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.enterPaymentPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.pleaseEnterPaymentPasswordToConfirm,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.paymentPassword,
                hintText: l10n.pleaseEnterPaymentPassword,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.pleaseEnterPaymentPassword)),
                );
                return;
              }
              if (password.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.paymentPasswordMustBe6Digits)),
                );
                return;
              }
              Navigator.of(context).pop(password);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// 显示订单成功对话框
  Future<void> _showOrderSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const OrderSuccessDialog(),
    );
  }

  /// 显示设置支付密码提示对话框
  Future<bool?> _showSetPaymentPasswordPrompt() async {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.paymentPasswordNotSet),
        content: Text(l10n.pleaseSetPaymentPasswordFirst),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.goToSet),
          ),
        ],
      ),
    );
  }
}
