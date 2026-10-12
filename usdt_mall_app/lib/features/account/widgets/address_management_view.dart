import 'package:flutter/material.dart';
import '../../../core/api/address_management_api.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';

/// 地址管理视图
class AddressManagementView extends StatefulWidget {
  const AddressManagementView({super.key});

  @override
  State<AddressManagementView> createState() => _AddressManagementViewState();
}

class _AddressManagementViewState extends State<AddressManagementView> {
  List<Map<String, dynamic>> _addresses = [];
  final Set<int> _selectedIndices = {};
  bool _selectAll = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  /// 加载地址列表
  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AddressManagementApi.getAddressList();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _addresses = List<Map<String, dynamic>>.from(response.data!);
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

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 桌面端显示标题行
          if (!isMobile)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.addressManagement,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddAddressDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newAddress),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          // 移动端显示新建按钮
          if (isMobile)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddAddressDialog,
                icon: const Icon(Icons.add),
                label: Text(l10n.newAddress),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          SizedBox(height: isMobile ? 16 : 24),
          _buildToolbar(),
          const SizedBox(height: 16),
          Expanded(child: _buildAddressList()),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Checkbox(
          value: _selectAll,
          onChanged: (value) {
            setState(() {
              _selectAll = value ?? false;
              if (_selectAll) {
                _selectedIndices.addAll(List.generate(_addresses.length, (i) => i));
              } else {
                _selectedIndices.clear();
              }
            });
          },
        ),
        Text(l10n.selectAll),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _selectedIndices.isEmpty ? null : _deleteSelected,
          icon: const Icon(Icons.delete),
          label: Text('${l10n.deleteSelected} (${_selectedIndices.length})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressList() {
    final l10n = AppLocalizations.of(context);
    if (_addresses.isEmpty) {
      return Center(child: Text(l10n.noAddresses));
    }

    return ListView.builder(
      itemCount: _addresses.length,
      itemBuilder: (context, index) => _buildAddressItem(index),
    );
  }

  Widget _buildAddressItem(int index) {
    final address = _addresses[index];
    final isSelected = _selectedIndices.contains(index);
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedIndices.add(index);
                } else {
                  _selectedIndices.remove(index);
                }
                _selectAll = _selectedIndices.length == _addresses.length;
              });
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      address['phone'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (address['isDefault']) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.defaultAddress,
                          style: TextStyle(fontSize: 12, color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address['address'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _showEditAddressDialog(index),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: l10n.edit,
              ),
              IconButton(
                onPressed: () => _deleteAddress(index),
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                tooltip: l10n.delete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog() {
    _showAddressDialog(null);
  }

  void _showEditAddressDialog(int index) {
    _showAddressDialog(_addresses[index]);
  }

  /// 显示地址对话框（新增或编辑）
  void _showAddressDialog(Map<String, dynamic>? address) {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: address?['name'] ?? '');
    final phoneController = TextEditingController(text: address?['phone'] ?? '');
    final addressController = TextEditingController(text: address?['address'] ?? '');
    bool isDefault = address?['isDefault'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(address == null ? l10n.newAddress : l10n.editAddress),
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
                        labelText: l10n.recipientName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? l10n.pleaseEnterRecipientName : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.contactPhone,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.isEmpty ?? true ? l10n.pleaseEnterContactPhone : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: l10n.detailedAddress,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (v) => v?.isEmpty ?? true ? l10n.pleaseEnterDetailedAddress : null,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: Text(l10n.setAsDefault),
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
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _saveAddress(
                    id: address?['id'],
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
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存地址
  Future<void> _saveAddress({
    int? id,
    required String name,
    required String phone,
    required String address,
    required bool isDefault,
  }) async {
    final l10n = AppLocalizations.of(context);
    try {
      final response = await AddressManagementApi.saveAddress(
        id: id,
        name: name,
        phone: phone,
        address: address,
        isDefault: isDefault,
      );

      if (response.isSuccess) {
        await _loadAddresses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(id == null ? l10n.addressAddedSuccess : l10n.addressUpdatedSuccess)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.saveFailed}: ${response.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.saveFailed}: $e')),
        );
      }
    }
  }

  /// 删除单个地址
  void _deleteAddress(int index) {
    final l10n = AppLocalizations.of(context);
    final address = _addresses[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteThisAddress),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteAddress(address['id']);
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

  /// 执行删除地址
  Future<void> _performDeleteAddress(int id) async {
    final l10n = AppLocalizations.of(context);
    try {
      final response = await AddressManagementApi.deleteAddress(id);
      if (response.isSuccess) {
        await _loadAddresses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteSuccess)),
          );
        }
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

  /// 批量删除地址
  void _deleteSelected() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteSelectedAddresses(_selectedIndices.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performBatchDelete();
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

  /// 执行批量删除
  Future<void> _performBatchDelete() async {
    final l10n = AppLocalizations.of(context);
    final ids = _selectedIndices.map((index) => _addresses[index]['id'] as int).toList();

    try {
      final response = await AddressManagementApi.batchDeleteAddresses(ids);
      if (response.isSuccess) {
        _selectedIndices.clear();
        _selectAll = false;
        await _loadAddresses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.batchDeleteSuccess)),
          );
        }
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
}
