import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:dio/io.dart';
import 'package:flutter_im/constants/app_constant.dart';
import 'package:flutter_im/exceptions/app_exception.dart'; // 假设此文件存在，包含 NetworkException

import '../../config/app_config.dart';

// HTTP 配置类（简化版，参考 Axios 配置）
class HttpConfig {
  final String baseUrl;
  final Map<String, String>? serviceBaseUrls;
  final Map<String, String>? staticHeaders;
  final Future<Map<String, String>> Function()? dynamicHeaderBuilder;
  final Function(String message)? onGlobalError;
  final bool enableLogging;
  final bool ignoreBadCertInDebug; // 新增：是否忽略调试模式下的证书验证

  HttpConfig({
    required this.baseUrl,
    this.serviceBaseUrls,
    this.staticHeaders,
    this.dynamicHeaderBuilder,
    this.onGlobalError,
    this.enableLogging = true,
    this.ignoreBadCertInDebug = true,
  });
}

// 拦截器类型定义（参考 Axios 拦截器）
typedef RequestInterceptor = Future<dio.RequestOptions> Function(
    dio.RequestOptions options);
typedef ResponseInterceptor = Future<dio.Response> Function(
    dio.Response response);
typedef ErrorInterceptor = Future<dio.DioException> Function(
    dio.DioException error);

// HTTP 工具类（单例模式，简单易用，支持扩展）
class Http {
  static final Http _instance = Http._internal();

  factory Http() => _instance;

  Http._internal();

  late final dio.Dio _dio;
  HttpConfig? _config;

  // 拦截器列表（允许外部添加多个）
  final List<RequestInterceptor> _requestInterceptors = [];
  final List<ResponseInterceptor> _responseInterceptors = [];
  final List<ErrorInterceptor> _errorInterceptors = [];

  // 初始化方法（必须调用一次设置配置）
  void init(HttpConfig config) {
    _config = config;
    _dio = dio.Dio(dio.BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: Duration(seconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
      sendTimeout: Duration(seconds: AppConfig.sendTimeout),
      headers: config.staticHeaders,
    ));

    _setupSSL();
    _setupInterceptors();
  }

  // 设置忽略坏证书（调试模式）
  void _setupSSL() {
    if (_config?.ignoreBadCertInDebug == true && AppConfig.isDebug) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
  }

  // 设置内置拦截器（动态 header、默认 content-type、日志等）
  void _setupInterceptors() {
    _dio.interceptors.add(dio.InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 应用所有请求拦截器
        for (var interceptor in _requestInterceptors) {
          options = await interceptor(options);
        }

        // 内置：动态 header
        if (_config?.dynamicHeaderBuilder != null) {
          final dynamicHeaders = await _config!.dynamicHeaderBuilder!();
          options.headers.addAll(dynamicHeaders);
        }

        // 内置：默认 Content-Type
        options.headers['Content-Type'] ??= 'application/json';

        // 内置：日志
        if (_config?.enableLogging ?? false) {
          print('📡 请求: ${options.method} ${options.uri}');
        }

        return handler.next(options);
      },
      onResponse: (response, handler) async {
        // 应用所有响应拦截器
        for (var interceptor in _responseInterceptors) {
          response = await interceptor(response);
        }

        // 内置：日志
        if (_config?.enableLogging ?? false) {
          print('✅ 响应: ${response.statusCode} ${response.requestOptions.uri}');
        }

        return handler.next(response);
      },
      onError: (dio.DioException e, handler) async {
        // 应用所有错误拦截器
        for (var interceptor in _errorInterceptors) {
          e = await interceptor(e);
        }

        // 内置：日志和全局错误回调
        final message = e.message ?? 'Unknown error';
        if (_config?.enableLogging ?? false) {
          print('❌ 错误: $message [${e.requestOptions.uri}]');
        }
        _config?.onGlobalError?.call(message);

        return handler.next(e);
      },
    ));
  }

  // 添加拦截器方法（外部可扩展，参考 Axios）
  void addRequestInterceptor(RequestInterceptor interceptor) {
    _requestInterceptors.add(interceptor);
  }

  void addResponseInterceptor(ResponseInterceptor interceptor) {
    _responseInterceptors.add(interceptor);
  }

  void addErrorInterceptor(ErrorInterceptor interceptor) {
    _errorInterceptors.add(interceptor);
  }

  // 核心请求方法（支持 service 切换 baseUrl）
  Future<Result<T>> request<T>(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    String? service,
    dio.Options? options,
  }) async {
    try {
      dio.Options requestOptions =
          (options ?? dio.Options()).copyWith(method: method);
      String requestPath = path;

      // 支持多种服务：如果指定 service，切换 baseUrl
      if (service != null &&
          _config?.serviceBaseUrls?.containsKey(service) == true) {
        final serviceBaseUrl = _config!.serviceBaseUrls![service]!;
        if (!path.startsWith('http')) {
          requestPath =
              serviceBaseUrl + (path.startsWith('/') ? path : '/$path');
        }
      } else {}

      final response = await _dio.request(
        requestPath,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
      );

      final responseData = response.data;

      // 统一响应解析
      if (responseData is Map<String, dynamic>) {
        final result = Result<T>.fromJson(responseData, fromJson);

        // 示例全局业务拦截：401 处理（可外部扩展拦截器处理更多）
        if (result.code != AppConstants.httpStatusSuccess) {
          // 可以在这里添加自定义逻辑，如登出
        }

        return result;
      }

      return Result<T>(
        code: response.statusCode ?? 200,
        message: 'success',
        data: responseData is T ? responseData : null,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } on dio.DioException catch (e) {
      final appEx = NetworkException.fromDioError(e);
      return Result<T>(
        code: appEx.code ?? -1,
        message: appEx.message,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      return Result<T>(
        code: -1,
        message: e.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  // 快捷方法：GET
  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
    String? service,
    dio.Options? options,
  }) {
    return request<T>(path,
        method: 'GET',
        queryParameters: params,
        fromJson: fromJson,
        service: service,
        options: options);
  }

  // 快捷方法：POST
  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    String? service,
    dio.Options? options,
  }) {
    return request<T>(path,
        method: 'POST',
        data: data,
        fromJson: fromJson,
        service: service,
        options: options);
  }

  // 可以添加更多方法如 put, delete 等，类似 Axios
  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    String? service,
    dio.Options? options,
  }) {
    return request<T>(path,
        method: 'PUT',
        data: data,
        fromJson: fromJson,
        service: service,
        options: options);
  }

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
    String? service,
    dio.Options? options,
  }) {
    return request<T>(path,
        method: 'DELETE',
        data: data,
        fromJson: fromJson,
        service: service,
        options: options);
  }
}

// 链式调用扩展（参考 Promise 链式，增强可读性）
extension HttpResultExt<T> on Future<Result<T>> {
  /// 成功时执行
  Future<Result<T>> onSuccess(Function(T? data) action) async {
    final result = await this;
    if (result.isSuccess) {
      action(result.data);
    }
    return result;
  }

  /// 失败时执行
  Future<Result<T>> onError(Function(int code, String message) action) async {
    final result = await this;
    if (!result.isSuccess) {
      action(result.code, result.message);
    }
    return result;
  }

  /// 无论成功失败都会在最后执行
  Future<Result<T>> onFinish(Function() action) async {
    try {
      return await this;
    } finally {
      action();
    }
  }
}

class Result<T> {
  final int code;
  final String message;
  final T? data;
  final int timestamp;

  Result({
    required this.code,
    required this.message,
    this.data,
    required this.timestamp,
  });

  /// 是否成功
  bool get isSuccess => code == 200 || code == 0;

  /// 从 JSON 转换，支持泛型转换函数
  factory Result.fromJson(Map<String, dynamic> json,
      [T Function(dynamic)? fromJsonT]) {
    final dataJson = json['data'];
    T? parsedData;

    if (dataJson != null && fromJsonT != null) {
      try {
        parsedData = fromJsonT(dataJson);
      } catch (e) {
        print('Error parsing data: $e');
      }
    } else if (dataJson is T) {
      parsedData = dataJson;
    }

    return Result<T>(
      code: json['code'] ?? -1,
      message: json['message'] ?? '',
      data: parsedData ?? dataJson,
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 转换数据类型
  Result<R> map<R>(R Function(T? data) mapper) {
    return Result<R>(
      code: code,
      message: message,
      data: mapper(data),
      timestamp: timestamp,
    );
  }

  @override
  String toString() => 'Result(code: $code, message: $message, data: $data)';

  void operator [](String other) {}
}
