import 'http_client.dart';
import '../models/api_response.dart';

/// 代下订单API接口
class ProxyOrderApi {
  static final HttpClient _client = HttpClient();

  /// 搜索用户
  /// [keyword] 搜索关键词（用户名、手机号、邮箱）
  static Future<ApiResponse<Map<String, dynamic>>> searchUsers(
    String keyword,
  ) async {
    return await _client.post(
      '/user-management/query',
      data: {
        'keyword': keyword,
        'page': 1,
        'pageSize': 10,
      },
    );
  }

  /// 搜索商品
  /// [keyword] 商品关键词（商品名称、编号）
  /// [page] 页码
  static Future<ApiResponse<Map<String, dynamic>>> searchProducts(
    String keyword, {
    int page = 1,
  }) async {
    return await _client.get(
      '/product/search',
      queryParameters: {'keyword': keyword, 'page': page, 'pageSize': 10},
    );
  }

  /// 获取商品详情
  /// [productId] 商品ID
  static Future<ApiResponse<Map<String, dynamic>>> getProductDetail(
    int productId,
  ) async {
    return await _client.get('/product/$productId');
  }

  /// 获取用户地址列表
  /// [userId] 用户ID
  static Future<ApiResponse<List<dynamic>>> getUserAddresses(int userId) async {
    return await _client.get('/address-management/user/$userId/addresses');
  }

  /// 搜索店铺
  /// [keyword] 店铺关键词
  /// [page] 页码
  static Future<ApiResponse<Map<String, dynamic>>> searchShops(
    String keyword, {
    int page = 1,
  }) async {
    return await _client.get(
      '/shop/search',
      queryParameters: {'keyword': keyword, 'page': page, 'pageSize': 5},
    );
  }

  /// 获取店铺商品列表
  /// [shopId] 店铺ID
  static Future<ApiResponse<Map<String, dynamic>>> getShopProducts(
    int shopId,
  ) async {
    return await _client.get(
      '/shop/$shopId/products',
      queryParameters: {'page': 1, 'pageSize': 10},
    );
  }

  /// 创建代下订单
  /// [userId] 用户ID
  /// [addressId] 收货地址ID
  /// [products] 商品列表 [{productId, quantity}]
  /// [paymentPassword] 支付密码
  /// [remark] 订单备注
  static Future<ApiResponse<int>> createProxyOrder({
    required int userId,
    required int addressId,
    required List<Map<String, dynamic>> products,
    required String paymentPassword,
    String? remark,
  }) async {
    return await _client.post(
      '/order/proxy',
      data: {
        'userId': userId,
        'addressId': addressId,
        'products': products,
        'paymentPassword': paymentPassword,
        if (remark != null) 'remark': remark,
      },
    );
  }

  /// 为指定用户保存地址
  /// [userId] 用户ID
  /// [name] 收货人姓名
  /// [phone] 联系电话
  /// [address] 详细地址
  /// [isDefault] 是否设为默认地址
  static Future<ApiResponse<void>> saveAddressForUser({
    required int userId,
    required String name,
    required String phone,
    required String address,
    required bool isDefault,
  }) async {
    return await _client.post(
      '/address-management/user/$userId/save',
      data: {
        'name': name,
        'phone': phone,
        'address': address,
        'isDefault': isDefault,
      },
    );
  }
}
