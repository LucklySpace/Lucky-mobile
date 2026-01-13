import 'package:flutter/material.dart';
import 'package:flutter_im/constants/app_colors.dart';
import 'package:flutter_im/constants/app_sizes.dart';
import 'package:get/get.dart';

class ChatInfoPage extends StatelessWidget {
  const ChatInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final String avatarUrl = args['avatar'] ?? '';
    final String name = args['name'] ?? '未知用户';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '$name 的聊天信息',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.font18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户头像
            Container(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radius8),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: avatarUrl.isNotEmpty
                          ? Image.network(avatarUrl, fit: BoxFit.cover)
                          : const Icon(Icons.person,
                              size: 50, color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacing16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: AppSizes.font18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spacing20),
            // 聊天记录
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing16, vertical: AppSizes.spacing12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '聊天设置',
                    style: TextStyle(
                      fontSize: AppSizes.font14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing10),
                  _buildSettingItem('查找聊天记录', onTap: () {
                    // TODO: Implement search chat history
                    Get.snackbar('提示', '功能开发中');
                  }),
                  const Divider(
                      height: AppSizes.spacing1, color: AppColors.divider),
                  // 消息免打扰
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      '消息免打扰',
                      style: TextStyle(
                        fontSize: AppSizes.font16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    value: false,
                    // 这里可以根据实际状态设置
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      // 处理免打扰逻辑
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppSizes.font16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
