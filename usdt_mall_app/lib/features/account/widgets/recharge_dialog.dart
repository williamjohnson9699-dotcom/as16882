import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/api/file_api.dart';
import '../../../core/api/system_config_api.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';

/// 充值对话框
class RechargeDialog extends StatefulWidget {
  final Function(String paymentMethod, double amount, String remark, String? proofImage, String receivingAddress) onSubmit;

  const RechargeDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<RechargeDialog> createState() => _RechargeDialogState();
}

class _RechargeDialogState extends State<RechargeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();

  String _selectedPaymentMethod = 'USDT-TRC20';
  bool _isSubmitting = false;
  XFile? _selectedImage;
  bool _isUploading = false;
  String? _uploadedProofImageUrl;
  String _uploadStatus = '';
  String _receivingAddress = '';
  bool _isLoadingAddress = true;

  final List<String> _paymentMethods = [
    'USDT-TRC20',
    'USDT-ERC20',
    'BTC',
    'ETH',
  ];

  @override
  void initState() {
    super.initState();
    _loadReceivingAddress();
  }

  Future<void> _loadReceivingAddress() async {
    try {
      final response = await SystemConfigApi.getReceivingAddress();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _receivingAddress = response.data!;
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveUtil.isMobile(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      title: Text(l10n.recharge),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPaymentMethodDropdown(),
                const SizedBox(height: 16),
                _buildAmountField(),
                const SizedBox(height: 16),
                _buildReceivingAddressField(),
                const SizedBox(height: 16),
                _buildRemarkField(),
                const SizedBox(height: 16),
                _buildProofImageSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.submit),
        ),
      ],
    );
  }

  /// 构建充值方式下拉选择
  Widget _buildPaymentMethodDropdown() {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: InputDecoration(
        labelText: l10n.paymentMethod,
        border: const OutlineInputBorder(),
      ),
      items: _paymentMethods.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Text(method),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPaymentMethod = value;
          });
        }
      },
    );
  }

  /// 构建金额输入框
  Widget _buildAmountField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: l10n.rechargeAmount,
        border: const OutlineInputBorder(),
        prefixText: '\$ ',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.pleaseEnterRechargeAmount;
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return l10n.pleaseEnterValidAmount;
        }
        return null;
      },
    );
  }

  /// 构建收款地址输入框
  Widget _buildReceivingAddressField() {
    final l10n = AppLocalizations.of(context);
    if (_isLoadingAddress) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_receivingAddress.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          l10n.translate('receiving_address_not_configured'),
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.translate('receiving_address'), style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: Text(_receivingAddress)),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _receivingAddress));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.translate('copied'))),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建备注输入框
  Widget _buildRemarkField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _remarkController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: l10n.remarkOptional,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// 构建凭证图片上传部分
  Widget _buildProofImageSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('proof_image'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (_selectedImage != null) _buildImagePreview(),
        const SizedBox(height: 8),
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
        if (_uploadStatus.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _uploadedProofImageUrl != null
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _uploadedProofImageUrl != null
                      ? Colors.green[300]!
                      : Colors.orange[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _uploadedProofImageUrl != null
                        ? Icons.check_circle
                        : Icons.info,
                    color: _uploadedProofImageUrl != null
                        ? Colors.green[700]
                        : Colors.orange[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _uploadStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: _uploadedProofImageUrl != null
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
    );
  }

  /// 构建图片预览
  Widget _buildImagePreview() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<Uint8List>(
          future: _selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  /// 处理提交
  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context);

    if (_receivingAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('receiving_address_not_configured'))),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedProofImageUrl == null || _uploadedProofImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.translate('proof_image')}${l10n.translate('is_required')}')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final remark = _remarkController.text.trim();

      await widget.onSubmit(_selectedPaymentMethod, amount, remark, _uploadedProofImageUrl, _receivingAddress);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
    if (_selectedImage == null) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _isUploading = true;
      _uploadStatus = l10n.uploadingImage;
    });

    try {
      // 读取图片字节
      final fileBytes = await _selectedImage!.readAsBytes();
      final fileName = _selectedImage!.name;

      // 上传图片，指定路径前缀为 proof_image
      final response = await FileApi.uploadFile(
        filePath: _selectedImage!.path,
        fileName: fileName,
        fileBytes: fileBytes,
        pathPrefix: 'proof_image',
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          _uploadedProofImageUrl = response.data!;
          _uploadStatus = l10n.imageUploadSuccess;
        });
      } else {
        setState(() {
          _uploadStatus = '${l10n.uploadFailed}: ${response.errorMessage}';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = '${l10n.uploadError}: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
