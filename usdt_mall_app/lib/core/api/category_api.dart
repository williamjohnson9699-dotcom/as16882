import 'package:usdt_mall_app/core/api/http_client.dart';
import 'package:usdt_mall_app/core/models/api_response.dart';

/// 分类API
class CategoryApi {
  static final _httpClient = HttpClient();

  /// 获取所有分类列表
  static Future<ApiResponse<List<dynamic>>> getAllCategories() async {
    return await _httpClient.get('/category/list');
  }

  /// 根据分类ID获取商品列表
  static Future<ApiResponse<Map<String, dynamic>>> getProductsByCategory(
    int categoryId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _httpClient.get('/product/category/$categoryId?page=$page&pageSize=$pageSize');
  }

  /// 获取热销商品列表（分页）
  static Future<ApiResponse<Map<String, dynamic>>> getHotProducts({
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _httpClient.get('/home/hot-products?page=$page&pageSize=$pageSize');
  }
}
