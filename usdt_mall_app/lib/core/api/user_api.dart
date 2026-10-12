import 'http_client.dart';
import '../models/api_response.dart';

/// 用户API接口
class UserApi {
  static final HttpClient _client = HttpClient();

  /// 获取用户信息
  static Future<ApiResponse<Map<String, dynamic>>> getUserInfo() async {
    return await _client.get('/auth/userinfo');
  }

  /// 更新用户昵称
  /// [nickname] 新昵称
  static Future<ApiResponse<void>> updateNickname({
    required String nickname,
  }) async {
    return await _client.put(
      '/auth/nickname',
      queryParameters: {'nickname': nickname},
    );
  }

  /// 更新用户头像
  /// [avatar] 头像URL
  static Future<ApiResponse<void>> updateAvatar({
    required String avatar,
  }) async {
    return await _client.put(
      '/auth/avatar',
      queryParameters: {'avatar': avatar},
    );
  }

  /// 修改登录密码
  /// [oldPassword] 旧密码
  /// [newPassword] 新密码
  static Future<ApiResponse<void>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _client.put(
      '/auth/password',
      queryParameters: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// 设置支付密码
  /// [paymentPassword] 支付密码
  static Future<ApiResponse<void>> setPaymentPassword({
    required String paymentPassword,
  }) async {
    return await _client.post(
      '/auth/payment-password',
      queryParameters: {'paymentPassword': paymentPassword},
    );
  }

  /// 修改支付密码
  /// [oldPaymentPassword] 旧支付密码
  /// [newPaymentPassword] 新支付密码
  static Future<ApiResponse<void>> updatePaymentPassword({
    required String oldPaymentPassword,
    required String newPaymentPassword,
  }) async {
    return await _client.put(
      '/auth/payment-password',
      queryParameters: {
        'oldPaymentPassword': oldPaymentPassword,
        'newPaymentPassword': newPaymentPassword,
      },
    );
  }
}
