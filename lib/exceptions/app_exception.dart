import 'package:dio/dio.dart';

/// 全局异常基类
class AppException implements Exception {
  final String message;
  final int? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => '[$code] $message';
}

/// 网络异常
class NetworkException extends AppException {
  NetworkException(String message, {int? code, dynamic details})
      : super(message, code: code, details: details);

  factory NetworkException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('网络连接超时，请检查您的网络设置', code: -1);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        // 尝试从响应体中解析后端返回的错误信息
        String? msg;
        if (data is Map && data.containsKey('message')) {
          msg = data['message'];
        }
        return NetworkException(msg ?? '服务器响应错误 ($statusCode)',
            code: statusCode, details: data);
      case DioExceptionType.cancel:
        return NetworkException('请求已取消', code: -2);
      case DioExceptionType.connectionError:
        return NetworkException('网络连接失败，请检查您的网络设置', code: -3);
      default:
        return NetworkException('未知网络错误: ${error.message}', code: -4);
    }
  }
}

/// 业务逻辑异常（如 Token 失效、权限不足等）
class BusinessException extends AppException {
  BusinessException(String message, {int? code}) : super(message, code: code);
}

/// 数据解析异常
class ParseException extends AppException {
  ParseException(String message) : super(message, code: -5);
}
