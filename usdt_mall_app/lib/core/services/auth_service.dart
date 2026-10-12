import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/user_info.dart';
import 'http_service.dart';
import 'token_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final HttpService _httpService = HttpService();

  /// 用户登录
  Future<ApiResponse<void>> login({
    required String username,
    required String password,
  }) async {
    return await _httpService.post<void>(
      ApiConstants.login,
      body: {
        'username': username,
        'password': password,
      },
      saveToken: true, // 自动保存响应头中的token
    );
  }

  /// 用户注册
  Future<ApiResponse<void>> register({
    required String username,
    required String nickname,
    required String password,
  }) async {
    return await _httpService.post<void>(
      ApiConstants.register,
      body: {
        'username': username,
        'nickname': nickname,
        'password': password,
      },
    );
  }

  /// 刷新Token
  Future<ApiResponse<void>> refreshToken() async {
    return await _httpService.get<void>(
      ApiConstants.refreshToken,
      needAuth: true,
    );
  }

  /// 用户登出
  Future<ApiResponse<void>> logout() async {
    final response = await _httpService.post<void>(
      '/auth/logout',
      needAuth: true,
    );

    // 清除本地token
    await TokenService.deleteToken();

    return response;
  }

  /// 获取用户信息
  Future<ApiResponse<UserInfoModel>> getUserInfo() async {
    return await _httpService.get<UserInfoModel>(
      ApiConstants.userInfo,
      needAuth: true,
      fromJsonT: (json) => UserInfoModel.fromJson(json),
    );
  }

  /// 设置用户在线状态
  /// [status] 1:在线, 0:离线
  Future<ApiResponse<void>> setOnlineStatus(int status) async {
    return await _httpService.post<void>(
      '${ApiConstants.onlineStatus}?status=$status',
      needAuth: true,
    );
  }
}
