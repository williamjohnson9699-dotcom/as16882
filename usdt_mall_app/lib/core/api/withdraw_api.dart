import 'http_client.dart';
import '../models/api_response.dart';

/// 提现API接口
class WithdrawApi {
  static final HttpClient _client = HttpClient();

  /// 提交提现申请
  /// [paymentMethod] 提现方式
  /// [amount] 提现金额
  /// [receivingAddress] 收款地址
  /// [paymentPassword] 支付密码
  static Future<ApiResponse<Map<String, dynamic>>> submitWithdraw({
    required String paymentMethod,
    required double amount,
    required String receivingAddress,
    required String paymentPassword,
  }) async {
    return await _client.post(
      '/withdraw/submit',
      data: {
        'paymentMethod': paymentMethod,
        'amount': amount,
        'receivingAddress': receivingAddress,
        'paymentPassword': paymentPassword,
      },
    );
  }
}
