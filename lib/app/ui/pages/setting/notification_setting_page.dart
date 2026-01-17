import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';
import '../../../services/notification_service.dart';

/// 消息通知设置页面
class NotificationSettingPage extends GetView<LocalNotificationService> {
  const NotificationSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Obx(() => ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
            children: [
              // 消息通知总开关
              _buildSettingGroup('基础设置', [
                _buildSwitchTile(
                  'settings.notification.enable'.tr,
                  controller.enableNotification.value,
                  (value) => controller.updateEnableNotification(value),
                  subtitle: 'settings.notification.desc'.tr,
                ),
              ]),

              if (controller.enableNotification.value) ...[
                const SizedBox(height: AppSizes.spacing20),

                // 通知内容显示
                _buildSettingGroup('内容显示', [
                  _buildSwitchTile(
                    'settings.notification.show_preview'.tr,
                    controller.showPreview.value,
                    (value) => controller.updateShowPreview(value),
                    subtitle: 'settings.notification.preview_desc'.tr,
                  ),
                ]),

                const SizedBox(height: AppSizes.spacing20),

                // 提醒方式
                _buildSettingGroup('提醒方式', [
                  _buildSwitchTile(
                    'settings.notification.sound'.tr,
                    controller.sound.value,
                    (value) => controller.updateSound(value),
                  ),
                  _buildSwitchTile(
                    'settings.notification.vibrate'.tr,
                    controller.vibrate.value,
                    (value) => controller.updateVibrate(value),
                  ),
                ]),
              ],
              const SizedBox(height: AppSizes.spacing32),
            ],
          )),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('settings.notification'.tr),
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

  /// 构建设置分组
  Widget _buildSettingGroup(String? title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
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
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
          ),
          child: Column(
            children: List.generate(children.length, (index) {
              return Column(
                children: [
                  children[index],
                  if (index < children.length - 1)
                    const Divider(
                        height: 1, indent: 20, color: AppColors.divider),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing16, vertical: AppSizes.spacing8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: AppSizes.font16, color: AppColors.textPrimary),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: AppSizes.font12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
