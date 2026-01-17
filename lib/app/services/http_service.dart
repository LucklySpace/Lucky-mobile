// import 'dart:io';
// import 'package:dio/dio.dart' as dio;
// import 'package:dio/io.dart';
// import 'package:flutter_im/exceptions/app_exception.dart';
// import 'package:get/get.dart';
//
// import '../../config/app_config.dart';
// import '../api/wrapper/result.dart';
// import '../controller/user_controller.dart';
//
// /// HTTP 配置类
// class HttpConfig {
//   final String baseUrl;
//   final Map<String, String>? serviceBaseUrls;
//   final Map<String, String>? staticHeaders;
//   final Future<Map<String, String>> Function()? dynamicHeaderBuilder;
//   final Function(String message)? onError;
//   final bool enableLogging;
//
//   HttpConfig({
//     required this.baseUrl,
//     this.serviceBaseUrls,
//     this.staticHeaders,
//     this.dynamicHeaderBuilder,
//     this.onError,
//     this.enableLogging = true,
//   });
// }
//
// /// HTTP 请求服务类
// class HttpService extends GetxService {
//   static HttpService get to => Get.find();
//
//   late final dio.Dio _dio;
//   HttpConfig? _config;
//
//   /// 初始化配置
//   void init(HttpConfig config) {
//     _config = config;
//     _dio.options.baseUrl = config.baseUrl;
//     if (config.staticHeaders != null) {
//       _dio.options.headers.addAll(config.staticHeaders!);
//     }
//   }
//
//   @override
//   void onInit() {
//     super.onInit();
//     _dio = dio.Dio(dio.BaseOptions(
//       baseUrl: AppConfig.apiServer,
//       connectTimeout: Duration(seconds: AppConfig.connectTimeout),
//       receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
//       sendTimeout: Duration(seconds: AppConfig.sendTimeout),
//     ));
//
//     _setupInterceptors();
//     _setupSSL();
//   }
//
//   void _setupSSL() {
//     if (AppConfig.isDebug) {
//       (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
//         final client = HttpClient();
//         client.badCertificateCallback =
//             (X509Certificate cert, String host, int port) => true;
//         return client;
//       };
//     }
//   }
//
//   void _setupInterceptors() {
//     _dio.interceptors.add(dio.InterceptorsWrapper(
//       onRequest: (options, handler) async {
//         // 1. 处理动态 Header
//         if (_config?.dynamicHeaderBuilder != null) {
//           final dynamicHeaders = await _config!.dynamicHeaderBuilder!();
//           options.headers.addAll(dynamicHeaders);
//         }
//
//         // 2. 默认 Token 处理（如果 Header 中没设置 Authorization，则自动从 UserController 获取）
//         if (!options.headers.containsKey('Authorization')) {
//           final token = UserController.to.token.value;
//           if (token.isNotEmpty) {
//             options.headers['Authorization'] = 'Bearer $token';
//           }
//         }
//
//         options.headers['Content-Type'] = 'application/json';
//         if (_config?.enableLogging ?? true) {
//           Get.log('📡 请求: ${options.method} ${options.uri}');
//         }
//         return handler.next(options);
//       },
//       onResponse: (response, handler) {
//         if (_config?.enableLogging ?? true) {
//           Get.log('✅ 响应: ${response.statusCode} ${response.requestOptions.uri}');
//         }
//         return handler.next(response);
//       },
//       onError: (dio.DioException e, handler) {
//         final message = e.message ?? 'Unknown error';
//         if (_config?.enableLogging ?? true) {
//           Get.log('❌ 错误: $message [${e.requestOptions.uri}]');
//         }
//         // 全局错误回调
//         _config?.onError?.call(message);
//         return handler.next(e);
//       },
//     ));
//   }
//
//   /// 核心请求方法
//   /// [service] 参数可用于切换不同的 BaseURL (从 HttpConfig.serviceBaseUrls 获取)
//   Future<Result<T>> request<T>(
//     String path, {
//     String method = 'GET',
//     dynamic data,
//     Map<String, dynamic>? queryParameters,
//     T Function(dynamic)? fromJson,
//     String? service,
//     dio.Options? options,
//   }) async {
//     try {
//       dio.Options requestOptions = (options ?? dio.Options()).copyWith(method: method);
//       String requestPath = path;
//
//       // 如果指定了 service 且配置中有对应的 BaseUrl，则构造完整 URL
//       if (service != null && _config?.serviceBaseUrls?.containsKey(service) == true) {
//         final serviceBaseUrl = _config!.serviceBaseUrls![service]!;
//         if (!path.startsWith('http')) {
//           requestPath = serviceBaseUrl + (path.startsWith('/') ? path : '/$path');
//         }
//       }
//
//       final response = await _dio.request(
//         requestPath,
//         data: data,
//         queryParameters: queryParameters,
//         options: requestOptions,
//       );
//
//       final responseData = response.data;
//
//       // 统一响应解析
//       if (responseData is Map<String, dynamic>) {
//         final result = Result<T>.fromJson(responseData, fromJson);
//
//         // 这里可以添加全局业务拦截逻辑，例如 401 自动跳转登录
//         if (result.code == 401) {
//           // Get.find<UserController>().logout();
//         }
//
//         return result;
//       }
//
//       return Result<T>(
//         code: response.statusCode ?? 200,
//         message: 'success',
//         data: responseData is T ? responseData : null,
//         timestamp: DateTime.now().millisecondsSinceEpoch,
//       );
//
//     } on dio.DioException catch (e) {
//       final appEx = NetworkException.fromDioError(e);
//       return Result<T>(
//         code: appEx.code ?? -1,
//         message: appEx.message,
//         timestamp: DateTime.now().millisecondsSinceEpoch,
//       );
//     } catch (e) {
//       return Result<T>(
//         code: -1,
//         message: e.toString(),
//         timestamp: DateTime.now().millisecondsSinceEpoch,
//       );
//     }
//   }
//
//   /// 发送 GET 请求
//   Future<Result<T>> get<T>(String path, {
//     Map<String, dynamic>? params,
//     T Function(dynamic)? fromJson,
//     String? service,
//   }) {
//     return request<T>(path, method: 'GET', queryParameters: params, fromJson: fromJson, service: service);
//   }
//
//   /// 发送 POST 请求
//   Future<Result<T>> post<T>(String path, {
//     dynamic data,
//     T Function(dynamic)? fromJson,
//     String? service,
//   }) {
//     return request<T>(path, method: 'POST', data: data, fromJson: fromJson, service: service);
//   }
// }
//
// /// 链式调用扩展，增强异步请求的可读性
// extension HttpResultExt<T> on Future<Result<T>> {
//   /// 成功时执行
//   Future<Result<T>> onSuccess(Function(T? data) action) async {
//     final result = await this;
//     if (result.isSuccess) {
//       action(result.data);
//     }
//     return result;
//   }
//
//   /// 失败时执行
//   Future<Result<T>> onError(Function(int code, String message) action) async {
//     final result = await this;
//     if (!result.isSuccess) {
//       action(result.code, result.message);
//     }
//     return result;
//   }
//
//   /// 无论成功失败都会在最后执行
//   Future<Result<T>> onFinish(Function() action) async {
//     try {
//       return await this;
//     } finally {
//       action();
//     }
//   }
// }
