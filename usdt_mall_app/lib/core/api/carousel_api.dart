import 'http_client.dart';
import '../models/api_response.dart';

/// 轮播商品API接口
class CarouselApi {
  static final HttpClient _client = HttpClient();

  /// 获取轮播商品列表
  static Future<ApiResponse<List<dynamic>>> getCarouselProducts() async {
    return await _client.get('/carousel/products');
  }

  /// 获取所有商品列表（用于选择）
  static Future<ApiResponse<List<dynamic>>> getAllProducts() async {
    return await _client.get('/carousel/all-products');
  }

  /// 分页搜索商品
  static Future<ApiResponse<Map<String, dynamic>>> searchProducts({
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (keyword != null && keyword.isNotEmpty) {
      params['keyword'] = keyword;
    }
    return await _client.get('/carousel/search-products', queryParameters: params);
  }

  /// 添加轮播商品
  /// [productId] 商品ID
  static Future<ApiResponse<void>> addCarouselProduct(int productId) async {
    return await _client.post('/carousel/products/$productId');
  }

  /// 删除轮播商品
  /// [carouselId] 轮播商品ID
  static Future<ApiResponse<void>> deleteCarouselProduct(int carouselId) async {
    return await _client.delete('/carousel/products/$carouselId');
  }

  /// 更新轮播商品排序
  /// [productIds] 商品ID列表（按顺序）
  static Future<ApiResponse<void>> updateCarouselOrder(List<int> productIds) async {
    return await _client.put(
      '/carousel/products/order',
      data: {'productIds': productIds},
    );
  }
}
