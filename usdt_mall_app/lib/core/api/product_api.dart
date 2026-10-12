import 'http_client.dart';
import '../models/api_response.dart';

/// 商品API
class ProductApi {
  static final HttpClient _client = HttpClient();

  /// 获取商品详情
  static Future<ApiResponse<Map<String, dynamic>>> getProductDetail(String productId) async {
    return await _client.get('/product/$productId');
  }

  /// 获取推荐商品列表（猜你喜欢）
  static Future<ApiResponse<Map<String, dynamic>>> getRecommendProducts(
    String productId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _client.get('/product/$productId/recommend?page=$page&pageSize=$pageSize');
  }

  /// 获取商品关联的店铺列表
  static Future<ApiResponse<List<Map<String, dynamic>>>> getProductShops(int productId) async {
    final response = await _client.get('/product/$productId/shops');

    // 手动转换数据类型
    if (response.isSuccess && response.data != null) {
      final List<dynamic> dataList = response.data as List<dynamic>;
      final List<Map<String, dynamic>> shops = dataList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      return ApiResponse<List<Map<String, dynamic>>>(
        code: response.code,
        message: response.message,
        cnMsg: response.cnMsg,
        data: shops,
      );
    }

    return ApiResponse<List<Map<String, dynamic>>>(
      code: response.code,
      message: response.message,
      cnMsg: response.cnMsg,
      data: null,
    );
  }
}
