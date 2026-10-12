class UserInfoModel {
  final int id;
  final String username;
  final String nickname;
  final String? avatar;
  final String role;
  final String? inviteCode;
  final bool hasPaymentPassword;
  final double balance;

  UserInfoModel({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatar,
    required this.role,
    this.inviteCode,
    required this.hasPaymentPassword,
    required this.balance,
  });

  /// 是否是管理员或客服
  bool get isAdminOrCustomerService {
    return role == 'admin' || role == 'customer_service';
  }

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      id: json['id'] as int,
      username: json['username'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String,
      inviteCode: json['inviteCode'] as String?,
      hasPaymentPassword: json['hasPaymentPassword'] as bool? ?? false,
      balance: (json['balance'] as num).toDouble(),
    );
  }

  UserInfoModel copyWith({
    int? id,
    String? username,
    String? nickname,
    String? avatar,
    String? role,
    String? inviteCode,
    bool? hasPaymentPassword,
    double? balance,
  }) {
    return UserInfoModel(
      id: id ?? this.id,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      inviteCode: inviteCode ?? this.inviteCode,
      hasPaymentPassword: hasPaymentPassword ?? this.hasPaymentPassword,
      balance: balance ?? this.balance,
    );
  }
}

