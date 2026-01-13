import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_im/exceptions/app_exception.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../constants/app_constant.dart';
import '../core/handlers/error_handler.dart';

/// 主页控制器
///
/// 功能：
/// - 底部导航栏管理
/// - 语言切换
/// - 屏幕方向控制
/// - 用户偏好设置持久化
class HomeController extends GetxController {
  // ==================== 常量定义 ====================

  static const _localeZhCN = Locale('zh', 'CN');
  static const _localeEnUS = Locale('en', 'US');

  // ==================== 依赖注入 ====================

  final _storage = GetStorage();

  // ==================== 响应式状态 ====================

  /// 当前选中的底部导航栏索引
  final RxInt currentIndex = 0.obs;

  /// 当前语言
  final Rx<Locale> currentLocale = const Locale('zh', 'CN').obs;

  // ==================== 生命周期 ====================

  @override
  void onInit() {
    super.onInit();

    // 加载用户偏好设置
    _loadUserPreferences();

    // 设置屏幕为竖屏模式
    _setPortraitOrientation();
  }

  // ==================== 导航栏管理 ====================

  /// 切换底部导航栏
  ///
  /// [index] 新的索引值（0-3）
  void changeTabIndex(int index) {
    if (index < 0 || index > 3) {
      Get.log('⚠️ 无效的导航栏索引: $index');
      return;
    }

    if (currentIndex.value != index) {
      currentIndex.value = index;
      Get.log('📍 切换到导航栏: $index');
    }
  }

  // ==================== 语言管理 ====================

  /// 切换应用语言（中文/英文）
  void toggleLanguage() {
    final newLocale = Get.locale == _localeZhCN ? _localeEnUS : _localeZhCN;
    setLanguage(newLocale);
  }

  /// 设置语言
  ///
  /// [locale] 要设置的语言
  void setLanguage(Locale locale) {
    Get.updateLocale(locale);
    currentLocale.value = locale;
    _saveLanguagePreference(locale);

    // 显示成功提示
    ErrorHandler.showSuccess(
      locale.languageCode == 'zh' ? '语言已切换' : 'Language switched',
    );

    Get.log('🌍 语言已设置: ${locale.languageCode}');
  }

  // ==================== 持久化管理 ====================

  /// 加载用户偏好设置
  void _loadUserPreferences() {
    try {
      // 加载语言偏好
      final languageCode = _storage.read(AppConstants.cacheKeyLanguage);
      if (languageCode != null) {
        final locale = languageCode == 'en' ? _localeEnUS : _localeZhCN;
        currentLocale.value = locale;
        Get.updateLocale(locale);
        Get.log('✅ 已加载语言偏好: $languageCode');
      }
    } catch (e) {
      Get.log('⚠️ 加载用户偏好失败: $e');
    }
  }

  /// 保存语言偏好
  void _saveLanguagePreference(Locale locale) {
    try {
      _storage.write(AppConstants.cacheKeyLanguage, locale.languageCode);
    } catch (e) {
      Get.log('⚠️ 保存语言偏好失败: $e');
    }
  }

  // ==================== 屏幕方向控制 ====================

  /// 设置屏幕为竖屏模式
  Future<void> _setPortraitOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      Get.log('✅ 屏幕方向已设置为竖屏');
    } catch (e) {
      ErrorHandler.handle(
        AppException('设置屏幕方向失败', details: e),
        silent: true,
      );
    }
  }

  /// 重置屏幕方向（允许所有方向）
  Future<void> resetOrientation() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      Get.log('✅ 屏幕方向已重置');
    } catch (e) {
      ErrorHandler.handle(
        AppException('重置屏幕方向失败', details: e),
        silent: true,
      );
    }
  }
}
