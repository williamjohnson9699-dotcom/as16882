import 'http_client.dart';
import '../models/api_response.dart';

/// 搜索API
class SearchApi {
  static final HttpClient _client = HttpClient();

  /// 搜索商品
  static Future<ApiResponse<Map<String, dynamic>>> searchProducts({
    required String keyword,
    int page = 1,
    int pageSize = 12,
  }) async {
    return await _client.post(
      '/search/products',
      data: {
        'keyword': keyword,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 搜索店铺
  static Future<ApiResponse<Map<String, dynamic>>> searchShops({
    required String keyword,
    int page = 1,
    int pageSize = 12,
  }) async {
    return await _client.post(
      '/search/shops',
      data: {
        'keyword': keyword,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }
}
