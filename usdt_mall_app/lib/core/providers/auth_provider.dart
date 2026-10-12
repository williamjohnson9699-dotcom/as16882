import 'package:flutter/foundation.dart';
import '../services/token_service.dart';
import '../services/user_info_service.dart';
import '../services/auth_service.dart';

/// 用户角色枚举
enum UserRole {
  user('USER', '普通用户'),
  shop('SHOP', '店铺用户'),
  service('SERVICE', '客服'),
  admin('ADMIN', '管理员');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }
}

/// 用户信息模型
class UserInfo {
  final int id;
  final String email;
  final String nickname;
  final String? avatar;
  final String? inviteCode;
  final bool hasPaymentPassword;
  final UserRole role;
  final double balance;
  final bool isOnline;

  UserInfo({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatar,
    this.inviteCode,
    required this.hasPaymentPassword,
    required this.role,
    required this.balance,
    this.isOnline = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'],
      inviteCode: json['inviteCode'],
      hasPaymentPassword: json['hasPaymentPassword'] ?? false,
      role: UserRole.fromString(json['role'] ?? 'USER'),
      balance: (json['balance'] ?? 0).toDouble(),
      isOnline: json['onlineStatus'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'inviteCode': inviteCode,
      'hasPaymentPassword': hasPaymentPassword,
      'role': role.value,
      'balance': balance,
      'onlineStatus': isOnline ? 1 : 0,
    };
  }

  UserInfo copyWith({
    int? id,
    String? email,
    String? nickname,
    String? avatar,
    String? inviteCode,
    bool? hasPaymentPassword,
    UserRole? role,
    double? balance,
    bool? isOnline,
  }) {
    return UserInfo(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      inviteCode: inviteCode ?? this.inviteCode,
      hasPaymentPassword: hasPaymentPassword ?? this.hasPaymentPassword,
      role: role ?? this.role,
      balance: balance ?? this.balance,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// 认证状态Provider
class AuthProvider extends ChangeNotifier {
  UserInfo? _userInfo;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  UserInfo? get userInfo => _userInfo;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  /// 是否是店铺用户
  bool get isShop => _userInfo?.role == UserRole.shop;

  /// 是否是客服
  bool get isService => _userInfo?.role == UserRole.service;

  /// 是否是管理员
  bool get isAdmin => _userInfo?.role == UserRole.admin;

  /// 初始化认证状态（从本地存储恢复）
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await TokenService.isLoggedIn();
      if (isLoggedIn) {
        // 恢复用户信息
        final userInfo = await UserInfoService.getUserInfo();
        if (userInfo != null) {
          _userInfo = userInfo;
          _isAuthenticated = true;
        } else {
          // 如果没有用户信息，清除token
          await TokenService.deleteToken();
          _isAuthenticated = false;
        }
      }
    } catch (e) {
      debugPrint('初始化认证状态失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 登录成功后设置用户信息
  Future<void> setUserInfo(UserInfo userInfo) async {
    debugPrint('🔄 setUserInfo 被调用');
    debugPrint('📥 接收到的用户信息: nickname=${userInfo.nickname}, id=${userInfo.id}');
    _userInfo = userInfo;
    _isAuthenticated = true;
    debugPrint('🔍 _isAuthenticated 设置为: $_isAuthenticated');
    debugPrint('🔍 _userInfo 设置为: ${_userInfo?.nickname}');

    // 保存用户信息到本地
    await UserInfoService.saveUserInfo(userInfo);

    debugPrint('📢 准备调用 notifyListeners()');
    notifyListeners();
    debugPrint('✅ notifyListeners() 已调用');
  }

  /// 更新用户信息
  Future<void> updateUserInfo(UserInfo userInfo) async {
    _userInfo = userInfo;
    // 保存用户信息到本地
    await UserInfoService.saveUserInfo(userInfo);
    notifyListeners();
  }

  /// 从后端刷新用户信息
  Future<void> refreshUserInfo() async {
    try {
      final authService = AuthService();
      final response = await authService.getUserInfo();

      if (response.isSuccess && response.data != null) {
        final userInfoModel = response.data!;

        // 将 UserInfoModel 转换为 UserInfo
        final userInfo = UserInfo(
          id: userInfoModel.id,
          email: userInfoModel.username,
          nickname: userInfoModel.nickname,
          avatar: userInfoModel.avatar,
          inviteCode: userInfoModel.inviteCode,
          hasPaymentPassword: userInfoModel.hasPaymentPassword,
          role: UserRole.fromString(userInfoModel.role),
          balance: userInfoModel.balance,
        );

        await updateUserInfo(userInfo);
      }
    } catch (e) {
      debugPrint('刷新用户信息失败: $e');
    }
  }

  /// 更新余额
  Future<void> updateBalance(double balance) async {
    if (_userInfo != null) {
      _userInfo = _userInfo!.copyWith(balance: balance);
      // 保存用户信息到本地
      await UserInfoService.saveUserInfo(_userInfo!);
      notifyListeners();
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      // 先设置用户为离线状态（在清除token之前）
      final authService = AuthService();
      await authService.setOnlineStatus(0);
    } catch (e) {
      debugPrint('设置离线状态失败: $e');
      // 即使设置离线状态失败，也继续执行退出流程
    }

    await TokenService.deleteToken();
    // 清除本地保存的用户信息
    await UserInfoService.deleteUserInfo();
    _userInfo = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// 清除状态
  Future<void> clear() async {
    // 清除本地保存的用户信息
    await UserInfoService.deleteUserInfo();
    _userInfo = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }
}
