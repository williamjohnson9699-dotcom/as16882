import 'http_client.dart';
import '../models/api_response.dart';

/// 店铺申请API接口
class ShopApplicationApi {
  static final HttpClient _client = HttpClient();

  /// 提交店铺申请
  static Future<ApiResponse<void>> submitApplication(Map<String, dynamic> data) async {
    return await _client.post('/shop-application/submit', data: data);
  }

  /// 获取我的申请
  static Future<ApiResponse<Map<String, dynamic>>> getMyApplication() async {
    return await _client.get('/shop-application/my');
  }

  /// 获取我的申请历史
  static Future<ApiResponse<List<dynamic>>> getMyApplicationHistory() async {
    return await _client.get('/shop-application/my/history');
  }

  /// 分页查询申请列表
  static Future<ApiResponse<Map<String, dynamic>>> getApplicationsByPage({
    String? status,
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (status != null && status != 'all') {
      queryParams['status'] = status;
    }

    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    return await _client.get(
      '/shop-application/page',
      queryParameters: queryParams,
    );
  }

  /// 审核通过
  static Future<ApiResponse<void>> approveApplication(int id) async {
    return await _client.post('/shop-application/approve/$id');
  }

  /// 审核拒绝
  static Future<ApiResponse<void>> rejectApplication(int id, String reviewNote) async {
    return await _client.post(
      '/shop-application/reject/$id',
      queryParameters: {'reviewNote': reviewNote},
    );
  }

  /// 获取待审核数量
  static Future<ApiResponse<int>> getPendingCount() async {
    return await _client.get('/shop-application/pending-count');
  }
}
