import 'package:flutter/material.dart';

/// SnackBar工具类
class SnackBarUtil {
  /// 显示成功消息
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  /// 显示错误消息
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  /// 显示普通消息
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}
