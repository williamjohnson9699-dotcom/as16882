import 'http_client.dart';
import '../models/api_response.dart';

/// 权限管理API接口
class PermissionManagementApi {
  static final HttpClient _client = HttpClient();

  /// 获取用户列表
  /// [keyword] 搜索关键词（姓名、手机号、邮箱）
  /// [role] 角色筛选: all/normal_user/shop_user/customer_service/admin
  /// [page] 页码
  /// [pageSize] 每页数量
  static Future<ApiResponse<Map<String, dynamic>>> getUserList({
    String? keyword,
    String role = 'all',
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _client.get(
      '/api/permission/users',
      queryParameters: {
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        'role': role,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 添加用户
  /// [name] 姓名
  /// [phone] 手机号
  /// [email] 邮箱
  static Future<ApiResponse<Map<String, dynamic>>> addUser({
    required String name,
    required String phone,
    required String email,
  }) async {
    return await _client.post(
      '/api/permission/users',
      data: {
        'name': name,
        'phone': phone,
        'email': email,
      },
    );
  }

  /// 修改用户信息
  /// [userId] 用户ID
  /// [name] 姓名
  /// [phone] 手机号
  /// [email] 邮箱
  static Future<ApiResponse<Map<String, dynamic>>> updateUser({
    required String userId,
    required String name,
    required String phone,
    required String email,
  }) async {
    return await _client.put(
      '/api/permission/users/$userId',
      data: {
        'name': name,
        'phone': phone,
        'email': email,
      },
    );
  }

  /// 修改用户角色
  /// [userId] 用户ID
  /// [role] 角色: normal_user/shop_user/customer_service/admin
  static Future<ApiResponse<void>> updateUserRole({
    required String userId,
    required String role,
  }) async {
    return await _client.put(
      '/api/permission/users/$userId/role',
      data: {'role': role},
    );
  }

  /// 删除用户
  /// [userId] 用户ID
  static Future<ApiResponse<void>> deleteUser(String userId) async {
    return await _client.delete('/api/permission/users/$userId');
  }
}
