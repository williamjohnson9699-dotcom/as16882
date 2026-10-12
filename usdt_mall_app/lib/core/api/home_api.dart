import 'http_client.dart';
import '../models/api_response.dart';

/// 首页API
class HomeApi {
  static final HttpClient _client = HttpClient();

  /// 获取热卖商品
  static Future<ApiResponse<Map<String, dynamic>>> getHotProducts({
    int limit = 30,
  }) async {
    return await _client.get(
      '/home/hot-products',
      queryParameters: {
        'limit': limit,
      },
    );
  }

  /// 获取每日新发现商品
  static Future<ApiResponse<Map<String, dynamic>>> getDailyDiscover({
    int limit = 8,
  }) async {
    return await _client.get(
      '/home/daily-discover',
      queryParameters: {
        'limit': limit,
      },
    );
  }
}
