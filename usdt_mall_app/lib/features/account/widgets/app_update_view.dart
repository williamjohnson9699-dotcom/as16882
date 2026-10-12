import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/api/app_update_api.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive_util.dart';
import '../../../core/utils/date_util.dart';

/// APP更新视图
class AppUpdateView extends StatefulWidget {
  const AppUpdateView({super.key});

  @override
  State<AppUpdateView> createState() => _AppUpdateViewState();
}

class _AppUpdateViewState extends State<AppUpdateView> {
  String _selectedPlatform = 'android';
  final _versionController = TextEditingController();
  final _versionCodeController = TextEditingController();
  final _updateDescController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 版本历史数据
  List<Map<String, dynamic>> _versionHistory = [];
  bool _isLoadingHistory = false;
  bool _isUploading = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  List<int>? _selectedFileBytes; // Web平台使用

  @override
  void initState() {
    super.initState();
    _loadVersionHistory();
  }

  @override
  void dispose() {
    _versionController.dispose();
    _versionCodeController.dispose();
    _updateDescController.dispose();
    super.dispose();
  }

  /// 加载版本历史
  Future<void> _loadVersionHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final response = await AppUpdateApi.getVersionHistory();
      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final records = data['records'] as List<dynamic>? ?? [];
        setState(() {
          _versionHistory = records.map((e) => e as Map<String, dynamic>).toList();
          _isLoadingHistory = false;
        });
      } else {
        setState(() {
          _isLoadingHistory = false;
        });
        if (mounted) {
          SnackBarUtil.showError(context, response.errorMessage);
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
      });
      if (mounted) {
        SnackBarUtil.showError(context, '加载版本历史失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtil.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            _buildTitle(),
            const SizedBox(height: 24),
          ],
          _buildUploadSection(),
          const SizedBox(height: 32),
          _buildHistorySection(),
        ],
      ),
    );
  }

  /// 构建标题
  Widget _buildTitle() {
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.appUpdateManagement,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  /// 构建上传区域
  Widget _buildUploadSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.uploadNewVersion,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            _buildPlatformSelector(),
            const SizedBox(height: 20),
            _buildVersionInput(),
            const SizedBox(height: 20),
            _buildFileUpload(),
            const SizedBox(height: 24),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  /// 构建平台选择器
  Widget _buildPlatformSelector() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectPlatform,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPlatformButton('Android', 'android', Icons.android),
            const SizedBox(width: 16),
            _buildPlatformButton('iOS', 'ios', Icons.apple),
          ],
        ),
      ],
    );
  }

  /// 构建平台按钮
  Widget _buildPlatformButton(String label, String platform, IconData icon) {
    final isSelected = _selectedPlatform == platform;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlatform = platform;
        });
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建版本号输入
  Widget _buildVersionInput() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.versionInfo,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _versionController,
                decoration: InputDecoration(
                  labelText: l10n.versionName,
                  hintText: l10n.versionNameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterVersionName;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _versionCodeController,
                decoration: InputDecoration(
                  labelText: l10n.versionCode,
                  hintText: l10n.versionCodeHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterVersionCode;
                  }
                  if (int.tryParse(value) == null) {
                    return l10n.versionCodeMustBeNumber;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _updateDescController,
          decoration: InputDecoration(
            labelText: l10n.updateDescription,
            hintText: l10n.updateDescriptionHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  /// 构建文件上传
  Widget _buildFileUpload() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appFile,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedFileName != null ? Colors.blue[300]! : Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFileName != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                  size: 48,
                  color: _selectedFileName != null ? Colors.blue[700] : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedFileName ?? l10n.clickToSelectFile,
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedFileName != null ? Colors.blue[700] : Colors.grey[600],
                    fontWeight: _selectedFileName != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedPlatform == 'android' ? l10n.supportApkFile : l10n.supportIpaFile,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 选择文件
  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context);
    try {
      print('开始选择文件，平台: $_selectedPlatform, 运行环境: ${kIsWeb ? "Web" : "Native"}');

      FilePickerResult? result;

      if (kIsWeb) {
        // Web平台：使用any类型，手动验证扩展名
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true, // Web平台需要读取字节数据
        );
      } else {
        // 移动端/桌面端：使用custom类型限制文件扩展名
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: _selectedPlatform == 'android' ? ['apk'] : ['ipa'],
          allowMultiple: false,
        );
      }

      print('文件选择结果: ${result != null ? "有结果" : "无结果"}');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('选择的文件: ${file.name}');

        // 检查文件扩展名
        final fileName = file.name.toLowerCase();
        final expectedExt = _selectedPlatform == 'android' ? '.apk' : '.ipa';

        if (!fileName.endsWith(expectedExt)) {
          if (mounted) {
            final fileType = _selectedPlatform == 'android' ? l10n.apkFile : l10n.ipaFile;
            SnackBarUtil.showError(
              context,
              '${l10n.pleaseSelectCorrectFileType}（${fileType}${l10n.translate('file')}）'
            );
          }
          return;
        }

        setState(() {
          _selectedFileName = file.name;
          if (kIsWeb) {
            // Web平台：使用字节数据
            _selectedFileBytes = file.bytes;
            _selectedFilePath = null;
            print('Web平台，文件大小: ${file.bytes?.length ?? 0} 字节');
          } else {
            // 移动端/桌面端：使用文件路径
            _selectedFilePath = file.path;
            _selectedFileBytes = null;
            print('Native平台，文件路径: ${file.path}');
          }
        });
        print('文件选择成功: $_selectedFileName');
      } else {
        print('用户取消选择文件');
      }
    } catch (e, stackTrace) {
      print('选择文件失败: $e');
      print('堆栈跟踪: $stackTrace');
      if (mounted) {
        SnackBarUtil.showError(context, '${l10n.selectFileFailed}: $e');
      }
    }
  }

  /// 构建上传按钮
  Widget _buildUploadButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _handleUpload,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                l10n.uploadVersion,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
      ),
    );
  }

  /// 处理上传
  Future<void> _handleUpload() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFileName == null) {
      SnackBarUtil.showError(context, l10n.pleaseSelectAppFile);
      return;
    }

    // 检查是否有文件数据
    if (kIsWeb && _selectedFileBytes == null) {
      SnackBarUtil.showError(context, l10n.fileDataInvalid);
      return;
    }

    if (!kIsWeb && _selectedFilePath == null) {
      SnackBarUtil.showError(context, l10n.filePathInvalid);
      return;
    }

    print('开始上传文件...');
    print('平台: $_selectedPlatform');
    print('运行环境: ${kIsWeb ? "Web" : "Native"}');
    print('文件名: $_selectedFileName');
    if (kIsWeb) {
      print('文件大小: ${_selectedFileBytes?.length ?? 0} 字节');
    } else {
      print('文件路径: $_selectedFilePath');
    }
    print('版本名称: ${_versionController.text}');
    print('版本号: ${_versionCodeController.text}');

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. 上传文件
      print('步骤1: 上传文件到服务器...');
      final uploadResponse = await AppUpdateApi.uploadAppFile(
        platform: _selectedPlatform,
        filePath: _selectedFilePath,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
      );

      print('上传响应: isSuccess=${uploadResponse.isSuccess}, code=${uploadResponse.code}');
      print('上传响应数据: ${uploadResponse.data}');
      print('上传响应消息: ${uploadResponse.errorMessage}');

      if (!uploadResponse.isSuccess || uploadResponse.data == null) {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          SnackBarUtil.showError(context, '${l10n.fileUploadFailed}: ${uploadResponse.errorMessage}');
        }
        return;
      }

      final downloadUrl = uploadResponse.data as String;
      print('文件上传成功，下载地址: $downloadUrl');

      // 2. 保存版本信息
      print('步骤2: 保存版本信息...');
      final saveResponse = await AppUpdateApi.saveVersion(
        platform: _selectedPlatform.toUpperCase(),
        versionCode: int.parse(_versionCodeController.text),
        versionName: _versionController.text,
        downloadUrl: downloadUrl,
        updateDesc: _updateDescController.text.isEmpty ? null : _updateDescController.text,
      );

      print('保存响应: isSuccess=${saveResponse.isSuccess}, code=${saveResponse.code}');
      print('保存响应消息: ${saveResponse.errorMessage}');

      setState(() {
        _isUploading = false;
      });

      if (saveResponse.isSuccess) {
        if (mounted) {
          SnackBarUtil.showSuccess(context, l10n.versionUploadSuccess);
          // 清空表单
          _versionController.clear();
          _versionCodeController.clear();
          _updateDescController.clear();
          _selectedFilePath = null;
          _selectedFileName = null;
          _selectedFileBytes = null;
          // 重新加载版本历史
          _loadVersionHistory();
        }
      } else {
        if (mounted) {
          SnackBarUtil.showError(context, '${l10n.saveVersionInfoFailed}: ${saveResponse.errorMessage}');
        }
      }
    } catch (e, stackTrace) {
      print('上传过程发生异常: $e');
      print('堆栈跟踪: $stackTrace');
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        SnackBarUtil.showError(context, '${l10n.uploadFailed}: $e');
      }
    }
  }

  /// 构建历史版本区域
  Widget _buildHistorySection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.versionHistory,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingHistory
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            : _versionHistory.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        l10n.noVersionHistory,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                : _buildHistoryTable(),
      ],
    );
  }

  /// 构建历史版本表格
  Widget _buildHistoryTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ..._versionHistory.map((version) => _buildTableRow(version)).toList(),
        ],
      ),
    );
  }

  /// 构建表格头部
  Widget _buildTableHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          _buildHeaderCell(l10n.platform, flex: 1),
          _buildHeaderCell(l10n.versionName, flex: 1),
          _buildHeaderCell(l10n.versionCode, flex: 1),
          _buildHeaderCell(l10n.uploadTime, flex: 2),
          _buildHeaderCell(l10n.action, flex: 1),
        ],
      ),
    );
  }

  /// 构建表头单元格
  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  /// 构建表格行
  Widget _buildTableRow(Map<String, dynamic> version) {
    final platform = version['platform']?.toString() ?? '';
    final versionName = version['versionName']?.toString() ?? '';
    final versionCode = version['versionCode']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          _buildCell(
            platform.toUpperCase() == 'ANDROID' ? 'Android' : 'iOS',
            flex: 1,
          ),
          _buildCell(versionName, flex: 1),
          _buildCell(versionCode, flex: 1),
          _buildCell(
            DateUtil.formatDateTime(DateUtil.parseAsLocalDateTime(version['createTime'])),
            flex: 2,
          ),
          _buildActionCell(version),
        ],
      ),
    );
  }

  /// 构建状态单元格
  Widget _buildStatusCell(int status) {
    final l10n = AppLocalizations.of(context);
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status == 1 ? Colors.green[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status == 1 ? l10n.enabled : l10n.disabled,
            style: TextStyle(
              fontSize: 12,
              color: status == 1 ? Colors.green[700] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// 构建单元格
  Widget _buildCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  /// 构建操作单元格
  Widget _buildActionCell(Map<String, dynamic> version) {
    final l10n = AppLocalizations.of(context);
    return Expanded(
      flex: 1,
      child: Row(
        children: [
          TextButton(
            onPressed: () => _handleDelete(version),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.delete, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  /// 处理删除
  Future<void> _handleDelete(Map<String, dynamic> version) async {
    final l10n = AppLocalizations.of(context);
    final versionName = version['versionName']?.toString() ?? '';
    final versionId = version['id'] as int?;

    if (versionId == null) {
      SnackBarUtil.showError(context, l10n.versionIdInvalid);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteVersion.replaceAll('{version}', versionName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final response = await AppUpdateApi.deleteVersion(versionId);
                if (response.isSuccess) {
                  if (mounted) {
                    SnackBarUtil.showSuccess(context, l10n.deleteSuccess);
                    _loadVersionHistory();
                  }
                } else {
                  if (mounted) {
                    SnackBarUtil.showError(context, response.errorMessage);
                  }
                }
              } catch (e) {
                if (mounted) {
                  SnackBarUtil.showError(context, '${l10n.deleteFailed}: $e');
                }
              }
            },
            child: Text(l10n.delete, style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
  }
}
