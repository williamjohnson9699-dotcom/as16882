import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'http_client.dart';
import '../models/api_response.dart';

/// 文件API接口
class FileApi {
  static final HttpClient _client = HttpClient();

  /// 上传文件
  /// [filePath] 文件路径
  /// [fileName] 文件名（可选）
  /// [fileBytes] Web平台使用的文件字节数据
  /// [pathPrefix] 路径前缀（如：avatar, proof_image）
  static Future<ApiResponse<String>> uploadFile({
    required String filePath,
    String? fileName,
    List<int>? fileBytes,
    String pathPrefix = 'avatar',
  }) async {
    try {
      print('📤 开始上传文件: $filePath, 路径前缀: $pathPrefix');

      MultipartFile multipartFile;

      if (kIsWeb && fileBytes != null) {
        // Web平台使用字节数据
        multipartFile = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName ?? 'upload.jpg',
        );
      } else {
        // 移动/桌面平台使用文件路径
        multipartFile = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
        'pathPrefix': pathPrefix,
      });

      final response = await _client.post<String>(
        '/file/upload',
        data: formData,
      );

      print('✅ 文件上传响应: code=${response.code}, data=${response.data}');

      return response;
    } catch (e) {
      print('❌ 文件上传异常: $e');
      return ApiResponse<String>(
        code: -1,
        message: '文件上传失败: $e',
        cnMsg: '文件上传失败',
      );
    }
  }

  /// 获取文件预览URL
  /// [filename] 文件名（如：chat/xxx.jpg）
  static Future<ApiResponse<String>> getPreviewUrl(String filename) async {
    try {
      print('📷 获取预览URL: $filename');

      final response = await _client.get<String>('/file/preview/$filename');

      print('✅ 预览URL响应: code=${response.code}, data=${response.data}');

      return response;
    } catch (e) {
      print('❌ 获取预览URL异常: $e');
      return ApiResponse<String>(
        code: -1,
        message: '获取预览URL失败: $e',
        cnMsg: '获取预览URL失败',
      );
    }
  }
}
