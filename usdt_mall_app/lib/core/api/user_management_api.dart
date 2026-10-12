import '../models/api_response.dart';
import 'http_client.dart';

/// 用户管理API接口
class UserManagementApi {
  static final HttpClient _client = HttpClient();

  /// 查询用户列表
  /// [keyword] 搜索关键词（ID、用户名、昵称）
  /// [role] 角色筛选
  /// [page] 页码
  /// [pageSize] 每页数量
  static Future<ApiResponse<Map<String, dynamic>>> queryUsers({
    String? keyword,
    String? role,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _client.post(
      '/user-management/query',
      data: {
        'keyword': keyword,
        'role': role,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 修改用户角色
  /// [userId] 用户ID
  /// [role] 新角色
  static Future<ApiResponse<void>> updateUserRole({
    required int userId,
    required String role,
  }) async {
    return await _client.post(
      '/user-management/update-role',
      data: {
        'userId': userId,
        'role': role,
      },
    );
  }

  /// 删除用户
  /// [userId] 用户ID
  static Future<ApiResponse<void>> deleteUser(int userId) async {
    return await _client.delete('/user-management/$userId');
  }
}
