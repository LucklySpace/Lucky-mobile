import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_im/exceptions/app_exception.dart';

/// 全局错误处理器，负责统一展示错误信息
class ErrorHandler {
  /// 处理并展示错误
  /// [silent] 为 true 时仅记录日志，不显示 Snackbar
  static void handle(dynamic error,
      {StackTrace? stackTrace, bool silent = false}) {
    // 打印日志
    final String errorMsg = _getErrorMessage(error);
    Get.log('❌ ErrorHandler caught: $errorMsg');
    if (stackTrace != null) {
      Get.log(stackTrace.toString());
    }

    // 显示错误提示 (Snackbar)
    // 只有当应用在前台且上下文可用，并且非静默模式时才显示
    if (!silent && Get.context != null) {
      _showSnackbar(errorMsg);
    }
  }

  /// 获取友好的错误信息
  static String _getErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return error.message;
    } else if (error is BusinessException) {
      return error.message;
    } else if (error is ParseException) {
      return '数据解析失败，请稍后重试';
    } else if (error is FormatException) {
      return '数据格式错误';
    } else {
      // 生产环境可以隐藏具体的系统错误信息，显示通用提示
      // return '发生未知错误，请稍后重试';
      return error.toString();
    }
  }

  /// 显示 Snackbar
  static void _showSnackbar(String message) {
    // 避免重复显示相同的错误消息（可选逻辑，这里简单实现）
    if (Get.isSnackbarOpen) {
      // 如果已经有 Snackbar 打开，可以根据策略决定是否覆盖，这里选择不覆盖或者关闭旧的
      // Get.closeAllSnackbars();
    }

    Get.snackbar(
      '提示',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.redAccent.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }
}
