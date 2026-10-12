import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/token_service.dart';
import '../models/api_response.dart';

/// HTTP客户端封装
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;

  late Dio _dio;

  HttpClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  /// 配置拦截器
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  /// 请求拦截器
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 添加Token到请求头
    final token = await TokenService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    print('🚀 请求: ${options.method} ${options.path}');
    print('📦 参数: ${options.data}');

    handler.next(options);
  }

  /// 响应拦截器
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    print('✅ 响应: ${response.statusCode} ${response.requestOptions.path}');

    // 从响应头中提取Token
    final token = response.headers.value('Authorization');
    if (token != null && token.isNotEmpty) {
      TokenService.saveToken(token.replaceFirst('Bearer ', ''));
    }

    handler.next(response);
  }

  /// 错误拦截器
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('❌ 错误: ${err.requestOptions.path}');
    print('📛 错误信息: ${err.message}');

    // 处理401未授权错误
    if (err.response?.statusCode == 401) {
      print('🔐 Token过期，尝试刷新...');
      // 可以在这里实现Token刷新逻辑
      await TokenService.deleteToken();
    }

    handler.next(err);
  }

  /// GET请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  /// POST请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  /// PUT请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  /// DELETE请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse<T>.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  /// 文件上传（支持Web和移动端）
  Future<ApiResponse<T>> upload<T>(
    String path,
    String? filePath, {
    String fileKey = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      MultipartFile multipartFile;

      if (fileBytes != null && fileName != null) {
        // Web平台：使用字节数据
        multipartFile = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
      } else if (filePath != null) {
        // 移动端/桌面端：使用文件路径
        multipartFile = await MultipartFile.fromFile(filePath);
      } else {
        throw Exception('必须提供文件路径或文件字节数据');
      }

      final formData = FormData.fromMap({
        fileKey: multipartFile,
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return ApiResponse<T>.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  /// 错误处理
  ApiResponse<T> _handleError<T>(DioException error) {
    String message = '请求失败';
    int code = -1;

    if (error.response != null) {
      // 服务器返回错误
      code = error.response?.statusCode ?? -1;
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        message = data['cnMsg'] ?? data['message'] ?? message;
        code = data['code'] ?? code;
      }
    } else {
      // 网络错误
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = '连接超时，请检查网络';
          break;
        case DioExceptionType.connectionError:
          message = '网络连接失败';
          break;
        case DioExceptionType.cancel:
          message = '请求已取消';
          break;
        default:
          message = '网络异常: ${error.message}';
      }
    }

    return ApiResponse<T>(
      code: code,
      message: message,
      cnMsg: message,
      data: null,
    );
  }

  /// 获取Dio实例（用于特殊场景）
  Dio get dio => _dio;
}
