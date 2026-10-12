import 'package:usdt_mall_app/core/api/http_client.dart';
import 'package:usdt_mall_app/core/models/api_response.dart';

/// 虚拟数据接口。只给管理员用。
class VirtualDataApi {
  static final _httpClient = HttpClient();

  static Future<ApiResponse<Map<String, dynamic>>> previewShops({
    required String prefix,
    int? count,
  }) {
    return _httpClient.post('/virtual-data/shops/preview', data: {
      'prefix': prefix,
      if (count != null) 'count': count,
    });
  }

  static Future<ApiResponse<Map<String, dynamic>>> submitShops({
    required String prefix,
    int? count,
    required String password,
  }) {
    return _httpClient.post('/virtual-data/shops', data: {
      'prefix': prefix,
      if (count != null) 'count': count,
      'password': password,
    });
  }

  static Future<ApiResponse<Map<String, dynamic>>> listShops({
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) {
    return _httpClient.get('/virtual-data/shops', queryParameters: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      'page': page,
      'pageSize': pageSize,
    });
  }

  static Future<ApiResponse<Map<String, dynamic>>> submitOrders({
    required List<int> shopIds,
    int? pendingShipment,
    int? pendingReceipt,
    int? completed,
    int? cancelled,
    int? rechargeCount,
    int? withdrawCount,
  }) {
    return _httpClient.post('/virtual-data/orders', data: {
      'shopIds': shopIds,
      'pendingShipment': pendingShipment,
      'pendingReceipt': pendingReceipt,
      'completed': completed,
      'cancelled': cancelled,
      'rechargeCount': rechargeCount,
      'withdrawCount': withdrawCount,
    });
  }

  static Future<ApiResponse<Map<String, dynamic>>> submitProducts({
    required List<int> shopIds,
    int? count,
  }) {
    return _httpClient.post('/virtual-data/products', data: {
      'shopIds': shopIds,
      'count': count,
    });
  }

  static Future<ApiResponse<Map<String, dynamic>>> getTask(int taskId) {
    return _httpClient.get('/virtual-data/tasks/$taskId');
  }

  static Future<ApiResponse<Map<String, dynamic>>> listTasks({
    int page = 1,
    int pageSize = 10,
  }) {
    return _httpClient.get('/virtual-data/tasks', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
  }
}
