import 'package:flutter/foundation.dart';
import '../providers/app_provider.dart';

class ApiResponse<T> {
  final int code;
  final String? message;
  final String? cnMsg;
  final T? data;

  ApiResponse({
    required this.code,
    this.message,
    this.cnMsg,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['msg'] as String?,
      cnMsg: json['cnMsg'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  bool get isSuccess => code == 101100;

  String get errorMessage {
    final languageCode = AppProvider.currentLocale.languageCode;
    debugPrint('🌐 当前语言: $languageCode, cnMsg: $cnMsg, message: $message');
    if (languageCode == 'zh') {
      return cnMsg ?? message ?? '请求失败';
    } else {
      return message ?? cnMsg ?? 'Request failed';
    }
  }
}
