import 'package:usdt_mall_app/core/api/http_client.dart';
import 'package:usdt_mall_app/core/models/api_response.dart';

/// 地址API
class AddressApi {
  static final _httpClient = HttpClient();

  /// 获取地址列表
  static Future<ApiResponse<List<dynamic>>> getAddressList() async {
    return await _httpClient.get('/address-management/list');
  }

  /// 保存地址（新增或编辑）
  static Future<ApiResponse> saveAddress({
    int? id,
    required String name,
    required String phone,
    required String address,
    int isDefault = 0,
  }) async {
    return await _httpClient.post('/address-management/save', data: {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'isDefault': isDefault,
    });
  }

  /// 删除地址
  static Future<ApiResponse> deleteAddress(int id) async {
    return await _httpClient.delete('/address-management/$id');
  }

  /// 设置默认地址
  static Future<ApiResponse> setDefaultAddress(int id) async {
    return await _httpClient.put('/address-management/set-default/$id');
  }
}
