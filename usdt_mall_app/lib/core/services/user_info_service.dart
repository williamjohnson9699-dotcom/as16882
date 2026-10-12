import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';

/// 用户信息存储服务
class UserInfoService {
  static const String _userInfoKey = 'user_info';

  /// 保存用户信息
  static Future<void> saveUserInfo(UserInfo userInfo) async {
    try {
      debugPrint('💾 开始保存用户信息: ${userInfo.nickname}');

      final prefs = await SharedPreferences.getInstance();

      final jsonString = jsonEncode(userInfo.toJson());
      debugPrint('📝 JSON数据: $jsonString');

      // 先清除旧数据
      await prefs.remove(_userInfoKey);
      debugPrint('🗑️ 已清除旧数据');

      // 保存新数据
      final result = await prefs.setString(_userInfoKey, jsonString);
      debugPrint('✅ 保存结果: $result');

      // 强制刷新并验证
      await prefs.reload();
      final saved = prefs.getString(_userInfoKey);
      debugPrint('🔍 验证保存: ${saved != null ? "成功" : "失败"}');

      if (saved != null) {
        debugPrint('📄 保存的数据: ${saved.substring(0, saved.length > 100 ? 100 : saved.length)}...');
      } else {
        debugPrint('❌ 数据未保存成功');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 保存用户信息失败: $e');
      debugPrint('📚 堆栈: $stackTrace');
    }
  }

  /// 获取用户信息
  static Future<UserInfo?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userInfoKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return UserInfo.fromJson(json);
      }
    } catch (e) {
      print('获取用户信息失败: $e');
    }
    return null;
  }

  /// 删除用户信息
  static Future<void> deleteUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userInfoKey);
    } catch (e) {
      print('删除用户信息失败: $e');
    }
  }

  /// 检查是否有保存的用户信息
  static Future<bool> hasUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_userInfoKey);
    } catch (e) {
      print('检查用户信息失败: $e');
      return false;
    }
  }
}
