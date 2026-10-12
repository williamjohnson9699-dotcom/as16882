import '../constants/api_constants.dart';

/// 图片工具类
/// 用于处理图片 URL 的拼接和转换
class ImageUtil {
  /// 将相对路径转换为完整的图片 URL
  ///
  /// 参数:
  /// - [relativePath]: 相对路径，如 "avatar/64ceffb951d2466ca8adb04b293c5111.jpg"
  ///
  /// 返回:
  /// - 完整的图片 URL，如 "http://10.0.2.2:8080/api/v1/file/download/avatar/64ceffb951d2466ca8adb04b293c5111.jpg"
  /// - 如果 relativePath 为空或已经是完整 URL，则返回原值
  static String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }

    // 如果已经是完整的 URL（以 http:// 或 https:// 开头），直接返回
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }

    // 拼接完整的图片 URL
    return '${ApiConstants.baseUrl}${ApiConstants.downloadFile(relativePath)}';
  }

  /// 从完整 URL 中提取相对路径
  ///
  /// 参数:
  /// - [fullUrl]: 完整的图片 URL
  ///
  /// 返回:
  /// - 相对路径，如 "avatar/64ceffb951d2466ca8adb04b293c5111.jpg"
  /// - 如果不是完整 URL，则返回原值
  static String getRelativePath(String? fullUrl) {
    if (fullUrl == null || fullUrl.isEmpty) {
      return '';
    }

    // 如果不是完整 URL，直接返回
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      return fullUrl;
    }

    // 提取 /file/download/ 后面的部分
    final downloadPrefix = '/file/download/';
    final index = fullUrl.indexOf(downloadPrefix);
    if (index != -1) {
      return fullUrl.substring(index + downloadPrefix.length);
    }

    // 如果没有找到 /file/download/，返回原值
    return fullUrl;
  }

  /// 批量转换相对路径为完整 URL
  static List<String> getImageUrls(List<String>? relativePaths) {
    if (relativePaths == null || relativePaths.isEmpty) {
      return [];
    }
    return relativePaths.map((path) => getImageUrl(path)).toList();
  }
}
