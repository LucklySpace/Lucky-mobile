import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:dio/io.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import 'package:get/get.dart';

import '../../config/app_config.dart';
import '../controller/user_controller.dart';

/// HTTP 请求服务类，基于 Dio 封装，提供统一的网络请求功能
class HttpService extends GetxService {
  late final dio.Dio _dio;

  /// 初始化 Dio 配置和拦截器
  @override
  void onInit() {
    super.onInit();
    _initDio();
    _setupInterceptors();
  }

  /// 配置 Dio 实例，包括基础 URL 和超时设置
  void _initDio() {
    _dio = dio.Dio(dio.BaseOptions(
      baseUrl: AppConfig.apiServer,
      connectTimeout: Duration(seconds: AppConfig.connectTimeout),
      receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
      sendTimeout: Duration(seconds: AppConfig.sendTimeout),
    ));

    // 仅在调试模式下启用忽略 SSL 证书验证（用于抓包调试）
    // ⚠️ 生产环境必须关闭此功能！
    if (AppConfig.isDebug) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
  }

  /// 设置 Dio 拦截器，统一处理请求头、响应日志和错误处理
  void _setupInterceptors() {
    _dio.interceptors.add(dio.InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加认证 Token（如果存在）
        final token = UserController.to.token.value;
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // 设置默认 Content-Type
        options.headers['Content-Type'] = 'application/json';
        Get.log('📡 请求: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        Get.log(
            '✅ 响应成功: ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (dio.DioException e, handler) {
        Get.log('❌ 请求错误: ${e.message} [${e.requestOptions.uri}]');
        // 这里不再直接处理错误，而是交给调用方或上层逻辑捕获
        return handler.next(e);
      },
    ));
  }

  /// 通用请求方法，封装 GET 和 POST 请求逻辑
  /// 发生错误时会抛出 [AppException] 及其子类
  Future<Map<String, dynamic>?> _request(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: dio.Options(method: method),
      );
      final result = _processResponse(response);
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      // 如果期望是 Map 但返回了 null 或其他类型，且状态码成功，可能需要根据业务逻辑判断
      // 这里暂时允许返回 null (例如 204 No Content)
      if (result == null) return null;

      Get.log('⚠️ $method 请求返回了非 Map 类型数据: $path - ${result.runtimeType}');
      return null;
    } on dio.DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('请求发生未知异常', details: e);
    }
  }

  /// 发送 GET 请求
  Future<Map<String, dynamic>?> get(String path,
      {Map<String, dynamic>? params}) {
    return _request(path, method: 'GET', queryParameters: params);
  }

  /// 发送 POST 请求
  Future<Map<String, dynamic>?> post(String path, {dynamic data}) {
    return _request(path, method: 'POST', data: data);
  }

  /// 处理 HTTP 响应数据
  static dynamic _processResponse(dio.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is String) {
        try {
          return jsonDecode(data);
        } catch (_) {
          return data;
        }
      }
      return data;
    }
    // 非成功状态码，抛出异常
    throw dio.DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: dio.DioExceptionType.badResponse,
    );
  }
}
