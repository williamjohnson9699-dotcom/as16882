import 'http_client.dart';
import '../models/api_response.dart';

/// APP更新API接口
class AppUpdateApi {
  static final HttpClient _client = HttpClient();

  /// 上传APP文件
  /// [platform] 平台: android/ios
  /// [filePath] 文件路径（移动端/桌面端）
  /// [fileBytes] 文件字节数据（Web平台）
  /// [fileName] 文件名（Web平台必需）
  static Future<ApiResponse<String>> uploadAppFile({
    required String platform,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    return await _client.upload(
      '/app-version/upload',
      filePath,
      fileKey: 'file',
      data: {
        'platform': platform,
      },
      fileBytes: fileBytes,
      fileName: fileName,
      onSendProgress: (sent, total) {
        print('上传进度: ${(sent / total * 100).toStringAsFixed(2)}%');
      },
    );
  }

  /// 保存版本信息
  /// [platform] 平台: ANDROID/IOS
  /// [versionCode] 版本号
  /// [versionName] 版本名称
  /// [downloadUrl] 下载地址
  /// [updateDesc] 更新描述
  /// [isForceUpdate] 是否强制更新
  static Future<ApiResponse<void>> saveVersion({
    required String platform,
    required int versionCode,
    required String versionName,
    required String downloadUrl,
    String? updateDesc,
    int isForceUpdate = 0,
  }) async {
    return await _client.post(
      '/app-version/save',
      data: {
        'platform': platform,
        'versionCode': versionCode,
        'versionName': versionName,
        'downloadUrl': downloadUrl,
        'updateDesc': updateDesc,
        'isForceUpdate': isForceUpdate,
        'status': 1,
      },
    );
  }

  /// 获取版本历史列表
  /// [platform] 平台筛选: ANDROID/IOS，为空则查询所有
  /// [page] 页码
  /// [pageSize] 每页数量
  static Future<ApiResponse<Map<String, dynamic>>> getVersionHistory({
    String? platform,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, dynamic> params = {
      'page': page,
      'pageSize': pageSize,
    };
    if (platform != null && platform.isNotEmpty) {
      params['platform'] = platform;
    }
    return await _client.get(
      '/app-version/list',
      queryParameters: params,
    );
  }

  /// 删除版本
  /// [versionId] 版本ID
  static Future<ApiResponse<void>> deleteVersion(int versionId) async {
    return await _client.delete('/app-version/$versionId');
  }

  /// 获取最新版本信息
  /// [platform] 平台: ANDROID/IOS
  static Future<ApiResponse<Map<String, dynamic>>> getLatestVersion(
    String platform,
  ) async {
    return await _client.get(
      '/app-version/latest',
      queryParameters: {'platform': platform},
    );
  }
}
