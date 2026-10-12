import 'package:flutter/material.dart';
import '../../core/api/address_api.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/responsive_util.dart';

/// 地址选择对话框
class AddressSelectDialog extends StatefulWidget {
  const AddressSelectDialog({super.key});

  @override
  State<AddressSelectDialog> createState() => _AddressSelectDialogState();
}

class _AddressSelectDialogState extends State<AddressSelectDialog> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;
  int? _selectedAddressId;

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
      final response = await AddressApi.getAddressList();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _addresses = (response.data as List).cast<Map<String, dynamic>>();
          _isLoading = false;

          // 默认选中默认地址
          for (var address in _addresses) {
            if (address['isDefault'] == 1) {
              _selectedAddressId = address['id'];
              break;
            }
          }
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : 600,
        constraints: BoxConstraints(maxHeight: isMobile ? double.infinity : 500),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.selectShippingAddress,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 地址列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _addresses.isEmpty
                      ? _buildEmptyView()
                      : _buildAddressList(),
            ),
            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedAddressId == null
                        ? null
                        : () {
                            final selectedAddress = _addresses.firstWhere(
                              (addr) => addr['id'] == _selectedAddressId,
                            );
                            Navigator.of(context).pop(selectedAddress);
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
          ],
        ),
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            l10n.noShippingAddress,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showAddAddressDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.addAddress),
          ),
        ],
      ),
    );
  }

  /// 构建地址列表
  Widget _buildAddressList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final isSelected = address['id'] == _selectedAddressId;
        final isDefault = address['isDefault'] == 1;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAddressId = address['id'];
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? Colors.blue[50] : Colors.white,
            ),
            child: Row(
              children: [
                // 选中图标
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.blue[700] : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                // 地址信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            address['phone'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                AppLocalizations.of(context).defaultAddress,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address['address'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示添加地址对话框
  void _showAddAddressDialog() {
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
          title: Text(l10n.newAddress),
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
    required String name,
    required String phone,
    required String address,
    required bool isDefault,
  }) async {
    final l10n = AppLocalizations.of(context);
    try {
      final response = await AddressApi.saveAddress(
        name: name,
        phone: phone,
        address: address,
        isDefault: isDefault ? 1 : 0,
      );

      if (response.isSuccess) {
        await _loadAddresses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.addressAddedSuccess)),
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
}
