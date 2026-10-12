import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/api/file_api.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';

/// 商品图片上传对话框
class ProductImageUploadDialog extends StatefulWidget {
  final Function(List<String>) onImagesSelected;
  final int maxImages;

  const ProductImageUploadDialog({
    super.key,
    required this.onImagesSelected,
    this.maxImages = 5,
  });

  @override
  State<ProductImageUploadDialog> createState() => _ProductImageUploadDialogState();
}

class _ProductImageUploadDialogState extends State<ProductImageUploadDialog> {
  List<XFile> _selectedImages = [];
  bool _isUploading = false;
  List<String> _uploadedImageUrls = [];
  String _uploadStatus = '';
  int _uploadedCount = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text('${l10n.translate('add_product_images')} (${_uploadedImageUrls.length}/${widget.maxImages})'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 显示选中的图片预览
            _buildImagesPreview(),
            const SizedBox(height: 16),
            // 选择图片按钮
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickImages,
              icon: const Icon(Icons.image),
              label: Text('${l10n.translate('select_images')} (${l10n.translate('max')} ${widget.maxImages})'),
            ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
            // 显示上传状态信息
            if (_uploadStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _uploadedImageUrls.length == _selectedImages.length && _selectedImages.isNotEmpty
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _uploadedImageUrls.length == _selectedImages.length && _selectedImages.isNotEmpty
                          ? Colors.green[300]!
                          : Colors.orange[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _uploadedImageUrls.length == _selectedImages.length && _selectedImages.isNotEmpty
                            ? Icons.check_circle
                            : Icons.info,
                        color: _uploadedImageUrls.length == _selectedImages.length && _selectedImages.isNotEmpty
                            ? Colors.green[700]
                            : Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadStatus,
                          style: TextStyle(
                            fontSize: 13,
                            color: _uploadedImageUrls.length == _selectedImages.length && _selectedImages.isNotEmpty
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
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: (_isUploading || _uploadedImageUrls.isEmpty) ? null : _confirmAdd,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }

  Widget _buildImagesPreview() {
    if (_selectedImages.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedImages.map((image) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<Uint8List>(
                future: image.readAsBytes(),
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
        }).toList(),
      );
    } else {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              '请选择图片',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context);
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        // 检查图片数量限制
        if (images.length > widget.maxImages) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.translate('max_images_limit')}: ${widget.maxImages}')),
            );
          }
          return;
        }

        setState(() {
          _selectedImages = images;
          _uploadedImageUrls.clear();
          _uploadedCount = 0;
        });

        // 立即上传所有图片
        await _uploadImages();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('select_image_failed')}: $e')),
        );
      }
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isUploading = true;
      _uploadStatus = '${l10n.translate('uploading_images_progress')}: 0/${_selectedImages.length}';
    });

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];

        setState(() {
          _uploadStatus = '${l10n.translate('uploading_images_progress')}: ${i + 1}/${_selectedImages.length}';
        });

        // 读取图片字节
        final fileBytes = await image.readAsBytes();
        final fileName = image.name;

        // 上传图片
        final response = await FileApi.uploadFile(
          filePath: image.path,
          fileName: fileName,
          fileBytes: fileBytes,
        );

        if (response.isSuccess && response.data != null) {
          setState(() {
            _uploadedImageUrls.add(response.data!);
            _uploadedCount++;
          });
        } else {
          setState(() {
            _uploadStatus = '✗ 第${i + 1}张图片上传失败: ${response.errorMessage}';
          });
          break;
        }
      }

      if (_uploadedImageUrls.length == _selectedImages.length) {
        setState(() {
          _uploadStatus = '✓ 所有图片上传成功！共${_uploadedImageUrls.length}张';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = '✗ 上传异常: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _confirmAdd() {
    if (_uploadedImageUrls.isNotEmpty) {
      widget.onImagesSelected(_uploadedImageUrls);
      Navigator.pop(context);
    }
  }
}
