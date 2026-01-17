import 'package:flutter_im/app/core/handlers/error_handler.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import 'package:flutter_im/utils/http.dart';
import 'package:get/get.dart';

import '../../api/api_service.dart';

/// 控制器基类
///
/// 提供统一的错误处理、API响应处理和通用方法
/// 所有业务控制器都应该继承此类
class BaseController extends GetxController {
  // ==================== 依赖注入 ====================

  /// 获取 ApiService 实例
  ApiService get apiService => Get.find<ApiService>();

  /// 获取 ErrorHandler 实例
  ErrorHandler get errorHandler => Get.find<ErrorHandler>();

  // ==================== 响应式状态 ====================

  /// 是否正在加载
  final RxBool isLoading = false.obs;

  /// 错误信息
  final RxString errorMessage = ''.obs;

  // ==================== API 响应处理 ====================

  /// 处理 API 响应的统一方法
  ///
  /// [response] API 响应结果
  /// [onSuccess] 成功回调，接收数据
  /// [onError] 错误回调，接收错误码和消息
  /// [showError] 是否显示错误提示
  /// [silent] 是否静默模式（不显示任何提示）
  void handleApiResponse<T>(
    Result<T> response, {
    void Function(T data)? onSuccess,
    void Function(int code, String message)? onError,
    bool showError = true,
    bool silent = false,
  }) {
    try {
      // 检查响应是否成功
      if (response.isSuccess) {
        // 成功：执行成功回调
        if (onSuccess != null) {
          // 注意：如果 data 为 null，且 T 是非空类型，这里可能会抛出异常
          // 建议在 ApiService 中根据接口定义确定 T 的类型（是否可空）
          onSuccess(response.data as T);
        }
      } else {
        // 失败：执行错误回调
        if (onError != null) {
          onError(response.code, response.message);
        }

        // 显示错误信息
        if (!silent && showError) {
          this.showError(response.message);
        }

        // 记录错误日志
        Get.log('❌ API Error: [${response.code}] ${response.message}');
      }
    } catch (e) {
      // 异常处理
      final msg = '处理响应异常: $e';
      if (onError != null) {
        onError(-1, msg);
      }

      if (!silent && showError) {
        this.showError(msg);
      }

      Get.log('❌ Response Handling Error: $e');
    }
  }

  /// 执行带加载状态的异步操作
  ///
  /// [operation] 要执行的异步操作
  /// [onSuccess] 成功回调
  /// [onError] 错误回调
  /// [showError] 是否显示错误提示
  Future<T?> executeAsync<T>({
    required Future<T> Function() operation,
    Function(T data)? onSuccess,
    Function(int code, String message)? onError,
    bool showError = true,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await operation();

      if (onSuccess != null) {
        await onSuccess(result);
      }

      return result;
    } on AppException catch (e) {
      if (onError != null) {
        onError(e.code ?? -1, e.message);
      }

      if (showError) {
        this.showError(e.message);
      }

      Get.log('❌ Error: [${e.code}] ${e.message}');
      return null;
    } on Exception catch (e) {
      final msg = '操作失败: $e';
      if (onError != null) {
        onError(-1, msg);
      }

      if (showError) {
        this.showError(msg);
      }

      Get.log('❌ Error: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== 错误处理 ====================

  /// 显示错误信息
  ///
  /// 子类可以重写此方法自定义错误显示方式
  void showError(dynamic message) {
    if (message == null) return;

    // 如果是异常对象，使用 ErrorHandler 处理
    if (message is! String) {
      ErrorHandler.handle(message);
      return;
    }

    // 默认实现：使用 snackbar
    Get.snackbar(
      '错误',
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  /// 显示成功信息
  void showSuccess(String message) {
    Get.snackbar(
      '成功',
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  /// 显示提示信息
  void showInfo(String message) {
    Get.snackbar(
      '提示',
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  // ==================== 验证方法 ====================

  /// 验证字符串是否为空
  bool validateNotEmpty(String? value, {String fieldName = '字段'}) {
    if (value == null || value.isEmpty) {
      showError('$fieldName不能为空');
      return false;
    }
    return true;
  }

  /// 验证用户ID是否已初始化
  bool validateUserId(String? userId) {
    if (userId == null || userId.isEmpty) {
      showError('用户ID未初始化，请先登录');
      return false;
    }
    return true;
  }

  // ==================== 生命周期 ====================

  @override
  void onClose() {
    isLoading.close();
    errorMessage.close();
    super.onClose();
  }
}
