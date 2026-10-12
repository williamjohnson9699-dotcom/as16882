import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/api/shop_api.dart';
import '../../../core/api/file_api.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/l10n/app_localizations.dart';

/// 编辑店铺信息对话框
class EditShopDialog extends StatefulWidget {
  final Map<String, dynamic> shopData;

  const EditShopDialog({
    super.key,
    required this.shopData,
  });

  @override
  State<EditShopDialog> createState() => _EditShopDialogState();
}

class _EditShopDialogState extends State<EditShopDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _logoController;
  late TextEditingController _orderCountController;
  late TextEditingController _salesAmountController;
  late TextEditingController _followCountController;
  late TextEditingController _levelController;
  late TextEditingController _ratingController;
  late TextEditingController _viewsController;
  late TextEditingController _creditScoreController;

  bool _isSubmitting = false;
  XFile? _selectedImage;
  bool _isUploading = false;
  String? _uploadedLogoUrl;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shopData['name'] ?? '');
    _logoController = TextEditingController(text: widget.shopData['logo'] ?? '');
    _orderCountController = TextEditingController(text: (widget.shopData['orderCount'] ?? 0).toString());
    _salesAmountController = TextEditingController(text: (widget.shopData['salesAmount'] ?? 0).toString());
    _followCountController = TextEditingController(text: (widget.shopData['followCount'] ?? 0).toString());
    _levelController = TextEditingController(text: (widget.shopData['level'] ?? 5).toString());
    _ratingController = TextEditingController(text: (widget.shopData['rating'] ?? 4.8).toString());
    _viewsController = TextEditingController(text: (widget.shopData['views'] ?? 0).toString());
    _creditScoreController = TextEditingController(text: (widget.shopData['creditScore'] ?? 98).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    _orderCountController.dispose();
    _salesAmountController.dispose();
    _followCountController.dispose();
    _levelController.dispose();
    _ratingController.dispose();
    _viewsController.dispose();
    _creditScoreController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 使用上传后的logo URL，如果没有上传则使用原来的
      final logoUrl = _uploadedLogoUrl ?? _logoController.text.trim();

      final data = {
        'name': _nameController.text.trim(),
        'logo': logoUrl,
        'orderCount': int.tryParse(_orderCountController.text) ?? 0,
        'salesAmount': double.tryParse(_salesAmountController.text) ?? 0,
        'followCount': int.tryParse(_followCountController.text) ?? 0,
        'level': int.tryParse(_levelController.text) ?? 5,
        'rating': double.tryParse(_ratingController.text) ?? 4.8,
        'views': int.tryParse(_viewsController.text) ?? 0,
        'creditScore': int.tryParse(_creditScoreController.text) ?? 98,
      };

      final response = await ShopApi.updateShop(widget.shopData['id'].toString(), data);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (response.isSuccess) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('update_success'))),
          );
          Navigator.of(context).pop(true);
        } else {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? l10n.translate('update_failed'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('update_failed')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('edit_shop'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: l10n.translate('shop_name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.translate('shop_name_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLogoUploadSection(l10n),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        controller: _orderCountController,
                        label: l10n.translate('order_count'),
                        maxValue: 100000,
                      ),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        controller: _salesAmountController,
                        label: l10n.translate('sales_amount'),
                        maxValue: 40000000,
                        isDecimal: true,
                      ),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        controller: _followCountController,
                        label: l10n.followCount,
                        maxValue: 500,
                      ),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        controller: _levelController,
                        label: l10n.translate('shop_level_label'),
                        maxValue: 10,
                      ),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        controller: _ratingController,
                        label: l10n.shopRating,
                        maxValue: 5,
                        isDecimal: true,
                      ),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        controller: _viewsController,
                        label: l10n.views,
                        maxValue: 500000,
                      ),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        controller: _creditScoreController,
                        label: l10n.creditScore,
                        maxValue: 100,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n.confirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建Logo上传区域
  Widget _buildLogoUploadSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('shop_logo'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Logo预览
            _buildLogoPreview(),
            const SizedBox(width: 16),
            // 上传按钮
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(l10n.selectImage),
                  ),
                  if (_isUploading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(),
                    ),
                  // 显示上传状态信息
                  if (_uploadStatus.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _uploadedLogoUrl != null
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _uploadedLogoUrl != null
                                ? Colors.green[300]!
                                : Colors.orange[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _uploadedLogoUrl != null
                                  ? Icons.check_circle
                                  : Icons.info,
                              color: _uploadedLogoUrl != null
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _uploadStatus,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _uploadedLogoUrl != null
                                      ? Colors.green[900]
                                      : Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建Logo预览
  Widget _buildLogoPreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<Uint8List>(
          future: _selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              );
            }
            return const CircularProgressIndicator();
          },
        ),
      );
    } else if (_logoController.text.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          ImageUtil.getImageUrl(_logoController.text),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 100,
              height: 100,
              color: Colors.grey[300],
              child: Icon(Icons.store, size: 50, color: Colors.grey[700]),
            );
          },
        ),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
        ),
        child: Icon(Icons.store, size: 50, color: Colors.grey[700]),
      );
    }
  }

  /// 选择图片
  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context);
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });

        // 立即上传图片
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.selectImageFailed}: $e')),
        );
      }
    }
  }

  /// 上传图片
  Future<void> _uploadImage() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = l10n.uploadingImageText;
    });

    try {
      // 读取图片字节
      final fileBytes = await _selectedImage!.readAsBytes();
      final fileName = _selectedImage!.name;

      // 上传图片
      final response = await FileApi.uploadFile(
        filePath: _selectedImage!.path,
        fileName: fileName,
        fileBytes: fileBytes,
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          _uploadedLogoUrl = response.data!;
          _uploadStatus = '${l10n.uploadSuccessFile}: ${response.data!}';
        });
      } else {
        setState(() {
          _uploadStatus = '${l10n.uploadFailedText}: ${response.errorMessage}';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = '${l10n.uploadErrorText}: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required int maxValue,
    bool isDecimal = false,
  }) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: '${l10n.translate('max')}: $maxValue',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [
        if (!isDecimal) FilteringTextInputFormatter.digitsOnly,
        if (isDecimal) FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.translate('field_required');
        }
        final number = isDecimal ? double.tryParse(value) : int.tryParse(value);
        if (number == null) {
          return l10n.translate('invalid_number');
        }
        if (number > maxValue) {
          return '${l10n.translate('max')}: $maxValue';
        }
        if (number < 0) {
          return l10n.translate('must_be_positive');
        }
        return null;
      },
    );
  }
}
