import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';

/// 404 页面，显示页面未找到的错误提示
/// 特性：
/// - 显示错误图标、404 标题和提示文字。
/// - 提供“返回”和“返回首页”按钮，处理导航。
/// - 使用主题化样式，支持暗黑模式和一致性 UI。
class UnknownView extends GetView {
  // 常量定义
  static const _iconSize = AppSizes.spacing80; // 错误图标尺寸
  static const _titleStyle =
      TextStyle(fontSize: AppSizes.font32, fontWeight: FontWeight.bold); // 标题样式
  static const _messageStyle = TextStyle(fontSize: AppSizes.font18); // 提示文本样式
  static const _spacing = AppSizes.spacing16; // 垂直间距
  static const _buttonSpacing = AppSizes.spacing24; // 按钮区域间距
  static const _buttonTextStyle =
      TextStyle(fontSize: AppSizes.font16); // 按钮文本样式

  const UnknownView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面未找到'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 错误图标
            _buildErrorIcon(context),
            const SizedBox(height: _spacing),

            /// 404 标题
            Text(
              '404',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ) ??
                  _titleStyle,
            ),
            const SizedBox(height: _spacing),

            /// 提示文字
            Text(
              '抱歉，页面未找到',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ) ??
                  _messageStyle,
            ),
            const SizedBox(height: _buttonSpacing),

            /// 按钮区域
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  /// 构建错误图标
  Widget _buildErrorIcon(BuildContext context) {
    return Icon(
      Icons.error_outline,
      size: _iconSize,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  /// 构建按钮区域（返回和返回首页）
  Widget _buildButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// 返回按钮
        ElevatedButton(
          onPressed: Get.back,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing24, vertical: AppSizes.spacing12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius8)),
          ),
          child: Text(
            '返回',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ) ??
                _buttonTextStyle,
          ),
        ),
        const SizedBox(width: AppSizes.spacing16),

        /// 返回首页按钮
        OutlinedButton(
          onPressed: () => Get.offAllNamed(Routes.HOME),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing24, vertical: AppSizes.spacing12),
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius8)),
          ),
          child: Text(
            '返回首页',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ) ??
                _buttonTextStyle,
          ),
        ),
      ],
    );
  }
}
