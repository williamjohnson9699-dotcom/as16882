import 'http_client.dart';
import '../models/api_response.dart';

/// 地址管理API接口
class AddressManagementApi {
  static final HttpClient _client = HttpClient();

  /// 获取地址列表
  static Future<ApiResponse<List<dynamic>>> getAddressList() async {
    return await _client.get('/address-management/list');
  }

  /// 保存地址（新增或编辑）
  /// [id] 地址ID（编辑时需要）
  /// [name] 收货人姓名
  /// [phone] 联系电话
  /// [address] 详细地址
  /// [isDefault] 是否设为默认地址
  static Future<ApiResponse<void>> saveAddress({
    int? id,
    required String name,
    required String phone,
    required String address,
    required bool isDefault,
  }) async {
    return await _client.post(
      '/address-management/save',
      data: {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'isDefault': isDefault,
      },
    );
  }

  /// 删除地址
  /// [id] 地址ID
  static Future<ApiResponse<void>> deleteAddress(int id) async {
    return await _client.delete('/address-management/$id');
  }

  /// 批量删除地址
  /// [ids] 地址ID列表
  static Future<ApiResponse<void>> batchDeleteAddresses(List<int> ids) async {
    return await _client.post(
      '/address-management/batch-delete',
      data: ids,
    );
  }

  /// 设置默认地址
  /// [id] 地址ID
  static Future<ApiResponse<void>> setDefaultAddress(int id) async {
    return await _client.put('/address-management/set-default/$id');
  }
}
