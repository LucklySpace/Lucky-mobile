import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_sizes.dart';

class VideoCallSnackbar {
  static void show({
    required String avatar,
    required String username,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    Get.snackbar(
      '',
      '',
      titleText: const SizedBox.shrink(),
      messageText: _buildSnackbarContent(
        avatar: avatar,
        username: username,
        onAccept: onAccept,
        onReject: onReject,
      ),
      duration: const Duration(seconds: 30),
      backgroundColor: AppColors.mask,
      borderRadius: AppSizes.radius8,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12, vertical: AppSizes.spacing16),
      margin: const EdgeInsets.all(AppSizes.spacing8),
      snackPosition: SnackPosition.TOP,
    );
  }

  static Widget _buildSnackbarContent({
    required String avatar,
    required String username,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    return Row(
      children: [
        // 头像
        CircleAvatar(
          radius: AppSizes.radius24,
          backgroundImage: NetworkImage(avatar),
        ),
        const SizedBox(width: AppSizes.spacing16),
        // 用户名和通话请求文本
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                username,
                style: const TextStyle(
                  fontSize: AppSizes.font18,
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.spacing6),
              const Text(
                '视频通话请求',
                style: const TextStyle(
                  fontSize: AppSizes.font14,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        // 接通按钮
        IconButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            onAccept();
          },
          style: IconButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.all(AppSizes.spacing4),
          ),
          icon: const Icon(
            Icons.videocam_rounded,
            color: AppColors.textWhite,
            size: AppSizes.iconLarge,
          ),
        ),
        const SizedBox(width: AppSizes.spacing12),
        // 拒绝按钮
        IconButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            onReject();
          },
          style: IconButton.styleFrom(
            backgroundColor: AppColors.error,
            padding: const EdgeInsets.all(AppSizes.spacing4),
          ),
          icon: const Icon(
            Icons.call_end_rounded,
            color: AppColors.textWhite,
            size: AppSizes.iconLarge,
          ),
        ),
      ],
    );
  }
}
