import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/handlers/error_handler.dart';
import 'package:flutter_im/exceptions/app_exception.dart';

/// 主页控制器，管理底部导航栏切换和语言切换功能
class HomeController extends GetxController {
  // 常量定义
  static const _localeZhCN = Locale('zh', 'CN'); // 中文简体
  static const _localeEnUS = Locale('en', 'US'); // 英文（美国）

  // 响应式状态
  final RxInt currentIndex = 0.obs; // 当前选中的底部导航栏索引

  @override
  void onInit() {
    super.onInit();

    /// 初始化时强制设置屏幕为竖屏
    _setPortraitOrientation();
  }

  // --- 导航栏管理 ---

  /// 切换底部导航栏索引
  /// @param index 新的索引值
  void changeTabIndex(int index) {
    currentIndex.value = index;
  }

  // --- 语言管理 ---

  /// 切换应用语言（中文/英文）
  void toggleLanguage() {
    Get.updateLocale(
      Get.locale == _localeZhCN ? _localeEnUS : _localeZhCN,
    );
  }

  // --- 辅助方法 ---

  /// 显示错误提示
  void _showError(dynamic error, {bool silent = false}) {
    ErrorHandler.handle(error, silent: silent);
  }

  /// 设置屏幕为竖屏模式
  Future<void> _setPortraitOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } catch (e) {
      _showError(AppException('设置竖屏失败', details: e), silent: true);
    }
  }
}
