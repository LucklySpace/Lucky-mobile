import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../config/app_config.dart';
import '../../../exceptions/app_exception.dart';

/// 全局错误处理器
///
/// 功能：
/// - 统一处理和展示错误信息
/// - 区分生产环境和开发环境的错误展示
/// - 记录详细的错误日志
/// - 提供友好的用户提示
class ErrorHandler {
  // 私有构造函数，防止实例化
  ErrorHandler._();

  /// 最后一次显示错误的时间
  static DateTime? _lastErrorTime;

  /// 最后一次显示的错误消息
  static String? _lastErrorMessage;

  /// 防止重复显示的时间间隔（毫秒）
  static const int _duplicateThreshold = 1000;

  /// 处理并展示错误
  ///
  /// [error] 错误对象
  /// [stackTrace] 堆栈跟踪（可选）
  /// [silent] 是否静默处理（仅记录日志，不显示UI提示）
  /// [tag] 错误标签（用于分类）
  static void handle(
    dynamic error, {
    StackTrace? stackTrace,
    bool silent = false,
    String? tag,
  }) {
    // 获取错误信息
    final errorInfo = _parseError(error);

    // 记录日志
    _logError(errorInfo, stackTrace, tag);

    // 显示用户提示
    if (!silent) {
      _showErrorToUser(errorInfo.userMessage);
    }

    // 特殊错误处理
    _handleSpecialError(error);
  }

  /// 解析错误对象
  static ErrorInfo _parseError(dynamic error) {
    if (error is AppException) {
      return ErrorInfo(
        userMessage: error.userMessage,
        detailMessage: error.detailMessage,
        code: error.code,
        type: _getErrorType(error),
      );
    } else if (error is FormatException) {
      return ErrorInfo(
        userMessage: '数据格式错误',
        detailMessage: error.toString(),
        type: ErrorType.parse,
      );
    } else if (error is Exception) {
      return ErrorInfo(
        userMessage: AppConfig.isDebug ? error.toString() : '操作失败，请稍后重试',
        detailMessage: error.toString(),
        type: ErrorType.unknown,
      );
    } else {
      return ErrorInfo(
        userMessage: AppConfig.isDebug ? error.toString() : '发生未知错误',
        detailMessage: error.toString(),
        type: ErrorType.unknown,
      );
    }
  }

  /// 获取错误类型
  static ErrorType _getErrorType(AppException exception) {
    if (exception is NetworkException) return ErrorType.network;
    if (exception is BusinessException) return ErrorType.business;
    if (exception is ParseException) return ErrorType.parse;
    if (exception is ValidationException) return ErrorType.validation;
    if (exception is StorageException) return ErrorType.storage;
    if (exception is AuthException) return ErrorType.auth;
    if (exception is PermissionException) return ErrorType.permission;
    return ErrorType.unknown;
  }

  /// 记录错误日志
  static void _logError(
    ErrorInfo errorInfo,
    StackTrace? stackTrace,
    String? tag,
  ) {
    final tagStr = tag != null ? '[$tag] ' : '';
    Get.log('❌ ${tagStr}ErrorHandler: ${errorInfo.detailMessage}');

    if (stackTrace != null && AppConfig.isDebug) {
      Get.log('Stack trace:\n$stackTrace');
    }

    // TODO: 在生产环境可以将错误上报到服务器
    // if (!AppConfig.isDebug) {
    //   _reportErrorToServer(errorInfo, stackTrace);
    // }
  }

  /// 显示错误提示给用户
  static void _showErrorToUser(String message) {
    // 检查是否有可用的上下文
    if (Get.context == null) {
      Get.log('⚠️ 无法显示错误提示：上下文不可用');
      return;
    }

    // 防止重复显示相同的错误
    final now = DateTime.now();
    if (_lastErrorMessage == message && _lastErrorTime != null) {
      final diff = now.difference(_lastErrorTime!).inMilliseconds;
      if (diff < _duplicateThreshold) {
        Get.log('⚠️ 跳过重复错误提示: $message');
        return;
      }
    }

    // 更新最后显示的错误信息
    _lastErrorMessage = message;
    _lastErrorTime = now;

    // 关闭已有的Snackbar（可选）
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }

    // 显示Snackbar
    Get.snackbar(
      '提示',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error_outline, color: Colors.white),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// 处理特殊错误（如Token失效需要跳转登录页）
  static void _handleSpecialError(dynamic error) {
    if (error is AuthException) {
      // Token失效，跳转到登录页
      Get.log('🔒 认证失败，准备跳转登录页');
      // TODO: 跳转到登录页
      // Get.offAllNamed(Routes.LOGIN);
    } else if (error is PermissionException) {
      // 权限不足
      Get.log('🚫 权限不足');
      // TODO: 可以显示权限申请对话框
    }
  }

  /// 显示成功提示
  static void showSuccess(String message) {
    if (Get.context == null) return;

    Get.snackbar(
      '成功',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// 显示信息提示
  static void showInfo(String message) {
    if (Get.context == null) return;

    Get.snackbar(
      '提示',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }

  /// 显示警告提示
  static void showWarning(String message) {
    if (Get.context == null) return;

    Get.snackbar(
      '警告',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.warning_amber, color: Colors.white),
    );
  }
}

/// 错误类型枚举
enum ErrorType {
  network, // 网络错误
  business, // 业务错误
  parse, // 解析错误
  validation, // 验证错误
  storage, // 存储错误
  auth, // 认证错误
  permission, // 权限错误
  unknown, // 未知错误
}

/// 错误信息封装类
class ErrorInfo {
  /// 用户友好的错误消息
  final String userMessage;

  /// 详细的错误信息（用于日志）
  final String detailMessage;

  /// 错误代码
  final int? code;

  /// 错误类型
  final ErrorType type;

  ErrorInfo({
    required this.userMessage,
    required this.detailMessage,
    this.code,
    required this.type,
  });
}
