import 'package:usdt_mall_app/core/api/http_client.dart';
import 'package:usdt_mall_app/core/models/api_response.dart';

/// 订单API
class OrderApi {
  static final _httpClient = HttpClient();

  /// 创建订单
  static Future<ApiResponse<int>> createOrder({
    required List<int> cartIds,
    required int addressId,
    required String paymentPassword,
    String? remark,
  }) async {
    return await _httpClient.post('/order', data: {
      'cartIds': cartIds,
      'addressId': addressId,
      'paymentPassword': paymentPassword,
      if (remark != null) 'remark': remark,
    });
  }

  /// 获取用户订单列表
  static Future<ApiResponse<dynamic>> getUserOrders(
      {int? status, int? page, int? pageSize}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (page != null) params['page'] = page;
    if (pageSize != null) params['pageSize'] = pageSize;

    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return await _httpClient
        .get('/order${queryString.isNotEmpty ? '?$queryString' : ''}');
  }

  /// 获取订单详情
  static Future<ApiResponse<Map<String, dynamic>>> getOrderDetail(
      int orderId) async {
    return await _httpClient.get('/order/$orderId');
  }

  /// 确认发货
  static Future<ApiResponse> confirmShipment(int orderId) async {
    return await _httpClient.post('/order/$orderId/ship');
  }

  /// 确认收货
  static Future<ApiResponse> confirmReceipt(int orderId) async {
    return await _httpClient.post('/order/$orderId/receive');
  }

  /// 取消订单
  static Future<ApiResponse> cancelOrder(
      int orderId, String cancelReason) async {
    return await _httpClient.post('/order/$orderId/cancel', data: {
      'cancelReason': cancelReason,
    });
  }

  /// 获取店铺订单列表
  static Future<ApiResponse<dynamic>> getShopOrders(int? shopId,
      {int? status, String? keyword, int? page, int? pageSize}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (page != null) params['page'] = page;
    if (pageSize != null) params['pageSize'] = pageSize;

    final queryString =
        params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final path = shopId != null ? '/order/shop/$shopId' : '/order/shop/all';
    return await _httpClient
        .get('$path${queryString.isNotEmpty ? '?$queryString' : ''}');
  }

  /// 获取店铺订单统计
  static Future<ApiResponse<Map<String, dynamic>>> getShopOrderStats(
      int? shopId) async {
    if (shopId == null) {
      return await _httpClient.get('/order/shop/my/stats');
    }
    return await _httpClient.get('/order/shop/$shopId/stats');
  }

  /// 获取待处理订单数量
  static Future<ApiResponse<int>> getPendingOrderCount() async {
    return await _httpClient.get('/order/pending-count');
  }

  /// 获取用户订单统计
  static Future<ApiResponse<Map<String, dynamic>>> getUserOrderStats() async {
    return await _httpClient.get('/order/stats');
  }

  /// 获取我的店铺订单统计
  static Future<ApiResponse<Map<String, dynamic>>> getMyShopOrderStats() async {
    return await _httpClient.get('/order/shop/my/stats');
  }

  /// 卖家支付
  static Future<ApiResponse<void>> sellerPay(
    int orderId, {
    required String paymentPassword,
  }) async {
    return await _httpClient.post('/order/$orderId/seller-pay', data: {
      'paymentPassword': paymentPassword,
    });
  }

  /// 更新物流信息
  static Future<ApiResponse<void>> updateLogistics(
      int orderId, String logisticsInfo) async {
    return await _httpClient.post('/order/$orderId/update-logistics', data: {
      'logisticsInfo': logisticsInfo,
    });
  }

  /// 标记为已到货
  static Future<ApiResponse<void>> markAsArrived(int orderId) async {
    return await _httpClient.post('/order/$orderId/mark-arrived');
  }

  /// 标记终态订单为已读。status 为空时不传，表示同时处理已完成和已取消。
  /// viewType: 'buyer' - 买家视图, 'seller' - 卖家视图, 'service' - 客服视图
  static Future<ApiResponse<void>> markFinalOrdersAsRead(
      int? status, List<int> orderIds, String viewType) async {
    final data = <String, dynamic>{
      'orderIds': orderIds,
      'viewType': viewType,
    };
    if (status != null) {
      data['status'] = status;
    }
    return await _httpClient.post('/order/mark-final-read', data: data);
  }
}
