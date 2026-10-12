import 'http_client.dart';
import '../models/api_response.dart';

/// 店铺管理API接口
class ShopManagementApi {
  static final HttpClient _client = HttpClient();

  /// 获取店铺列表
  /// [keyword] 搜索关键词（店铺名称、店主姓名）
  /// [page] 页码
  /// [pageSize] 每页数量
  static Future<ApiResponse<Map<String, dynamic>>> getShopList({
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _client.post(
      '/shop-management/query',
      data: {
        'keyword': keyword,
        'page': page,
        'pageSize': pageSize,
      },
    );
  }

  /// 获取店铺详情
  /// [shopId] 店铺ID
  static Future<ApiResponse<Map<String, dynamic>>> getShopDetail(
    String shopId,
  ) async {
    return await _client.get('/shop-management/shops/$shopId');
  }

  /// 更新店铺信息
  static Future<ApiResponse<void>> updateShop({
    required int shopId,
    required Map<String, dynamic> data,
  }) async {
    return await _client.put(
      '/shop-management/shops/$shopId',
      data: data,
    );
  }

  /// 删除店铺
  /// [shopId] 店铺ID
  static Future<ApiResponse<void>> deleteShop(String shopId) async {
    return await _client.delete('/shop-management/shops/$shopId');
  }

  /// 管理员解除店铺因超时未支付产生的商家页面限制。
  ///
  /// [shopId] 店铺ID。
  /// 返回解封接口结果。
  static Future<ApiResponse<void>> unlockPaymentLock(int shopId) async {
    return await _client.post('/shop-management/shops/$shopId/unlock-payment');
  }

  /// 更新店铺状态
  /// [shopId] 店铺ID
  /// [status] 状态: active/inactive
  static Future<ApiResponse<void>> updateShopStatus({
    required String shopId,
    required String status,
  }) async {
    return await _client.put(
      '/shop-management/shops/$shopId/status',
      data: {'status': status},
    );
  }
}
