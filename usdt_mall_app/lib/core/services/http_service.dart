import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../models/api_response.dart';
import 'token_service.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  // 获取请求头
  Future<Map<String, String>> _getHeaders({bool needAuth = false}) async {
    final headers = <String, String>{};

    if (needAuth) {
      final token = await TokenService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET 请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    bool needAuth = false,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final headers = await _getHeaders(needAuth: needAuth);
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return ApiResponse<T>(
        code: -1,
        message: 'Network error: $e',
        cnMsg: '网络错误',
      );
    }
  }

  // POST 请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    bool needAuth = false,
    T Function(dynamic)? fromJsonT,
    bool saveToken = false,
  }) async {
    try {
      final headers = await _getHeaders(needAuth: needAuth);
      final response = await _dio.post(
        path,
        data: body,
        options: Options(headers: headers),
      );

      // 如果需要保存token，从响应头中获取并保存
      if (saveToken) {
        final token = response.headers.value('authorization');
        if (token != null) {
          await TokenService.saveToken(token);
        }
      }

      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return ApiResponse<T>(
        code: -1,
        message: 'Network error: $e',
        cnMsg: '网络错误',
      );
    }
  }

  // PUT 请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    bool needAuth = false,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final headers = await _getHeaders(needAuth: needAuth);
      final response = await _dio.put(
        path,
        data: body,
        options: Options(headers: headers),
      );

      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return ApiResponse<T>(
        code: -1,
        message: 'Network error: $e',
        cnMsg: '网络错误',
      );
    }
  }

  // DELETE 请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    bool needAuth = false,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final headers = await _getHeaders(needAuth: needAuth);
      final response = await _dio.delete(
        path,
        options: Options(headers: headers),
      );

      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return ApiResponse<T>(
        code: -1,
        message: 'Network error: $e',
        cnMsg: '网络错误',
      );
    }
  }

  // 处理响应
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJsonT,
  ) {
    try {
      return ApiResponse<T>.fromJson(response.data, fromJsonT);
    } catch (e) {
      return ApiResponse<T>(
        code: -1,
        message: 'Parse error: $e',
        cnMsg: '数据解析错误',
      );
    }
  }
}
