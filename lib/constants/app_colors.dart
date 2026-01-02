import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  AppColors._();

  // Brand Colors - 品牌色
  static const Color primary = Color(0xFF409EFF); // 主色调
  static const Color secondary = Color(0xFF998AED); // 次色调

  // Text Colors - 文本色
  static const Color textPrimary = Color(0xFF333333); // 主要文本
  static const Color textSecondary = Color(0xFF666666); // 次要文本
  static const Color textHint = Color(0xFF999999); // 提示文本
  static const Color textDisabled = Color(0xFFCCCCCC); // 禁用文本
  static const Color textWhite = Colors.white; // 白色文本

  // Background Colors - 背景色
  static const Color background = Color(0xFFF5F7FA); // 页面背景
  static const Color surface = Colors.white; // 卡片/容器背景
  static const Color inputBackground = Color(0xFFF5F7FA); // 输入框背景

  // Status Colors - 状态色
  static const Color success = Color(0xFF67C23A); // 成功
  static const Color warning = Color(0xFFE6A23C); // 警告
  static const Color error = Color(0xFFF56C6C); // 错误
  static const Color info = Color(0xFF909399); // 信息

  // Border & Divider - 边框与分割线
  static const Color border = Color(0xFFDCDFE6); // 边框
  static const Color divider = Color(0xFFEBEEF5); // 分割线

  // Other - 其他
  static const Color mask = Color(0x99000000); // 遮罩
  static const Color shadow = Color(0x1A000000); // 阴影
  static const Color toastBackground = Color(0x99000000); // Toast背景
  static const Color wechat = Color(0xFF24CF5F); // 微信
  static const Color female = Color(0xFFE91E63); // 女性
  static const Color inverseSurface = Color(0xFF333333); // 反色背景
  static const Color onInverseSurface = Colors.white; // 反色文本

  // Basic Colors - 基础色
  static const Color black = Colors.black; // 纯黑
  static const Color white = Colors.white; // 纯白
  static const Color transparent = Colors.transparent; // 透明
}
