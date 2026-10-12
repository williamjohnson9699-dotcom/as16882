import 'http_client.dart';
import '../models/api_response.dart';

/// 系统公告管理API接口
class AnnouncementManagementApi {
  static final HttpClient _client = HttpClient();

  /// 获取公告列表
  static Future<ApiResponse<List<dynamic>>> getAnnouncementList() async {
    return await _client.get('/announcement-management/list');
  }

  /// 保存公告（新增或编辑）
  static Future<ApiResponse<void>> saveAnnouncement(Map<String, dynamic> data) async {
    return await _client.post('/announcement-management/save', data: data);
  }

  /// 删除公告
  static Future<ApiResponse<void>> deleteAnnouncement(int id) async {
    return await _client.delete('/announcement-management/$id');
  }

  /// 批量删除公告
  static Future<ApiResponse<void>> batchDeleteAnnouncements(List<int> ids) async {
    return await _client.post('/announcement-management/batch-delete', data: ids);
  }
}
