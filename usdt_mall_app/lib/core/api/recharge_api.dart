import 'http_client.dart';
import '../models/api_response.dart';

/// 充值API接口
class RechargeApi {
  static final HttpClient _client = HttpClient();

  /// 提交充值申请
  /// [paymentMethod] 充值方式
  /// [amount] 充值金额
  /// [remark] 备注
  /// [proofImage] 凭证图片URL
  /// [receivingAddress] 收款地址
  static Future<ApiResponse<Map<String, dynamic>>> submitRecharge({
    required String paymentMethod,
    required double amount,
    String? remark,
    String? proofImage,
    required String receivingAddress,
  }) async {
    return await _client.post(
      '/recharge/submit',
      data: {
        'paymentMethod': paymentMethod,
        'amount': amount,
        'remark': remark ?? '',
        'proofImage': proofImage,
        'receivingAddress': receivingAddress,
      },
    );
  }
}
