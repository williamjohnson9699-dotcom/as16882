import 'package:usdt_mall_app/core/api/http_client.dart';
import 'package:usdt_mall_app/core/models/api_response.dart';

/// 购物车API
class CartApi {
  static final _httpClient = HttpClient();

  /// 添加商品到购物车
  static Future<ApiResponse> addToCart({
    required int productId,
    required int shopId,
    required int quantity,
  }) async {
    return await _httpClient.post('/cart', data: {
      'productId': productId,
      'shopId': shopId,
      'quantity': quantity,
    });
  }

  /// 获取购物车列表
  static Future<ApiResponse<List<dynamic>>> getCartList() async {
    return await _httpClient.get('/cart');
  }

  /// 获取购物车商品数量
  static Future<ApiResponse<int>> getCartCount() async {
    return await _httpClient.get('/cart/count');
  }

  /// 更新购物车商品数量
  static Future<ApiResponse> updateCartQuantity({
    required int cartId,
    required int quantity,
  }) async {
    return await _httpClient.put('/cart/$cartId', data: {
      'quantity': quantity,
    });
  }

  /// 删除购物车商品
  static Future<ApiResponse> deleteCart(int cartId) async {
    return await _httpClient.delete('/cart/$cartId');
  }
}
