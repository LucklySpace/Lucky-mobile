import 'package:dio/dio.dart';

/// 全局异常基类
///
/// 所有自定义异常的基类，提供统一的异常处理接口
class AppException implements Exception {
  /// 异常消息
  final String message;

  /// 异常代码
  final int? code;

  /// 异常详细信息
  final dynamic details;

  /// 异常时间戳
  final DateTime timestamp;

  AppException(
    this.message, {
    this.code,
    this.details,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    if (code != null) {
      return '[$code] $message';
    }
    return message;
  }

  /// 获取用户友好的错误消息
  String get userMessage => message;

  /// 获取详细的错误信息（用于日志）
  String get detailMessage {
    final buffer = StringBuffer();
    buffer.write('[$code] $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    buffer.write('\nTimestamp: $timestamp');
    return buffer.toString();
  }
}

/// 网络异常
///
/// 处理所有网络相关的异常情况
class NetworkException extends AppException {
  NetworkException(
    String message, {
    int? code,
    dynamic details,
  }) : super(message, code: code, details: details);

  /// 从Dio异常转换为网络异常
  factory NetworkException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          '连接超时，请检查网络连接',
          code: -1001,
          details: error.message,
        );

      case DioExceptionType.sendTimeout:
        return NetworkException(
          '请求超时，请稍后重试',
          code: -1002,
          details: error.message,
        );

      case DioExceptionType.receiveTimeout:
        return NetworkException(
          '响应超时，请稍后重试',
          code: -1003,
          details: error.message,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return NetworkException(
          '请求已取消',
          code: -1005,
          details: error.message,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          '网络连接失败，请检查网络设置',
          code: -1006,
          details: error.message,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          'SSL证书验证失败',
          code: -1007,
          details: error.message,
        );

      case DioExceptionType.unknown:
        return NetworkException(
          '网络请求失败：${error.message ?? "未知错误"}',
          code: -1000,
          details: error.toString(),
        );
    }
  }

  /// 处理错误响应
  static NetworkException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // 尝试从响应体中解析后端返回的错误信息
    String? message;
    if (data is Map) {
      message = data['message'] ?? data['msg'] ?? data['error'];
    }

    // 根据HTTP状态码返回不同的错误消息
    switch (statusCode) {
      case 400:
        return NetworkException(
          message ?? '请求参数错误',
          code: statusCode,
          details: data,
        );
      case 401:
        return NetworkException(
          message ?? '未授权，请重新登录',
          code: statusCode,
          details: data,
        );
      case 403:
        return NetworkException(
          message ?? '权限不足',
          code: statusCode,
          details: data,
        );
      case 404:
        return NetworkException(
          message ?? '请求的资源不存在',
          code: statusCode,
          details: data,
        );
      case 405:
        return NetworkException(
          message ?? '请求方法不被允许',
          code: statusCode,
          details: data,
        );
      case 408:
        return NetworkException(
          message ?? '请求超时',
          code: statusCode,
          details: data,
        );
      case 500:
        return NetworkException(
          message ?? '服务器内部错误',
          code: statusCode,
          details: data,
        );
      case 502:
        return NetworkException(
          message ?? '网关错误',
          code: statusCode,
          details: data,
        );
      case 503:
        return NetworkException(
          message ?? '服务暂时不可用',
          code: statusCode,
          details: data,
        );
      case 504:
        return NetworkException(
          message ?? '网关超时',
          code: statusCode,
          details: data,
        );
      default:
        return NetworkException(
          message ?? '服务器错误 ($statusCode)',
          code: statusCode,
          details: data,
        );
    }
  }
}

/// 业务逻辑异常
///
/// 处理业务层面的异常，如Token失效、权限不足等
class BusinessException extends AppException {
  BusinessException(
    String message, {
    int? code,
    dynamic details,
  }) : super(message, code: code, details: details);
}

/// 数据解析异常
///
/// 处理数据解析相关的异常
class ParseException extends AppException {
  ParseException(
    String message, {
    dynamic details,
  }) : super(message, code: -2001, details: details);
}

/// 验证异常
///
/// 处理数据验证相关的异常
class ValidationException extends AppException {
  ValidationException(
    String message, {
    dynamic details,
  }) : super(message, code: -3001, details: details);
}

/// 存储异常
///
/// 处理本地存储相关的异常
class StorageException extends AppException {
  StorageException(
    String message, {
    dynamic details,
  }) : super(message, code: -4001, details: details);
}

/// 认证异常
///
/// 处理用户认证相关的异常
class AuthException extends AppException {
  AuthException(
    String message, {
    int? code,
    dynamic details,
  }) : super(message, code: code ?? -5001, details: details);
}

/// 权限异常
///
/// 处理权限相关的异常
class PermissionException extends AppException {
  PermissionException(
    String message, {
    dynamic details,
  }) : super(message, code: -6001, details: details);
}
