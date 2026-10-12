import 'http_client.dart';
import '../models/api_response.dart';

/// 系统配置API
class SystemConfigApi {
  static final HttpClient _client = HttpClient();

  /// 获取利润率配置
  static Future<ApiResponse<int>> getProfitRate() async {
    return await _client.get('/system-config/profit-rate');
  }

  /// 更新利润率配置
  static Future<ApiResponse<void>> updateProfitRate(int profitRate) async {
    return await _client.put('/system-config/profit-rate', data: {
      'profitRate': profitRate,
    });
  }

  /// 获取所有系统配置
  static Future<ApiResponse<Map<String, dynamic>>> getAllConfigs() async {
    return await _client.get('/system-config/all');
  }

  /// 获取收款地址
  static Future<ApiResponse<String>> getReceivingAddress() async {
    return await _client.get('/system-config/receiving-address');
  }

  /// 更新收款地址
  static Future<ApiResponse<void>> updateReceivingAddress(String address) async {
    return await _client.put('/system-config/receiving-address', data: {
      'receivingAddress': address,
    });
  }
}
