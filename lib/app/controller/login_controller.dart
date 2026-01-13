import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../utils/validator.dart';
import '../core/handlers/error_handler.dart';
import 'user_controller.dart';

/// 登录类型枚举
enum AuthType {
  /// 密码登录
  password,

  /// 验证码登录
  verifyCode,
}

/// 登录控制器
///
/// 功能：
/// - 密码/验证码登录
/// - 凭证安全存储
/// - 验证码倒计时
/// - 输入验证
class LoginController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // ==================== 常量定义 ====================

  static const _keySavedUsername = 'saved_username';
  static const _keySavedPassword = 'saved_password';
  static const _countdownSeconds = 60; // 验证码倒计时（秒）

  // 依赖注入
  final _secureStorage = const FlutterSecureStorage();
  late final UserController _userController;

  // 控制器和响应式状态
  late final TabController tabController; // 切换密码/验证码登录
  final TextEditingController principalController =
      TextEditingController(); // 用户名或手机号
  final TextEditingController credentialsController =
      TextEditingController(); // 密码或验证码
  final RxBool isLoading = false.obs; // 登录加载状态
  final RxBool rememberCredentials = false.obs; // 是否记住密码
  final RxBool canSendCode = true.obs; // 是否可发送验证码
  final RxInt countDown = _countdownSeconds.obs; // 验证码倒计时
  Timer? countdownTimer; // 验证码倒计时定时器

  /// 当前登录类型
  AuthType get currentAuthType =>
      tabController.index == 0 ? AuthType.password : AuthType.verifyCode;

  @override
  void onInit() {
    super.onInit();

    /// 初始化依赖和控制器
    _userController = Get.find<UserController>();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabChange);

    /// 加载公钥和已保存的凭证
    _loadPublicKey();
    _loadSavedCredentials();
  }

  @override
  void onClose() {
    /// 清理资源
    countdownTimer?.cancel();
    tabController.removeListener(_handleTabChange);
    tabController.dispose();
    principalController.dispose();
    credentialsController.dispose();
    super.onClose();
  }

  // --- 登录处理 ---

  /// 处理登录请求
  Future<void> handleLogin() async {
    if (isLoading.value) return;

    if (!_validateInput()) return;

    isLoading.value = true;
    try {
      final authType = currentAuthType == AuthType.password ? 'form' : 'sms';
      final success = await _userController.login(
        principalController.text,
        credentialsController.text,
        authType,
      );

      if (success) {
        if (currentAuthType == AuthType.password) {
          await _handleCredentialsStorage();
        }
        await _navigateToHome();
      }
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // --- 验证码管理 ---

  /// 发送验证码
  Future<void> sendVerificationCode() async {
    // 检查是否可以发送
    if (!canSendCode.value) {
      _showError(BusinessException('请等待倒计时结束'));
      return;
    }

    // 验证手机号
    final phoneError = Validator.validatePhone(principalController.text);
    if (phoneError != null) {
      _showError(ValidationException(phoneError));
      return;
    }

    try {
      await _userController.sendVerificationCode(principalController.text);
      ErrorHandler.showSuccess('验证码已发送');
      _startCountdown();
    } catch (e) {
      _showError(e);
    }
  }

  /// 开始验证码倒计时
  void _startCountdown() {
    canSendCode.value = false;
    countDown.value = _countdownSeconds;

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countDown.value == 0) {
        timer.cancel();
        canSendCode.value = true;
      } else {
        countDown.value--;
      }
    });
  }

  // --- 凭证管理 ---

  /// 加载保存的凭证
  Future<void> _loadSavedCredentials() async {
    try {
      final credentials = await _getSavedCredentials();
      if (credentials != null) {
        principalController.text = credentials['username']!;
        credentialsController.text = credentials['password']!;
        rememberCredentials.value = true;
        if (tabController.index != 0) {
          tabController.animateTo(0);
        }
      }
    } catch (e) {
      _showError(AppException('加载保存的凭证失败', details: e), silent: true);
    }
  }

  /// 保存登录凭证
  Future<void> _saveCredentials(String username, String password) async {
    await _secureStorage.write(key: _keySavedUsername, value: username);
    await _secureStorage.write(key: _keySavedPassword, value: password);
  }

  /// 获取保存的凭证
  Future<Map<String, String>?> _getSavedCredentials() async {
    final username = await _secureStorage.read(key: _keySavedUsername);
    final password = await _secureStorage.read(key: _keySavedPassword);

    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  /// 清除保存的凭证
  Future<void> _clearSavedCredentials() async {
    await _secureStorage.delete(key: _keySavedUsername);
    await _secureStorage.delete(key: _keySavedPassword);
  }

  // --- 辅助方法 ---

  /// 显示错误提示
  void _showError(dynamic error, {bool silent = false}) {
    ErrorHandler.handle(error, silent: silent);
  }

  /// 处理 Tab 切换，清空输入框
  void _handleTabChange() {
    if (tabController.indexIsChanging) {
      principalController.clear();
      credentialsController.clear();
    }
  }

  /// 加载公钥
  Future<void> _loadPublicKey() async {
    await _userController.getPublicKey();
  }

  /// 处理凭证存储逻辑
  Future<void> _handleCredentialsStorage() async {
    if (rememberCredentials.value) {
      await _saveCredentials(
        principalController.text,
        credentialsController.text,
      );
    } else {
      await _clearSavedCredentials();
    }
  }

  /// 跳转到主页
  Future<void> _navigateToHome() async {
    try {
      Get.offNamed(Routes.HOME);
    } catch (e) {
      _showError(BusinessException('获取用户信息失败，请重新登录'));
    }
  }

  /// 验证输入是否有效
  bool _validateInput() {
    final principal = principalController.text.trim();
    final credentials = credentialsController.text.trim();

    // 检查是否为空
    if (principal.isEmpty || credentials.isEmpty) {
      final message =
          currentAuthType == AuthType.password ? '请输入账号和密码' : '请输入手机号和验证码';
      _showError(ValidationException(message));
      return false;
    }

    // 验证码登录时，验证手机号格式
    if (currentAuthType == AuthType.verifyCode) {
      final phoneError = Validator.validatePhone(principal);
      if (phoneError != null) {
        _showError(ValidationException(phoneError));
        return false;
      }
    }

    // 密码登录时，验证密码格式
    if (currentAuthType == AuthType.password) {
      final passwordError = Validator.validatePassword(credentials);
      if (passwordError != null) {
        _showError(ValidationException(passwordError));
        return false;
      }
    }

    return true;
  }
}
