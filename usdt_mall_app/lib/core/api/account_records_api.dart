import 'http_client.dart';
import '../models/api_response.dart';

/// 账户记录API接口
class AccountRecordsApi {
  static final HttpClient _client = HttpClient();

  /// 分页查询记录
  /// type: null-全部, 1-充值, 2-提现
  static Future<ApiResponse<Map<String, dynamic>>> getRecordsByPage({
    int? type,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (type != null) {
      queryParams['type'] = type;
    }

    return await _client.get(
      '/account-records/page',
      queryParameters: queryParams,
    );
  }

  /// 管理员分页查询所有用户的记录
  /// keyword: 搜索关键词（用户名/昵称）
  /// type: null-全部, 1-充值, 2-提现
  static Future<ApiResponse<Map<String, dynamic>>> getAllRecordsByPage({
    String? keyword,
    int? type,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    if (type != null) {
      queryParams['type'] = type;
    }

    return await _client.get(
      '/account-records/admin/page',
      queryParameters: queryParams,
    );
  }

  /// 审核通过记录
  static Future<ApiResponse<void>> approveRecord(int recordId) async {
    return await _client.post('/account-records/admin/approve/$recordId');
  }

  /// 拒绝记录
  static Future<ApiResponse<void>> rejectRecord(int recordId) async {
    return await _client.post('/account-records/admin/reject/$recordId');
  }

  /// 获取待处理记录数量
  static Future<ApiResponse<Map<String, dynamic>>> getPendingCount() async {
    return await _client.get('/account-records/pending-count');
  }

  /// 标记记录为已读
  static Future<ApiResponse<void>> markAsRead(int recordId) async {
    return await _client.post('/account-records/$recordId/mark-read');
  }

  /// 批量标记记录为已读
  static Future<ApiResponse<void>> batchMarkAsRead(List<int> recordIds) async {
    return await _client.post('/account-records/batch-mark-read', data: {
      'recordIds': recordIds,
    });
  }
}
