import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:usdt_mall_app/core/api/shop_application_api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:usdt_mall_app/core/api/file_api.dart';
import 'package:usdt_mall_app/core/constants/api_constants.dart';
import '../../../core/utils/image_util.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';

/// 申请店铺视图
class ApplyShopView extends StatefulWidget {
  const ApplyShopView({super.key});

  @override
  State<ApplyShopView> createState() => _ApplyShopViewState();
}

class _ApplyShopViewState extends State<ApplyShopView> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedCategory;
  String? _shopLogoPath;
  String? _idFrontPath;
  String? _idBackPath;
  bool _isSubmitting = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _applicationHistory = [];
  bool _showForm = false;
  bool _cannotApply = false; // 是否不能申请（有待审核或已通过的申请）

  @override
  void initState() {
    super.initState();
    _loadApplicationHistory();
  }

  /// 加载申请历史
  Future<void> _loadApplicationHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ShopApplicationApi.getMyApplicationHistory();
      if (response.isSuccess && response.data != null) {
        final history = (response.data as List).cast<Map<String, dynamic>>();
        // 检查是否有待审核或已通过的申请
        final cannotApply = history.any((app) =>
          app['status'] == 'approved' || app['status'] == 'pending'
        );

        setState(() {
          _applicationHistory = history;
          _cannotApply = cannotApply;
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

  @override
  void dispose() {
    _shopNameController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _idNumberController.dispose();
    _inviteCodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// 将类别值转换为国际化文本
  String _getCategoryText(String category, AppLocalizations l10n) {
    switch (category) {
      case '全部':
        return l10n.all;
      case '生活':
        return l10n.life;
      case '男鞋':
        return l10n.menShoes;
      case '女鞋':
        return l10n.womenShoes;
      case '配饰':
        return l10n.accessories;
      case '男装':
        return l10n.menClothing;
      case '女装':
        return l10n.womenClothing;
      case '男包':
        return l10n.menBags;
      case '女包':
        return l10n.womenBags;
      case '男童':
        return l10n.boyClothing;
      case '女童':
        return l10n.girlClothing;
      case '全球购':
        return l10n.globalShopping;
      default:
        return category;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isMobile)
                Text(
                  l10n.applyShop,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ElevatedButton.icon(
                onPressed: _cannotApply && !_showForm
                    ? null
                    : () {
                        setState(() {
                          _showForm = !_showForm;
                          if (_showForm) {
                            // 清空表单
                            _shopNameController.clear();
                            _contactNameController.clear();
                            _contactPhoneController.clear();
                            _idNumberController.clear();
                            _inviteCodeController.clear();
                            _addressController.clear();
                            _selectedCategory = null;
                            _shopLogoPath = null;
                            _idFrontPath = null;
                            _idBackPath = null;
                          }
                        });
                      },
                icon: Icon(_showForm ? Icons.list : Icons.add),
                label: Text(_showForm ? l10n.viewHistory : l10n.newApplication),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showForm
                    ? _buildApplicationForm()
                    : _buildApplicationHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationHistory() {
    final l10n = AppLocalizations.of(context);
    if (_applicationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noApplicationRecords,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cannotApply
                  ? null
                  : () {
                      setState(() {
                        _showForm = true;
                      });
                    },
              icon: const Icon(Icons.add),
              label: Text(l10n.applyNow),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _applicationHistory.length,
      itemBuilder: (context, index) => _buildHistoryItem(_applicationHistory[index]),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> application) {
    final l10n = AppLocalizations.of(context);
    final status = application['status'] as String;
    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'approved'
            ? Colors.green
            : Colors.red;
    final statusText = status == 'pending'
        ? l10n.pending
        : status == 'approved'
            ? l10n.approved
            : l10n.rejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  ImageUtil.getImageUrl(application['shopLogo'] ?? ''),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(Icons.store, color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application['shopName'] ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.contactPerson}：${application['contactName']} | ${application['contactPhone']}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.mainBusiness}：${_getCategoryText(application['category'], l10n)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (application['reviewNote'] != null && application['reviewNote'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.reviewNote}：${application['reviewNote']}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _showDetailDialog(application),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[700]!),
                ),
                child: Text(l10n.viewDetails),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationForm() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          _buildShopLogoField(),
          const SizedBox(height: 20),
          _buildTextField(l10n.shopName, _shopNameController, l10n.pleaseEnterShopName),
          const SizedBox(height: 20),
          _buildTextField(l10n.contactPerson, _contactNameController, l10n.pleaseEnterContactName),
          const SizedBox(height: 20),
          _buildTextField(l10n.contactPhone, _contactPhoneController, l10n.pleaseEnterContactPhone),
          const SizedBox(height: 20),
          _buildTextField(l10n.idNumber, _idNumberController, l10n.pleaseEnterIdNumber),
          const SizedBox(height: 20),
          _buildTextField(l10n.inviteCode, _inviteCodeController, l10n.pleaseEnterInviteCode),
          const SizedBox(height: 20),
          _buildIdCardFields(),
          const SizedBox(height: 20),
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          _buildTextField(l10n.detailedAddress, _addressController, l10n.pleaseEnterDetailedAddress, maxLines: 3),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildShopLogoField() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.shopLogo} *', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickShopLogo,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _shopLogoPath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(l10n.uploadLogo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ImageUtil.getImageUrl(_shopLogoPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1, bool required = true}) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(required ? '$label *' : label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return l10n.thisFieldIsRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildIdCardFields() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.passportIdCard} *', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildIdCardUpload(l10n.frontSide, _idFrontPath, () => _pickIdCard(true))),
            const SizedBox(width: 16),
            Expanded(child: _buildIdCardUpload(l10n.backSide, _idBackPath, () => _pickIdCard(false))),
          ],
        ),
      ],
    );
  }

  Widget _buildIdCardUpload(String label, String? path, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: path == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ImageUtil.getImageUrl(path),
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.mainBusiness} *', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            hintText: l10n.pleaseSelectMainBusiness,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: [
            DropdownMenuItem(value: '全部', child: Text(l10n.all)),
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
          onChanged: (value) => setState(() => _selectedCategory = value),
          validator: (value) => value == null ? l10n.pleaseSelectMainBusiness : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(l10n.submitApplication, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  void _pickShopLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // 读取图片字节
        final fileBytes = await image.readAsBytes();
        final fileName = image.name;

        // 上传图片
        final response = await FileApi.uploadFile(
          filePath: image.path,
          fileName: fileName,
          fileBytes: fileBytes,
          pathPrefix: 'shop_logo',
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            _shopLogoPath = response.data!;
          });
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.logoUploadSuccess)),
            );
          }
        } else {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message ?? l10n.uploadFailed)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.uploadFailed}: $e')),
        );
      }
    }
  }

  void _pickIdCard(bool isFront) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // 读取图片字节
        final fileBytes = await image.readAsBytes();
        final fileName = image.name;

        // 上传图片
        final response = await FileApi.uploadFile(
          filePath: image.path,
          fileName: fileName,
          fileBytes: fileBytes,
          pathPrefix: 'id_card',
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            if (isFront) {
              _idFrontPath = response.data!;
            } else {
              _idBackPath = response.data!;
            }
          });
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isFront ? l10n.frontPhotoUploadSuccess : l10n.backPhotoUploadSuccess)),
            );
          }
        } else {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message ?? l10n.uploadFailed)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.uploadFailed}: $e')),
        );
      }
    }
  }

  void _submitForm() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 验证必填图片
    if (_shopLogoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseUploadShopLogo)),
      );
      return;
    }

    if (_idFrontPath == null || _idBackPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseUploadIdPhotos)),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectMainBusiness)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final data = {
        'shopName': _shopNameController.text.trim(),
        'shopLogo': _shopLogoPath,
        'contactName': _contactNameController.text.trim(),
        'contactPhone': _contactPhoneController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'idFrontImage': _idFrontPath,
        'idBackImage': _idBackPath,
        'category': _selectedCategory,
        'address': _addressController.text.trim(),
        'inviteCode': _inviteCodeController.text.trim(),
      };

      final response = await ShopApplicationApi.submitApplication(data);

      setState(() {
        _isSubmitting = false;
      });

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.applicationSubmitted)),
          );
          // 重新加载申请历史并切换回历史视图
          setState(() {
            _showForm = false;
          });
          _loadApplicationHistory();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.errorMessage)),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.submitFailed}: $e')),
        );
      }
    }
  }

  void _showDetailDialog(Map<String, dynamic> application) {
    final l10n = AppLocalizations.of(context);
    final status = application['status'] as String;
    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'approved'
            ? Colors.green
            : Colors.red;
    final statusText = status == 'pending'
        ? l10n.pending
        : status == 'approved'
            ? l10n.approved
            : l10n.rejected;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shopApplicationDetails),
        content: SingleChildScrollView(
          child: Container(
            width: 600,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailSection(l10n.basicInformation, [
                  _buildDetailRow(l10n.shopName, application['shopName'] ?? ''),
                  _buildDetailRow(l10n.mainBusiness, _getCategoryText(application['category'] ?? '', l10n)),
                  _buildDetailRow(l10n.applicationStatus, statusText, valueColor: statusColor),
                ]),
                const Divider(height: 32),
                _buildDetailSection(l10n.contactInformation, [
                  _buildDetailRow(l10n.contactPerson, application['contactName'] ?? ''),
                  _buildDetailRow(l10n.contactPhone, application['contactPhone'] ?? ''),
                  _buildDetailRow(l10n.idNumber, application['idNumber'] ?? ''),
                  _buildDetailRow(l10n.inviteCode, application['inviteCode'] ?? ''),
                  _buildDetailRow(l10n.detailedAddress, application['address'] ?? ''),
                ]),
                const Divider(height: 32),
                _buildDetailSection(l10n.shopLogo, [
                  const SizedBox(height: 8),
                  _buildImagePreview(application['shopLogo']),
                ]),
                const Divider(height: 32),
                _buildDetailSection(l10n.identityCredentials, [
                  const SizedBox(height: 8),
                  _buildIdCardImages(application),
                ]),
                if (application['reviewNote'] != null && application['reviewNote'].toString().isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildDetailSection(l10n.reviewNote, [
                    Text(
                      application['reviewNote'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label：',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.grey[800],
                fontWeight: valueColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.store, size: 48, color: Colors.grey[400]),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        ImageUtil.getImageUrl(imageUrl),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.store, size: 48, color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildIdCardImages(Map<String, dynamic> application) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildIdCardImage(
            l10n.idFront,
            application['idFrontImage'],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildIdCardImage(
            l10n.idBack,
            application['idBackImage'],
          ),
        ),
      ],
    );
  }

  Widget _buildIdCardImage(String label, String? imageUrl) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (imageUrl != null && imageUrl.isNotEmpty) {
              _showImagePreviewDialog(imageUrl, label);
            }
          },
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: imageUrl == null || imageUrl.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noImage,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ImageUtil.getImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            l10n.imageLoadFailed,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showImagePreviewDialog(String imageUrl, String title) {
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
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                            '图片加载失败',
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
}
