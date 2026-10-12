import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api/app_update_api.dart';
import '../../core/utils/snackbar_util.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants/api_constants.dart';

/// 下载APP对话框
class DownloadAppDialog extends StatefulWidget {
  const DownloadAppDialog({super.key});

  @override
  State<DownloadAppDialog> createState() => _DownloadAppDialogState();
}

class _DownloadAppDialogState extends State<DownloadAppDialog> {
  String _selectedPlatform = 'android'; // 默认选择Android
  Map<String, dynamic>? _androidVersion;
  Map<String, dynamic>? _iosVersion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  /// 加载版本信息
  Future<void> _loadVersionInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 并行加载Android和iOS版本信息
      final results = await Future.wait([
        AppUpdateApi.getLatestVersion('ANDROID'),
        AppUpdateApi.getLatestVersion('IOS'),
      ]);

      setState(() {
        if (results[0].isSuccess && results[0].data != null) {
          _androidVersion = results[0].data as Map<String, dynamic>;
        }
        if (results[1].isSuccess && results[1].data != null) {
          _iosVersion = results[1].data as Map<String, dynamic>;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('加载版本信息失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部背景图
            _buildHeader(),
            // 平台选择和二维码区域
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildPlatformSelector(),
                  const SizedBox(height: 24),
                  _buildQRCodeSection(),
                  const SizedBox(height: 24),
                  _buildCloseButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部背景
  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        image: const DecorationImage(
          image: AssetImage('assets/pic/download_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Text(
          l10n.downloadApp,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建平台选择器
  Widget _buildPlatformSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPlatformButton('Android', 'android', Icons.android),
        const SizedBox(width: 24),
        _buildPlatformButton('iOS', 'ios', Icons.apple),
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
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[700] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(height: 8),
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

  /// 构建二维码区域
  Widget _buildQRCodeSection() {
    final versionInfo = _selectedPlatform == 'android' ? _androidVersion : _iosVersion;
    final downloadUrl = versionInfo?['downloadUrl']?.toString() ?? '';

    // 构建完整的下载URL
    final fullUrl = downloadUrl.isNotEmpty
        ? (downloadUrl.startsWith('http')
            ? downloadUrl
            : '${ApiConstants.baseUrl}/file/download/$downloadUrl')
        : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // 二维码
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.grey[400],
                    ),
                  )
                : fullUrl.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.qr_code_2,
                          size: 150,
                          color: Colors.grey[400],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: QrImageView(
                          data: fullUrl,
                          version: QrVersions.auto,
                          size: 184,
                          backgroundColor: Colors.white,
                        ),
                      ),
          ),
          const SizedBox(height: 16),
          // APP图标和版本信息
          _buildAppInfo(),
        ],
      ),
    );
  }

  /// 构建APP信息
  Widget _buildAppInfo() {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      );
    }

    final versionInfo = _selectedPlatform == 'android' ? _androidVersion : _iosVersion;

    if (versionInfo == null) {
      return Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            l10n.noVersionAvailable(_selectedPlatform == 'android' ? 'Android' : 'iOS'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }

    final versionName = versionInfo['versionName']?.toString() ?? '';
    final versionCode = versionInfo['versionCode']?.toString() ?? '';
    final updateDesc = versionInfo['updateDesc']?.toString() ?? '';
    final downloadUrl = versionInfo['downloadUrl']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'AS1688',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${l10n.version}: $versionName (${l10n.build} $versionCode)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        if (updateDesc.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.updateNotes}:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  updateDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: downloadUrl.isNotEmpty ? () => _handleDownload(downloadUrl) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              disabledBackgroundColor: Colors.grey[400],
            ),
            icon: const Icon(Icons.download),
            label: Text(l10n.downloadNow),
          ),
        ),
      ],
    );
  }

  /// 处理下载
  Future<void> _handleDownload(String downloadUrl) async {
    final l10n = AppLocalizations.of(context);
    try {
      // 构建完整的下载URL
      final fullUrl = downloadUrl.startsWith('http')
          ? downloadUrl
          : '${ApiConstants.baseUrl}/file/download/$downloadUrl';

      print('开始下载: $fullUrl');

      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SnackBarUtil.showError(context, l10n.cannotOpenDownloadLink);
        }
      }
    } catch (e) {
      print('下载失败: $e');
      if (mounted) {
        SnackBarUtil.showError(context, '${l10n.downloadFailed}: $e');
      }
    }
  }

  /// 构建关闭按钮
  Widget _buildCloseButton() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(l10n.close),
      ),
    );
  }
}
