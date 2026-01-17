import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../routes/app_routes.dart';
import '../../widgets/icon/icon_font.dart';

/// 设置页面
///
/// 特性：
/// - 分组展示各种设置选项
/// - 统一的图标与列表样式
/// - 简洁大方的布局
class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: AppSizes.spacing12),

          // 设置项分组
          ..._buildSettingGroups(),

          const SizedBox(height: AppSizes.spacing32),
        ],
      ),
    );
  }

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('设置'),
      centerTitle: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => Get.back(),
      ),
    );
  }

  /// 构建所有设置分组
  List<Widget> _buildSettingGroups() {
    return [
      _buildSettingGroup('账号', [
        const _SettingItemData(
          title: '个人资料',
          route: '${Routes.HOME}${Routes.USER_PROFILE}',
        ),
        const _SettingItemData(
          title: '账号与安全',
          route: '${Routes.HOME}${Routes.SETTING}/security',
        ),
      ]),
      _buildSettingGroup('通用', [
        const _SettingItemData(
          title: '消息通知',
          route: '${Routes.HOME}${Routes.SETTING}/notification',
        ),
        const _SettingItemData(
          title: '多语言设置',
          route: '${Routes.HOME}${Routes.SETTING}/language',
        ),
        const _SettingItemData(
          title: '存储管理',
          route: '${Routes.HOME}${Routes.SETTING}/storage',
        ),
      ]),
      _buildSettingGroup('关于', [
        const _SettingItemData(
          title: '关于我们',
          route: '${Routes.HOME}${Routes.SETTING}/about',
        ),
        const _SettingItemData(
          title: '检查更新',
          route: '${Routes.HOME}${Routes.SETTING}/update',
        ),
      ]),
    ];
  }

  /// 构建单个设置分组
  Widget _buildSettingGroup(String title, List<_SettingItemData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.spacing20,
              AppSizes.spacing16, AppSizes.spacing20, AppSizes.spacing8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppSizes.font13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          color: AppColors.surface,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildSettingTile(item),
                  if (index < items.length - 1)
                    const Divider(
                        height: 1, indent: 20, color: AppColors.divider),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建单个设置项 ListTile
  Widget _buildSettingTile(_SettingItemData item) {
    return InkWell(
      onTap: item.route != null ? () => Get.toNamed(item.route!) : item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacing20, vertical: AppSizes.spacing16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: AppSizes.font16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Iconfont.fromName('right'),
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

/// 内部使用的设置项数据类
class _SettingItemData {
  final String title;
  final String? route;
  final VoidCallback? onTap;

  const _SettingItemData({
    required this.title,
    this.route,
    this.onTap,
  });
}
