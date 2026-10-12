import 'package:flutter/material.dart';

import '../../../core/api/proxy_order_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/utils/responsive_util.dart';

/// 代下订单视图
class ProxyOrderView extends StatefulWidget {
  const ProxyOrderView({super.key});

  @override
  State<ProxyOrderView> createState() => _ProxyOrderViewState();
}

class _ProxyOrderViewState extends State<ProxyOrderView> {
  final _userSearchController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _shopSearchController = TextEditingController();

  Map<String, dynamic>? _selectedUser;
  Map<String, dynamic>? _selectedShop;
  final List<Map<String, dynamic>> _selectedProducts = [];
  List<Map<String, dynamic>> _userAddresses = [];
  int? _selectedAddressId;

  // 用户搜索结果
  final List<Map<String, dynamic>> _userSearchResults = [];

  // 店铺搜索结果
  final List<Map<String, dynamic>> _shopSearchResults = [];
  int _shopCurrentPage = 1;
  int _shopTotalPages = 1;

  // 商品搜索结果
  final List<Map<String, dynamic>> _productSearchResults = [];
  int _productCurrentPage = 1;
  int _productTotalPages = 1;

  bool _isLoadingUsers = false;
  bool _isLoadingShops = false;
  bool _isLoadingProducts = false;
  bool _isLoadingAddresses = false;

  // 输入框内容状态
  bool _hasUserSearchText = false;
  bool _hasProductSearchText = false;
  bool _hasShopSearchText = false;

  @override
  void initState() {
    super.initState();
    _userSearchController.addListener(() {
      setState(() {
        _hasUserSearchText = _userSearchController.text.isNotEmpty;
      });
    });
    _productSearchController.addListener(() {
      setState(() {
        _hasProductSearchText = _productSearchController.text.isNotEmpty;
      });
    });
    _shopSearchController.addListener(() {
      setState(() {
        _hasShopSearchText = _shopSearchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _productSearchController.dispose();
    _shopSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    return Container(
      color: Colors.white,
      height: isMobile ? double.infinity : null,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) ...[
              _buildTitle(),
              const SizedBox(height: 24),
            ],
            _buildSearchSection(),
            SizedBox(height: isMobile ? 12 : 24),
            _buildSelectedProductsSection(),
            SizedBox(height: isMobile ? 12 : 24),
            _buildSummarySection(),
          ],
        ),
      ),
    );
  }

  /// 构建标题
  Widget _buildTitle() {
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.translate('proxy_order_title'),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  /// 构建搜索区域（左右布局）
  Widget _buildSearchSection() {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          _buildUserSearchSection(),
          const SizedBox(height: 12),
          _buildProductSearchSection(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildUserSearchSection()),
        const SizedBox(width: 24),
        Expanded(child: _buildProductSearchSection()),
      ],
    );
  }

  /// 构建用户搜索区域
  Widget _buildUserSearchSection() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('select_user'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: isMobile ? 10 : 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userSearchController,
                  onSubmitted: (_) => _handleUserSearch(),
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_user_hint'),
                    hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    prefixIcon: Icon(Icons.search, size: isMobile ? 16 : 24),
                    suffixIcon: _hasUserSearchText
                        ? IconButton(
                            icon: Icon(Icons.clear, size: isMobile ? 14 : 24),
                            padding: isMobile ? EdgeInsets.zero : null,
                            constraints: isMobile ? BoxConstraints(minWidth: 28, minHeight: 28, maxWidth: 28, maxHeight: 28) : null,
                            splashRadius: isMobile ? 14 : null,
                            onPressed: () {
                              _userSearchController.clear();
                              setState(() {
                                _userSearchResults.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 6 : 12,
                    ),
                  ),
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoadingUsers ? null : _handleUserSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 14 : 16,
                  ),
                ),
                child: _isLoadingUsers
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(l10n.translate('search'), style: TextStyle(fontSize: isMobile ? 13 : 14)),
              ),
            ],
          ),
          if (_selectedUser != null) ...[
            SizedBox(height: isMobile ? 10 : 16),
            _buildSelectedUserCard(),
          ],
          if (_isLoadingUsers) ...[
            SizedBox(height: isMobile ? 10 : 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (!_isLoadingUsers && _userSearchResults.isNotEmpty) ...[
            SizedBox(height: isMobile ? 10 : 16),
            _buildUserSearchResults(),
          ],
        ],
      ),
    );
  }

  /// 构建已选用户卡片
  Widget _buildSelectedUserCard() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);
    final username = _selectedUser!['username']?.toString() ?? '';
    final nickname = _selectedUser!['nickname']?.toString() ?? '';
    final inviteCode = _selectedUser!['inviteCode']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: isMobile ? 20 : 24,
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.person, color: Colors.blue[700], size: isMobile ? 20 : 24),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username.isNotEmpty ? username : nickname,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.translate('invite_code_label')}: $inviteCode',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedUser = null;
                    _selectedAddressId = null;
                    _userAddresses.clear();
                  });
                },
                icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                color: Colors.grey[600],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAddressSection(),
        ],
      ),
    );
  }

  /// 构建地址选择区域
  Widget _buildAddressSection() {
    final isMobile = ResponsiveUtil.isMobile(context);

    if (_isLoadingAddresses) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_selectedAddressId == null || _userAddresses.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _handleAddressSelection,
          icon: Icon(Icons.location_on, size: isMobile ? 16 : 18),
          label: Text(
            l10n.translate('select_address'),
            style: TextStyle(fontSize: isMobile ? 13 : 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue[700],
            side: BorderSide(color: Colors.blue[300]!),
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 8 : 10,
              horizontal: isMobile ? 12 : 16,
            ),
          ),
        ),
      );
    }

    // 显示已选地址
    final selectedAddress = _userAddresses.firstWhere(
      (addr) => addr['id'] == _selectedAddressId,
      orElse: () => {},
    );

    if (selectedAddress.isEmpty) {
      return const SizedBox.shrink();
    }

    final name = selectedAddress['name']?.toString() ?? '';
    final phone = selectedAddress['phone']?.toString() ?? '';
    final address = selectedAddress['address']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[700], size: isMobile ? 16 : 18),
          SizedBox(width: isMobile ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name $phone',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showAddressSelectionDialog,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 4 : 6,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppLocalizations.of(context).translate('change'),
              style: TextStyle(fontSize: isMobile ? 11 : 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理地址选择
  Future<void> _handleAddressSelection() async {
    await _loadUserAddresses();

    if (_userAddresses.isEmpty) {
      if (!mounted) return;

      // 显示提示对话框
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.translate('no_shipping_address')),
            content: Text(l10n.translate('user_no_address_create')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.translate('create')),
              ),
            ],
          );
        },
      );

      if (result == true && mounted) {
        // 显示创建地址对话框
        await _showCreateAddressDialog();
      }
      return;
    }

    // 有地址，显示地址选择对话框
    await _showAddressSelectionDialog();
  }

  /// 显示创建地址对话框
  Future<void> _showCreateAddressDialog() async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.translate('new_address')),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('recipient_name'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? l10n.translate('please_enter_recipient_name') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('contact_phone'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.isEmpty ?? true ? l10n.translate('please_enter_contact_phone') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: l10n.translate('detailed_address'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? l10n.translate('please_enter_detailed_address') : null,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: Text(l10n.translate('set_as_default')),
                      value: isDefault,
                      onChanged: (value) {
                        setDialogState(() => isDefault = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _saveAddressForUser(
                    name: nameController.text,
                    phone: phoneController.text,
                    address: addressController.text,
                    isDefault: isDefault,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.translate('confirm')),
            ),
          ],
        ),
      ),
    );
  }

  /// 为用户保存地址
  Future<void> _saveAddressForUser({
    required String name,
    required String phone,
    required String address,
    required bool isDefault,
  }) async {
    if (_selectedUser == null) return;

    try {
      final userId = _selectedUser!['id'] as int;
      final response = await ProxyOrderApi.saveAddressForUser(
        userId: userId,
        name: name,
        phone: phone,
        address: address,
        isDefault: isDefault,
      );

      if (response.isSuccess) {
        // 重新加载地址列表
        await _loadUserAddresses();
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          SnackBarUtil.showSuccess(context, l10n.translate('address_created_successfully'));
        }
      } else {
        if (mounted) {
          SnackBarUtil.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.translate('create_address_failed')}: $e');
      }
    }
  }

  /// 显示地址选择对话框
  Future<void> _showAddressSelectionDialog() async {
    if (_userAddresses.isEmpty) {
      await _loadUserAddresses();
    }

    if (_userAddresses.isEmpty) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, l10n.translate('user_no_shipping_address'));
      }
      return;
    }

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('select_shipping_address')),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _userAddresses.map((address) {
                final name = address['name']?.toString() ?? '';
                final phone = address['phone']?.toString() ?? '';
                final addressText = address['address']?.toString() ?? '';
                final addressId = address['id'];
                final isSelected = _selectedAddressId == addressId;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAddressId = addressId;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: isSelected ? Colors.blue[700] : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$name $phone',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                addressText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Colors.blue[700],
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// 构建用户搜索结果
  Widget _buildUserSearchResults() {
    final l10n = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _userSearchResults.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey[300]),
        itemBuilder: (context, index) {
          final user = _userSearchResults[index];
          final username = user['username']?.toString() ?? '';
          final nickname = user['nickname']?.toString() ?? '';
          final inviteCode = user['inviteCode']?.toString() ?? '';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[700]),
            ),
            title: Text(username.isNotEmpty ? username : nickname),
            subtitle: Text('${l10n.translate('invite_code_label')}: $inviteCode'),
            onTap: () {
              setState(() {
                _selectedUser = user;
                _userSearchResults.clear();
              });
            },
          );
        },
      ),
    );
  }

  /// 处理用户搜索
  Future<void> _handleUserSearch() async {
    final l10n = AppLocalizations.of(context);
    final keyword = _userSearchController.text.trim();
    if (keyword.isEmpty) {
      SnackBarUtil.showError(context, l10n.translate('please_enter_search_keyword'));
      return;
    }

    setState(() {
      _isLoadingUsers = true;
      _userSearchResults.clear();
    });

    try {
      final response = await ProxyOrderApi.searchUsers(keyword);
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final list = data['list'] as List<dynamic>? ?? [];

        // 过滤掉admin用户
        final filteredList =
            list.map((e) => e as Map<String, dynamic>).where((user) {
          final role = user['role']?.toString().toUpperCase() ?? '';
          return role != 'ADMIN';
        }).toList();

        setState(() {
          _userSearchResults.clear();
          _userSearchResults.addAll(filteredList);
          _isLoadingUsers = false;
        });
      } else {
        setState(() {
          _isLoadingUsers = false;
        });
        if (mounted) {
          SnackBarUtil.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.translate('search_failed')}: $e');
      }
    }
  }

  /// 处理店铺搜索
  Future<void> _handleShopSearch() async {
    final l10n = AppLocalizations.of(context);
    final keyword = _shopSearchController.text.trim();
    if (keyword.isEmpty) {
      SnackBarUtil.showError(context, l10n.translate('please_enter_shop_keyword'));
      return;
    }
    await _searchShops(keyword);
  }

  /// 处理商品搜索
  Future<void> _handleProductSearch() async {
    final l10n = AppLocalizations.of(context);
    final keyword = _productSearchController.text.trim();
    if (keyword.isEmpty) {
      SnackBarUtil.showError(context, l10n.translate('please_enter_product_keyword'));
      return;
    }
    await _searchProducts(keyword);
  }

  /// 搜索商品
  Future<void> _searchProducts(String keyword, {int page = 1}) async {
    setState(() {
      _isLoadingProducts = true;
      if (page == 1) {
        _productSearchResults.clear();
      }
    });

    try {
      final response = await ProxyOrderApi.searchProducts(keyword, page: page);
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final records = data['records'] as List<dynamic>? ?? [];
        final totalPages = (data['pages'] ?? data['totalPages'] ?? 1) as int;
        print('商品搜索响应数据: $data');
        print('商品总页数: $totalPages, 当前页: $page');
        setState(() {
          _productSearchResults.clear();
          _productSearchResults
              .addAll(records.map((e) => e as Map<String, dynamic>).toList());
          _productCurrentPage = page;
          _productTotalPages = totalPages;
          _isLoadingProducts = false;
        });
        print('商品状态更新后 - 当前页: $_productCurrentPage, 总页数: $_productTotalPages');
      } else {
        setState(() {
          _isLoadingProducts = false;
        });
        if (mounted) {
          SnackBarUtil.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.translate('search_failed')}: $e');
      }
    }
  }

  /// 搜索店铺
  Future<void> _searchShops(String keyword, {int page = 1}) async {
    setState(() {
      _isLoadingShops = true;
      if (page == 1) {
        _shopSearchResults.clear();
      }
    });

    try {
      final response = await ProxyOrderApi.searchShops(keyword, page: page);
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final records = data['records'] as List<dynamic>? ?? [];
        final totalPages = (data['pages'] ?? data['totalPages'] ?? 1) as int;
        print('店铺搜索响应数据: $data');
        print('店铺总页数: $totalPages, 当前页: $page');
        setState(() {
          _shopSearchResults.clear();
          _shopSearchResults.addAll(records.map((e) => e as Map<String, dynamic>).toList());
          _shopCurrentPage = page;
          _shopTotalPages = totalPages;
          _isLoadingShops = false;
        });
        print('店铺状态更新后 - 当前页: $_shopCurrentPage, 总页数: $_shopTotalPages');
      } else {
        setState(() {
          _isLoadingShops = false;
        });
        if (mounted) {
          SnackBarUtil.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingShops = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.translate('search_failed')}: $e');
      }
    }
  }

  /// 加载店铺商品
  Future<void> _loadShopProducts(int shopId) async {
    setState(() {
      _isLoadingProducts = true;
      _productSearchResults.clear();
    });

    try {
      final response = await ProxyOrderApi.getShopProducts(shopId);
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final records = data['records'] as List<dynamic>? ?? [];
        final totalPages = (data['pages'] ?? data['totalPages'] ?? 1) as int;
        setState(() {
          _productSearchResults.clear();
          _productSearchResults.addAll(records.map((e) => e as Map<String, dynamic>).toList());
          _productCurrentPage = 1;
          _productTotalPages = totalPages;
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
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.translate('load_products_failed')}: $e');
      }
    }
  }

  /// 加载用户地址
  Future<void> _loadUserAddresses() async {
    if (_selectedUser == null) {
      return;
    }

    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final userId = _selectedUser!['id'] as int;
      print('Loading addresses for user: $userId');
      final response = await ProxyOrderApi.getUserAddresses(userId);
      print('Address response: ${response.isSuccess}, data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        setState(() {
          _userAddresses = List<Map<String, dynamic>>.from(response.data!);
          _isLoadingAddresses = false;
          if (_userAddresses.isNotEmpty) {
            _selectedAddressId = _userAddresses[0]['id'];
          }
        });
        print('Loaded ${_userAddresses.length} addresses');
      } else {
        setState(() {
          _isLoadingAddresses = false;
        });
        print('Failed to load addresses: ${response.errorMessage}');
      }
    } catch (e) {
      setState(() {
        _isLoadingAddresses = false;
      });
      print('Error loading addresses: $e');
    }
  }

  /// 构建商品搜索区域
  Widget _buildProductSearchSection() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('search_products_title'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: isMobile ? 10 : 16),
          // 店铺搜索
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shopSearchController,
                  onSubmitted: (_) => _handleShopSearch(),
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_by_shop'),
                    hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    prefixIcon: Icon(Icons.store, size: isMobile ? 16 : 24),
                    suffixIcon: _hasShopSearchText
                        ? IconButton(
                            icon: Icon(Icons.clear, size: isMobile ? 14 : 24),
                            padding: isMobile ? EdgeInsets.zero : null,
                            constraints: isMobile ? BoxConstraints(minWidth: 28, minHeight: 28, maxWidth: 28, maxHeight: 28) : null,
                            splashRadius: isMobile ? 14 : null,
                            onPressed: () {
                              _shopSearchController.clear();
                              setState(() {
                                _shopSearchResults.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 6 : 12,
                    ),
                  ),
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoadingShops ? null : _handleShopSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 14 : 16,
                  ),
                ),
                child: _isLoadingShops
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(l10n.translate('search'), style: TextStyle(fontSize: isMobile ? 13 : 14)),
              ),
            ],
          ),
          if (_shopSearchResults.isNotEmpty) ...[
            SizedBox(height: isMobile ? 8 : 12),
            _buildShopSearchResults(),
          ],
          SizedBox(height: isMobile ? 8 : 12),
          // 商品直接搜索
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _productSearchController,
                  onSubmitted: (_) => _handleProductSearch(),
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_products_directly'),
                    hintStyle: TextStyle(fontSize: isMobile ? 13 : 14),
                    prefixIcon: Icon(Icons.search, size: isMobile ? 16 : 24),
                    suffixIcon: _hasProductSearchText
                        ? IconButton(
                            icon: Icon(Icons.clear, size: isMobile ? 14 : 24),
                            padding: isMobile ? EdgeInsets.zero : null,
                            constraints: isMobile ? BoxConstraints(minWidth: 28, minHeight: 28, maxWidth: 28, maxHeight: 28) : null,
                            splashRadius: isMobile ? 14 : null,
                            onPressed: () {
                              _productSearchController.clear();
                              setState(() {
                                _productSearchResults.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 6 : 12,
                    ),
                  ),
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoadingProducts ? null : _handleProductSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 14 : 16,
                  ),
                ),
                child: _isLoadingProducts
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(l10n.translate('search'), style: TextStyle(fontSize: isMobile ? 13 : 14)),
              ),
            ],
          ),
          if (_isLoadingProducts) ...[
            SizedBox(height: isMobile ? 10 : 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (!_isLoadingProducts && _productSearchResults.isNotEmpty) ...[
            SizedBox(height: isMobile ? 10 : 16),
            _buildProductSearchResults(),
          ],
        ],
      ),
    );
  }

  /// 构建商品搜索结果
  Widget _buildProductSearchResults() {
    final isMobile = ResponsiveUtil.isMobile(context);

    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _productSearchResults.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, index) {
          final product = _productSearchResults[index];
          final imageUrl = product['mainImage']?.toString() ?? '';
          final isAdded = _selectedProducts.any((p) => p['id'] == product['id']);
          final hasShop = product['shopId'] != null || (product['shopName']?.toString() ?? '').isNotEmpty;

          if (isMobile) {
            return Container(
              color: isAdded ? Colors.blue[50] : null,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              ImageUtil.getImageUrl(imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image, color: Colors.grey[400]);
                              },
                            ),
                          )
                        : Icon(Icons.image, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name']?.toString() ?? '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${product['price']} | ${product['shopName'] ?? ''}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 55,
                        height: 26,
                        child: TextButton(
                          onPressed: () => _showProductDetail(product),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            AppLocalizations.of(context).translate('details'),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: 55,
                        height: 26,
                        child: ElevatedButton(
                          onPressed: (isAdded || !hasShop) ? null : () => _addProduct(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (isAdded || !hasShop) ? Colors.grey : Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          child: isAdded
                              ? const Icon(Icons.check, size: 12)
                              : Text(
                                  hasShop ? AppLocalizations.of(context).translate('add') : '无店铺',
                                  style: const TextStyle(fontSize: 10),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return ListTile(
            tileColor: isAdded ? Colors.blue[50] : null,
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        ImageUtil.getImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, color: Colors.grey[400]);
                        },
                      ),
                    )
                  : Icon(Icons.image, color: Colors.grey[400]),
            ),
            title: Text(product['name']?.toString() ?? ''),
            subtitle: Text(
                hasShop
                  ? '\$${product['price']} | ${AppLocalizations.of(context).shop}: ${product['shopName'] ?? ''}'
                  : '\$${product['price']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _showProductDetail(product),
                  child: Text(AppLocalizations.of(context).translate('details')),
                ),
                ElevatedButton(
                  onPressed: (isAdded || !hasShop) ? null : () => _addProduct(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isAdded || !hasShop) ? Colors.grey : Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAdded) ...[
                        const Icon(Icons.check, size: 16),
                        const SizedBox(width: 4),
                      ],
                      Text(isAdded ? '已添加' : (hasShop ? AppLocalizations.of(context).translate('add') : '没有关联店铺')),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
        if (_productTotalPages > 1) ...[
          const SizedBox(height: 8),
          _buildPagination(
            currentPage: _productCurrentPage,
            totalPages: _productTotalPages,
            onPageChanged: (page) {
              final keyword = _productSearchController.text.trim();
              _searchProducts(keyword, page: page);
            },
          ),
        ],
      ],
    );
  }

  /// 添加商品
  void _addProduct(Map<String, dynamic> product) {
    setState(() {
      final existingIndex =
          _selectedProducts.indexWhere((p) => p['id'] == product['id']);
      if (existingIndex >= 0) {
        _selectedProducts[existingIndex]['quantity'] += 1;
      } else {
        _selectedProducts.add({
          ...product,
          'quantity': 1,
        });
      }
      // 不再清空搜索结果
      // _productSearchResults.clear();
    });
  }

  /// 显示商品详情
  void _showProductDetail(Map<String, dynamic> product) {
    final l10n = AppLocalizations.of(context);
    final imageUrl = product['mainImage']?.toString() ?? '';
    final name = product['name']?.toString() ?? '';
    final price = product['price']?.toString() ?? '0';
    final shopName = product['shopName']?.toString() ?? '';
    final stock = product['stock']?.toString() ?? '0';
    final description = product['description']?.toString() ?? l10n.translate('no_description_available');
    final category = product['categoryName']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 商品图片
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ImageUtil.getImageUrl(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image,
                                size: 80, color: Colors.grey[400]);
                          },
                        ),
                      )
                    : Icon(Icons.image, size: 80, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              // 价格
              Row(
                children: [
                  Text('${l10n.translate('price')}: ',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  Text(
                    '\$$price',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 店铺
              if (shopName.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.store, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${l10n.translate('shop')}: ',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[700])),
                    Text(shopName, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // 分类
              if (category.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${l10n.translate('category')}: ',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[700])),
                    Text(category, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // 库存
              Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${l10n.translate('stock')}: ',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  Text(stock, style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // 商品描述
              Text('${l10n.translate('product_description')}:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800])),
              const SizedBox(height: 8),
              Text(description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('add_to_order')),
          ),
        ],
      ),
    );
  }

  /// 构建已选商品区域
  Widget _buildSelectedProductsSection() {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    if (_selectedProducts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isMobile ? 24 : 40),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: isMobile ? 36 : 48, color: Colors.grey[400]),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                l10n.translate('no_products_selected'),
                style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('selected_products'),
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: isMobile ? 10 : 16),
          ..._selectedProducts
              .map((product) => _buildSelectedProductItem(product))
              .toList(),
        ],
      ),
    );
  }

  /// 构建已选商品项
  Widget _buildSelectedProductItem(Map<String, dynamic> product) {
    final imageUrl = product['mainImage']?.toString() ?? '';
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 50 : 60,
            height: isMobile ? 50 : 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      ImageUtil.getImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image, color: Colors.grey[400], size: isMobile ? 20 : 24);
                      },
                    ),
                  )
                : Icon(Icons.image, color: Colors.grey[400], size: isMobile ? 20 : 24),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product['price']}',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildQuantityControl(product),
          SizedBox(width: isMobile ? 8 : 12),
          IconButton(
            onPressed: () => _removeProduct(product),
            icon: Icon(Icons.delete_outline, size: isMobile ? 20 : 24),
            color: Colors.red[600],
            padding: EdgeInsets.all(isMobile ? 4 : 8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 构建数量控制
  Widget _buildQuantityControl(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _decreaseQuantity(product),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.remove, size: 16),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${product['quantity']}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          InkWell(
            onTap: () => _increaseQuantity(product),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// 增加数量
  void _increaseQuantity(Map<String, dynamic> product) {
    setState(() {
      product['quantity'] += 1;
    });
  }

  /// 减少数量
  void _decreaseQuantity(Map<String, dynamic> product) {
    if (product['quantity'] > 1) {
      setState(() {
        product['quantity'] -= 1;
      });
    }
  }

  /// 移除商品
  void _removeProduct(Map<String, dynamic> product) {
    setState(() {
      _selectedProducts.remove(product);
    });
  }

  /// 构建结算区域
  Widget _buildSummarySection() {
    if (_selectedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final total = _calculateTotal();
    final isMobile = ResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('total'),
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedUser != null ? _handleCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey[400],
              ),
              child: Text(
                _selectedUser != null ? l10n.translate('confirm_order') : l10n.translate('please_select_user_first'),
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 计算总价
  double _calculateTotal() {
    double total = 0;
    for (var product in _selectedProducts) {
      final price = product['price'];
      final quantity = product['quantity'] as int;

      double priceValue;
      if (price is int) {
        priceValue = price.toDouble();
      } else if (price is double) {
        priceValue = price;
      } else if (price is String) {
        priceValue = double.parse(price);
      } else {
        priceValue = 0.0;
      }

      total += priceValue * quantity;
    }
    return total;
  }

  /// 处理结算
  Future<void> _handleCheckout() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedUser == null) {
      SnackBarUtil.showError(context, l10n.translate('please_select_user_first'));
      return;
    }

    if (_selectedProducts.isEmpty) {
      SnackBarUtil.showError(context, l10n.translate('please_add_products_first'));
      return;
    }

    if (_selectedAddressId == null) {
      SnackBarUtil.showError(context, l10n.translate('please_select_shipping_address_first'));
      return;
    }

    // 直接显示支付密码输入框
    await _showPaymentPasswordDialog();
  }

  /// 显示支付密码输入对话框
  Future<void> _showPaymentPasswordDialog() async {
    final l10n = AppLocalizations.of(context);
    final passwordController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('payment_password')),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: l10n.translate('please_enter_payment_password'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _createProxyOrder(result);
    }
  }

  /// 创建代下订单
  Future<void> _createProxyOrder(String paymentPassword) async {
    if (_selectedUser == null || _selectedAddressId == null) {
      return;
    }

    try {
      final products = _selectedProducts
          .map((p) => {
                'productId': p['id'],
                'quantity': p['quantity'],
              })
          .toList();

      print('创建代下订单 - 用户ID: ${_selectedUser!['id']}');
      print('创建代下订单 - 地址ID: $_selectedAddressId');
      print('创建代下订单 - 商品列表: $products');

      final response = await ProxyOrderApi.createProxyOrder(
        userId: _selectedUser!['id'],
        addressId: _selectedAddressId!,
        products: products,
        paymentPassword: paymentPassword,
      );

      if (response.isSuccess) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          SnackBarUtil.showSuccess(context, l10n.translate('order_created_successfully'));
          setState(() {
            _selectedUser = null;
            _selectedProducts.clear();
            _userAddresses.clear();
            _selectedAddressId = null;
            _userSearchController.clear();
            _productSearchController.clear();
            _shopSearchController.clear();
          });
        }
      } else {
        if (mounted) {
          SnackBarUtil.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtil.showError(context, '${l10n.translate('create_order_failed')}: $e');
      }
    }
  }

  /// 构建店铺搜索结果
  Widget _buildShopSearchResults() {
    final isMobile = ResponsiveUtil.isMobile(context);
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _shopSearchResults.length,
            itemBuilder: (context, index) {
              final shop = _shopSearchResults[index];
              final name = shop['name']?.toString() ?? '';
              final description = shop['description']?.toString() ?? '';
              final isSelected = _selectedShop != null && _selectedShop!['id'] == shop['id'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedShop = shop;
                  });
                  _loadShopProducts(shop['id']);
                },
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : null,
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, size: isMobile ? 20 : 24, color: isSelected ? Colors.blue[700] : Colors.grey[600]),
                      SizedBox(width: isMobile ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.blue[700] : Colors.black,
                              ),
                            ),
                            if (description.isNotEmpty)
                              Text(description, style: TextStyle(fontSize: isMobile ? 11 : 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: Colors.blue[700]),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_shopTotalPages > 1) ...[
          const SizedBox(height: 8),
          _buildPagination(
            currentPage: _shopCurrentPage,
            totalPages: _shopTotalPages,
            onPageChanged: (page) {
              final keyword = _shopSearchController.text.trim();
              _searchShops(keyword, page: page);
            },
          ),
        ],
      ],
    );
  }

  /// 构建分页控件（简化版）
  Widget _buildPagination({
    required int currentPage,
    required int totalPages,
    required Function(int) onPageChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          color: currentPage > 1 ? Colors.blue[700] : Colors.grey,
        ),
        Text(
          '$currentPage / $totalPages',
          style: const TextStyle(fontSize: 14),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          color: currentPage < totalPages ? Colors.blue[700] : Colors.grey,
        ),
      ],
    );
  }
}
