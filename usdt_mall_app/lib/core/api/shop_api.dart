import 'package:usdt_mall_app/core/api/http_client.dart';
import 'package:usdt_mall_app/core/models/api_response.dart';

/// 店铺API
class ShopApi {
  static final _httpClient = HttpClient();

  /// 获取我的店铺信息
  static Future<ApiResponse> getMyShop() async {
    return await _httpClient.get('/shop/my-shop');
  }

  /// 获取店铺统计信息
  static Future<ApiResponse> getShopStatistics(int shopId) async {
    return await _httpClient.get('/shop/$shopId/statistics');
  }

  /// 获取店铺详情
  static Future<ApiResponse<Map<String, dynamic>>> getShopDetail(String shopId) async {
    return await _httpClient.get('/shop/$shopId');
  }

  /// 获取店铺商品列表
  static Future<ApiResponse<Map<String, dynamic>>> getShopProducts(
    String shopId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _httpClient.get('/shop/$shopId/products?page=$page&pageSize=$pageSize');
  }

  /// 关注店铺
  static Future<ApiResponse> followShop(String shopId) async {
    return await _httpClient.post('/shop/$shopId/follow', data: {});
  }

  /// 取消关注店铺
  static Future<ApiResponse> unfollowShop(String shopId) async {
    return await _httpClient.delete('/shop/$shopId/follow');
  }

  /// 获取我的关注列表
  static Future<ApiResponse<Map<String, dynamic>>> getMyFollows({
    String keyword = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _httpClient.get('/shop/my-follows?keyword=$keyword&page=$page&pageSize=$pageSize');
  }

  /// 获取我的关注统计
  static Future<ApiResponse<Map<String, dynamic>>> getMyFollowStats() async {
    return await _httpClient.get('/shop/my-follow-stats');
  }

  /// 更新店铺信息
  static Future<ApiResponse> updateShop(String shopId, Map<String, dynamic> data) async {
    return await _httpClient.put('/shop/$shopId', data: data);
  }
}
